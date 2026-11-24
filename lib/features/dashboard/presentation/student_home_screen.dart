import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../app/router/app_routes.dart';
import '../../../core/l10n/tr.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/time_format.dart';
import '../../../mock/seed/curriculum_seed.dart';
import '../../../shared/widgets/app_page_scaffold.dart';
import '../../../shared/widgets/progress.dart';
import '../../../shared/widgets/section_header.dart';
import '../../../shared/widgets/stat_card.dart';
import '../../book_avatar/data/book_catalog.dart';
import '../../exams/application/exam_controller.dart';
import '../../library/library_controller.dart';
import '../../planner/application/planner_controller.dart';
import '../../planner/domain/study_task.dart';
import '../../profile/application/student_profile_controller.dart';
import '../../progress/application/learning_progress_controller.dart';
import 'widgets/greeting_header.dart';

abstract final class HomeStrings {
  static const title = Tr('ড্যাশবোর্ড', 'Dashboard');
  static const subtitle = Tr('আজ কী শিখতে চাও?', 'What do you want to learn today?');
  static const week = Tr('এই সপ্তাহ', 'This week');
  static const minutes = Tr('পড়ার সময় (মিনিট)', 'Study time (min)');
  static const practiced = Tr('অনুশীলিত প্রশ্ন', 'Questions practised');
  static const avgScore = Tr('গড় নম্বর', 'Average score');
  static const streak = Tr('টানা পড়ার দিন', 'Day streak');
  static const today = Tr('আজকের পরিকল্পনা', "Today's plan");
  static const noTasks = Tr('আজ কোনো কাজ নেই — প্ল্যানার থেকে যোগ করো।', 'Nothing planned today — add tasks in the planner.');
  static const planner = Tr('প্ল্যানার', 'Planner');
  static const continueReading = Tr('পড়া চালিয়ে যাও', 'Continue reading');
  static const upcoming = Tr('আসন্ন পরীক্ষা', 'Upcoming exams');
  static const exams = Tr('সব পরীক্ষা', 'All exams');
  static const weak = Tr('দুর্বল টপিক সতর্কতা', 'Weak topic alert');
  static const practise = Tr('অনুশীলন করো', 'Practise');
  static const quick = Tr('দ্রুত শুরু করো', 'Quick start');
  static const avatar = Tr('বইয়ের শিক্ষককে প্রশ্ন করো (অ্যাভাটার)', "Ask a book's teacher (avatar)");
  static const tutor = Tr('AI টিউটরকে প্রশ্ন করো', 'Ask the AI tutor');
  static const photo = Tr('ছবি তুলে সমাধান', 'Solve from a photo');
  static const modelTest = Tr('মডেল টেস্ট দাও', 'Take a model test');
  static const page = Tr('পৃষ্ঠা {n}', 'Page {n}');
}

/// Student home on live data: week stats, today's plan, reading, exams and weak topics.
class StudentHomeScreen extends ConsumerWidget {
  const StudentHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = ref.watch(learningProgressProvider);
    final exams = ref.watch(examProvider);
    final plan = ref.watch(plannerProvider);
    final reading = ref.watch(libraryProvider);
    final level = ref.watch(studentProfileProvider.select((s) => s.level));
    final today = plan.on(DateTime.now());
    final finished = exams.finished;
    final avg = finished.isEmpty
        ? null
        : finished.map((a) => a.result!.totalMarks == 0 ? 0.0 : a.result!.score / a.result!.totalMarks).reduce((a, b) => a + b) / finished.length;
    final lastRead = [for (final r in reading.values) if (r.lastPage != null && r.updatedAt != null) r]..sort((a, b) => b.updatedAt!.compareTo(a.updatedAt!));
    final weak = [
      for (final s in seedSubjects.where((s) => s.level == level))
        for (final c in s.chapters)
          if (c.topics.any((t) => p.topic(t.id).attempts > 0)) (s, c, p.chapterMastery(c)),
    ]..sort((a, b) => a.$3.compareTo(b.$3));
    final text = Theme.of(context).textTheme;

