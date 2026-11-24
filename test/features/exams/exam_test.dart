import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shikkhaai_mobile/core/l10n/tr.dart';
import 'package:shikkhaai_mobile/core/mock/mock_simulator.dart';
import 'package:shikkhaai_mobile/core/storage/local_store.dart';
import 'package:shikkhaai_mobile/core/theme/app_theme.dart';
import 'package:shikkhaai_mobile/features/exams/application/exam_controller.dart';
import 'package:shikkhaai_mobile/features/exams/application/exam_scoring.dart';
import 'package:shikkhaai_mobile/features/exams/domain/exam.dart';
import 'package:shikkhaai_mobile/features/exams/presentation/exam_result_screen.dart';
import 'package:shikkhaai_mobile/features/exams/presentation/exam_take_screen.dart';
import 'package:shikkhaai_mobile/features/notifications/application/notifications_controller.dart';
import 'package:shikkhaai_mobile/features/progress/application/learning_progress_controller.dart';
import 'package:shikkhaai_mobile/features/progress/domain/learning_progress.dart';
import 'package:shikkhaai_mobile/features/question_bank/application/practice_controller.dart';
import 'package:shikkhaai_mobile/mock/seed/questions_seed.dart';

import '../../helpers/test_app.dart';

void main() {
  final all = {for (final q in seedQuestions()) q.id: q};

  ExamAttempt attemptWith(Map<String, ExamAnswer> answers, {bool negative = false}) => ExamAttempt(
    id: 't',
    type: ExamType.custom,
    title: const Tr.same('t'),
    config: ExamConfig(negativeMarking: negative, questionCount: answers.length),
    questionIds: answers.keys.toList(),
    startedAt: DateTime(2026),
    answers: answers,
  );

  group('scoring', () {
    test('MCQ right, wrong and blank', () {
      final r = scoreAttempt(
        attemptWith({
          'q-phy-m1': const ExamAnswer(choice: 1), // correct
          'q-phy-m2': const ExamAnswer(choice: 0), // wrong
          'q-phy-f1': const ExamAnswer(), // blank
        }),
        all,
        timeSpentSeconds: 60,
      );
      expect(r.count(Outcome.correct), 1);
      expect(r.count(Outcome.incorrect), 1);
      expect(r.count(Outcome.unanswered), 1);
      expect(r.score, 1);
      expect(r.totalMarks, 3);
      expect(r.accuracy, 0.5);
    });

    test('negative marking deducts a quarter per wrong answer but never goes below zero', () {
      final r = scoreAttempt(
        attemptWith({'q-phy-m1': const ExamAnswer(choice: 1), 'q-phy-m2': const ExamAnswer(choice: 0)}, negative: true),
        all,
        timeSpentSeconds: 60,
      );
      expect(r.score, 0.75);
      final allWrong = scoreAttempt(attemptWith({'q-phy-m2': const ExamAnswer(choice: 0)}, negative: true), all, timeSpentSeconds: 1);
      expect(allWrong.score, 0);
    });

    test('fill-in-the-blank accepts variants case-insensitively', () {
      final r = scoreAttempt(attemptWith({'q-eng-a2': const ExamAnswer(text: ' OF ')}), all, timeSpentSeconds: 1);
      expect(r.count(Outcome.correct), 1);
    });

    test('written answers get a bounded simulated estimate that rewards key terms', () {
      final q = all['q-phy-m4']!;
      final good = estimateWrittenMarks(q, const ExamAnswer(text: 'The train travels 25 m before stopping'));
      final poor = estimateWrittenMarks(q, const ExamAnswer(text: 'I do not know'));
      expect(good, greaterThan(poor));
      expect(good, lessThanOrEqualTo(q.marks.toDouble()));
      final r = scoreAttempt(attemptWith({'q-phy-m4': const ExamAnswer(text: 'train 25 m')}), all, timeSpentSeconds: 1);
      expect(r.hasEstimates, isTrue);
    });

    test('grades follow the SSC/HSC scale', () {
      expect(gradeFor(0.85).grade, 'A+');
      expect(gradeFor(0.72).grade, 'A');
      expect(gradeFor(0.33).grade, 'D');
      expect(gradeFor(0.2).grade, 'F');
    });

    test('weak topics are those under 50 percent', () {
      final r = scoreAttempt(
        attemptWith({'q-phy-m1': const ExamAnswer(choice: 1), 'q-phy-f1': const ExamAnswer(choice: 0)}),
        all,
        timeSpentSeconds: 1,
      );
      expect(weakTopics(r, all), ['ssc-phy-p1-c3-t1']);
    });
  });

  group('exam controller', () {
    test('seeds templates and past results', () {
      final c = testContainer();
      addTearDown(c.dispose);
      final s = c.read(examProvider);
      expect(s.templates.length, greaterThanOrEqualTo(8));
      expect(s.finished.length, 3);
      expect(s.finished.every((a) => a.result != null), isTrue);
    });

    test('submitting updates practice history, mastery, study log and notifications', () async {
      final c = testContainer();
      addTearDown(c.dispose);
      final ctl = c.read(examProvider.notifier);
      final attempt = await ctl.start(config: const ExamConfig(chapterIds: ['ssc-phy-p1-c2'], questionCount: 3, randomize: false));
      expect(attempt.questionIds, hasLength(3));
      final q = all[attempt.questionIds.first]!;
      final topicBefore = c.read(learningProgressProvider).topic(q.topicId).attempts;
      final xpBefore = c.read(learningProgressProvider).totalXp;
      final unreadBefore = c.read(unreadNotificationCountProvider);

      await ctl.answer(attempt.id, q.id, ExamAnswer(choice: q.correctIndex, text: 'answer'));
      await ctl.saveRemaining(attempt.id, attempt.config.timeLimitMinutes * 60 - 90);
      final done = await ctl.submit(attempt.id);

      expect(done.status, AttemptStatus.submitted);
      expect(done.result!.timeSpentSeconds, 90);
      expect(c.read(examProvider).inProgress, isEmpty);
      expect(c.read(practiceProvider).attempts.first.context, 'exam');
      expect(c.read(learningProgressProvider).topic(q.topicId).attempts, topicBefore + 1);
      expect(c.read(learningProgressProvider).totalXp, greaterThan(xpBefore));
      expect(c.read(learningProgressProvider).activities.first.kind, ActivityKind.exam);
      expect(c.read(unreadNotificationCountProvider), unreadBefore + 1);
    });

    test('in-progress attempts survive a restart (session recovery)', () async {
      final store = MemoryLocalStore();
      final c1 = testContainer(store: store);
      final a = await c1.read(examProvider.notifier).start(config: const ExamConfig(questionCount: 2));
      await c1.read(examProvider.notifier).answer(a.id, a.questionIds.first, const ExamAnswer(choice: 0, markedForReview: true));
      await c1.read(examProvider.notifier).saveRemaining(a.id, 321);
      c1.dispose();

      final c2 = testContainer(store: store);
      addTearDown(c2.dispose);
      final recovered = c2.read(examProvider).attempt(a.id)!;
      expect(recovered.status, AttemptStatus.inProgress);
      expect(recovered.remainingSeconds, 321);
      expect(recovered.answerFor(a.questionIds.first).markedForReview, isTrue);
    });

    test('scheduled institution exams cannot start early', () async {
      final c = testContainer();
      addTearDown(c.dispose);
      final ctl = c.read(examProvider.notifier);
      final tpl = c.read(examProvider).templates.first;
      final future = ExamTemplate(id: 'x', type: ExamType.teacherAssigned, title: const Tr.same('x'), config: tpl.config, scheduledAt: DateTime.now().add(const Duration(days: 1)));
      expect(() => ctl.start(template: future), throwsA(anything));
    });
  });

  testWidgets('student takes an exam, submits and sees the result', (tester) async {
    final store = MemoryLocalStore();
    final container = ProviderContainer(
      retry: (_, _) => null,
      overrides: [localStoreProvider.overrideWithValue(store), mockLatencyProvider.overrideWithValue(Duration.zero)],
    );
    addTearDown(container.dispose);
    final attempt = await container.read(examProvider.notifier).start(
      config: const ExamConfig(chapterIds: ['ssc-phy-p1-c2'], types: {}, questionCount: 2, randomize: false),
    );
    final router = GoRouter(
      initialLocation: '/exam/${attempt.id}',
      routes: [
        GoRoute(path: '/exam/:id', builder: (_, s) => ExamTakeScreen(attemptId: s.pathParameters['id']!)),
        GoRoute(path: '/student/practice/results/:id', builder: (_, s) => ExamResultScreen(attemptId: s.pathParameters['id']!)),
      ],
    );
    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(
        theme: AppTheme.light(useGoogleFonts: false),
        locale: AppLanguage.en.locale,
        supportedLocales: const [Locale('bn', 'BD'), Locale('en', 'US')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        routerConfig: router,
      ),
    ));
    await tester.pumpAndSettle();
    expect(find.text('Instructions'), findsOneWidget);
    await tester.tap(find.byKey(const Key('exam.begin')));
    await tester.pump();

    final first = all[attempt.questionIds.first]!;
    await tester.tap(find.byKey(Key('exam.option.${first.correctIndex}')));
    await tester.pump(const Duration(milliseconds: 50));
    expect(container.read(examProvider).attempt(attempt.id)!.answeredCount, 1);

    await tester.tap(find.byKey(const Key('exam.submit')));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.widgetWithText(FilledButton, 'Submit').last);
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 300));

    expect(container.read(examProvider).attempt(attempt.id)!.status, AttemptStatus.submitted);
    expect(find.byKey(const Key('result.score')), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });
}
