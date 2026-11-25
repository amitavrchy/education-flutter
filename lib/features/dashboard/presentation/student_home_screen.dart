import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../app/router/app_routes.dart';
import '../../../core/l10n/tr.dart';
import '../../../core/settings/app_settings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/time_format.dart';
import '../../../mock/seed/curriculum_seed.dart';
import '../../../shared/widgets/app_page_scaffold.dart';
import '../../../shared/widgets/badges.dart';
import '../../../shared/widgets/cards.dart';
import '../../../shared/widgets/progress.dart';
import '../../../shared/widgets/section_header.dart';
import '../../../shared/widgets/stat_card.dart';
import '../../account/account_controller.dart';
import '../../ai_tutor/application/tutor_controller.dart';
import '../../book_avatar/data/book_catalog.dart';
import '../../curriculum/domain/curriculum_models.dart';
import '../../exams/application/exam_controller.dart';
import '../../exams/domain/exam.dart';
import '../../flashcards/application/flashcards_controller.dart';
import '../../library/library_controller.dart';
import '../../notes/application/notes_controller.dart';
import '../../notifications/application/notifications_controller.dart';
import '../../notifications/domain/app_notification.dart';
import '../../planner/application/planner_controller.dart';
import '../../planner/domain/study_task.dart';
import '../../profile/application/student_profile_controller.dart';
import '../../progress/application/learning_progress_controller.dart';
import '../../progress/domain/learning_progress.dart';
import '../../question_bank/application/practice_controller.dart';
import 'widgets/greeting_header.dart';

abstract final class HomeStrings {
  static const title = Tr('ড্যাশবোর্ড', 'Dashboard');
  static const subtitle = Tr('আজ কী শিখতে চাও?', 'What do you want to learn today?');
  static const customise = Tr('ড্যাশবোর্ড সাজাও', 'Customise dashboard');
  static const customiseHint = Tr('টেনে ক্রম বদলাও, সুইচ দিয়ে লুকাও। পছন্দ সংরক্ষিত থাকে।', 'Drag to reorder, switch to hide. Your choice is saved.');
  static const reset = Tr('ডিফল্টে ফেরাও', 'Reset to default');
  static const intro = Tr('তোমার প্রোফাইল অনুযায়ী ড্যাশবোর্ড তৈরি হয়েছে — দুর্বল বিষয়, লক্ষ্য ও পরীক্ষার তারিখ মিলিয়ে।', 'Your dashboard is built from your profile — weak subjects, goals and exam date.');
  static const introOk = Tr('বুঝেছি', 'Got it');
  static const summary = Tr('আজকের সারাংশ', "Today's summary");
  static const minToday = Tr('আজ পড়েছ', 'Studied today');
  static const tasksToday = Tr('আজকের কাজ', "Today's tasks");
  static const cardsToday = Tr('রিভিউ করা কার্ড', 'Cards reviewed');
  static const xpToday = Tr('আজকের XP', 'XP today');
  static const goal = Tr('আজকের লক্ষ্য', "Today's goal");
  static const goalOf = Tr('{a}/{b} মিনিট', '{a}/{b} min');
  static const goalDone = Tr('আজকের লক্ষ্য পূরণ! 🎉', "Today's goal reached! 🎉");
  static const week = Tr('সাপ্তাহিক পড়ার সময়', 'Weekly study time');
  static const streak = Tr('টানা পড়ার দিন', 'Study streak');
  static const streakDays = Tr('{n} দিন', '{n} days');
  static const recommended = Tr('আজকের প্রস্তাবিত অধ্যায়', "Today's recommended chapters");
  static const continueLearning = Tr('শেখা চালিয়ে যাও', 'Continue learning');
  static const nextTopic = Tr('পরের টপিক', 'Next topic');
  static const page = Tr('পৃষ্ঠা {n}', 'Page {n}');
  static const upcoming = Tr('আসন্ন পরীক্ষা', 'Upcoming exams');
  static const examCountdown = Tr('বোর্ড পরীক্ষার {n} দিন বাকি', '{n} days to the board exam');
  static const exams = Tr('সব পরীক্ষা', 'All exams');
  static const quickTutor = Tr('দ্রুত AI টিউটর', 'Quick AI tutor');
  static const askHint = Tr('যেকোনো প্রশ্ন লেখো…', 'Ask anything…');
  static const conversations = Tr('সাম্প্রতিক কথোপকথন', 'Recent conversations');
  static const weak = Tr('দুর্বল টপিক সতর্কতা', 'Weak topic alerts');
  static const practise = Tr('অনুশীলন', 'Practise');
  static const revision = Tr('রিভিশন রিমাইন্ডার', 'Revision reminders');
  static const cardsDue = Tr('{n}টি ফ্ল্যাশকার্ড রিভিউ বাকি', '{n} flashcards due');
  static const revisionTasks = Tr('{n}টি রিভিশন কাজ আজ', '{n} revision tasks today');
  static const review = Tr('রিভিউ করো', 'Review');
  static const sessions = Tr('আসন্ন পড়ার সেশন', 'Upcoming study sessions');
  static const noSessions = Tr('আজ আর কোনো সেশন নেই — প্ল্যানার থেকে যোগ করো।', 'No more sessions today — add some in the planner.');
  static const planner = Tr('প্ল্যানার', 'Planner');
  static const subjects = Tr('বিষয়ভিত্তিক পারফরম্যান্স', 'Subject performance');
  static const completion = Tr('অধ্যায় সম্পন্ন', 'Chapter completion');
  static const completionOf = Tr('{a}/{b} টপিক শেষ', '{a}/{b} topics done');
  static const dailyQuiz = Tr('ডেইলি কুইজ', 'Daily quiz');
  static const dailyQuizSub = Tr('দুর্বল টপিক থেকে ৫টি প্রশ্ন · ~৫ মিনিট', '5 questions from weak topics · ~5 min');
  static const start = Tr('শুরু করো', 'Start');
  static const saved = Tr('সংরক্ষিত প্রশ্ন', 'Saved questions');
  static const savedN = Tr('{n}টি প্রশ্ন বুকমার্ক করা', '{n} bookmarked questions');
  static const models = Tr('প্রস্তাবিত মডেল টেস্ট', 'Recommended model tests');
  static const achievements = Tr('অর্জন', 'Achievements');
  static const level = Tr('লেভেল {n}', 'Level {n}');
  static const xpToNext = Tr('পরের লেভেলে {n} XP', '{n} XP to next level');
  static const notices = Tr('যাচাইকৃত শিক্ষা বিজ্ঞপ্তি', 'Verified educational notices');
  static const noNotices = Tr('নতুন বিজ্ঞপ্তি নেই', 'No new notices');
  static const subscription = Tr('সাবস্ক্রিপশন', 'Subscription');
  static const renews = Tr('নবায়ন: {d}', 'Renews: {d}');
  static const upgrade = Tr('প্রো নাও', 'Upgrade');
  static const manage = Tr('পরিচালনা', 'Manage');
  static const calendar = Tr('স্টাডি ক্যালেন্ডার', 'Study calendar');
  static const notifications = Tr('নোটিফিকেশন', 'Notifications');
  static const allCaught = Tr('সব পড়া হয়ে গেছে', "You're all caught up");
  static const resources = Tr('সাম্প্রতিক রিসোর্স', 'Recent resources');
  static const noResources = Tr('এখনো কিছু খোলা হয়নি', 'Nothing opened yet');
  static const quick = Tr('দ্রুত শুরু করো', 'Quick start');
  static const avatar = Tr('বইয়ের শিক্ষক', 'Book teacher');
  static const tutor = Tr('AI টিউটর', 'AI tutor');
  static const photo = Tr('ছবি থেকে সমাধান', 'Photo solver');
  static const modelTest = Tr('মডেল টেস্ট', 'Model test');
  static const empty = Tr('এখনো তথ্য নেই — কিছু পড়া বা অনুশীলন করো।', 'No data yet — study or practise a little.');
}

