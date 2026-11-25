import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shikkhaai_mobile/app/router/app_routes.dart';
import 'package:shikkhaai_mobile/app/router/auth_redirect.dart';
import 'package:shikkhaai_mobile/core/l10n/tr.dart';
import 'package:shikkhaai_mobile/core/mock/mock_simulator.dart';
import 'package:shikkhaai_mobile/core/network/network_providers.dart';
import 'package:shikkhaai_mobile/core/storage/local_store.dart';
import 'package:shikkhaai_mobile/core/theme/app_theme.dart';
import 'package:shikkhaai_mobile/features/auth/application/auth_controller.dart';
import 'package:shikkhaai_mobile/features/auth/data/auth_repository.dart';
import 'package:shikkhaai_mobile/features/auth/presentation/auth_flow_screens.dart';
import 'package:shikkhaai_mobile/features/profile/application/student_profile_controller.dart';

import '../../helpers/test_app.dart';

void main() {
  test('signed-out users may open the signup screens; others go to login', () {
    const out = Unauthenticated();
    for (final r in [AppRoutes.welcome, AppRoutes.register, AppRoutes.verifyOtp, AppRoutes.forgotPassword, AppRoutes.resetPassword]) {
      expect(resolveAuthRedirect(out, r), isNull, reason: r);
    }
    expect(resolveAuthRedirect(out, AppRoutes.onboarding), AppRoutes.login);
  });

  test('identifier and password rules', () {
    expect(validIdentifier('01712345678'), isTrue);
    expect(validIdentifier('a@b.co'), isTrue);
    expect(validIdentifier('0171234'), isFalse);
    expect(strongPassword('abcd1234'), isTrue);
    expect(strongPassword('abcdefgh'), isFalse);
  });

  testWidgets('student signs up → OTP → onboarding → profile saved', (tester) async {
    final store = MemoryLocalStore();
    final router = GoRouter(
      initialLocation: AppRoutes.register,
      routes: [
        GoRoute(path: AppRoutes.register, builder: (_, _) => const RegisterScreen()),
        GoRoute(path: AppRoutes.verifyOtp, builder: (_, _) => const VerifyOtpScreen()),
        GoRoute(path: AppRoutes.onboarding, builder: (_, _) => const OnboardingScreen()),
        GoRoute(path: AppRoutes.consent, builder: (_, _) => const ConsentScreen()),
        GoRoute(path: AppRoutes.login, builder: (_, _) => const Scaffold(body: Text('login'))),
        GoRoute(path: '/student/home', builder: (_, _) => const Scaffold(body: Text('student home'))),
      ],
    );
    late ProviderContainer container;
    await tester.pumpWidget(ProviderScope(
      retry: (_, _) => null,
      overrides: [
        localStoreProvider.overrideWithValue(store),
        mockLatencyProvider.overrideWithValue(Duration.zero),
        tokenStorageProvider.overrideWithValue(MemoryTokenStorage()),
        authRepositoryProvider.overrideWithValue(const MockAuthRepository(delay: Duration.zero)),
      ],
      child: Consumer(builder: (context, ref, _) {
        container = ProviderScope.containerOf(context);
        return MaterialApp.router(
          theme: AppTheme.light(useGoogleFonts: false),
          locale: AppLanguage.en.locale,
          supportedLocales: const [Locale('bn', 'BD'), Locale('en', 'US')],
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          routerConfig: router,
        );
      }),
    ));
    await tester.pumpAndSettle();

    // Validation first.
    await tester.tap(find.byKey(const Key('reg.submit')));
    await tester.pumpAndSettle();
    expect(find.text('Enter your name'), findsOneWidget);
    expect(find.text('Please accept the terms'), findsOneWidget);

    await tester.enterText(find.byKey(const Key('reg.name')), 'Test Student');
    await tester.enterText(find.byKey(const Key('reg.id')), '01712345678');
    await tester.enterText(find.byKey(const Key('reg.pw')), 'abcd1234');
    await tester.enterText(find.byKey(const Key('reg.pw2')), 'abcd1234');
    await tester.ensureVisible(find.byKey(const Key('reg.terms')));
    await tester.tap(find.byKey(const Key('reg.terms')));
    await tester.ensureVisible(find.byKey(const Key('reg.submit')));
    await tester.tap(find.byKey(const Key('reg.submit')));
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('otp.code')), '000000');
    await tester.tap(find.byKey(const Key('otp.verify')));
    await tester.pump();
    expect(find.text('Incorrect code'), findsOneWidget);
    await tester.enterText(find.byKey(const Key('otp.code')), '123456');
    await tester.tap(find.byKey(const Key('otp.verify')));
    await tester.pumpAndSettle();
    expect(container.read(authControllerProvider), isA<Authenticated>());

    // Privacy & consent before onboarding.
    await tester.ensureVisible(find.byKey(const Key('consent.terms')));
    await tester.tap(find.byKey(const Key('consent.terms')));
    await tester.ensureVisible(find.byKey(const Key('consent.ai')));
    await tester.tap(find.byKey(const Key('consent.ai')));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('consent.accept')));
    await tester.tap(find.byKey(const Key('consent.accept')));
    await tester.pumpAndSettle();

    for (var i = 0; i < 6; i++) {
      await tester.ensureVisible(find.byKey(const Key('ob.next')));
      await tester.tap(find.byKey(const Key('ob.next')));
      await tester.pumpAndSettle();
    }
    expect(find.text('student home'), findsOneWidget);
    final profile = container.read(studentProfileProvider);
    expect(profile.onboarded, isTrue);
    expect(profile.name, 'Test Student');
  });
}
