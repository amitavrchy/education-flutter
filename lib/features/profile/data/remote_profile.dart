import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../../curriculum/domain/curriculum_models.dart';
import '../domain/student_profile.dart';

/// The student's profile record (`/student-profiles/:id`) and the privacy switches the server
/// enforces for guardians and the leaderboard.
class RemoteProfile {
  RemoteProfile(this._api, this.studentId);

  final ApiClient _api;
  final String studentId;

  /// App privacy keys → the server profile's privacy fields. Other app keys stay on the device.
  static const privacyKeys = {
    'progress': 'shareProgressWithGuardian',
    'scores': 'shareScoresWithGuardian',
    'conversations': 'shareConversationsWithGuardian',
    'leaderboard': 'showOnLeaderboard',
  };

  static StudentProfile fromApi(Map<String, dynamic> j, StudentProfile current) => StudentProfile(
    name: j['name'] as String? ?? current.name,
    level: EducationLevel.fromCode(j['levelCode'] as String? ?? current.level.code),
    classYear: (j['grade'] as num?)?.round() ?? current.classYear,
    group: AcademicGroup.values.where((g) => g.name == j['group']).firstOrNull ?? current.group,
    medium: j['version'] == 'en' ? CurriculumMedium.english : CurriculumMedium.bangla,
    boardId: (j['boardId'] as String?)?.replaceFirst('brd-', '') ?? current.boardId,
    curriculumVersionId: j['curriculumVersionId'] as String? ?? current.curriculumVersionId,
    institution: j['institutionName'] as String? ?? current.institution,
    examYear: (j['examYear'] as num?)?.round() ?? current.examYear,
    targetGpa: (j['targetGpa'] as num?)?.toDouble() ?? current.targetGpa,
    dailyMinutes: (j['dailyMinutes'] as num?)?.round() ?? current.dailyMinutes,
    weakSubjectIds: [for (final s in j['weakSubjectIds'] as List? ?? const []) s as String],
    // A profile on the server means onboarding is done.
    onboarded: true,
  );

  static Map<String, bool> privacyFrom(Map<String, dynamic> j) {
    final p = (j['privacy'] as Map? ?? const {}).cast<String, dynamic>();
    return {
      for (final e in privacyKeys.entries)
        if (p[e.value] is bool) e.key: p[e.value] as bool,
    };
  }

  static Map<String, dynamic> toApi(StudentProfile p) => {
    'name': p.name,
    'levelCode': p.level.code,
    'grade': p.classYear,
    'group': p.group.name,
    'version': p.medium == CurriculumMedium.english ? 'en' : 'bn',
    'boardId': 'brd-${p.boardId}',
    'institutionName': p.institution,
    'examYear': p.examYear,
    'targetGpa': p.targetGpa,
    'dailyMinutes': p.dailyMinutes,
    'weakSubjectIds': p.weakSubjectIds,
  };

  /// Null when the account has no profile yet (a new student who hasn't onboarded).
  Future<Map<String, dynamic>?> load() async {
    try {
      return (await _api.get('/student-profiles/$studentId', parse: (d) => (d! as Map).cast<String, dynamic>())).data;
    } on ApiException catch (e) {
      if (e.statusCode == 404) return null;
      rethrow;
    }
  }

  Future<void> save(StudentProfile p, {required bool exists}) {
    final now = DateTime.now().toUtc().toIso8601String();
    return exists
        ? _api.patch('/student-profiles/$studentId', body: {...toApi(p), 'updatedAt': now}, parse: (d) => d)
        : _api.post('/student-profiles', body: {'id': studentId, ...toApi(p), 'subjectIds': <String>[], 'weakChapterIds': <String>[], 'createdAt': now, 'updatedAt': now}, parse: (d) => d);
  }

  Future<void> savePrivacy(Map<String, dynamic> serverPrivacy) =>
      _api.patch('/student-profiles/$studentId', body: {'privacy': serverPrivacy}, parse: (d) => d);
}
