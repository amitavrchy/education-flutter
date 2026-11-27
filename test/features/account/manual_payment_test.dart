import 'package:flutter_test/flutter_test.dart';
import 'package:shikkhaai_mobile/features/account/account_controller.dart';
import 'package:shikkhaai_mobile/features/account/remote_billing.dart';

import '../../helpers/fake_server.dart';

void main() {
  test('API mode: wallet numbers, manual submission and the awaiting payment', () async {
    final server = FakeServer();
    server.responses['GET /billing/payment-settings'] = {
      'id': 'payment',
      'methods': [
        {'method': 'bkash', 'number': '01700000000', 'accountType': 'personal', 'enabled': true, 'instructions': 'Send Money'},
        {'method': 'nagad', 'number': '', 'accountType': 'personal', 'enabled': true},
      ],
    };
    server.responses['POST /billing/checkout'] = {'id': 'pay-1', 'status': 'pending', 'verification': 'awaiting', 'transactionId': 'ABC123XYZ', 'invoiceNo': 'INV-1'};
    final billing = RemoteBilling(server.client);

    final numbers = await billing.walletNumbers();
    expect(numbers.map((w) => w.method), ['bkash']); // a method without a number is hidden
    expect(numbers.single.instructions, 'Send Money');

    final p = await billing.submitManual(plan: PlanCode.pro, yearly: false, method: 'bkash', sender: '01811111111', transactionId: 'ABC123XYZ');
    expect(p['verification'], 'awaiting');
    expect(server.lastBody['/billing/checkout'], {'planCode': 'pro', 'cycle': 'monthly', 'method': 'bkash', 'account': '01811111111', 'transactionId': 'ABC123XYZ'});

    expect(RemoteBilling.awaitingVerification({'payments': [p]})?['transactionId'], 'ABC123XYZ');
    expect(RemoteBilling.awaitingVerification({'payments': [{...p, 'status': 'success', 'verification': 'approved'}]}), isNull);
    expect(RemoteBilling.methodLabel('rocket'), 'Rocket');
  });
}
