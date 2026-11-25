import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/router/app_routes.dart';
import '../../core/l10n/common_strings.dart';
import '../../core/l10n/tr.dart';
import '../../core/network/api_exception.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/time_format.dart';
import '../../shared/widgets/app_page_scaffold.dart';
import '../../shared/widgets/badges.dart';
import '../../shared/widgets/cards.dart';
import '../../shared/widgets/empty_state.dart';
import '../../shared/widgets/feedback.dart';
import '../../shared/widgets/progress.dart';
import '../../shared/widgets/section_header.dart';
import '../../shared/widgets/stat_card.dart';
import '../dashboard/presentation/widgets/greeting_header.dart';
import '../planner/domain/study_task.dart';
import 'guardian_controller.dart';

abstract final class PStr {
  static const home = Tr('ড্যাশবোর্ড', 'Dashboard');
  static const sub = Tr('সন্তানের পড়াশোনার খবর', "Your child's learning");
  static const week = Tr('এই সপ্তাহ', 'This week');
  static const minutes = Tr('পড়ার সময় (মিনিট)', 'Study time (min)');
  static const vsPrev = Tr('গত সপ্তাহে {n}', 'Last week {n}');
  static const streak = Tr('টানা দিন', 'Day streak');
  static const avg = Tr('গড় নম্বর', 'Average score');
  static const tasks = Tr('কাজ সম্পন্ন / মিস', 'Tasks done / missed');
  static const hidden = Tr('সন্তান এটি শেয়ার করেনি', 'Your child has not shared this');
  static const avatarUsage = Tr('অ্যাভাটার শিক্ষকের ব্যবহার', 'Avatar teacher usage');
  static const children = Tr('আমার সন্তান', 'My children');
  static const childrenSub = Tr('যুক্ত শিক্ষার্থী ও শেয়ার করা তথ্য', 'Linked students and what they share');
  static const link = Tr('সন্তান যুক্ত করো', 'Link a child');
  static const linkCode = Tr('লিংক কোড', 'Link code');
  static const linkCodeHint = Tr('শিক্ষার্থীর অ্যাপ → গোপনীয়তা থেকে কোড নিন (ডেমো: SHK-2741)', "From the student's app → Privacy (demo: SHK-2741)");
  static const relation = Tr('সম্পর্ক', 'Relation');
  static const next = Tr('পরবর্তী', 'Next');
  static const otp = Tr('আপনার ফোনে পাঠানো OTP (ডেমো: 123456)', 'OTP sent to your phone (demo: 123456)');
  static const verify = Tr('যাচাই করো', 'Verify');
  static const linked = Tr('সন্তান যুক্ত হয়েছে', 'Child linked');
  static const unlink = Tr('সংযোগ বিচ্ছিন্ন', 'Unlink');
  static const unlinkConfirm = Tr('এই সন্তানের সাথে সংযোগ বিচ্ছিন্ন করবেন?', 'Unlink this child?');
  static const unlinked = Tr('সংযোগ বিচ্ছিন্ন হয়েছে', 'Unlinked');
  static const active = Tr('সক্রিয়', 'Active');
  static const pending = Tr('যাচাই অপেক্ষমাণ', 'Awaiting verification');
  static const since = Tr('{d} থেকে যুক্ত', 'Linked since {d}');
  static const whatYouSee = Tr('কী দেখা যাবে', 'What you can see');
  static const permNote = Tr('আপনি শেয়ার বন্ধ করতে পারেন; AI কথোপকথন শুধু শিক্ষার্থী নিজে চালু করতে পারে।', 'You can turn sharing off; only the student can turn on AI-conversation sharing.');
  static const linkNote = Tr('যুক্ত হওয়ার পরও কী দেখবেন তা সন্তান নিজে ঠিক করে। AI কথোপকথন ডিফল্টে ব্যক্তিগত।', 'Your child decides what you see, even after linking. AI conversations are private by default.');
  static const noChildren = Tr('কোনো শিক্ষার্থী যুক্ত নেই', 'No linked students');
  static const progress = Tr('অগ্রগতি', 'Progress');
  static const mastery = Tr('বিষয়ভিত্তিক দক্ষতা', 'Subject mastery');
  static const weak = Tr('দুর্বল টপিক', 'Weak topics');
  static const noWeak = Tr('এখন কোনো দুর্বল টপিক নেই', 'No weak topics right now');
  static const results = Tr('ফলাফল', 'Results');
  static const noResults = Tr('এখনো কোনো পরীক্ষার ফল নেই', 'No exam results yet');
  static const reports = Tr('রিপোর্ট', 'Reports');
  static const weekly = Tr('সাপ্তাহিক', 'Weekly');
  static const monthly = Tr('মাসিক', 'Monthly');
  static const download = Tr('ডাউনলোড', 'Download');
  static const downloaded = Tr('রিপোর্ট কপি হয়েছে — যেকোনো অ্যাপে পেস্ট করুন', 'Report copied — paste it into any app');
  static const email = Tr('ইমেইল', 'Email');
  static const emailed = Tr('রিপোর্ট ইমেইলে পাঠানো হয়েছে (ডেমো)', 'Report emailed (demo)');
  static const print = Tr('প্রিন্ট', 'Print');
  static const printed = Tr('প্রিন্ট ডায়ালগ ডেমোতে নেই — ডাউনলোড করে প্রিন্ট করুন', 'No print dialog in the demo — download and print');
  static const calendar = Tr('ক্যালেন্ডার', 'Calendar');
  static const noPlan = Tr('এই দিনে কোনো পরিকল্পনা নেই', 'Nothing planned this day');
  static const feedback = Tr('শিক্ষকের মন্তব্য', 'Teacher feedback');
  static const noFeedback = Tr('কোনো মন্তব্য নেই', 'No feedback yet');
  static const ack = Tr('দেখেছি', 'Acknowledge');
  static const acked = Tr('দেখা হয়েছে', 'Acknowledged');
  static const reply = Tr('উত্তর দিন', 'Reply');
  static const replyHint = Tr('শিক্ষকের জন্য বার্তা…', 'Message for the teacher…');
  static const replied = Tr('বার্তা শিক্ষকের কাছে পাঠানো হয়েছে', 'Message sent to the teacher');
  static const yourReply = Tr('আপনার উত্তর', 'Your reply');
  static const goals = Tr('শেখার লক্ষ্য', 'Learning goals');
  static const goalsSub = Tr('সন্তানের সাথে মিলে বাস্তবসম্মত সাপ্তাহিক লক্ষ্য ঠিক করুন', 'Set realistic weekly goals together with your child');
  static const addGoal = Tr('লক্ষ্য যোগ করুন', 'Add goal');
  static const editGoal = Tr('লক্ষ্য সম্পাদনা', 'Edit goal');
  static const goalTitle = Tr('লক্ষ্য', 'Goal');
  static const goalHint = Tr('যেমন: সপ্তাহে ৮ ঘণ্টা', 'e.g. 8 hours a week');
  static const metric = Tr('পরিমাপ', 'Metric');
  static const target = Tr('সাপ্তাহিক লক্ষ্যমাত্রা', 'Weekly target');
  static const noGoals = Tr('কোনো লক্ষ্য নেই', 'No goals yet');
  static const reached = Tr('লক্ষ্য পূরণ!', 'Goal reached!');
  static const privacy = Tr('গোপনীয়তা', 'Privacy');
  static const privacyBanner = Tr('শিশুর গোপনীয়তা আমাদের অগ্রাধিকার: AI কথোপকথন ডিফল্টে ব্যক্তিগত, তথ্য বিক্রি হয় না, আর কী শেয়ার হবে তা সন্তান নিজে ঠিক করে।', 'Child privacy comes first: AI conversations are private by default, data is never sold, and your child decides what is shared.');
  static const sharedData = Tr('শেয়ার করা তথ্য', 'Shared data');
  static const sharedDataSub = Tr('পরিবর্তন করতে "আমার সন্তান" পাতায় যান।', 'Change this on the "My children" page.');
  static const aiPrivate = Tr('AI কথোপকথন ব্যক্তিগত — অভিভাবক দেখতে পান না।', 'AI conversations are private — guardians cannot see them.');
  static const quick = Tr('আরও দেখুন', 'More');
  static const subscription = Tr('সাবস্ক্রিপশন', 'Subscription');
  static const demoChild = Tr('ডেমো তথ্য', 'Demo data');
  static const liveChild = Tr('এই ডিভাইসের শিক্ষার্থী — লাইভ তথ্য', "This device's student — live data");
  static const onboardTitle = Tr('অভিভাবক পোর্টালে স্বাগতম', 'Welcome to the guardian portal');
  static const onboard1 = Tr('সন্তানের অ্যাপ থেকে লিংক কোড নিয়ে যুক্ত করুন।', 'Link your child with the code from their app.');
  static const onboard2 = Tr('সন্তান যা শেয়ার করে শুধু সেটুকু দেখবেন — অগ্রগতি, ফল, ক্যালেন্ডার।', 'You see only what your child shares — progress, results, calendar.');
  static const onboard3 = Tr('লক্ষ্য ঠিক করুন, শিক্ষকের মন্তব্য পড়ুন, রিপোর্ট ডাউনলোড করুন।', 'Set goals, read teacher feedback, download reports.');
  static const gotIt = Tr('বুঝেছি', 'Got it');
  static const latestFeedback = Tr('সর্বশেষ শিক্ষকের মন্তব্য', 'Latest teacher feedback');
  static const studyByDay = Tr('দিনভিত্তিক পড়ার সময়', 'Study time by day');
  static const reportFooter = Tr('এই রিপোর্টে AI কথোপকথন অন্তর্ভুক্ত নয়। সব তথ্য ডেমো।', 'AI conversations are not included in this report. All data is demo.');
  static const notShared = Tr('শেয়ার করা নেই', 'not shared');
  static const student = Tr('শিক্ষার্থী', 'Student');
  static const period = Tr('সময়কাল', 'Period');
  static const last7 = Tr('গত ৭ দিন', 'Last 7 days');
  static const last30 = Tr('গত ৩০ দিন (আনুমানিক)', 'Last 30 days (approx.)');
  static const classN = Tr('{n}ম শ্রেণি', 'Class {n}');
}

