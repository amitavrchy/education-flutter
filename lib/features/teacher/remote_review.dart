import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/config/env.dart';
import '../../core/network/api_client.dart';
import '../../core/network/network_providers.dart';
import '../auth/application/auth_controller.dart';
import '../auth/domain/app_user.dart';
import '../question_bank/data/question_mapper.dart';
import '../question_bank/domain/question.dart';
import 'review_data.dart';

/// Content review on the education-backend (`/review-items`, `/rubrics`). The server enforces
/// the workflow and who may make each move; every action returns the updated item.
class RemoteReview {
  RemoteReview(this._api);

  final ApiClient _api;

  // ── Mapping ───────────────────────────────────────────────────────────

  static const _statuses = {
    'draft': ContentStatus.draft,
    'submitted': ContentStatus.submitted,
    'in_review': ContentStatus.inReview,
    'changes_requested': ContentStatus.changesRequested,
    'approved': ContentStatus.approved,
    'published': ContentStatus.published,
    'archived': ContentStatus.archived,
  };

  static ContentStatus statusOf(String? s) => _statuses[s] ?? ContentStatus.draft;

  static String serverStatus(ContentStatus s) => _statuses.entries.firstWhere((e) => e.value == s).key;

  static const _kinds = {
    'question': ReviewKind.question,
    'ai_answer': ReviewKind.aiAnswer,
    'chapter': ReviewKind.chapter,
    'board_paper': ReviewKind.boardPaper,
    'institution_paper': ReviewKind.institutionPaper,
    'rubric': ReviewKind.rubric,
    'book': ReviewKind.book,
    'note': ReviewKind.note,
  };

  static ActorRole roleOf(String? r) => switch (r) {
    'content_reviewer' || 'reviewer' => ActorRole.reviewer,
    'content_manager' || 'manager' || 'platform_admin' || 'super_admin' => ActorRole.manager,
    _ => ActorRole.teacher,
  };

  static Actor actorFrom(Object? a) {
    final m = (a as Map? ?? const {}).cast<String, dynamic>();
    return Actor(m['name'] as String? ?? '', roleOf(m['role'] as String?));
  }

  static DateTime _date(Object? v) => (v is String ? DateTime.tryParse(v) : null) ?? DateTime.now();

  static ReviewItem itemFrom(Map<String, dynamic> j) => ReviewItem(
    id: j['id'] as String,
    kind: _kinds[j['contentType']] ?? ReviewKind.question,
    title: j['title'] as String? ?? '',
    subjectId: j['subjectId'] as String? ?? '',
    status: statusOf(j['status'] as String?),
    priority: ReviewPriority.values.where((p) => p.name == j['priority']).firstOrNull ?? ReviewPriority.normal,
    submittedBy: actorFrom(j['submittedBy']),
    preview: j['preview'] as String? ?? '',
    history: [
      for (final h in j['history'] as List? ?? const [])
        ReviewEvent(
          _date((h as Map)['at']),
          h['from'] == null ? null : statusOf(h['from'] as String),
          statusOf(h['to'] as String?),
          actorFrom(h['by']),
          note: h['note'] as String?,
        ),
      if ((j['history'] as List? ?? const []).isEmpty) ReviewEvent(_date(j['createdAt']), null, statusOf(j['status'] as String?), actorFrom(j['submittedBy'])),
    ],
    contentId: j['contentId'] as String?,
    assignedTo: j['assignedTo'] == null ? null : actorFrom(j['assignedTo']),
    dueAt: j['dueAt'] == null ? null : _date(j['dueAt']),
    comments: [for (final c in j['comments'] as List? ?? const []) ReviewComment(actorFrom((c as Map)['author']), c['text'] as String? ?? '', _date(c['at']))],
    suggestions: [
      for (final s in j['suggestions'] as List? ?? const [])
        Suggestion(
          id: (s as Map)['id'] as String,
          from: s['from'] as String? ?? '',
          to: s['to'] as String? ?? '',
          by: actorFrom(s['by']),
          at: _date(s['at']),
          state: SuggestionState.values.where((x) => x.name == s['state']).firstOrNull ?? SuggestionState.open,
        ),
    ],
  );

