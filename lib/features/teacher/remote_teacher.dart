import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/config/env.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_exception.dart';
import '../../core/network/network_providers.dart';
import '../../mock/seed/curriculum_seed.dart';
import '../auth/application/auth_controller.dart';
import '../auth/domain/app_user.dart';
import 'teacher_data.dart';

/// What the teacher portal needs from the server, already in the app's shapes, plus the ids
/// the app has to send back (it works with student names, the server with ids).
class TeacherSnapshot {
  const TeacherSnapshot({
    required this.classes,
    required this.state,
    required this.studentIds,
    required this.submissionIds,
    required this.evaluationOwners,
    required this.institutionId,
  });

  final List<TeacherClass> classes;
  final TeacherState state;

  /// Student name → user id (only students with an account).
  final Map<String, String> studentIds;

  /// `assignmentId/studentName` → submission id.
  final Map<String, String> submissionIds;

  /// Evaluation id → the student's user id.
  final Map<String, String> evaluationOwners;
  final String? institutionId;
}

/// Teacher portal on the education-backend: classes from class groups and institution members,
/// assignments and submissions, answer-script evaluations, shared resources and feedback.
class RemoteTeacher {
  RemoteTeacher(this._api, {required this.teacherId, required this.teacherName});

  final ApiClient _api;
  final String teacherId;
  final String teacherName;

  // ── Mapping ───────────────────────────────────────────────────────────

  static const _bnDigits = ['০', '১', '২', '৩', '৪', '৫', '৬', '৭', '৮', '৯'];
  static String _bn(int n) => n.toString().split('').map((d) => _bnDigits[int.parse(d)]).join();

  static String subjectName(String id) => seedSubjects.where((s) => s.id == id).firstOrNull?.name.bn ?? id;

  static DateTime? _date(Object? v) => v is String ? DateTime.tryParse(v) : null;

  static String classIdOf(String groupId, String subjectId) => '$groupId:$subjectId';

  /// One class per (class group, subject the teacher teaches there).
  static List<TeacherClass> classesFrom(List<Map<String, dynamic>> groups, Map<String, String> memberNames, List<String> teacherSubjects) {
    final out = <TeacherClass>[];
    for (final g in groups) {
      final subjects = [for (final s in g['subjectIds'] as List? ?? const []) s as String];
      final taught = teacherSubjects.isEmpty ? subjects.take(1) : subjects.where(teacherSubjects.contains);
      final students = [
        for (final id in g['studentIds'] as List? ?? const []) ?memberNames[id],
      ];
      for (final s in taught) {
        out.add(TeacherClass(
          classIdOf(g['id'] as String, s),
          '${_bn((g['grade'] as num?)?.round() ?? 10)}ম শ্রেণি (${g['section'] ?? ''}) — ${subjectName(s)}',
          s,
          students,
        ));
      }
    }
    return out;
  }

  static WorkStatus _workStatus(String? s) => switch (s) {
    'late' => WorkStatus.late,
    'pending' || null => WorkStatus.missing,
    _ => WorkStatus.submitted,
  };

  static Assignment assignmentFrom(Map<String, dynamic> a, List<TeacherClass> classes, List<Map<String, dynamic>> submissions) {
    final group = (a['classGroupIds'] as List? ?? const []).cast<String>().firstOrNull ?? '';
    final subject = a['subjectId'] as String? ?? '';
    final cls = classes.where((c) => c.id == classIdOf(group, subject)).firstOrNull ?? classes.where((c) => c.id.startsWith('$group:')).firstOrNull;
    final mine = [for (final s in submissions) if (s['assignmentId'] == a['id']) s];
    final byName = {for (final s in mine) s['studentName'] as String? ?? '': s};
    final names = {...?cls?.students, ...byName.keys};
    final grades = <String, double>{
      for (final s in mine)
        if (s['marks'] is num) s['studentName'] as String: (s['marks'] as num).toDouble(),
    };
    final feedback = <String, String>{
      for (final s in mine)
        if (s['feedback'] is String) s['studentName'] as String: s['feedback'] as String,
    };
    return Assignment(
      id: a['id'] as String,
      classId: cls?.id ?? classIdOf(group, subject),
      title: a['title'] as String? ?? '',
      dueAt: _date(a['dueAt']) ?? DateTime.now(),
      questionIds: const [],
      submitted: mine.where((s) => s['status'] != 'pending').length,
      grades: grades,
      feedback: feedback,
      instructions: a['instructions'] as String? ?? '',
      total: (a['totalMarks'] as num?)?.round() ?? 10,
      serverWork: [
        for (final n in names)
          StudentWork(n, _workStatus(byName[n]?['status'] as String?), _date(byName[n]?['submittedAt']), grade: grades[n], feedback: feedback[n]),
      ],
    );
  }

