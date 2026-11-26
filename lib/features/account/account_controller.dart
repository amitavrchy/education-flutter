import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/config/env.dart';
import '../../core/l10n/tr.dart';
import '../../core/mock/mock_simulator.dart';
import '../../core/network/api_exception.dart';
import '../../core/network/network_providers.dart';
import '../../core/storage/local_store.dart';
import 'remote_billing.dart';

enum PlanCode { free, pro, family }

class Plan {
  const Plan(this.code, this.name, this.monthly, this.yearly, this.features, {this.trialDays = 0, this.highlighted = false});

  final PlanCode code;
  final Tr name;
  final int monthly;
  final int yearly;
  final List<Tr> features;
  final int trialDays;
  final bool highlighted;
}

/// Same plans as the web pricing page (prices in BDT).
const plans = [
  Plan(PlanCode.free, Tr('ফ্রি', 'Free'), 0, 0, [Tr('দৈনিক ২০টি AI প্রশ্ন', '20 AI questions a day'), Tr('প্রশ্ন ব্যাংক ও অনুশীলন', 'Question bank & practice'), Tr('৩টি অফলাইন ডাউনলোড', '3 offline downloads')]),
  Plan(PlanCode.pro, Tr('স্টুডেন্ট প্রো', 'Student Pro'), 299, 2990, [Tr('দৈনিক ৩০০টি AI প্রশ্ন', '300 AI questions a day'), Tr('মাসে ৩০০ মিনিট ভয়েস ও অ্যাভাটার', '300 voice & avatar minutes a month'), Tr('হাতের লেখা মূল্যায়ন', 'Handwriting evaluation'), Tr('৫০টি অফলাইন ডাউনলোড', '50 offline downloads')], trialDays: 7, highlighted: true),
  Plan(PlanCode.family, Tr('ফ্যামিলি', 'Family'), 699, 6990, [Tr('৪টি শিক্ষার্থী অ্যাকাউন্ট', '4 student accounts'), Tr('প্রো-এর সব ফিচার', 'All Pro features'), Tr('অভিভাবক রিপোর্ট', 'Guardian reports')], trialDays: 7),
];

Plan planOf(PlanCode c) => plans.firstWhere((p) => p.code == c);

class Coupon {
  const Coupon(this.code, this.plans, {this.percentOff, this.amountOff, this.expired = false});

  final String code;
  final List<PlanCode> plans;
  final int? percentOff;
  final int? amountOff;
  final bool expired;
}

const coupons = [
  Coupon('SSC2027', [PlanCode.pro, PlanCode.family], percentOff: 20),
  Coupon('WELCOME50', [PlanCode.pro], amountOff: 50),
  Coupon('FAMILY30', [PlanCode.family], percentOff: 30),
  Coupon('EID2026', [PlanCode.pro, PlanCode.family], percentOff: 25, expired: true),
];

/// (total, discount) after a coupon.
(int, int) priceWithCoupon(int price, Coupon? c) {
  if (c == null) return (price, 0);
  final discount = c.percentOff != null ? (price * c.percentOff! / 100).round() : (c.amountOff ?? 0);
  final d = discount.clamp(0, price);
  return (price - d, d);
}

class Invoice {
  const Invoice(this.id, this.plan, this.yearly, this.amount, this.method, this.at);

  factory Invoice.fromJson(Map<String, dynamic> j) =>
      Invoice(j['id'] as String, PlanCode.values.byName(j['plan'] as String), j['yearly'] as bool, j['amount'] as int, j['method'] as String, DateTime.parse(j['at'] as String));

  final String id;
  final PlanCode plan;
  final bool yearly;
  final int amount;
  final String method;
  final DateTime at;

  Map<String, dynamic> toJson() => {'id': id, 'plan': plan.name, 'yearly': yearly, 'amount': amount, 'method': method, 'at': at.toIso8601String()};
}

class SupportTicket {
  const SupportTicket(this.id, this.topic, this.message, this.at, {this.status = 'open'});

  factory SupportTicket.fromJson(Map<String, dynamic> j) =>
      SupportTicket(j['id'] as String, j['topic'] as String, j['message'] as String, DateTime.parse(j['at'] as String), status: j['status'] as String? ?? 'open');

  final String id;
  final String topic;
  final String message;
  final DateTime at;
  final String status;

  Map<String, dynamic> toJson() => {'id': id, 'topic': topic, 'message': message, 'at': at.toIso8601String(), 'status': status};
}

