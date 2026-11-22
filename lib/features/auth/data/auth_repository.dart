import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/env.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/network_providers.dart';
import '../domain/app_user.dart';

/// Sign-in contract. The UI never knows whether it talks to the API or the mock.
abstract interface class AuthRepository {
  Future<AuthSession> login({required String identifier, required String password});

  Future<void> logout();
}

/// Real backend. Note: the backend's auth endpoints currently answer 501 (not implemented).
class ApiAuthRepository implements AuthRepository {
  ApiAuthRepository(this._api);

  final ApiClient _api;

  @override
  Future<AuthSession> login({required String identifier, required String password}) async {
    final tokens = await _api.post<Map<String, dynamic>>(
      '/auth/login',
      body: {'identifier': identifier, 'password': password},
      parse: (data) => data! as Map<String, dynamic>,
      skipAuth: true,
    );
    final accessToken = tokens.data['accessToken'] as String;

    final me = await _api.get<AppUser>(
      '/users/me',
      headers: {'Authorization': 'Bearer $accessToken'},
      parse: (data) => AppUser.fromMeResponse(data! as Map<String, dynamic>),
    );

    return AuthSession(
      accessToken: accessToken,
      refreshToken: tokens.data['refreshToken'] as String?,
      user: me.data,
    );
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
    UserRole.institutionAdmin: 'ঢাকা আইডিয়াল কলেজ',
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

  @override
  Future<void> logout() async {}
}

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => Env.useMockApi ? const MockAuthRepository() : ApiAuthRepository(ref.watch(apiClientProvider)),
);
