import 'dart:math';

import 'package:material_ui/material_ui.dart';

import '../../../core/l10n/tr.dart';

enum DeckSource {
  manual(Tr('নিজে তৈরি', 'Made by you'), Icons.edit_outlined),
  chapter(Tr('অধ্যায় থেকে (AI)', 'From chapter (AI)'), Icons.menu_book_outlined),
  notes(Tr('নোট থেকে', 'From notes'), Icons.sticky_note_2_outlined),
  conversation(Tr('AI কথোপকথন থেকে', 'From AI chat'), Icons.smart_toy_outlined),
  mistakes(Tr('ভুল উত্তর থেকে', 'From wrong answers'), Icons.replay);

  const DeckSource(this.label, this.icon);

  final Tr label;
  final IconData icon;
}

@immutable
class Deck {
  const Deck({required this.id, required this.title, required this.createdAt, this.source = DeckSource.manual, this.subjectId, this.chapterId});

  factory Deck.fromJson(Map<String, dynamic> j) => Deck(
    id: j['id'] as String,
    title: j['title'] as String,
    createdAt: DateTime.parse(j['createdAt'] as String),
    source: DeckSource.values.byName(j['source'] as String? ?? 'manual'),
    subjectId: j['subjectId'] as String?,
    chapterId: j['chapterId'] as String?,
  );

  final String id;
  final String title;
  final DateTime createdAt;
  final DeckSource source;
  final String? subjectId;
  final String? chapterId;

  Deck copyWith({String? title}) => Deck(id: id, title: title ?? this.title, createdAt: createdAt, source: source, subjectId: subjectId, chapterId: chapterId);

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'createdAt': createdAt.toIso8601String(),
    'source': source.name,
    'subjectId': subjectId,
    'chapterId': chapterId,
  };
}

/// Review rating. "Again" also serves as "unknown"; "easy" as "known".
enum Rating {
  again(Tr('আবার', 'Again')),
  hard(Tr('কঠিন', 'Hard')),
  good(Tr('ভালো', 'Good')),
  easy(Tr('সহজ', 'Easy'));

  const Rating(this.label);

  final Tr label;
}

/// Spaced-repetition state of one card (simplified SM-2).
@immutable
class SrsState {
  const SrsState({this.ease = 2.5, this.intervalDays = 0, this.repetitions = 0, this.lapses = 0, this.due, this.lastReviewed});

  factory SrsState.fromJson(Map<String, dynamic> j) => SrsState(
    ease: (j['ease'] as num?)?.toDouble() ?? 2.5,
    intervalDays: (j['intervalDays'] as num?)?.toDouble() ?? 0,
    repetitions: j['repetitions'] as int? ?? 0,
    lapses: j['lapses'] as int? ?? 0,
    due: j['due'] == null ? null : DateTime.parse(j['due'] as String),
    lastReviewed: j['lastReviewed'] == null ? null : DateTime.parse(j['lastReviewed'] as String),
  );

  final double ease;
  final double intervalDays;
  final int repetitions;
  final int lapses;

  /// Null = new card, due immediately.
  final DateTime? due;
  final DateTime? lastReviewed;

  bool get isNew => lastReviewed == null;

  /// "Learned" once a card has survived a few days' interval.
  bool get isMature => intervalDays >= 7;

  bool isDue(DateTime now) => due == null || !due!.isAfter(now);

  /// Next state after a review. Deterministic; unit-tested.
  SrsState review(Rating r, DateTime now) {
    switch (r) {
      case Rating.again:
        return SrsState(
          ease: max(1.3, ease - 0.2),
          intervalDays: 0,
          repetitions: 0,
          lapses: lapses + 1,
          due: now.add(const Duration(minutes: 10)),
          lastReviewed: now,
        );
      case Rating.hard:
        final next = max(1.0, intervalDays * 1.2);
        return SrsState(ease: max(1.3, ease - 0.15), intervalDays: next, repetitions: repetitions + 1, lapses: lapses, due: now.add(_days(next)), lastReviewed: now);
      case Rating.good:
      case Rating.easy:
        final base = switch (repetitions) { 0 => 1.0, 1 => 3.0, _ => intervalDays * ease };
        final next = r == Rating.easy ? base * 1.3 : base;
        return SrsState(
          ease: r == Rating.easy ? ease + 0.15 : ease,
          intervalDays: next,
          repetitions: repetitions + 1,
          lapses: lapses,
          due: now.add(_days(next)),
          lastReviewed: now,
        );
    }
  }

  static Duration _days(double d) => Duration(minutes: (d * 24 * 60).round());

  Map<String, dynamic> toJson() => {
    'ease': ease,
    'intervalDays': intervalDays,
    'repetitions': repetitions,
    'lapses': lapses,
    'due': due?.toIso8601String(),
    'lastReviewed': lastReviewed?.toIso8601String(),
  };
}

@immutable
class Flashcard {
  const Flashcard({
    required this.id,
    required this.deckId,
    required this.front,
    required this.back,
    required this.createdAt,
    this.srs = const SrsState(),
    this.bookmarked = false,
    this.reviews = 0,
    this.aiGenerated = false,
  });

  factory Flashcard.fromJson(Map<String, dynamic> j) => Flashcard(
    id: j['id'] as String,
    deckId: j['deckId'] as String,
    front: j['front'] as String,
    back: j['back'] as String,
    createdAt: DateTime.parse(j['createdAt'] as String),
    srs: SrsState.fromJson(j['srs'] as Map<String, dynamic>? ?? const {}),
    bookmarked: j['bookmarked'] as bool? ?? false,
    reviews: j['reviews'] as int? ?? 0,
    aiGenerated: j['aiGenerated'] as bool? ?? false,
  );

  final String id;
  final String deckId;

  /// Rich content (markdown + math).
  final String front;
  final String back;
  final DateTime createdAt;
  final SrsState srs;
  final bool bookmarked;
  final int reviews;
  final bool aiGenerated;

  Flashcard copyWith({String? front, String? back, SrsState? srs, bool? bookmarked, int? reviews}) => Flashcard(
    id: id,
    deckId: deckId,
    front: front ?? this.front,
    back: back ?? this.back,
    createdAt: createdAt,
    srs: srs ?? this.srs,
    bookmarked: bookmarked ?? this.bookmarked,
    reviews: reviews ?? this.reviews,
    aiGenerated: aiGenerated,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'deckId': deckId,
    'front': front,
    'back': back,
    'createdAt': createdAt.toIso8601String(),
    'srs': srs.toJson(),
    'bookmarked': bookmarked,
    'reviews': reviews,
    'aiGenerated': aiGenerated,
  };
}
