import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/router/app_routes.dart';
import '../../core/l10n/tr.dart';
import '../../core/settings/app_settings.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/time_format.dart';
import '../../shared/widgets/app_page_scaffold.dart';
import '../../shared/widgets/badges.dart';
import '../../shared/widgets/empty_state.dart';
import '../../shared/widgets/feedback.dart';
import '../../shared/widgets/progress.dart';
import '../../shared/widgets/section_header.dart';
import '../../shared/widgets/stat_card.dart';
import '../planner/application/planner_controller.dart';
import '../progress/application/learning_progress_controller.dart';
import '../progress/domain/learning_progress.dart';
import 'insights_engine.dart';

abstract final class InsightStrings {
  static const analytics = Tr('অ্যাডাপটিভ লার্নিং', 'Adaptive learning');
  static const overview = Tr('সারসংক্ষেপ', 'Overview');
  static const topics = Tr('টপিক', 'Topics');
  static const roadmap = Tr('রোডম্যাপ', 'Roadmap');
  static const studyMinutes = Tr('পড়ার সময় (৭ দিন, মিনিট)', 'Study time (7 days, min)');
  static const practiced = Tr('অনুশীলিত প্রশ্ন', 'Questions practised');
  static const accuracy = Tr('সঠিকতা', 'Accuracy');
  static const streak = Tr('টানা দিন', 'Day streak');
  static const subjectMastery = Tr('বিষয়ভিত্তিক দক্ষতা', 'Subject mastery');
  static const weak = Tr('দুর্বল টপিক — আগে অনুশীলন করো', 'Weak topics — practise these first');
  static const strong = Tr('শক্তিশালী টপিক', 'Strong topics');
  static const compare = Tr('শক্তি বনাম দুর্বলতা', 'Strengths vs weaknesses');
  static const practise = Tr('অনুশীলন', 'Practise');
  static const examTrend = Tr('পরীক্ষার ফলের ধারা', 'Exam score trend');
  static const accuracyTrend = Tr('সাপ্তাহিক সঠিকতার ধারা', 'Weekly accuracy trend');
  static const improvement = Tr('উন্নতি (এই সপ্তাহ বনাম আগের)', 'Improvement (this week vs last)');
  static const minutesDelta = Tr('পড়ার সময়', 'Study time');
  static const difficulty = Tr('কঠিনতা অনুযায়ী সঠিকতা', 'Accuracy by difficulty');
  static const answered = Tr('{n}টি উত্তর', '{n} answered');
  static const consistency = Tr('ধারাবাহিকতা (২৮ দিন)', 'Consistency (28 days)');
  static const activeDays = Tr('{n} দিন সক্রিয়', '{n} active days');
  static const heatmap = Tr('টপিক হিটম্যাপ', 'Topic heatmap');
  static const heatLegend = Tr('ধূসর = শুরু হয়নি · লাল → সবুজ = দক্ষতা', 'Grey = not started · red → green = mastery');
  static const mistakes = Tr('সাধারণ ভুল', 'Common mistakes');
  static const wrongN = Tr('{n}টি ভুল', '{n} wrong');
  static const gaps = Tr('জ্ঞানের ফাঁক', 'Knowledge gaps');
  static const gapsHint = Tr('যে অধ্যায় শুরু করেছ তার এই টপিকগুলো এখনো ধরা হয়নি', "Topics in chapters you've started that you haven't touched");
  static const prerequisites = Tr('পূর্বশর্ত যাচাই', 'Prerequisite check');
  static const prereqLine = Tr('“{c}” এর আগে “{p}” মজবুত করো ({m})', 'Strengthen “{p}” before “{c}” ({m})');
  static const path = Tr('দুর্বলতা থেকে দক্ষতার পথ', 'Weakness-to-mastery path');
  static const pathFor = Tr('লক্ষ্য: {t}', 'Target: {t}');
  static const sequence = Tr('প্রস্তাবিত পাঠক্রম', 'Recommended lesson order');
  static const revision = Tr('রিভিশন প্রস্তাব', 'Revision recommendations');
  static const revisionHint = Tr('৭ দিনের বেশি দেখা হয়নি', 'Not seen for over 7 days');
  static const adjust = Tr('ব্যক্তিগত সমন্বয়', 'Personalised adjustment');
  static const adjustLine = Tr('প্রস্তাবিত দৈনিক পড়ার সময়: {n} মিনিট', 'Suggested daily study time: {n} min');
  static const apply = Tr('প্ল্যানারে প্রয়োগ করো', 'Apply to planner');
  static const applied = Tr('প্ল্যানারের দৈনিক সময় হালনাগাদ হয়েছে', 'Planner daily time updated');
  static const noData = Tr('এখনো যথেষ্ট তথ্য নেই — কিছু প্রশ্ন অনুশীলন করো।', 'Not enough data yet — practise some questions.');
  static const masteryNote = Tr(
    'দক্ষতা = সঠিক উত্তর, সাম্প্রতিকতা ও পড়া শেষ করার সমন্বয়। পরীক্ষা ও কুইজের ফলে এটি সঙ্গে সঙ্গে বদলায়।',
    'Mastery combines correct answers, recency and completion. It updates right after quizzes and exams.',
  );
  static const achievements = Tr('অর্জন ও XP', 'Achievements & XP');
  static const level = Tr('লেভেল {n}', 'Level {n}');
  static const xpToNext = Tr('পরের লেভেলে {n} XP বাকি', '{n} XP to the next level');
  static const points = Tr('স্টাডি পয়েন্ট', 'Study points');
  static const badges = Tr('ব্যাজ', 'Badges');
  static const missions = Tr('এই সপ্তাহের মিশন', "This week's missions");
  static const challenges = Tr('আজকের চ্যালেঞ্জ', "Today's challenges");
  static const milestones = Tr('মাসিক মাইলফলক', 'Monthly milestones');
  static const goalDays = Tr('দৈনিক লক্ষ্য পূরণ (৩০ দিন)', 'Daily goal met (30 days)');
  static const chapters = Tr('অধ্যায় সম্পন্ন', 'Chapters completed');
  static const chapterReward = Tr('প্রতিটি অধ্যায় শেষ করলে ৩০ XP বোনাস', '30 XP bonus for every chapter you finish');
  static const leaderboard = Tr('লিডারবোর্ড (ডেমো)', 'Leaderboard (demo)');
  static const leaderboardHidden = Tr('সেটিংসে প্রতিযোগিতামূলক অংশ লুকানো আছে।', 'Competitive features are hidden in settings.');
  static const friends = Tr('বন্ধুর সাথে চ্যালেঞ্জ (ডেমো)', 'Friend challenges (demo)');
  static const newChallenge = Tr('নতুন চ্যালেঞ্জ', 'New challenge');
  static const friend = Tr('বন্ধু', 'Friend');
  static const goal = Tr('লক্ষ্য', 'Goal');
  static const goalMinutes = Tr('পড়ার মিনিট', 'Study minutes');
  static const goalQuestions = Tr('প্রশ্ন', 'Questions');
  static const target = Tr('লক্ষ্যমাত্রা', 'Target');
  static const days = Tr('দিন', 'Days');
  static const start = Tr('শুরু করো', 'Start');
  static const ends = Tr('শেষ: {d}', 'Ends: {d}');
  static const youWin = Tr('তুমি এগিয়ে!', "You're ahead!");
  static const friendWins = Tr('বন্ধু এগিয়ে', 'Friend is ahead');
  static const history = Tr('অর্জনের ইতিহাস', 'Achievement history');
  static const you = Tr('তুমি', 'You');
  static const celebrate = Tr('অভিনন্দন! নতুন ব্যাজ', 'Congratulations! New badge');
  static const great = Tr('দারুণ!', 'Great!');
  static const consistencyTitle = Tr('ধারাবাহিকতা', 'Consistency');
}

