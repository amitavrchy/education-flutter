import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../app/router/app_routes.dart';
import '../../../core/l10n/common_strings.dart';
import '../../../core/l10n/tr.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/time_format.dart';
import '../../../shared/widgets/badges.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/feedback.dart';
import '../../../shared/widgets/progress.dart';
import '../../../shared/widgets/section_header.dart';
import '../../curriculum/data/curriculum_repository.dart';
import '../../curriculum/domain/curriculum_models.dart';
import '../../progress/application/learning_progress_controller.dart';
import '../../progress/domain/learning_progress.dart';
import '../application/planner_controller.dart';
import '../domain/study_task.dart';
import '../planner_strings.dart';

String hhmm(BuildContext context, int minute) =>
    context.n('${(minute ~/ 60).toString().padLeft(2, '0')}:${(minute % 60).toString().padLeft(2, '0')}');

/// Planner with day (timeline), week board (drag to reschedule), month calendar and insights.
class PlannerScreen extends ConsumerStatefulWidget {
  const PlannerScreen({super.key});

  @override
  ConsumerState<PlannerScreen> createState() => _PlannerScreenState();
}

class _PlannerScreenState extends ConsumerState<PlannerScreen> {
  DateTime _day = dayOf(DateTime.now());

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(plannerProvider);
    final now = DateTime.now();
    final missed = s.tasks.where((t) => t.status == TaskStatus.missed).length;
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: Text(context.tr(PlanStrings.planner)),
          actions: [
            IconButton(
              key: const Key('plan.generate'),
              tooltip: context.tr(PlanStrings.generate),
              icon: const Icon(Icons.auto_awesome),
              onPressed: () async {
                final ok = await showConfirmDialog(context, title: PlanStrings.generate, message: PlanStrings.generateConfirm);
                if (!ok) return;
                final n = await ref.read(plannerProvider.notifier).regenerate();
                if (context.mounted) context.showSnack(PlanStrings.generated.fill({'n': n}));
              },
            ),
            IconButton(tooltip: context.tr(PlanStrings.settings), icon: const Icon(Icons.tune), onPressed: () => _settings(context, ref)),
          ],
          bottom: TabBar(tabs: [
            Tab(text: context.tr(PlanStrings.today)),
            Tab(text: context.tr(PlanStrings.week)),
            Tab(text: context.tr(PlanStrings.month)),
            Tab(text: context.tr(PlanStrings.insights)),
          ]),
        ),
        floatingActionButton: FloatingActionButton(
          key: const Key('plan.add'),
          tooltip: context.tr(PlanStrings.addTask),
          onPressed: () => showTaskEditor(context, ref, day: _day),
          child: const Icon(Icons.add_task),
        ),
        body: Column(
          children: [
            _Header(state: s, now: now),
            if (missed > 0)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: InfoBanner(
                  tone: Tone.warning,
                  message: context.tr(PlanStrings.missedBanner.fill({'n': missed})),
                  action: TextButton(
                    key: const Key('plan.moveMissed'),
                    onPressed: () async {
                      final n = await ref.read(plannerProvider.notifier).rescheduleMissed();
                      if (context.mounted) context.showSnack(PlanStrings.movedMissed.fill({'n': n}));
                    },
                    child: Text(context.tr(PlanStrings.rescheduleMissed)),
                  ),
                ),
              ),
            Expanded(
              child: TabBarView(
                children: [
                  _DayView(day: _day, onDay: (d) => setState(() => _day = d)),
                  const _WeekBoard(),
                  _MonthView(selected: _day, onDay: (d) => setState(() => _day = d)),
                  const _Insights(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _settings(BuildContext context, WidgetRef ref) async {
    var p = ref.read(plannerProvider).prefs;
    final saved = await showModalBottomSheet<PlannerPrefs>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(context.tr(PlanStrings.settings), style: context.text.titleLarge),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.event),
                title: Text(context.tr(PlanStrings.examDate)),
                subtitle: Text(shortDate(p.examDate, context.lang) + context.n(' ${p.examDate.year}')),
                onTap: () async {
                  final d = await showDatePicker(context: context, firstDate: DateTime.now(), lastDate: DateTime(2032), initialDate: p.examDate.isAfter(DateTime.now()) ? p.examDate : DateTime.now());
                  if (d != null) setState(() => p = p.copyWith(examDate: d));
                },
              ),
              Text('${context.tr(PlanStrings.dailyMinutes)}: ${context.n(p.dailyMinutes)} ${context.tr(S.minutes)}'),
              Slider(value: p.dailyMinutes.toDouble(), min: 30, max: 240, divisions: 14, onChanged: (v) => setState(() => p = p.copyWith(dailyMinutes: v.round()))),
              Text(context.tr(PlanStrings.preferredTime)),
              const SizedBox(height: AppSpacing.xs),
              SegmentedButton<StudyTime>(
                segments: [for (final t in StudyTime.values) ButtonSegment(value: t, label: Text(context.tr(t.label)))],
                selected: {p.studyTime},
                onSelectionChanged: (v) => setState(() => p = p.copyWith(studyTime: v.first)),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text('${context.tr(PlanStrings.targetGpa)}: ${context.n(p.targetGpa.toStringAsFixed(2))}'),
              Slider(value: p.targetGpa, min: 3, max: 5, divisions: 8, onChanged: (v) => setState(() => p = p.copyWith(targetGpa: v))),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(context.tr(PlanStrings.dailyReminders)),
                value: p.reminders,
                onChanged: (v) => setState(() => p = p.copyWith(reminders: v)),
              ),
              OutlinedButton.icon(
                onPressed: () async {
                  final sent = await ref.read(plannerProvider.notifier).sendTodayReminder();
                  if (context.mounted) context.showSnack(sent ? PlanStrings.reminderSent : PlanStrings.noReminder);
                },
                icon: const Icon(Icons.notifications_active_outlined),
                label: Text(context.tr(PlanStrings.sendReminder)),
              ),
              const SizedBox(height: AppSpacing.md),
              FilledButton(onPressed: () => Navigator.pop(context, p), child: Text(context.tr(PlanStrings.save))),
            ],
          ),
        ),
      ),
    );
    if (saved != null) await ref.read(plannerProvider.notifier).setPrefs(saved);
  }
}

