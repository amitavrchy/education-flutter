import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../features/ai_tutor/presentation/tutor_chat_screen.dart';
import '../../features/auth/application/auth_controller.dart';
import '../../features/auth/domain/app_user.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/splash_screen.dart';
import '../../features/account/account_screens.dart';
import '../../features/ai_tools/ai_tools_screens.dart';
import '../../features/archives/archive_screens.dart';
import '../../features/auth/presentation/auth_flow_screens.dart';
import '../../features/auth/presentation/unsupported_role_screen.dart';
import '../../features/book_avatar/presentation/avatar_classroom_screen.dart';
import '../../features/book_avatar/presentation/avatar_gallery_screen.dart';
import '../../features/book_avatar/presentation/avatar_role_screens.dart';
import '../../features/insights/insights_screens.dart';
import '../../features/library/library_screens.dart';
import '../../features/parent/parent_screens.dart';
import '../../features/search/presentation/search_screen.dart';
import '../../features/study_tools/audio_and_offline.dart';
import '../../features/study_tools/english_and_labs.dart';
import '../../features/teacher/teacher_screens.dart';
import '../../features/teacher/teacher_workflow_screens.dart';
import '../../features/curriculum/presentation/chapter_detail_screen.dart';
import '../../features/curriculum/presentation/subject_detail_screen.dart';
import '../../features/curriculum/presentation/topic_screen.dart';
import '../../features/exams/presentation/exam_center_screen.dart';
import '../../features/exams/presentation/exam_result_screen.dart';
import '../../features/exams/presentation/exam_setup_screen.dart';
import '../../features/exams/presentation/exam_take_screen.dart';
import '../../features/flashcards/presentation/flashcard_study_screen.dart';
import '../../features/flashcards/presentation/flashcards_screen.dart';
import '../../features/notes/presentation/note_editor_screen.dart';
import '../../features/notes/presentation/notes_screen.dart';
import '../../features/notifications/presentation/notifications_screen.dart';
import '../../features/planner/presentation/planner_screen.dart';
import '../../features/question_bank/application/practice_controller.dart';
import '../../features/question_bank/presentation/bookmarks_screen.dart';
import '../../features/question_bank/presentation/practice_session_screen.dart';
import '../../features/question_bank/presentation/question_bank_screen.dart';
import '../../features/question_bank/presentation/question_detail_screen.dart';
import '../../features/settings/presentation/settings_screen.dart';
import '../../shared/widgets/feature_placeholder_screen.dart';
import '../navigation/portal_config.dart';
import '../shell/role_shell.dart';
import 'app_routes.dart';
import 'auth_redirect.dart';

/// Screen for a route whose module is still listed as incomplete in FEATURE_MATRIX.md.
Widget _pending(String title, IconData icon) => FeaturePlaceholderScreen(title: title, icon: icon);

String? _param(GoRouterState state, String key) => state.uri.queryParameters[key];

/// Routes nested under a tab, so the bottom navigation stays visible while drilling down.
List<RouteBase> _tabChildRoutes(PortalConfig config, PortalTab tab) {
  if (tab.slug == 'more') {
    return [
      GoRoute(
        path: ':slug',
        builder: (context, state) {
          final item = config.menuItem(state.pathParameters['slug'] ?? '');
          return _pending(item?.label ?? 'পাওয়া যায়নি', item?.icon ?? FeaturePlaceholderScreen.defaultIcon);
        },
      ),
    ];
  }
  if (config.role != UserRole.student) return const [];
  return switch (tab.slug) {
    'learn' => [
      GoRoute(
        path: 'subject/:id',
        builder: (context, state) => SubjectDetailScreen(subjectId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: 'chapter/:id',
        builder: (context, state) => ChapterDetailScreen(chapterId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: 'topic/:id',
        builder: (context, state) => TopicScreen(topicId: state.pathParameters['id']!),
      ),
    ],
    'ai-tutor' => [
      GoRoute(
        path: 'chat/:id',
        builder: (context, state) => TutorChatScreen(
          conversationId: state.pathParameters['id']!,
          initialPrompt: _param(state, 'prompt'),
        ),
      ),
    ],
    'practice' => [
      GoRoute(
        path: 'bank',
        builder: (context, state) => QuestionBankScreen(
          subjectId: _param(state, 'subject'),
          chapterId: _param(state, 'chapter'),
          topicId: _param(state, 'topic'),
        ),
      ),
      GoRoute(
        path: 'question/:id',
        builder: (context, state) => QuestionDetailScreen(questionId: state.pathParameters['id']!),
      ),
      GoRoute(path: 'bookmarks', builder: (context, state) => const BookmarksScreen()),
      GoRoute(
        path: 'exams',
        builder: (context, state) => const ExamCenterScreen(),
        routes: [GoRoute(path: 'new', builder: (context, state) => const ExamSetupScreen())],
      ),
      GoRoute(
        path: 'results',
        builder: (context, state) => const ExamResultsScreen(),
        routes: [
          GoRoute(path: ':id', builder: (context, state) => ExamResultScreen(attemptId: state.pathParameters['id']!)),
        ],
      ),
    ],
    _ => const [],
  };
}

StatefulShellRoute _portalRoute(PortalConfig config) {
  return StatefulShellRoute.indexedStack(
    builder: (context, state, navigationShell) => RoleShell(config: config, navigationShell: navigationShell),
    branches: [
      for (final tab in config.tabs)
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: config.tabPath(tab),
              builder: (context, state) => tab.builder(config),
              routes: _tabChildRoutes(config, tab),
            ),
          ],
        ),
    ],
  );
}

