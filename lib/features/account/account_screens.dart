import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/router/app_routes.dart';
import '../../core/l10n/tr.dart';
import '../../core/network/api_exception.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/time_format.dart';
import '../../mock/seed/curriculum_seed.dart';
import '../../shared/widgets/app_page_scaffold.dart';
import '../../shared/widgets/badges.dart';
import '../../shared/widgets/feedback.dart';
import '../../shared/widgets/section_header.dart';
import '../curriculum/domain/curriculum_models.dart';
import '../parent/guardian_controller.dart' show demoLinkCode;
import '../profile/application/student_profile_controller.dart';
import 'account_controller.dart';

abstract final class AccStrings {
  static const profile = Tr('প্রোফাইল', 'Profile');
  static const name = Tr('নাম', 'Name');
  static const level = Tr('স্তর', 'Level');
  static const classYear = Tr('শ্রেণি', 'Class');
  static const group = Tr('বিভাগ', 'Group');
  static const board = Tr('বোর্ড', 'Board');
  static const school = Tr('শিক্ষাপ্রতিষ্ঠানের নাম', 'School / college name');
  static const examYear = Tr('পরীক্ষার বছর', 'Exam year');
  static const targetGpa = Tr('লক্ষ্য GPA', 'Target GPA');
  static const daily = Tr('দৈনিক পড়ার লক্ষ্য (মিনিট)', 'Daily study goal (min)');
  static const save = Tr('সংরক্ষণ', 'Save');
  static const saved = Tr('প্রোফাইল সংরক্ষিত হয়েছে', 'Profile saved');
  static const more = Tr('অ্যাকাউন্ট', 'Account');
  static const subscription = Tr('সাবস্ক্রিপশন', 'Subscription');
  static const privacy = Tr('গোপনীয়তা ও নিরাপত্তা', 'Privacy & security');
  static const support = Tr('সাহায্য ও মতামত', 'Help & feedback');
  static const settings = Tr('সেটিংস', 'Settings');
  static const current = Tr('বর্তমান প্ল্যান: {p}', 'Current plan: {p}');
  static const renews = Tr('নবায়ন: {d}', 'Renews: {d}');
  static const ends = Tr('মেয়াদ শেষে ফ্রি প্ল্যানে ফিরবে: {d}', 'Returns to Free on {d}');
  static const monthly = Tr('মাসিক', 'Monthly');
  static const yearly = Tr('বার্ষিক (২ মাস ফ্রি)', 'Yearly (2 months free)');
  static const perMonth = Tr('/মাস', '/month');
  static const perYear = Tr('/বছর', '/year');
  static const trial = Tr('{n} দিনের ফ্রি ট্রায়াল', '{n}-day free trial');
  static const choose = Tr('বেছে নাও', 'Choose');
  static const currentBadge = Tr('বর্তমান', 'Current');
  static const cancel = Tr('সাবস্ক্রিপশন বাতিল', 'Cancel subscription');
  static const resume = Tr('বাতিল ফিরিয়ে নাও', 'Keep subscription');
  static const invoices = Tr('পেমেন্ট ইতিহাস', 'Payment history');
  static const checkout = Tr('পেমেন্ট (সিমুলেটেড)', 'Checkout (simulated)');
  static const method = Tr('পেমেন্ট পদ্ধতি', 'Payment method');
  static const account = Tr('মোবাইল / কার্ড নম্বর', 'Mobile / card number');
  static const coupon = Tr('কুপন কোড', 'Coupon code');
  static const apply = Tr('প্রয়োগ', 'Apply');
  static const total = Tr('মোট: ৳{n}', 'Total: ৳{n}');
  static const discount = Tr('ছাড়: ৳{n}', 'Discount: ৳{n}');
  static const pay = Tr('পেমেন্ট করো', 'Pay');
  static const paid = Tr('পেমেন্ট সফল — প্ল্যান চালু হয়েছে (ডেমো)', 'Payment successful — plan active (demo)');
  static const demoPay = Tr('ডেমো: কোনো আসল টাকা কাটা হয় না। টেস্ট কার্ড 4000 0000 0000 0002 সবসময় ব্যর্থ হয়।', 'Demo: no real money is charged. Test card 4000 0000 0000 0002 always fails.');
  static const sharing = Tr('অভিভাবকের সাথে কী শেয়ার হবে', 'What your guardian can see');
  static const shareProgress = Tr('অগ্রগতি', 'Progress');
  static const shareScores = Tr('পরীক্ষার নম্বর', 'Exam scores');
  static const shareChats = Tr('AI কথোপকথন', 'AI conversations');
  static const leaderboard = Tr('লিডারবোর্ডে দেখাও', 'Show me on leaderboards');
  static const history = Tr('AI কথোপকথন সংরক্ষণ', 'Save AI conversation history');
  static const retention = Tr('ডেটা কতদিন রাখা হবে', 'Data retention');
  static const months = Tr('{n} মাস', '{n} months');
  static const yourData = Tr('তোমার ডেটা', 'Your data');
  static const export = Tr('আমার ডেটা ডাউনলোডের অনুরোধ', 'Request a copy of my data');
  static const exportSent = Tr('অনুরোধ পাঠানো হয়েছে — প্রস্তুত হলে নোটিফিকেশন পাবে', 'Request sent — you will be notified when it is ready');
  static const delete = Tr('অ্যাকাউন্ট মোছার অনুরোধ', 'Request account deletion');
  static const deleteConfirm = Tr('৩০ দিন পর সব তথ্য স্থায়ীভাবে মুছে যাবে। এর মধ্যে বাতিল করা যাবে।', 'All data is permanently deleted after 30 days; you can cancel before then.');
  static const deletionPending = Tr('মোছার অনুরোধ চলছে — {d} তারিখে মুছে যাবে', 'Deletion pending — on {d}');
  static const cancelDeletion = Tr('মোছা বাতিল করো', 'Cancel deletion');
  static const chatsPrivate = Tr('AI কথোপকথন ডিফল্টভাবে প্রাইভেট।', 'AI conversations are private by default.');
  static const faq = Tr('সচরাচর জিজ্ঞাসা', 'FAQ');
  static const searchFaq = Tr('প্রশ্ন খুঁজুন', 'Search questions');
  static const contact = Tr('আমাদের লেখো', 'Contact us');
  static const topic = Tr('বিষয়', 'Topic');
  static const message = Tr('বার্তা', 'Message');
  static const send = Tr('পাঠাও', 'Send');
  static const ticketSent = Tr('টিকিট তৈরি হয়েছে — সাধারণত ২৪ ঘণ্টায় উত্তর দিই', 'Ticket created — we usually reply within 24 hours');
  static const tickets = Tr('আমার টিকিট', 'My tickets');
  static const needMessage = Tr('বার্তা লেখো (কমপক্ষে ১০ অক্ষর)', 'Write a message (at least 10 characters)');
}