class _Header extends ConsumerWidget {
  const _Header({required this.state, required this.now});

  final PlannerState state;
  final DateTime now;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final days = state.daysToExam(now);
    final minutesToday = ref.watch(learningProgressProvider.select((p) => p.minutesOn(now)));
    final goal = state.prefs.dailyMinutes;
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.sm),
      child: Row(
        children: [
          Expanded(
            child: Card(
              color: context.colors.primaryContainer,
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Row(
                  children: [
                    Icon(Icons.hourglass_bottom, color: context.colors.onPrimaryContainer),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        days >= 0 ? context.tr(PlanStrings.daysToExam.fill({'n': days})) : context.tr(PlanStrings.examPassed),
                        key: const Key('plan.countdown'),
                        style: context.text.titleSmall?.copyWith(color: context.colors.onPrimaryContainer),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.sm),
              child: Row(
                children: [
                  ProgressRing(value: goal == 0 ? 0 : minutesToday / goal, size: 44, stroke: 5),
                  const SizedBox(width: AppSpacing.sm),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(context.tr(PlanStrings.dailyGoal), style: context.text.labelSmall),
                      Text(context.tr(PlanStrings.minutesOf.fill({'a': minutesToday, 'b': goal})), style: context.text.labelLarge),
                    ],
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

class _DayView extends ConsumerWidget {
  const _DayView({required this.day, required this.onDay});

  final DateTime day;
  final ValueChanged<DateTime> onDay;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasks = ref.watch(plannerProvider).on(day);
    final today = dayOf(DateTime.now());
    return ListView(
      padding: AppSpacing.screen,
      children: [
        SizedBox(
          height: 64,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              for (var i = -3; i < 11; i++)
                Builder(builder: (context) {
                  final d = today.add(Duration(days: i));
                  final selected = d == day;
                  return Padding(
                    padding: const EdgeInsetsDirectional.only(end: AppSpacing.xs),
                    child: ChoiceChip(
                      selected: selected,
                      onSelected: (_) => onDay(d),
                      label: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [Text(_weekday(context, d), style: context.text.labelSmall), Text(context.n(d.day))],
                      ),
                    ),
                  );
                }),
            ],
          ),
        ),
        SectionHeader(title: '${context.tr(PlanStrings.timeline)} · ${shortDate(day, context.lang)}'),
        if (tasks.isEmpty) EmptyState(icon: Icons.event_available_outlined, title: context.tr(PlanStrings.noTasks), compact: true),
        for (final t in tasks) TaskTile(task: t),
        const SizedBox(height: 88),
      ],
    );
  }
}

String _weekday(BuildContext context, DateTime d) {
  const bn = ['সোম', 'মঙ্গল', 'বুধ', 'বৃহঃ', 'শুক্র', 'শনি', 'রবি'];
  const en = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  return (context.isBangla ? bn : en)[d.weekday - 1];
}

/// Timeline row with status, priority and quick complete.
class TaskTile extends ConsumerWidget {
  const TaskTile({super.key, required this.task, this.compact = false});

  final StudyTask task;
  final bool compact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = task;
    final color = switch (t.status) {
      TaskStatus.done => context.palette.success,
      TaskStatus.missed => context.palette.danger,
      TaskStatus.scheduled => t.priority == Priority.high ? context.palette.warning : context.colors.primary,
    };
    return Card(
      child: InkWell(
        key: Key('task.${t.id}'),
        onTap: () => showTaskSheet(context, ref, t),
        child: Padding(
          padding: EdgeInsets.all(compact ? AppSpacing.sm : AppSpacing.md),
          child: Row(
            children: [
              if (!compact)
                SizedBox(
                  width: 48,
                  child: Column(children: [Text(hhmm(context, t.startMinute), style: context.text.labelLarge), Text('${context.n(t.minutes)}′', style: context.text.labelSmall)]),
                ),
              Container(width: 4, height: compact ? 28 : 40, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.tr(t.title),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: (compact ? context.text.labelMedium : context.text.titleSmall)?.copyWith(
                        decoration: t.status == TaskStatus.done ? TextDecoration.lineThrough : null,
                      ),
                    ),
                    if (!compact)
                      Wrap(spacing: AppSpacing.xs, children: [
                        Pill(context.tr(t.kind.label), icon: t.kind.icon),
                        if (t.status == TaskStatus.missed) Pill(context.tr(PlanStrings.missed), tone: Tone.danger),
                        if (t.priority == Priority.high && t.status == TaskStatus.scheduled) Pill(context.tr(t.priority.label), tone: Tone.warning),
                        if (t.generated) Pill(context.tr(PlanStrings.aiTag), tone: Tone.info),
                      ]),
                  ],
                ),
              ),
              if (!compact)
                Checkbox(
                  key: Key('task.check.${t.id}'),
                  value: t.status == TaskStatus.done,
                  onChanged: (v) => v == true ? showCompletionModal(context, ref, t) : ref.read(plannerProvider.notifier).reopen(t.id),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WeekBoard extends ConsumerWidget {
  const _WeekBoard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(plannerProvider);
    final today = dayOf(DateTime.now());
    final start = today.subtract(Duration(days: (today.weekday + 1) % 7)); // Bangladeshi week starts on Saturday
    return Column(
      children: [
        Padding(padding: const EdgeInsets.all(AppSpacing.sm), child: Text(context.tr(PlanStrings.dragHint), style: context.text.bodySmall)),
        Expanded(
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
            children: [
              for (var i = 0; i < 7; i++)
                Builder(builder: (context) {
                  final d = start.add(Duration(days: i));
                  final tasks = s.on(d);
                  return DragTarget<StudyTask>(
                    key: Key('board.day.$i'),
                    onAcceptWithDetails: (details) async {
                      await ref.read(plannerProvider.notifier).reschedule(details.data.id, d);
                      if (context.mounted) context.showSnack(PlanStrings.rescheduled);
                    },
                    builder: (context, candidate, _) => Container(
                      width: 170,
                      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
                      padding: const EdgeInsets.all(AppSpacing.xs),
                      decoration: BoxDecoration(
                        color: candidate.isNotEmpty ? context.colors.primaryContainer : (d == today ? context.colors.surfaceContainerHigh : context.colors.surfaceContainerLow),
                        borderRadius: AppRadius.card,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(AppSpacing.xs),
                            child: Text('${_weekday(context, d)} ${context.n(d.day)}', style: context.text.titleSmall),
                          ),
                          Expanded(
                            child: ListView(
                              children: [
                                for (final t in tasks)
                                  LongPressDraggable<StudyTask>(
                                    data: t,
                                    feedback: Material(
                                      elevation: 6,
                                      borderRadius: AppRadius.card,
                                      child: SizedBox(width: 160, child: Padding(padding: const EdgeInsets.all(AppSpacing.sm), child: Text(context.tr(t.title), maxLines: 2))),
                                    ),
                                    childWhenDragging: Opacity(opacity: 0.3, child: TaskTile(task: t, compact: true)),
                                    child: TaskTile(task: t, compact: true),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
            ],
          ),
        ),
      ],
    );
  }
}

class _MonthView extends ConsumerWidget {
  const _MonthView({required this.selected, required this.onDay});

  final DateTime selected;
  final ValueChanged<DateTime> onDay;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(plannerProvider);
    final first = DateTime(selected.year, selected.month);
    final daysInMonth = DateTime(selected.year, selected.month + 1, 0).day;
    final offset = first.weekday % 7; // Sunday-first grid
    final today = dayOf(DateTime.now());
    return ListView(
      padding: AppSpacing.screen,
      children: [
        Row(
          children: [
            IconButton(onPressed: () => onDay(DateTime(selected.year, selected.month - 1, 1)), icon: const Icon(Icons.chevron_left)),
            Expanded(child: Center(child: Text('${shortDate(first, context.lang).split(' ').last} ${context.n(first.year)}', style: context.text.titleMedium))),
            IconButton(onPressed: () => onDay(DateTime(selected.year, selected.month + 1, 1)), icon: const Icon(Icons.chevron_right)),
          ],
        ),
        GridView.count(
          crossAxisCount: 7,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            for (var i = 0; i < offset; i++) const SizedBox.shrink(),
            for (var d = 1; d <= daysInMonth; d++)
              Builder(builder: (context) {
                final day = DateTime(selected.year, selected.month, d);
                final tasks = s.on(day);
                final done = tasks.where((t) => t.status == TaskStatus.done).length;
                final isSel = day == dayOf(selected);
                return InkWell(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  onTap: () {
                    onDay(day);
                    DefaultTabController.of(context).animateTo(0);
                  },
                  child: Container(
                    margin: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: isSel ? context.colors.primary : (day == today ? context.colors.primaryContainer : null),
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(context.n(d), style: TextStyle(color: isSel ? context.colors.onPrimary : null)),
                        if (tasks.isNotEmpty)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              for (var i = 0; i < tasks.length.clamp(0, 3); i++)
                                Container(
                                  width: 5,
                                  height: 5,
                                  margin: const EdgeInsets.all(1),
                                  decoration: BoxDecoration(shape: BoxShape.circle, color: i < done ? context.palette.success : context.palette.warning),
                                ),
                            ],
                          ),
                      ],
                    ),
                  ),
                );
              }),
          ],
        ),
      ],
    );
  }
}

class _Insights extends ConsumerWidget {
  const _Insights();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(plannerProvider);
    final progress = ref.watch(learningProgressProvider);
    final repo = ref.watch(curriculumRepositoryProvider);
    final now = DateTime.now();
    final rate = s.completionRate(now);
    final hour = s.bestHour();
    final bySubject = <String, int>{};
    for (final a in progress.activities.where((a) => now.difference(a.at).inDays < 14 && a.subjectId != null)) {
      bySubject.update(a.subjectId!, (v) => v + a.minutes, ifAbsent: () => a.minutes);
    }
    final maxMin = bySubject.values.fold<int>(1, (m, v) => v > m ? v : m);
    return ListView(
      padding: AppSpacing.screen,
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Row(
              children: [
                ProgressRing(value: rate ?? 0, size: 72, color: masteryColor(context, rate ?? 0)),
                const SizedBox(width: AppSpacing.lg),
                Expanded(child: Text(context.tr(PlanStrings.completion), style: context.text.titleMedium)),
              ],
            ),
          ),
        ),
        if (hour != null)
          Card(
            child: ListTile(
              leading: const Icon(Icons.wb_twilight),
              title: Text(context.tr(PlanStrings.bestTime)),
              trailing: Text(hhmm(context, hour * 60), style: context.text.titleMedium),
            ),
          ),
        SectionHeader(title: context.tr(PlanStrings.minutesBySubject)),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              children: [
                for (final e in bySubject.entries)
                  LabeledProgress(
                    label: context.tr(repo.cachedSubjects.where((x) => x.id == e.key).firstOrNull?.name ?? Tr.same(e.key)),
                    value: e.value / maxMin,
                    trailing: '${context.n(e.value)} ${context.tr(S.minutes)}',
                    color: repo.cachedSubjects.where((x) => x.id == e.key).firstOrNull?.color,
                  ),
              ],
            ),
          ),
        ),
        SectionHeader(title: context.tr(PlanStrings.recommendations)),
        InfoBanner(message: context.tr(rate != null && rate < 0.6 ? PlanStrings.recLowCompletion : PlanStrings.recGood), tone: Tone.info),
        if (hour != null) ...[
          const SizedBox(height: AppSpacing.sm),
          InfoBanner(message: context.tr(PlanStrings.recBestTime.fill({'h': hour})), tone: Tone.success),
        ],
      ],
    );
  }
}