Color _heat(BuildContext context, TopicCell c) {
  if (!c.started) return context.colors.surfaceContainerHighest;
  return Color.lerp(context.palette.danger, context.palette.success, c.mastery)!.withValues(alpha: 0.85);
}

/// Adaptive learning & weakness detection (web §19): overview, topics, roadmap.
class AnalyticsScreen extends ConsumerWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 3,
      child: AppPageScaffold(
        title: context.tr(InsightStrings.analytics),
        bottom: TabBar(
          tabAlignment: TabAlignment.fill,
          tabs: [
            Tab(text: context.tr(InsightStrings.overview)),
            Tab(text: context.tr(InsightStrings.topics)),
            Tab(text: context.tr(InsightStrings.roadmap)),
          ],
        ),
        scrollable: false,
        padding: EdgeInsets.zero,
        body: const TabBarView(children: [_OverviewTab(), _TopicsTab(), _RoadmapTab()]),
      ),
    );
  }
}

class _Scroll extends StatelessWidget {
  const _Scroll({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) => ListView(padding: const EdgeInsets.all(AppSpacing.lg), children: children);
}

class _OverviewTab extends ConsumerWidget {
  const _OverviewTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final a = ref.watch(analyticsProvider);
    final p = ref.watch(learningProgressProvider);
    final text = context.text;
    String delta(num now, num before) {
      final d = now - before;
      return '${d >= 0 ? '+' : ''}${context.n(d.round())}';
    }

