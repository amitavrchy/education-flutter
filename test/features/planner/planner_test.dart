import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shikkhaai_mobile/core/l10n/tr.dart';
import 'package:shikkhaai_mobile/features/notifications/application/notifications_controller.dart';
import 'package:shikkhaai_mobile/features/planner/application/planner_controller.dart';
import 'package:shikkhaai_mobile/features/planner/domain/study_task.dart';
import 'package:shikkhaai_mobile/features/planner/presentation/planner_screen.dart';
import 'package:shikkhaai_mobile/features/progress/application/learning_progress_controller.dart';
import 'package:shikkhaai_mobile/features/progress/domain/learning_progress.dart';
import 'package:shikkhaai_mobile/mock/seed/curriculum_seed.dart';

import '../../helpers/test_app.dart';

void main() {
  final subjects = seedSubjects.where((s) => s.id == 'ssc-phy' || s.id == 'ssc-chem').toList();
  final prefs = PlannerPrefs(examDate: DateTime(2027, 2, 15), dailyMinutes: 90);

  group('plan generation', () {
    test('fills each day up to the daily budget and puts the weakest chapter first', () {
      final plan = generatePlan(
        subjects: subjects,
        masteryOf: (c) => c.id == 'ssc-chem-p1-c5' ? 0.0 : 0.8,
        prefs: prefs,
        from: DateTime(2026, 11, 23),
      );
      final days = {for (final t in plan) dayOf(t.day)};
      expect(days.length, 7);
      for (final d in days) {
        expect(plan.where((t) => dayOf(t.day) == d).fold<int>(0, (s, t) => s + t.minutes), lessThanOrEqualTo(90));
      }
      final first = plan.first;
      expect(first.kind, TaskKind.study);
      expect(first.chapterId, 'ssc-chem-p1-c5');
      expect(first.priority, Priority.high);
    });

    test('Friday has a model test; tasks do not overlap', () {
      final plan = generatePlan(subjects: subjects, masteryOf: (_) => 0.5, prefs: prefs, from: DateTime(2026, 11, 23));
      final friday = plan.where((t) => t.day.weekday == DateTime.friday);
      expect(friday.any((t) => t.kind == TaskKind.exam), isTrue);
      final monday = plan.where((t) => t.day.weekday == DateTime.monday).toList()..sort((a, b) => a.startMinute.compareTo(b.startMinute));
      for (var i = 1; i < monday.length; i++) {
        expect(monday[i].startMinute, greaterThanOrEqualTo(monday[i - 1].startMinute + monday[i - 1].minutes));
      }
    });

    test('is deterministic', () {
      final a = generatePlan(subjects: subjects, masteryOf: (_) => 0.5, prefs: prefs, from: DateTime(2026, 11, 23));
      final b = generatePlan(subjects: subjects, masteryOf: (_) => 0.5, prefs: prefs, from: DateTime(2026, 11, 23));
      expect([for (final t in a) t.toJson()], [for (final t in b) t.toJson()]);
    });
  });

  group('planner controller', () {
    test('seed has past done/missed tasks and a week ahead', () {
      final c = testContainer();
      addTearDown(c.dispose);
      final s = c.read(plannerProvider);
      expect(s.tasks.any((t) => t.status == TaskStatus.done), isTrue);
      expect(s.tasks.any((t) => t.status == TaskStatus.missed), isTrue);
      expect(s.on(DateTime.now()), isNotEmpty);
      expect(s.completionRate(DateTime.now()), isNotNull);
      expect(s.bestHour(), isNotNull);
    });

    test('complete logs study time; reschedule and missed handling work', () async {
      final c = testContainer();
      addTearDown(c.dispose);
      final ctl = c.read(plannerProvider.notifier);
      final today = c.read(plannerProvider).on(DateTime.now()).first;
      final minutesBefore = c.read(learningProgressProvider).minutesOn(DateTime.now());
      await ctl.complete(today.id, actualMinutes: 25, focus: 5);
      expect(c.read(plannerProvider).tasks.firstWhere((t) => t.id == today.id).status, TaskStatus.done);
      expect(c.read(learningProgressProvider).minutesOn(DateTime.now()), minutesBefore + 25);

      final tomorrow = dayOf(DateTime.now()).add(const Duration(days: 1));
      final other = c.read(plannerProvider).on(DateTime.now()).last;
      await ctl.reschedule(other.id, tomorrow, startMinute: 600);
      final moved = c.read(plannerProvider).tasks.firstWhere((t) => t.id == other.id);
      expect(dayOf(moved.day), tomorrow);
      expect(moved.startMinute, 600);

      final missedBefore = c.read(plannerProvider).tasks.where((t) => t.status == TaskStatus.missed).length;
      expect(await ctl.rescheduleMissed(), missedBefore);
      expect(c.read(plannerProvider).tasks.where((t) => t.status == TaskStatus.missed), isEmpty);
    });

    test('regenerate keeps manual tasks; reminder raises a notification', () async {
      final c = testContainer();
      addTearDown(c.dispose);
      final ctl = c.read(plannerProvider.notifier);
      await ctl.add(StudyTask(id: 'mine', title: const Tr.same('My task'), kind: TaskKind.study, day: dayOf(DateTime.now()), startMinute: 300, minutes: 20));
      await ctl.regenerate();
      expect(c.read(plannerProvider).tasks.any((t) => t.id == 'mine'), isTrue);
      final unread = c.read(unreadNotificationCountProvider);
      expect(await ctl.sendTodayReminder(), isTrue);
      expect(c.read(unreadNotificationCountProvider), unread + 1);
    });
  });

  testWidgets('planner shows countdown and completes a task from the day view', (tester) async {
    late ProviderContainer container;
    await tester.pumpWidget(testApp(
      Consumer(builder: (context, ref, _) {
        container = ProviderScope.containerOf(context);
        return const PlannerScreen();
      }),
      lang: AppLanguage.en,
    ));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('plan.countdown')), findsOneWidget);
    final first = container.read(plannerProvider).on(DateTime.now()).first;
    await tester.tap(find.byKey(Key('task.check.${first.id}')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('complete.save')));
    await tester.pumpAndSettle();
    expect(container.read(plannerProvider).tasks.firstWhere((t) => t.id == first.id).status, TaskStatus.done);
    expect(container.read(learningProgressProvider).activities.first.kind, ActivityKind.lesson);
  });
}
