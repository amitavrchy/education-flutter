import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/router/app_routes.dart';
import '../../core/l10n/tr.dart';
import '../../core/settings/app_settings.dart';
import '../../core/theme/app_spacing.dart';
import '../../mock/seed/curriculum_seed.dart';
import '../../shared/widgets/app_page_scaffold.dart';
import '../../shared/widgets/badges.dart';
import '../../shared/widgets/empty_state.dart';
import '../../shared/widgets/progress.dart';
import '../../shared/widgets/section_header.dart';
import '../../shared/widgets/stat_card.dart';
import '../curriculum/domain/curriculum_models.dart';
import '../exams/application/exam_controller.dart';
import '../profile/application/student_profile_controller.dart';
import '../progress/application/learning_progress_controller.dart';
import '../progress/domain/learning_progress.dart';

abstract final class InsightStrings {
  static const analytics = Tr('অগ্রগতি ও দুর্বলতা', 'Progress & weak areas');
  static const studyMinutes = Tr('পড়ার সময় (৭ দিন, মিনিট)', 'Study time (7 days, min)');
  static const practiced = Tr('অনুশীলিত প্রশ্ন', 'Questions practised');
  static const accuracy = Tr('সঠিকতা', 'Accuracy');
  static const streak = Tr('টানা দিন', 'Day streak');
  static const subjectMastery = Tr('বিষয়ভিত্তিক দক্ষতা', 'Subject mastery');
  static const weak = Tr('দুর্বল অধ্যায় — আগে অনুশীলন করো', 'Weak chapters — practise these first');
  static const strong = Tr('শক্তিশালী অধ্যায়', 'Strong chapters');
  static const practise = Tr('অনুশীলন', 'Practise');
  static const examTrend = Tr('পরীক্ষার ফলের ধারা', 'Exam score trend');
  static const noData = Tr('এখনো যথেষ্ট তথ্য নেই — কিছু প্রশ্ন অনুশীলন করো।', 'Not enough data yet — practise some questions.');
  static const achievements = Tr('অর্জন ও XP', 'Achievements & XP');
  static const level = Tr('লেভেল {n}', 'Level {n}');
  static const xpToNext = Tr('পরের লেভেলে {n} XP বাকি', '{n} XP to the next level');
  static const badges = Tr('ব্যাজ', 'Badges');
  static const missions = Tr('এই সপ্তাহের মিশন', "This week's missions");
  static const leaderboard = Tr('লিডারবোর্ড (ডেমো)', 'Leaderboard (demo)');
  static const leaderboardHidden = Tr('সেটিংসে প্রতিযোগিতামূলক অংশ লুকানো আছে।', 'Competitive features are hidden in settings.');
  static const you = Tr('তুমি', 'You');
}

class _Badge {
  const _Badge(this.icon, this.title, this.earned);

  final IconData icon;
  final Tr title;
  final bool earned;
}

List<Subject> _mySubjects(WidgetRef ref) {
  final level = ref.watch(studentProfileProvider.select((p) => p.level));
  return [for (final s in seedSubjects) if (s.level == level) s];
}

