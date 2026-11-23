import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../features/auth/application/auth_controller.dart';
import '../../features/auth/domain/app_user.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/splash_screen.dart';
import '../../features/auth/presentation/unsupported_role_screen.dart';
import '../../features/curriculum/presentation/chapter_detail_screen.dart';
import '../../features/curriculum/presentation/subject_detail_screen.dart';
import '../../features/curriculum/presentation/topic_screen.dart';
import '../../features/exams/presentation/exam_center_screen.dart';
import '../../features/exams/presentation/exam_result_screen.dart';
import '../../features/exams/presentation/exam_setup_screen.dart';
import '../../features/exams/presentation/exam_take_screen.dart';
import '../../features/notifications/presentation/notifications_screen.dart';
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
  GoRoute(path: AppRoutes.notifications, builder: (context, state) => const NotificationsScreen()),
  GoRoute(path: AppRoutes.settings, builder: (context, state) => const SettingsScreen()),
  GoRoute(path: AppRoutes.search, builder: (context, state) => _pending('খুঁজুন', Icons.search)),
  GoRoute(path: AppRoutes.profile, builder: (context, state) => _pending('প্রোফাইল', Icons.person_outline)),
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
  GoRoute(path: AppRoutes.analytics, builder: (context, state) => _pending('অগ্রগতি', Icons.insights_outlined)),
  GoRoute(path: '/notes', builder: (context, state) => _pending('নোটস', Icons.sticky_note_2_outlined)),
  GoRoute(path: '/flashcards', builder: (context, state) => _pending('ফ্ল্যাশকার্ড', Icons.style_outlined)),
  GoRoute(path: AppRoutes.planner, builder: (context, state) => _pending('স্টাডি প্ল্যানার', Icons.calendar_month_outlined)),
  GoRoute(path: AppRoutes.library, builder: (context, state) => _pending('লাইব্রেরি', Icons.local_library_outlined)),
  GoRoute(path: AppRoutes.boardArchive, builder: (context, state) => _pending('বোর্ড প্রশ্ন', Icons.history_edu_outlined)),
  GoRoute(path: AppRoutes.institutionArchive, builder: (context, state) => _pending('স্কুল-কলেজের প্রশ্ন', Icons.account_balance_outlined)),
  GoRoute(path: AppRoutes.photoSolver, builder: (context, state) => _pending('ফটো সলভার', Icons.photo_camera_outlined)),
  GoRoute(path: AppRoutes.voiceTutor, builder: (context, state) => _pending('ভয়েস টিউটর', Icons.mic_none)),
  GoRoute(path: AppRoutes.handwriting, builder: (context, state) => _pending('হাতের লেখা মূল্যায়ন', Icons.draw_outlined)),
  GoRoute(path: AppRoutes.english, builder: (context, state) => _pending('ইংরেজি কোচ', Icons.translate)),
  GoRoute(path: AppRoutes.labs, builder: (context, state) => _pending('ল্যাব', Icons.science_outlined)),
  GoRoute(path: AppRoutes.audio, builder: (context, state) => _pending('অডিও রিভিশন', Icons.headphones_outlined)),
  GoRoute(path: AppRoutes.achievements, builder: (context, state) => _pending('অর্জন', Icons.emoji_events_outlined)),
  GoRoute(path: AppRoutes.offline, builder: (context, state) => _pending('অফলাইন', Icons.download_for_offline_outlined)),
  GoRoute(path: AppRoutes.subscription, builder: (context, state) => _pending('সাবস্ক্রিপশন', Icons.workspace_premium_outlined)),
  GoRoute(path: AppRoutes.support, builder: (context, state) => _pending('সাহায্য', Icons.support_agent)),
  GoRoute(path: AppRoutes.privacy, builder: (context, state) => _pending('গোপনীয়তা', Icons.shield_outlined)),
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
