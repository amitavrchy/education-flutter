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
import '../../../shared/widgets/async_value_view.dart';
import '../../../shared/widgets/badges.dart';
import '../../../shared/widgets/cards.dart';
import '../../../shared/widgets/progress.dart';
import '../../../shared/widgets/section_header.dart';
import '../../progress/application/learning_progress_controller.dart';
import '../application/curriculum_providers.dart';
import '../curriculum_strings.dart';
import '../data/curriculum_repository.dart';
import '../domain/curriculum_models.dart';

/// Chapter overview: description, metadata, outcomes, prerequisites, topic list with
/// completion, and shortcuts into learning, practice, tutor, flashcards, notes and labs.
class ChapterDetailScreen extends ConsumerWidget {
  const ChapterDetailScreen({super.key, required this.chapterId});

  final String chapterId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final value = ref.watch(chapterProvider(chapterId));
    return AppPageScaffold(
      title: value.whenOrNull(data: (c) => context.tr(c.chapter.title)) ?? context.tr(S.chapter),
      body: AsyncValueView<ChapterRef>(
        value: value,
        onRetry: () => ref.invalidate(chapterProvider(chapterId)),
        data: (c) => _ChapterBody(data: c),
      ),
    );
  }
}

class _ChapterBody extends ConsumerWidget {
  const _ChapterBody({required this.data});

