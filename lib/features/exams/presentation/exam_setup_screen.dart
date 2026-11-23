import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/l10n/common_strings.dart';
import '../../../core/l10n/tr.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/app_page_scaffold.dart';
import '../../../shared/widgets/badges.dart';
import '../../curriculum/application/curriculum_providers.dart';
import '../../curriculum/domain/curriculum_models.dart';
import '../../question_bank/data/question_repository.dart';
import '../../question_bank/domain/question.dart';
import '../domain/exam.dart';
import '../exam_strings.dart';
import 'exam_center_screen.dart';

/// Custom exam builder with live validation against the question pool.
class ExamSetupScreen extends ConsumerStatefulWidget {
  const ExamSetupScreen({super.key});

  @override
  ConsumerState<ExamSetupScreen> createState() => _ExamSetupScreenState();
}

class _ExamSetupScreenState extends ConsumerState<ExamSetupScreen> {
  ExamConfig _c = const ExamConfig(questionCount: 5, timeLimitMinutes: 10);

  @override
  Widget build(BuildContext context) {
    final subjects = ref.watch(mySubjectsProvider).value ?? const <Subject>[];
    final subject = subjects.where((s) => s.id == _c.subjectId).firstOrNull;
    final pool = ref.watch(questionRepositoryProvider).cached.where(_c.accepts).toList();
    final enough = pool.length >= _c.questionCount;
    final totalMarks = (List.of(pool)..sort((a, b) => a.marks.compareTo(b.marks))).take(_c.questionCount).fold<int>(0, (s, q) => s + q.marks);

    Widget title(Tr t) => Padding(
      padding: const EdgeInsets.only(top: AppSpacing.lg, bottom: AppSpacing.sm),
      child: Text(context.tr(t), style: context.text.titleSmall),
    );

    return AppPageScaffold(
      title: context.tr(ExamStrings.setup),
      showShortcuts: false,
      bottomBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                enough ? context.tr(ExamStrings.totalMarks.fill({'n': totalMarks})) : context.tr(ExamStrings.notEnough),
                style: context.text.labelMedium?.copyWith(color: enough ? null : context.colors.error),
              ),
              const SizedBox(height: AppSpacing.sm),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  key: const Key('setup.start'),
                  onPressed: enough ? () => startExam(context, ref, config: _c, type: _typeFor()) : null,
                  icon: const Icon(Icons.play_arrow),
                  label: Text(context.tr(ExamStrings.startExam)),
                ),
              ),
            ],
          ),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          title(ExamStrings.subject),
          DropdownButtonFormField<String?>(
            key: const Key('setup.subject'),
            initialValue: _c.subjectId,
            decoration: InputDecoration(hintText: context.tr(ExamStrings.chooseSubject)),
            items: [
              DropdownMenuItem<String?>(child: Text(context.tr(const Tr('সব বিষয়', 'All subjects')))),
              for (final s in subjects) DropdownMenuItem(value: s.id, child: Text(context.tr(s.name))),
            ],
            onChanged: (v) => setState(() => _c = _c.copyWith(subjectId: () => v, chapterIds: const [])),
          ),
          if (subject != null) ...[
            title(ExamStrings.chapters),
            Wrap(
              spacing: AppSpacing.xs,
              runSpacing: AppSpacing.xs,
              children: [
                for (final ch in subject.chapters)
                  FilterChip(
                    label: Text('${context.n(ch.number)}. ${context.tr(ch.title)}'),
                    selected: _c.chapterIds.contains(ch.id),
                    onSelected: (on) => setState(() {
                      final next = List.of(_c.chapterIds);
                      on ? next.add(ch.id) : next.remove(ch.id);
                      _c = _c.copyWith(chapterIds: next);
                    }),
                  ),
              ],
            ),
          ],
          title(ExamStrings.types),
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: [
              for (final t in const [QuestionType.mcq, QuestionType.trueFalse, QuestionType.fillBlank, QuestionType.short, QuestionType.numerical, QuestionType.creative, QuestionType.descriptive])
                FilterChip(
                  label: Text(context.tr(t.label)),
                  selected: _c.types.contains(t),
                  onSelected: (on) => setState(() {
                    final next = Set.of(_c.types);
                    on ? next.add(t) : next.remove(t);
                    _c = _c.copyWith(types: next);
                  }),
                ),
            ],
          ),
          title(S.difficulty),
          SegmentedButton<Difficulty?>(
            segments: [
              ButtonSegment(value: null, label: Text(context.tr(S.all))),
              for (final d in Difficulty.values) ButtonSegment(value: d, label: Text(context.tr(d.label))),
            ],
            selected: {_c.difficulty},
            onSelectionChanged: (v) => setState(() => _c = _c.copyWith(difficulty: () => v.first)),
          ),
          title(ExamStrings.count),
          Row(
            children: [
              Expanded(
                child: Slider(
                  key: const Key('setup.count'),
                  value: _c.questionCount.toDouble(),
                  min: 3,
                  max: 30,
                  divisions: 27,
                  label: context.n(_c.questionCount),
                  onChanged: (v) => setState(() => _c = _c.copyWith(questionCount: v.round())),
                ),
              ),
              Text(context.n(_c.questionCount), style: context.text.titleMedium),
            ],
          ),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: Pill(context.tr(ExamStrings.availableCount.fill({'n': pool.length})), tone: enough ? Tone.success : Tone.danger),
          ),
          title(ExamStrings.timeLimit),
          Wrap(
            spacing: AppSpacing.xs,
            children: [
              for (final m in const [5, 10, 15, 20, 30, 45, 60])
                ChoiceChip(
                  label: Text(context.tr(ExamStrings.minutes.fill({'n': m}))),
                  selected: _c.timeLimitMinutes == m,
                  onSelected: (_) => setState(() => _c = _c.copyWith(timeLimitMinutes: m)),
                ),
            ],
          ),
          title(ExamStrings.mode),
          SegmentedButton<ExamMode>(
            segments: [for (final m in ExamMode.values) ButtonSegment(value: m, label: Text(context.tr(m.label)))],
            selected: {_c.mode},
            onSelectionChanged: (v) => setState(() => _c = _c.copyWith(
              mode: v.first,
              reviewPolicy: v.first == ExamMode.practice ? ReviewPolicy.immediate : ReviewPolicy.afterSubmit,
            )),
          ),
          const SizedBox(height: AppSpacing.sm),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(context.tr(ExamStrings.negative)),
            value: _c.negativeMarking,
            onChanged: (v) => setState(() => _c = _c.copyWith(negativeMarking: v)),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(context.tr(ExamStrings.randomize)),
            value: _c.randomize,
            onChanged: (v) => setState(() => _c = _c.copyWith(randomize: v)),
          ),
          title(ExamStrings.reviewPolicy),
          RadioGroup<ReviewPolicy>(
            groupValue: _c.reviewPolicy,
            onChanged: (v) => setState(() => _c = _c.copyWith(reviewPolicy: v)),
            child: Column(
              children: [
                for (final p in ReviewPolicy.values)
                  RadioListTile<ReviewPolicy>(contentPadding: EdgeInsets.zero, value: p, title: Text(context.tr(p.label))),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }

  ExamType _typeFor() {
    if (_c.subjectId == null) return ExamType.custom;
    if (_c.chapterIds.length == 1) return ExamType.chapter;
    return ExamType.subject;
  }
}
