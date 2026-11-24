import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/router/app_routes.dart';
import '../../core/l10n/tr.dart';
import '../../core/mock/mock_simulator.dart';
import '../../core/network/api_exception.dart';
import '../../core/storage/local_store.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/time_format.dart';
import '../../mock/seed/curriculum_seed.dart';
import '../../shared/widgets/app_page_scaffold.dart';
import '../../shared/widgets/badges.dart';
import '../../shared/widgets/empty_state.dart';
import '../../shared/widgets/feedback.dart';
import '../../shared/widgets/progress.dart';
import '../../shared/widgets/section_header.dart';
import '../../shared/widgets/stat_card.dart';
import '../account/account_controller.dart';
import '../dashboard/presentation/widgets/greeting_header.dart';
import '../exams/application/exam_controller.dart';
import '../profile/application/student_profile_controller.dart';
import '../progress/application/learning_progress_controller.dart';

abstract final class PStr {
  static const home = Tr('ড্যাশবোর্ড', 'Dashboard');
  static const sub = Tr('সন্তানের পড়াশোনার খবর', "Your child's learning");
  static const child = Tr('রাফি আহমেদ (ডেমো সন্তান)', 'Rafi Ahmed (demo child)');
  static const week = Tr('এই সপ্তাহ', 'This week');
  static const minutes = Tr('পড়ার সময় (মিনিট)', 'Study time (min)');
  static const streak = Tr('টানা দিন', 'Day streak');
  static const avg = Tr('গড় নম্বর', 'Average score');
  static const practiced = Tr('অনুশীলিত প্রশ্ন', 'Questions practised');
  static const hidden = Tr('সন্তান এটি শেয়ার করেনি', 'Your child has not shared this');
  static const avatarUsage = Tr('অ্যাভাটার শিক্ষকের ব্যবহার', 'Avatar teacher usage');
  static const children = Tr('আমার সন্তান', 'My children');
  static const link = Tr('সন্তান যুক্ত করো', 'Link a child');
  static const phone = Tr('সন্তানের মোবাইল নম্বর', "Child's mobile number");
  static const code = Tr('সন্তানের ফোনে পাঠানো কোড (ডেমো: 123456)', 'Code sent to the child (demo: 123456)');
  static const sendCode = Tr('কোড পাঠাও', 'Send code');
  static const verify = Tr('যাচাই করো', 'Verify');
  static const linked = Tr('সন্তান যুক্ত হয়েছে', 'Child linked');
  static const wrongCode = Tr('কোড সঠিক নয়', 'Wrong code');
  static const linkNote = Tr('যুক্ত হওয়ার পরও কী দেখবেন তা সন্তান নিজে ঠিক করে। AI কথোপকথন দেখা যায় না।', 'Your child decides what you see, even after linking. AI conversations are not shown.');
  static const progress = Tr('অগ্রগতি ও ফলাফল', 'Progress & results');
  static const mastery = Tr('বিষয়ভিত্তিক দক্ষতা', 'Subject mastery');
  static const results = Tr('ফলাফল', 'Results');
  static const noResults = Tr('এখনো কোনো পরীক্ষার ফল নেই', 'No exam results yet');
  static const reports = Tr('রিপোর্ট', 'Reports');
  static const weekly = Tr('সাপ্তাহিক রিপোর্ট', 'Weekly report');
  static const download = Tr('PDF ডাউনলোড (সিমুলেটেড)', 'Download PDF (simulated)');
  static const downloaded = Tr('রিপোর্ট তৈরি হয়েছে (ডেমো)', 'Report generated (demo)');
  static const summary = Tr('এই সপ্তাহে {m} মিনিট পড়েছে, {q}টি প্রশ্ন অনুশীলন করেছে, টানা {s} দিন। সবচেয়ে দুর্বল: {w}।', 'This week: {m} min studied, {q} questions practised, {s}-day streak. Weakest: {w}.');
}

/// Child's data as the guardian may see it (respects the student's sharing choices).
class _Shared {
  const _Shared(this.progress, this.scores);