/// Session detail: complete, reschedule, edit, delete, jump to the related chapter/practice.
Future<void> showTaskSheet(BuildContext context, WidgetRef ref, StudyTask t) => showModalBottomSheet<void>(
  context: context,
  showDragHandle: true,
  builder: (context) {
    final repo = ref.read(curriculumRepositoryProvider);
    final ch = t.chapterId == null ? null : repo.findChapter(t.chapterId!);
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.xl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(context.tr(t.title), style: context.text.titleLarge),
          const SizedBox(height: AppSpacing.xs),
          Text('${shortDate(t.day, context.lang)} · ${hhmm(context, t.startMinute)} · ${context.n(t.minutes)} ${context.tr(S.minutes)} · ${context.tr(t.kind.label)}'),
          if (t.note.isNotEmpty) ...[const SizedBox(height: AppSpacing.sm), Text(t.note)],
          const SizedBox(height: AppSpacing.md),
          if (ch != null)
            Wrap(spacing: AppSpacing.sm, children: [
              OutlinedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  context.push(AppRoutes.chapter(ch.chapter.id));
                },
                icon: const Icon(Icons.menu_book_outlined),
                label: Text(context.tr(PlanStrings.openChapter)),
              ),
              OutlinedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  context.push(AppRoutes.practiceSession(subjectId: ch.subject.id, chapterId: ch.chapter.id));
                },
                icon: const Icon(Icons.quiz_outlined),
                label: Text(context.tr(PlanStrings.startPractice)),
              ),
            ]),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () async {
                    final d = await showDatePicker(context: context, firstDate: DateTime.now().subtract(const Duration(days: 1)), lastDate: DateTime.now().add(const Duration(days: 120)), initialDate: t.day.isBefore(DateTime.now()) ? DateTime.now() : t.day);
                    if (d == null || !context.mounted) return;
                    final time = await showTimePicker(context: context, initialTime: TimeOfDay(hour: t.startMinute ~/ 60, minute: t.startMinute % 60));
                    await ref.read(plannerProvider.notifier).reschedule(t.id, d, startMinute: time == null ? null : time.hour * 60 + time.minute);
                    if (context.mounted) Navigator.pop(context);
                  },
                  icon: const Icon(Icons.event_repeat),
                  label: Text(context.tr(PlanStrings.reschedule)),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: t.status == TaskStatus.done
                    ? OutlinedButton(onPressed: () => ref.read(plannerProvider.notifier).reopen(t.id).then((_) => context.mounted ? Navigator.pop(context) : null), child: Text(context.tr(PlanStrings.reopen)))
                    : FilledButton.icon(
                        onPressed: () async {
                          Navigator.pop(context);
                          await showCompletionModal(context, ref, t);
                        },
                        icon: const Icon(Icons.check),
                        label: Text(context.tr(PlanStrings.markDone)),
                      ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              TextButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  showTaskEditor(context, ref, task: t);
                },
                icon: const Icon(Icons.edit_outlined),
                label: Text(context.tr(S.edit)),
              ),
              const Spacer(),
              TextButton.icon(
                style: TextButton.styleFrom(foregroundColor: context.colors.error),
                onPressed: () async {
                  final ok = await showConfirmDialog(context, title: PlanStrings.deleteTask, destructive: true, confirmLabel: S.delete);
                  if (!ok) return;
                  await ref.read(plannerProvider.notifier).delete(t.id);
                  if (context.mounted) Navigator.pop(context);
                },
                icon: const Icon(Icons.delete_outline),
                label: Text(context.tr(S.delete)),
              ),
            ],
          ),
        ],
      ),
    );
  },
);

