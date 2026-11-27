import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/env.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/network_providers.dart';
import '../../../core/network/api_exception.dart';
import '../domain/app_user.dart';

/// Sign-in contract. The UI never knows whether it talks to the API or the mock.
abstract interface class AuthRepository {
  Future<AuthSession> login({required String identifier, required String password});

  /// Starts signup: the server sends an OTP and answers with its challenge id
  /// (null for the mock, where the demo code 123456 is checked on the device).
  Future<String?> startRegistration({required String name, required String identifier, required String password, required UserRole role});

  /// Finishes signup once the OTP is entered and returns the new session.
  Future<AuthSession> completeRegistration({
    required String? challengeId,
    required String code,
    required String name,
    required String identifier,
    required String password,
    required UserRole role,
  });

  /// Rotates the refresh token (API only).
  Future<AuthSession> refresh(String refreshToken);

  /// Demo mode: signs in as the demo account of [role].
  Future<AuthSession> switchRole(UserRole role);

  Future<void> logout();
}

/// The education-backend's `/auth/*` endpoints.
class ApiAuthRepository implements AuthRepository {
  ApiAuthRepository(this._api);

  final ApiClient _api;

  static Map<String, dynamic> _map(Object? data) => data! as Map<String, dynamic>;

  /// `{ user, accessToken, refreshToken, expiresAt, … }` → session.
  static AuthSession sessionFrom(Map<String, dynamic> j) => AuthSession(
    accessToken: j['accessToken'] as String,
    refreshToken: j['refreshToken'] as String?,
    user: AppUser.fromJson((j['user'] as Map).cast<String, dynamic>()),
  );

  @override
  Future<AuthSession> login({required String identifier, required String password}) async {
    final res = await _api.post('/auth/login', body: {'identifier': identifier, 'password': password}, parse: _map, skipAuth: true);
    return sessionFrom(res.data);
  }

  @override
  Future<String?> startRegistration({required String name, required String identifier, required String password, required UserRole role}) async {
    final res = await _api.post(
      '/auth/register',
      body: {
        'name': name,
        'identifier': identifier,
        'channel': identifier.contains('@') ? 'email' : 'phone',
        'role': role.pathSegment,
        if (password.isNotEmpty) 'password': password,
      },
      parse: _map,
      skipAuth: true,
    );
    return res.data['challengeId'] as String?;
  }

  @override
  Future<AuthSession> completeRegistration({
    required String? challengeId,
    required String code,
    required String name,
    required String identifier,
    required String password,
    required UserRole role,
  }) async {
    if (challengeId == null) throw const ApiException.validation('OTP-র মেয়াদ শেষ — আবার নিবন্ধন করুন।');
    final res = await _api.post('/auth/otp/verify', body: {'challengeId': challengeId, 'code': code}, parse: _map, skipAuth: true);
    final session = res.data['session'];
    if (session is! Map) throw const ApiException.validation('সেশন পাওয়া যায়নি।');
    return sessionFrom(session.cast<String, dynamic>());
  }

  @override
  Future<AuthSession> refresh(String refreshToken) async {
    final res = await _api.post('/auth/refresh', body: {'refreshToken': refreshToken}, parse: _map, skipAuth: true);
    return sessionFrom(res.data);
  }

  @override
  Future<AuthSession> switchRole(UserRole role) async {
    final res = await _api.post('/auth/switch-role', body: {'role': role.pathSegment}, parse: _map, skipAuth: true);
    return sessionFrom(res.data);
  }

  @override
  Future<void> logout() async {
    await _api.sendNoContent('POST', '/auth/logout');
  }
}

/// Offline mock: any password works; the role comes from the identifier prefix,
/// e.g. "teacher@shikkha.ai" signs in as a teacher (default: student).
class MockAuthRepository implements AuthRepository {
  const MockAuthRepository({this.delay = const Duration(milliseconds: 400)});

  final Duration delay;

  static const _names = {
    UserRole.student: 'রাফি আহমেদ',
    UserRole.teacher: 'নাসরিন সুলতানা',
    UserRole.parent: 'করিম উদ্দিন',
    UserRole.superAdmin: 'সিস্টেম অ্যাডমিন',
  };

  @override
  Future<AuthSession> login({required String identifier, required String password}) async {
    await Future<void>.delayed(delay);
    final lower = identifier.toLowerCase();
    final role = UserRole.values.firstWhere(
      (candidate) => lower.startsWith(candidate.pathSegment),
      orElse: () => UserRole.student,
    );
    return AuthSession(
      accessToken: 'mock-token-${role.pathSegment}',
      user: AppUser(id: 'mock-${role.pathSegment}', name: _names[role]!, role: role, email: identifier),
    );
  }

  /// Creates the mock account (after the on-device OTP check).
  Future<AuthSession> register({required String name, required String identifier, required String password, required UserRole role}) async {
    await Future<void>.delayed(delay);
    return AuthSession(
      accessToken: 'mock-token-${role.pathSegment}',
      user: AppUser(id: 'mock-${role.pathSegment}', name: name, role: role, email: identifier),
    );
  }

  @override
  Future<String?> startRegistration({required String name, required String identifier, required String password, required UserRole role}) async => null;

  @override
  Future<AuthSession> completeRegistration({
    required String? challengeId,
    required String code,
    required String name,
    required String identifier,
    required String password,
    required UserRole role,
  }) async {
    if (code.trim() != '123456') throw const ApiException.validation('কোড সঠিক নয়');
    return register(name: name, identifier: identifier, password: password, role: role);
  }

  @override
  Future<AuthSession> refresh(String refreshToken) async => throw const ApiException(statusCode: 401, code: 'SESSION_EXPIRED', message: 'সেশন শেষ');

  @override
  Future<AuthSession> switchRole(UserRole role) => login(identifier: '${role.pathSegment}@shikkha.ai', password: 'demo');

  @override
  Future<void> logout() async {}
}

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => Env.useMockApi ? const MockAuthRepository() : ApiAuthRepository(ref.watch(apiClientProvider)),
);