  final bool progress;
  final bool scores;
}

_Shared _shared(WidgetRef ref) {
  final p = ref.watch(accountProvider).privacy;
  return _Shared(p['progress'] ?? true, p['scores'] ?? true);
}

class ParentHomeScreen extends ConsumerWidget {
  const ParentHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = ref.watch(learningProgressProvider);
    final finished = ref.watch(examProvider).finished;
    final s = _shared(ref);
    final avg = finished.isEmpty ? null : finished.map((a) => a.result!.totalMarks == 0 ? 0.0 : a.result!.score / a.result!.totalMarks).reduce((a, b) => a + b) / finished.length;
    final hidden = context.tr(PStr.hidden);
    return AppPageScaffold(
      title: context.tr(PStr.home),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          GreetingHeader(subtitle: context.tr(PStr.sub)),
          const SizedBox(height: AppSpacing.sm),
          Card(margin: EdgeInsets.zero, child: ListTile(leading: const CircleAvatar(child: Icon(Icons.child_care)), title: Text(context.tr(PStr.child)))),
          SectionHeader(title: context.tr(PStr.week)),
          StatGrid(
            cards: [
              StatCard(label: context.tr(PStr.minutes), value: s.progress ? context.n(p.recentMinutes().fold<int>(0, (a, b) => a + b)) : '—', icon: Icons.timer_outlined, caption: s.progress ? null : hidden),
              StatCard(label: context.tr(PStr.streak), value: s.progress ? context.n(p.streak) : '—', icon: Icons.local_fire_department_outlined),
              StatCard(label: context.tr(PStr.practiced), value: s.progress ? context.n(p.practicedQuestions) : '—', icon: Icons.quiz_outlined),
              StatCard(label: context.tr(PStr.avg), value: s.scores && avg != null ? context.pct(avg * 100) : '—', icon: Icons.grade_outlined, caption: s.scores ? null : hidden),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Card(
            margin: EdgeInsets.zero,
            child: ListTile(leading: const Icon(Icons.co_present_outlined), title: Text(context.tr(PStr.avatarUsage)), trailing: const Icon(Icons.chevron_right), onTap: () => context.push(AppRoutes.avatarActivity)),
          ),
        ],
      ),
    );
  }
}

class ParentChildrenScreen extends ConsumerStatefulWidget {
  const ParentChildrenScreen({super.key});

  @override
  ConsumerState<ParentChildrenScreen> createState() => _ParentChildrenScreenState();
}

class _ParentChildrenScreenState extends ConsumerState<ParentChildrenScreen> {
  final _phone = TextEditingController();
  final _code = TextEditingController();
  bool _codeSent = false;

  List<String> _children() => ((ref.read(localStoreProvider).get('guardian', 'children')?['items'] as List?) ?? const ['রাফি আহমেদ']).cast<String>();

  @override
  void dispose() {
    _phone.dispose();
    _code.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final kids = _children();
    return AppPageScaffold(
      title: context.tr(PStr.children),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final k in kids) Card(margin: const EdgeInsets.only(bottom: AppSpacing.sm), child: ListTile(leading: const CircleAvatar(child: Icon(Icons.child_care)), title: Text(k))),
          SectionHeader(title: context.tr(PStr.link)),
          TextField(key: const Key('link.phone'), controller: _phone, keyboardType: TextInputType.phone, decoration: InputDecoration(labelText: context.tr(PStr.phone))),
          if (_codeSent) TextField(key: const Key('link.code'), controller: _code, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: context.tr(PStr.code))),
          const SizedBox(height: AppSpacing.sm),
          FilledButton(
            key: const Key('link.go'),
            onPressed: () async {
              if (!_codeSent) {
                if (_phone.text.trim().length < 11) return;
                try {
                  await ref.read(mockSimulatorProvider).run(() {});
                  setState(() => _codeSent = true);
                } on ApiException catch (e) {
                  if (context.mounted) context.showErrorSnack(e);
                }
                return;
              }
              if (_code.text.trim() != '123456') return context.showSnack(PStr.wrongCode);
              await ref.read(localStoreProvider).put('guardian', 'children', {'items': [...kids, 'শিক্ষার্থী ${_phone.text.trim().substring(_phone.text.trim().length - 3)} (ডেমো)']});
              _phone.clear();
              _code.clear();
              setState(() => _codeSent = false);
              if (context.mounted) context.showSnack(PStr.linked);
            },
            child: Text(context.tr(_codeSent ? PStr.verify : PStr.sendCode)),
          ),
          const SizedBox(height: AppSpacing.sm),
          InfoBanner(message: context.tr(PStr.linkNote), icon: Icons.lock_outline),
        ],
      ),
    );
  }
}