/// Full-screen routes pushed above the tab shell (focused flows and secondary modules).
List<RouteBase> _moduleRoutes() => [
  GoRoute(
    path: AppRoutes.notifications,
    builder: (context, state) => const NotificationsScreen(),
    routes: [GoRoute(path: 'preferences', builder: (context, state) => const NotificationPrefsScreen())],
  ),
  GoRoute(path: AppRoutes.settings, builder: (context, state) => const SettingsScreen()),
  GoRoute(path: AppRoutes.search, builder: (context, state) => const SearchScreen()),
  GoRoute(path: AppRoutes.profile, builder: (context, state) => const ProfileScreen()),
  GoRoute(
    path: '/practice-session',
    builder: (context, state) => PracticeSessionScreen(
      request: PracticeRequest(
        mode: _param(state, 'mode') ?? 'chapter',
        subjectId: _param(state, 'subject'),
        chapterId: _param(state, 'chapter'),
        topicId: _param(state, 'topic'),
        setId: _param(state, 'set'),
      ),
    ),
  ),
  GoRoute(path: '/exam/:id', builder: (context, state) => ExamTakeScreen(attemptId: state.pathParameters['id']!)),
  GoRoute(path: AppRoutes.analytics, builder: (context, state) => const AnalyticsScreen()),
  GoRoute(
    path: '/notes',
    builder: (context, state) => NotesScreen(chapterId: _param(state, 'chapter')),
    routes: [GoRoute(path: ':id', builder: (context, state) => NoteEditorScreen(noteId: state.pathParameters['id']!))],
  ),
  GoRoute(
    path: '/flashcards',
    builder: (context, state) => FlashcardsScreen(chapterId: _param(state, 'chapter')),
    routes: [
      GoRoute(path: 'deck/:id', builder: (context, state) => DeckScreen(deckId: state.pathParameters['id']!)),
      GoRoute(
        path: 'study/:id',
        builder: (context, state) => FlashcardStudyScreen(deckId: state.pathParameters['id']!, quick: _param(state, 'mode') == 'quick'),
      ),
    ],
  ),
  GoRoute(path: AppRoutes.planner, builder: (context, state) => const PlannerScreen()),
  GoRoute(
    path: AppRoutes.avatarTutor,
    builder: (context, state) => const AvatarGalleryScreen(),
    routes: [
      GoRoute(
        path: ':bookId',
        builder: (context, state) => AvatarClassroomScreen(bookId: state.pathParameters['bookId']!, sessionId: _param(state, 'session')),
      ),
    ],
  ),
  GoRoute(path: AppRoutes.teacherAvatars, builder: (context, state) => const TeacherAvatarsScreen()),
  GoRoute(path: AppRoutes.avatarActivity, builder: (context, state) => const ParentAvatarActivityScreen()),
  GoRoute(path: AppRoutes.teacherAssignments, builder: (context, state) => const TeacherAssignmentsScreen()),
  GoRoute(path: AppRoutes.teacherExams, builder: (context, state) => const TeacherExamsScreen()),
  GoRoute(path: AppRoutes.questionGenerator, builder: (context, state) => const QuestionGeneratorScreen()),
  GoRoute(path: AppRoutes.teacherMaterials, builder: (context, state) => const TeacherMaterialsScreen()),
  GoRoute(path: AppRoutes.teacherAnalytics, builder: (context, state) => const TeacherAnalyticsScreen()),
  GoRoute(path: AppRoutes.teacherReview, builder: (context, state) => const TeacherReviewScreen()),
  GoRoute(path: AppRoutes.teacherHistory, builder: (context, state) => const TeacherHistoryScreen()),
  GoRoute(path: AppRoutes.teacherQuestions, builder: (context, state) => const TeacherQuestionsScreen()),
  GoRoute(path: AppRoutes.teacherRubrics, builder: (context, state) => const TeacherRubricsScreen()),
  GoRoute(path: AppRoutes.teacherSubjects, builder: (context, state) => const TeacherSubjectsScreen()),
  GoRoute(path: AppRoutes.teacherStudents, builder: (context, state) => const TeacherStudentsScreen()),
  GoRoute(path: AppRoutes.parentReports, builder: (context, state) => const ParentReportsScreen()),
  GoRoute(path: AppRoutes.parentResults, builder: (context, state) => const ParentResultsScreen()),
  GoRoute(path: AppRoutes.parentCalendar, builder: (context, state) => const ParentCalendarScreen()),
  GoRoute(path: AppRoutes.parentFeedback, builder: (context, state) => const ParentFeedbackScreen()),
  GoRoute(path: AppRoutes.parentGoals, builder: (context, state) => const ParentGoalsScreen()),
  GoRoute(path: AppRoutes.parentPrivacy, builder: (context, state) => const ParentPrivacyScreen()),
  GoRoute(
    path: AppRoutes.library,
    builder: (context, state) => const LibraryScreen(),
    routes: [
      GoRoute(
        path: ':id',
        builder: (context, state) => BookScreen(bookId: state.pathParameters['id']!),
        routes: [
          GoRoute(
            path: 'read',
            builder: (context, state) => BookReaderScreen(bookId: state.pathParameters['id']!, page: int.tryParse(_param(state, 'page') ?? '')),
          ),
        ],
      ),
    ],
  ),
  GoRoute(
    path: AppRoutes.boardArchive,
    builder: (context, state) => const BoardArchiveScreen(),
    routes: [GoRoute(path: ':id', builder: (context, state) => ArchivePaperScreen(paperId: state.pathParameters['id']!))],
  ),
  GoRoute(
    path: AppRoutes.institutionArchive,
    builder: (context, state) => const InstitutionArchiveScreen(),
    routes: [GoRoute(path: ':id', builder: (context, state) => ArchivePaperScreen(paperId: state.pathParameters['id']!))],
  ),
  GoRoute(path: AppRoutes.photoSolver, builder: (context, state) => const PhotoSolverScreen()),
  GoRoute(path: AppRoutes.voiceTutor, builder: (context, state) => const VoiceTutorScreen()),
  GoRoute(path: AppRoutes.handwriting, builder: (context, state) => const HandwritingScreen()),
  GoRoute(path: AppRoutes.english, builder: (context, state) => const EnglishCoachScreen()),
  GoRoute(path: AppRoutes.labs, builder: (context, state) => const LabsScreen()),
  GoRoute(path: AppRoutes.audio, builder: (context, state) => const AudioRevisionScreen()),
  GoRoute(path: AppRoutes.achievements, builder: (context, state) => const AchievementsScreen()),
  GoRoute(path: AppRoutes.offline, builder: (context, state) => const OfflineScreen()),
  GoRoute(path: AppRoutes.subscription, builder: (context, state) => const SubscriptionScreen()),
  GoRoute(path: AppRoutes.support, builder: (context, state) => const SupportScreen()),
  GoRoute(path: AppRoutes.privacy, builder: (context, state) => const PrivacyScreen()),
];

