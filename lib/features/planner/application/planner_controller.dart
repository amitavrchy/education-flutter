import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/tr.dart';
import '../../../core/mock/json_collection.dart';
import '../../../core/storage/local_store.dart';
import '../../curriculum/domain/curriculum_models.dart';
import '../../notifications/application/notifications_controller.dart';
import '../../notifications/domain/app_notification.dart';
import '../../profile/application/student_profile_controller.dart';
import '../../progress/application/learning_progress_controller.dart';
import '../../progress/domain/learning_progress.dart';
import '../../curriculum/data/curriculum_repository.dart';
import '../domain/study_task.dart';
import '../../../core/network/network_providers.dart';
import '../../../core/network/owner_sync.dart';
import '../../progress/data/remote_progress.dart';
import '../data/remote_tasks.dart';

/// Deterministic study-plan generator ("AI plan" simulation). Pure, unit-tested.
///
/// Each day fills [PlannerPrefs.dailyMinutes]: the weakest unfinished chapters get new study
/// blocks, recently studied topics get spaced revision, flashcards every day, practice on
/// weak chapters, and a model test every Friday.
List<StudyTask> generatePlan({
  required List<Subject> subjects,
  required double Function(Chapter c) masteryOf,
  required PlannerPrefs prefs,
  required DateTime from,
  int days = 7,
}) {
  final start = dayOf(from);
  final chapters = [
    for (final s in subjects)
      for (final c in s.chapters) (s, c),
  ]..sort((a, b) {
      // Weakest first; ties broken by exam relevance (high first).
      final byMastery = masteryOf(a.$2).compareTo(masteryOf(b.$2));
      return byMastery != 0 ? byMastery : a.$2.relevance.index.compareTo(b.$2.relevance.index);
    });
  if (chapters.isEmpty) return const [];
  final tasks = <StudyTask>[];
  var cursor = 0;
  for (var d = 0; d < days; d++) {
    final day = start.add(Duration(days: d));
    var minute = prefs.studyTime.startMinute;
    var budget = prefs.dailyMinutes;
    var n = 0;
    void add(TaskKind kind, Tr title, int mins, {Subject? s, Chapter? c, Priority p = Priority.medium}) {
      if (budget <= 0) return;
      final m = min(mins, budget);
      tasks.add(StudyTask(
        id: 'gen-${day.toIso8601String().substring(0, 10)}-${n++}',
        title: title,
        kind: kind,
        day: day,
        startMinute: minute,
        minutes: m,
        subjectId: s?.id,
        chapterId: c?.id,
        priority: p,
        generated: true,
      ));
      minute += m + 10;
      budget -= m;
    }

    final (s1, c1) = chapters[cursor % chapters.length];
    final weak = masteryOf(c1) < 0.4;
    add(TaskKind.study, Tr('${s1.name.bn}: ${c1.title.bn}', '${s1.name.en}: ${c1.title.en}'), 40, s: s1, c: c1, p: weak ? Priority.high : Priority.medium);
    if (day.weekday == DateTime.friday) {
      add(TaskKind.exam, const Tr('সাপ্তাহিক মডেল টেস্ট', 'Weekly model test'), 30, p: Priority.high);
    } else {
      add(TaskKind.practice, Tr('অনুশীলন: ${c1.title.bn}', 'Practice: ${c1.title.en}'), 20, s: s1, c: c1);
    }
    final (s2, c2) = chapters[(cursor + 1) % chapters.length];
    add(TaskKind.revision, Tr('রিভিশন: ${c2.title.bn}', 'Revise: ${c2.title.en}'), 20, s: s2, c: c2, p: Priority.low);
    add(TaskKind.flashcards, const Tr('ফ্ল্যাশকার্ড রিভিউ', 'Flashcard review'), 10, p: Priority.low);
    cursor++;
  }
  return tasks;
}

@immutable
class PlannerState {
  const PlannerState({required this.tasks, required this.prefs});

  final List<StudyTask> tasks;
  final PlannerPrefs prefs;

  List<StudyTask> on(DateTime day) => tasks.where((t) => dayOf(t.day) == dayOf(day)).toList()..sort((a, b) => a.startMinute.compareTo(b.startMinute));

  List<StudyTask> between(DateTime from, DateTime to) =>
      tasks.where((t) => !dayOf(t.day).isBefore(dayOf(from)) && !dayOf(t.day).isAfter(dayOf(to))).toList();

  int daysToExam(DateTime now) => dayOf(prefs.examDate).difference(dayOf(now)).inDays;

  /// Completion rate over the last [days] days (excluding today's open tasks).
  double? completionRate(DateTime now, {int days = 7}) {
    final past = between(now.subtract(Duration(days: days)), now).where((t) => t.status != TaskStatus.scheduled).toList();
    if (past.isEmpty) return null;
    return past.where((t) => t.status == TaskStatus.done).length / past.length;
  }

