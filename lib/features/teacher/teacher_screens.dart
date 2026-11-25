import 'package:fl_chart/fl_chart.dart';
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
import '../../shared/widgets/cards.dart';
import '../../shared/widgets/empty_state.dart';
import '../../shared/widgets/feedback.dart';
import '../../shared/widgets/progress.dart';
import '../../shared/widgets/rich_content.dart';
import '../../shared/widgets/section_header.dart';
import '../../shared/widgets/stat_card.dart';
import '../book_avatar/application/avatar_controller.dart';
import '../book_avatar/domain/avatar_models.dart';
import '../dashboard/presentation/widgets/greeting_header.dart';
import '../exams/application/exam_controller.dart';
import '../exams/domain/exam.dart';
import '../question_bank/data/question_repository.dart';
import '../question_bank/domain/question.dart';
import 'review_data.dart';
import 'teacher_data.dart';
import 'teacher_workflow_screens.dart';

abstract final class TStr {
  static const home = Tr('ড্যাশবোর্ড', 'Dashboard');
  static const sub = Tr('আজকের ক্লাস ও মূল্যায়ন', "Today's classes and reviews");
  static const glance = Tr('সংক্ষেপে', 'At a glance');
  static const classes = Tr('ক্লাস', 'Classes');
  static const students = Tr('শিক্ষার্থী', 'Students');
  static const toReview = Tr('মূল্যায়ন বাকি', 'To review');
  static const active = Tr('চলমান অ্যাসাইনমেন্ট', 'Active assignments');
  static const avatarReports = Tr('অ্যাভাটার রিপোর্ট খোলা', 'Open avatar reports');
  static const average = Tr('গড় দক্ষতা', 'Average mastery');
  static const needHelp = Tr('সাহায্য দরকার', 'Needs help');
  static const evaluation = Tr('উত্তর মূল্যায়ন', 'Answer evaluation');
  static const pending = Tr('বাকি', 'Pending');
  static const done = Tr('সম্পন্ন', 'Reviewed');
  static const ai = Tr('AI আনুমানিক: {m}/{t}', 'AI estimate: {m}/{t}');
  static const finalMark = Tr('চূড়ান্ত নম্বর', 'Final marks');
  static const feedback = Tr('শিক্ষকের মতামত', 'Teacher feedback');
  static const save = Tr('সংরক্ষণ', 'Save');
  static const reviewed = Tr('মূল্যায়ন সংরক্ষিত — শিক্ষার্থী নোটিফিকেশন পাবে', 'Review saved — the student is notified');
  static const assignments = Tr('অ্যাসাইনমেন্ট', 'Assignments');
  static const newAssignment = Tr('নতুন অ্যাসাইনমেন্ট', 'New assignment');
  static const title = Tr('শিরোনাম', 'Title');
  static const due = Tr('শেষ তারিখ: {d}', 'Due: {d}');
  static const submitted = Tr('{n} জন জমা দিয়েছে', '{n} submitted');
  static const dueIn = Tr('কত দিনের মধ্যে', 'Due in (days)');
  static const create = Tr('তৈরি করো', 'Create');
  static const exams = Tr('পরীক্ষা ও কুইজ', 'Exams & quizzes');
  static const publish = Tr('কুইজ প্রকাশ করো', 'Publish quiz');
  static const published = Tr('কুইজ প্রকাশিত — শিক্ষার্থীরা "শিক্ষকের দেওয়া" তালিকায় পাবে', 'Quiz published — students see it under teacher-assigned');
  static const subject = Tr('বিষয়', 'Subject');
  static const count = Tr('প্রশ্ন সংখ্যা', 'Questions');
  static const minutes = Tr('সময় (মিনিট)', 'Time (min)');
  static const generator = Tr('AI প্রশ্ন জেনারেটর', 'AI question generator');
  static const generate = Tr('প্রশ্ন তৈরি করো', 'Generate');
  static const generatedNote = Tr('সিমুলেটেড AI: প্রশ্নগুলো প্রশ্নব্যাংক থেকে বাছাই করা খসড়া — প্রকাশের আগে রিভিউ করুন।', 'Simulated AI: drafts picked from the question bank — review before publishing.');
  static const sendReview = Tr('রিভিউতে পাঠাও', 'Send to review');
  static const sentReview = Tr('রিভিউ কিউতে পাঠানো হয়েছে', 'Sent to the review queue');
  static const materials = Tr('শিক্ষা উপকরণ', 'Materials');
  static const share = Tr('উপকরণ শেয়ার', 'Share material');
  static const analytics = Tr('অ্যানালিটিক্স', 'Analytics');
  static const classAverage = Tr('ক্লাসভিত্তিক গড় দক্ষতা', 'Average mastery by class');
  static const distribution = Tr('শিক্ষার্থী বণ্টন', 'Student distribution');
  static const evalSub = Tr('AI আনুমানিক নম্বর যাচাই করে শিক্ষক নম্বর ও চূড়ান্ত নম্বর দিন — তিনটি আলাদা থাকে।', 'Check the AI estimate, then give teacher marks and final marks — all three stay distinct.');
  static const all = Tr('সব', 'All');
  static const pages = Tr('পৃষ্ঠা', 'pages');
  static const scriptPages = Tr('উত্তরপত্র: {n} পৃষ্ঠা (ডেমো ছবি)', 'Answer script: {n} pages (demo images)');
  static const teacherMarks = Tr('শিক্ষকের নম্বর', 'Teacher marks');
  static const useRubric = Tr('রুব্রিক', 'Rubric');
  static const publishOfficial = Tr('চূড়ান্ত অফিসিয়াল নম্বর হিসেবে প্রকাশ', 'Publish as final official marks');
  static const officialNote = Tr('প্রকাশের পর আর বদলানো যাবে না', 'Cannot be changed after publishing');
  static const finalize = Tr('চূড়ান্ত করুন', 'Finalize');
  static const finalized = Tr('চূড়ান্ত নম্বর প্রকাশিত', 'Final marks published');
  static const gradedN = Tr('{n} জনকে নম্বর দেওয়া হয়েছে', '{n} graded');
  static const reviewQueue = Tr('কনটেন্ট পর্যালোচনা বাকি', 'Content to review');
  static const workflow = Tr('কনটেন্ট ও মূল্যায়ন', 'Content & evaluation');
  static const reviewerStats = Tr('পর্যালোচক বিশ্লেষণ', 'Reviewer analytics');
  static const decisions = Tr('সিদ্ধান্ত', 'Decisions');
  static const approvalRate = Tr('অনুমোদনের হার', 'Approval rate');
  static const avgTurnaround = Tr('গড় সময় (ঘণ্টা)', 'Avg. turnaround (h)');
  static const buckets = Tr('<৫০% · ৫০–৭০% · >৭০%', '<50% · 50–70% · >70%');
}

