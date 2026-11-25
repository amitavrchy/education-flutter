import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/mock/json_collection.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/storage/local_store.dart';
import '../../profile/application/student_profile_controller.dart';
import '../data/ai_tutor_repository.dart';
import '../data/mock_tutor_engine.dart';
import '../domain/tutor_models.dart';
import '../../settings/learning_prefs.dart';

/// All tutor conversations (newest activity first) and the streaming state of answers.
class TutorController extends Notifier<List<Conversation>> {
  late JsonCollection<Conversation> _collection;
  late LocalStore _store;
  final Map<String, StreamSubscription<TutorEvent>> _streams = {};

  @override
  List<Conversation> build() {
    _store = watchStore(ref);
    final engine = ref.read(mockTutorEngineProvider);
    _collection = JsonCollection<Conversation>(
      store: _store,
      name: 'tutor_conversations',
      fromJson: Conversation.fromJson,
      toJson: (c) => c.toJson(),
      idOf: (c) => c.id,
      seed: () => seedConversations(engine),
    );
    ref.onDispose(() {
      for (final s in _streams.values) {
        s.cancel();
      }
      _streams.clear();
    });
    // A stream interrupted by an app restart is shown as an error the user can retry.
    return _sorted([
      for (final c in _collection.all())
        c.copyWith(messages: [
          for (final m in c.messages)
            m.status == MessageStatus.streaming ? m.copyWith(status: MessageStatus.error, error: () => 'INTERRUPTED') : m,
        ]),
    ]);
  }

  List<Conversation> _sorted(List<Conversation> list) => list..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

  Conversation? byId(String id) => state.where((c) => c.id == id).firstOrNull;

  Future<void> _put(Conversation c, {bool persist = true}) async {
    state = _sorted([c, ...state.where((x) => x.id != c.id)]);
    if (persist) await _collection.upsert(c);
  }

  /// Default context from the student's profile and tutor preferences.
  TutorContext defaultContext() {
    final p = ref.read(studentProfileProvider);
    final prefs = ref.read(learningPrefsProvider);
    return TutorContext(level: p.level, classYear: p.classYear, curriculumVersionId: p.curriculumVersionId, mode: prefs.tutorMode, language: prefs.tutorLanguage);
  }

  Future<Conversation> create({TutorContext? context, String? title}) async {
    final now = DateTime.now();
    final c = Conversation(
      id: 'c-${now.microsecondsSinceEpoch}',
      title: title ?? '',
      createdAt: now,
      updatedAt: now,
      context: context ?? defaultContext(),
    );
    await _put(c);
    return c;
  }

  Future<void> send(String conversationId, String text) async {
    final c = byId(conversationId);
    if (c == null || text.trim().isEmpty || c.isStreaming) return;
    final now = DateTime.now();
    final user = ChatMessage(id: 'm-${now.microsecondsSinceEpoch}', role: ChatRole.user, text: text.trim(), createdAt: now);
    final title = c.title.isEmpty ? (text.trim().length > 48 ? '${text.trim().substring(0, 48)}…' : text.trim()) : c.title;
    await _put(c.copyWith(title: title, messages: [...c.messages, user], updatedAt: now));
    await _ask(conversationId, user.text);
  }

  /// Streams an answer into a new (or [replaceId]) assistant message.
  Future<void> _ask(String conversationId, String query, {String? replaceId, int variant = 0, List<String> versions = const []}) async {
    final c = byId(conversationId)!;
    final now = DateTime.now();
    final id = replaceId ?? 'm-${now.microsecondsSinceEpoch + 1}';
    final placeholder = ChatMessage(
      id: id,
      role: ChatRole.assistant,
      text: '',
      createdAt: now,
      status: MessageStatus.streaming,
      mode: c.context.mode,
      versions: versions,
    );
    final history = c.messages.where((m) => m.id != replaceId).toList();
    final messages = replaceId == null ? [...c.messages, placeholder] : [for (final m in c.messages) m.id == replaceId ? placeholder : m];
    await _put(c.copyWith(messages: messages, updatedAt: now), persist: false);

    final buffer = StringBuffer();
    final completer = Completer<void>();
    _streams[conversationId] = ref
        .read(aiTutorRepositoryProvider)
        .ask(query: query, context: c.context, history: history, variant: variant)
        .listen(
          (event) {
            switch (event) {
              case TutorDelta(:final text):
                buffer.write(text);
                _updateMessage(conversationId, id, (m) => m.copyWith(text: buffer.toString()), persist: false);
              case TutorDone(:final reply):
                _updateMessage(
                  conversationId,
                  id,
                  (m) => m.copyWith(
                    text: reply.text,
                    status: MessageStatus.done,
                    sources: reply.sources,
                    grounding: reply.grounding,
                    confidence: reply.confidence,
                    followUps: reply.followUps,
                    relatedQuestionIds: reply.relatedQuestionIds,
                    warnings: reply.warnings,
                  ),
                );
            }
          },
          onError: (Object e) {
            final code = e is ApiException ? e.code : 'UNKNOWN';
            _updateMessage(conversationId, id, (m) => m.copyWith(status: MessageStatus.error, error: () => code));
            _streams.remove(conversationId);
            if (!completer.isCompleted) completer.complete();
          },
          onDone: () {
            _streams.remove(conversationId);
            if (!completer.isCompleted) completer.complete();
          },
          cancelOnError: true,
        );
    return completer.future;
  }