/// Completion modal: actual minutes and focus rating.
Future<void> showCompletionModal(BuildContext context, WidgetRef ref, StudyTask t) async {
  var minutes = t.minutes.toDouble();
  var focus = 4;
  final ok = await showDialog<bool>(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        icon: Icon(Icons.celebration_outlined, color: context.palette.success, size: 40),
        title: Text(context.tr(PlanStrings.completeTitle)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('${context.tr(PlanStrings.actualMinutes)} ${context.n(minutes.round())}'),
            Slider(value: minutes, min: 5, max: 180, divisions: 35, onChanged: (v) => setState(() => minutes = v)),
            Text(context.tr(PlanStrings.focusLevel)),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 1; i <= 5; i++)
                  IconButton(
                    tooltip: '$i/5',
                    onPressed: () => setState(() => focus = i),
                    icon: Icon(i <= focus ? Icons.star : Icons.star_border, color: context.palette.warning),
                  ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(context.tr(S.cancel))),
          FilledButton(key: const Key('complete.save'), onPressed: () => Navigator.pop(context, true), child: Text(context.tr(PlanStrings.save))),
        ],
      ),
    ),
  );
  if (ok == true) await ref.read(plannerProvider.notifier).complete(t.id, actualMinutes: minutes.round(), focus: focus);
}

