import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../app/router/app_routes.dart';
import '../../../core/l10n/common_strings.dart';
import '../../../core/l10n/tr.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/time_format.dart';
import '../../../shared/widgets/app_page_scaffold.dart';
import '../../../shared/widgets/badges.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/progress.dart';
import '../../../shared/widgets/section_header.dart';
import '../../../shared/widgets/stat_card.dart';
import '../../curriculum/data/curriculum_repository.dart';
import '../../curriculum/domain/curriculum_models.dart';
import '../../question_bank/data/question_repository.dart';
import '../../question_bank/domain/question.dart';
import '../../question_bank/presentation/widgets/question_widgets.dart';
import '../application/exam_controller.dart';
import '../application/exam_scoring.dart';
import '../domain/exam.dart';
import '../exam_strings.dart';
import 'exam_center_screen.dart';

/// Score, counts, time, accuracy, grade, topic/difficulty analysis, question review,
/// weak areas with lesson links, teacher feedback, retake and a printable layout.
class ExamResultScreen extends ConsumerWidget {
  const ExamResultScreen({super.key, required this.attemptId});

  final String attemptId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final a = ref.watch(examProvider.select((s) => s.attempt(attemptId)));
    if (a == null || a.result == null) {
      return Scaffold(appBar: AppBar(), body: EmptyState(icon: Icons.search_off, title: context.tr(S.notFound)));
    }
    final r = a.result!;
    final questions = {for (final q in ref.watch(questionRepositoryProvider).cached) q.id: q};
    final repo = ref.watch(curriculumRepositoryProvider);
    final g = gradeFor(r.percent);
    final weak = weakTopics(r, questions);
    final byDifficulty = breakdown(r, questions, (q) => q.difficulty);
    final byTopic = breakdown(r, questions, (q) => q.topicId);
    final showAnswers = a.config.reviewPolicy != ReviewPolicy.never;
    final template = ref.watch(examProvider).templates.where((t) => t.id == a.templateId).firstOrNull;