/// One dashboard widget (DASH-01..24). Ids are persisted in [AppSettings.dashboardOrder].
enum DashWidget {
  summary(HomeStrings.summary, Icons.today_outlined),
  goal(HomeStrings.goal, Icons.flag_outlined),
  weekly(HomeStrings.week, Icons.bar_chart),
  streak(HomeStrings.streak, Icons.local_fire_department_outlined),
  continueLearning(HomeStrings.continueLearning, Icons.play_circle_outline),
  sessions(HomeStrings.sessions, Icons.schedule),
  recommended(HomeStrings.recommended, Icons.recommend_outlined),
  quickTutor(HomeStrings.quickTutor, Icons.smart_toy_outlined),
  weak(HomeStrings.weak, Icons.warning_amber_outlined),
  revision(HomeStrings.revision, Icons.replay),
  dailyQuiz(HomeStrings.dailyQuiz, Icons.bolt),
  exams(HomeStrings.upcoming, Icons.event_note_outlined),
  models(HomeStrings.models, Icons.assignment_outlined),
  subjects(HomeStrings.subjects, Icons.insights_outlined),
  completion(HomeStrings.completion, Icons.donut_large),
  conversations(HomeStrings.conversations, Icons.forum_outlined),
  saved(HomeStrings.saved, Icons.bookmark_border),
  achievements(HomeStrings.achievements, Icons.emoji_events_outlined),
  calendar(HomeStrings.calendar, Icons.calendar_month_outlined),
  notifications(HomeStrings.notifications, Icons.notifications_none),
  notices(HomeStrings.notices, Icons.campaign_outlined),
  resources(HomeStrings.resources, Icons.folder_open_outlined),
  subscription(HomeStrings.subscription, Icons.workspace_premium_outlined),
  quick(HomeStrings.quick, Icons.rocket_launch_outlined);

  const DashWidget(this.label, this.icon);

  final Tr label;
  final IconData icon;

  /// Persisted order with unknown ids dropped and new widgets appended.
  static List<DashWidget> ordered(List<String> saved) {
    final known = {for (final w in values) w.name: w};
    final out = [for (final id in saved) if (known[id] != null) known[id]!];
    return [...out, for (final w in values) if (!out.contains(w)) w];
  }
}