    return _Scroll(
      children: [
        StatGrid(
          cards: [
            StatCard(label: context.tr(InsightStrings.studyMinutes), value: context.n(a.thisWeekMinutes), icon: Icons.timer_outlined, caption: delta(a.thisWeekMinutes, a.lastWeekMinutes)),
            StatCard(label: context.tr(InsightStrings.practiced), value: context.n(p.practicedQuestions), icon: Icons.quiz_outlined),
            StatCard(
              label: context.tr(InsightStrings.accuracy),
              value: p.overallAccuracy == null ? '—' : context.pct(p.overallAccuracy! * 100),
              icon: Icons.track_changes,
              caption: a.thisWeekAccuracy == null || a.lastWeekAccuracy == null ? null : '${delta(a.thisWeekAccuracy! * 100, a.lastWeekAccuracy! * 100)}%',
            ),
            StatCard(label: context.tr(InsightStrings.streak), value: context.n(p.streak), icon: Icons.local_fire_department_outlined),
          ],
        ),
        SectionHeader(title: context.tr(InsightStrings.subjectMastery)),
        for (final s in a.subjects)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: LabeledProgress(label: context.tr(s.name), value: p.subjectMastery(s), color: s.color),
          ),
        SectionHeader(title: context.tr(InsightStrings.accuracyTrend)),
        SizedBox(
          height: 150,
          child: a.weeklyAccuracy.every((x) => x == null)
              ? EmptyState(title: context.tr(InsightStrings.noData), compact: true, icon: Icons.show_chart)
              : LineChart(
                  LineChartData(
                    minY: 0,
                    maxY: 100,
                    gridData: const FlGridData(show: false),
                    borderData: FlBorderData(show: false),
                    titlesData: const FlTitlesData(topTitles: AxisTitles(), rightTitles: AxisTitles()),
                    lineBarsData: [
                      LineChartBarData(
                        isCurved: true,
                        color: context.colors.primary,
                        spots: [
                          for (final (i, v) in a.weeklyAccuracy.indexed)
                            if (v != null) FlSpot(i.toDouble(), v * 100),
                        ],
                      ),
                    ],
                  ),
                ),
        ),
        SectionHeader(title: context.tr(InsightStrings.difficulty)),
        for (final (d, n, acc) in a.byDifficulty)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: LabeledProgress(
              label: '${context.tr(d.label)} · ${context.tr(InsightStrings.answered.fill({'n': n}))}',
              value: acc ?? 0,
              trailing: acc == null ? '—' : context.pct(acc * 100),
              dense: true,
            ),
          ),
        SectionHeader(title: context.tr(InsightStrings.consistency)),
        _ConsistencyGrid(minutes: a.minutes28),
        Text(context.tr(InsightStrings.activeDays.fill({'n': a.activeDays28})), style: text.bodySmall),
        if (a.examTrend.length >= 2) ...[
          SectionHeader(title: context.tr(InsightStrings.examTrend)),
          SizedBox(
            height: 150,
            child: LineChart(
              LineChartData(
                minY: 0,
                maxY: 100,
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
                titlesData: const FlTitlesData(topTitles: AxisTitles(), rightTitles: AxisTitles(), bottomTitles: AxisTitles()),
                lineBarsData: [
                  LineChartBarData(isCurved: true, color: context.palette.success, spots: [for (final (i, v) in a.examTrend.indexed) FlSpot(i.toDouble(), v)]),
                ],
              ),
            ),
          ),
        ],
        const SizedBox(height: AppSpacing.md),
        Text(context.tr(InsightStrings.masteryNote), style: text.bodySmall),
      ],
    );
  }
}

