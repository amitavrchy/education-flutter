import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shikkhaai_mobile/core/network/network_providers.dart';
import 'package:shikkhaai_mobile/core/storage/token_storage.dart';
import 'package:shikkhaai_mobile/features/auth/application/auth_controller.dart';
import 'package:shikkhaai_mobile/features/auth/data/auth_repository.dart';
import 'package:shikkhaai_mobile/features/auth/domain/app_user.dart';
import 'package:shikkhaai_mobile/features/auth/presentation/login_screen.dart';

/// In-memory replacement for secure storage (no platform channel in tests).
class _MemoryTokenStorage extends TokenStorage {
  final Map<String, String?> _values = {};

  @override
  Future<String?> readAccessToken() async => _values['access'];

  @override
  Future<String?> readRefreshToken() async => _values['refresh'];

  @override
  Future<String?> readUserJson() async => _values['user'];

  @override
  Future<void> saveSession({
    required String accessToken,
    String? refreshToken,
    required String userJson,
  }) async {
    _values
      ..['access'] = accessToken
      ..['refresh'] = refreshToken
      ..['user'] = userJson;
  }

  @override
  Future<void> clear() async => _values.clear();
}

Widget _app() => ProviderScope(
  overrides: [
    tokenStorageProvider.overrideWithValue(_MemoryTokenStorage()),
    authRepositoryProvider.overrideWithValue(const MockAuthRepository(delay: Duration.zero)),
  ],
  child: const MaterialApp(home: LoginScreen()),
);

void main() {
  testWidgets('shows validation errors for an empty form', (tester) async {
    await tester.pumpWidget(_app());
    await tester.tap(find.byKey(const Key('login.submit')));
    await tester.pump();

    expect(find.text('ইমেইল বা মোবাইল নম্বর দিন'), findsOneWidget);
    expect(find.text('পাসওয়ার্ড দিন'), findsOneWidget);
  });

  testWidgets('signs in with valid credentials', (tester) async {
    await tester.pumpWidget(_app());
    await tester.pump(); // let the session restore finish

    await tester.enterText(find.byKey(const Key('login.identifier')), 'teacher@shikkha.ai');
    await tester.enterText(find.byKey(const Key('login.password')), 'password123');
    await tester.tap(find.byKey(const Key('login.submit')));
    await tester.pumpAndSettle();

    final container = ProviderScope.containerOf(tester.element(find.byType(LoginScreen)));
    final state = container.read(authControllerProvider);
    expect(state, isA<Authenticated>());
    expect((state as Authenticated).user.role, UserRole.teacher);
  });
}
