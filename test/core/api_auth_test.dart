import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shikkhaai_mobile/core/network/api_client.dart';
import 'package:shikkhaai_mobile/core/network/auth_interceptor.dart';
import 'package:shikkhaai_mobile/features/auth/data/auth_repository.dart';
import 'package:shikkhaai_mobile/features/auth/domain/app_user.dart';

import '../helpers/test_app.dart';

/// Answers requests from a handler, like a tiny fake server.
class _FakeAdapter implements HttpClientAdapter {
  _FakeAdapter(this.handle);

  final (int, Object?) Function(RequestOptions o) handle;
  final List<String> calls = [];

  @override
  Future<ResponseBody> fetch(RequestOptions o, Stream<Uint8List>? body, Future<void>? cancel) async {
    calls.add('${o.method} ${o.path} ${o.headers['Authorization'] ?? ''}'.trim());
    final (status, json) = handle(o);
    return ResponseBody.fromString(jsonEncode(json), status, headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
    });
  }

  @override
  void close({bool force = false}) {}
}

Map<String, Object?> _ok(Object? data) => {'success': true, 'data': data};

const _user = {'id': 'u-student-1', 'name': 'রাফি', 'role': 'student', 'email': 'student@shikkha.ai'};

void main() {
  test('backend role names map to app roles', () {
    expect(UserRole.fromKey('student'), UserRole.student);
    expect(UserRole.fromKey('STUDENT'), UserRole.student);
    expect(UserRole.fromKey('content_reviewer'), UserRole.teacher);
    expect(UserRole.fromKey('platform_admin'), UserRole.superAdmin);
  });

  test('login, signup with the OTP challenge, and switch-role use /auth endpoints', () async {
    final adapter = _FakeAdapter((o) => switch (o.path) {
      '/auth/login' || '/auth/switch-role' => (200, _ok({'user': _user, 'accessToken': 'a1', 'refreshToken': 'r1', 'expiresAt': 'x'})),
      '/auth/register' => (201, _ok({'challengeId': 'ch-1', 'purpose': 'register', 'target': '017'})),
      '/auth/otp/verify' => (200, _ok({'purpose': 'register', 'session': {'user': _user, 'accessToken': 'a2', 'refreshToken': 'r2'}})),
      _ => (404, {'success': false, 'code': 'NOT_FOUND', 'message': 'x'}),
    });
    final repo = ApiAuthRepository(ApiClient(Dio()..httpClientAdapter = adapter));
    final s = await repo.login(identifier: 'student@shikkha.ai', password: 'p');
    expect(s.user.role, UserRole.student);
    expect(s.refreshToken, 'r1');
    final ch = await repo.startRegistration(name: 'n', identifier: '01711000009', password: 'abcd1234', role: UserRole.student);
    expect(ch, 'ch-1');
    final reg = await repo.completeRegistration(challengeId: ch, code: '123456', name: 'n', identifier: '01711000009', password: 'abcd1234', role: UserRole.student);
    expect(reg.accessToken, 'a2');
    expect((await repo.switchRole(UserRole.teacher)).accessToken, 'a1');
  });

  test('a 401 rotates the refresh token once and replays the request', () async {
    final storage = MemoryTokenStorage();
    await storage.saveSession(accessToken: 'old', refreshToken: 'r', userJson: '{}');
    late Dio dio;
    final adapter = _FakeAdapter((o) => o.headers['Authorization'] == 'Bearer new' ? (200, _ok({'n': 1})) : (401, {'success': false, 'code': 'UNAUTHORIZED', 'message': 'x'}));
    var refreshed = 0;
    var signedOut = false;
    dio = Dio()..httpClientAdapter = adapter;
    dio.interceptors.add(AuthInterceptor(
      tokenStorage: storage,
      onUnauthorized: () => signedOut = true,
      refresh: () async {
        refreshed++;
        await storage.saveSession(accessToken: 'new', refreshToken: 'r2', userJson: '{}');
        return 'new';
      },
      retry: (o) => dio.fetch(o),
    ));
    final res = await ApiClient(dio).get('/subjects', parse: (d) => d);
    expect(res.data, {'n': 1});
    expect(refreshed, 1);
    expect(signedOut, isFalse);
  });

  test('when refresh fails the user is signed out', () async {
    final storage = MemoryTokenStorage();
    await storage.saveSession(accessToken: 'old', refreshToken: 'r', userJson: '{}');
    var signedOut = false;
    final dio = Dio()..httpClientAdapter = _FakeAdapter((o) => (401, {'success': false, 'code': 'UNAUTHORIZED', 'message': 'x'}));
    dio.interceptors.add(AuthInterceptor(tokenStorage: storage, onUnauthorized: () => signedOut = true, refresh: () async => null, retry: (o) => dio.fetch(o)));
    await expectLater(ApiClient(dio).get('/subjects', parse: (d) => d), throwsA(anything));
    expect(signedOut, isTrue);
  });
}
