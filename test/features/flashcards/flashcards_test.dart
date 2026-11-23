import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shikkhaai_mobile/core/l10n/tr.dart';
import 'package:shikkhaai_mobile/features/ai_tutor/application/tutor_controller.dart';
import 'package:shikkhaai_mobile/features/flashcards/application/flashcards_controller.dart';
import 'package:shikkhaai_mobile/features/flashcards/domain/flashcard.dart';
import 'package:shikkhaai_mobile/features/flashcards/presentation/flashcard_study_screen.dart';
import 'package:shikkhaai_mobile/features/question_bank/application/practice_controller.dart';
import 'package:shikkhaai_mobile/mock/seed/questions_seed.dart';

import '../../helpers/test_app.dart';

void main() {
  final now = DateTime(2026, 11, 23, 10);

  group('spaced repetition', () {
    test('good: 1 day, then 3 days, then interval × ease', () {
      var s = const SrsState();
      s = s.review(Rating.good, now);
      expect(s.intervalDays, 1);
      s = s.review(Rating.good, now);
      expect(s.intervalDays, 3);
      s = s.review(Rating.good, now);
      expect(s.intervalDays, closeTo(7.5, 0.001));
      expect(s.isMature, isTrue);
    });

    test('again resets, lowers ease (min 1.3) and returns in 10 minutes', () {
      var s = const SrsState(ease: 1.4, intervalDays: 10, repetitions: 4);
      s = s.review(Rating.again, now);
      expect(s.repetitions, 0);
      expect(s.ease, 1.3);
      expect(s.lapses, 1);
      expect(s.due, now.add(const Duration(minutes: 10)));
      expect(s.isDue(now.add(const Duration(minutes: 11))), isTrue);
    });

    test('easy grows faster than good; hard grows slower', () {
      const base = SrsState(intervalDays: 3, repetitions: 2);
      final good = base.review(Rating.good, now).intervalDays;
      expect(base.review(Rating.easy, now).intervalDays, greaterThan(good));
      expect(base.review(Rating.hard, now).intervalDays, lessThan(good));
    });

    test('new cards are due immediately', () {
      expect(const SrsState().isDue(now), isTrue);
    });
  });

  group('generators', () {
    test('markdown bullets and headings become cards', () {
      final cards = FlashcardsController.cardsFromMarkdown('## Inertia\nAn object keeps its state.\n- **Force** — push or pull\n- Mass: amount of matter\n> quote: ignored');
      expect(cards, contains(('Inertia', 'An object keeps its state.')));
      expect(cards, contains(('Force', 'push or pull')));
      expect(cards, contains(('Mass', 'amount of matter')));
      expect(cards.length, 3);
    });

    test('chapter, conversation and mistakes decks', () async {
      final c = testContainer();
      addTearDown(c.dispose);
      final ctl = c.read(flashcardsProvider.notifier);
      final chapter = await ctl.generateFromChapter('ssc-phy-p1-c3', AppLanguage.en);
      expect(c.read(flashcardsProvider).cardsIn(chapter!.id).length, greaterThanOrEqualTo(3));

      final conv = c.read(tutorProvider.notifier).byId('c-seed-2')!;
      final fromChat = await ctl.generateFromConversation(conv, AppLanguage.en);
      expect(fromChat!.source, DeckSource.conversation);

      expect(await ctl.generateFromMistakes(AppLanguage.en), isNull);
      await c.read(practiceProvider.notifier).recordAttempt(seedQuestions().first, correct: false);
      final mistakes = await ctl.generateFromMistakes(AppLanguage.en);
      expect(c.read(flashcardsProvider).cardsIn(mistakes!.id), hasLength(1));
    });

    test('due queue spans decks and reviewing removes a card from it', () async {
      final c = testContainer();
      addTearDown(c.dispose);
      final ctl = c.read(flashcardsProvider.notifier);
      final due = c.read(flashcardsProvider).dueIn(null, DateTime.now());
      expect(due.map((x) => x.deckId).toSet().length, 2);
      await ctl.review(due.first.id, Rating.good);
      expect(c.read(flashcardsProvider).dueIn(null, DateTime.now()).any((x) => x.id == due.first.id), isFalse);
    });
  });

  testWidgets('study: flip, rate, finish', (tester) async {
    late ProviderContainer container;
    await tester.pumpWidget(testApp(
      Consumer(builder: (context, ref, _) {
        container = ProviderScope.containerOf(context);
        return const FlashcardStudyScreen(deckId: 'd-seed-eng');
      }),
      lang: AppLanguage.en,
    ));
    await tester.pumpAndSettle();
    final queue = container.read(flashcardsProvider).dueIn('d-seed-eng', DateTime.now());
    expect(find.text('Card 1/${queue.length}'), findsOneWidget);
    for (var i = 0; i < queue.length; i++) {
      await tester.tap(find.byKey(const Key('study.flip')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('rate.good')));
      await tester.pumpAndSettle();
    }
    expect(find.text('Session complete!'), findsWidgets);
    expect(container.read(flashcardsProvider).dueIn('d-seed-eng', DateTime.now()), isEmpty);
  });
}
