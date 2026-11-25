import '../../features/auth/domain/app_user.dart';

/// Every route path in the app. Screens never build paths by hand.
abstract final class AppRoutes {
  static const String splash = '/splash';
  static const String login = '/login';
  static const String unsupportedRole = '/unsupported-role';
  static const String welcome = '/welcome';
  static const String register = '/register';
  static const String verifyOtp = '/verify-otp';
  static const String forgotPassword = '/forgot-password';
  static const String resetPassword = '/reset-password';
  static const String sessionExpired = '/session-expired';
  static const String consent = '/consent';

  /// Screens a signed-out visitor may open.
  static const Set<String> publicRoutes = {login, welcome, register, verifyOtp, forgotPassword, resetPassword, sessionExpired};
  static const String notifications = '/notifications';
  static const String notificationPrefs = '/notifications/preferences';
  static const String settings = '/settings';
  static const String search = '/search';
  static const String profile = '/profile';

  /// Landing tab of a role's portal, e.g. /student/home.
  static String portalHome(UserRole role) => '/${role.pathSegment}/home';

  // Context-carrying deep links (query parameters are optional filters).
  static String _q(String path, Map<String, String?> params) {
    final q = {
      for (final e in params.entries)
        if (e.value != null) e.key: e.value!,
    };
    return q.isEmpty ? path : Uri(path: path, queryParameters: q).toString();
  }

  // ── Student: Learn tab (nested so the bottom bar stays visible) ──
  static const String learn = '/student/learn';
  static String subject(String id) => '$learn/subject/$id';
  static String chapter(String id) => '$learn/chapter/$id';
  static String topic(String id) => '$learn/topic/$id';

  // ── Student: AI tutor tab ──
  static const String tutorTab = '/student/ai-tutor';
  static String tutor({String? subjectId, String? chapterId, String? topicId, String? prompt}) =>
      _q(tutorTab, {'subject': subjectId, 'chapter': chapterId, 'topic': topicId, 'prompt': prompt});
  static String tutorChat(String conversationId) => '$tutorTab/chat/$conversationId';

  // ── Student: Practice tab ──
  static const String practice = '/student/practice';
  static String questionBank({String? subjectId, String? chapterId, String? topicId}) =>
      _q('$practice/bank', {'subject': subjectId, 'chapter': chapterId, 'topic': topicId});
  static String question(String id) => '$practice/question/$id';
  static const String bookmarks = '$practice/bookmarks';
  static const String examCenter = '$practice/exams';
  static const String examSetup = '$practice/exams/new';
  static const String examResults = '$practice/results';
  static String examResult(String attemptId) => '$practice/results/$attemptId';

  // ── Full-screen focused flows (outside the tab shell) ──
  static String practiceSession({String? subjectId, String? chapterId, String? topicId, String? mode}) =>
      _q('/practice-session', {'subject': subjectId, 'chapter': chapterId, 'topic': topicId, 'mode': mode});
  static String examTake(String attemptId) => '/exam/$attemptId';

  // ── Student modules opened from Home / More ──
  static const String analytics = '/analytics';
  static String notes({String? chapterId}) => _q('/notes', {'chapter': chapterId});
  static String note(String id) => '/notes/$id';
  static String flashcards({String? chapterId}) => _q('/flashcards', {'chapter': chapterId});
  static String flashcardStudy(String deckId, {String mode = 'study'}) => _q('/flashcards/study/$deckId', {'mode': mode});
  static const String planner = '/planner';
  static const String library = '/library';
  static String book(String id) => '/library/$id';
  static String bookReader(String id, {int? page}) => _q('/library/$id/read', {'page': page?.toString()});
  static const String boardArchive = '/board';
  static String boardPaper(String id) => '/board/$id';
  static const String institutionArchive = '/institution-papers';
  static String institutionPaper(String id) => '/institution-papers/$id';
  static const String photoSolver = '/photo-solver';
  static const String voiceTutor = '/voice-tutor';
  static const String handwriting = '/handwriting';
  static const String english = '/english';
  static const String labs = '/labs';
  static const String audio = '/audio';
  static const String achievements = '/achievements';
  static const String offline = '/offline';
  static const String subscription = '/subscription';
  static const String support = '/support';
  static const String privacy = '/privacy';
  static const String onboarding = '/onboarding';

  // ── Book avatar teacher ──
  static const String avatarTutor = '/avatar-tutor';
  static String avatarClass(String bookId, {String? sessionId}) => _q('$avatarTutor/$bookId', {'session': sessionId});
  static const String teacherAvatars = '/teacher-avatars';
  static const String avatarActivity = '/avatar-activity';

  // ── Teacher & parent modules ──
  static const String teacherAssignments = '/teacher-assignments';
  static const String teacherExams = '/teacher-exams';
  static const String questionGenerator = '/question-generator';
  static const String teacherMaterials = '/teacher-materials';
  static const String teacherAnalytics = '/teacher-analytics';
  static const String teacherReview = '/teacher-review';
  static const String teacherHistory = '/teacher-history';
  static const String teacherQuestions = '/teacher-questions';
  static const String teacherRubrics = '/teacher-rubrics';
  static const String teacherSubjects = '/teacher-subjects';
  static const String teacherStudents = '/teacher-students';
  static const String parentReports = '/parent-reports';
  static const String parentResults = '/parent-results';
  static const String parentCalendar = '/parent-calendar';
  static const String parentFeedback = '/parent-feedback';
  static const String parentGoals = '/parent-goals';
  static const String parentPrivacy = '/parent-privacy';
}