    return AppPageScaffold(
      title: context.tr(ExamStrings.result),
      showShortcuts: false,
      actions: [
        IconButton(
          tooltip: context.tr(ExamStrings.printResult),
          icon: const Icon(Icons.print_outlined),
          onPressed: () => Navigator.of(context).push(MaterialPageRoute<void>(
            fullscreenDialog: true,
            builder: (_) => _PrintableResult(attempt: a, questions: questions),
          )),
        ),
      ],
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(context.tr(a.title), style: context.text.titleLarge),
          Text(
            '${context.tr(a.type.label)} · ${shortDate(a.submittedAt ?? a.startedAt, context.lang)}'
            '${a.status == AttemptStatus.expired ? ' · ${context.tr(ExamStrings.expired)}' : ''}',
            style: context.text.bodySmall?.copyWith(color: context.colors.onSurfaceVariant),
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              ProgressRing(
                value: r.percent,
                size: 110,
                stroke: 10,
                color: masteryColor(context, r.percent),
                center: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(g.grade, style: context.text.headlineMedium?.copyWith(fontWeight: FontWeight.w700)),
                    Text(context.pct(r.percent * 100), style: context.text.labelMedium),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(context.tr(ExamStrings.score), style: context.text.labelLarge),
                    Text(
                      '${context.n(_fmt(r.score))} / ${context.n(r.totalMarks)}',
                      key: const Key('result.score'),
                      style: context.text.headlineSmall,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text('${context.tr(ExamStrings.grade)}: ${g.grade} (GPA ${context.n(g.gpa.toStringAsFixed(1))})'),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          StatGrid(cards: [
            StatCard(label: context.tr(ExamStrings.correct), value: context.n(r.count(Outcome.correct)), icon: Icons.check_circle_outline, color: context.palette.success),
            StatCard(label: context.tr(ExamStrings.incorrect), value: context.n(r.count(Outcome.incorrect)), icon: Icons.cancel_outlined, color: context.palette.danger),
            StatCard(label: context.tr(ExamStrings.unanswered), value: context.n(r.count(Outcome.unanswered)), icon: Icons.remove_circle_outline),
            StatCard(label: context.tr(ExamStrings.timeSpent), value: clockLabel(Duration(seconds: r.timeSpentSeconds), context.lang), icon: Icons.timer_outlined),
            StatCard(label: context.tr(ExamStrings.accuracy), value: r.accuracy == null ? '—' : context.pct(r.accuracy! * 100), icon: Icons.track_changes),
            if (r.hasEstimates)
              StatCard(label: context.tr(ExamStrings.estimated), value: context.n(r.count(Outcome.estimated)), icon: Icons.auto_awesome, color: context.palette.xp),
          ]),
          if (r.hasEstimates) ...[
            const SizedBox(height: AppSpacing.md),
            InfoBanner(message: context.tr(ExamStrings.estimateNote), tone: Tone.warning, icon: Icons.auto_awesome),
          ],
          if (r.teacherFeedback != null) ...[
            SectionHeader(title: context.tr(ExamStrings.teacherFeedback)),
            InfoBanner(
              title: template?.assignedBy == null ? null : context.tr(template!.assignedBy!),
              message: context.tr(r.teacherFeedback!),
              icon: Icons.person_outline,
            ),
          ],
          SectionHeader(title: context.tr(ExamStrings.weakAreas)),
          if (weak.isEmpty)
            InfoBanner(message: context.tr(ExamStrings.noWeak), tone: Tone.success)
          else
            for (final topicId in weak)
              if (repo.findTopic(topicId) case final t?)
                Card(
                  child: ListTile(
                    leading: Icon(Icons.trending_down, color: context.palette.danger),
                    title: Text(context.tr(t.topic.title)),
                    subtitle: Text(context.tr(t.subject.name)),
                    trailing: Wrap(
                      spacing: AppSpacing.xs,
                      children: [
                        TextButton(onPressed: () => context.push(AppRoutes.topic(topicId)), child: Text(context.tr(ExamStrings.reviseTopic))),
                        FilledButton.tonal(
                          onPressed: () => context.push(AppRoutes.practiceSession(chapterId: t.chapter.id, topicId: topicId, mode: 'quick')),
                          child: Text(context.tr(ExamStrings.practiceTopic)),
                        ),
                      ],
                    ),
                  ),
                ),
          SectionHeader(title: context.tr(ExamStrings.byDifficulty)),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                children: [
                  for (final d in Difficulty.values)
                    if (byDifficulty[d] case final v?)
                      LabeledProgress(
                        label: '${context.tr(d.label)} (${context.n(v.count)})',
                        value: v.max == 0 ? 0 : v.earned / v.max,
                        color: masteryColor(context, v.max == 0 ? 0 : v.earned / v.max),
                      ),
                ],
              ),
            ),
          ),
          SectionHeader(title: context.tr(ExamStrings.byTopic)),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                children: [
                  for (final e in byTopic.entries)
                    LabeledProgress(
                      dense: true,
                      label: context.tr(repo.findTopic(e.key)?.topic.title ?? Tr.same(e.key)),
                      value: e.value.max == 0 ? 0 : e.value.earned / e.value.max,
                      color: masteryColor(context, e.value.max == 0 ? 0 : e.value.earned / e.value.max),
                    ),
                ],
              ),
            ),
          ),
          SectionHeader(title: context.tr(ExamStrings.questionWise)),
          if (!showAnswers) InfoBanner(message: context.tr(ExamStrings.answersHidden)),
          for (var i = 0; i < r.scores.length; i++)
            if (questions[r.scores[i].questionId] case final q?)
              _QuestionReview(index: i, question: q, score: r.scores[i], answer: a.answerFor(q.id), showAnswer: showAnswers),
          const SizedBox(height: AppSpacing.lg),
          FilledButton.icon(
            key: const Key('result.retake'),
            onPressed: () => template != null
                ? startExam(context, ref, template: template)
                : startExam(context, ref, config: a.config, type: a.type),
            icon: const Icon(Icons.replay),
            label: Text(context.tr(ExamStrings.retake)),
          ),
          const SizedBox(height: AppSpacing.sm),
          OutlinedButton(onPressed: () => context.push(AppRoutes.examResults), child: Text(context.tr(ExamStrings.results))),
          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }
}

