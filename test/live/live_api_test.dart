import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shikkhaai_mobile/core/network/api_client.dart';
import 'package:shikkhaai_mobile/features/auth/data/auth_repository.dart';
import 'package:shikkhaai_mobile/features/auth/domain/app_user.dart';

/// Talks to a running education-backend (demo mode). Skipped unless LIVE_API=1:
///   LIVE_API=1 flutter test test/live
void main() {
  final live = Platform.environment['LIVE_API'] == '1';
  final base = Platform.environment['API_BASE_URL'] ?? 'http://localhost:4000/api/v1';
  ApiClient client([String? token]) => ApiClient(Dio(BaseOptions(baseUrl: base, headers: {if (token != null) 'Authorization': 'Bearer $token'})));

  test('demo accounts sign in with their role, refresh rotates, switch-role works', () async {
    final repo = ApiAuthRepository(client());
    for (final (id, role) in [('student@shikkha.ai', UserRole.student), ('teacher@shikkha.ai', UserRole.teacher), ('parent@shikkha.ai', UserRole.parent), ('reviewer@shikkha.ai', UserRole.teacher), ('admin@shikkha.ai', UserRole.superAdmin)]) {
      final s = await repo.login(identifier: id, password: 'demo-password-123');
      expect(s.user.role, role, reason: id);
    }
    final s = await repo.login(identifier: 'student@shikkha.ai', password: 'demo-password-123');
    final r = await repo.refresh(s.refreshToken!);
    expect(r.refreshToken, isNot(s.refreshToken));
    expect((await repo.switchRole(UserRole.parent)).user.role, UserRole.parent);
  }, skip: !live);

  test('signup: register → OTP challenge → verify with the demo code', () async {
    final repo = ApiAuthRepository(client());
    final phone = '0171${DateTime.now().millisecondsSinceEpoch % 10000000}'.padRight(11, '0').substring(0, 11);
    final ch = await repo.startRegistration(name: 'Live Test', identifier: phone, password: 'abcd1234', role: UserRole.student);
    expect(ch, isNotNull);
    final s = await repo.completeRegistration(challengeId: ch, code: '123456', name: 'Live Test', identifier: phone, password: 'abcd1234', role: UserRole.student);
    expect(s.user.role, UserRole.student);
  }, skip: !live);
}