/// Academic profile + entry points to the other account pages.
class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  late var _p = ref.read(studentProfileProvider);
  late final _name = TextEditingController(text: _p.name);
  late final _school = TextEditingController(text: _p.institution);

  @override
  void dispose() {
    _name.dispose();
    _school.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return AppPageScaffold(
      title: context.tr(AccStrings.profile),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(key: const Key('profile.name'), controller: _name, decoration: InputDecoration(labelText: context.tr(AccStrings.name))),
          const SizedBox(height: AppSpacing.md),
          SegmentedButton<EducationLevel>(
            segments: [for (final l in EducationLevel.values) ButtonSegment(value: l, label: Text(context.tr(l.label)))],
            selected: {_p.level},
            onSelectionChanged: (v) => setState(() => _p = _p.copyWith(level: v.first, classYear: v.first.classes.last)),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<int>(
                  isExpanded: true,
                  initialValue: _p.level.classes.contains(_p.classYear) ? _p.classYear : _p.level.classes.last,
                  decoration: InputDecoration(labelText: context.tr(AccStrings.classYear)),
                  items: [for (final c in _p.level.classes) DropdownMenuItem(value: c, child: Text(context.n(c)))],
                  onChanged: (v) => setState(() => _p = _p.copyWith(classYear: v)),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: DropdownButtonFormField<AcademicGroup>(
                  isExpanded: true,
                  initialValue: _p.group,
                  decoration: InputDecoration(labelText: context.tr(AccStrings.group)),
                  items: [for (final g in AcademicGroup.values) DropdownMenuItem(value: g, child: Text(context.tr(g.label)))],
                  onChanged: (v) => setState(() => _p = _p.copyWith(group: v)),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  isExpanded: true,
                  initialValue: _p.boardId,
                  decoration: InputDecoration(labelText: context.tr(AccStrings.board)),
                  items: [for (final b in educationBoards) DropdownMenuItem(value: b.id, child: Text(context.tr(b.name)))],
                  onChanged: (v) => setState(() => _p = _p.copyWith(boardId: v)),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: DropdownButtonFormField<int>(
                  isExpanded: true,
                  initialValue: _p.examYear,
                  decoration: InputDecoration(labelText: context.tr(AccStrings.examYear)),
                  items: [for (var y = 2026; y <= 2030; y++) DropdownMenuItem(value: y, child: Text(context.n(y)))],
                  onChanged: (v) => setState(() => _p = _p.copyWith(examYear: v)),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(controller: _school, decoration: InputDecoration(labelText: context.tr(AccStrings.school))),
          const SizedBox(height: AppSpacing.md),
          Text('${context.tr(AccStrings.targetGpa)}: ${context.n(_p.targetGpa.toStringAsFixed(2))}', style: text.labelLarge),
          Slider(value: _p.targetGpa, min: 3, max: 5, divisions: 8, onChanged: (v) => setState(() => _p = _p.copyWith(targetGpa: v))),
          Text('${context.tr(AccStrings.daily)}: ${context.n(_p.dailyMinutes)}', style: text.labelLarge),
          Slider(value: _p.dailyMinutes.toDouble(), min: 15, max: 240, divisions: 15, onChanged: (v) => setState(() => _p = _p.copyWith(dailyMinutes: v.round()))),
          const SizedBox(height: AppSpacing.sm),
          FilledButton(
            key: const Key('profile.save'),
            onPressed: () async {
              await ref.read(studentProfileProvider.notifier).update((_) => _p.copyWith(name: _name.text.trim(), institution: _school.text.trim()));
              if (context.mounted) context.showSnack(AccStrings.saved);
            },
            child: Text(context.tr(AccStrings.save)),
          ),
          SectionHeader(title: context.tr(AccStrings.more)),
          for (final (icon, label, route) in [
            (Icons.workspace_premium_outlined, AccStrings.subscription, AppRoutes.subscription),
            (Icons.shield_outlined, AccStrings.privacy, AppRoutes.privacy),
            (Icons.support_agent, AccStrings.support, AppRoutes.support),
            (Icons.settings_outlined, AccStrings.settings, AppRoutes.settings),
          ])
            ListTile(contentPadding: EdgeInsets.zero, leading: Icon(icon), title: Text(context.tr(label)), trailing: const Icon(Icons.chevron_right), onTap: () => context.push(route)),
        ],
      ),
    );
  }
}

/// Plans, simulated checkout with coupons, cancel/resume and payment history.
class SubscriptionScreen extends ConsumerStatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  ConsumerState<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends ConsumerState<SubscriptionScreen> {
  bool _yearly = false;

  Future<void> _checkout(Plan plan) async {
    final ok = await showModalBottomSheet<bool>(context: context, isScrollControlled: true, showDragHandle: true, builder: (_) => _CheckoutSheet(plan: plan, yearly: _yearly));
    if (ok == true && mounted) context.showSnack(AccStrings.paid);
  }

  @override
  Widget build(BuildContext context) {
    final acc = ref.watch(accountProvider);
    final ctrl = ref.read(accountProvider.notifier);
    final text = Theme.of(context).textTheme;
    final current = planOf(acc.plan);
    return AppPageScaffold(
      title: context.tr(AccStrings.subscription),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Card(
            margin: EdgeInsets.zero,
            child: ListTile(
              leading: const Icon(Icons.workspace_premium),
              title: Text(context.tr(AccStrings.current.fill({'p': context.tr(current.name)}))),
              subtitle: acc.renewsAt == null
                  ? null
                  : Text(context.tr((acc.cancelAtPeriodEnd ? AccStrings.ends : AccStrings.renews).fill({'d': shortDate(acc.renewsAt!, context.lang)}))),
              trailing: acc.plan == PlanCode.free
                  ? null
                  : TextButton(onPressed: acc.cancelAtPeriodEnd ? ctrl.resume : ctrl.cancel, child: Text(context.tr(acc.cancelAtPeriodEnd ? AccStrings.resume : AccStrings.cancel))),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          SegmentedButton<bool>(
            segments: [ButtonSegment(value: false, label: Text(context.tr(AccStrings.monthly))), ButtonSegment(value: true, label: Text(context.tr(AccStrings.yearly)))],
            selected: {_yearly},
            onSelectionChanged: (v) => setState(() => _yearly = v.first),
          ),
          const SizedBox(height: AppSpacing.md),
          for (final p in plans)
            Card(
              margin: const EdgeInsets.only(bottom: AppSpacing.sm),
              shape: p.highlighted ? RoundedRectangleBorder(side: BorderSide(color: Theme.of(context).colorScheme.primary, width: 2), borderRadius: BorderRadius.circular(12)) : null,
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(child: Text(context.tr(p.name), style: text.titleMedium)),
                        if (p.code == acc.plan) Pill(context.tr(AccStrings.currentBadge), tone: Tone.success),
                      ],
                    ),
                    Text('৳${context.n(_yearly ? p.yearly : p.monthly)}${context.tr(_yearly ? AccStrings.perYear : AccStrings.perMonth)}', style: text.headlineSmall),
                    if (p.trialDays > 0) Text(context.tr(AccStrings.trial.fill({'n': p.trialDays})), style: text.bodySmall?.copyWith(color: Theme.of(context).colorScheme.primary)),
                    const SizedBox(height: AppSpacing.xs),
                    for (final f in p.features) Row(children: [const Icon(Icons.check, size: 16), const SizedBox(width: AppSpacing.xs), Expanded(child: Text(context.tr(f)))]),
                    if (p.code != PlanCode.free && p.code != acc.plan)
                      Align(
                        alignment: Alignment.centerRight,
                        child: FilledButton(key: Key('plan.${p.code.name}'), onPressed: () => _checkout(p), child: Text(context.tr(AccStrings.choose))),
                      ),
                  ],
                ),
              ),
            ),
          if (acc.invoices.isNotEmpty) ...[
            SectionHeader(title: context.tr(AccStrings.invoices)),
            for (final i in acc.invoices)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.receipt_long_outlined),
                title: Text('${context.tr(planOf(i.plan).name)} · ৳${context.n(i.amount)}'),
                subtitle: Text('${i.id} · ${i.method} · ${shortDate(i.at, context.lang)}'),
              ),
          ],
          const SizedBox(height: AppSpacing.sm),
          InfoBanner(message: context.tr(AccStrings.demoPay)),
        ],
      ),
    );
  }
}

