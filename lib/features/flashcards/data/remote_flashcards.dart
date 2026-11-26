import '../domain/flashcard.dart';

/// Maps decks and cards between the app and the backend's (web) records.
abstract final class FlashcardMapper {
  static DeckSource sourceOf(String? s) => switch (s) {
    'chapter' || 'ai' => DeckSource.chapter,
    'notes' => DeckSource.notes,
    'conversation' => DeckSource.conversation,
    'incorrect' => DeckSource.mistakes,
    _ => DeckSource.manual,
  };

  static String serverSource(DeckSource s) => switch (s) {
    DeckSource.mistakes => 'incorrect',
    _ => s.name,
  };

  static DateTime? _date(Object? v) => v == null ? null : DateTime.tryParse(v as String);

  static Deck deckFrom(Map<String, dynamic> j) => Deck(
    id: j['id'] as String,
    title: (j['name'] ?? j['title'] ?? '') as String,
    createdAt: _date(j['createdAt']) ?? DateTime.now(),
    source: sourceOf(j['source'] as String?),
    subjectId: j['subjectId'] as String?,
    chapterId: j['chapterId'] as String?,
  );

  static Map<String, dynamic> deckFields(Deck d) => {
    'name': d.title,
    'source': serverSource(d.source),
    'subjectId': d.subjectId,
    'chapterId': d.chapterId,
    'createdAt': d.createdAt.toUtc().toIso8601String(),
  };

  /// Filled only for decks created in the app.
  static const deckDefaults = {'color': '#2563eb', 'offline': false};

  static Flashcard cardFrom(Map<String, dynamic> j) => Flashcard(
    id: j['id'] as String,
    deckId: j['deckId'] as String,
    front: j['front'] as String? ?? '',
    back: j['back'] as String? ?? '',
    createdAt: _date(j['createdAt']) ?? DateTime.now(),
    srs: SrsState(
      ease: (j['ease'] as num?)?.toDouble() ?? 2.5,
      intervalDays: (j['intervalDays'] as num?)?.toDouble() ?? 0,
      repetitions: (j['repetitions'] as num?)?.toInt() ?? 0,
      lapses: (j['lapses'] as num?)?.toInt() ?? 0,
      due: _date(j['dueAt']),
      lastReviewed: _date(j['lastReviewedAt']),
    ),
    bookmarked: j['bookmarked'] as bool? ?? false,
    reviews: (j['reviews'] as num?)?.toInt() ?? 0,
    aiGenerated: j['aiGenerated'] as bool? ?? false,
  );

  static Map<String, dynamic> cardFields(Flashcard c) => {
    'deckId': c.deckId,
    'front': c.front,
    'back': c.back,
    'ease': c.srs.ease,
    'intervalDays': c.srs.intervalDays,
    'repetitions': c.srs.repetitions,
    'lapses': c.srs.lapses,
    'dueAt': c.srs.due?.toUtc().toIso8601String(),
    'lastReviewedAt': c.srs.lastReviewed?.toUtc().toIso8601String(),
    'known': c.srs.isMature,
    'bookmarked': c.bookmarked,
    'reviews': c.reviews,
    'aiGenerated': c.aiGenerated,
    'createdAt': c.createdAt.toUtc().toIso8601String(),
    'updatedAt': DateTime.now().toUtc().toIso8601String(),
  };
}