class TeacherHomeScreen extends ConsumerWidget {
  const TeacherHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(teacherProvider);
    final reports = ref.watch(avatarControllerProvider).reports.where((r) => r.status == ReportStatus.open).length;
    final students = teacherClasses.fold<int>(0, (n, c) => n + c.students.length);
    final queue = ref.watch(reviewProvider).queue.length;
    return AppPageScaffold(
      title: context.tr(TStr.home),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          GreetingHeader(subtitle: context.tr(TStr.sub)),
          SectionHeader(title: context.tr(TStr.glance)),
          StatGrid(
            cards: [
              StatCard(label: context.tr(TStr.classes), value: context.n(teacherClasses.length), icon: Icons.class_outlined),
              StatCard(label: context.tr(TStr.students), value: context.n(students), icon: Icons.groups_outlined),
              StatCard(label: context.tr(TStr.toReview), value: context.n(t.pending.length), icon: Icons.fact_check_outlined, onTap: () => context.go('/teacher/evaluation')),
              StatCard(label: context.tr(TStr.active), value: context.n(t.assignments.where((a) => a.dueAt.isAfter(DateTime.now())).length), icon: Icons.assignment_outlined),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Card(
            margin: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: ListTile(
              key: const Key('home.review'),
              leading: const Icon(Icons.manage_search),
              title: Text(context.tr(TStr.reviewQueue)),
              trailing: Pill(context.n(queue), tone: queue > 0 ? Tone.info : Tone.neutral),
              onTap: () => context.push(AppRoutes.teacherReview),
            ),
          ),
          Card(
            margin: EdgeInsets.zero,
            child: ListTile(
              leading: const Icon(Icons.co_present_outlined),
              title: Text(context.tr(TStr.avatarReports)),
              trailing: Pill(context.n(reports), tone: reports > 0 ? Tone.warning : Tone.neutral),
              onTap: () => context.push(AppRoutes.teacherAvatars),
            ),
          ),
          SectionHeader(title: context.tr(TStr.workflow)),
          GridView.count(
            crossAxisCount: 3,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: AppSpacing.sm,
            crossAxisSpacing: AppSpacing.sm,
            childAspectRatio: 1.1,
            children: [
              for (final (icon, label, route) in [
                (Icons.manage_search, const Tr('পর্যালোচনা', 'Review'), AppRoutes.teacherReview),
                (Icons.edit_note, const Tr('প্রশ্ন', 'Questions'), AppRoutes.teacherQuestions),
                (Icons.rule, const Tr('রুব্রিক', 'Rubrics'), AppRoutes.teacherRubrics),
                (Icons.assignment_outlined, TStr.assignments, AppRoutes.teacherAssignments),
                (Icons.groups_outlined, TStr.students, AppRoutes.teacherStudents),
                (Icons.history, const Tr('ইতিহাস', 'History'), AppRoutes.teacherHistory),
              ])
                TapCard(
                  onTap: () => context.push(route),
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(icon, color: Theme.of(context).colorScheme.primary),
                      const SizedBox(height: AppSpacing.xs),
                      Text(context.tr(label), textAlign: TextAlign.center, style: Theme.of(context).textTheme.labelMedium),
                    ],
                  ),
                ),
            ],
          ),
          SectionHeader(title: context.tr(TStr.classes)),
          for (final c in teacherClasses) _ClassCard(c: c),
        ],
      ),
    );
  }
}

