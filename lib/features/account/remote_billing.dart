import '../../core/network/api_client.dart';
import 'account_controller.dart';

/// Subscription and payments on the education-backend (`/billing/*`).
class RemoteBilling {
  RemoteBilling(this._api);

  final ApiClient _api;

  static Map<String, dynamic> _map(Object? d) => (d! as Map).cast<String, dynamic>();

  static String methodKey(String label) => switch (label.toLowerCase()) {
    'nagad' => 'nagad_mock',
    'card' => 'card_mock',
    'bank' => 'bank_mock',
    _ => 'bkash_mock',
  };

  static String methodLabel(String key) => switch (key) {
    'nagad_mock' => 'Nagad',
    'card_mock' => 'Card',
    'bank_mock' => 'Bank',
    _ => 'bKash',
  };

  static PlanCode planCode(String? code) => PlanCode.values.where((p) => p.name == code).firstOrNull ?? PlanCode.free;

  /// Applies `GET /billing/me` to the local account state (privacy, tickets stay on the device).
  static AccountState apply(AccountState s, Map<String, dynamic> me) {
    final sub = me['subscription'] as Map?;
    final payments = [for (final p in me['payments'] as List? ?? const []) (p as Map).cast<String, dynamic>()];
    return s.copyWith(
      plan: planCode(sub?['planCode'] as String?),
      yearly: sub?['cycle'] == 'yearly',
      renewsAt: () => sub?['renewsAt'] == null ? null : DateTime.parse(sub!['renewsAt'] as String),
      cancelAtPeriodEnd: sub?['cancelAt'] != null,
      invoices: [
        for (final p in payments)
          if (p['status'] == 'success')
            Invoice(p['invoiceNo'] as String? ?? p['id'] as String, planCode(p['planCode'] as String?), sub?['cycle'] == 'yearly', (p['amount'] as num).round(), methodLabel(p['method'] as String? ?? ''), DateTime.parse(p['createdAt'] as String)),
      ],
    );
  }

  Future<Map<String, dynamic>> me() async => (await _api.get('/billing/me', parse: _map)).data;

  /// Returns the payment status (`success`, `pending`, `failed`).
  Future<String> checkout({required PlanCode plan, required bool yearly, required String method, required String account, String? coupon}) async {
    final res = await _api.post(
      '/billing/checkout',
      body: {'planCode': plan.name, 'cycle': yearly ? 'yearly' : 'monthly', 'method': methodKey(method), 'account': account, 'couponCode': ?coupon},
      parse: _map,
    );
    return res.data['status'] as String? ?? 'success';
  }

  Future<void> cancel() => _api.post('/billing/cancel', body: {'reason': ''}, parse: (d) => d);

  Future<void> resume() => _api.post('/billing/resume', parse: (d) => d);
}