class _CheckoutSheet extends ConsumerStatefulWidget {
  const _CheckoutSheet({required this.plan, required this.yearly});

  final Plan plan;
  final bool yearly;

  @override
  ConsumerState<_CheckoutSheet> createState() => _CheckoutSheetState();
}

class _CheckoutSheetState extends ConsumerState<_CheckoutSheet> {
  String _method = 'bKash';
  final _account = TextEditingController();
  final _coupon = TextEditingController();
  Coupon? _applied;
  String? _error;
  bool _busy = false;

  @override
  void dispose() {
    _account.dispose();
    _coupon.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final price = widget.yearly ? widget.plan.yearly : widget.plan.monthly;
    final (total, discount) = priceWithCoupon(price, _applied);
    final ctrl = ref.read(accountProvider.notifier);
    return Padding(
      padding: EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, MediaQuery.viewInsetsOf(context).bottom + AppSpacing.lg),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('${context.tr(AccStrings.checkout)} — ${context.tr(widget.plan.name)}', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: AppSpacing.md),
            Text(context.tr(AccStrings.method)),
            Wrap(spacing: AppSpacing.xs, children: [for (final m in const ['bKash', 'Nagad', 'Card', 'Bank']) ChoiceChip(label: Text(m), selected: _method == m, onSelected: (_) => setState(() => _method = m))]),
            const SizedBox(height: AppSpacing.sm),
            TextField(key: const Key('checkout.account'), controller: _account, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: context.tr(AccStrings.account))),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Expanded(child: TextField(key: const Key('checkout.coupon'), controller: _coupon, decoration: InputDecoration(labelText: context.tr(AccStrings.coupon)))),
                TextButton(
                  onPressed: () {
                    try {
                      setState(() {
                        _applied = ctrl.validateCoupon(_coupon.text, widget.plan.code);
                        _error = null;
                      });
                    } on ApiException catch (e) {
                      setState(() {
                        _applied = null;
                        _error = e.message;
                      });
                    }
                  },
                  child: Text(context.tr(AccStrings.apply)),
                ),
              ],
            ),
            if (_error != null) Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
            const SizedBox(height: AppSpacing.sm),
            if (discount > 0) Text(context.tr(AccStrings.discount.fill({'n': discount}))),
            Text(context.tr(AccStrings.total.fill({'n': total})), style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: AppSpacing.md),
            FilledButton(
              key: const Key('checkout.pay'),
              onPressed: _busy
                  ? null
                  : () async {
                      if (_account.text.trim().length < 6) return setState(() => _error = context.tr(AccStrings.account));
                      setState(() => _busy = true);
                      try {
                        await ctrl.checkout(plan: widget.plan.code, yearly: widget.yearly, method: _method, account: _account.text, coupon: _applied);
                        if (context.mounted) Navigator.pop(context, true);
                      } on ApiException catch (e) {
                        setState(() => _error = e.message);
                      } finally {
                        if (mounted) setState(() => _busy = false);
                      }
                    },
              child: _busy ? const SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2)) : Text(context.tr(AccStrings.pay)),
            ),
          ],
        ),
      ),
    );
  }
}

