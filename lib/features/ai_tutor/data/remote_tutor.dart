import '../../../core/l10n/tr.dart';
import '../../../core/network/api_client.dart';
import '../../curriculum/domain/curriculum_models.dart';
import '../domain/tutor_models.dart';

/// Tutor conversations on the education-backend. The server answers (and stores both
/// messages); conversations, folders and message flags use the generic records API.
class RemoteTutor {
  RemoteTutor(this._api, this.studentId);

  final ApiClient _api;
  final String studentId;

  // ── Mapping ───────────────────────────────────────────────────────────

  static const _modes = {
    'simple': TeachingMode.simple,
    'socratic': TeachingMode.socratic,
    'board': TeachingMode.boardAnswer,
    'revision': TeachingMode.quickRevision,
    'stepwise': TeachingMode.stepByStep,
    'deep': TeachingMode.deepConcept,
    'practice': TeachingMode.practice,
    'oral': TeachingMode.oralExam,
    'formula': TeachingMode.formula,
    'english': TeachingMode.englishCoach,
  };

  static TeachingMode modeOf(String? m) => _modes[m] ?? TeachingMode.simple;

  static String serverMode(TeachingMode m) => _modes.entries.firstWhere((e) => e.value == m).key;

  static const _warnings = {
    'low_confidence': AnswerWarning.lowConfidence,
    'missing_kb': AnswerWarning.missingKnowledge,
    'conflicting_sources': AnswerWarning.conflictingSources,
    'old_curriculum': AnswerWarning.oldCurriculum,
    'integrity': AnswerWarning.integrity,
    'safety': AnswerWarning.offTopic,
  };

  static DateTime _date(Object? v) => (v is String ? DateTime.tryParse(v) : null) ?? DateTime.now();

  static TutorContext contextFrom(Map<String, dynamic> c) => TutorContext(
    level: EducationLevel.fromCode(c['levelCode'] as String? ?? 'SSC'),
    classYear: (c['grade'] as num?)?.round() ?? 10,
    subjectId: c['subjectId'] as String?,
    paper: int.tryParse(RegExp(r'(\d+)$').firstMatch(c['paperId'] as String? ?? '')?[1] ?? ''),
    chapterId: c['chapterId'] as String?,
    topicId: c['topicId'] as String?,
    curriculumVersionId: c['curriculumVersionId'] as String? ?? 'nctb-2025',
    language: TutorLanguage.values.where((l) => l.name == c['language']).firstOrNull ?? TutorLanguage.bn,
    mode: modeOf(c['mode'] as String?),
  );

  static Map<String, dynamic> contextToApi(TutorContext c) => {
    'levelCode': c.level.code,
    'grade': c.classYear,
    'subjectId': ?c.subjectId,
    'chapterId': ?c.chapterId,
    'topicId': ?c.topicId,
    'curriculumVersionId': c.curriculumVersionId,
    'language': c.language.name,
    'mode': serverMode(c.mode),
  };

  /// `psg-ssc-math-c3-t3` → the library book of `ssc-math`.
  static String bookOf(String passageId) => 'book-${passageId.replaceFirst('psg-', '').replaceFirst(RegExp(r'-c\d+(-.*)?$'), '')}';

  static SourceRef sourceFrom(Map<String, dynamic> c) => SourceRef(
    id: c['id'] as String? ?? c['passageId'] as String? ?? '',
    bookId: bookOf(c['passageId'] as String? ?? ''),
    bookTitle: Tr.same(c['bookTitle'] as String? ?? ''),
    chapterTitle: Tr.same(c['chapterTitle'] as String? ?? ''),
    page: (c['page'] as num?)?.round() ?? 0,
    excerpt: Tr.same(c['excerpt'] as String? ?? ''),
    curriculumVersionId: c['curriculumVersionId'] as String? ?? '',
    score: (c['score'] as num?)?.toDouble() ?? 0,
  );

  static ChatMessage messageFrom(Map<String, dynamic> m) => ChatMessage(
    id: m['id'] as String,
    role: m['role'] == 'user' ? ChatRole.user : ChatRole.assistant,
    text: m['content'] as String? ?? '',
    createdAt: _date(m['createdAt']),
    status: m['status'] == 'error' ? MessageStatus.error : MessageStatus.done,
    mode: m['mode'] == null ? null : modeOf(m['mode'] as String),
    sources: [for (final c in m['citations'] as List? ?? const []) sourceFrom((c as Map).cast<String, dynamic>())],
    grounding: Grounding.values.where((g) => g.name == m['grounding']).firstOrNull,
    confidence: (m['confidence'] as num?)?.toDouble(),
    followUps: [for (final f in m['followUps'] as List? ?? const []) f as String],
    relatedQuestionIds: [for (final q in m['relatedQuestionIds'] as List? ?? const []) q as String],
    warnings: [for (final w in m['warnings'] as List? ?? const []) ?_warnings[w]],
    feedback: switch (m['feedback']) {
      'up' => 1,
      'down' => -1,
      _ => null,
    },
    bookmarked: m['bookmarked'] as bool? ?? false,
    reported: m['reported'] as bool? ?? false,
    teacherReview: m['teacherReviewRequested'] as bool? ?? false,
    editedAt: m['editedAt'] == null ? null : _date(m['editedAt']),
    error: m['status'] == 'error' ? 'UPSTREAM_ERROR' : null,
  );