class _ConsistencyGrid extends StatelessWidget {
  const _ConsistencyGrid({required this.minutes});

  final List<int> minutes;

  @override
  Widget build(BuildContext context) {
    final max = math.max(1, minutes.fold(0, math.max));
    return Semantics(
      label: minutes.join(', '),
      child: Wrap(
        spacing: 4,
        runSpacing: 4,
        children: [
          for (final m in minutes)
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: m == 0 ? context.colors.surfaceContainerHighest : context.colors.primary.withValues(alpha: 0.25 + 0.75 * m / max),
                borderRadius: BorderRadius.circular(6),
              ),
            ),
        ],
      ),
    );
  }
}

class _TopicsTab extends ConsumerWidget {
  const _TopicsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final a = ref.watch(analyticsProvider);
    final weakest = a.weakest.take(5).toList();
    final strongest = a.strongest.where((c) => c.mastery >= 0.6).take(5).toList();
    return _Scroll(
      children: [
        SectionHeader(title: context.tr(InsightStrings.heatmap)),
        Text(context.tr(InsightStrings.heatLegend), style: context.text.bodySmall),
        const SizedBox(height: AppSpacing.sm),
        for (final s in a.subjects)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(context.tr(s.name), style: context.text.labelLarge),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 3,
                  runSpacing: 3,
                  children: [
                    for (final c in a.cells.where((c) => c.subject.id == s.id))
                      Tooltip(
                        message: '${context.tr(c.topic.title)} · ${c.started ? context.pct(c.mastery * 100) : '—'}',
                        child: InkWell(
                          onTap: () => context.go(AppRoutes.topic(c.topic.id)),
                          child: Container(
                            width: 18,
                            height: 18,
                            decoration: BoxDecoration(color: _heat(context, c), borderRadius: BorderRadius.circular(3)),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        SectionHeader(title: context.tr(InsightStrings.compare)),
        if (weakest.isEmpty)
          EmptyState(title: context.tr(InsightStrings.noData), compact: true, icon: Icons.insights_outlined)
        else
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _TopicColumn(title: InsightStrings.weak, cells: weakest, tone: Tone.warning),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _TopicColumn(title: InsightStrings.strong, cells: strongest, tone: Tone.success),
              ),
            ],
          ),
        SectionHeader(title: context.tr(InsightStrings.mistakes)),
        if (a.mistakes.isEmpty) Text('—', style: context.text.bodySmall),
        for (final (c, n) in a.mistakes.take(5))
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.error_outline),
            title: Text(context.tr(c.topic.title)),
            subtitle: Text('${context.tr(c.subject.name)} · ${context.tr(InsightStrings.wrongN.fill({'n': n}))}'),
            trailing: TextButton(
              onPressed: () => context.push(AppRoutes.practiceSession(mode: 'wrong')),
              child: Text(context.tr(InsightStrings.practise)),
            ),
          ),
        SectionHeader(title: context.tr(InsightStrings.gaps)),
        Text(context.tr(InsightStrings.gapsHint), style: context.text.bodySmall),
        const SizedBox(height: AppSpacing.xs),
        if (a.gaps.isEmpty) Text('—', style: context.text.bodySmall),
        Wrap(
          spacing: AppSpacing.xs,
          runSpacing: AppSpacing.xs,
          children: [for (final c in a.gaps.take(10)) ActionChip(label: Text(context.tr(c.topic.title)), onPressed: () => context.go(AppRoutes.topic(c.topic.id)))],
        ),
        SectionHeader(title: context.tr(InsightStrings.prerequisites)),
        if (a.prerequisites.isEmpty) Text('—', style: context.text.bodySmall),
        for (final (c, pc, m) in a.prerequisites.take(4))
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.account_tree_outlined),
            title: Text(context.tr(InsightStrings.prereqLine.fill({'c': context.tr(c.title), 'p': context.tr(pc.title), 'm': context.pct(m * 100)}))),
            onTap: () => context.go(AppRoutes.chapter(pc.id)),
          ),
      ],
    );
  }
}