  /// Hour (0–23) when the student completes most tasks.
  int? bestHour() {
    final hours = <int, int>{};
    for (final t in tasks.where((t) => t.completedAt != null)) {
      hours.update(t.completedAt!.hour, (v) => v + 1, ifAbsent: () => 1);
    }
    if (hours.isEmpty) return null;
    return (hours.entries.toList()..sort((a, b) => b.value.compareTo(a.value))).first.key;
  }

  StudyTask? nextUp(DateTime now) {
    final upcoming = tasks.where((t) => t.status == TaskStatus.scheduled && !t.start.isBefore(now.subtract(const Duration(hours: 1)))).toList()
      ..sort((a, b) => a.start.compareTo(b.start));
    return upcoming.firstOrNull;
  }
}

/// Study planner: generation, manual editing, completion, rescheduling, missed detection,
/// reminders (in-app notifications) and preferences.
class PlannerController extends Notifier<PlannerState> {
  late JsonCollection<StudyTask> _tasks;
  late LocalStore _store;
  static const _prefsId = 'planner';
  OwnerSync? _sync;
  bool _applyingServer = false;
  Future<void>? _refreshing;

  @override
  PlannerState build() {
    _store = watchStore(ref);
    final remote = ref.watch(remoteProgressProvider);
    _sync = remote == null ? null : OwnerSync(ref.read(apiClientProvider), collection: 'tasks', studentId: remote.studentId);
    ref.onDispose(() => _sync?.dispose());
    final profile = ref.read(studentProfileProvider);
    final prefsJson = _store.get('prefs', _prefsId);
    final prefs = prefsJson == null
        ? PlannerPrefs(examDate: DateTime(profile.examYear, 2, 15), dailyMinutes: max(60, profile.dailyMinutes), targetGpa: profile.targetGpa)
        : PlannerPrefs.fromJson(prefsJson);
    _tasks = JsonCollection<StudyTask>(
      store: _store,
      name: 'planner_tasks',
      fromJson: StudyTask.fromJson,
      toJson: (t) => t.toJson(),
      idOf: (t) => t.id,
      // API mode: the server holds the plan; no generated demo seed.
      seed: () => _sync == null ? _seed(prefs) : const [],
    );
    if (_sync != null) {
      listenSelf((prev, next) {
        if (prev == null || _applyingServer || identical(prev.tasks, next.tasks)) return;
        final now = DateTime.now().toUtc().toIso8601String();
        _sync?.schedule(() => [for (final t in state.tasks) _sync!.merge(t.id, TaskMapper.fields(t), defaults: {'createdAt': now})]);
      });
      Future.microtask(refresh);
    }
    // Anything still scheduled from before today becomes "missed".
    final today = dayOf(DateTime.now());
    final all = _tasks.all();
    final missed = [for (final t in all) if (t.status == TaskStatus.scheduled && dayOf(t.day).isBefore(today)) t.copyWith(status: TaskStatus.missed)];
    if (missed.isNotEmpty) _tasks.upsertAll(missed);
    final byId = {for (final t in all) t.id: t, for (final t in missed) t.id: t};
    return PlannerState(tasks: byId.values.toList(), prefs: prefs);
  }

  /// API mode: the server's tasks replace the local copy (single-flight).
  Future<void> refresh() => _refreshing ??= _refresh().whenComplete(() => _refreshing = null);

  Future<void> _refresh() async {
    if (_sync == null || !ref.mounted) return;
    try {
      final tasks = [for (final t in await _sync!.pull()) TaskMapper.fromApi(t)];
      if (!ref.mounted) return;
      await _store.clearCollection('planner_tasks');
      await _tasks.upsertAll(tasks);
      _applyingServer = true;
      state = PlannerState(tasks: tasks, prefs: state.prefs);
      _applyingServer = false;
    } catch (_) {
      // Offline: keep the cached plan.
    }
  }

  List<StudyTask> _seed(PlannerPrefs prefs) {
    final subjects = _mySubjects();
    final progress = ref.read(learningProgressProvider);
    final now = DateTime.now();
    // Three past days (mixed outcomes) + the coming week.
    final past = generatePlan(subjects: subjects, masteryOf: progress.chapterMastery, prefs: prefs, from: now.subtract(const Duration(days: 3)), days: 3);
    final seeded = <StudyTask>[];
    for (var i = 0; i < past.length; i++) {
      final t = past[i];
      final done = i % 4 != 3;
      seeded.add(t.copyWith(
        status: done ? TaskStatus.done : TaskStatus.missed,
        completedAt: done ? () => t.start.add(Duration(minutes: t.minutes)) : null,
        actualMinutes: done ? t.minutes : null,
        focus: done ? 3 + i % 3 : null,
      ));
    }
    return [...seeded, ...generatePlan(subjects: subjects, masteryOf: progress.chapterMastery, prefs: prefs, from: now, days: 7)];
  }