    return AppPageScaffold(
      title: context.tr(HomeStrings.title),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          GreetingHeader(subtitle: context.tr(HomeStrings.subtitle)),
          SectionHeader(title: context.tr(HomeStrings.week)),
          StatGrid(
            cards: [
              StatCard(label: context.tr(HomeStrings.minutes), value: context.n(p.recentMinutes().fold<int>(0, (a, b) => a + b)), icon: Icons.timer_outlined, onTap: () => context.push(AppRoutes.analytics)),
              StatCard(label: context.tr(HomeStrings.practiced), value: context.n(p.practicedQuestions), icon: Icons.quiz_outlined, onTap: () => context.push(AppRoutes.analytics)),
              StatCard(label: context.tr(HomeStrings.avgScore), value: avg == null ? '—' : context.pct(avg * 100), icon: Icons.grade_outlined, onTap: () => context.go(AppRoutes.examResults)),
              StatCard(label: context.tr(HomeStrings.streak), value: context.n(p.streak), icon: Icons.local_fire_department_outlined, onTap: () => context.push(AppRoutes.achievements)),
            ],
          ),
          SectionHeader(title: context.tr(HomeStrings.today), actionLabel: context.tr(HomeStrings.planner), onAction: () => context.push(AppRoutes.planner)),
          if (today.isEmpty)
            Text(context.tr(HomeStrings.noTasks), style: text.bodySmall)
          else
            for (final t in today.take(3))
              Card(
                margin: const EdgeInsets.only(bottom: AppSpacing.xs),
                child: ListTile(
                  dense: true,
                  leading: Icon(t.status == TaskStatus.done ? Icons.check_circle : Icons.radio_button_unchecked, color: t.status == TaskStatus.done ? Colors.green : null),
                  title: Text(context.tr(t.title)),
                  subtitle: Text('${context.n(t.startMinute ~/ 60)}:${(t.startMinute % 60).toString().padLeft(2, '0')} · ${context.n(t.minutes)} min'),
                  onTap: () => context.push(AppRoutes.planner),
                ),
              ),
          if (lastRead.isNotEmpty)
            if (bookById(lastRead.first.bookId) case final b?) ...[
              SectionHeader(title: context.tr(HomeStrings.continueReading)),
              Card(
                margin: EdgeInsets.zero,
                child: ListTile(
                  leading: Icon(b.icon, color: b.color),
                  title: Text(context.tr(b.title)),
                  subtitle: Text('${context.tr(HomeStrings.page.fill({'n': lastRead.first.lastPage!}))} · ${relativeTime(lastRead.first.updatedAt!, context.lang)}'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push(AppRoutes.bookReader(b.id, page: lastRead.first.lastPage)),
                ),
              ),
            ],
          if (exams.open.isNotEmpty) ...[
            SectionHeader(title: context.tr(HomeStrings.upcoming), actionLabel: context.tr(HomeStrings.exams), onAction: () => context.go(AppRoutes.examCenter)),
            for (final e in exams.open.take(2))
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
          if (weak.isNotEmpty) ...[
            SectionHeader(title: context.tr(HomeStrings.weak)),
            Card(
              margin: EdgeInsets.zero,
              child: ListTile(
                leading: ProgressRing(value: weak.first.$3, size: 40),
                title: Text(context.tr(weak.first.$2.title)),
                subtitle: Text(context.tr(weak.first.$1.name)),
                trailing: TextButton(
                  onPressed: () => context.push(AppRoutes.practiceSession(subjectId: weak.first.$1.id, chapterId: weak.first.$2.id)),
                  child: Text(context.tr(HomeStrings.practise)),
                ),
              ),
            ),
          ],
          SectionHeader(title: context.tr(HomeStrings.quick)),
          _QuickAction(icon: Icons.co_present_outlined, title: context.tr(HomeStrings.avatar), onTap: () => context.push(AppRoutes.avatarTutor)),
          _QuickAction(icon: Icons.smart_toy_outlined, title: context.tr(HomeStrings.tutor), onTap: () => context.go(AppRoutes.tutorTab)),
          _QuickAction(icon: Icons.photo_camera_outlined, title: context.tr(HomeStrings.photo), onTap: () => context.push(AppRoutes.photoSolver)),
          _QuickAction(icon: Icons.quiz_outlined, title: context.tr(HomeStrings.modelTest), onTap: () => context.go(AppRoutes.examCenter)),
        ],
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({required this.icon, required this.title, required this.onTap});

  final IconData icon;
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: ListTile(leading: Icon(icon), title: Text(title), trailing: const Icon(Icons.chevron_right), onTap: onTap),
    );
  }
}
