import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/config/env.dart';
import '../../core/l10n/tr.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_exception.dart';
import '../../core/network/network_providers.dart';
import '../../mock/seed/curriculum_seed.dart';
import '../auth/application/auth_controller.dart';
import '../auth/domain/app_user.dart';
import '../planner/data/remote_tasks.dart';
import 'guardian_controller.dart';

/// Guardian portal on the education-backend: links via `/guardian/*`, the children's records
/// through the records API (the server only returns what each link may see; anything else is
/// a 404 and shows as empty), goals in the `guardianGoals:<guardianId>` document.
class RemoteGuardian {
  RemoteGuardian(this._api, this.guardianId);

  final ApiClient _api;
  final String guardianId;

  String get _goalsKey => 'guardianGoals:$guardianId';

  // ── Mapping ───────────────────────────────────────────────────────────

  static DateTime? _date(Object? v) => v is String ? DateTime.tryParse(v) : null;

  static GuardianLink linkFrom(Map<String, dynamic> j) {
    final perms = (j['permissions'] as Map? ?? const {}).cast<String, dynamic>();
    return GuardianLink(
      id: j['id'] as String,
      studentName: j['studentName'] as String? ?? '',
      relation: j['relation'] as String? ?? '',
      status: j['status'] == 'active' ? LinkStatus.active : LinkStatus.pending,
      permissions: {for (final k in ShareKey.values) k: perms[k.name] == true},
      linkedAt: _date(j['linkedAt']),
    );
  }

  static Tr _subjectName(String? id) => seedSubjects.where((s) => s.id == id).firstOrNull?.name ?? Tr.same(id ?? '');

  static TeacherNote noteFrom(Map<String, dynamic> j, String linkId) => TeacherNote(
    id: j['id'] as String,
    linkId: linkId,
    teacher: j['teacherName'] as String? ?? '',
    subject: _subjectName(j['subjectId'] as String?),
    message: j['text'] as String? ?? '',
    at: _date(j['at']) ?? DateTime.now(),
    acknowledged: j['acknowledged'] as bool? ?? false,
  );

  static GuardianGoal goalFrom(Map<String, dynamic> j, String linkId) => GuardianGoal(
    id: j['id'] as String,
    linkId: linkId,
    title: j['title'] as String? ?? '',
    metric: GoalMetric.values.where((m) => m.name == j['metric']).firstOrNull ?? GoalMetric.minutes,
    target: (j['target'] as num?)?.round() ?? 0,
    createdAt: _date(j['createdAt']) ?? DateTime.now(),
  );

  static Map<String, dynamic> goalToApi(GuardianGoal g, String studentId) => {
    'id': g.id,
    'studentId': studentId,
    'title': g.title,
    'metric': g.metric.name,
    'target': g.target,
    'current': 0,
    'period': 'weekly',
    'createdAt': g.createdAt.toUtc().toIso8601String(),
  };

  static DateTime _dayOf(DateTime d) => DateTime(d.year, d.month, d.day);

  static DateTime? _recordDay(Map<String, dynamic> r, String dateField, String atField) {
    final d = DateTime.tryParse(r[dateField] as String? ?? '') ?? _date(r[atField])?.toLocal();
    return d == null ? null : _dayOf(d);
  }

  /// One child's portal summary from `/guardian/children` plus the records the link may read.
  static ChildSummary summaryFrom(
    GuardianLink link,
    Map<String, dynamic> summary, {
    List<Map<String, dynamic>> activity = const [],
    List<Map<String, dynamic>> examAttempts = const [],
    List<Map<String, dynamic>> tasks = const [],
    List<Map<String, dynamic>> mastery = const [],
    List<Map<String, dynamic>> chapters = const [],
    List<Map<String, dynamic>> answers = const [],
    DateTime? now,
  }) {
    final today = _dayOf(now ?? DateTime.now());
    final weekStart = today.subtract(const Duration(days: 6));
    final minutes = List.filled(7, 0);
    for (final a in activity) {
      final d = _recordDay(a, 'date', 'at');
      if (d == null || d.isBefore(weekStart) || d.isAfter(today)) continue;
      minutes[d.difference(weekStart).inDays] += (a['minutes'] as num?)?.round() ?? 0;
    }
    final masteryOf = {for (final m in mastery) m['topicId'] as String: ((m['mastery'] as num?) ?? 0) / 100};
    final topics = {
      for (final s in seedSubjects)
        for (final c in s.chapters)
          for (final t in c.topics) t.id: (t.title, s.name),
    };
    final finished = [for (final a in examAttempts) if (a['result'] is Map) a]
      ..sort((a, b) => (b['submittedAt'] as String? ?? '').compareTo(a['submittedAt'] as String? ?? ''));
    bool thisWeek(DateTime? d) => d != null && !d.isBefore(weekStart);
    return ChildSummary(
      link: link,
      perms: link.permissions,
      weekMinutes: minutes,
      minutesPrevWeek: (summary['minutesPrevWeek'] as num?)?.round() ?? 0,
      tasksDone: (summary['tasksDone'] as num?)?.round() ?? 0,
      tasksMissed: (summary['tasksMissed'] as num?)?.round() ?? 0,
      avgScore: (summary['avgScore'] as num?)?.round(),
      streak: (summary['streak'] as num?)?.round() ?? 0,
      weakTopics: [
        for (final id in summary['weakTopicIds'] as List? ?? const [])
          if (topics[id] case final t?) (t.$1, t.$2, masteryOf[id] ?? 0.4),
      ],
      subjectMastery: [
        for (final s in summary['subjectMastery'] as List? ?? const [])
          (_subjectName((s as Map)['subjectId'] as String?), ((s['mastery'] as num?) ?? 0) / 100),
      ],
      results: [
        for (final a in finished)
          ExamLine(
            Tr.same(a['examTitle'] as String? ?? ''),
            (((a['result'] as Map)['percent'] as num?) ?? 0).round(),
            _date(a['submittedAt']) ?? _date(a['startedAt']) ?? today,
          ),
      ],
      calendar: [
        for (final t in tasks)
          if (TaskMapper.fromApi(t) case final task when !task.day.isBefore(weekStart) && !task.day.isAfter(today.add(const Duration(days: 7))))
            CalendarItem(task.day, task.title, task.minutes, task.status, startMinute: task.startMinute),
      ]..sort((a, b) => a.day.compareTo(b.day)),
      goalValues: {
        GoalMetric.minutes: minutes.fold(0, (a, b) => a + b),
        GoalMetric.exams: finished.where((a) => thisWeek(_date(a['submittedAt'])?.toLocal())).length,
        GoalMetric.chapters: chapters.where((c) => thisWeek(_date(c['completedAt'])?.toLocal())).length,
        GoalMetric.questions: answers.where((a) => thisWeek(_date(a['answeredAt'])?.toLocal())).length,
      },
    );
  }

