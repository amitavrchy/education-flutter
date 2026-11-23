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
import '../../../shared/widgets/cards.dart';
import '../../../shared/widgets/feedback.dart';
import '../../../shared/widgets/section_header.dart';
import '../application/exam_controller.dart';
import '../domain/exam.dart';
import '../exam_strings.dart';

/// Start a new attempt from a template (or config) and open the exam screen.
Future<void> startExam(BuildContext context, WidgetRef ref, {ExamTemplate? template, ExamConfig? config, ExamType type = ExamType.custom}) async {
  try {
    final attempt = await ref.read(examProvider.notifier).start(template: template, config: config, type: type);
    if (context.mounted) await context.push(AppRoutes.examTake(attempt.id));
  } catch (e) {
    if (context.mounted) context.showErrorSnack(e);
  }
}

/// Lists in-progress attempts (recovery), available exams, custom/adaptive creation and recent results.
class ExamCenterScreen extends ConsumerWidget {
  const ExamCenterScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(examProvider);
    final now = DateTime.now();
    return AppPageScaffold(
      title: context.tr(ExamStrings.center),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (state.inProgress.isNotEmpty) ...[
            SectionHeader(title: context.tr(ExamStrings.inProgress)),
            for (final a in state.inProgress)
              Card(
                color: context.palette.warningContainer.withValues(alpha: 0.5),
                child: ListTile(
                  key: Key('exam.resume.${a.id}'),
                  leading: Icon(a.type.icon, color: context.palette.warning),
                  title: Text(context.tr(a.title)),
                  subtitle: Text(
                    '${context.n(a.answeredCount)}/${context.n(a.questionIds.length)} · '
                    '${clockLabel(Duration(seconds: a.remainingSeconds ?? 0), context.lang)}',
                  ),
                  trailing: Wrap(
                    children: [
                      IconButton(
                        tooltip: context.tr(ExamStrings.discard),
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () async {
                          final ok = await showConfirmDialog(context, title: ExamStrings.discardConfirm, destructive: true, confirmLabel: ExamStrings.discard);
                          if (ok) await ref.read(examProvider.notifier).discard(a.id);
                        },
                      ),
                      FilledButton(onPressed: () => context.push(AppRoutes.examTake(a.id)), child: Text(context.tr(ExamStrings.resume))),
                    ],
                  ),
                ),
              ),
          ],
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: _ActionCard(
                  key: const Key('exam.custom'),
                  icon: Icons.tune,
                  title: ExamStrings.createCustom,
                  subtitle: ExamStrings.createCustomHint,
                  color: AppColors.categorical[3],
                  onTap: () => context.push(AppRoutes.examSetup),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _ActionCard(
                  key: const Key('exam.adaptive'),
                  icon: Icons.auto_graph,
                  title: ExamStrings.adaptive,
                  subtitle: ExamStrings.adaptiveHint,
                  color: AppColors.categorical[5],
                  onTap: () => startExam(
                    context,
                    ref,
                    config: const ExamConfig(questionCount: 8, timeLimitMinutes: 12),
                    type: ExamType.adaptive,
                  ),
                ),
              ),
            ],
          ),
          SectionHeader(title: context.tr(ExamStrings.available)),
          for (final t in state.templates) ...[
            _TemplateCard(
              template: t,
              done: state.finished.any((a) => a.templateId == t.id),
              locked: t.scheduledAt != null && t.scheduledAt!.isAfter(now),
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
          SectionHeader(
            title: context.tr(ExamStrings.recent),
            actionLabel: context.tr(S.seeAll),
            onAction: () => context.push(AppRoutes.examResults),
          ),
          for (final a in state.finished.take(3))
            Card(
              child: ListTile(
                leading: CircleAvatar(child: Text(gradeFor(a.result!.percent).grade)),
                title: Text(context.tr(a.title)),
                subtitle: Text(relativeTime(a.submittedAt ?? a.startedAt, context.lang)),
                trailing: Text(context.pct(a.result!.percent * 100), style: context.text.titleMedium),
                onTap: () => context.push(AppRoutes.examResult(a.id)),
              ),
            ),
          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({super.key, required this.icon, required this.title, required this.subtitle, required this.color, required this.onTap});

  final IconData icon;
  final Tr title;
  final Tr subtitle;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => TapCard(
    onTap: onTap,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        IconTile(icon: icon, color: color),
        const SizedBox(height: AppSpacing.sm),
        Text(context.tr(title), style: context.text.titleSmall),
        Text(context.tr(subtitle), style: context.text.bodySmall, maxLines: 2, overflow: TextOverflow.ellipsis),
      ],
    ),
  );
}

class _TemplateCard extends ConsumerWidget {
  const _TemplateCard({required this.template, required this.done, required this.locked});

  final ExamTemplate template;
  final bool done;
  final bool locked;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = template;
    return TapCard(
      key: Key('exam.tpl.${t.id}'),
      onTap: locked ? () => context.showSnack(ExamStrings.notOpenYet) : () => startExam(context, ref, template: t),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IconTile(icon: t.type.icon),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(context.tr(t.title), style: context.text.titleSmall),
                if (t.description != null)
                  Text(context.tr(t.description!), style: context.text.bodySmall?.copyWith(color: context.colors.onSurfaceVariant)),
                if (t.assignedBy != null)
                  Text(context.tr(t.assignedBy!), style: context.text.labelSmall?.copyWith(color: context.colors.primary)),
                const SizedBox(height: AppSpacing.xs),
                Wrap(
                  spacing: AppSpacing.xs,
                  runSpacing: AppSpacing.xs,
                  children: [
                    Pill(context.tr(t.type.label), tone: Tone.primary),
                    Pill(context.tr(ExamStrings.minutes.fill({'n': t.config.timeLimitMinutes})), icon: Icons.timer_outlined),
                    if (t.dueAt != null) Pill(context.tr(ExamStrings.due.fill({'d': shortDate(t.dueAt!, context.lang)})), tone: Tone.warning),
                    if (locked) Pill(context.tr(ExamStrings.opensAt.fill({'d': shortDate(t.scheduledAt!, context.lang)})), tone: Tone.neutral, icon: Icons.lock_clock),
                    if (done) Pill(context.tr(ExamStrings.completed), tone: Tone.success, icon: Icons.check),
                    if (t.type == ExamType.boardPrevious) const DemoBadge(label: S.syntheticSample),
                  ],
                ),
              ],
            ),
          ),
          Icon(locked ? Icons.lock_outline : Icons.play_circle_outline, color: context.colors.primary),
        ],
      ),
    );
  }
}