  List<Subject> _mySubjects() {
    final profile = ref.read(studentProfileProvider);
    return ref.read(curriculumRepositoryProvider).cachedSubjects.where((s) => s.level == profile.level && s.availableFor(profile.group)).toList();
  }

  Future<void> _put(List<StudyTask> changed) async {
    final ids = {for (final t in changed) t.id};
    state = PlannerState(tasks: [...state.tasks.where((t) => !ids.contains(t.id)), ...changed], prefs: state.prefs);
    await _tasks.upsertAll(changed);
  }

  /// Replaces future generated, unfinished tasks with a fresh plan.
  Future<int> regenerate({int days = 7}) async {
    final today = dayOf(DateTime.now());
    final stale = state.tasks.where((t) => t.generated && t.status == TaskStatus.scheduled && !dayOf(t.day).isBefore(today)).toList();
    for (final t in stale) {
      await _tasks.remove(t.id);
    }
    final fresh = generatePlan(subjects: _mySubjects(), masteryOf: ref.read(learningProgressProvider).chapterMastery, prefs: state.prefs, from: DateTime.now(), days: days);
    state = PlannerState(tasks: [...state.tasks.where((t) => !stale.contains(t)), ...fresh], prefs: state.prefs);
    await _tasks.upsertAll(fresh);
    return fresh.length;
  }

  Future<StudyTask> add(StudyTask t) async {
    await _put([t]);
    return t;
  }

  Future<void> update(StudyTask t) => _put([t]);

  Future<void> delete(String id) async {
    state = PlannerState(tasks: state.tasks.where((t) => t.id != id).toList(), prefs: state.prefs);
    await _tasks.remove(id);
  }

  /// Completion modal result: logs study time and XP.
  Future<void> complete(String id, {int? actualMinutes, int? focus}) async {
    final t = state.tasks.firstWhere((x) => x.id == id);
    final mins = actualMinutes ?? t.minutes;
    await _put([t.copyWith(status: TaskStatus.done, completedAt: () => DateTime.now(), actualMinutes: mins, focus: focus)]);
    final kind = switch (t.kind) {
      TaskKind.study => ActivityKind.lesson,
      TaskKind.revision => ActivityKind.lesson,
      TaskKind.practice => ActivityKind.practice,
      TaskKind.exam => ActivityKind.exam,
      TaskKind.flashcards => ActivityKind.flashcards,
    };
    await ref.read(learningProgressProvider.notifier).logActivity(kind, minutes: mins, subjectId: t.subjectId);
  }

  Future<void> reopen(String id) async {
    final t = state.tasks.firstWhere((x) => x.id == id);
    await _put([t.copyWith(status: TaskStatus.scheduled, completedAt: () => null)]);
  }

  /// Move a task to another day/time (drag on the week board, or the reschedule dialog).
  Future<void> reschedule(String id, DateTime day, {int? startMinute}) async {
    final t = state.tasks.firstWhere((x) => x.id == id);
    await _put([t.copyWith(day: dayOf(day), startMinute: startMinute, status: TaskStatus.scheduled)]);
  }

  /// Moves every missed task to the next free days.
  Future<int> rescheduleMissed() async {
    final missed = state.tasks.where((t) => t.status == TaskStatus.missed).toList();
    final today = dayOf(DateTime.now());
    final moved = [
      for (var i = 0; i < missed.length; i++)
        missed[i].copyWith(day: today.add(Duration(days: 1 + i % 3)), status: TaskStatus.scheduled, startMinute: state.prefs.studyTime.startMinute + 120),
    ];
    await _put(moved);
    return moved.length;
  }

  Future<void> setPrefs(PlannerPrefs prefs) async {
    state = PlannerState(tasks: state.tasks, prefs: prefs);
    await _store.put('prefs', _prefsId, prefs.toJson());
  }

  /// Simulated daily reminder: raises an in-app notification for today's first task.
  Future<bool> sendTodayReminder() async {
    final today = state.on(DateTime.now()).where((t) => t.status == TaskStatus.scheduled && t.reminder).toList();
    if (today.isEmpty || !state.prefs.reminders) return false;
    final first = today.first;
    final hh = (first.startMinute ~/ 60).toString().padLeft(2, '0');
    final mm = (first.startMinute % 60).toString().padLeft(2, '0');
    await ref.read(notificationsProvider.notifier).push(AppNotification(
      id: 'plan-${DateTime.now().millisecondsSinceEpoch}',
      category: NotificationCategory.study,
      title: const Tr('আজকের পড়ার রিমাইন্ডার', 'Today’s study reminder'),
      body: Tr('$hh:$mm — ${first.title.bn} (${today.length}টি কাজ)', '$hh:$mm — ${first.title.en} (${today.length} tasks)'),
      createdAt: DateTime.now(),
      route: '/planner',
      audience: 'student',
    ));
    return true;
  }
}

final plannerProvider = NotifierProvider<PlannerController, PlannerState>(PlannerController.new);
