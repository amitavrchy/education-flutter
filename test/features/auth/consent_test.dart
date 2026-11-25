import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shikkhaai_mobile/core/l10n/tr.dart';
import 'package:shikkhaai_mobile/features/auth/application/auth_controller.dart';
import 'package:shikkhaai_mobile/features/auth/domain/app_user.dart';
import 'package:shikkhaai_mobile/features/auth/presentation/auth_flow_screens.dart';

import '../../helpers/test_app.dart';

void main() {
  testWidgets('consent needs both required boxes', (tester) async {
    await tester.pumpWidget(testApp(const ConsentScreen(), lang: AppLanguage.en));
    await tester.pumpAndSettle();
    final accept = find.byKey(const Key('consent.accept'));
    await tester.ensureVisible(accept);
    expect(tester.widget<FilledButton>(accept).onPressed, isNull);
    await tester.ensureVisible(find.byKey(const Key('consent.terms')));
    await tester.tap(find.byKey(const Key('consent.terms')));
    await tester.ensureVisible(find.byKey(const Key('consent.ai')));
    await tester.tap(find.byKey(const Key('consent.ai')));
    await tester.pumpAndSettle();
    expect(tester.widget<FilledButton>(accept).onPressed, isNotNull);
  });

  test('demo role switch signs in as the chosen role; 401 marks the session expired', () async {
    final c = testContainer();
    await c.read(authControllerProvider.notifier).switchDemoRole(UserRole.teacher);
    final auth = c.read(authControllerProvider);
    expect(auth, isA<Authenticated>());
    expect((auth as Authenticated).user.role, UserRole.teacher);
    c.read(authControllerProvider.notifier).onUnauthorized();
    final out = c.read(authControllerProvider);
    expect(out, isA<Unauthenticated>());
    expect((out as Unauthenticated).expired, isTrue);
  });
}