/// Sharing choices, retention, export and deletion requests.
class PrivacyScreen extends ConsumerWidget {
  const PrivacyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final acc = ref.watch(accountProvider);
    final ctrl = ref.read(accountProvider.notifier);
    return AppPageScaffold(
      title: context.tr(AccStrings.privacy),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InfoBanner(message: context.tr(AccStrings.chatsPrivate), icon: Icons.lock_outline),
          SectionHeader(title: context.tr(AccStrings.sharing)),
          for (final (key, label, fallback) in [
            ('progress', AccStrings.shareProgress, true),
            ('scores', AccStrings.shareScores, true),
            ('calendar', const Tr('অভিভাবকের সাথে স্টাডি ক্যালেন্ডার শেয়ার', 'Share my study calendar with guardians'), true),
            ('feedback', const Tr('অভিভাবকের সাথে শিক্ষকের মন্তব্য শেয়ার', 'Share teacher feedback with guardians'), true),
            ('conversations', AccStrings.shareChats, false),
          ])
            SwitchListTile(key: Key('privacy.$key'), contentPadding: EdgeInsets.zero, title: Text(context.tr(label)), value: acc.privacy[key] ?? fallback, onChanged: (v) => ctrl.setPrivacy(key, v)),
          Card(
            margin: const EdgeInsets.only(top: AppSpacing.sm),
            child: ListTile(
              leading: const Icon(Icons.link),
              title: Text(context.tr(const Tr('অভিভাবক যুক্ত করার কোড', 'Code to link a guardian'))),
              subtitle: Text(context.tr(const Tr('অভিভাবক এই কোড দিয়ে তোমাকে যুক্ত করতে পারবেন। কী দেখবেন তা তুমিই ঠিক করো।', 'Your guardian links you with this code. You decide what they see.'))),
              trailing: SelectableText(demoLinkCode, key: const Key('privacy.linkCode'), style: Theme.of(context).textTheme.titleMedium),
            ),
          ),
          const Divider(),
          SwitchListTile(contentPadding: EdgeInsets.zero, title: Text(context.tr(AccStrings.leaderboard)), value: acc.privacy['leaderboard'] ?? true, onChanged: (v) => ctrl.setPrivacy('leaderboard', v)),
          SwitchListTile(contentPadding: EdgeInsets.zero, title: Text(context.tr(AccStrings.history)), value: acc.privacy['history'] ?? true, onChanged: (v) => ctrl.setPrivacy('history', v)),
          DropdownButtonFormField<int>(
            isExpanded: true,
            initialValue: acc.retentionMonths,
            decoration: InputDecoration(labelText: context.tr(AccStrings.retention)),
            items: [for (final m in const [6, 12, 24, 36]) DropdownMenuItem(value: m, child: Text(context.tr(AccStrings.months.fill({'n': m}))))],
            onChanged: (v) => ctrl.setRetention(v ?? acc.retentionMonths),
          ),
          SectionHeader(title: context.tr(AccStrings.yourData)),
          OutlinedButton.icon(
            onPressed: acc.exportRequestedAt != null
                ? null
                : () async {
                    try {
                      await ctrl.requestExport();
                      if (context.mounted) context.showSnack(AccStrings.exportSent);
                    } on ApiException catch (e) {
                      if (context.mounted) context.showErrorSnack(e);
                    }
                  },
            icon: const Icon(Icons.download_outlined),
            label: Text(acc.exportRequestedAt == null ? context.tr(AccStrings.export) : '${context.tr(AccStrings.exportSent)} · ${relativeTime(acc.exportRequestedAt!, context.lang)}'),
          ),
          const SizedBox(height: AppSpacing.sm),
          if (acc.deletionRequestedAt != null) ...[
            InfoBanner(
              tone: Tone.warning,
              message: context.tr(AccStrings.deletionPending.fill({'d': shortDate(acc.deletionRequestedAt!.add(const Duration(days: 30)), context.lang)})),
              action: TextButton(onPressed: ctrl.cancelDeletion, child: Text(context.tr(AccStrings.cancelDeletion))),
            ),
          ] else
            OutlinedButton.icon(
              key: const Key('privacy.delete'),
              style: OutlinedButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.error),
              onPressed: () async {
                final ok = await showConfirmDialog(context, title: AccStrings.delete, message: AccStrings.deleteConfirm, destructive: true);
                if (ok) await ctrl.requestDeletion();
              },
              icon: const Icon(Icons.delete_forever_outlined),
              label: Text(context.tr(AccStrings.delete)),
            ),
        ],
      ),
    );
  }
}