const _relations = ['বাবা', 'মা', 'অভিভাবক', 'ভাই/বোন'];

/// Shows a child picker when more than one child is linked. Reads/writes the selected link.
class ChildSwitcher extends ConsumerWidget {
  const ChildSwitcher({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final g = ref.watch(guardianProvider);
    final active = g.active;
    if (active.length < 2) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            for (final l in active)
              Padding(
                padding: const EdgeInsets.only(right: AppSpacing.xs),
                child: ChoiceChip(
                  key: Key('child.${l.id}'),
                  avatar: CircleAvatar(child: Text(l.studentName.characters.first)),
                  label: Text(l.studentName),
                  selected: g.selected?.id == l.id,
                  onSelected: (_) => ref.read(guardianProvider.notifier).select(l.id),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Runs [builder] with the selected child's summary, or an empty state when none is linked.
class _WithChild extends ConsumerWidget {
  const _WithChild({required this.builder});

  final Widget Function(BuildContext context, ChildSummary s) builder;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final link = ref.watch(guardianProvider).selected;
    final s = link == null ? null : ref.watch(childSummaryProvider(link.id));
    if (s == null) {
      return EmptyState(
        icon: Icons.person_add_alt,
        title: context.tr(PStr.noChildren),
        action: FilledButton(onPressed: () => context.go('/parent/children'), child: Text(context.tr(PStr.link))),
      );
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [const ChildSwitcher(), builder(context, s)]);
  }
}

Widget _hidden(BuildContext context) => InfoBanner(message: context.tr(PStr.hidden), icon: Icons.visibility_off_outlined);

class ParentHomeScreen extends ConsumerWidget {
  const ParentHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final onboarded = ref.watch(guardianProvider.select((g) => g.onboarded));
    return AppPageScaffold(
      title: context.tr(PStr.home),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          GreetingHeader(subtitle: context.tr(PStr.sub)),
          const SizedBox(height: AppSpacing.sm),
          if (!onboarded) const _OnboardingCard(),
          _WithChild(builder: (context, s) => _Dashboard(s: s)),
        ],
      ),
    );
  }
}

class _OnboardingCard extends ConsumerWidget {
  const _OnboardingCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      key: const Key('parent.onboarding'),
      color: context.colors.primaryContainer,
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(context.tr(PStr.onboardTitle), style: context.text.titleMedium),
            const SizedBox(height: AppSpacing.sm),
            for (final (i, t) in [PStr.onboard1, PStr.onboard2, PStr.onboard3].indexed)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(radius: 11, child: Text(context.n(i + 1), style: context.text.labelSmall)),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(child: Text(context.tr(t))),
                  ],
                ),
              ),
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: FilledButton(onPressed: () => ref.read(guardianProvider.notifier).finishOnboarding(), child: Text(context.tr(PStr.gotIt))),
            ),
          ],
        ),
      ),
    );
  }
}

