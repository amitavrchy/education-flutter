import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../core/l10n/common_strings.dart';
import '../../../../core/l10n/tr.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../mock/seed/curriculum_seed.dart';
import '../../../../shared/widgets/badges.dart';
import '../../../../shared/widgets/rich_content.dart';
import '../../../curriculum/data/curriculum_repository.dart';
import '../../../curriculum/domain/curriculum_models.dart';
import '../../domain/question.dart';
import '../../question_strings.dart';

/// Title of the synthetic sample textbook a citation points to (`book-<subjectId>`).
Tr sampleBookTitle(WidgetRef ref, String bookId) {
  final subjectId = bookId.replaceFirst('book-', '');
  final subject = ref.read(curriculumRepositoryProvider).cachedSubjects.where((s) => s.id == subjectId).firstOrNull;
  final name = subject?.name ?? const Tr('পাঠ্যবই', 'Textbook');
  return Tr('${name.bn} (নমুনা পাঠ্যবই)', '${name.en} (sample textbook)');
}

/// Type, difficulty, marks, source and authenticity labels.
class QuestionMetaRow extends StatelessWidget {
  const QuestionMetaRow({super.key, required this.question, this.showSource = true});

  final Question question;
  final bool showSource;

  @override
  Widget build(BuildContext context) {
    final q = question;
    final board = q.boardId == null ? null : educationBoards.where((b) => b.id == q.boardId).firstOrNull;
    return Wrap(
      spacing: AppSpacing.xs,
      runSpacing: AppSpacing.xs,
      children: [
        Pill(context.tr(q.type.label), icon: q.type.icon, tone: Tone.primary),
        Pill(
          context.tr(q.difficulty.label),
          tone: switch (q.difficulty) {
            Difficulty.easy => Tone.success,
            Difficulty.medium => Tone.info,
            Difficulty.hard => Tone.danger,
          },
        ),
        Pill('${context.n(q.marks)} ${context.tr(S.marks)}'),
        if (showSource && q.source == QuestionSource.board && board != null)
          Pill(
            '${context.tr(QStrings.boardStyle)} · ${context.tr(board.name)} ${q.year == null ? '' : context.n(q.year!)}',
            tone: Tone.warning,
            icon: Icons.history_edu_outlined,
          )
        else if (showSource)
          Pill(context.tr(q.source.label)),
        if (q.synthetic) const DemoBadge(label: S.syntheticSample),
        Pill(
          context.tr(q.verified ? QStrings.verified : QStrings.unverified),
          tone: q.verified ? Tone.success : Tone.neutral,
          icon: q.verified ? Icons.verified_outlined : Icons.hourglass_empty,
        ),
      ],
    );
  }
}

/// Question prompt: stimulus, stem, CQ parts, options (read-only) and matching table.
class QuestionPrompt extends StatelessWidget {
  const QuestionPrompt({super.key, required this.question, this.showOptions = true});

  final Question question;
  final bool showOptions;

  @override
  Widget build(BuildContext context) {
    final q = question;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (q.stimulus != null) ...[
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: context.colors.surfaceContainerHigh,
              borderRadius: AppRadius.field,
              border: BorderDirectional(start: BorderSide(color: context.colors.primary, width: 3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(context.tr(QStrings.stimulus), style: context.text.labelMedium?.copyWith(color: context.colors.primary)),
                const SizedBox(height: AppSpacing.xs),
                RichContent(context.tr(q.stimulus!)),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
        ],
        RichContent(context.tr(q.stem), baseStyle: context.text.titleMedium?.copyWith(fontWeight: FontWeight.w500)),
        if (q.parts.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.sm),
          for (final p in q.parts)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${p.label}) ', style: context.text.titleSmall),
                  Expanded(child: InlineRich(context.tr(p.prompt), style: context.text.bodyLarge!)),
                  Text(' ${context.n(p.marks)}', style: context.text.labelMedium?.copyWith(color: context.colors.onSurfaceVariant)),
                ],
              ),
            ),
        ],
        if (showOptions && q.options.isNotEmpty && q.type != QuestionType.trueFalse) ...[
          const SizedBox(height: AppSpacing.sm),
          for (var i = 0; i < q.options.length; i++)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxs),
              child: Row(
                children: [
                  Text('${optionLabel(context, i)}. ', style: context.text.titleSmall),
                  Expanded(child: InlineRich(context.tr(q.options[i]), style: context.text.bodyLarge!)),
                ],
              ),
            ),
        ],
        if (q.pairs.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(context.tr(QStrings.matchHint), style: context.text.labelMedium),
          const SizedBox(height: AppSpacing.xs),
          MatchingTable(pairs: q.pairs, revealed: false),
        ],
      ],
    );
  }
}

/// ক/খ/গ/ঘ in Bangla, A/B/C/D in English.
String optionLabel(BuildContext context, int i) => context.isBangla ? const ['ক', 'খ', 'গ', 'ঘ', 'ঙ'][i] : String.fromCharCode(65 + i);