  /// Answer scripts students sent for teacher review (earlier stages are still processing).
  static Submission? submissionFrom(Map<String, dynamic> e, String classId) {
    final stage = e['stage'] as String?;
    if (stage == 'uploaded' || stage == 'processing') return null;
    final rubric = [for (final r in e['rubric'] as List? ?? const []) (r as Map).cast<String, dynamic>()];
    final teacherMarks = (e['officialMarks'] ?? e['teacherMarks']) as num?;
    return Submission(
      id: e['id'] as String,
      student: e['studentName'] as String? ?? '',
      classId: classId,
      title: e['title'] as String? ?? '',
      aiMarks: ((e['aiMarks'] as num?) ?? 0).toDouble(),
      total: (e['maxMarks'] as num?)?.round() ?? 10,
      pages: (e['pages'] as List? ?? const []).length.clamp(1, 20),
      finalMarks: teacherMarks?.toDouble(),
      feedback: e['teacherComment'] as String?,
      reviewedAt: teacherMarks == null ? null : _date(e['updatedAt']),
      official: stage == 'official',
      criterionMarks: [
        for (final r in rubric)
          if (r['teacher'] is num) (r['teacher'] as num).toDouble(),
      ],
      requested: stage != 'ai_estimated',
    );
  }

  static String _materialKind(String? k) => switch (k) {
    'video_link' => 'video',
    'pdf' || 'slide' || 'worksheet' || 'image' => 'pdf',
    _ => 'link',
  };

  static TeachingMaterial materialFrom(Map<String, dynamic> r, List<TeacherClass> classes) {
    final subject = r['subjectId'] as String?;
    final cls = classes.where((c) => c.subjectId == subject).firstOrNull ?? classes.firstOrNull;
    return TeachingMaterial(r['id'] as String, cls?.id ?? '', r['title'] as String? ?? '', _materialKind(r['kind'] as String?), _date(r['createdAt']) ?? DateTime.now());
  }

  // ── Requests ──────────────────────────────────────────────────────────

  List<Map<String, dynamic>> _list(Object? d) => [for (final x in d! as List) (x as Map).cast<String, dynamic>()];

  Future<List<Map<String, dynamic>>> _all(String path) async {
    try {
      return (await _api.get(path, query: {'all': true}, parse: _list)).data;
    } on ApiException catch (e) {
      if (e.statusCode == 404 || e.statusCode == 403) return const [];
      rethrow;
    }
  }

  Future<TeacherSnapshot> load() async {
    final r = await Future.wait([
      _all('/class-groups'),
      _all('/institution-members'),
      _all('/teacher-profiles'),
      _all('/assignments'),
      _all('/submissions'),
      _all('/institution-resources'),
      _all('/teacher-feedback'),
    ]);
    final (groups, members, profiles, assignments, submissions, resources, feedback) = (r[0], r[1], r[2], r[3], r[4], r[5], r[6]);
    final memberNames = {for (final m in members) m['id'] as String: m['name'] as String? ?? ''};
    final studentIds = {
      for (final m in members)
        if (m['kind'] == 'student' && m['userId'] is String) m['name'] as String: m['userId'] as String,
    };
    final namesById = {for (final e in studentIds.entries) e.value: e.key};
    final profile = profiles.where((p) => p['userId'] == teacherId).firstOrNull;
    final teacherSubjects = [for (final s in profile?['subjectIds'] as List? ?? const []) s as String];
    final classes = classesFrom(groups, memberNames, teacherSubjects);

    // Answer scripts of the students in the teacher's classes who have an account.
    final evaluations = <String, List<Map<String, dynamic>>>{};
    await Future.wait([
      for (final sid in studentIds.values) _all('/evaluations/$sid').then((list) => evaluations[sid] = list),
    ]);
    final owners = <String, String>{};
    final scripts = <Submission>[];
    for (final MapEntry(key: sid, value: list) in evaluations.entries) {
      final name = namesById[sid] ?? '';
      for (final e in list) {
        final cls = classes.where((c) => c.subjectId == e['subjectId'] && c.students.contains(name)).firstOrNull ??
            classes.where((c) => c.students.contains(name)).firstOrNull;
        if (submissionFrom(e, cls?.id ?? '') case final s?) {
          scripts.add(s);
          owners[s.id] = sid;
        }
      }
    }

    return TeacherSnapshot(
      classes: classes,
      state: TeacherState(
        assignments: [for (final a in assignments) assignmentFrom(a, classes, submissions)]..sort((a, b) => b.dueAt.compareTo(a.dueAt)),
        submissions: scripts,
        materials: [for (final m in resources) materialFrom(m, classes)],
        notes: [
          for (final f in feedback)
            StudentNote(f['id'] as String, namesById[f['studentId']] ?? '', f['text'] as String? ?? '', _date(f['at']) ?? DateTime.now()),
        ],
      ),
      studentIds: studentIds,
      submissionIds: {
        for (final s in submissions) '${s['assignmentId']}/${s['studentName']}': s['id'] as String,
      },
      evaluationOwners: owners,
      institutionId: groups.firstOrNull?['institutionId'] as String?,
    );
  }