class _TopicColumn extends StatelessWidget {
  const _TopicColumn({required this.title, required this.cells, required this.tone});

  final Tr title;
  final List<TopicCell> cells;
  final Tone tone;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Text(context.tr(title), style: context.text.labelLarge),
      const SizedBox(height: AppSpacing.xs),
      if (cells.isEmpty) Text('—', style: context.text.bodySmall),
      for (final c in cells)
        Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.xs),
          child: InkWell(
            onTap: () => context.push(AppRoutes.practiceSession(subjectId: c.subject.id, chapterId: c.chapter.id, topicId: c.topic.id)),
            child: Pill('${context.tr(c.topic.title)} · ${context.pct(c.mastery * 100)}', tone: tone),
          ),
        ),
    ],
  );
}

class _RoadmapTab extends ConsumerWidget {
  const _RoadmapTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final a = ref.watch(analyticsProvider);
    final target = a.weakest.firstOrNull;
    final daily = ref.watch(plannerProvider.select((s) => s.prefs.dailyMinutes));
    return _Scroll(
      children: [
        SectionHeader(title: context.tr(InsightStrings.path)),
        if (target == null)
          EmptyState(title: context.tr(InsightStrings.noData), compact: true, icon: Icons.route_outlined)
        else ...[
          Text(context.tr(InsightStrings.pathFor.fill({'t': context.tr(target.topic.title)})), style: context.text.titleSmall),
          const SizedBox(height: AppSpacing.sm),
          for (final (i, step) in PathStep.values.indexed)
            Card(
              margin: const EdgeInsets.only(bottom: AppSpacing.xs),
              child: ListTile(
                key: Key('path.${step.name}'),
                leading: CircleAvatar(child: Text(context.n(i + 1))),
                title: Text(context.tr(step.label)),
                trailing: Icon(step.icon),
                onTap: () => switch (step) {
                  PathStep.lesson => context.go(AppRoutes.topic(target.topic.id)),
                  PathStep.practice => context.push(AppRoutes.practiceSession(subjectId: target.subject.id, chapterId: target.chapter.id, topicId: target.topic.id)),
                  PathStep.flashcards => context.push(AppRoutes.flashcards(chapterId: target.chapter.id)),
                  PathStep.quiz => context.push(AppRoutes.practiceSession(mode: 'quick', topicId: target.topic.id)),
                },
              ),
            ),
        ],
        SectionHeader(title: context.tr(InsightStrings.sequence)),
        for (final (i, (s, c)) in a.sequence.take(6).indexed)
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: CircleAvatar(
              radius: 14,
              backgroundColor: s.color.withValues(alpha: 0.2),
              child: Text(context.n(i + 1), style: context.text.labelSmall),
            ),
            title: Text(context.tr(c.title)),
            subtitle: Text('${context.tr(s.name)} · ${context.tr(c.relevance.label)}'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.go(AppRoutes.chapter(c.id)),
          ),
        SectionHeader(title: context.tr(InsightStrings.revision)),
        Text(context.tr(InsightStrings.revisionHint), style: context.text.bodySmall),
        if (a.revisionDue.isEmpty) Text('—', style: context.text.bodySmall),
        for (final c in a.revisionDue.take(5))
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: ProgressRing(value: c.mastery, size: 32),
            title: Text(context.tr(c.topic.title)),
            subtitle: Text(relativeTime(c.progress.lastStudied!, context.lang)),
            onTap: () => context.go(AppRoutes.topic(c.topic.id)),
          ),
        SectionHeader(title: context.tr(InsightStrings.adjust)),
        Card(
          margin: EdgeInsets.zero,
          child: ListTile(
            leading: const Icon(Icons.tune),
            title: Text(context.tr(InsightStrings.adjustLine.fill({'n': a.suggestedDailyMinutes}))),
            trailing: a.suggestedDailyMinutes == daily
                ? const Icon(Icons.check, color: Colors.green)
                : TextButton(
                    key: const Key('adjust.apply'),
                    onPressed: () async {
                      final c = ref.read(plannerProvider.notifier);
                      await c.setPrefs(ref.read(plannerProvider).prefs.copyWith(dailyMinutes: a.suggestedDailyMinutes));
                      if (context.mounted) context.showSnack(InsightStrings.applied);
                    },
                    child: Text(context.tr(InsightStrings.apply)),
                  ),
          ),
        ),
      ],
    );
  }
}