String _fmt(double v) => v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(2).replaceFirst(RegExp(r'0$'), '');

class _QuestionReview extends StatelessWidget {
  const _QuestionReview({required this.index, required this.question, required this.score, required this.answer, required this.showAnswer});

  final int index;
  final Question question;
  final QuestionScore score;
  final ExamAnswer answer;
  final bool showAnswer;

  @override
  Widget build(BuildContext context) {
    final (icon, color) = switch (score.outcome) {
      Outcome.correct => (Icons.check_circle, context.palette.success),
      Outcome.incorrect => (Icons.cancel, context.palette.danger),
      Outcome.unanswered => (Icons.remove_circle_outline, context.colors.outline),
      Outcome.estimated => (Icons.auto_awesome, context.palette.xp),
    };
    final yours = answer.choice != null && answer.choice! < question.options.length
        ? '${optionLabel(context, answer.choice!)}. ${context.tr(question.options[answer.choice!])}'
        : (answer.text?.trim().isNotEmpty ?? false)
            ? answer.text!.trim()
            : answer.imagePaths.isNotEmpty
                ? context.tr(ExamStrings.imagesAttached.fill({'n': answer.imagePaths.length}))
                : context.tr(ExamStrings.noAnswer);
    return Card(
      child: ExpansionTile(
        leading: Icon(icon, color: color),
        title: Text('${context.n(index + 1)}. ${context.tr(question.stem).replaceAll(RegExp(r'[\$\\{}]'), '')}', maxLines: 2, overflow: TextOverflow.ellipsis),
        subtitle: Text('${context.n(_fmt(score.marks))}/${context.n(score.maxMarks)} · ${context.tr(question.type.label)}'),
        childrenPadding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.lg),
        expandedCrossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          QuestionPrompt(question: question),
          const SizedBox(height: AppSpacing.sm),
          Text(context.tr(ExamStrings.yourAnswer.fill({'a': yours})), style: context.text.bodyMedium?.copyWith(color: color)),
          if (score.outcome == Outcome.estimated) ...[
            const SizedBox(height: AppSpacing.xs),
            const Align(alignment: AlignmentDirectional.centerStart, child: SimulatedBadge()),
          ],
          if (showAnswer) ...[const SizedBox(height: AppSpacing.sm), AnswerPanel(question: question)],
        ],
      ),
    );
  }
}

class _PrintableResult extends StatelessWidget {
  const _PrintableResult({required this.attempt, required this.questions});

  final ExamAttempt attempt;
  final Map<String, Question> questions;

  @override
  Widget build(BuildContext context) {
    final r = attempt.result!;
    return Theme(
      data: ThemeData(brightness: Brightness.light, colorSchemeSeed: Colors.grey, useMaterial3: true),
      child: Builder(
        builder: (context) => Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(title: Text(context.tr(ExamStrings.printResult))),
          body: ListView(
            padding: const EdgeInsets.all(AppSpacing.xl),
            children: [
              Text(context.tr(attempt.title), style: context.text.headlineSmall),
              Text(shortDate(attempt.submittedAt ?? attempt.startedAt, context.lang)),
              const Divider(height: AppSpacing.xl),
              KeyValue(context.tr(ExamStrings.score), '${context.n(_fmt(r.score))} / ${context.n(r.totalMarks)} (${gradeFor(r.percent).grade})'),
              KeyValue(context.tr(ExamStrings.correct), context.n(r.count(Outcome.correct))),
              KeyValue(context.tr(ExamStrings.incorrect), context.n(r.count(Outcome.incorrect))),
              KeyValue(context.tr(ExamStrings.unanswered), context.n(r.count(Outcome.unanswered))),
              KeyValue(context.tr(ExamStrings.timeSpent), clockLabel(Duration(seconds: r.timeSpentSeconds), context.lang)),
              const Divider(height: AppSpacing.xl),
              Table(
                border: TableBorder.all(color: Colors.black26),
                children: [
                  for (var i = 0; i < r.scores.length; i++)
                    TableRow(children: [
                      Padding(padding: const EdgeInsets.all(6), child: Text(context.n(i + 1))),
                      Padding(padding: const EdgeInsets.all(6), child: Text(context.tr(questions[r.scores[i].questionId]?.type.label ?? const Tr.same('')))),
                      Padding(padding: const EdgeInsets.all(6), child: Text('${context.n(_fmt(r.scores[i].marks))}/${context.n(r.scores[i].maxMarks)}')),
                    ]),
                ],
              ),
              if (r.hasEstimates) ...[const SizedBox(height: AppSpacing.md), Text(context.tr(ExamStrings.estimateNote), style: context.text.bodySmall)],
            ],
          ),
        ),
      ),
    );
  }
}