  Future<void> createAssignment(Assignment a, {String? institutionId}) {
    final now = DateTime.now().toUtc().toIso8601String();
    final parts = a.classId.split(':');
    return _api.post('/assignments', body: {
      'id': a.id,
      'title': a.title,
      'instructions': a.instructions,
      'subjectId': parts.length > 1 ? parts[1] : '',
      'institutionId': ?institutionId,
      'teacherId': teacherId,
      'teacherName': teacherName,
      'classGroupIds': [parts.first],
      'studentIds': <String>[],
      'dueAt': a.dueAt.toUtc().toIso8601String(),
      'totalMarks': a.total,
      'status': 'assigned',
      'attachments': <Object>[],
      'createdAt': now,
      'updatedAt': now,
    }, parse: (d) => d);
  }

  Future<void> gradeSubmission(String submissionId, double marks, String feedback) => _api.patch('/submissions/$submissionId', body: {
    'marks': marks,
    'feedback': feedback,
    'status': 'graded',
    'gradedBy': teacherName,
  }, parse: (d) => d);

  /// Teacher review of an answer script; [official] publishes final marks.
  Future<void> reviewEvaluation(String studentId, String evaluationId, double marks, String comment, {bool official = false}) =>
      _api.patch('/evaluations/$studentId/$evaluationId', body: {
        'teacherMarks': marks,
        'teacherComment': comment,
        'reviewerName': teacherName,
        'stage': official ? 'official' : 'teacher_reviewed',
        'officialMarks': ?(official ? marks : null),
      }, parse: (d) => d);

  Future<void> createResource(TeachingMaterial m, {String? institutionId, String? subjectId}) {
    final now = DateTime.now().toUtc().toIso8601String();
    return _api.post('/institution-resources', body: {
      'id': m.id,
      'title': m.title,
      'kind': m.kind == 'pdf' ? 'pdf' : 'video_link',
      'subjectId': ?subjectId,
      'institutionId': ?institutionId,
      'sizeKb': 0,
      'visibility': 'students',
      'uploadedBy': teacherName,
      'downloads': 0,
      'createdAt': now,
      'updatedAt': now,
    }, parse: (d) => d);
  }

  Future<void> sendFeedback(String studentId, String subjectId, String text, String id) => _api.post('/teacher-feedback', body: {
    'id': id,
    'studentId': studentId,
    'teacherId': teacherId,
    'teacherName': teacherName,
    'subjectId': subjectId,
    'text': text,
    'kind': 'suggestion',
    'at': DateTime.now().toUtc().toIso8601String(),
    'acknowledged': false,
  }, parse: (d) => d);
}

/// The signed-in teacher's server data (API mode); null with the mock or for other roles.
final remoteTeacherProvider = Provider<RemoteTeacher?>((ref) {
  if (Env.useMockApi) return null;
  final auth = ref.watch(authControllerProvider);
  if (auth is! Authenticated || auth.user.role != UserRole.teacher) return null;
  return RemoteTeacher(ref.watch(apiClientProvider), teacherId: auth.user.id, teacherName: auth.user.name);
});
