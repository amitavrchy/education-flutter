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
    'nagad' || 'nagad_mock' => 'Nagad',
    'rocket' => 'Rocket',
    'upay' => 'Upay',
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

  /// Wallet numbers students send money to (only enabled ones).
  Future<List<WalletNumber>> walletNumbers() async {
    final doc = (await _api.get('/billing/payment-settings', parse: _map)).data;
    return [
      for (final m in doc['methods'] as List? ?? const [])
        if (WalletNumber.fromJson((m as Map).cast<String, dynamic>()) case final w when w.enabled && w.number.isNotEmpty) w,
    ];
  }

  /// Manual payment: the payer's number and the transaction id; an admin verifies it.
  Future<Map<String, dynamic>> submitManual({required PlanCode plan, required bool yearly, required String method, required String sender, required String transactionId, String? coupon}) async =>
      (await _api.post(
        '/billing/checkout',
        body: {'planCode': plan.name, 'cycle': yearly ? 'yearly' : 'monthly', 'method': method, 'account': sender, 'transactionId': transactionId, 'couponCode': ?coupon},
        parse: _map,
      )).data;

  /// The payment waiting for an admin, if any (from `GET /billing/me`).
  static Map<String, dynamic>? awaitingVerification(Map<String, dynamic> me) => [
    for (final p in me['payments'] as List? ?? const [])
      if ((p as Map)['status'] == 'pending' && p['verification'] == 'awaiting') p.cast<String, dynamic>(),
  ].firstOrNull;

  Future<void> cancel() => _api.post('/billing/cancel', body: {'reason': ''}, parse: (d) => d);

  Future<void> resume() => _api.post('/billing/resume', parse: (d) => d);
}

/// A bKash / Nagad / Rocket / Upay number from the admin's payment settings.
class WalletNumber {
  const WalletNumber({required this.method, required this.number, required this.accountType, required this.enabled, this.instructions = ''});

  factory WalletNumber.fromJson(Map<String, dynamic> j) => WalletNumber(
    method: j['method'] as String? ?? 'bkash',
    number: j['number'] as String? ?? '',
    accountType: j['accountType'] as String? ?? 'personal',
    enabled: j['enabled'] as bool? ?? false,
    instructions: j['instructions'] as String? ?? '',
  );

  final String method;
  final String number;

  /// personal | agent | merchant
  final String accountType;
  final bool enabled;
  final String instructions;
}