/// Add/edit task form with validation.
Future<void> showTaskEditor(BuildContext context, WidgetRef ref, {StudyTask? task, DateTime? day}) async {
  final repo = ref.read(curriculumRepositoryProvider);
  final title = TextEditingController(text: task == null ? '' : context.tr(task.title));
  final note = TextEditingController(text: task?.note ?? '');
  var kind = task?.kind ?? TaskKind.study;
  var priority = task?.priority ?? Priority.medium;
  var date = task?.day ?? day ?? dayOf(DateTime.now());
  var start = task?.startMinute ?? ref.read(plannerProvider).prefs.studyTime.startMinute;
  var minutes = (task?.minutes ?? 30).toDouble();
  var reminder = task?.reminder ?? true;
  String? subjectId = task?.subjectId;
  final formKey = GlobalKey<FormState>();
  final saved = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) => Padding(
        padding: EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.lg + MediaQuery.viewInsetsOf(context).bottom),
        child: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(context.tr(task == null ? PlanStrings.addTask : PlanStrings.editTask), style: context.text.titleLarge),
                const SizedBox(height: AppSpacing.md),
                TextFormField(
                  key: const Key('task.title'),
                  controller: title,
                  decoration: InputDecoration(labelText: context.tr(PlanStrings.title)),
                  validator: (v) => (v ?? '').trim().isEmpty ? context.tr(S.required) : null,
                ),
                const SizedBox(height: AppSpacing.sm),
                DropdownButtonFormField<String?>(
                  initialValue: subjectId,
                  isExpanded: true,
                  decoration: InputDecoration(labelText: context.tr(S.subject)),
                  items: [
                    DropdownMenuItem<String?>(child: Text(context.tr(S.all))),
                    for (final Subject s in repo.cachedSubjects) DropdownMenuItem(value: s.id, child: Text('${context.tr(s.name)} (${context.tr(s.level.label)})')),
                  ],
                  onChanged: (v) => setState(() => subjectId = v),
                ),
                const SizedBox(height: AppSpacing.sm),
                Wrap(spacing: AppSpacing.xs, children: [
                  for (final k in TaskKind.values) ChoiceChip(avatar: Icon(k.icon, size: 16), label: Text(context.tr(k.label)), selected: kind == k, onSelected: (_) => setState(() => kind = k)),
                ]),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          final d = await showDatePicker(context: context, firstDate: DateTime.now().subtract(const Duration(days: 30)), lastDate: DateTime.now().add(const Duration(days: 365)), initialDate: date);
                          if (d != null) setState(() => date = d);
                        },
                        icon: const Icon(Icons.event),
                        label: Text(shortDate(date, context.lang)),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          final t = await showTimePicker(context: context, initialTime: TimeOfDay(hour: start ~/ 60, minute: start % 60));
                          if (t != null) setState(() => start = t.hour * 60 + t.minute);
                        },
                        icon: const Icon(Icons.schedule),
                        label: Text(hhmm(context, start)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                Text('${context.tr(PlanStrings.duration)}: ${context.n(minutes.round())}'),
                Slider(value: minutes, min: 10, max: 180, divisions: 17, onChanged: (v) => setState(() => minutes = v)),
                SegmentedButton<Priority>(
                  segments: [for (final p in Priority.values) ButtonSegment(value: p, label: Text(context.tr(p.label)))],
                  selected: {priority},
                  onSelectionChanged: (v) => setState(() => priority = v.first),
                ),
                SwitchListTile(contentPadding: EdgeInsets.zero, title: Text(context.tr(PlanStrings.reminder)), value: reminder, onChanged: (v) => setState(() => reminder = v)),
                TextField(controller: note, decoration: InputDecoration(labelText: context.tr(PlanStrings.note)), maxLines: 2),
                const SizedBox(height: AppSpacing.md),
                FilledButton(
                  key: const Key('task.save'),
                  onPressed: () {
                    if (formKey.currentState!.validate()) Navigator.pop(context, true);
                  },
                  child: Text(context.tr(PlanStrings.save)),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
  if (saved != true) return;
  final ctl = ref.read(plannerProvider.notifier);
  if (task == null) {
    await ctl.add(StudyTask(
      id: 'task-${DateTime.now().microsecondsSinceEpoch}',
      title: Tr.same(title.text.trim()),
      kind: kind,
      day: dayOf(date),
      startMinute: start,
      minutes: minutes.round(),
      subjectId: subjectId,
      priority: priority,
      note: note.text.trim(),
      reminder: reminder,
    ));
  } else {
    await ctl.update(task.copyWith(
      title: Tr.same(title.text.trim()),
      kind: kind,
      day: dayOf(date),
      startMinute: start,
      minutes: minutes.round(),
      priority: priority,
      note: note.text.trim(),
      reminder: reminder,
      subjectId: () => subjectId,
    ));
  }
}
