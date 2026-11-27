import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/tr.dart';
import '../../../core/mock/json_collection.dart';
import '../../../core/storage/local_store.dart';
import '../../ai_tutor/domain/tutor_models.dart';
import '../../curriculum/data/curriculum_repository.dart';
import '../../progress/application/learning_progress_controller.dart';
import '../../progress/domain/learning_progress.dart';
import '../../question_bank/data/question_repository.dart';
import '../../question_bank/domain/question.dart';
import '../domain/note.dart';
import 'note_generator.dart';
import '../../../core/network/network_providers.dart';
import '../../../core/network/owner_sync.dart';
import '../../progress/data/remote_progress.dart';
import '../data/remote_notes.dart';
import '../../ai_tools/remote_ai_tools.dart';

/// Notes CRUD with autosave history, folders, tags, favourites, linking and generation.
class NotesController extends Notifier<List<Note>> {
  late JsonCollection<Note> _collection;

  static const _maxHistory = 10;
  static const _snapshotGap = Duration(minutes: 2);

  OwnerSync? _sync;
  bool _applyingServer = false;
  Future<void>? _refreshing;

  @override
  List<Note> build() {
    final remote = ref.watch(remoteProgressProvider);
    _collection = JsonCollection<Note>(
      store: watchStore(ref),
      name: 'notes',
      fromJson: Note.fromJson,
      toJson: (n) => n.toJson(),
      idOf: (n) => n.id,
      seed: remote == null ? _seed : () => const [],
    );
    _sync = remote == null ? null : OwnerSync(ref.read(apiClientProvider), collection: 'notes', studentId: remote.studentId);
    ref.onDispose(() => _sync?.dispose());
    if (_sync != null) {
      // Local edits push the whole note list (debounced); web-only fields are preserved.
      listenSelf((prev, next) {
        if (prev == null || _applyingServer || identical(prev, next)) return;
        _sync?.schedule(() => [for (final n in state) _sync!.merge(n.id, NoteMapper.fields(n), defaults: NoteMapper.defaults(n))]);
      });
      Future.microtask(refresh);
    }
    return _sorted(_collection.all());
  }

  /// API mode: the server's notes replace the local copy (single-flight).
  Future<void> refresh() => _refreshing ??= _refresh().whenComplete(() => _refreshing = null);

  Future<void> _refresh() async {
    if (_sync == null || !ref.mounted) return;
    try {
      final notes = [for (final n in await _sync!.pull()) NoteMapper.fromApi(n)];
      if (!ref.mounted) return;
      await ref.read(localStoreProvider).clearCollection('notes');
      await _collection.upsertAll(notes);
      _applyingServer = true;
      state = _sorted(notes);
      _applyingServer = false;
    } catch (_) {
      // Offline: keep the cached notes.
    }
  }

  List<Note> _sorted(List<Note> list) => list..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

  Note? byId(String id) => state.where((n) => n.id == id).firstOrNull;

  NoteGenerator get generator => NoteGenerator(
    curriculum: ref.read(curriculumRepositoryProvider),
    questions: ref.read(questionRepositoryProvider).cached,
  );

  Future<Note> _put(Note n) async {
    state = _sorted([n, ...state.where((x) => x.id != n.id)]);
    await _collection.upsert(n);
    return n;
  }

  Future<Note> create({
    String title = '',
    String body = '',
    NoteType type = NoteType.freeform,
    NoteSource source = NoteSource.manual,
    String? subjectId,
    String? chapterId,
    String? topicId,
    String? folder,
    List<String> tags = const [],
    bool aiGenerated = false,
  }) async {
    final now = DateTime.now();
    final note = await _put(Note(
      id: 'n-${now.microsecondsSinceEpoch}',
      title: title,
      body: body,
      createdAt: now,
      updatedAt: now,
      type: type,
      source: source,
      subjectId: subjectId,
      chapterId: chapterId,
      topicId: topicId,
      folder: folder,
      tags: tags,
      aiGenerated: aiGenerated,
    ));
    await ref.read(learningProgressProvider.notifier).logActivity(ActivityKind.notes, minutes: 5, xp: 5, subjectId: subjectId);
    return note;
  }