class _ClassCard extends StatelessWidget {
  const _ClassCard({required this.c});

  final TeacherClass c;

  @override
  Widget build(BuildContext context) => Card(
    margin: const EdgeInsets.only(bottom: AppSpacing.sm),
    child: ListTile(
      key: Key('class.${c.id}'),
      leading: ProgressRing(value: c.average / 100, size: 40),
      title: Text(c.name),
      subtitle: Text('${context.tr(TStr.students)}: ${context.n(c.students.length)} · ${context.tr(TStr.average)} ${context.pct(c.average)}'),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => ClassDetailScreen(c: c))),
    ),
  );
}

class TeacherClassesScreen extends StatelessWidget {
  const TeacherClassesScreen({super.key});

  @override
  Widget build(BuildContext context) => AppPageScaffold(title: context.tr(TStr.classes), body: Column(children: [for (final c in teacherClasses) _ClassCard(c: c)]));
}

class ClassDetailScreen extends StatelessWidget {
  const ClassDetailScreen({super.key, required this.c});

  final TeacherClass c;

  @override
  Widget build(BuildContext context) {
    final sorted = [...c.students]..sort((a, b) => c.masteryOf(a).compareTo(c.masteryOf(b)));
    return AppPageScaffold(
      title: c.name,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('${context.tr(TStr.average)}: ${context.pct(c.average)}', style: Theme.of(context).textTheme.titleMedium),
          SectionHeader(title: context.tr(TStr.students)),
          for (final s in sorted)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: CircleAvatar(child: Text(s.characters.first)),
              title: Text(s),
              subtitle: LinearProgressIndicator(value: c.masteryOf(s) / 100, minHeight: 4),
              trailing: c.masteryOf(s) < 55 ? Pill(context.tr(TStr.needHelp), tone: Tone.warning) : Text(context.pct(c.masteryOf(s))),
            ),
        ],
      ),
    );
  }
}

class TeacherEvaluationScreen extends ConsumerStatefulWidget {
  const TeacherEvaluationScreen({super.key});

  @override
  ConsumerState<TeacherEvaluationScreen> createState() => _TeacherEvaluationScreenState();
}