class _Dashboard extends ConsumerWidget {
  const _Dashboard({required this.s});

  final ChildSummary s;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hidden = context.tr(PStr.hidden);
    final notes = s.can(ShareKey.teacherFeedback) ? ref.watch(teacherNotesProvider(s.link.id)) : const <TeacherNote>[];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Card(
          margin: EdgeInsets.zero,
          child: ListTile(
            leading: CircleAvatar(child: Text(s.link.studentName.characters.first)),
            title: Text(s.link.studentName),
            subtitle: Text('${context.tr(PStr.classN.fill({'n': s.link.studentClass}))} · ${context.tr(s.link.self ? PStr.liveChild : PStr.demoChild)}'),
          ),
        ),
        SectionHeader(title: context.tr(PStr.week)),
        StatGrid(
          cards: [
            StatCard(
              label: context.tr(PStr.minutes),
              value: s.can(ShareKey.studyTime) ? context.n(s.minutesWeek) : '—',
              icon: Icons.timer_outlined,
              caption: s.can(ShareKey.studyTime) ? context.tr(PStr.vsPrev.fill({'n': s.minutesPrevWeek})) : hidden,
            ),
            StatCard(label: context.tr(PStr.streak), value: s.can(ShareKey.progress) ? context.n(s.streak) : '—', icon: Icons.local_fire_department_outlined),
            StatCard(
              label: context.tr(PStr.tasks),
              value: s.can(ShareKey.calendar) ? '${context.n(s.tasksDone)} / ${context.n(s.tasksMissed)}' : '—',
              icon: Icons.task_alt,
              caption: s.can(ShareKey.calendar) ? null : hidden,
              onTap: () => context.push(AppRoutes.parentCalendar),
            ),
            StatCard(
              label: context.tr(PStr.avg),
              value: s.can(ShareKey.scores) && s.avgScore != null ? context.pct(s.avgScore!) : '—',
              icon: Icons.grade_outlined,
              caption: s.can(ShareKey.scores) ? null : hidden,
              onTap: () => context.push(AppRoutes.parentResults),
            ),
          ],
        ),
        if (s.can(ShareKey.studyTime)) ...[
          SectionHeader(title: context.tr(PStr.studyByDay)),
          SizedBox(height: 140, child: _WeekBars(minutes: s.weekMinutes)),
        ],
        SectionHeader(title: context.tr(PStr.mastery), actionLabel: context.tr(PStr.progress), onAction: () => context.go('/parent/progress')),
        if (!s.can(ShareKey.progress))
          _hidden(context)
        else
          for (final (name, m) in s.subjectMastery.take(4))
            Padding(padding: const EdgeInsets.only(bottom: AppSpacing.sm), child: LabeledProgress(label: context.tr(name), value: m)),
        if (s.can(ShareKey.progress)) ...[
          SectionHeader(title: context.tr(PStr.weak)),
          if (s.weakTopics.isEmpty)
            Text(context.tr(PStr.noWeak), style: context.text.bodySmall)
          else
            Wrap(
              spacing: AppSpacing.xs,
              runSpacing: AppSpacing.xs,
              children: [for (final (t, _, m) in s.weakTopics.take(4)) Pill('${context.tr(t)} · ${context.pct(m * 100)}', tone: Tone.warning)],
            ),
        ],
        if (notes.isNotEmpty) ...[
          SectionHeader(title: context.tr(PStr.latestFeedback), actionLabel: context.tr(PStr.feedback), onAction: () => context.push(AppRoutes.parentFeedback)),
          Card(
            margin: EdgeInsets.zero,
            child: ListTile(
              leading: const Icon(Icons.rate_review_outlined),
              title: Text('${notes.first.teacher} · ${context.tr(notes.first.subject)}'),
              subtitle: Text(notes.first.message, maxLines: 2, overflow: TextOverflow.ellipsis),
              onTap: () => context.push(AppRoutes.parentFeedback),
            ),
          ),
        ],
        const SizedBox(height: AppSpacing.md),
        InfoBanner(message: context.tr(PStr.aiPrivate), icon: Icons.lock_outline),
        SectionHeader(title: context.tr(PStr.quick)),
        GridView.count(
          crossAxisCount: 3,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: AppSpacing.sm,
          crossAxisSpacing: AppSpacing.sm,
          childAspectRatio: 1.1,
          children: [
            const _QuickTile(icon: Icons.calendar_month_outlined, label: PStr.calendar, route: AppRoutes.parentCalendar),
            const _QuickTile(icon: Icons.flag_outlined, label: PStr.goals, route: AppRoutes.parentGoals),
            const _QuickTile(icon: Icons.rate_review_outlined, label: PStr.feedback, route: AppRoutes.parentFeedback),
            const _QuickTile(icon: Icons.description_outlined, label: PStr.reports, route: AppRoutes.parentReports),
            const _QuickTile(icon: Icons.emoji_events_outlined, label: PStr.results, route: AppRoutes.parentResults),
            const _QuickTile(icon: Icons.co_present_outlined, label: PStr.avatarUsage, route: AppRoutes.avatarActivity),
          ],
        ),
      ],
    );
  }
}

