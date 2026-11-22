import '../../features/auth/domain/app_user.dart';

abstract final class AppRoutes {
  static const String splash = '/splash';
  static const String login = '/login';
  static const String unsupportedRole = '/unsupported-role';
  static const String notifications = '/notifications';
  static const String settings = '/settings';

  /// Landing tab of a role's portal, e.g. /student/home.
  static String portalHome(UserRole role) => '/${role.pathSegment}/home';
}