/// Subscription, privacy choices, data requests and support tickets (one persisted document).
class AccountState {
  const AccountState({
    this.plan = PlanCode.free,
    this.yearly = false,
    this.renewsAt,
    this.cancelAtPeriodEnd = false,
    this.invoices = const [],
    this.privacy = const {'progress': true, 'scores': true, 'conversations': false, 'leaderboard': true, 'history': true},
    this.retentionMonths = 24,
    this.exportRequestedAt,
    this.deletionRequestedAt,
    this.tickets = const [],
  });

  factory AccountState.fromJson(Map<String, dynamic> j) => AccountState(
    plan: PlanCode.values.byName(j['plan'] as String? ?? 'free'),
    yearly: j['yearly'] as bool? ?? false,
    renewsAt: j['renewsAt'] == null ? null : DateTime.parse(j['renewsAt'] as String),
    cancelAtPeriodEnd: j['cancelAtPeriodEnd'] as bool? ?? false,
    invoices: [for (final i in j['invoices'] as List? ?? const []) Invoice.fromJson((i as Map).cast<String, dynamic>())],
    privacy: (j['privacy'] as Map? ?? const {}).cast<String, bool>(),
    retentionMonths: j['retentionMonths'] as int? ?? 24,
    exportRequestedAt: j['exportRequestedAt'] == null ? null : DateTime.parse(j['exportRequestedAt'] as String),
    deletionRequestedAt: j['deletionRequestedAt'] == null ? null : DateTime.parse(j['deletionRequestedAt'] as String),
    tickets: [for (final t in j['tickets'] as List? ?? const []) SupportTicket.fromJson((t as Map).cast<String, dynamic>())],
  );

  final PlanCode plan;
  final bool yearly;
  final DateTime? renewsAt;
  final bool cancelAtPeriodEnd;
  final List<Invoice> invoices;
  final Map<String, bool> privacy;
  final int retentionMonths;
  final DateTime? exportRequestedAt;
  final DateTime? deletionRequestedAt;
  final List<SupportTicket> tickets;

  AccountState copyWith({
    PlanCode? plan,
    bool? yearly,
    DateTime? Function()? renewsAt,
    bool? cancelAtPeriodEnd,
    List<Invoice>? invoices,
    Map<String, bool>? privacy,
    int? retentionMonths,
    DateTime? Function()? exportRequestedAt,
    DateTime? Function()? deletionRequestedAt,
    List<SupportTicket>? tickets,
  }) => AccountState(
    plan: plan ?? this.plan,
    yearly: yearly ?? this.yearly,
    renewsAt: renewsAt == null ? this.renewsAt : renewsAt(),
    cancelAtPeriodEnd: cancelAtPeriodEnd ?? this.cancelAtPeriodEnd,
    invoices: invoices ?? this.invoices,
    privacy: privacy ?? this.privacy,
    retentionMonths: retentionMonths ?? this.retentionMonths,
    exportRequestedAt: exportRequestedAt == null ? this.exportRequestedAt : exportRequestedAt(),
    deletionRequestedAt: deletionRequestedAt == null ? this.deletionRequestedAt : deletionRequestedAt(),
    tickets: tickets ?? this.tickets,
  );

  Map<String, dynamic> toJson() => {
    'plan': plan.name,
    'yearly': yearly,
    'renewsAt': renewsAt?.toIso8601String(),
    'cancelAtPeriodEnd': cancelAtPeriodEnd,
    'invoices': [for (final i in invoices) i.toJson()],
    'privacy': privacy,
    'retentionMonths': retentionMonths,
    'exportRequestedAt': exportRequestedAt?.toIso8601String(),
    'deletionRequestedAt': deletionRequestedAt?.toIso8601String(),
    'tickets': [for (final t in tickets) t.toJson()],
  };
}

class AccountController extends Notifier<AccountState> {
  static const _col = 'account';
  static const _id = 'me';
  late LocalStore _store;

  @override
  AccountState build() {
    _store = watchStore(ref);
    final doc = _store.get(_col, _id);
    if (_billing != null) Future.microtask(refreshBilling);
    return doc == null ? const AccountState() : AccountState.fromJson(doc);
  }

  RemoteBilling? get _billing => ref.read(remoteBillingProvider);

