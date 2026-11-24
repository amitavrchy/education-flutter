import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shikkhaai_mobile/core/l10n/tr.dart';
import 'package:shikkhaai_mobile/core/network/api_exception.dart';
import 'package:shikkhaai_mobile/features/account/account_controller.dart';
import 'package:shikkhaai_mobile/features/account/account_screens.dart';

import '../../helpers/test_app.dart';

void main() {
  test('coupons: percent/amount, applicability and expiry', () {
    final ctrl = testContainer().read(accountProvider.notifier);
    expect(priceWithCoupon(299, ctrl.validateCoupon('ssc2027', PlanCode.pro)), (239, 60));
    expect(priceWithCoupon(30, coupons.firstWhere((c) => c.code == 'WELCOME50')), (0, 30));
    expect(() => ctrl.validateCoupon('FAMILY30', PlanCode.pro), throwsA(isA<ApiException>().having((e) => e.code, 'code', 'COUPON_NOT_APPLICABLE')));
    expect(() => ctrl.validateCoupon('EID2026', PlanCode.pro), throwsA(isA<ApiException>().having((e) => e.code, 'code', 'COUPON_INVALID')));
  });

  test('checkout activates the plan; the test card declines; cancel keeps access until renewal', () async {
    final c = testContainer();
    final ctrl = c.read(accountProvider.notifier);
    await expectLater(ctrl.checkout(plan: PlanCode.pro, yearly: false, method: 'Card', account: '4000 0000 0000 0002'), throwsA(isA<ApiException>()));
    expect(c.read(accountProvider).plan, PlanCode.free);
    final inv = await ctrl.checkout(plan: PlanCode.pro, yearly: true, method: 'bKash', account: '01700000000');
    expect(inv.amount, 2990);
    expect(c.read(accountProvider).plan, PlanCode.pro);
    await ctrl.cancel();
    expect(c.read(accountProvider).cancelAtPeriodEnd, isTrue);
    expect(c.read(accountProvider).plan, PlanCode.pro);
  });

  testWidgets('privacy: deletion request can be cancelled', (tester) async {
    await tester.pumpWidget(testApp(const PrivacyScreen(), lang: AppLanguage.en));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('privacy.delete')));
    await tester.tap(find.byKey(const Key('privacy.delete')));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(FilledButton).last);
    await tester.pumpAndSettle();
    expect(find.text('Cancel deletion'), findsOneWidget);
    await tester.ensureVisible(find.text('Cancel deletion'));
    await tester.tap(find.text('Cancel deletion'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('privacy.delete')), findsOneWidget);
  });

  testWidgets('support: sends a ticket', (tester) async {
    await tester.pumpWidget(testApp(const SupportScreen(), lang: AppLanguage.en));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('support.message')), 'The avatar did not speak on my phone.');
    await tester.ensureVisible(find.byKey(const Key('support.send')));
    await tester.tap(find.byKey(const Key('support.send')));
    await tester.pumpAndSettle();
    expect(find.text('My tickets'), findsOneWidget);
  });
}