/// Gamification (web §25): XP, points, level, streak, badges with celebration, missions,
/// daily challenges, monthly milestones, consistency, friend challenges, leaderboard, history.
class AchievementsScreen extends ConsumerStatefulWidget {
  const AchievementsScreen({super.key});

  @override
  ConsumerState<AchievementsScreen> createState() => _AchievementsScreenState();
}

class _AchievementsScreenState extends ConsumerState<AchievementsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _celebrate());
  }

  Future<void> _celebrate() async {
    final unseen = ref.read(gamificationProvider).unseen;
    if (unseen.isEmpty || !mounted) return;
    await ref.read(gamificationStoreProvider.notifier).celebrate(unseen);
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.celebration, size: 40),
        title: Text(ctx.tr(InsightStrings.celebrate)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final b in unseen)
                ListTile(
                  leading: Icon(b.icon, color: ctx.palette.xp),
                  title: Text(ctx.tr(b.title)),
                  subtitle: Text(ctx.tr(b.how)),
                  trailing: b.xp > 0 ? Text('+${ctx.n(b.xp)} XP') : null,
                ),
            ],
          ),
        ),
        actions: [FilledButton(key: const Key('celebrate.ok'), onPressed: () => Navigator.pop(ctx), child: Text(ctx.tr(InsightStrings.great)))],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final g = ref.watch(gamificationProvider);
    final hide = ref.watch(appSettingsProvider.select((s) => s.hideCompetitive));
    final lvl = levelFor(g.xp);
    final text = context.text;
    final p = ref.watch(learningProgressProvider);
    return AppPageScaffold(
      title: context.tr(InsightStrings.achievements),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Card(
            margin: EdgeInsets.zero,
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Row(
                children: [
                  ProgressRing(
                    value: lvl.intoLevel / lvl.forNext,
                    size: 72,
                    center: Text(context.n(lvl.level), style: text.titleLarge),
                  ),
                  const SizedBox(width: AppSpacing.lg),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(context.tr(InsightStrings.level.fill({'n': lvl.level})), style: text.titleLarge),
                        Text('${context.n(g.xp)} XP · ${context.n(g.points)} ${context.tr(InsightStrings.points)}', style: text.bodyMedium),
                        Text(context.tr(InsightStrings.xpToNext.fill({'n': lvl.forNext - lvl.intoLevel})), style: text.bodySmall),
                      ],
                    ),
                  ),
                  Column(
                    children: [
                      Icon(Icons.local_fire_department, color: context.palette.streak),
                      Text(context.n(g.streak), style: text.titleMedium),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          InfoBanner(message: context.tr(g.motivation), icon: Icons.emoji_objects_outlined, tone: Tone.info),
          SectionHeader(title: context.tr(InsightStrings.consistencyTitle)),
          _ConsistencyGrid(minutes: [for (var d = 27; d >= 0; d--) p.minutesOn(DateTime.now().subtract(Duration(days: d)))]),
          const SizedBox(height: AppSpacing.sm),
          StatGrid(
            cards: [
              StatCard(label: context.tr(InsightStrings.goalDays), value: context.n(g.goalDays), icon: Icons.task_alt),
              StatCard(label: context.tr(InsightStrings.chapters), value: context.n(g.chaptersCompleted), icon: Icons.menu_book, caption: context.tr(InsightStrings.chapterReward)),
            ],
          ),
          SectionHeader(title: context.tr(InsightStrings.badges)),
          GridView.count(
            crossAxisCount: 3,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: AppSpacing.sm,
            crossAxisSpacing: AppSpacing.sm,
            children: [
              for (final b in badgeDefs)
                Tooltip(
                  message: context.tr(b.how),
                  child: Card(
                    key: Key('badge.${b.id}'),
                    margin: EdgeInsets.zero,
                    child: Opacity(
                      opacity: g.earned.containsKey(b.id) ? 1 : 0.4,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(b.icon, size: 32, color: g.earned.containsKey(b.id) ? context.colors.primary : null),
                          const SizedBox(height: AppSpacing.xs),
                          Text(context.tr(b.title), textAlign: TextAlign.center, style: text.labelSmall),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
          SectionHeader(title: context.tr(InsightStrings.challenges)),
          for (final m in g.challenges) _MissionRow(m: m),
          SectionHeader(title: context.tr(InsightStrings.missions)),
          for (final m in g.missions) _MissionRow(m: m),
          SectionHeader(title: context.tr(InsightStrings.milestones)),
          for (final m in g.milestones) _MissionRow(m: m),
          if (!hide) ...[
            SectionHeader(title: context.tr(InsightStrings.friends), actionLabel: context.tr(InsightStrings.newChallenge), onAction: () => _newChallenge(context)),
            if (g.friendChallenges.isEmpty) Text('—', style: text.bodySmall),
            for (final c in g.friendChallenges) _ChallengeCard(c: c, g: g),
          ],
          SectionHeader(title: context.tr(InsightStrings.leaderboard)),
          if (hide)
            Text(context.tr(InsightStrings.leaderboardHidden), style: text.bodySmall)
          else
            for (final (i, (name, xp)) in [
              ('তানিয়া (ডেমো)', g.xp + 340),
              (context.tr(InsightStrings.you), g.xp),
              ('রাশেদ (ডেমো)', math.max(0, g.xp - 120)),
              ('নুসাইবা (ডেমো)', math.max(0, g.xp - 260)),
            ].indexed)
              ListTile(
                dense: true,
                leading: CircleAvatar(child: Text(context.n(i + 1))),
                title: Text(name, style: name == context.tr(InsightStrings.you) ? text.titleSmall : null),
                trailing: Text('${context.n(xp)} XP'),
              ),
          SectionHeader(title: context.tr(InsightStrings.history)),
          for (final b in badgeDefs)
            if (g.earned[b.id] case final at?)
              ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: Icon(b.icon, color: context.palette.xp),
                title: Text(context.tr(b.title)),
                subtitle: Text(relativeTime(at, context.lang)),
              ),
          for (final a in g.history.take(8))
            ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.bolt, size: 20),
              title: Text(context.tr(activityLabel(a.kind))),
              subtitle: Text(relativeTime(a.at, context.lang)),
              trailing: Text('+${context.n(a.xp)} XP'),
            ),
        ],
      ),
    );
  }

  Future<void> _newChallenge(BuildContext context) async {
    final result = await showModalBottomSheet<(String, String, int, int)>(context: context, isScrollControlled: true, showDragHandle: true, builder: (_) => const _ChallengeSheet());
    if (result == null) return;
    await ref.read(gamificationStoreProvider.notifier).startChallenge(result.$1, result.$2, result.$3, result.$4);
  }
}