/// Mastery, weak/strong chapters, study time and exam trend (adaptive analytics).
class AnalyticsScreen extends ConsumerWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = ref.watch(learningProgressProvider);
    final exams = ref.watch(examProvider).finished.take(8).toList().reversed.toList();
    final subjects = _mySubjects(ref);
    final chapters = [
      for (final s in subjects)
        for (final c in s.chapters)
          if (c.topics.any((t) => p.topic(t.id).attempts > 0)) (s, c, p.chapterMastery(c)),
    ]..sort((a, b) => a.$3.compareTo(b.$3));
    final minutes = p.recentMinutes();
    final text = Theme.of(context).textTheme;
    return AppPageScaffold(
      title: context.tr(InsightStrings.analytics),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          StatGrid(
            cards: [
              StatCard(label: context.tr(InsightStrings.studyMinutes), value: context.n(minutes.fold<int>(0, (a, b) => a + b)), icon: Icons.timer_outlined),
              StatCard(label: context.tr(InsightStrings.practiced), value: context.n(p.practicedQuestions), icon: Icons.quiz_outlined),
              StatCard(label: context.tr(InsightStrings.accuracy), value: p.overallAccuracy == null ? '—' : context.pct(p.overallAccuracy! * 100), icon: Icons.track_changes),
              StatCard(label: context.tr(InsightStrings.streak), value: context.n(p.streak), icon: Icons.local_fire_department_outlined),
            ],
          ),
          SectionHeader(title: context.tr(InsightStrings.studyMinutes)),
          SizedBox(height: 160, child: _MinutesChart(minutes: minutes)),
          SectionHeader(title: context.tr(InsightStrings.subjectMastery)),
          for (final s in subjects)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: LabeledProgress(label: context.tr(s.name), value: p.subjectMastery(s)),
            ),
          SectionHeader(title: context.tr(InsightStrings.weak)),
          if (chapters.isEmpty)
            EmptyState(title: context.tr(InsightStrings.noData), compact: true, icon: Icons.insights_outlined)
          else
            for (final (s, c, m) in chapters.take(4))
              Card(
                margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: ListTile(
                  leading: ProgressRing(value: m, size: 40),
                  title: Text(context.tr(c.title)),
                  subtitle: Text(context.tr(s.name)),
                  trailing: TextButton(
                    onPressed: () => context.push(AppRoutes.practiceSession(subjectId: s.id, chapterId: c.id)),
                    child: Text(context.tr(InsightStrings.practise)),
                  ),
                ),
              ),
          if (chapters.length > 4) ...[
            SectionHeader(title: context.tr(InsightStrings.strong)),
            Wrap(
              spacing: AppSpacing.xs,
              runSpacing: AppSpacing.xs,
              children: [for (final (_, c, m) in chapters.reversed.take(4)) Pill('${context.tr(c.title)} · ${context.pct(m * 100)}', tone: Tone.success)],
            ),
          ],
          if (exams.length >= 2) ...[
            SectionHeader(title: context.tr(InsightStrings.examTrend)),
            SizedBox(
              height: 160,
              child: LineChart(
                LineChartData(
                  minY: 0,
                  maxY: 100,
                  gridData: const FlGridData(show: false),
                  borderData: FlBorderData(show: false),
                  titlesData: const FlTitlesData(topTitles: AxisTitles(), rightTitles: AxisTitles(), bottomTitles: AxisTitles()),
                  lineBarsData: [
                    LineChartBarData(
                      isCurved: true,
                      color: Theme.of(context).colorScheme.primary,
                      spots: [
                        for (var i = 0; i < exams.length; i++)
                          FlSpot(i.toDouble(), exams[i].result!.totalMarks == 0 ? 0 : 100 * exams[i].result!.score / exams[i].result!.totalMarks),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.md),
          Text(context.tr(const Tr('দক্ষতা = সঠিক উত্তর, সাম্প্রতিকতা ও পড়া শেষ করার সমন্বয়।', 'Mastery combines correct answers, recency and completion.')), style: text.bodySmall),
        ],
      ),
    );
  }
}

class _MinutesChart extends StatelessWidget {
  const _MinutesChart({required this.minutes});

  final List<int> minutes;

  @override
  Widget build(BuildContext context) {
    final maxY = math.max(30, minutes.fold(0, math.max)).toDouble() * 1.2;
    return BarChart(
      BarChartData(
        maxY: maxY,
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        titlesData: const FlTitlesData(topTitles: AxisTitles(), rightTitles: AxisTitles(), bottomTitles: AxisTitles()),
        barGroups: [
          for (var i = 0; i < minutes.length; i++)
            BarChartGroupData(x: i, barRods: [BarChartRodData(toY: minutes[i].toDouble(), width: 18, color: Theme.of(context).colorScheme.primary, borderRadius: BorderRadius.circular(4))]),
        ],
      ),
    );
  }
}

/// XP, level, streak, badges, weekly missions and an optional leaderboard.
class AchievementsScreen extends ConsumerWidget {
  const AchievementsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = ref.watch(learningProgressProvider);
    final exams = ref.watch(examProvider).finished;
    final hide = ref.watch(appSettingsProvider.select((s) => s.hideCompetitive));
    final lvl = levelFor(p.totalXp);
    final weekMinutes = p.recentMinutes().fold(0, (a, b) => a + b);
    final weekStart = DateTime.now().subtract(const Duration(days: 7));
    final weekExams = exams.where((e) => (e.submittedAt ?? e.startedAt).isAfter(weekStart)).length;
    final weekKinds = {for (final a in p.activities.where((a) => a.at.isAfter(weekStart))) a.kind};
    final badges = [
      _Badge(Icons.flag_outlined, const Tr('প্রথম পদক্ষেপ', 'First step'), p.activities.isNotEmpty),
      _Badge(Icons.local_fire_department, const Tr('৭ দিনের ধারা', '7-day streak'), p.streak >= 7),
      _Badge(Icons.quiz, const Tr('১০০ প্রশ্ন', '100 questions'), p.practicedQuestions >= 100),
      _Badge(Icons.assignment_turned_in, const Tr('প্রথম পরীক্ষা', 'First exam'), exams.isNotEmpty),
      _Badge(Icons.workspace_premium, const Tr('লেভেল ৫', 'Level 5'), lvl.level >= 5),
      _Badge(Icons.style, const Tr('ফ্ল্যাশকার্ড অভ্যাস', 'Flashcard habit'), p.activities.where((a) => a.kind == ActivityKind.flashcards).length >= 5),
    ];
    final missions = [
      (const Tr('এই সপ্তাহে ১২০ মিনিট পড়ো', 'Study 120 minutes this week'), (weekMinutes / 120).clamp(0.0, 1.0)),
      (const Tr('একটি পরীক্ষা দাও', 'Take one exam'), weekExams > 0 ? 1.0 : 0.0),
      (const Tr('৩ ধরনের পড়া করো (পাঠ, অনুশীলন, টিউটর…)', 'Do 3 kinds of study (lesson, practice, tutor…)'), (weekKinds.length / 3).clamp(0.0, 1.0)),
    ];
    final text = Theme.of(context).textTheme;
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
                  ProgressRing(value: lvl.intoLevel / lvl.forNext, size: 72, center: Text(context.n(lvl.level), style: text.titleLarge)),
                  const SizedBox(width: AppSpacing.lg),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(context.tr(InsightStrings.level.fill({'n': lvl.level})), style: text.titleLarge),
                        Text('${context.n(p.totalXp)} XP', style: text.bodyMedium),
                        Text(context.tr(InsightStrings.xpToNext.fill({'n': lvl.forNext - lvl.intoLevel})), style: text.bodySmall),
                      ],
                    ),
                  ),
                  Column(children: [const Icon(Icons.local_fire_department, color: Colors.deepOrange), Text(context.n(p.streak), style: text.titleMedium)]),
                ],
              ),
            ),
          ),
          SectionHeader(title: context.tr(InsightStrings.badges)),
          GridView.count(
            crossAxisCount: 3,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: AppSpacing.sm,
            crossAxisSpacing: AppSpacing.sm,
            children: [
              for (final b in badges)
                Card(
                  margin: EdgeInsets.zero,
                  child: Opacity(
                    opacity: b.earned ? 1 : 0.4,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(b.icon, size: 32, color: b.earned ? Theme.of(context).colorScheme.primary : null),
                        const SizedBox(height: AppSpacing.xs),
                        Text(context.tr(b.title), textAlign: TextAlign.center, style: text.labelSmall),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          SectionHeader(title: context.tr(InsightStrings.missions)),
          for (final (title, v) in missions) Padding(padding: const EdgeInsets.only(bottom: AppSpacing.sm), child: LabeledProgress(label: context.tr(title), value: v)),
          SectionHeader(title: context.tr(InsightStrings.leaderboard)),
          if (hide)
            Text(context.tr(InsightStrings.leaderboardHidden), style: text.bodySmall)
          else
            for (final (i, (name, xp)) in [
              ('তানিয়া (ডেমো)', p.totalXp + 340),
              (context.tr(InsightStrings.you), p.totalXp),
              ('রাশেদ (ডেমো)', math.max(0, p.totalXp - 120)),
              ('নুসাইবা (ডেমো)', math.max(0, p.totalXp - 260)),
            ].indexed)
              ListTile(
                dense: true,
                leading: CircleAvatar(child: Text(context.n(i + 1))),
                title: Text(name, style: name == context.tr(InsightStrings.you) ? text.titleSmall : null),
                trailing: Text('${context.n(xp)} XP'),
              ),
        ],
      ),
    );
  }
}
