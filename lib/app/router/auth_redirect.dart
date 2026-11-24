import '../../features/auth/application/auth_controller.dart';
import '../../features/auth/domain/app_user.dart';
import 'app_routes.dart';

bool _isInPortal(String location, UserRole role) {
  final prefix = '/${role.pathSegment}';
  return location == prefix || location.startsWith('$prefix/');
}

/// Pure routing guard (unit-tested). Returns where to go instead, or null to stay.
///
/// - while restoring the session → splash
/// - signed out → login
/// - web-only roles (admins) → "use the web dashboard" screen
/// - signed in → own portal only; other portals redirect to the user's home
String? resolveAuthRedirect(AuthState auth, String location) {
  if (auth is AuthUnknown) {
    return location == AppRoutes.splash ? null : AppRoutes.splash;
  }
  if (auth is Unauthenticated) {
    return location == AppRoutes.login ? null : AppRoutes.login;
  }

  final role = (auth as Authenticated).user.role;
  if (!role.supportedOnMobile) {
    return location == AppRoutes.unsupportedRole ? null : AppRoutes.unsupportedRole;
  }

  final home = AppRoutes.portalHome(role);
  const entryRoutes = {AppRoutes.splash, AppRoutes.login, AppRoutes.unsupportedRole};
  if (entryRoutes.contains(location) || location == '/${role.pathSegment}') return home;

  final inOtherPortal = UserRole.values.any(
    (other) => other != role && _isInPortal(location, other),
  );
  return inOtherPortal ? home : null;
}