class _TeacherEvaluationScreenState extends ConsumerState<TeacherEvaluationScreen> {
  EvalStage? _stage;

  Future<void> _review(Submission s) async {
    final rubric = ref.read(reviewProvider).rubrics.where((r) => r.use == RubricUse.creative || r.use == RubricUse.handwriting).firstOrNull;
    final result = await showModalBottomSheet<_EvalResult>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _EvalSheet(s: s, rubric: rubric),
    );
    if (result == null) return;
    try {
      await ref.read(teacherProvider.notifier).review(s.id, result.marks, result.note, official: result.official, criterionMarks: result.criteria);
      if (mounted) context.showSnack(result.official ? TStr.finalized : TStr.reviewed);
    } on ApiException catch (e) {
      if (mounted) context.showErrorSnack(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = ref.watch(teacherProvider);
    final list = [for (final s in t.submissions) if (_stage == null || s.stage == _stage) s]..sort((a, b) => a.stage.index.compareTo(b.stage.index));
    return AppPageScaffold(
      title: context.tr(TStr.evaluation),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(context.tr(TStr.evalSub), style: Theme.of(context).textTheme.bodySmall),
          ChoiceChipBar<EvalStage?>(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
            options: [null, ...EvalStage.values],
            selected: _stage,
            labelOf: (x) => x == null ? '${context.tr(TStr.all)} (${context.n(t.submissions.length)})' : '${context.tr(x.label)} (${context.n(t.submissions.where((s) => s.stage == x).length)})',
            onSelected: (x) => setState(() => _stage = x),
          ),
          if (list.isEmpty) EmptyState(title: context.tr(TStr.pending), compact: true, icon: Icons.done_all),
          for (final s in list)
            Card(
              margin: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: ListTile(
                key: Key('sub.${s.id}'),
                leading: Icon(s.official ? Icons.verified : (s.reviewed ? Icons.check_circle_outline : Icons.description_outlined), color: s.reviewed ? Colors.green : null),
                title: Text(s.student),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${s.title} · ${context.n(s.pages)} ${context.tr(TStr.pages)}'),
                    const SizedBox(height: 2),
                    Wrap(
                      spacing: AppSpacing.xs,
                      children: [
                        Pill(context.tr(s.stage.label), tone: switch (s.stage) {
                          EvalStage.official => Tone.success,
                          EvalStage.teacherReviewed => Tone.info,
                          EvalStage.reviewRequested => Tone.warning,
                          EvalStage.aiEstimated => Tone.neutral,
                        }),
                        Pill(context.tr(TStr.ai.fill({'m': s.aiMarks, 't': s.total}))),
                        if (s.reviewed) Pill('${context.tr(TStr.finalMark)}: ${context.n(s.finalMarks!)}/${context.n(s.total)}', tone: Tone.primary),
                      ],
                    ),
                  ],
                ),
                isThreeLine: true,
                trailing: s.official ? const Icon(Icons.lock_outline) : const Icon(Icons.rate_review_outlined),
                onTap: s.official ? null : () => _review(s),
              ),
            ),
        ],
      ),
    );
  }
}

class _EvalResult {
  const _EvalResult(this.marks, this.note, this.official, this.criteria);

  final double marks;
  final String note;
  final bool official;
  final List<double> criteria;
}

/// AI estimate beside the teacher's rubric marks; optionally published as official.
class _EvalSheet extends StatefulWidget {
  const _EvalSheet({required this.s, this.rubric});

  final Submission s;
  final Rubric? rubric;

  @override
  State<_EvalSheet> createState() => _EvalSheetState();
}

class _EvalSheetState extends State<_EvalSheet> {
  late final _note = TextEditingController(text: widget.s.feedback ?? '');
  late double _marks = widget.s.finalMarks ?? widget.s.aiMarks;
  late bool _useRubric = widget.rubric != null;
  late final List<double> _criteria = widget.rubric == null
      ? []
      : [
          for (final (i, c) in widget.rubric!.criteria.indexed)
            i < widget.s.criterionMarks.length ? widget.s.criterionMarks[i] : (c.marks * widget.s.aiMarks / widget.s.total * 2).round() / 2,
        ];
  bool _official = false;