  final ChapterRef data;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = data.subject;
    final c = data.chapter;
    final progress = ref.watch(learningProgressProvider);
    final repo = ref.watch(curriculumRepositoryProvider);
    final completion = progress.chapterCompletion(c);
    final nextTopic = c.topics.where((t) => !progress.topic(t.id).completed).firstOrNull ?? c.topics.firstOrNull;
    final history = [
      for (final t in c.topics)
        if (progress.topic(t.id).lastStudied != null) (t, progress.topic(t.id).lastStudied!),
    ]..sort((a, b) => b.$2.compareTo(a.$2));

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
                    IconTile(icon: s.icon, color: s.color, size: 48),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${context.tr(s.name)} · ${context.tr(S.chapter)} ${context.n(c.number)}',
                            style: context.text.labelMedium?.copyWith(color: s.color),
                          ),
                          Text(context.tr(c.title), style: context.text.titleLarge),
                        ],
                      ),
                    ),
                    ProgressRing(value: progress.chapterMastery(c), size: 56, color: s.color),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                Text(context.tr(c.description), style: context.text.bodyMedium),
                const SizedBox(height: AppSpacing.md),
                Wrap(
                  spacing: AppSpacing.xs,
                  runSpacing: AppSpacing.xs,
                  children: [
                    Pill(context.tr(CurriculumStrings.estTime.fill({'n': (c.minutes / 60).toStringAsFixed(1)})),
                        icon: Icons.schedule),
                    Pill('${context.tr(S.difficulty)}: ${context.tr(c.difficulty.label)}',
                        tone: c.difficulty == Difficulty.hard ? Tone.danger : Tone.neutral),
                    Pill(context.tr(c.relevance.label),
                        tone: c.relevance == ExamRelevance.high ? Tone.warning : Tone.neutral,
                        icon: Icons.local_fire_department_outlined),
                    Pill(context.tr(CurriculumStrings.topicCount.fill({'n': c.topics.length}))),
                    if (c.hasLab) Pill(context.tr(CurriculumStrings.lab_), tone: Tone.info, icon: Icons.science_outlined),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                LabeledProgress(label: context.tr(CurriculumStrings.completed), value: completion, color: s.color),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        if (nextTopic != null)
          FilledButton.icon(
            key: const Key('chapter.start'),
            onPressed: () => context.push(AppRoutes.topic(nextTopic.id)),
            icon: Icon(completion > 0 ? Icons.play_circle_outline : Icons.play_arrow),
            label: Text(context.tr(completion > 0 ? CurriculumStrings.resumeLearning : CurriculumStrings.startLearning)),
          ),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            ActionChip(
              avatar: const Icon(Icons.quiz_outlined, size: 18),
              label: Text(context.tr(CurriculumStrings.practiceChapter)),
              onPressed: () => context.push(AppRoutes.practiceSession(subjectId: s.id, chapterId: c.id)),
            ),
            ActionChip(
              avatar: const Icon(Icons.smart_toy_outlined, size: 18),
              label: Text(context.tr(CurriculumStrings.askTutor)),
              onPressed: () => context.go(AppRoutes.tutor(subjectId: s.id, chapterId: c.id)),
            ),
            ActionChip(
              avatar: const Icon(Icons.style_outlined, size: 18),
              label: Text(context.tr(CurriculumStrings.flashcards)),
              onPressed: () => context.push(AppRoutes.flashcards(chapterId: c.id)),
            ),
            ActionChip(
              avatar: const Icon(Icons.sticky_note_2_outlined, size: 18),
              label: Text(context.tr(CurriculumStrings.notes)),
              onPressed: () => context.push(AppRoutes.notes(chapterId: c.id)),
            ),
            ActionChip(
              avatar: const Icon(Icons.help_outline, size: 18),
              label: Text(context.tr(CurriculumStrings.questionBank)),
              onPressed: () => context.push(AppRoutes.questionBank(subjectId: s.id, chapterId: c.id)),
            ),
            if (c.hasLab)
              ActionChip(
                avatar: const Icon(Icons.science_outlined, size: 18),
                label: Text(context.tr(CurriculumStrings.lab)),
                onPressed: () => context.push(AppRoutes.labs),
              ),
          ],
        ),
        if (c.prerequisiteIds.isNotEmpty) ...[
          SectionHeader(title: context.tr(CurriculumStrings.prerequisites)),
          for (final id in c.prerequisiteIds)
            if (repo.findChapter(id) case final pre?)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: NavTile(
                  icon: Icons.link,
                  color: pre.subject.color,
                  title: context.tr(pre.chapter.title),
                  subtitle: context.tr(pre.subject.name),
                  onTap: () => context.push(AppRoutes.chapter(pre.chapter.id)),
                ),
              ),
        ],
        SectionHeader(title: context.tr(CurriculumStrings.topics)),
        for (final t in c.topics) ...[
          _TopicTile(subject: s, topic: t),
          const SizedBox(height: AppSpacing.sm),
        ],
        SectionHeader(title: context.tr(CurriculumStrings.outcomes)),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final o in c.outcomes)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.flag_outlined, size: 18, color: s.color),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(child: Text(context.tr(o.text), style: context.text.bodyMedium)),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
        if (history.isNotEmpty) ...[
          SectionHeader(title: context.tr(CurriculumStrings.learningHistory)),
          Card(
            child: Column(
              children: [
                for (final (t, at) in history.take(5))
                  ListTile(
                    dense: true,
                    leading: const Icon(Icons.history),
                    title: Text(context.tr(t.title)),
                    trailing: Text(relativeTime(at, context.lang), style: context.text.labelSmall),
                    onTap: () => context.push(AppRoutes.topic(t.id)),
                  ),
              ],
            ),
          ),
        ],
        const SizedBox(height: AppSpacing.xl),
      ],
    );
  }
}

class _TopicTile extends ConsumerWidget {
  const _TopicTile({required this.subject, required this.topic});

  final Subject subject;
  final Topic topic;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = ref.watch(learningProgressProvider.select((s) => s.topic(topic.id)));
    return TapCard(
      key: Key('topic.${topic.id}'),
      onTap: () => context.push(AppRoutes.topic(topic.id)),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
      child: Row(
        children: [
          Icon(
            p.completed ? Icons.check_circle : Icons.radio_button_unchecked,
            color: p.completed ? context.palette.success : context.colors.outline,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(context.tr(topic.title), style: context.text.titleSmall),
                Text(
                  '${context.n(topic.minutes)} ${context.tr(S.minutes)}'
                  '${p.accuracy == null ? '' : ' · ${context.tr(CurriculumStrings.accuracy)} ${context.pct(p.accuracy! * 100)}'}',
                  style: context.text.bodySmall?.copyWith(color: context.colors.onSurfaceVariant),
                ),
              ],
            ),
          ),
          SizedBox(
            width: 48,
            child: LinearProgressIndicator(value: p.mastery, color: masteryColor(context, p.mastery)),
          ),
        ],
      ),
    );
  }
}