class _QuickTile extends StatelessWidget {
  const _QuickTile({required this.icon, required this.label, required this.route});

  final IconData icon;
  final Tr label;
  final String route;

  @override
  Widget build(BuildContext context) => TapCard(
    onTap: () => context.push(route),
    padding: const EdgeInsets.all(AppSpacing.sm),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, color: context.colors.primary),
        const SizedBox(height: AppSpacing.xs),
        Text(context.tr(label), textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis, style: context.text.labelMedium),
      ],
    ),
  );
}

class _WeekBars extends StatelessWidget {
  const _WeekBars({required this.minutes});

  final List<int> minutes;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final days = context.isBangla ? const ['র', 'সো', 'ম', 'বু', 'বৃ', 'শু', 'শ'] : const ['S', 'M', 'T', 'W', 'T', 'F', 'S'];
    return Semantics(
      label: minutes.join(', '),
      child: BarChart(
        BarChartData(
          gridData: const FlGridData(show: false),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(),
            rightTitles: const AxisTitles(),
            leftTitles: const AxisTitles(),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (v, _) => Text(days[now.subtract(Duration(days: 6 - v.toInt())).weekday % 7], style: context.text.labelSmall),
              ),
            ),
          ),
          barGroups: [
            for (var i = 0; i < minutes.length; i++)
              BarChartGroupData(x: i, barRods: [BarChartRodData(toY: minutes[i].toDouble(), color: context.colors.primary, width: 14, borderRadius: BorderRadius.circular(4))]),
          ],
        ),
      ),
    );
  }
}