const _faq = [
  (Tr('১৮ বছরের নিচে হলে কী লাগবে?', "What if I'm under 18?"), Tr('কিছু লাগবে না — যেকোনো বয়সের শিক্ষার্থী নিজেই অ্যাকাউন্ট খুলতে পারে।', 'Nothing extra — students of any age can sign up on their own.')),
  (Tr('বইয়ের শিক্ষক (অ্যাভাটার) কী?', 'What is the book teacher (avatar)?'), Tr('প্রতিটি পাঠ্যবইয়ের একজন 2D শিক্ষক আছেন। লিখে বা কথা বলে প্রশ্ন করলে শুধু ওই বই থেকে, পৃষ্ঠা নম্বরসহ উত্তর দেন।', 'Each textbook has a 2D teacher. Ask by typing or speaking and it answers only from that book, with page numbers.')),
  (Tr('AI উত্তর কি সবসময় সঠিক?', 'Are AI answers always right?'), Tr('উত্তরগুলো উৎসসহ দেওয়া হয়, তবু গুরুত্বপূর্ণ তথ্য বই ও শিক্ষকের সাথে মিলিয়ে নাও। ভুল মনে হলে রিপোর্ট করো।', 'Answers come with sources, but check important facts with your book and teacher. Report anything that looks wrong.')),
  (Tr('অভিভাবক কি আমার চ্যাট দেখতে পান?', 'Can my guardian see my chats?'), Tr('না, ডিফল্টে AI কথোপকথন প্রাইভেট। গোপনীয়তা পাতা থেকে তুমি শেয়ারিং ঠিক করো।', 'No — AI conversations are private by default. You control sharing on the privacy page.')),
  (Tr('অফলাইনে কী কী চলে?', 'What works offline?'), Tr('ডাউনলোড করা বই, নোট ও ফ্ল্যাশকার্ড। AI টিউটর ও অ্যাভাটারের জন্য ইন্টারনেট লাগে।', 'Downloaded books, notes and flashcards. The AI tutor and avatar need internet.')),
  (Tr('কীভাবে পেমেন্ট করব?', 'How do I pay?'), Tr('bKash, Nagad, কার্ড বা ব্যাংক (ডেমোতে সব সিমুলেটেড)।', 'bKash, Nagad, card or bank (all simulated in the demo).')),
];