  /// [messages] are the conversation's records; [folders] maps folder ids to names.
  static Conversation conversationFrom(Map<String, dynamic> c, List<Map<String, dynamic>> messages, Map<String, String> folders) {
    final sorted = [...messages]..sort((a, b) => (a['createdAt'] as String? ?? '').compareTo(b['createdAt'] as String? ?? ''));
    return Conversation(
      id: c['id'] as String,
      title: c['title'] as String? ?? '',
      createdAt: _date(c['createdAt']),
      updatedAt: _date(c['updatedAt'] ?? c['createdAt']),
      context: contextFrom((c['context'] as Map? ?? const {}).cast<String, dynamic>()),
      messages: [for (final m in sorted) messageFrom(m)],
      pinned: c['pinned'] as bool? ?? false,
      archived: c['archived'] as bool? ?? false,
      folder: folders[c['folderId']],
    );
  }

  /// A new conversation record in the web's shape.
  static Map<String, dynamic> newConversation(Conversation c, {String? folderId}) => {
    'id': c.id,
    'title': c.title.isEmpty ? 'নতুন কথোপকথন' : c.title,
    'context': contextToApi(c.context),
    'folderId': ?folderId,
    'pinned': c.pinned,
    'archived': c.archived,
    'messageCount': 0,
    'lastMessagePreview': '',
    'share': {'enabled': false, 'includeName': false},
    'createdAt': c.createdAt.toUtc().toIso8601String(),
    'updatedAt': c.updatedAt.toUtc().toIso8601String(),
  };

  // ── Requests ──────────────────────────────────────────────────────────

  List<Map<String, dynamic>> _list(Object? d) => [for (final x in d! as List) (x as Map).cast<String, dynamic>()];
  Map<String, dynamic> _map(Object? d) => (d! as Map).cast<String, dynamic>();

  Future<List<Map<String, dynamic>>> _all(String collection) async =>
      (await _api.get('/$collection/$studentId', query: {'all': true}, parse: _list)).data;

  /// Conversations with their messages, and folder names by id.
  Future<({List<Conversation> conversations, Map<String, String> folders})> load() async {
    final (convos, messages, folders) = await (_all('conversations'), _all('messages'), _all('folders')).wait;
    final names = {for (final f in folders) f['id'] as String: f['name'] as String? ?? ''};
    final byConvo = <String, List<Map<String, dynamic>>>{};
    for (final m in messages) {
      (byConvo[m['conversationId'] as String? ?? ''] ??= []).add(m);
    }
    return (conversations: [for (final c in convos) conversationFrom(c, byConvo[c['id']] ?? const [], names)], folders: names);
  }

  Future<void> createConversation(Conversation c, {String? folderId}) =>
      _api.post('/conversations/$studentId', body: newConversation(c, folderId: folderId), parse: (d) => d);

  Future<void> updateConversation(String id, Map<String, dynamic> fields) => _api.patch('/conversations/$studentId/$id', body: fields, parse: (d) => d);

  Future<void> deleteConversation(String id) => _api.sendNoContent('DELETE', '/conversations/$studentId/$id');

  Future<String> createFolder(String name) async {
    final id = 'fld-${DateTime.now().microsecondsSinceEpoch}';
    await _api.post('/folders/$studentId', body: {'id': id, 'name': name, 'color': '#2563eb', 'createdAt': DateTime.now().toUtc().toIso8601String()}, parse: (d) => d);
    return id;
  }

  /// Asks the tutor; the server stores and returns both messages.
  Future<({ChatMessage? user, ChatMessage assistant})> send(String conversationId, String content, {String? replaceFromMessageId}) async {
    final r = (await _api.post('/tutor/$studentId/conversations/$conversationId/messages', body: {
      'content': content,
      'replaceFromMessageId': ?replaceFromMessageId,
    }, parse: _map)).data;
    return (
      user: r['user'] is Map ? messageFrom((r['user'] as Map).cast<String, dynamic>()) : null,
      assistant: messageFrom((r['assistant'] as Map).cast<String, dynamic>()),
    );
  }

  Future<ChatMessage> regenerate(String assistantId) async =>
      messageFrom((await _api.post('/tutor/$studentId/messages/$assistantId/regenerate', parse: _map)).data);

  Future<void> report(String messageId, String reason) => _api.post('/tutor/$studentId/messages/$messageId/report', body: {'reason': reason}, parse: (d) => d);

  Future<void> updateMessage(String id, Map<String, dynamic> fields) => _api.patch('/messages/$studentId/$id', body: fields, parse: (d) => d);
}