  double get _scaled {
    if (!_useRubric || widget.rubric == null) return _marks;
    final sum = _criteria.fold<double>(0, (a, b) => a + b);
    return ((sum / widget.rubric!.total) * widget.s.total * 2).round() / 2;
  }

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.s;
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, MediaQuery.viewInsetsOf(context).bottom + AppSpacing.lg),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('${s.student} · ${s.title}', style: text.titleMedium),
            const SizedBox(height: AppSpacing.xs),
            Row(
              children: [
                Expanded(child: _MarkBox(label: context.tr(EvalStage.aiEstimated.label), value: '${context.n(s.aiMarks)}/${context.n(s.total)}')),
                const SizedBox(width: AppSpacing.sm),
                Expanded(child: _MarkBox(label: context.tr(TStr.teacherMarks), value: '${context.n(_scaled)}/${context.n(s.total)}', highlight: true)),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Container(
              height: 90,
              alignment: Alignment.center,
              decoration: BoxDecoration(color: Theme.of(context).colorScheme.surfaceContainerHighest, borderRadius: BorderRadius.circular(8)),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.image_outlined),
                  const SizedBox(width: AppSpacing.xs),
                  Text(context.tr(TStr.scriptPages.fill({'n': s.pages}))),
                ],
              ),
            ),
            if (widget.rubric != null)
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text('${context.tr(TStr.useRubric)}: ${widget.rubric!.name}'),
                value: _useRubric,
                onChanged: (v) => setState(() => _useRubric = v),
              ),
            if (_useRubric && widget.rubric != null)
              for (final (i, c) in widget.rubric!.criteria.indexed)
                Row(
                  children: [
                    Expanded(child: Text('${c.criterion} (${context.n(c.marks)})', style: text.bodySmall)),
                    SizedBox(
                      width: 150,
                      child: Slider(
                        key: Key('eval.c$i'),
                        value: _criteria[i].clamp(0, c.marks),
                        max: c.marks,
                        divisions: (c.marks * 2).round(),
                        label: context.n(_criteria[i]),
                        onChanged: (v) => setState(() => _criteria[i] = v),
                      ),
                    ),
                    Text(context.n(_criteria[i])),
                  ],
                )
            else ...[
              Text('${context.tr(TStr.finalMark)}: ${context.n(_marks)}'),
              Slider(key: const Key('eval.marks'), value: _marks, max: s.total.toDouble(), divisions: s.total * 2, onChanged: (v) => setState(() => _marks = v)),
            ],
            TextField(key: const Key('eval.note'), controller: _note, maxLines: 3, decoration: InputDecoration(labelText: context.tr(TStr.feedback))),
            CheckboxListTile(
              key: const Key('eval.official'),
              contentPadding: EdgeInsets.zero,
              value: _official,
              onChanged: (v) => setState(() => _official = v ?? false),
              title: Text(context.tr(TStr.publishOfficial)),
              subtitle: Text(context.tr(TStr.officialNote)),
            ),
            const SizedBox(height: AppSpacing.sm),
            FilledButton(
              key: const Key('eval.save'),
              onPressed: () => Navigator.pop(context, _EvalResult(_scaled, _note.text.trim(), _official, _useRubric ? [..._criteria] : const [])),
              child: Text(context.tr(_official ? TStr.finalize : TStr.save)),
            ),
          ],
        ),
      ),
    );
  }
}

class _MarkBox extends StatelessWidget {
  const _MarkBox({required this.label, required this.value, this.highlight = false});

  final String label;
  final String value;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(color: highlight ? cs.primaryContainer : cs.surfaceContainerHighest, borderRadius: BorderRadius.circular(8)),
      child: Column(
        children: [
          Text(label, style: Theme.of(context).textTheme.labelSmall, textAlign: TextAlign.center),
          Text(value, style: Theme.of(context).textTheme.titleLarge),
        ],
      ),
    );
  }
}

class TeacherAssignmentsScreen extends ConsumerWidget {
  const TeacherAssignmentsScreen({super.key});

