import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shikkhaai_mobile/core/l10n/tr.dart';
import 'package:shikkhaai_mobile/features/curriculum/domain/curriculum_models.dart';
import 'package:shikkhaai_mobile/features/progress/application/learning_progress_controller.dart';
import 'package:shikkhaai_mobile/features/question_bank/application/practice_controller.dart';
import 'package:shikkhaai_mobile/features/question_bank/data/question_repository.dart';
import 'package:shikkhaai_mobile/features/question_bank/domain/question.dart';
import 'package:shikkhaai_mobile/features/question_bank/presentation/practice_session_screen.dart';
import 'package:shikkhaai_mobile/mock/seed/curriculum_seed.dart';
import 'package:shikkhaai_mobile/mock/seed/questions_seed.dart';

import '../../helpers/test_app.dart';

void main() {
  group('seed integrity', () {
    final questions = seedQuestions();
    final topicIds = {
      for (final s in seedSubjects)
        for (final c in s.chapters)
          for (final t in c.topics) t.id,
    };

    test('every question points at a real topic and has a non-empty answer', () {
      for (final q in questions) {
        expect(topicIds, contains(q.topicId), reason: q.id);
        expect(q.answer.bn.trim(), isNotEmpty, reason: q.id);
        expect(q.answer.en.trim(), isNotEmpty, reason: q.id);
      }
    });

    test('objective questions are answerable', () {
      for (final q in questions.where((q) => q.type == QuestionType.mcq || q.type == QuestionType.trueFalse)) {
        expect(q.correctIndex, isNotNull, reason: q.id);
        expect(q.correctIndex, lessThan(q.options.length), reason: q.id);
      }
      for (final q in questions.where((q) => q.type == QuestionType.fillBlank)) {
        expect(q.acceptedAnswers, isNotEmpty, reason: q.id);
      }
    });

    test('ids are unique and every fixture is labelled synthetic', () {
      expect(questions.map((q) => q.id).toSet().length, questions.length);
      expect(questions.every((q) => q.synthetic), isTrue);
    });

    test('JSON round trip keeps the question intact', () {
      for (final q in questions) {
        final back = Question.fromJson(q.toJson());
        expect(back.toJson(), q.toJson(), reason: q.id);
      }
    });
  });

  group('filter and search', () {
    final all = seedQuestions();

    test('filters by chapter, type and difficulty', () {
      const f = QuestionFilter(chapterId: 'ssc-phy-p1-c2', types: {QuestionType.mcq}, difficulty: Difficulty.easy);
      final hits = all.where(f.matches).toList();
      expect(hits, isNotEmpty);
      expect(hits.every((q) => q.chapterId == 'ssc-phy-p1-c2' && q.type == QuestionType.mcq && q.difficulty == Difficulty.easy), isTrue);
    });

    test('free-text search matches Bangla and English', () {
      expect(all.where(const QuestionFilter(query: 'acceleration').matches), isNotEmpty);
      expect(all.where(const QuestionFilter(query: 'ত্বরণ').matches), isNotEmpty);
      expect(all.where(const QuestionFilter(query: 'zzzz-nothing').matches), isEmpty);
    });

    test('repository paginates and sorts by frequency', () async {
      final c = testContainer();
      addTearDown(c.dispose);
      final repo = c.read(questionRepositoryProvider);
      final p0 = await repo.search(const QuestionFilter(sort: QuestionSort.frequency), pageSize: 10);
      expect(p0.items.length, 10);
      expect(p0.hasMore, isTrue);
      expect(p0.items.first.frequency >= p0.items.last.frequency, isTrue);
      final p1 = await repo.search(const QuestionFilter(sort: QuestionSort.frequency), page: 1, pageSize: 10);
      expect(p1.items.map((q) => q.id).toSet().intersection(p0.items.map((q) => q.id).toSet()), isEmpty);
    });
  });

  group('practice', () {
    test('quick session draws from the topic first, objective first', () {
      final all = seedQuestions();
      final session = buildPracticeSession(
        request: const PracticeRequest(mode: 'quick', chapterId: 'ssc-phy-p1-c2', topicId: 'ssc-phy-p1-c2-t2'),
        all: all,
        practice: const PracticeState(bookmarks: {}, attempts: [], sets: []),
        masteryOf: (_) => 0,
      );
      expect(session, isNotEmpty);
      expect(session.length, lessThanOrEqualTo(5));
      expect(session.first.topicId, 'ssc-phy-p1-c2-t2');
      expect(session.every((q) => q.chapterId == 'ssc-phy-p1-c2'), isTrue);
    });

    test('daily quiz prefers the weakest topics', () {
      final all = seedQuestions();
      final session = buildPracticeSession(
        request: const PracticeRequest(mode: 'daily'),
        all: all,
        practice: const PracticeState(bookmarks: {}, attempts: [], sets: []),
        masteryOf: (topicId) => topicId.startsWith('ssc-phy-p1-c3') ? 0.0 : 0.9,
        now: DateTime(2026, 11, 23),
      );
      expect(session.length, 5);
      expect(session.where((q) => q.chapterId == 'ssc-phy-p1-c3').length, greaterThanOrEqualTo(3));
    });

    test('recording a wrong answer lists it for reattempt and lowers accuracy', () async {
      final c = testContainer();
      addTearDown(c.dispose);
      final q = seedQuestions().first;
      final before = c.read(learningProgressProvider).topic(q.topicId).attempts;
      await c.read(practiceProvider.notifier).recordAttempt(q, correct: false);
      expect(c.read(practiceProvider).wrongIds, contains(q.id));
      expect(c.read(learningProgressProvider).topic(q.topicId).attempts, before + 1);
      await c.read(practiceProvider.notifier).recordAttempt(q, correct: true);
      expect(c.read(practiceProvider).wrongIds, isNot(contains(q.id)));
    });

    test('bookmarks and sets persist in the store', () async {
      final c = testContainer();
      addTearDown(c.dispose);
      final n = c.read(practiceProvider.notifier);
      await n.toggleBookmark('q-phy-m1');
      final set = await n.createSet('Revision');
      await n.addToSet(set.id, 'q-phy-m2');
      c.invalidate(practiceProvider);
      final s = c.read(practiceProvider);
      expect(s.isBookmarked('q-phy-m1'), isTrue);
      expect(s.sets.single.questionIds, ['q-phy-m2']);
    });
  });

  testWidgets('answering an MCQ shows feedback and records the attempt', (tester) async {
    await tester.pumpWidget(
      testApp(
        const PracticeSessionScreen(
          request: PracticeRequest(mode: 'quick', chapterId: 'ssc-phy-p1-c2', topicId: 'ssc-phy-p1-c2-t2'),
        ),
        lang: AppLanguage.en,
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Question 1/5'), findsOneWidget);
    // q-phy-m1: correct option index 1.
    await tester.tap(find.byKey(const Key('option.1')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('practice.check')));
    await tester.pumpAndSettle();
    expect(find.text('Correct!'), findsOneWidget);
    final container = ProviderScope.containerOf(tester.element(find.byType(PracticeSessionScreen)));
    expect(container.read(practiceProvider).attempts.first.correct, isTrue);
  });
}