  /// API mode: pulls the subscription and payments from the server.
  Future<void> refreshBilling() async {
    final billing = _billing;
    if (billing == null || !ref.mounted) return;
    try {
      final me = await billing.me();
      if (ref.mounted) await _save(RemoteBilling.apply(state, me));
    } catch (_) {
      // Offline or signed out: keep the cached plan.
    }
  }

  Future<void> _save(AccountState s) async {
    state = s;
    await _store.put(_col, _id, s.toJson());
  }

  MockSimulator get _sim => ref.read(mockSimulatorProvider);

  Coupon validateCoupon(String code, PlanCode plan) {
    final c = coupons.where((c) => c.code == code.trim().toUpperCase()).firstOrNull;
    if (c == null || c.expired) throw const ApiException(statusCode: 422, code: 'COUPON_INVALID', message: 'কুপনটি সঠিক নয় বা মেয়াদ শেষ।');
    if (!c.plans.contains(plan)) throw const ApiException(statusCode: 422, code: 'COUPON_NOT_APPLICABLE', message: 'এই প্ল্যানে কুপনটি প্রযোজ্য নয়।');
    return c;
  }

  /// Simulated checkout. Card 4000 0000 0000 0002 always declines (test card).
  Future<Invoice> checkout({required PlanCode plan, required bool yearly, required String method, required String account, Coupon? coupon}) async {
    final billing = _billing;
    if (billing == null) return _mockCheckout(plan: plan, yearly: yearly, method: method, account: account, coupon: coupon);
    final status = await billing.checkout(plan: plan, yearly: yearly, method: method, account: account, coupon: coupon?.code);
    if (status == 'failed') throw const ApiException(statusCode: 402, code: 'PAYMENT_DECLINED', message: 'পেমেন্ট প্রত্যাখ্যাত হয়েছে।');
    await refreshBilling();
    return state.invoices.firstOrNull ?? Invoice('pending', plan, yearly, 0, method, DateTime.now());
  }

  Future<Invoice> _mockCheckout({required PlanCode plan, required bool yearly, required String method, required String account, Coupon? coupon}) => _sim.run(() async {
    if (account.replaceAll(' ', '') == '4000000000000002') {
      throw const ApiException(statusCode: 402, code: 'PAYMENT_DECLINED', message: 'পেমেন্ট প্রত্যাখ্যাত হয়েছে (টেস্ট কার্ড)।');
    }
    final p = planOf(plan);
    final (total, _) = priceWithCoupon(yearly ? p.yearly : p.monthly, coupon);
    final now = DateTime.now();
    final inv = Invoice('INV-${now.millisecondsSinceEpoch % 1000000}', plan, yearly, total, method, now);
    await _save(state.copyWith(
      plan: plan,
      yearly: yearly,
      renewsAt: () => now.add(Duration(days: yearly ? 365 : 30)),
      cancelAtPeriodEnd: false,
      invoices: [inv, ...state.invoices],
    ));
    return inv;
  }, latencyFactor: 2);

  Future<void> cancel() async {
    await _billing?.cancel();
    await _save(state.copyWith(cancelAtPeriodEnd: true));
  }

  Future<void> resume() async {
    await _billing?.resume();
    await _save(state.copyWith(cancelAtPeriodEnd: false));
  }

  Future<void> setPrivacy(String key, bool value) => _save(state.copyWith(privacy: {...state.privacy, key: value}));

  Future<void> setRetention(int months) => _save(state.copyWith(retentionMonths: months));

  Future<void> requestExport() => _sim.run(() => _save(state.copyWith(exportRequestedAt: DateTime.now)));

  Future<void> requestDeletion() => _sim.run(() => _save(state.copyWith(deletionRequestedAt: DateTime.now)));

  Future<void> cancelDeletion() => _save(state.copyWith(deletionRequestedAt: () => null));

  Future<SupportTicket> submitTicket(String topic, String message) => _sim.run(() async {
    final t = SupportTicket('T-${DateTime.now().millisecondsSinceEpoch % 100000}', topic, message.trim(), DateTime.now());
    await _save(state.copyWith(tickets: [t, ...state.tickets]));
    return t;
  });
}

/// Server billing in API mode; null with the mock.
final remoteBillingProvider = Provider<RemoteBilling?>((ref) => Env.useMockApi ? null : RemoteBilling(ref.watch(apiClientProvider)));

final accountProvider = NotifierProvider<AccountController, AccountState>(AccountController.new);