  Future<void> _create(BuildContext context, WidgetRef ref) async {
    final title = TextEditingController();
    var cls = teacherClasses.first;
    var days = 3.0;
    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Padding(
          padding: EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, MediaQuery.viewInsetsOf(context).bottom + AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(context.tr(TStr.newAssignment), style: Theme.of(context).textTheme.titleMedium),
              TextField(key: const Key('as.title'), controller: title, decoration: InputDecoration(labelText: context.tr(TStr.title))),
              DropdownButtonFormField<TeacherClass>(
                isExpanded: true,
                initialValue: cls,
                items: [for (final c in teacherClasses) DropdownMenuItem(value: c, child: Text(c.name))],
                onChanged: (v) => setState(() => cls = v ?? cls),
              ),
              Text('${context.tr(TStr.dueIn)}: ${context.n(days.round())}'),
              Slider(value: days, min: 1, max: 14, divisions: 13, onChanged: (v) => setState(() => days = v)),
              FilledButton(key: const Key('as.create'), onPressed: () => Navigator.pop(context, title.text.trim().isNotEmpty), child: Text(context.tr(TStr.create))),
            ],
          ),
        ),
      ),
    );
    if (ok == true) {
      final bank = ref.read(questionRepositoryProvider).cached;
      await ref.read(teacherProvider.notifier).addAssignment(Assignment(
        id: 'as-${DateTime.now().microsecondsSinceEpoch}',
        classId: cls.id,
        title: title.text.trim(),
        dueAt: DateTime.now().add(Duration(days: days.round())),
        questionIds: [for (final q in bank) if (q.subjectId == cls.subjectId) q.id].take(5).toList(),
      ));
    }
    title.dispose();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(teacherProvider);
    return AppPageScaffold(
      title: context.tr(TStr.assignments),
      floatingActionButton: FloatingActionButton.extended(key: const Key('as.new'), onPressed: () => _create(context, ref), icon: const Icon(Icons.add), label: Text(context.tr(TStr.newAssignment))),
      body: Column(
        children: [
          for (final a in t.assignments)
            Card(
              margin: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: ListTile(
                key: Key('assignment.${a.id}'),
                title: Text(a.title),
                subtitle: Text([
                  teacherClasses.firstWhere((c) => c.id == a.classId).name,
                  context.tr(TStr.due.fill({'d': shortDate(a.dueAt, context.lang)})),
                  context.tr(TStr.submitted.fill({'n': a.submitted})),
                  if (a.grades.isNotEmpty) context.tr(TStr.gradedN.fill({'n': a.grades.length})),
                ].join(' · ')),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => TeacherSubmissionsScreen(assignmentId: a.id))),
              ),
            ),
        ],
      ),
    );
  }
}

class TeacherExamsScreen extends ConsumerStatefulWidget {
  const TeacherExamsScreen({super.key});

  @override
  ConsumerState<TeacherExamsScreen> createState() => _TeacherExamsScreenState();
}

class _TeacherExamsScreenState extends ConsumerState<TeacherExamsScreen> {
  final _title = TextEditingController(text: 'শ্রেণি কুইজ — বল ও গতি');
  String _subject = 'ssc-phy';
  double _count = 5;
  double _minutes = 15;