  static Rubric rubricFrom(Map<String, dynamic> j) => Rubric(
    id: j['id'] as String,
    name: j['name'] as String? ?? '',
    // Speaking rubrics have no app counterpart; they show as essay rubrics.
    use: RubricUse.values.where((u) => u.name == j['appliesTo']).firstOrNull ?? RubricUse.essay,
    criteria: [
      for (final c in j['criteria'] as List? ?? const [])
        RubricCriterion((c as Map)['criterion'] as String? ?? '', ((c['marks'] as num?) ?? 0).toDouble(), c['description'] as String? ?? ''),
    ],
    status: statusOf(j['status'] as String?),
    owner: j['owner'] as String? ?? '',
    subjectId: j['subjectId'] as String?,
  );

  static Map<String, dynamic> rubricToApi(Rubric r) {
    final now = DateTime.now().toUtc().toIso8601String();
    return {
      'id': r.id,
      'name': r.name,
      'subjectId': ?r.subjectId,
      'appliesTo': r.use.name,
      'criteria': [for (final c in r.criteria) {'criterion': c.criterion, 'marks': c.marks, 'description': c.description}],
      'status': serverStatus(r.status),
      'owner': r.owner,
      'createdAt': now,
      'updatedAt': now,
    };
  }

  // ── Requests ──────────────────────────────────────────────────────────

  List<Map<String, dynamic>> _list(Object? d) => [for (final x in d! as List) (x as Map).cast<String, dynamic>()];
  ReviewItem _item(Object? d) => itemFrom((d! as Map).cast<String, dynamic>());

  Future<List<ReviewItem>> items() async => [for (final i in (await _api.get('/review-items', query: {'all': true}, parse: _list)).data) itemFrom(i)];

  Future<List<Rubric>> rubrics() async => [for (final r in (await _api.get('/rubrics', query: {'all': true}, parse: _list)).data) rubricFrom(r)];

  Future<ReviewItem> transition(String id, ContentStatus to, {String? note}) async =>
      (await _api.post('/review-items/$id/transition', body: {'to': serverStatus(to), 'note': ?note}, parse: _item)).data;

  Future<ReviewItem> comment(String id, String text) async => (await _api.post('/review-items/$id/comments', body: {'text': text}, parse: _item)).data;

  Future<ReviewItem> suggest(String id, String from, String to) async =>
      (await _api.post('/review-items/$id/suggestions', body: {'field': 'preview', 'from': from, 'to': to}, parse: _item)).data;

  Future<ReviewItem> resolve(String id, String suggestionId, {required bool accept}) async =>
      (await _api.post('/review-items/$id/suggestions/$suggestionId/resolve', body: {'accept': accept}, parse: _item)).data;

  Future<void> saveQuestion(Question q, {required bool submit}) =>
      _api.post('/review-items/questions', body: {'question': questionToApi(q), 'submit': submit}, parse: (d) => d);

  Future<void> createRubric(Rubric r) => _api.post('/rubrics', body: rubricToApi(r), parse: (d) => d);

  Future<void> updateRubric(Rubric r) {
    final body = rubricToApi(r)..remove('createdAt');
    return _api.patch('/rubrics/${r.id}', body: body, parse: (d) => d);
  }

  Future<void> deleteRubric(String id) => _api.sendNoContent('DELETE', '/rubrics/$id');
}

/// Content review for the signed-in teacher or reviewer (API mode); null with the mock.
final remoteReviewProvider = Provider<RemoteReview?>((ref) {
  if (Env.useMockApi) return null;
  final auth = ref.watch(authControllerProvider);
  if (auth is! Authenticated || auth.user.role != UserRole.teacher) return null;
  return RemoteReview(ref.watch(apiClientProvider));
});