/// Linked children with per-link sharing switches, unlink and the code + OTP link flow.
class ParentChildrenScreen extends ConsumerWidget {
  const ParentChildrenScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final links = ref.watch(guardianProvider).links;
    final c = ref.read(guardianProvider.notifier);
    return AppPageScaffold(
      title: context.tr(PStr.children),
      floatingActionButton: FloatingActionButton.extended(
        key: const Key('link.open'),
        onPressed: () => showModalBottomSheet<void>(context: context, isScrollControlled: true, builder: (_) => const _LinkSheet()),
        icon: const Icon(Icons.person_add_alt),
        label: Text(context.tr(PStr.link)),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(context.tr(PStr.childrenSub), style: context.text.bodySmall),
          const SizedBox(height: AppSpacing.sm),
          if (links.isEmpty) EmptyState(icon: Icons.person_add_alt, title: context.tr(PStr.noChildren)),
          for (final l in links)
            Card(
              key: Key('childCard.${l.id}'),
              margin: const EdgeInsets.only(bottom: AppSpacing.md),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(radius: 22, child: Text(l.studentName.characters.first)),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(l.studentName, style: context.text.titleMedium),
                              Text(
                                '${l.relation} · ${l.linkedAt == null ? context.tr(PStr.pending) : context.tr(PStr.since.fill({'d': shortDate(l.linkedAt!, context.lang)}))}',
                                style: context.text.bodySmall,
                              ),
                            ],
                          ),
                        ),
                        Pill(context.tr(l.active ? PStr.active : PStr.pending), tone: l.active ? Tone.success : Tone.warning),
                      ],
                    ),
                    if (!l.active)
                      Padding(
                        padding: const EdgeInsets.only(top: AppSpacing.sm),
                        child: OutlinedButton(
                          onPressed: () => showModalBottomSheet<void>(context: context, isScrollControlled: true, builder: (_) => _LinkSheet(pending: l)),
                          child: Text(context.tr(PStr.verify)),
                        ),
                      ),
                    if (l.active) ...[
                      const SizedBox(height: AppSpacing.sm),
                      Text(context.tr(PStr.whatYouSee), style: context.text.labelLarge),
                      for (final k in ShareKey.values)
                        SwitchListTile(
                          key: Key('perm.${l.id}.${k.name}'),
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          secondary: k == ShareKey.aiConversations ? const Icon(Icons.lock_outline, size: 18) : null,
                          title: Text(context.tr(k.label)),
                          value: l.permissions[k] ?? false,
                          onChanged: k == ShareKey.aiConversations && !(l.permissions[k] ?? false)
                              ? null
                              : (v) async {
                                  try {
                                    await c.setPermission(l.id, k, v);
                                  } on ApiException catch (e) {
                                    if (context.mounted) context.showErrorSnack(e);
                                  }
                                },
                        ),
                      Text(context.tr(PStr.permNote), style: context.text.bodySmall),
                    ],
                    Align(
                      alignment: AlignmentDirectional.centerEnd,
                      child: TextButton.icon(
                        key: Key('unlink.${l.id}'),
                        style: TextButton.styleFrom(foregroundColor: context.colors.error),
                        onPressed: () async {
                          if (!await showConfirmDialog(context, title: PStr.unlinkConfirm, destructive: true, confirmLabel: PStr.unlink)) return;
                          await c.unlink(l.id);
                          if (context.mounted) context.showSnack(PStr.unlinked);
                        },
                        icon: const Icon(Icons.link_off),
                        label: Text(context.tr(PStr.unlink)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          InfoBanner(message: context.tr(PStr.linkNote), icon: Icons.lock_outline),
          const SizedBox(height: 72),
        ],
      ),
    );
  }
}

class _LinkSheet extends ConsumerStatefulWidget {
  const _LinkSheet({this.pending});

  final GuardianLink? pending;

  @override
  ConsumerState<_LinkSheet> createState() => _LinkSheetState();
}

class _LinkSheetState extends ConsumerState<_LinkSheet> {
  final _code = TextEditingController();
  final _otp = TextEditingController();
  String _relation = _relations.first;
  GuardianLink? _pending;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _pending = widget.pending;
  }

  @override
  void dispose() {
    _code.dispose();
    _otp.dispose();
    super.dispose();
  }

  Future<void> _go() async {
    final c = ref.read(guardianProvider.notifier);
    setState(() => _busy = true);
    try {
      if (_pending == null) {
        final l = await c.requestLink(_code.text, _relation);
        setState(() => _pending = l);
      } else {
        await c.confirmLink(_pending!.id, _otp.text);
        if (mounted) {
          Navigator.pop(context);
          context.showSnack(PStr.linked);
        }
      }
    } on ApiException catch (e) {
      if (mounted) context.showErrorSnack(e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, MediaQuery.viewInsetsOf(context).bottom + AppSpacing.lg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(context.tr(PStr.link), style: context.text.titleLarge),
          const SizedBox(height: AppSpacing.md),
          if (_pending == null) ...[
            TextField(
              key: const Key('link.code'),
              controller: _code,
              textCapitalization: TextCapitalization.characters,
              decoration: InputDecoration(labelText: context.tr(PStr.linkCode), helperText: context.tr(PStr.linkCodeHint), hintText: 'SHK-XXXX'),
            ),
            const SizedBox(height: AppSpacing.md),
            DropdownButtonFormField<String>(
              initialValue: _relation,
              decoration: InputDecoration(labelText: context.tr(PStr.relation)),
              items: [for (final r in _relations) DropdownMenuItem(value: r, child: Text(r))],
              onChanged: (v) => setState(() => _relation = v ?? _relation),
            ),
          ] else
            TextField(
              key: const Key('link.otp'),
              controller: _otp,
              keyboardType: TextInputType.number,
              maxLength: 6,
              decoration: InputDecoration(labelText: context.tr(PStr.otp)),
            ),
          const SizedBox(height: AppSpacing.md),
          FilledButton(
            key: const Key('link.go'),
            onPressed: _busy ? null : _go,
            child: _busy ? const SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2)) : Text(context.tr(_pending == null ? PStr.next : PStr.verify)),
          ),
        ],
      ),
    );
  }
}