  Future<void> _updateMessage(String conversationId, String messageId, ChatMessage Function(ChatMessage) change, {bool persist = true}) async {
    final c = byId(conversationId);
    if (c == null) return;
    await _put(
      c.copyWith(messages: [for (final m in c.messages) m.id == messageId ? change(m) : m]),
      persist: persist,
    );
  }

  /// Stops a streaming answer, keeping what has arrived so far.
  Future<void> stop(String conversationId) async {
    await _streams.remove(conversationId)?.cancel();
    final c = byId(conversationId);
    if (c == null) return;
    await _put(c.copyWith(messages: [
      for (final m in c.messages) m.status == MessageStatus.streaming ? m.copyWith(status: MessageStatus.done) : m,
    ]));
  }

  String? _questionBefore(Conversation c, String assistantId) {
    final i = c.messages.indexWhere((m) => m.id == assistantId);
    for (var j = i - 1; j >= 0; j--) {
      if (c.messages[j].isUser) return c.messages[j].text;
    }
    return null;
  }

  Future<void> retry(String conversationId, String assistantId) async {
    final c = byId(conversationId);
    final q = c == null ? null : _questionBefore(c, assistantId);
    if (q != null) await _ask(conversationId, q, replaceId: assistantId);
  }

  /// New version of an answer; the old one goes into the correction history.
  Future<void> regenerate(String conversationId, String assistantId) async {
    final c = byId(conversationId);
    if (c == null || c.isStreaming) return;
    final old = c.messages.firstWhere((m) => m.id == assistantId);
    final q = _questionBefore(c, assistantId);
    if (q == null) return;
    await _ask(conversationId, q, replaceId: assistantId, variant: old.versions.length + 1, versions: [...old.versions, old.text]);
  }

  /// Edits a question and re-asks it; later messages are dropped.
  Future<void> editUserMessage(String conversationId, String messageId, String text) async {
    final c = byId(conversationId);
    if (c == null || c.isStreaming || text.trim().isEmpty) return;
    final i = c.messages.indexWhere((m) => m.id == messageId);
    if (i < 0) return;
    final edited = c.messages[i].copyWith(text: text.trim(), editedAt: DateTime.now());
    await _put(c.copyWith(messages: [...c.messages.take(i), edited], updatedAt: DateTime.now()));
    await _ask(conversationId, edited.text);
  }

  Future<void> setContext(String conversationId, TutorContext context) async {
    final c = byId(conversationId);
    if (c != null) await _put(c.copyWith(context: context));
  }

  Future<void> rename(String id, String title) async => _mutate(id, (c) => c.copyWith(title: title));

  Future<void> togglePin(String id) async => _mutate(id, (c) => c.copyWith(pinned: !c.pinned));

  Future<void> toggleArchive(String id) async => _mutate(id, (c) => c.copyWith(archived: !c.archived));

  Future<void> setFolder(String id, String? folder) async => _mutate(id, (c) => c.copyWith(folder: () => folder));

  Future<void> _mutate(String id, Conversation Function(Conversation) change) async {
    final c = byId(id);
    if (c != null) await _put(change(c));
  }

  Future<void> delete(String id) async {
    await _streams.remove(id)?.cancel();
    state = state.where((c) => c.id != id).toList();
    await _collection.remove(id);
  }