class KeyValue extends StatelessWidget {
  const KeyValue(this.label, this.value, {super.key});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 2),
    child: Row(children: [SizedBox(width: 140, child: Text(label)), Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w600)))]),
  );
}

/// History of finished exams with a score trend chart.
class ExamResultsScreen extends ConsumerWidget {
  const ExamResultsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final finished = ref.watch(examProvider).finished;
    if (finished.isEmpty) {
      return AppPageScaffold(
        title: context.tr(ExamStrings.results),
        scrollable: false,
        body: EmptyState(
          icon: Icons.leaderboard_outlined,
          title: context.tr(ExamStrings.noResults),
          message: context.tr(ExamStrings.noResultsHint),
          action: FilledButton(onPressed: () => context.push(AppRoutes.examCenter), child: Text(context.tr(ExamStrings.center))),
        ),
      );
    }
    final chronological = finished.reversed.toList();
    return AppPageScaffold(
      title: context.tr(ExamStrings.results),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SectionHeader(title: context.tr(ExamStrings.trend)),
          Card(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.sm, AppSpacing.lg, AppSpacing.lg, AppSpacing.sm),
              child: SizedBox(
                height: 180,
                child: Semantics(
                  label: context.tr(ExamStrings.trend),
                  value: chronological.map((a) => context.pct(a.result!.percent * 100)).join(', '),
                  child: LineChart(
                    LineChartData(
                      minY: 0,
                      maxY: 100,
                      gridData: FlGridData(
                        drawVerticalLine: false,
                        horizontalInterval: 25,
                        getDrawingHorizontalLine: (_) => FlLine(color: context.colors.outlineVariant, strokeWidth: 1),
                      ),
                      borderData: FlBorderData(show: false),
                      titlesData: FlTitlesData(
                        topTitles: const AxisTitles(),
                        rightTitles: const AxisTitles(),
                        bottomTitles: const AxisTitles(),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 34,
                            interval: 25,
                            getTitlesWidget: (v, _) => Text(context.n(v.round()), style: context.text.labelSmall),
                          ),
                        ),
                      ),
                      lineBarsData: [
                        LineChartBarData(
                          isCurved: true,
                          preventCurveOverShooting: true,
                          color: context.colors.primary,
                          barWidth: 3,
                          dotData: const FlDotData(),
                          belowBarData: BarAreaData(show: true, color: context.colors.primary.withValues(alpha: 0.08)),
                          spots: [
                            for (var i = 0; i < chronological.length; i++) FlSpot(i.toDouble(), chronological[i].result!.percent * 100),
                          ],
                        ),
                      ],
                    ),
                    duration: context.reduceMotion ? Duration.zero : const Duration(milliseconds: 250),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          for (final a in finished)
            Card(
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: masteryColor(context, a.result!.percent).withValues(alpha: 0.15),
                  child: Text(gradeFor(a.result!.percent).grade, style: TextStyle(color: masteryColor(context, a.result!.percent))),
                ),
                title: Text(context.tr(a.title)),
                subtitle: Text('${context.tr(a.type.label)} · ${relativeTime(a.submittedAt ?? a.startedAt, context.lang)}'),
                trailing: Text(context.pct(a.result!.percent * 100), style: context.text.titleMedium),
                onTap: () => context.push(AppRoutes.examResult(a.id)),
              ),
            ),
        ],
      ),
    );
  }
}