  @override
  void dispose() {
    _title.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mine = [for (final t in ref.watch(examProvider).templates) if (t.type == ExamType.teacherAssigned) t];
    return AppPageScaffold(
      title: context.tr(TStr.exams),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(controller: _title, decoration: InputDecoration(labelText: context.tr(TStr.title))),
          DropdownButtonFormField<String>(
            isExpanded: true,
            initialValue: _subject,
            decoration: InputDecoration(labelText: context.tr(TStr.subject)),
            items: [for (final s in seedSubjects) DropdownMenuItem(value: s.id, child: Text('${context.tr(s.name)} (${s.level.code})'))],
            onChanged: (v) => setState(() => _subject = v ?? _subject),
          ),
          Text('${context.tr(TStr.count)}: ${context.n(_count.round())}'),
          Slider(value: _count, min: 3, max: 20, divisions: 17, onChanged: (v) => setState(() => _count = v)),
          Text('${context.tr(TStr.minutes)}: ${context.n(_minutes.round())}'),
          Slider(value: _minutes, min: 5, max: 60, divisions: 11, onChanged: (v) => setState(() => _minutes = v)),
          FilledButton.icon(
            key: const Key('exam.publish'),
            onPressed: () async {
              final now = DateTime.now();
              await ref.read(examProvider.notifier).publishTemplate(ExamTemplate(
                id: 'tpl-t-${now.microsecondsSinceEpoch}',
                type: ExamType.teacherAssigned,
                title: Tr.same(_title.text.trim()),
                assignedBy: const Tr('নাসরিন সুলতানা (শিক্ষক)', 'Nasrin Sultana (teacher)'),
                config: ExamConfig(subjectId: _subject, questionCount: _count.round(), timeLimitMinutes: _minutes.round()),
                dueAt: now.add(const Duration(days: 3)),
                createdAt: now,
              ));
              if (context.mounted) context.showSnack(TStr.published);
            },
            icon: const Icon(Icons.publish),
            label: Text(context.tr(TStr.publish)),
          ),
          SectionHeader(title: context.tr(TStr.exams)),
          for (final t in mine) ListTile(contentPadding: EdgeInsets.zero, leading: const Icon(Icons.quiz_outlined), title: Text(context.tr(t.title)), subtitle: Text(t.dueAt == null ? '' : context.tr(TStr.due.fill({'d': shortDate(t.dueAt!, context.lang)})))),
        ],
      ),
    );
  }
}

class QuestionGeneratorScreen extends ConsumerStatefulWidget {
  const QuestionGeneratorScreen({super.key});

  @override
  ConsumerState<QuestionGeneratorScreen> createState() => _QuestionGeneratorScreenState();
}

class _QuestionGeneratorScreenState extends ConsumerState<QuestionGeneratorScreen> {
  String _subject = 'ssc-phy';
  List<Question> _out = const [];
  final Set<String> _sent = {};

  @override
  Widget build(BuildContext context) {
    return AppPageScaffold(
      title: context.tr(TStr.generator),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InfoBanner(message: context.tr(TStr.generatedNote)),
          const SizedBox(height: AppSpacing.sm),
          DropdownButtonFormField<String>(
            isExpanded: true,
            initialValue: _subject,
            decoration: InputDecoration(labelText: context.tr(TStr.subject)),
            items: [for (final s in seedSubjects) DropdownMenuItem(value: s.id, child: Text('${context.tr(s.name)} (${s.level.code})'))],
            onChanged: (v) => setState(() => _subject = v ?? _subject),
          ),
          const SizedBox(height: AppSpacing.sm),
          FilledButton.icon(
            key: const Key('gen.go'),
            onPressed: () {
              final bank = ref.read(questionRepositoryProvider).cached;
              setState(() => _out = [for (final q in bank) if (q.subjectId == _subject) q].take(5).toList());
            },
            icon: const Icon(Icons.auto_awesome),
            label: Text(context.tr(TStr.generate)),
          ),
          for (final q in _out)
            Card(
              margin: const EdgeInsets.only(top: AppSpacing.sm),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${context.tr(q.type.label)} · ${context.tr(q.difficulty.label)}', style: Theme.of(context).textTheme.labelMedium),
                    RichContent(context.tr(q.stem)),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: _sent.contains(q.id)
                            ? null
                            : () {
                                setState(() => _sent.add(q.id));
                                context.showSnack(TStr.sentReview);
                              },
                        child: Text(context.tr(_sent.contains(q.id) ? TStr.sentReview : TStr.sendReview)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class TeacherMaterialsScreen extends ConsumerWidget {
  const TeacherMaterialsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(teacherProvider);
    return AppPageScaffold(
      title: context.tr(TStr.materials),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final ctrl = TextEditingController();
          final ok = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: Text(context.tr(TStr.share)),
              content: TextField(controller: ctrl, decoration: InputDecoration(labelText: context.tr(TStr.title))),
              actions: [FilledButton(onPressed: () => Navigator.pop(context, ctrl.text.trim().isNotEmpty), child: Text(context.tr(TStr.create)))],
            ),
          );
          if (ok == true) {
            await ref.read(teacherProvider.notifier).addMaterial(TeachingMaterial('m-${DateTime.now().microsecondsSinceEpoch}', teacherClasses.first.id, ctrl.text.trim(), 'link', DateTime.now()));
          }
          ctrl.dispose();
        },
        icon: const Icon(Icons.add),
        label: Text(context.tr(TStr.share)),
      ),
      body: Column(
        children: [
          for (final m in t.materials)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(switch (m.kind) { 'pdf' => Icons.picture_as_pdf_outlined, 'video' => Icons.ondemand_video, _ => Icons.link }),
              title: Text(m.title),
              subtitle: Text('${teacherClasses.firstWhere((c) => c.id == m.classId).name} · ${relativeTime(m.at, context.lang)}'),
            ),
        ],
      ),
    );
  }
}