/// Matching question table. Before reveal the right column is shown in a fixed shuffled order.
class MatchingTable extends StatelessWidget {
  const MatchingTable({super.key, required this.pairs, required this.revealed});

  final List<(Tr, Tr)> pairs;
  final bool revealed;

  @override
  Widget build(BuildContext context) {
    final rights = [for (final p in pairs) p.$2];
    final shown = revealed ? rights : [...rights.skip(1), rights.first];
    return Table(
      border: TableBorder.all(color: context.colors.outlineVariant, borderRadius: AppRadius.chip),
      children: [
        for (var i = 0; i < pairs.length; i++)
          TableRow(
            children: [
              Padding(padding: const EdgeInsets.all(AppSpacing.sm), child: Text('${context.n(i + 1)}. ${context.tr(pairs[i].$1)}')),
              Padding(
                padding: const EdgeInsets.all(AppSpacing.sm),
                child: Text(
                  '${revealed ? '→ ' : '${optionLabel(context, i)}. '}${context.tr(shown[i])}',
                  style: revealed ? TextStyle(color: context.palette.success, fontWeight: FontWeight.w600) : null,
                ),
              ),
            ],
          ),
      ],
    );
  }
}

/// Full answer: model answer, steps, alternative method, rubric, explanation, citation.
class AnswerPanel extends ConsumerWidget {
  const AnswerPanel({super.key, required this.question});

  final Question question;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final q = question;
    Widget heading(Tr t, IconData icon) => Padding(
      padding: const EdgeInsets.only(top: AppSpacing.md, bottom: AppSpacing.xs),
      child: Row(
        children: [
          Icon(icon, size: 18, color: context.colors.primary),
          const SizedBox(width: AppSpacing.xs),
          Text(context.tr(t), style: context.text.titleSmall?.copyWith(color: context.colors.primary)),
        ],
      ),
    );
    return Container(
      key: Key('answer.${q.id}'),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(color: context.palette.successContainer.withValues(alpha: 0.45), borderRadius: AppRadius.field),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(context.tr(QStrings.answer), style: context.text.titleSmall?.copyWith(color: context.palette.success)),
          const SizedBox(height: AppSpacing.xs),
          if (q.parts.isNotEmpty)
            for (final p in q.parts)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${p.label}) ${context.tr(p.level.label)} · ${context.n(p.marks)} ${context.tr(S.marks)}', style: context.text.labelMedium),
                    RichContent(context.tr(p.answer)),
                  ],
                ),
              )
          else
            RichContent(context.tr(q.answer)),
          if (q.pairs.isNotEmpty) ...[const SizedBox(height: AppSpacing.sm), MatchingTable(pairs: q.pairs, revealed: true)],
          if (q.steps.isNotEmpty) ...[
            heading(QStrings.steps, Icons.format_list_numbered),
            for (var i = 0; i < q.steps.length; i++)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxs),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(radius: 11, child: Text(context.n(i + 1), style: context.text.labelSmall)),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(child: InlineRich(context.tr(q.steps[i]), style: context.text.bodyMedium!)),
                  ],
                ),
              ),
          ],
          if (q.altMethod != null) ...[heading(QStrings.altMethod, Icons.alt_route), RichContent(context.tr(q.altMethod!))],
          if (q.explanation != null) ...[heading(QStrings.explanation, Icons.lightbulb_outline), RichContent(context.tr(q.explanation!))],
          if (q.rubric.isNotEmpty) ...[
            heading(QStrings.rubric, Icons.checklist),
            for (final r in q.rubric)
              Row(
                children: [
                  const Icon(Icons.check, size: 16),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(child: Text(context.tr(r))),
                ],
              ),
          ],
          if (q.citation != null) ...[
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Icon(Icons.menu_book_outlined, size: 16, color: context.colors.onSurfaceVariant),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Text(
                    context.tr(QStrings.citation.fill({'book': context.tr(sampleBookTitle(ref, q.citation!.bookId)), 'page': q.citation!.page})),
                    style: context.text.bodySmall?.copyWith(color: context.colors.onSurfaceVariant),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// Compact list row for a question.
class QuestionListTile extends StatelessWidget {
  const QuestionListTile({super.key, required this.question, required this.onTap, this.trailing, this.status});

  final Question question;
  final VoidCallback onTap;
  final Widget? trailing;

  /// Latest practice result: true correct, false wrong, null unattempted.
  final bool? status;

  @override
  Widget build(BuildContext context) {
    final q = question;
    return Card(
      child: InkWell(
        key: Key('q.${q.id}'),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                status == null ? q.type.icon : (status! ? Icons.check_circle : Icons.cancel),
                color: status == null ? context.colors.primary : (status! ? context.palette.success : context.palette.danger),
                size: 22,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    InlineRich(context.tr(q.stem), style: context.text.bodyLarge!, maxLines: 3),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      '${context.tr(q.type.label)} · ${context.tr(q.difficulty.label)} · ${context.n(q.marks)} ${context.tr(S.marks)}',
                      style: context.text.bodySmall?.copyWith(color: context.colors.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              ?trailing,
            ],
          ),
        ),
      ),
    );
  }
}
