import 'package:flutter_test/flutter_test.dart';
import 'package:shikkhaai_mobile/core/network/network_providers.dart';
import 'package:shikkhaai_mobile/features/flashcards/application/flashcards_controller.dart';
import 'package:shikkhaai_mobile/features/flashcards/domain/flashcard.dart';
import 'package:shikkhaai_mobile/features/progress/data/remote_progress.dart';

import '../../helpers/fake_server.dart';
import '../../helpers/test_app.dart';

void main() {
  test('API mode: decks and cards load from the server and edits push the whole list', () async {
    final server = FakeServer({
      '/decks/u-student-1': [
        {'id': 'deck-1', 'name': 'গতি ও বল', 'color': '#ff0000', 'source': 'incorrect', 'offline': true, 'createdAt': '2026-11-04T03:00:00.000Z'},
      ],
      '/cards/u-student-1': [
        {'id': 'fc-1', 'deckId': 'deck-1', 'front': 'ত্বরণ?', 'back': 'বেগ পরিবর্তনের হার', 'ease': 2.3, 'intervalDays': 4, 'repetitions': 2, 'lapses': 0, 'dueAt': '2026-11-24T03:00:00.000Z', 'hint': 'web-only hint', 'createdAt': '2026-11-04T03:00:00.000Z'},
      ],
    });
    final c = testContainer(overrides: [
      apiClientProvider.overrideWithValue(server.client),
      remoteProgressProvider.overrideWithValue(RemoteProgress(server.client, 'u-student-1')),
    ]);
    c.read(flashcardsProvider);
    await c.read(flashcardsProvider.notifier).refresh();
    final s = c.read(flashcardsProvider);
    expect(s.decks.single.source, DeckSource.mistakes);
    expect(s.cards.single.srs.repetitions, 2);
    expect(s.cards.single.srs.due, isNotNull);

    await c.read(flashcardsProvider.notifier).createDeck('নতুন', cards: const [('প্রশ্ন', 'উত্তর')]);
    await Future<void>.delayed(const Duration(milliseconds: 1300));
    final decks = server.data['/decks/u-student-1']!;
    final cards = server.data['/cards/u-student-1']!;
    expect(decks.map((d) => d['name']), containsAll(['গতি ও বল', 'নতুন']));
    expect(decks.firstWhere((d) => d['id'] == 'deck-1')['color'], '#ff0000'); // web field kept
    expect(cards.firstWhere((x) => x['id'] == 'fc-1')['hint'], 'web-only hint');
    expect(cards.length, 2);
  });
}