/// Student home: greeting + the student's chosen widgets in their chosen order.
class StudentHomeScreen extends ConsumerWidget {
  const StudentHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(appSettingsProvider);
    final hidden = settings.hiddenWidgets.toSet();
    final widgets = [for (final w in DashWidget.ordered(settings.dashboardOrder)) if (!hidden.contains(w.name)) w];
    return AppPageScaffold(
      title: context.tr(HomeStrings.title),
      actions: [
        IconButton(
          key: const Key('dash.customise'),
          tooltip: context.tr(HomeStrings.customise),
          icon: const Icon(Icons.dashboard_customize_outlined),
          onPressed: () => showModalBottomSheet<void>(context: context, isScrollControlled: true, showDragHandle: true, builder: (_) => const DashboardCustomiseSheet()),
        ),
      ],
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          GreetingHeader(subtitle: context.tr(HomeStrings.subtitle)),
          if (!hidden.contains('_intro')) const _IntroCard(),
          for (final w in widgets) KeyedSubtree(key: Key('dash.${w.name}'), child: _build(w)),
        ],
      ),
    );
  }

  Widget _build(DashWidget w) => switch (w) {
    DashWidget.summary => const _SummaryWidget(),
    DashWidget.goal => const _GoalWidget(),
    DashWidget.weekly => const _WeeklyWidget(),
    DashWidget.streak => const _StreakWidget(),
    DashWidget.continueLearning => const _ContinueWidget(),
    DashWidget.sessions => const _SessionsWidget(),
    DashWidget.recommended => const _RecommendedWidget(),
    DashWidget.quickTutor => const _QuickTutorWidget(),
    DashWidget.weak => const _WeakWidget(),
    DashWidget.revision => const _RevisionWidget(),
    DashWidget.dailyQuiz => const _DailyQuizWidget(),
    DashWidget.exams => const _ExamsWidget(),
    DashWidget.models => const _ModelsWidget(),
    DashWidget.subjects => const _SubjectsWidget(),
    DashWidget.completion => const _CompletionWidget(),
    DashWidget.conversations => const _ConversationsWidget(),
    DashWidget.saved => const _SavedWidget(),
    DashWidget.achievements => const _AchievementsWidget(),
    DashWidget.calendar => const _CalendarWidget(),
    DashWidget.notifications => const _NotificationsWidget(),
    DashWidget.notices => const _NoticesWidget(),
    DashWidget.resources => const _ResourcesWidget(),
    DashWidget.subscription => const _SubscriptionWidget(),
    DashWidget.quick => const _QuickWidget(),
  };
}

/// Personalised dashboard introduction (AUTH-29), dismissed once.
class _IntroCard extends ConsumerWidget {
  const _IntroCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) => Padding(
    padding: const EdgeInsets.only(top: AppSpacing.md),
    child: InfoBanner(
      message: context.tr(HomeStrings.intro),
      icon: Icons.auto_awesome_outlined,
      tone: Tone.info,
      action: TextButton(
        key: const Key('dash.introOk'),
        onPressed: () => ref.read(appSettingsProvider.notifier).update((s) => s.copyWith(hiddenWidgets: [...s.hiddenWidgets, '_intro'])),
        child: Text(context.tr(HomeStrings.introOk)),
      ),
    ),
  );
}