class ParentProgressScreen extends ConsumerWidget {
  const ParentProgressScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = ref.watch(learningProgressProvider);
    final s = _shared(ref);
    final level = ref.watch(studentProfileProvider.select((x) => x.level));
    return AppPageScaffold(
      title: context.tr(PStr.progress),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SectionHeader(title: context.tr(PStr.mastery)),
          if (!s.progress)
            InfoBanner(message: context.tr(PStr.hidden), icon: Icons.visibility_off_outlined)
          else
            for (final subj in seedSubjects.where((x) => x.level == level))
              Padding(padding: const EdgeInsets.only(bottom: AppSpacing.sm), child: LabeledProgress(label: context.tr(subj.name), value: p.subjectMastery(subj))),
          const ParentResultsList(),
        ],
      ),
    );
  }
}

class ParentResultsList extends ConsumerWidget {
  const ParentResultsList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final finished = ref.watch(examProvider).finished;
    final s = _shared(ref);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(title: context.tr(PStr.results)),
        if (!s.scores)
          InfoBanner(message: context.tr(PStr.hidden), icon: Icons.visibility_off_outlined)
        else if (finished.isEmpty)
          EmptyState(title: context.tr(PStr.noResults), compact: true, icon: Icons.emoji_events_outlined)
        else
          for (final a in finished)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.assignment_turned_in_outlined),
              title: Text(context.tr(a.title)),
              subtitle: Text(relativeTime(a.submittedAt ?? a.startedAt, context.lang)),
              trailing: Pill('${context.n(a.result!.score.round())}/${context.n(a.result!.totalMarks)}'),
            ),
      ],
    );
  }
}

class ParentResultsScreen extends StatelessWidget {
  const ParentResultsScreen({super.key});

  @override
  Widget build(BuildContext context) => AppPageScaffold(title: context.tr(PStr.results), body: const ParentResultsList());
}

class ParentReportsScreen extends ConsumerWidget {
  const ParentReportsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = ref.watch(learningProgressProvider);
    final level = ref.watch(studentProfileProvider.select((x) => x.level));
    final subjects = [for (final x in seedSubjects) if (x.level == level) x]..sort((a, b) => p.subjectMastery(a).compareTo(p.subjectMastery(b)));
    final s = _shared(ref);
    return AppPageScaffold(
      title: context.tr(PStr.reports),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SectionHeader(title: context.tr(PStr.weekly)),
          if (!s.progress)
            InfoBanner(message: context.tr(PStr.hidden), icon: Icons.visibility_off_outlined)
          else
            Card(
              margin: EdgeInsets.zero,
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Text(context.tr(PStr.summary.fill({
                  'm': p.recentMinutes().fold<int>(0, (a, b) => a + b),
                  'q': p.practicedQuestions,
                  's': p.streak,
                  'w': subjects.isEmpty ? '—' : context.tr(subjects.first.name),
                }))),
              ),
            ),
          const SizedBox(height: AppSpacing.md),
          OutlinedButton.icon(onPressed: () => context.showSnack(PStr.downloaded), icon: const Icon(Icons.picture_as_pdf_outlined), label: Text(context.tr(PStr.download))),
        ],
      ),
    );
  }
}