  // ── Requests ──────────────────────────────────────────────────────────

  List<Map<String, dynamic>> _list(Object? d) => [for (final x in d! as List) (x as Map).cast<String, dynamic>()];
  Map<String, dynamic> _map(Object? d) => (d! as Map).cast<String, dynamic>();

  /// Links other than revoked ones.
  Future<List<Map<String, dynamic>>> links() async =>
      [for (final l in (await _api.get('/guardian/links', parse: _list)).data) if (l['status'] != 'revoked') l];

  Future<List<Map<String, dynamic>>> children() async => (await _api.get('/guardian/children', parse: _list)).data;

  /// A child's records in [collection]; empty when the link may not see them.
  Future<List<Map<String, dynamic>>> records(String collection, String studentId) async {
    try {
      return (await _api.get('/$collection/$studentId', query: {'all': true}, parse: _list)).data;
    } on ApiException catch (e) {
      if (e.statusCode == 404 || e.statusCode == 403) return const [];
      rethrow;
    }
  }

  Future<ChildSummary> childSummary(GuardianLink link, String studentId, Map<String, dynamic> summary) async {
    final r = await Future.wait([
      records('activity', studentId),
      records('exam-attempts', studentId),
      records('tasks', studentId),
      records('mastery', studentId),
      records('chapter-progress', studentId),
      records('attempts', studentId),
    ]);
    return summaryFrom(link, summary, activity: r[0], examAttempts: r[1], tasks: r[2], mastery: r[3], chapters: r[4], answers: r[5]);
  }

  Future<List<Map<String, dynamic>>> feedback() async => (await _api.get('/teacher-feedback', query: {'all': true}, parse: _list)).data;

  Future<void> acknowledge(String feedbackId) => _api.patch('/teacher-feedback/$feedbackId', body: {'acknowledged': true}, parse: (d) => d);

  Future<void> reply(String feedbackId, String message) => _api.post('/guardian/feedback/$feedbackId/reply', body: {'message': message}, parse: (d) => d);

  /// Step 1: the student's code → a pending link and the verification challenge.
  Future<({Map<String, dynamic> link, String challengeId})> requestLink(String code, String relation) async {
    final r = (await _api.post('/guardian/links', body: {'code': code.trim().toUpperCase(), 'relation': relation}, parse: _map)).data;
    return (link: (r['link'] as Map).cast<String, dynamic>(), challengeId: (r['pending'] as Map)['challengeId'] as String);
  }

  Future<Map<String, dynamic>> confirmLink(String linkId, String challengeId, String code) async =>
      (await _api.post('/guardian/links/$linkId/confirm', body: {'challengeId': challengeId, 'code': code.trim()}, parse: _map)).data;

  Future<void> unlink(String linkId) => _api.post('/guardian/links/$linkId/unlink', parse: (d) => d);

  Future<void> setPermissions(String linkId, Map<ShareKey, bool> perms) =>
      _api.patch('/guardian-links/$linkId', body: {'permissions': {for (final e in perms.entries) e.key.name: e.value}}, parse: (d) => d);

  Future<List<Map<String, dynamic>>> goals() async {
    final doc = (await _api.get('/documents/$_goalsKey', parse: (d) => d == null ? const <String, dynamic>{} : _map(d))).data;
    return [for (final g in doc['items'] as List? ?? const []) (g as Map).cast<String, dynamic>()];
  }

  Future<void> saveGoals(List<Map<String, dynamic>> items) => _api.put('/documents/$_goalsKey', body: {'id': 'goals', 'items': items}, parse: (d) => d);
}

/// The signed-in guardian's server data (API mode); null with the mock or for other roles.
final remoteGuardianProvider = Provider<RemoteGuardian?>((ref) {
  if (Env.useMockApi) return null;
  final auth = ref.watch(authControllerProvider);
  if (auth is! Authenticated || auth.user.role != UserRole.parent) return null;
  return RemoteGuardian(ref.watch(apiClientProvider), auth.user.id);
});

/// The code a student shares with a guardian: issued by the server in API mode
/// (`POST /guardian/link-code`, valid for a limited time), the demo code otherwise.
final studentLinkCodeProvider = FutureProvider<String>((ref) async {
  if (Env.useMockApi) return demoLinkCode;
  final auth = ref.watch(authControllerProvider);
  if (auth is! Authenticated || auth.user.role != UserRole.student) return demoLinkCode;
  final res = await ref.watch(apiClientProvider).post('/guardian/link-code', parse: (d) => (d! as Map)['code'] as String);
  return res.data;
});