/// Reorder (drag) and hide widgets; persisted (DASH-25).
class DashboardCustomiseSheet extends ConsumerWidget {
  const DashboardCustomiseSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(appSettingsProvider);
    final ctl = ref.read(appSettingsProvider.notifier);
    final order = DashWidget.ordered(s.dashboardOrder);
    final hidden = s.hiddenWidgets.toSet();
    return SizedBox(
      height: MediaQuery.sizeOf(context).height * 0.8,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Row(
              children: [
                Expanded(child: Text(context.tr(HomeStrings.customise), style: context.text.titleLarge)),
                TextButton(
                  key: const Key('dash.reset'),
                  onPressed: () => ctl.update((x) => x.copyWith(dashboardOrder: const [], hiddenWidgets: [for (final h in x.hiddenWidgets) if (h.startsWith('_')) h])),
                  child: Text(context.tr(HomeStrings.reset)),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Text(context.tr(HomeStrings.customiseHint), style: context.text.bodySmall),
          ),
          Expanded(
            child: ReorderableListView(
              buildDefaultDragHandles: false,
              padding: const EdgeInsets.all(AppSpacing.md),
              onReorderItem: (from, to) {
                final list = [...order];
                final item = list.removeAt(from);
                list.insert(to, item);
                ctl.update((x) => x.copyWith(dashboardOrder: [for (final w in list) w.name]));
              },
              children: [
                for (final (i, w) in order.indexed)
                  ListTile(
                    key: ValueKey(w.name),
                    leading: ReorderableDragStartListener(index: i, child: const Icon(Icons.drag_indicator)),
                    title: Row(children: [Icon(w.icon, size: 18), const SizedBox(width: AppSpacing.sm), Expanded(child: Text(context.tr(w.label)))]),
                    trailing: Switch(
                      key: Key('dash.toggle.${w.name}'),
                      value: !hidden.contains(w.name),
                      onChanged: (v) => ctl.update((x) => x.copyWith(hiddenWidgets: v ? [for (final h in x.hiddenWidgets) if (h != w.name) h] : [...x.hiddenWidgets, w.name])),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ───────────────────────── helpers ─────────────────────────

DateTime _day(DateTime d) => DateTime(d.year, d.month, d.day);

List<Subject> _mySubjects(WidgetRef ref) {
  final level = ref.watch(studentProfileProvider.select((p) => p.level));
  return [for (final s in seedSubjects) if (s.level == level) s];
}

class _Box extends StatelessWidget {
  const _Box({required this.title, required this.child, this.action, this.onAction});

  final Tr title;
  final Widget child;
  final Tr? action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      SectionHeader(title: context.tr(title), actionLabel: action == null ? null : context.tr(action!), onAction: onAction),
      child,
    ],
  );
}

// ───────────────────────── widgets ─────────────────────────

class _SummaryWidget extends ConsumerWidget {
  const _SummaryWidget();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = DateTime.now();
    final p = ref.watch(learningProgressProvider);
    final today = ref.watch(plannerProvider).on(now);
    final cards = ref.watch(flashcardsProvider).reviewedOn(now);
    final xp = p.activities.where((a) => _day(a.at) == _day(now)).fold<int>(0, (s, a) => s + a.xp);
    return _Box(
      title: HomeStrings.summary,
      child: StatGrid(
        cards: [
          StatCard(label: context.tr(HomeStrings.minToday), value: context.n(p.minutesOn(now)), icon: Icons.timer_outlined, onTap: () => context.push(AppRoutes.analytics)),
          StatCard(
            label: context.tr(HomeStrings.tasksToday),
            value: '${context.n(today.where((t) => t.status == TaskStatus.done).length)}/${context.n(today.length)}',
            icon: Icons.task_alt,
            onTap: () => context.push(AppRoutes.planner),
          ),
          StatCard(label: context.tr(HomeStrings.cardsToday), value: context.n(cards), icon: Icons.style_outlined, onTap: () => context.push(AppRoutes.flashcards())),
          StatCard(label: context.tr(HomeStrings.xpToday), value: context.n(xp), icon: Icons.bolt, onTap: () => context.push(AppRoutes.achievements)),
        ],
      ),
    );
  }
}

class _GoalWidget extends ConsumerWidget {
  const _GoalWidget();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final target = ref.watch(plannerProvider.select((s) => s.prefs.dailyMinutes));
    final done = ref.watch(learningProgressProvider).minutesOn(DateTime.now());
    final v = target == 0 ? 0.0 : (done / target).clamp(0.0, 1.0);
    return _Box(
      title: HomeStrings.goal,
      child: TapCard(
        onTap: () => context.push(AppRoutes.planner),
        child: Row(
          children: [
            ProgressRing(value: v, size: 56, center: Text(context.pct(v * 100), style: context.text.labelSmall)),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(context.tr(HomeStrings.goalOf.fill({'a': done, 'b': target})), style: context.text.titleMedium),
                  if (v >= 1) Text(context.tr(HomeStrings.goalDone), style: context.text.bodySmall?.copyWith(color: context.palette.success)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WeeklyWidget extends ConsumerWidget {
  const _WeeklyWidget();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final minutes = ref.watch(learningProgressProvider).recentMinutes();
    final now = DateTime.now();
    final days = context.isBangla ? const ['র', 'সো', 'ম', 'বু', 'বৃ', 'শু', 'শ'] : const ['S', 'M', 'T', 'W', 'T', 'F', 'S'];
    return _Box(
      title: HomeStrings.week,
      action: HomeStrings.subjects,
      onAction: () => context.push(AppRoutes.analytics),
      child: SizedBox(
        height: 140,
        child: Semantics(
          label: '${context.tr(HomeStrings.week)}: ${minutes.join(', ')}',
          child: BarChart(
            BarChartData(
              gridData: const FlGridData(show: false),
              borderData: FlBorderData(show: false),
              titlesData: FlTitlesData(
                topTitles: const AxisTitles(),
                rightTitles: const AxisTitles(),
                leftTitles: const AxisTitles(),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(showTitles: true, getTitlesWidget: (v, _) => Text(days[now.subtract(Duration(days: 6 - v.toInt())).weekday % 7], style: context.text.labelSmall)),
                ),
              ),
              barGroups: [
                for (var i = 0; i < minutes.length; i++)
                  BarChartGroupData(x: i, barRods: [BarChartRodData(toY: minutes[i].toDouble(), width: 14, color: context.colors.primary, borderRadius: BorderRadius.circular(4))]),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StreakWidget extends ConsumerWidget {
  const _StreakWidget();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = ref.watch(learningProgressProvider);
    final now = DateTime.now();
    return _Box(
      title: HomeStrings.streak,
      child: TapCard(
        onTap: () => context.push(AppRoutes.achievements),
        child: Row(
          children: [
            Icon(Icons.local_fire_department, color: context.palette.streak, size: 36),
            const SizedBox(width: AppSpacing.sm),
            Text(context.tr(HomeStrings.streakDays.fill({'n': p.streak})), style: context.text.titleLarge),
            const Spacer(),
            for (var d = 6; d >= 0; d--)
              Padding(
                padding: const EdgeInsets.only(left: 3),
                child: CircleAvatar(
                  radius: 7,
                  backgroundColor: p.minutesOn(now.subtract(Duration(days: d))) > 0 ? context.palette.streak : context.colors.surfaceContainerHighest,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ContinueWidget extends ConsumerWidget {
  const _ContinueWidget();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = ref.watch(learningProgressProvider);
    final reading = ref.watch(libraryProvider);
    final subjects = _mySubjects(ref);
    // Most recently studied topic, then the next unfinished topic in that chapter.
    (Subject, Chapter, Topic)? last;
    DateTime? lastAt;
    for (final s in subjects) {
      for (final c in s.chapters) {
        for (final t in c.topics) {
          final at = p.topic(t.id).lastStudied;
          if (at != null && (lastAt == null || at.isAfter(lastAt))) {
            lastAt = at;
            last = (s, c, t);
          }
        }
      }
    }
    final next = last?.$2.topics.where((t) => !p.topic(t.id).completed).firstOrNull;
    final lastRead = [for (final r in reading.values) if (r.lastPage != null && r.updatedAt != null) r]..sort((a, b) => b.updatedAt!.compareTo(a.updatedAt!));
    final book = lastRead.isEmpty ? null : bookById(lastRead.first.bookId);
    if (last == null && book == null) {
      final s = subjects.firstOrNull;
      final c = s?.chapters.firstOrNull;
      return _Box(
        title: HomeStrings.continueLearning,
        child: NavTile(icon: Icons.play_arrow, title: c == null ? context.tr(HomeStrings.empty) : context.tr(c.title), subtitle: s == null ? null : context.tr(s.name), onTap: c == null ? null : () => context.go(AppRoutes.chapter(c.id))),
      );
    }
    return _Box(
      title: HomeStrings.continueLearning,
      child: Column(
        children: [
          if (last != null)
            NavTile(
              icon: Icons.play_circle_outline,
              title: context.tr((next ?? last.$3).title),
              subtitle: '${context.tr(last.$1.name)} · ${context.tr(last.$2.title)}${next != null && next != last.$3 ? ' · ${context.tr(HomeStrings.nextTopic)}' : ''}',
              onTap: () => context.go(AppRoutes.topic((next ?? last!.$3).id)),
            ),
          if (book != null) ...[
            const SizedBox(height: AppSpacing.sm),
            NavTile(
              icon: book.icon,
              color: book.color,
              title: context.tr(book.title),
              subtitle: '${context.tr(HomeStrings.page.fill({'n': lastRead.first.lastPage!}))} · ${relativeTime(lastRead.first.updatedAt!, context.lang)}',
              onTap: () => context.push(AppRoutes.bookReader(book.id, page: lastRead.first.lastPage)),
            ),
          ],
        ],
      ),
    );
  }
}

class _SessionsWidget extends ConsumerWidget {
  const _SessionsWidget();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = DateTime.now();
    final plan = ref.watch(plannerProvider);
    final upcoming = [
      for (final t in plan.between(now, now.add(const Duration(days: 2))))
        if (t.status == TaskStatus.scheduled && t.start.isAfter(now.subtract(const Duration(minutes: 30)))) t,
    ]..sort((a, b) => a.start.compareTo(b.start));
    return _Box(
      title: HomeStrings.sessions,
      action: HomeStrings.planner,
      onAction: () => context.push(AppRoutes.planner),
      child: upcoming.isEmpty
          ? Text(context.tr(HomeStrings.noSessions), style: context.text.bodySmall)
          : Column(
              children: [
                for (final t in upcoming.take(3))
                  Card(
                    margin: const EdgeInsets.only(bottom: AppSpacing.xs),
                    child: ListTile(
                      dense: true,
                      leading: Icon(t.kind.icon),
                      title: Text(context.tr(t.title)),
                      subtitle: Text('${DateUtils.isSameDay(t.day, now) ? '' : '${shortDate(t.day, context.lang)} · '}${context.n(t.startMinute ~/ 60)}:${(t.startMinute % 60).toString().padLeft(2, '0')} · ${context.n(t.minutes)} min'),
                      onTap: () => context.push(AppRoutes.planner),
                    ),
                  ),
              ],
            ),
    );
  }
}

class _RecommendedWidget extends ConsumerWidget {
  const _RecommendedWidget();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = ref.watch(learningProgressProvider);
    final weakSubjects = ref.watch(studentProfileProvider.select((s) => s.weakSubjectIds)).toSet();
    final chapters = [
      for (final s in _mySubjects(ref))
        for (final c in s.chapters)
          if (p.chapterCompletion(c) < 1) (s, c, p.chapterMastery(c) - (weakSubjects.contains(s.id) ? 0.3 : 0) - c.relevance.index * 0.05),
    ]..sort((a, b) => a.$3.compareTo(b.$3));
    return _Box(
      title: HomeStrings.recommended,
      child: SizedBox(
        height: 116,
        child: ListView(
          scrollDirection: Axis.horizontal,
          children: [
            for (final (s, c, _) in chapters.take(5))
              SizedBox(
                width: 200,
                child: TapCard(
                  onTap: () => context.go(AppRoutes.chapter(c.id)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [Icon(s.icon, color: s.color, size: 18), const SizedBox(width: 4), Expanded(child: Text(context.tr(s.name), style: context.text.labelSmall, overflow: TextOverflow.ellipsis))]),
                      const SizedBox(height: AppSpacing.xs),
                      Text(context.tr(c.title), style: context.text.titleSmall, maxLines: 2, overflow: TextOverflow.ellipsis),
                      const Spacer(),
                      LinearProgressIndicator(value: p.chapterCompletion(c), minHeight: 4),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _QuickTutorWidget extends StatefulWidget {
  const _QuickTutorWidget();

  @override
  State<_QuickTutorWidget> createState() => _QuickTutorWidgetState();
}

class _QuickTutorWidgetState extends State<_QuickTutorWidget> {
  final _c = TextEditingController();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  void _send() {
    final q = _c.text.trim();
    if (q.isEmpty) return;
    _c.clear();
    context.go(AppRoutes.tutor(prompt: q));
  }

  @override
  Widget build(BuildContext context) => _Box(
    title: HomeStrings.quickTutor,
    child: TextField(
      key: const Key('dash.tutor'),
      controller: _c,
      textInputAction: TextInputAction.send,
      onSubmitted: (_) => _send(),
      decoration: InputDecoration(
        hintText: context.tr(HomeStrings.askHint),
        prefixIcon: const Icon(Icons.smart_toy_outlined),
        suffixIcon: IconButton(key: const Key('dash.tutorSend'), icon: const Icon(Icons.send), onPressed: _send),
      ),
    ),
  );
}

class _WeakWidget extends ConsumerWidget {
  const _WeakWidget();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = ref.watch(learningProgressProvider);
    final weak = [
      for (final s in _mySubjects(ref))
        for (final c in s.chapters)
          for (final t in c.topics)
            if (p.topic(t.id).attempts >= 2 && p.topic(t.id).mastery < 0.5) (s, c, t, p.topic(t.id).mastery),
    ]..sort((a, b) => a.$4.compareTo(b.$4));
    if (weak.isEmpty) return const SizedBox.shrink();
    return _Box(
      title: HomeStrings.weak,
      action: HomeStrings.subjects,
      onAction: () => context.push(AppRoutes.analytics),
      child: Column(
        children: [
          for (final (s, c, t, m) in weak.take(3))
            Card(
              margin: const EdgeInsets.only(bottom: AppSpacing.xs),
              child: ListTile(
                leading: ProgressRing(value: m, size: 36),
                title: Text(context.tr(t.title)),
                subtitle: Text(context.tr(s.name)),
                trailing: TextButton(onPressed: () => context.push(AppRoutes.practiceSession(subjectId: s.id, chapterId: c.id, topicId: t.id)), child: Text(context.tr(HomeStrings.practise))),
              ),
            ),
        ],
      ),
    );
  }
}

class _RevisionWidget extends ConsumerWidget {
  const _RevisionWidget();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = DateTime.now();
    final due = ref.watch(flashcardsProvider).dueIn(null, now).length;
    final rev = ref.watch(plannerProvider).on(now).where((t) => t.kind == TaskKind.revision && t.status == TaskStatus.scheduled).length;
    return _Box(
      title: HomeStrings.revision,
      child: Column(
        children: [
          NavTile(icon: Icons.style_outlined, title: context.tr(HomeStrings.cardsDue.fill({'n': due})), onTap: () => context.push(AppRoutes.flashcards()), trailing: due > 0 ? Pill(context.tr(HomeStrings.review), tone: Tone.warning) : null),
          if (rev > 0) ...[
            const SizedBox(height: AppSpacing.xs),
            NavTile(icon: Icons.replay, title: context.tr(HomeStrings.revisionTasks.fill({'n': rev})), onTap: () => context.push(AppRoutes.planner)),
          ],
        ],
      ),
    );
  }
}

class _DailyQuizWidget extends ConsumerWidget {
  const _DailyQuizWidget();

  @override
  Widget build(BuildContext context, WidgetRef ref) => _Box(
    title: HomeStrings.dailyQuiz,
    child: Card(
      color: context.colors.primaryContainer,
      margin: EdgeInsets.zero,
      child: ListTile(
        leading: const Icon(Icons.bolt),
        title: Text(context.tr(HomeStrings.dailyQuiz)),
        subtitle: Text(context.tr(HomeStrings.dailyQuizSub)),
        trailing: FilledButton(key: const Key('dash.quiz'), onPressed: () => context.push(AppRoutes.practiceSession(mode: 'daily')), child: Text(context.tr(HomeStrings.start))),
      ),
    ),
  );
}

class _ExamsWidget extends ConsumerWidget {
  const _ExamsWidget();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final exams = ref.watch(examProvider);
    final plan = ref.watch(plannerProvider);
    final days = plan.daysToExam(DateTime.now());
    final open = [...exams.open]..sort((a, b) => (a.dueAt ?? DateTime(2100)).compareTo(b.dueAt ?? DateTime(2100)));
    return _Box(
      title: HomeStrings.upcoming,
      action: HomeStrings.exams,
      onAction: () => context.go(AppRoutes.examCenter),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (days >= 0) Padding(padding: const EdgeInsets.only(bottom: AppSpacing.xs), child: Pill(context.tr(HomeStrings.examCountdown.fill({'n': days})), tone: days < 60 ? Tone.warning : Tone.info, icon: Icons.hourglass_bottom)),
          for (final e in open.take(2))
            Card(
              margin: const EdgeInsets.only(bottom: AppSpacing.xs),
              child: ListTile(
                dense: true,
                leading: Icon(e.type.icon),
                title: Text(context.tr(e.title)),
                subtitle: Text(context.tr(e.type.label) + (e.dueAt == null ? '' : ' · ${relativeTime(e.dueAt!, context.lang)}')),
                onTap: () => context.go(AppRoutes.examCenter),
              ),
            ),
        ],
      ),
    );
  }
}

class _ModelsWidget extends ConsumerWidget {
  const _ModelsWidget();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final models = [for (final t in ref.watch(examProvider).open) if (t.type == ExamType.modelTest || t.type == ExamType.fullSyllabus || t.type == ExamType.boardPrevious) t];
    if (models.isEmpty) return const SizedBox.shrink();
    return _Box(
      title: HomeStrings.models,
      child: SizedBox(
        height: 96,
        child: ListView(
          scrollDirection: Axis.horizontal,
          children: [
            for (final t in models.take(4))
              SizedBox(
                width: 210,
                child: TapCard(
                  onTap: () => context.go(AppRoutes.examCenter),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(t.type.icon, size: 20),
                      const SizedBox(height: AppSpacing.xs),
                      Text(context.tr(t.title), style: context.text.titleSmall, maxLines: 2, overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _SubjectsWidget extends ConsumerWidget {
  const _SubjectsWidget();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = ref.watch(learningProgressProvider);
    final subjects = [..._mySubjects(ref)]..sort((a, b) => p.subjectMastery(b).compareTo(p.subjectMastery(a)));
    return _Box(
      title: HomeStrings.subjects,
      action: HomeStrings.subjects,
      onAction: () => context.push(AppRoutes.analytics),
      child: Column(
        children: [
          for (final s in subjects.take(4))
            Padding(padding: const EdgeInsets.only(bottom: AppSpacing.sm), child: LabeledProgress(label: context.tr(s.name), value: p.subjectMastery(s), color: s.color, dense: true)),
        ],
      ),
    );
  }
}

class _CompletionWidget extends ConsumerWidget {
  const _CompletionWidget();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = ref.watch(learningProgressProvider);
    final topics = [for (final s in _mySubjects(ref)) for (final c in s.chapters) ...c.topics];
    final done = topics.where((t) => p.topic(t.id).completed).length;
    final v = topics.isEmpty ? 0.0 : done / topics.length;
    return _Box(
      title: HomeStrings.completion,
      child: TapCard(
        onTap: () => context.go(AppRoutes.learn),
        child: Row(
          children: [
            ProgressRing(value: v, size: 56, center: Text(context.pct(v * 100), style: context.text.labelSmall)),
            const SizedBox(width: AppSpacing.md),
            Expanded(child: Text(context.tr(HomeStrings.completionOf.fill({'a': done, 'b': topics.length})), style: context.text.titleMedium)),
          ],
        ),
      ),
    );
  }
}

class _ConversationsWidget extends ConsumerWidget {
  const _ConversationsWidget();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final list = [for (final c in ref.watch(tutorProvider)) if (!c.archived && c.messages.isNotEmpty) c]..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    if (list.isEmpty) return const SizedBox.shrink();
    return _Box(
      title: HomeStrings.conversations,
      action: HomeStrings.tutor,
      onAction: () => context.go(AppRoutes.tutorTab),
      child: Column(
        children: [
          for (final c in list.take(3))
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.forum_outlined),
              title: Text(c.title, maxLines: 1, overflow: TextOverflow.ellipsis),
              subtitle: Text(relativeTime(c.updatedAt, context.lang)),
              onTap: () => context.go(AppRoutes.tutorChat(c.id)),
            ),
        ],
      ),
    );
  }
}

class _SavedWidget extends ConsumerWidget {
  const _SavedWidget();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final n = ref.watch(practiceProvider).bookmarks.length;
    return _Box(
      title: HomeStrings.saved,
      child: NavTile(
        icon: Icons.bookmark_outline,
        title: context.tr(HomeStrings.savedN.fill({'n': n})),
        onTap: () => context.go(AppRoutes.bookmarks),
        trailing: n > 0 ? TextButton(onPressed: () => context.push(AppRoutes.practiceSession(mode: 'bookmarks')), child: Text(context.tr(HomeStrings.practise))) : null,
      ),
    );
  }
}

class _AchievementsWidget extends ConsumerWidget {
  const _AchievementsWidget();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lvl = levelFor(ref.watch(learningProgressProvider).totalXp);
    return _Box(
      title: HomeStrings.achievements,
      child: TapCard(
        onTap: () => context.push(AppRoutes.achievements),
        child: Row(
          children: [
            ProgressRing(value: lvl.intoLevel / lvl.forNext, size: 52, center: Text(context.n(lvl.level), style: context.text.titleMedium)),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(context.tr(HomeStrings.level.fill({'n': lvl.level})), style: context.text.titleMedium),
                  Text(context.tr(HomeStrings.xpToNext.fill({'n': lvl.forNext - lvl.intoLevel})), style: context.text.bodySmall),
                ],
              ),
            ),
            Icon(Icons.emoji_events, color: context.palette.xp),
          ],
        ),
      ),
    );
  }
}

class _CalendarWidget extends ConsumerWidget {
  const _CalendarWidget();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plan = ref.watch(plannerProvider);
    final today = _day(DateTime.now());
    return _Box(
      title: HomeStrings.calendar,
      action: HomeStrings.planner,
      onAction: () => context.push(AppRoutes.planner),
      child: Row(
        children: [
          for (var d = 0; d < 7; d++)
            Builder(
              builder: (context) {
                final day = today.add(Duration(days: d));
                final tasks = plan.on(day);
                final isToday = d == 0;
                return Expanded(
                  child: InkWell(
                    onTap: () => context.push(AppRoutes.planner),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
                      decoration: BoxDecoration(color: isToday ? context.colors.primaryContainer : context.colors.surfaceContainerHighest, borderRadius: BorderRadius.circular(8)),
                      child: Column(
                        children: [
                          Text(context.n(day.day), style: context.text.titleSmall),
                          const SizedBox(height: 2),
                          Text(tasks.isEmpty ? '·' : context.n(tasks.length), style: context.text.labelSmall),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}

class _NotificationsWidget extends ConsumerWidget {
  const _NotificationsWidget();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unread = [for (final n in ref.watch(visibleNotificationsProvider)) if (!n.read && !n.archived) n];
    return _Box(
      title: HomeStrings.notifications,
      action: HomeStrings.notifications,
      onAction: () => context.push(AppRoutes.notifications),
      child: unread.isEmpty
          ? Text(context.tr(HomeStrings.allCaught), style: context.text.bodySmall)
          : Column(
              children: [
                for (final n in unread.take(3))
                  ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(n.category.icon),
                    title: Text(context.tr(n.title)),
                    subtitle: Text(relativeTime(n.createdAt, context.lang)),
                    onTap: () => context.push(AppRoutes.notifications),
                  ),
              ],
            ),
    );
  }
}

class _NoticesWidget extends ConsumerWidget {
  const _NoticesWidget();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notices = [for (final n in ref.watch(visibleNotificationsProvider)) if (n.category == NotificationCategory.announcement && !n.archived) n];
    return _Box(
      title: HomeStrings.notices,
      child: notices.isEmpty
          ? Text(context.tr(HomeStrings.noNotices), style: context.text.bodySmall)
          : Column(
              children: [
                for (final n in notices.take(2))
                  Card(
                    margin: const EdgeInsets.only(bottom: AppSpacing.xs),
                    child: ListTile(
                      leading: const Icon(Icons.verified_outlined),
                      title: Text(context.tr(n.title)),
                      subtitle: Text(context.tr(n.body), maxLines: 2, overflow: TextOverflow.ellipsis),
                      onTap: () => context.push(AppRoutes.notifications),
                    ),
                  ),
              ],
            ),
    );
  }
}

class _ResourcesWidget extends ConsumerWidget {
  const _ResourcesWidget();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notes = [...ref.watch(notesProvider)]..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    final reading = [for (final r in ref.watch(libraryProvider).values) if (r.updatedAt != null) r]..sort((a, b) => b.updatedAt!.compareTo(a.updatedAt!));
    final items = <(IconData, String, DateTime, String)>[
      for (final n in notes.take(3)) (Icons.sticky_note_2_outlined, n.title, n.updatedAt, AppRoutes.note(n.id)),
      for (final r in reading.take(3))
        if (bookById(r.bookId) case final b?) (Icons.menu_book_outlined, context.tr(b.title), r.updatedAt!, AppRoutes.book(b.id)),
    ]..sort((a, b) => b.$3.compareTo(a.$3));
    return _Box(
      title: HomeStrings.resources,
      child: items.isEmpty
          ? Text(context.tr(HomeStrings.noResources), style: context.text.bodySmall)
          : Column(
              children: [
                for (final (icon, title, at, route) in items.take(4))
                  ListTile(dense: true, contentPadding: EdgeInsets.zero, leading: Icon(icon), title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis), subtitle: Text(relativeTime(at, context.lang)), onTap: () => context.push(route)),
              ],
            ),
    );
  }
}

class _SubscriptionWidget extends ConsumerWidget {
  const _SubscriptionWidget();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final acc = ref.watch(accountProvider);
    final plan = planOf(acc.plan);
    final free = acc.plan == PlanCode.free;
    return _Box(
      title: HomeStrings.subscription,
      child: Card(
        margin: EdgeInsets.zero,
        child: ListTile(
          leading: Icon(Icons.workspace_premium_outlined, color: free ? null : context.palette.xp),
          title: Text(context.tr(plan.name)),
          subtitle: acc.renewsAt == null ? null : Text(context.tr(HomeStrings.renews.fill({'d': shortDate(acc.renewsAt!, context.lang)}))),
          trailing: FilledButton.tonal(onPressed: () => context.push(AppRoutes.subscription), child: Text(context.tr(free ? HomeStrings.upgrade : HomeStrings.manage))),
        ),
      ),
    );
  }
}

class _QuickWidget extends StatelessWidget {
  const _QuickWidget();

  @override
  Widget build(BuildContext context) => _Box(
    title: HomeStrings.quick,
    child: GridView.count(
      crossAxisCount: 4,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: AppSpacing.sm,
      crossAxisSpacing: AppSpacing.sm,
      childAspectRatio: 0.9,
      children: [
        for (final (icon, label, go) in [
          (Icons.co_present_outlined, HomeStrings.avatar, () => context.push(AppRoutes.avatarTutor)),
          (Icons.smart_toy_outlined, HomeStrings.tutor, () => context.go(AppRoutes.tutorTab)),
          (Icons.photo_camera_outlined, HomeStrings.photo, () => context.push(AppRoutes.photoSolver)),
          (Icons.quiz_outlined, HomeStrings.modelTest, () => context.go(AppRoutes.examCenter)),
        ])
          TapCard(
            onTap: go,
            padding: const EdgeInsets.all(AppSpacing.xs),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: context.colors.primary),
                const SizedBox(height: 4),
                Text(context.tr(label), textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis, style: context.text.labelSmall),
              ],
            ),
          ),
      ],
    ),
  );
}
