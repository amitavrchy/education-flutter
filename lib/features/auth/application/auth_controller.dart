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
  const Unauthenticated();
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
    try {
      final token = await _storage.readAccessToken();
      final userJson = await _storage.readUserJson();
      if (state is! AuthUnknown) return;
      if (token == null || userJson == null) {
        state = const Unauthenticated();
        return;
      }
      state = Authenticated(AppUser.fromJson(jsonDecode(userJson) as Map<String, dynamic>));
    } catch (_) {
      await _storage.clear();
      if (state is AuthUnknown) state = const Unauthenticated();
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
    state = const Unauthenticated();
    unawaited(_storage.clear());
  }
}

final authControllerProvider = NotifierProvider<AuthController, AuthState>(AuthController.new);
