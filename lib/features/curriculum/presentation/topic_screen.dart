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
import '../../../shared/widgets/feedback.dart';
import '../../../shared/widgets/progress.dart';
import '../../../shared/widgets/rich_content.dart';
import '../../progress/application/learning_progress_controller.dart';
import '../../progress/domain/learning_progress.dart';
import '../application/curriculum_providers.dart';
import '../application/lesson_content.dart';
import '../curriculum_strings.dart';
import '../data/curriculum_repository.dart';

/// Focused lesson view for one topic: study guide, outcomes, mark complete, and
/// shortcuts to a quick check, the tutor and the next topic.
class TopicScreen extends ConsumerWidget {
  const TopicScreen({super.key, required this.topicId});

  final String topicId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final value = ref.watch(topicProvider(topicId));
    return AppPageScaffold(
      title: value.whenOrNull(data: (t) => context.tr(t.topic.title)) ?? context.tr(S.topic),
      body: AsyncValueView<TopicRef>(
        value: value,
        onRetry: () => ref.invalidate(topicProvider(topicId)),
        data: (t) => _TopicBody(data: t),
      ),
    );
  }
}

class _TopicBody extends ConsumerWidget {
  const _TopicBody({required this.data});

  final TopicRef data;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = data.subject;
    final c = data.chapter;
    final t = data.topic;
    final p = ref.watch(learningProgressProvider.select((st) => st.topic(t.id)));
    final index = c.topics.indexOf(t);
    final next = index >= 0 && index < c.topics.length - 1 ? c.topics[index + 1] : null;

    Future<void> toggleComplete() async {
      final controller = ref.read(learningProgressProvider.notifier);
      final completing = !p.completed;
      await controller.setTopicCompleted(t.id, completed: completing);
      if (completing) {
        await controller.logActivity(ActivityKind.lesson, minutes: t.minutes, xp: 20, subjectId: s.id);
        if (!context.mounted) return;
        final state = ref.read(learningProgressProvider);
        context.showSnack(
          state.chapterCompletion(c) >= 1 ? CurriculumStrings.chapterDone : CurriculumStrings.markedComplete,
        );
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          '${context.tr(s.name)} › ${context.tr(S.chapter)} ${context.n(c.number)}: ${context.tr(c.title)}',
          style: context.text.labelMedium?.copyWith(color: s.color),
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            Expanded(
              child: LabeledProgress(label: context.tr(CurriculumStrings.mastery), value: p.mastery, color: s.color),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        InfoBanner(message: context.tr(CurriculumStrings.lessonLabel), tone: Tone.warning, icon: Icons.auto_awesome),
        const SizedBox(height: AppSpacing.md),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: RichContent(lessonMarkdown(data, context.lang), selectable: true),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Card(
          color: context.colors.secondaryContainer.withValues(alpha: 0.5),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(context.tr(CurriculumStrings.quickCheck), style: context.text.titleMedium),
                const SizedBox(height: AppSpacing.xs),
                Text(context.tr(CurriculumStrings.quickCheckHint), style: context.text.bodySmall),
                const SizedBox(height: AppSpacing.md),
                FilledButton.tonalIcon(
                  onPressed: () => context.push(
                    AppRoutes.practiceSession(subjectId: s.id, chapterId: c.id, topicId: t.id, mode: 'quick'),
                  ),
                  icon: const Icon(Icons.quiz_outlined),
                  label: Text(context.tr(S.start)),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        OutlinedButton.icon(
          onPressed: () => context.go(AppRoutes.tutor(subjectId: s.id, chapterId: c.id, topicId: t.id)),
          icon: const Icon(Icons.smart_toy_outlined),
          label: Text(context.tr(CurriculumStrings.askTutor)),
        ),
        const SizedBox(height: AppSpacing.sm),
        FilledButton.icon(
          key: const Key('topic.complete'),
          style: p.completed ? FilledButton.styleFrom(backgroundColor: context.palette.success) : null,
          onPressed: toggleComplete,
          icon: Icon(p.completed ? Icons.check_circle : Icons.check_circle_outline),
          label: Text(context.tr(p.completed ? CurriculumStrings.completed : CurriculumStrings.markComplete)),
        ),
        if (next != null) ...[
          const SizedBox(height: AppSpacing.sm),
          TextButton.icon(
            onPressed: () => context.pushReplacement(AppRoutes.topic(next.id)),
            icon: const Icon(Icons.arrow_forward),
            label: Text('${context.tr(CurriculumStrings.nextTopic)}: ${context.tr(next.title)}'),
          ),
        ],
        const SizedBox(height: AppSpacing.xl),
      ],
    );
  }
}