/// FAQ with search, contact form (support tickets).
class SupportScreen extends ConsumerStatefulWidget {
  const SupportScreen({super.key});

  @override
  ConsumerState<SupportScreen> createState() => _SupportScreenState();
}

class _SupportScreenState extends ConsumerState<SupportScreen> {
  String _q = '';
  String _topic = 'general';
  final _message = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _message.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final acc = ref.watch(accountProvider);
    final q = _q.trim().toLowerCase();
    final faq = [for (final f in _faq) if (q.isEmpty || f.$1.matches(q) || f.$2.matches(q)) f];
    return AppPageScaffold(
      title: context.tr(AccStrings.support),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SectionHeader(title: context.tr(AccStrings.faq)),
          TextField(decoration: InputDecoration(prefixIcon: const Icon(Icons.search), hintText: context.tr(AccStrings.searchFaq)), onChanged: (v) => setState(() => _q = v)),
          for (final (qq, a) in faq) ExpansionTile(tilePadding: EdgeInsets.zero, title: Text(context.tr(qq)), children: [Padding(padding: const EdgeInsets.only(bottom: AppSpacing.md), child: Text(context.tr(a)))]),
          SectionHeader(title: context.tr(AccStrings.contact)),
          DropdownButtonFormField<String>(
            isExpanded: true,
            initialValue: _topic,
            decoration: InputDecoration(labelText: context.tr(AccStrings.topic)),
            items: [
              for (final (k, v) in const [
                ('general', Tr('সাধারণ', 'General')),
                ('account', Tr('অ্যাকাউন্ট', 'Account')),
                ('billing', Tr('পেমেন্ট', 'Billing')),
                ('content', Tr('কনটেন্ট ভুল', 'Content error')),
                ('ai', Tr('AI / অ্যাভাটার', 'AI / avatar')),
              ])
                DropdownMenuItem(value: k, child: Text(context.tr(v))),
            ],
            onChanged: (v) => setState(() => _topic = v ?? _topic),
          ),
          const SizedBox(height: AppSpacing.sm),
          TextField(key: const Key('support.message'), controller: _message, minLines: 3, maxLines: 6, decoration: InputDecoration(labelText: context.tr(AccStrings.message))),
          const SizedBox(height: AppSpacing.sm),
          FilledButton(
            key: const Key('support.send'),
            onPressed: _busy
                ? null
                : () async {
                    if (_message.text.trim().length < 10) return context.showSnack(AccStrings.needMessage);
                    setState(() => _busy = true);
                    try {
                      await ref.read(accountProvider.notifier).submitTicket(_topic, _message.text);
                      _message.clear();
                      if (context.mounted) context.showSnack(AccStrings.ticketSent);
                    } on ApiException catch (e) {
                      if (context.mounted) context.showErrorSnack(e);
                    } finally {
                      if (mounted) setState(() => _busy = false);
                    }
                  },
            child: Text(context.tr(AccStrings.send)),
          ),
          if (acc.tickets.isNotEmpty) ...[
            SectionHeader(title: context.tr(AccStrings.tickets)),
            for (final t in acc.tickets)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.confirmation_number_outlined),
                title: Text(t.message, maxLines: 2, overflow: TextOverflow.ellipsis),
                subtitle: Text('${t.id} · ${t.topic} · ${relativeTime(t.at, context.lang)}'),
                trailing: Pill(t.status),
              ),
          ],
        ],
      ),
    );
  }
}
