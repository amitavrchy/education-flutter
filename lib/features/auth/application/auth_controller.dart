import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/network_providers.dart';
import '../../../core/storage/token_storage.dart';
import '../data/auth_repository.dart';
import '../domain/app_user.dart';

sealed class AuthState {
  const AuthState();
}

/// Session is being restored from secure storage (app start).
final class AuthUnknown extends AuthState {
  const AuthUnknown();
}

final class Unauthenticated extends AuthState {
  const Unauthenticated({this.expired = false});

  /// Signed out because the session expired (401), not by the user.
  final bool expired;
}

final class Authenticated extends AuthState {
  const Authenticated(this.user);

  final AppUser user;
}

/// Owns the session: restore on start, login, logout and forced sign-out on 401.
class AuthController extends Notifier<AuthState> {
  AuthRepository get _repository => ref.read(authRepositoryProvider);
  TokenStorage get _storage => ref.read(tokenStorageProvider);

  @override
  AuthState build() {
    unawaited(Future.microtask(_restore));
    return const AuthUnknown();
  }

  Future<void> _restore() async {
    // The provider can be disposed before the microtask runs (short-lived reads in tests).
    if (!ref.mounted) return;
    final storage = _storage;
    try {
      final token = await storage.readAccessToken();
      final userJson = await storage.readUserJson();
      if (!ref.mounted || state is! AuthUnknown) return;
      if (token == null || userJson == null) {
        state = const Unauthenticated();
        return;
      }
      state = Authenticated(AppUser.fromJson(jsonDecode(userJson) as Map<String, dynamic>));
    } catch (_) {
      await storage.clear();
      if (ref.mounted && state is AuthUnknown) state = const Unauthenticated();
    }
  }

  /// Throws ApiException on failure; the caller shows the message.
  Future<void> login({required String identifier, required String password}) async {
    final session = await _repository.login(identifier: identifier.trim(), password: password);
    await _storage.saveSession(
      accessToken: session.accessToken,
      refreshToken: session.refreshToken,
      userJson: jsonEncode(session.user.toJson()),
    );
    state = Authenticated(session.user);
  }

  /// Signs in a freshly registered account (after OTP verification).
  Future<void> register({required String name, required String identifier, required String password, required UserRole role}) async {
    final session = await _repository.register(name: name.trim(), identifier: identifier.trim(), password: password, role: role);
    await _storage.saveSession(accessToken: session.accessToken, refreshToken: session.refreshToken, userJson: jsonEncode(session.user.toJson()));
    state = Authenticated(session.user);
  }

  Future<void> logout() async {
    try {
      await _repository.logout();
    } catch (_) {
      // Signing out locally must work even when the server can't be reached.
    }
    await _storage.clear();
    state = const Unauthenticated();
  }

  /// The backend rejected our token: drop the session without calling the API again.
  void onUnauthorized() {
    if (state is! Authenticated) return;
    state = const Unauthenticated(expired: true);
    unawaited(_storage.clear());
  }

  /// Demo tool (AUTH-09): signs in as another mock role without the login form.
  Future<void> switchDemoRole(UserRole role) => login(identifier: '${role.pathSegment}@shikkha.ai', password: 'demo');
}

final authControllerProvider = NotifierProvider<AuthController, AuthState>(AuthController.new);