class ParentProgressScreen extends ConsumerWidget {
  const ParentProgressScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AppPageScaffold(
      title: context.tr(PStr.progress),
      body: _WithChild(
        builder: (context, s) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SectionHeader(title: context.tr(PStr.mastery)),
            if (!s.can(ShareKey.progress))
              _hidden(context)
            else ...[
              for (final (name, m) in s.subjectMastery)
                Padding(padding: const EdgeInsets.only(bottom: AppSpacing.sm), child: LabeledProgress(label: context.tr(name), value: m)),
              SectionHeader(title: context.tr(PStr.weak)),
              if (s.weakTopics.isEmpty)
                EmptyState(title: context.tr(PStr.noWeak), compact: true, icon: Icons.check_circle_outline)
              else
                for (final (t, subj, m) in s.weakTopics)
                  ListTile(contentPadding: EdgeInsets.zero, leading: ProgressRing(value: m, size: 36), title: Text(context.tr(t)), subtitle: Text(context.tr(subj))),
            ],
            _ResultsList(s: s),
          ],
        ),
      ),
    );
  }
}

class _ResultsList extends StatelessWidget {
  const _ResultsList({required this.s});

  final ChildSummary s;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(title: context.tr(PStr.results)),
        if (!s.can(ShareKey.scores))
          _hidden(context)
        else if (s.results.isEmpty)
          EmptyState(title: context.tr(PStr.noResults), compact: true, icon: Icons.emoji_events_outlined)
        else
          for (final r in s.results)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.assignment_turned_in_outlined),
              title: Text(context.tr(r.title)),
              subtitle: Text(relativeTime(r.at, context.lang)),
              trailing: Pill(context.pct(r.percent), tone: r.percent >= 80 ? Tone.success : (r.percent >= 50 ? Tone.info : Tone.warning)),
            ),
      ],
    );
  }
}

/// Kept for callers that embed the results list (e.g. older widget tests).
class ParentResultsList extends ConsumerWidget {
  const ParentResultsList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => _WithChild(builder: (context, s) => _ResultsList(s: s));
}

class ParentResultsScreen extends StatelessWidget {
  const ParentResultsScreen({super.key});

  @override
  Widget build(BuildContext context) => AppPageScaffold(title: context.tr(PStr.results), body: const ParentResultsList());
}

/// The child's study calendar (PAR-11): last week and the coming week, grouped by day.
class ParentCalendarScreen extends ConsumerWidget {
  const ParentCalendarScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AppPageScaffold(
      title: context.tr(PStr.calendar),
      body: _WithChild(
        builder: (context, s) {
          if (!s.can(ShareKey.calendar)) return _hidden(context);
          final today = DateTime.now();
          final days = [for (var d = -6; d <= 7; d++) DateTime(today.year, today.month, today.day).add(Duration(days: d))];
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final d in days)
                Builder(
                  builder: (context) {
                    final items = [for (final i in s.calendar) if (DateUtils.isSameDay(i.day, d)) i];
                    final isToday = DateUtils.isSameDay(d, today);
                    return Card(
                      color: isToday ? context.colors.primaryContainer : null,
                      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.sm),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('${shortDate(d, context.lang)}${isToday ? ' · ${context.tr(const Tr('আজ', 'Today'))}' : ''}', style: context.text.titleSmall),
                            if (items.isEmpty)
                              Text(context.tr(PStr.noPlan), style: context.text.bodySmall)
                            else
                              for (final i in items)
                                Row(
                                  children: [
                                    Icon(
                                      switch (i.status) {
                                        TaskStatus.done => Icons.check_circle,
                                        TaskStatus.missed => Icons.cancel_outlined,
                                        TaskStatus.scheduled => Icons.schedule,
                                      },
                                      size: 18,
                                      color: switch (i.status) {
                                        TaskStatus.done => context.palette.success,
                                        TaskStatus.missed => context.palette.danger,
                                        TaskStatus.scheduled => context.colors.onSurfaceVariant,
                                      },
                                    ),
                                    const SizedBox(width: AppSpacing.xs),
                                    Expanded(child: Text(context.tr(i.title))),
                                    Text('${context.n(i.minutes)} min', style: context.text.labelSmall),
                                  ],
                                ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
            ],
          );
        },
      ),
    );
  }
}

