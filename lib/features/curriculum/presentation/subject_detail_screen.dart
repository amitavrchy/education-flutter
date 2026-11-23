import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../app/router/app_routes.dart';
import '../../../core/l10n/common_strings.dart';
import '../../../core/l10n/tr.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/app_page_scaffold.dart';
import '../../../shared/widgets/async_value_view.dart';
import '../../../shared/widgets/badges.dart';
import '../../../shared/widgets/cards.dart';
import '../../../shared/widgets/progress.dart';
import '../../../shared/widgets/section_header.dart';
import '../../progress/application/learning_progress_controller.dart';
import '../application/curriculum_providers.dart';
import '../curriculum_strings.dart';
import '../domain/curriculum_models.dart';

class SubjectDetailScreen extends ConsumerWidget {
  const SubjectDetailScreen({super.key, required this.subjectId});

  final String subjectId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final value = ref.watch(subjectProvider(subjectId));
    return AppPageScaffold(
      title: value.whenOrNull(data: (s) => context.tr(s.name)) ?? context.tr(S.subject),
      body: AsyncValueView<Subject>(
        value: value,
        onRetry: () => ref.invalidate(subjectProvider(subjectId)),
        data: (s) => _SubjectBody(subject: s),
      ),
    );
  }
}

class _SubjectBody extends ConsumerStatefulWidget {
  const _SubjectBody({required this.subject});

  final Subject subject;

  @override
  ConsumerState<_SubjectBody> createState() => _SubjectBodyState();
}

class _SubjectBodyState extends ConsumerState<_SubjectBody> {
  int _paper = 1;

  @override
  Widget build(BuildContext context) {
    final s = widget.subject;
    final progress = ref.watch(learningProgressProvider);
    final chapters = s.chapters.where((c) => s.papers == 1 || c.paper == _paper).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    IconTile(icon: s.icon, color: s.color, size: 52),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(context.tr(s.name), style: context.text.titleLarge),
                          Wrap(
                            spacing: AppSpacing.xs,
                            runSpacing: AppSpacing.xs,
                            children: [
                              Pill('${context.tr(s.level.label)} · ${s.code}'),
                              if (s.compulsory) Pill(context.tr(CurriculumStrings.compulsory), tone: Tone.info),
                              if (s.optional) Pill(context.tr(CurriculumStrings.optional), tone: Tone.warning),
                            ],
                          ),
                        ],
                      ),
                    ),
                    ProgressRing(value: progress.subjectMastery(s), size: 60, color: s.color),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                Text(context.tr(s.description), style: context.text.bodyMedium),
                const SizedBox(height: AppSpacing.md),
                LabeledProgress(
                  label: context.tr(CurriculumStrings.completed),
                  value: progress.subjectCompletion(s),
                  color: s.color,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  [
                    context.tr(CurriculumStrings.chapterCount.fill({'n': s.chapters.length})),
                    context.tr(CurriculumStrings.topicCount.fill({'n': s.topicCount})),
                    context.tr(CurriculumStrings.estTime.fill({'n': (s.totalMinutes / 60).round()})),
                  ].join(' · '),
                  style: context.text.bodySmall?.copyWith(color: context.colors.onSurfaceVariant),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            Expanded(
              child: FilledButton.tonalIcon(
                onPressed: () => context.go(AppRoutes.tutor(subjectId: s.id)),
                icon: const Icon(Icons.smart_toy_outlined),
                label: Text(context.tr(S.askAi)),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: FilledButton.icon(
                onPressed: () => context.push(AppRoutes.practiceSession(subjectId: s.id)),
                icon: const Icon(Icons.quiz_outlined),
                label: Text(context.tr(CurriculumStrings.practiceChapter)),
              ),
            ),
          ],
        ),
        SectionHeader(title: context.tr(CurriculumStrings.chapters)),
        if (s.papers > 1) ...[
          SegmentedButton<int>(
            segments: [
              for (var p = 1; p <= s.papers; p++)
                ButtonSegment(value: p, label: Text(context.tr(CurriculumStrings.paperN.fill({'n': p})))),
            ],
            selected: {_paper},
            onSelectionChanged: (v) => setState(() => _paper = v.first),
          ),
          const SizedBox(height: AppSpacing.md),
        ],
        for (final c in chapters) ...[
          _ChapterTile(subject: s, chapter: c, mastery: progress.chapterMastery(c)),
          const SizedBox(height: AppSpacing.sm),
        ],
      ],
    );
  }
}

class _ChapterTile extends StatelessWidget {
  const _ChapterTile({required this.subject, required this.chapter, required this.mastery});

  final Subject subject;
  final Chapter chapter;
  final double mastery;

  @override
  Widget build(BuildContext context) {
    return TapCard(
      key: Key('chapter.${chapter.id}'),
      onTap: () => context.push(AppRoutes.chapter(chapter.id)),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: subject.color.withValues(alpha: 0.12),
            child: Text(context.n(chapter.number), style: context.text.titleSmall?.copyWith(color: subject.color)),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(context.tr(chapter.title), style: context.text.titleSmall),
                const SizedBox(height: AppSpacing.xs),
                Wrap(
                  spacing: AppSpacing.xs,
                  runSpacing: AppSpacing.xs,
                  children: [
                    Pill(context.tr(CurriculumStrings.topicCount.fill({'n': chapter.topics.length}))),
                    if (chapter.relevance == ExamRelevance.high)
                      Pill(context.tr(chapter.relevance.label), tone: Tone.danger, icon: Icons.local_fire_department),
                    if (chapter.hasLab) Pill(context.tr(CurriculumStrings.lab_), tone: Tone.info, icon: Icons.science_outlined),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                LinearProgressIndicator(
                  value: mastery,
                  color: masteryColor(context, mastery),
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