  /// Autosave. Keeps a snapshot in the history when the previous save is older than
  /// [_snapshotGap] (or when [snapshot] is forced, e.g. on leaving the editor).
  Future<void> save(String id, {String? title, String? body, bool snapshot = false}) async {
    final n = byId(id);
    if (n == null) return;
    if ((title ?? n.title) == n.title && (body ?? n.body) == n.body) return;
    final now = DateTime.now();
    final keep = snapshot || now.difference(n.updatedAt) > _snapshotGap;
    final history = keep && n.body.isNotEmpty
        ? [NoteVersion(at: n.updatedAt, title: n.title, body: n.body), ...n.history].take(_maxHistory).toList()
        : n.history;
    await _put(n.copyWith(title: title, body: body, updatedAt: now, history: history));
  }

  Future<void> restore(String id, NoteVersion v) async {
    final n = byId(id);
    if (n == null) return;
    await _put(n.copyWith(
      title: v.title,
      body: v.body,
      updatedAt: DateTime.now(),
      history: [NoteVersion(at: n.updatedAt, title: n.title, body: n.body), ...n.history].take(_maxHistory).toList(),
    ));
  }

  Future<void> toggleFavorite(String id) async {
    final n = byId(id);
    if (n != null) await _put(n.copyWith(favorite: !n.favorite));
  }

  Future<void> setFolder(String id, String? folder) async {
    final n = byId(id);
    if (n != null) await _put(n.copyWith(folder: () => folder));
  }

  Future<void> setTags(String id, List<String> tags) async {
    final n = byId(id);
    if (n != null) await _put(n.copyWith(tags: {for (final t in tags) t.trim().toLowerCase()}.where((t) => t.isNotEmpty).toList()));
  }

  /// Two-way link.
  Future<void> link(String a, String b) async {
    final na = byId(a);
    final nb = byId(b);
    if (na == null || nb == null || a == b) return;
    await _put(na.copyWith(linkedIds: {...na.linkedIds, b}.toList()));
    await _put(nb.copyWith(linkedIds: {...nb.linkedIds, a}.toList()));
  }

  Future<void> unlink(String a, String b) async {
    final na = byId(a);
    final nb = byId(b);
    if (na != null) await _put(na.copyWith(linkedIds: na.linkedIds.where((x) => x != b).toList()));
    if (nb != null) await _put(nb.copyWith(linkedIds: nb.linkedIds.where((x) => x != a).toList()));
  }

  Future<void> delete(String id) async {
    for (final other in state.where((n) => n.linkedIds.contains(id)).toList()) {
      await _put(other.copyWith(linkedIds: other.linkedIds.where((x) => x != id).toList()));
    }
    state = state.where((n) => n.id != id).toList();
    await _collection.remove(id);
  }

  // ── Generation (AI service in API mode; the local generator in the mock) ──

  /// API mode: the note written by the AI service (HTML → the app's Markdown); null in the mock.
  Future<({String title, String body})?> _aiNote(NoteType type, {String? chapterId, String? topicId, String? questionText, String? answerText, String? conversation}) async {
    final remote = ref.read(remoteAiToolsProvider);
    if (remote == null) return null;
    final r = await remote.note(kind: NoteMapper.kindOf(type), chapterId: chapterId, topicId: topicId, questionText: questionText, answerText: answerText, conversation: conversation);
    return (title: r.title, body: htmlToMarkdown(r.html));
  }

  Future<Note> generateFromChapter(String chapterId, NoteType type, AppLanguage lang) async {
    final repo = ref.read(curriculumRepositoryProvider);
    final ch = repo.findChapter(chapterId)!;
    final topics = [for (final t in ch.chapter.topics) repo.findTopic(t.id)!];
    final out = await _aiNote(type, chapterId: chapterId) ?? generator.fromTopics(scopeTitle: ch.chapter.title.of(lang), topics: topics, type: type, lang: lang);
    return create(
      title: out.title,
      body: out.body,
      type: type,
      source: NoteSource.chapter,
      subjectId: ch.subject.id,
      chapterId: chapterId,
      tags: [ch.subject.code],
      aiGenerated: true,
    );
  }

  Future<Note> generateFromTopic(String topicId, NoteType type, AppLanguage lang) async {
    final r = ref.read(curriculumRepositoryProvider).findTopic(topicId)!;
    final out = await _aiNote(type, topicId: topicId) ?? generator.fromTopics(scopeTitle: r.topic.title.of(lang), topics: [r], type: type, lang: lang);
    return create(
      title: out.title,
      body: out.body,
      type: type,
      source: NoteSource.topic,
      subjectId: r.subject.id,
      chapterId: r.chapter.id,
      topicId: topicId,
      aiGenerated: true,
    );
  }