class TeacherAnalyticsScreen extends ConsumerWidget {
  const TeacherAnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(reviewProvider).items;
    // Reviewer decisions: in-review → approved / changes requested.
    final decisions = [
      for (final i in items)
        for (final (k, e) in i.history.indexed)
          if (e.from == ContentStatus.inReview && (e.to == ContentStatus.approved || e.to == ContentStatus.changesRequested)) (i, k, e),
    ];
    final approved = decisions.where((d) => d.$3.to == ContentStatus.approved).length;
    final hours = [
      for (final (i, k, e) in decisions)
        if (k > 0) e.at.difference(i.history[k - 1].at).inMinutes / 60,
    ];
    final all = [for (final c in teacherClasses) for (final s in c.students) c.masteryOf(s)];
    final low = all.where((m) => m < 50).length, mid = all.where((m) => m >= 50 && m <= 70).length, high = all.where((m) => m > 70).length;
    return AppPageScaffold(
      title: context.tr(TStr.analytics),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SectionHeader(title: context.tr(TStr.classAverage)),
          SizedBox(
            height: 180,
            child: BarChart(
              BarChartData(
                maxY: 100,
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
                titlesData: const FlTitlesData(topTitles: AxisTitles(), rightTitles: AxisTitles(), bottomTitles: AxisTitles()),
                barGroups: [
                  for (final (i, c) in teacherClasses.indexed)
                    BarChartGroupData(x: i, barRods: [BarChartRodData(toY: c.average.toDouble(), width: 28, color: Theme.of(context).colorScheme.primary, borderRadius: BorderRadius.circular(4))]),
                ],
              ),
            ),
          ),
          for (final (i, c) in teacherClasses.indexed) Text('${context.n(i + 1)}. ${c.name} — ${context.pct(c.average)}'),
          SectionHeader(title: context.tr(TStr.distribution)),
          Text(context.tr(TStr.buckets)),
          const SizedBox(height: AppSpacing.xs),
          Row(
            children: [
              for (final (n, color) in [(low, Colors.red), (mid, Colors.orange), (high, Colors.green)])
                Expanded(flex: n == 0 ? 1 : n, child: Container(height: 24, color: color.withValues(alpha: 0.7), alignment: Alignment.center, child: Text(context.n(n), style: const TextStyle(color: Colors.white)))),
            ],
          ),
          SectionHeader(title: context.tr(TStr.reviewerStats)),
          StatGrid(
            cards: [
              StatCard(label: context.tr(TStr.decisions), value: context.n(decisions.length), icon: Icons.gavel_outlined),
              StatCard(label: context.tr(TStr.approvalRate), value: decisions.isEmpty ? '—' : context.pct(100 * approved / decisions.length), icon: Icons.verified_outlined),
              StatCard(label: context.tr(TStr.avgTurnaround), value: hours.isEmpty ? '—' : context.n((hours.reduce((a, b) => a + b) / hours.length).round()), icon: Icons.timer_outlined),
              StatCard(label: context.tr(TStr.reviewQueue), value: context.n(ref.watch(reviewProvider).queue.length), icon: Icons.inbox_outlined, onTap: () => context.push(AppRoutes.teacherReview)),
            ],
          ),
        ],
      ),
    );
  }
}