class _MissionRow extends StatelessWidget {
  const _MissionRow({required this.m});

  final Mission m;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
    child: LabeledProgress(label: context.tr(m.title), value: m.progress, trailing: m.done ? '✓ +${context.n(m.xp)} XP' : '+${context.n(m.xp)} XP', color: m.done ? context.palette.success : null),
  );
}

class _ChallengeCard extends ConsumerWidget {
  const _ChallengeCard({required this.c, required this.g});

  final FriendChallenge c;
  final GamificationData g;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mine = c.goal == 'minutes' ? g.myMinutesSince(c.startedAt) : g.myQuestionsSince(c.startedAt);
    final ahead = mine >= c.friendProgress;
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text('${c.friend} · ${context.n(c.target)} ${context.tr(c.goal == 'minutes' ? InsightStrings.goalMinutes : InsightStrings.goalQuestions)}', style: context.text.titleSmall),
                ),
                IconButton(icon: const Icon(Icons.close, size: 18), onPressed: () => ref.read(gamificationStoreProvider.notifier).removeChallenge(c.id)),
              ],
            ),
            LabeledProgress(label: context.tr(InsightStrings.you), value: (mine / c.target).clamp(0.0, 1.0), trailing: context.n(mine), dense: true),
            const SizedBox(height: 4),
            LabeledProgress(label: c.friend, value: (c.friendProgress / c.target).clamp(0.0, 1.0), trailing: context.n(c.friendProgress), dense: true, color: context.colors.tertiary),
            const SizedBox(height: 4),
            Row(
              children: [
                Pill(context.tr(ahead ? InsightStrings.youWin : InsightStrings.friendWins), tone: ahead ? Tone.success : Tone.warning),
                const Spacer(),
                Text(context.tr(InsightStrings.ends.fill({'d': shortDate(c.endsAt, context.lang)})), style: context.text.labelSmall),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ChallengeSheet extends StatefulWidget {
  const _ChallengeSheet();

  @override
  State<_ChallengeSheet> createState() => _ChallengeSheetState();
}

class _ChallengeSheetState extends State<_ChallengeSheet> {
  static const _friends = ['তানিয়া (ডেমো)', 'রাশেদ (ডেমো)', 'নুসাইবা (ডেমো)'];
  String _friend = _friends.first;
  String _goal = 'minutes';
  double _target = 120;
  double _days = 7;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.lg),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(context.tr(InsightStrings.newChallenge), style: context.text.titleMedium),
        DropdownButtonFormField<String>(
          initialValue: _friend,
          decoration: InputDecoration(labelText: context.tr(InsightStrings.friend)),
          items: [for (final f in _friends) DropdownMenuItem(value: f, child: Text(f))],
          onChanged: (v) => setState(() => _friend = v ?? _friend),
        ),
        const SizedBox(height: AppSpacing.sm),
        SegmentedButton<String>(
          segments: [
            ButtonSegment(value: 'minutes', label: Text(context.tr(InsightStrings.goalMinutes))),
            ButtonSegment(value: 'questions', label: Text(context.tr(InsightStrings.goalQuestions))),
          ],
          selected: {_goal},
          onSelectionChanged: (v) => setState(() {
            _goal = v.first;
            _target = _goal == 'minutes' ? 120 : 50;
          }),
        ),
        Text('${context.tr(InsightStrings.target)}: ${context.n(_target.round())}'),
        Slider(value: _target, min: 10, max: _goal == 'minutes' ? 600 : 300, divisions: 29, onChanged: (v) => setState(() => _target = v)),
        Text('${context.tr(InsightStrings.days)}: ${context.n(_days.round())}'),
        Slider(value: _days, min: 1, max: 14, divisions: 13, onChanged: (v) => setState(() => _days = v)),
        FilledButton(key: const Key('challenge.start'), onPressed: () => Navigator.pop(context, (_friend, _goal, _target.round(), _days.round())), child: Text(context.tr(InsightStrings.start))),
      ],
    ),
  );
}