  Future<Note> generateFromQuestion(Question q, AppLanguage lang) async {
    final out = await _aiNote(NoteType.importantQuestions, questionText: q.stem.of(lang), answerText: q.answer.of(lang)) ?? generator.fromQuestion(q, lang);
    return create(
      title: out.title,
      body: out.body,
      type: NoteType.importantQuestions,
      source: NoteSource.question,
      subjectId: q.subjectId,
      chapterId: q.chapterId,
      topicId: q.topicId,
      aiGenerated: true,
    );
  }

  Future<Note> generateFromConversation(Conversation c, AppLanguage lang) async {
    final out = await _aiNote(NoteType.detailed, conversation: [for (final m in c.messages) '${m.role == ChatRole.user ? 'Student' : 'Tutor'}: ${m.text}'].join('\n')) ?? generator.fromConversation(c, lang);
    return create(
      title: out.title,
      body: out.body,
      type: NoteType.detailed,
      source: NoteSource.conversation,
      subjectId: c.context.subjectId,
      chapterId: c.context.chapterId,
      topicId: c.context.topicId,
      aiGenerated: true,
    );
  }

  Future<Note> generateFromUpload(String fileName, int bytes, AppLanguage lang) async {
    final out = generator.fromUpload(fileName, bytes, lang);
    return create(title: out.title, body: out.body, source: NoteSource.upload, tags: const ['upload'], aiGenerated: true);
  }

  List<Note> _seed() {
    final now = DateTime.now();
    return [
      Note(
        id: 'n-seed-1',
        title: 'গতির সমীকরণ — আমার নোট',
        body: '## তিনটি সমীকরণ\n\$\$v = u + at\$\$\n\$\$s = ut + \\tfrac12at^2\$\$\n\$\$v^2 = u^2 + 2as\$\$\n\n'
            '- কোন রাশি অজানা সেটা দেখে সমীকরণ বাছাই করব\n- মন্দন হলে ==a ঋণাত্মক==\n\n> পরীক্ষার আগে আবার দেখতে হবে',
        createdAt: now.subtract(const Duration(days: 4)),
        updatedAt: now.subtract(const Duration(days: 2)),
        type: NoteType.formulaSheet,
        subjectId: 'ssc-phy',
        chapterId: 'ssc-phy-p1-c2',
        folder: 'পদার্থবিজ্ঞান',
        tags: const ['formula', 'exam'],
        favorite: true,
        linkedIds: const ['n-seed-2'],
      ),
      Note(
        id: 'n-seed-2',
        title: 'নিউটনের সূত্র — সংক্ষেপে',
        body: '- **১ম সূত্র:** বল না থাকলে বস্তু নিজের অবস্থা বজায় রাখে (জড়তা)\n- **২য় সূত্র:** \$F = ma\$\n- **৩য় সূত্র:** ক্রিয়া = −প্রতিক্রিয়া\n\nউদাহরণ: বন্দুকের পশ্চাৎ বেগ',
        createdAt: now.subtract(const Duration(days: 3)),
        updatedAt: now.subtract(const Duration(days: 3)),
        type: NoteType.short,
        subjectId: 'ssc-phy',
        chapterId: 'ssc-phy-p1-c3',
        folder: 'পদার্থবিজ্ঞান',
        tags: const ['newton'],
        linkedIds: const ['n-seed-1'],
      ),
      Note(
        id: 'n-seed-3',
        title: 'Narration rules',
        body: '| Direct | Indirect |\n|---|---|\n| am/is | was |\n| will | would |\n| now | then |\n| today | that day |\n\nUniversal truth → tense unchanged.',
        createdAt: now.subtract(const Duration(days: 6)),
        updatedAt: now.subtract(const Duration(days: 5)),
        type: NoteType.revision,
        subjectId: 'ssc-eng2',
        chapterId: 'ssc-eng2-p1-c3',
        folder: 'English',
        tags: const ['grammar'],
      ),
    ];
  }
}

final notesProvider = NotifierProvider<NotesController, List<Note>>(NotesController.new);