/// Teacher feedback (PAR-12): acknowledge and reply (reply reaches the teacher's inbox).
class ParentFeedbackScreen extends ConsumerWidget {
  const ParentFeedbackScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AppPageScaffold(
      title: context.tr(PStr.feedback),
      body: _WithChild(
        builder: (context, s) {
          if (!s.can(ShareKey.teacherFeedback)) return _hidden(context);
          final notes = ref.watch(teacherNotesProvider(s.link.id));
          if (notes.isEmpty) return EmptyState(icon: Icons.rate_review_outlined, title: context.tr(PStr.noFeedback));
          final c = ref.read(guardianProvider.notifier);
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final n in notes)
                Card(
                  key: Key('note.${n.id}'),
                  margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(child: Text('${n.teacher} · ${context.tr(n.subject)}', style: context.text.titleSmall)),
                            Text(relativeTime(n.at, context.lang), style: context.text.labelSmall),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(n.message),
                        if (n.reply != null) ...[
                          const SizedBox(height: AppSpacing.sm),
                          Container(
                            padding: const EdgeInsets.all(AppSpacing.sm),
                            decoration: BoxDecoration(color: context.colors.surfaceContainerHighest, borderRadius: BorderRadius.circular(8)),
                            child: Text('${context.tr(PStr.yourReply)}: ${n.reply}', style: context.text.bodySmall),
                          ),
                        ],
                        const SizedBox(height: AppSpacing.sm),
                        Row(
                          children: [
                            if (n.acknowledged)
                              Pill(context.tr(PStr.acked), tone: Tone.success, icon: Icons.done)
                            else
                              OutlinedButton(key: Key('ack.${n.id}'), onPressed: () => c.acknowledge(n), child: Text(context.tr(PStr.ack))),
                            const Spacer(),
                            TextButton.icon(
                              key: Key('reply.${n.id}'),
                              onPressed: () async {
                                final text = await showTextInputDialog(context, title: PStr.reply, label: PStr.replyHint);
                                if (text == null || text.trim().isEmpty) return;
                                try {
                                  await c.reply(n, text.trim());
                                  if (context.mounted) context.showSnack(PStr.replied);
                                } on ApiException catch (e) {
                                  if (context.mounted) context.showErrorSnack(e);
                                }
                              },
                              icon: const Icon(Icons.reply),
                              label: Text(context.tr(PStr.reply)),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

/// Weekly goals (PAR-13) with live progress from the child's activity.
class ParentGoalsScreen extends ConsumerWidget {
  const ParentGoalsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final link = ref.watch(guardianProvider).selected;
    return AppPageScaffold(
      title: context.tr(PStr.goals),
      floatingActionButton: link == null
          ? null
          : FloatingActionButton.extended(
              key: const Key('goal.add'),
              onPressed: () => _editGoal(context, ref, link.id),
              icon: const Icon(Icons.add),
              label: Text(context.tr(PStr.addGoal)),
            ),
      body: _WithChild(
        builder: (context, s) {
          final goals = [for (final g in ref.watch(guardianProvider).goals) if (g.linkId == s.link.id) g];
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(context.tr(PStr.goalsSub), style: context.text.bodySmall),
              const SizedBox(height: AppSpacing.sm),
              if (goals.isEmpty) EmptyState(icon: Icons.flag_outlined, title: context.tr(PStr.noGoals)),
              for (final g in goals)
                Builder(
                  builder: (context) {
                    final current = s.goalValues[g.metric] ?? 0;
                    final pct = g.target == 0 ? 0.0 : (current / g.target).clamp(0.0, 1.0);
                    return Card(
                      key: Key('goal.${g.id}'),
                      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              children: [
                                Expanded(child: Text(g.title, style: context.text.titleSmall)),
                                if (pct >= 1) Pill(context.tr(PStr.reached), tone: Tone.success, icon: Icons.celebration_outlined),
                                PopupMenuButton<String>(
                                  onSelected: (v) => v == 'edit' ? _editGoal(context, ref, s.link.id, goal: g) : ref.read(guardianProvider.notifier).removeGoal(g.id),
                                  itemBuilder: (_) => [
                                    PopupMenuItem(value: 'edit', child: Text(context.tr(PStr.editGoal))),
                                    PopupMenuItem(value: 'delete', child: Text(context.tr(S.delete))),
                                  ],
                                ),
                              ],
                            ),
                            LabeledProgress(label: context.tr(g.metric.label), value: pct, trailing: '${context.n(current)}/${context.n(g.target)}'),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              const SizedBox(height: 72),
            ],
          );
        },
      ),
    );
  }
}

Future<void> _editGoal(BuildContext context, WidgetRef ref, String linkId, {GuardianGoal? goal}) async {
  final saved = await showDialog<GuardianGoal>(context: context, builder: (_) => _GoalDialog(linkId: linkId, goal: goal));
  if (saved != null) await ref.read(guardianProvider.notifier).saveGoal(saved);
}

class _GoalDialog extends StatefulWidget {
  const _GoalDialog({required this.linkId, this.goal});

  final String linkId;
  final GuardianGoal? goal;

  @override
  State<_GoalDialog> createState() => _GoalDialogState();
}

class _GoalDialogState extends State<_GoalDialog> {
  late final _title = TextEditingController(text: widget.goal?.title ?? '');
  late final _target = TextEditingController(text: '${widget.goal?.target ?? 300}');
  late GoalMetric _metric = widget.goal?.metric ?? GoalMetric.minutes;

  @override
  void dispose() {
    _title.dispose();
    _target.dispose();
    super.dispose();
  }

  void _save() {
    final t = int.tryParse(_target.text.trim()) ?? 0;
    if (_title.text.trim().isEmpty || t <= 0) return;
    final g = widget.goal;
    Navigator.pop(
      context,
      GuardianGoal(id: g?.id ?? 'gg-${DateTime.now().microsecondsSinceEpoch}', linkId: widget.linkId, title: _title.text.trim(), metric: _metric, target: t, createdAt: g?.createdAt ?? DateTime.now()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(context.tr(widget.goal == null ? PStr.addGoal : PStr.editGoal)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(key: const Key('goal.title'), controller: _title, decoration: InputDecoration(labelText: context.tr(PStr.goalTitle), hintText: context.tr(PStr.goalHint))),
          const SizedBox(height: AppSpacing.sm),
          DropdownButtonFormField<GoalMetric>(
            initialValue: _metric,
            decoration: InputDecoration(labelText: context.tr(PStr.metric)),
            items: [for (final m in GoalMetric.values) DropdownMenuItem(value: m, child: Text(context.tr(m.label)))],
            onChanged: (v) => setState(() => _metric = v ?? _metric),
          ),
          const SizedBox(height: AppSpacing.sm),
          TextField(key: const Key('goal.target'), controller: _target, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: context.tr(PStr.target))),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text(context.tr(S.cancel))),
        FilledButton(key: const Key('goal.save'), onPressed: _save, child: Text(context.tr(S.save))),
      ],
    );
  }
}

/// Guardian reports (PAR-15, PAR-20): weekly/monthly text report honouring sharing choices.
class ParentReportsScreen extends ConsumerStatefulWidget {
  const ParentReportsScreen({super.key});

  @override
  ConsumerState<ParentReportsScreen> createState() => _ParentReportsScreenState();
}

class _ParentReportsScreenState extends ConsumerState<ParentReportsScreen> {
  bool _monthly = false;

  List<String> _lines(BuildContext context, ChildSummary s) {
    String t(Tr x) => context.tr(x);
    final minutes = _monthly ? (s.minutesWeek + s.minutesPrevWeek) * 2 : s.minutesWeek;
    return [
      '${t(PStr.student)}: ${s.link.studentName}',
      '${t(PStr.period)}: ${t(_monthly ? PStr.last30 : PStr.last7)}',
      '${t(PStr.minutes)}: ${s.can(ShareKey.studyTime) ? context.n(minutes) : t(PStr.notShared)}',
      if (s.can(ShareKey.calendar)) '${t(PStr.tasks)}: ${context.n(s.tasksDone)}/${context.n(s.tasksMissed)}',
      if (s.can(ShareKey.scores) && s.avgScore != null) '${t(PStr.avg)}: ${context.pct(s.avgScore!)}',
      '${t(PStr.streak)}: ${context.n(s.streak)}',
      if (s.can(ShareKey.progress)) ...[
        '${t(PStr.mastery)}: ${s.subjectMastery.take(4).map((e) => '${t(e.$1)} ${context.pct(e.$2 * 100)}').join(', ')}',
        '${t(PStr.weak)}: ${s.weakTopics.isEmpty ? '—' : s.weakTopics.map((e) => t(e.$1)).join(', ')}',
      ],
      '',
      t(PStr.reportFooter),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return AppPageScaffold(
      title: context.tr(PStr.reports),
      body: _WithChild(
        builder: (context, s) {
          final lines = _lines(context, s);
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SegmentedButton<bool>(
                segments: [
                  ButtonSegment(value: false, label: Text(context.tr(PStr.weekly))),
                  ButtonSegment(value: true, label: Text(context.tr(PStr.monthly))),
                ],
                selected: {_monthly},
                onSelectionChanged: (v) => setState(() => _monthly = v.first),
              ),
              const SizedBox(height: AppSpacing.md),
              Card(
                key: const Key('report.body'),
                margin: EdgeInsets.zero,
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${context.tr(_monthly ? PStr.monthly : PStr.weekly)} ${context.tr(PStr.reports)} — ${s.link.studentName}', style: context.text.titleMedium),
                      Text(shortDate(DateTime.now(), context.lang), style: context.text.labelSmall),
                      const Divider(),
                      SelectableText(lines.join('\n')),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  FilledButton.icon(
                    key: const Key('report.download'),
                    onPressed: () async {
                      await Clipboard.setData(ClipboardData(text: lines.join('\n')));
                      if (context.mounted) context.showSnack(PStr.downloaded);
                    },
                    icon: const Icon(Icons.download),
                    label: Text(context.tr(PStr.download)),
                  ),
                  OutlinedButton.icon(onPressed: () => context.showSnack(PStr.emailed), icon: const Icon(Icons.mail_outline), label: Text(context.tr(PStr.email))),
                  OutlinedButton.icon(onPressed: () => context.showSnack(PStr.printed), icon: const Icon(Icons.print_outlined), label: Text(context.tr(PStr.print))),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Privacy overview (PAR-18, PAR-21): what each child shares and the privacy promise.
class ParentPrivacyScreen extends ConsumerWidget {
  const ParentPrivacyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final links = ref.watch(guardianProvider).active;
    return AppPageScaffold(
      title: context.tr(PStr.privacy),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InfoBanner(message: context.tr(PStr.privacyBanner), icon: Icons.verified_user_outlined, tone: Tone.info),
          SectionHeader(title: context.tr(PStr.sharedData)),
          Text(context.tr(PStr.sharedDataSub), style: context.text.bodySmall),
          const SizedBox(height: AppSpacing.sm),
          for (final l in links)
            Builder(
              builder: (context) {
                final perms = ref.watch(childSummaryProvider(l.id))?.perms ?? l.permissions;
                return Card(
                  margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(l.studentName, style: context.text.titleSmall),
                        const SizedBox(height: AppSpacing.xs),
                        Wrap(
                          spacing: AppSpacing.xs,
                          runSpacing: AppSpacing.xs,
                          children: [
                            for (final k in ShareKey.values)
                              Pill(context.tr(k.label), tone: (perms[k] ?? false) ? Tone.success : Tone.neutral, icon: (perms[k] ?? false) ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          const SizedBox(height: AppSpacing.sm),
          OutlinedButton.icon(onPressed: () => context.go('/parent/children'), icon: const Icon(Icons.tune), label: Text(context.tr(PStr.children))),
        ],
      ),
    );
  }
}