  Future<void> setFeedback(String conversationId, String messageId, int? value) =>
      _updateMessage(conversationId, messageId, (m) => m.copyWith(feedback: () => value));

  Future<void> toggleBookmark(String conversationId, String messageId) =>
      _updateMessage(conversationId, messageId, (m) => m.copyWith(bookmarked: !m.bookmarked));

  Future<void> report(String conversationId, String messageId, String reason) async {
    await _updateMessage(conversationId, messageId, (m) => m.copyWith(reported: true));
    await _store.put('ai_reports', '$conversationId/$messageId', {
      'conversationId': conversationId,
      'messageId': messageId,
      'reason': reason,
      'at': DateTime.now().toIso8601String(),
    });
  }

  /// Queues the answer for a teacher (appears in the teacher review queue).
  Future<void> requestTeacherReview(String conversationId, String messageId) async {
    final c = byId(conversationId);
    final m = c?.messages.where((x) => x.id == messageId).firstOrNull;
    if (c == null || m == null) return;
    await _updateMessage(conversationId, messageId, (x) => x.copyWith(teacherReview: true));
    await _store.put('review_requests', messageId, {
      'id': messageId,
      'kind': 'ai_answer',
      'conversationId': conversationId,
      'question': _questionBefore(c, messageId) ?? '',
      'answer': m.text,
      'subjectId': c.context.subjectId,
      'status': 'submitted',
      'at': DateTime.now().toIso8601String(),
    });
  }

  /// All bookmarked answers across conversations.
  List<(Conversation, ChatMessage)> get bookmarkedAnswers => [
    for (final c in state)
      for (final m in c.messages)
        if (m.bookmarked) (c, m),
  ];
}

final tutorProvider = NotifierProvider<TutorController, List<Conversation>>(TutorController.new);

/// Markdown transcript used for export, notes and sharing.
String conversationMarkdown(Conversation c, {bool includeName = false, String studentName = ''}) {
  final b = StringBuffer('# ${c.title.isEmpty ? 'AI Tutor' : c.title}\n\n');
  for (final m in c.messages) {
    final who = m.isUser ? (includeName && studentName.isNotEmpty ? studentName : 'Student') : 'AI Tutor (simulated)';
    b.writeln('**$who:**\n\n${m.text}\n');
  }
  return b.toString();
}

/// Two sample conversations so history, search and grouping have content on first launch.
List<Conversation> seedConversations(MockTutorEngine engine) {
  final now = DateTime.now();
  Conversation make(String id, String q, TutorContext ctx, Duration ago, {bool pinned = false, String? folder}) {
    final t = now.subtract(ago);
    final reply = engine.answer(query: q, context: ctx);
    return Conversation(
      id: id,
      title: q,
      createdAt: t,
      updatedAt: t,
      context: ctx,
      pinned: pinned,
      folder: folder,
      messages: [
        ChatMessage(id: '$id-u', role: ChatRole.user, text: q, createdAt: t),
        ChatMessage(
          id: '$id-a',
          role: ChatRole.assistant,
          text: reply.text,
          createdAt: t.add(const Duration(seconds: 4)),
          mode: ctx.mode,
          sources: reply.sources,
          grounding: reply.grounding,
          confidence: reply.confidence,
          followUps: reply.followUps,
          relatedQuestionIds: reply.relatedQuestionIds,
          warnings: reply.warnings,
        ),
      ],
    );
  }

  return [
    make('c-seed-1', 'নিউটনের দ্বিতীয় সূত্র বুঝিয়ে দাও',
        const TutorContext(subjectId: 'ssc-phy', chapterId: 'ssc-phy-p1-c3', topicId: 'ssc-phy-p1-c3-t1'), const Duration(hours: 5),
        pinned: true, folder: 'পদার্থবিজ্ঞান রিভিশন'),
    make('c-seed-2', 'সালোকসংশ্লেষণের দ্রুত রিভিশন',
        const TutorContext(subjectId: 'ssc-bio', mode: TeachingMode.quickRevision), const Duration(days: 1, hours: 3)),
    make('c-seed-3', 'x^2 + 7x + 12 factorise step by step',
        const TutorContext(subjectId: 'ssc-gmath', language: TutorLanguage.en, mode: TeachingMode.stepByStep), const Duration(days: 3)),
  ];
}
