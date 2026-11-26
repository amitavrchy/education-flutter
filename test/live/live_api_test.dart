import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shikkhaai_mobile/core/network/api_client.dart';
import 'package:shikkhaai_mobile/features/account/account_controller.dart';
import 'package:shikkhaai_mobile/features/account/remote_billing.dart';
import 'package:shikkhaai_mobile/features/auth/data/auth_repository.dart';
import 'package:shikkhaai_mobile/features/auth/domain/app_user.dart';
import 'package:shikkhaai_mobile/features/notifications/data/remote_notifications.dart';

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

  test('student inbox loads from /notifications and maps to app notifications', () async {
    final s = await ApiAuthRepository(client()).login(identifier: 'student@shikkha.ai', password: 'demo-password-123');
    final items = await RemoteNotifications(client(s.accessToken)).all();
    expect(items, isNotEmpty);
    expect(items.every((n) => RemoteNotifications.isServerId(n.id)), isTrue);
  }, skip: !live);

  test('billing: /billing/me parses and the declining test card fails', () async {
    final s = await ApiAuthRepository(client()).login(identifier: 'student@shikkha.ai', password: 'demo-password-123');
    final billing = RemoteBilling(client(s.accessToken));
    final state = RemoteBilling.apply(const AccountState(), await billing.me());
    expect(state.invoices, isNotEmpty);
    expect(await billing.checkout(plan: PlanCode.pro, yearly: false, method: 'Card', account: '4000000000000002'), 'failed');
  }, skip: !live);
}
