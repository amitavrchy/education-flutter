import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/application/auth_controller.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/splash_screen.dart';
import '../../features/auth/presentation/unsupported_role_screen.dart';
import '../../features/notifications/presentation/notifications_screen.dart';
import '../../features/settings/presentation/settings_screen.dart';
import '../../shared/widgets/feature_placeholder_screen.dart';
import '../navigation/portal_config.dart';
import '../shell/role_shell.dart';
import 'app_routes.dart';
import 'auth_redirect.dart';

StatefulShellRoute _portalRoute(PortalConfig config) {
  return StatefulShellRoute.indexedStack(
    builder: (context, state, navigationShell) =>
        RoleShell(config: config, navigationShell: navigationShell),
    branches: [
      for (final tab in config.tabs)
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: config.tabPath(tab),
              builder: (context, state) => tab.builder(config),
              routes: [
                if (tab.slug == 'more')
                  GoRoute(
                    path: ':slug',
                    builder: (context, state) {
                      final item = config.menuItem(state.pathParameters['slug'] ?? '');
                      return FeaturePlaceholderScreen(
                        title: item?.label ?? 'পাওয়া যায়নি',
                        icon: item?.icon ?? FeaturePlaceholderScreen.defaultIcon,
                      );
                    },
                  ),
              ],
            ),
          ],
        ),
    ],
  );
}

/// The app router. Rebuilds redirects whenever the auth state changes.
final routerProvider = Provider<GoRouter>((ref) {
  final authChanges = ValueNotifier<int>(0);
  ref.listen<AuthState>(authControllerProvider, (previous, next) => authChanges.value++);

  final router = GoRouter(
    initialLocation: AppRoutes.splash,
    refreshListenable: authChanges,
    debugLogDiagnostics: kDebugMode,
    redirect: (context, state) =>
        resolveAuthRedirect(ref.read(authControllerProvider), state.matchedLocation),
    routes: [
      GoRoute(path: AppRoutes.splash, builder: (context, state) => const SplashScreen()),
      GoRoute(path: AppRoutes.login, builder: (context, state) => const LoginScreen()),
      GoRoute(
        path: AppRoutes.unsupportedRole,
        builder: (context, state) => const UnsupportedRoleScreen(),
      ),
      GoRoute(
        path: AppRoutes.notifications,
        builder: (context, state) => const NotificationsScreen(),
      ),
      GoRoute(path: AppRoutes.settings, builder: (context, state) => const SettingsScreen()),
      for (final portal in mobilePortals) _portalRoute(portal),
    ],
  );

  ref.onDispose(() {
    router.dispose();
    authChanges.dispose();
  });
  return router;
});