/// The app router. Rebuilds redirects whenever the auth state changes.
final routerProvider = Provider<GoRouter>((ref) {
  final authChanges = ValueNotifier<int>(0);
  ref.listen<AuthState>(authControllerProvider, (previous, next) => authChanges.value++);

  final router = GoRouter(
    initialLocation: AppRoutes.splash,
    refreshListenable: authChanges,
    debugLogDiagnostics: kDebugMode,
    redirect: (context, state) => resolveAuthRedirect(ref.read(authControllerProvider), state.matchedLocation),
    routes: [
      GoRoute(path: AppRoutes.splash, builder: (context, state) => const SplashScreen()),
      GoRoute(path: AppRoutes.login, builder: (context, state) => const LoginScreen()),
      GoRoute(path: AppRoutes.unsupportedRole, builder: (context, state) => const UnsupportedRoleScreen()),
      GoRoute(path: AppRoutes.welcome, builder: (context, state) => const WelcomeScreen()),
      GoRoute(path: AppRoutes.register, builder: (context, state) => const RegisterScreen()),
      GoRoute(path: AppRoutes.verifyOtp, builder: (context, state) => const VerifyOtpScreen()),
      GoRoute(path: AppRoutes.forgotPassword, builder: (context, state) => const ForgotPasswordScreen()),
      GoRoute(path: AppRoutes.resetPassword, builder: (context, state) => const ResetPasswordScreen()),
      GoRoute(path: AppRoutes.onboarding, builder: (context, state) => const OnboardingScreen()),
      ..._moduleRoutes(),
      for (final portal in mobilePortals) _portalRoute(portal),
    ],
  );

  ref.onDispose(() {
    router.dispose();
    authChanges.dispose();
  });
  return router;
});
