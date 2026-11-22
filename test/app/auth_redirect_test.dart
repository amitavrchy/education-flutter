import 'package:flutter_test/flutter_test.dart';
import 'package:shikkhaai_mobile/app/router/app_routes.dart';
import 'package:shikkhaai_mobile/app/router/auth_redirect.dart';
import 'package:shikkhaai_mobile/features/auth/application/auth_controller.dart';
import 'package:shikkhaai_mobile/features/auth/domain/app_user.dart';

Authenticated _signedInAs(UserRole role) =>
    Authenticated(AppUser(id: 'u1', name: 'Test', role: role));

void main() {
  test('sends everyone to splash while the session is restoring', () {
    expect(resolveAuthRedirect(const AuthUnknown(), '/student/home'), AppRoutes.splash);
    expect(resolveAuthRedirect(const AuthUnknown(), AppRoutes.splash), isNull);
  });

  test('sends signed-out users to login', () {
    expect(resolveAuthRedirect(const Unauthenticated(), '/student/home'), AppRoutes.login);
    expect(resolveAuthRedirect(const Unauthenticated(), AppRoutes.login), isNull);
  });

  test('sends signed-in users from entry screens to their portal home', () {
    final student = _signedInAs(UserRole.student);
    expect(resolveAuthRedirect(student, AppRoutes.login), '/student/home');
    expect(resolveAuthRedirect(student, AppRoutes.splash), '/student/home');
    expect(resolveAuthRedirect(student, '/student'), '/student/home');
  });

  test('keeps users inside their own portal', () {
    final teacher = _signedInAs(UserRole.teacher);
    expect(resolveAuthRedirect(teacher, '/teacher/classes'), isNull);
    expect(resolveAuthRedirect(teacher, '/student/home'), '/teacher/home');
    expect(resolveAuthRedirect(teacher, '/parent/children'), '/teacher/home');
  });

  test('allows shared routes for every signed-in role', () {
    final parent = _signedInAs(UserRole.parent);
    expect(resolveAuthRedirect(parent, AppRoutes.settings), isNull);
    expect(resolveAuthRedirect(parent, AppRoutes.notifications), isNull);
  });

  test('routes web-only roles to the unsupported-role screen', () {
    final admin = _signedInAs(UserRole.superAdmin);
    expect(resolveAuthRedirect(admin, '/student/home'), AppRoutes.unsupportedRole);
    expect(resolveAuthRedirect(admin, AppRoutes.unsupportedRole), isNull);
    expect(
      resolveAuthRedirect(_signedInAs(UserRole.institutionAdmin), AppRoutes.login),
      AppRoutes.unsupportedRole,
    );
  });
}
