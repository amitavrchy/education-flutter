import 'package:flutter_test/flutter_test.dart';
import 'package:shikkhaai_mobile/features/account/account_controller.dart';
import 'package:shikkhaai_mobile/features/account/remote_billing.dart';

void main() {
  test('payment methods map to the backend mock providers', () {
    expect(RemoteBilling.methodKey('bKash'), 'bkash_mock');
    expect(RemoteBilling.methodKey('Card'), 'card_mock');
    expect(RemoteBilling.methodLabel('nagad_mock'), 'Nagad');
  });

  test('/billing/me updates plan, cycle, renewal, cancellation and invoices only', () {
    const before = AccountState(privacy: {'progress': false});
    final after = RemoteBilling.apply(before, {
      'subscription': {'planCode': 'pro', 'cycle': 'yearly', 'renewsAt': '2027-01-01T00:00:00.000Z', 'cancelAt': '2027-01-01T00:00:00.000Z'},
      'payments': [
        {'id': 'p1', 'invoiceNo': 'INV-1', 'planCode': 'pro', 'amount': 2990, 'method': 'card_mock', 'status': 'success', 'createdAt': '2026-11-01T00:00:00.000Z'},
        {'id': 'p2', 'planCode': 'pro', 'amount': 2990, 'method': 'card_mock', 'status': 'failed', 'createdAt': '2026-11-02T00:00:00.000Z'},
      ],
    });
    expect(after.plan, PlanCode.pro);
    expect(after.yearly, isTrue);
    expect(after.cancelAtPeriodEnd, isTrue);
    expect(after.invoices.single.id, 'INV-1');
    expect(after.privacy['progress'], isFalse);
  });

  test('no subscription means the free plan', () {
    expect(RemoteBilling.apply(const AccountState(plan: PlanCode.pro), {'subscription': null, 'payments': <Object>[]}).plan, PlanCode.free);
  });
}
