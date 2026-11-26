import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/tr.dart';
import '../../../core/mock/json_collection.dart';
import '../../../core/storage/local_store.dart';
import '../../../mock/seed/tutor_knowledge_seed.dart';
import '../../ai_tutor/domain/tutor_models.dart';
import '../../curriculum/data/curriculum_repository.dart';
import '../../notes/domain/note.dart';
import '../../progress/application/learning_progress_controller.dart';
import '../../progress/domain/learning_progress.dart';
import '../../question_bank/application/practice_controller.dart';
import '../../question_bank/data/question_repository.dart';
import '../../question_bank/domain/question.dart';
import '../domain/flashcard.dart';
import '../../../core/network/network_providers.dart';
import '../../../core/network/owner_sync.dart';
import '../../progress/data/remote_progress.dart';
import '../data/remote_flashcards.dart';

@immutable
class FlashcardState {
  const FlashcardState({required this.decks, required this.cards});

  final List<Deck> decks;
  final List<Flashcard> cards;

  List<Flashcard> cardsIn(String deckId) => cards.where((c) => c.deckId == deckId).toList();
  List<Flashcard> dueIn(String? deckId, DateTime now) =>
      cards.where((c) => (deckId == null || c.deckId == deckId) && c.srs.isDue(now)).toList()
        ..sort((a, b) => (a.srs.due ?? DateTime(2000)).compareTo(b.srs.due ?? DateTime(2000)));
  int get learned => cards.where((c) => c.srs.isMature).length;
  int reviewedOn(DateTime day) => cards.where((c) => c.srs.lastReviewed != null && dayOf(c.srs.lastReviewed!) == dayOf(day)).length;
}

/// Decks, cards, spaced-repetition reviews and the card generators.
class FlashcardsController extends Notifier<FlashcardState> {
  late JsonCollection<Deck> _decks;
  late JsonCollection<Flashcard> _cards;

  OwnerSync? _deckSync;
  OwnerSync? _cardSync;
  bool _applyingServer = false;

  @override
  FlashcardState build() {
    final store = watchStore(ref);
    final remote = ref.watch(remoteProgressProvider);
    final seed = remote == null ? _seed() : (decks: <Deck>[], cards: <Flashcard>[]);
    _decks = JsonCollection<Deck>(store: store, name: 'fc_decks', fromJson: Deck.fromJson, toJson: (d) => d.toJson(), idOf: (d) => d.id, seed: () => seed.decks);
    _cards = JsonCollection<Flashcard>(store: store, name: 'fc_cards', fromJson: Flashcard.fromJson, toJson: (c) => c.toJson(), idOf: (c) => c.id, seed: () => seed.cards);
    _deckSync = remote == null ? null : OwnerSync(ref.read(apiClientProvider), collection: 'decks', studentId: remote.studentId);
    _cardSync = remote == null ? null : OwnerSync(ref.read(apiClientProvider), collection: 'cards', studentId: remote.studentId);
    ref.onDispose(() {
      _deckSync?.dispose();
      _cardSync?.dispose();
    });
    if (remote != null) {
      // Any local change is pushed (debounced) as the whole deck and card lists.
      listenSelf((prev, next) {
        if (prev == null || _applyingServer) return;
        if (!identical(prev.decks, next.decks)) _deckSync?.schedule(() => [for (final d in state.decks) _deckSync!.merge(d.id, FlashcardMapper.deckFields(d), defaults: FlashcardMapper.deckDefaults)]);
        if (!identical(prev.cards, next.cards)) _cardSync?.schedule(() => [for (final c in state.cards) _cardSync!.merge(c.id, FlashcardMapper.cardFields(c))]);
      });
      Future.microtask(refresh);
    }
    final decks = _decks.all()..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return FlashcardState(decks: decks, cards: _cards.all());
  }

  /// API mode: the server's decks and cards replace the local copy.
  Future<void>? _refreshing;

  /// One refresh at a time; concurrent callers share it.
  Future<void> refresh() => _refreshing ??= _refresh().whenComplete(() => _refreshing = null);

  Future<void> _refresh() async {
    if (_deckSync == null || _cardSync == null || !ref.mounted) return;
    try {
      final decks = [for (final d in await _deckSync!.pull()) FlashcardMapper.deckFrom(d)];
      final cards = [for (final c in await _cardSync!.pull()) FlashcardMapper.cardFrom(c)];
      if (!ref.mounted) return;
      final store = ref.read(localStoreProvider);
      await store.clearCollection('fc_decks');
      await store.clearCollection('fc_cards');
      await _decks.upsertAll(decks);
      await _cards.upsertAll(cards);
      _applyingServer = true;
      state = FlashcardState(decks: decks..sort((a, b) => b.createdAt.compareTo(a.createdAt)), cards: cards);
      _applyingServer = false;
    } catch (_) {
      // Offline: keep the cached decks.
    }
  }

  String _id(String p) => '$p-${DateTime.now().microsecondsSinceEpoch}';

  Future<Deck> createDeck(String title, {DeckSource source = DeckSource.manual, String? subjectId, String? chapterId, List<(String, String)> cards = const [], bool ai = false}) async {
    final now = DateTime.now();
    final deck = Deck(id: _id('d'), title: title, createdAt: now, source: source, subjectId: subjectId, chapterId: chapterId);
    final newCards = [
      for (var i = 0; i < cards.length; i++)
        Flashcard(id: '${deck.id}-c$i', deckId: deck.id, front: cards[i].$1, back: cards[i].$2, createdAt: now, aiGenerated: ai),
    ];
    state = FlashcardState(decks: [deck, ...state.decks], cards: [...state.cards, ...newCards]);
    await _decks.upsert(deck);
    await _cards.upsertAll(newCards);
    return deck;
  }

  Future<void> renameDeck(String id, String title) async {
    final d = state.decks.firstWhere((x) => x.id == id).copyWith(title: title);
    state = FlashcardState(decks: [for (final x in state.decks) x.id == id ? d : x], cards: state.cards);
    await _decks.upsert(d);
  }

  Future<void> deleteDeck(String id) async {
    final removed = state.cardsIn(id);
    state = FlashcardState(decks: state.decks.where((d) => d.id != id).toList(), cards: state.cards.where((c) => c.deckId != id).toList());
    await _decks.remove(id);
    for (final c in removed) {
      await _cards.remove(c.id);
    }
  }

  Future<Flashcard> addCard(String deckId, String front, String back) async {
    final card = Flashcard(id: _id('c'), deckId: deckId, front: front, back: back, createdAt: DateTime.now());
    state = FlashcardState(decks: state.decks, cards: [...state.cards, card]);
    await _cards.upsert(card);
    return card;
  }

  Future<void> _putCard(Flashcard c) async {
    state = FlashcardState(decks: state.decks, cards: [for (final x in state.cards) x.id == c.id ? c : x]);
    await _cards.upsert(c);
  }

  Future<void> editCard(String id, {required String front, required String back}) =>
      _putCard(state.cards.firstWhere((c) => c.id == id).copyWith(front: front, back: back));

  Future<void> toggleBookmark(String id) {
    final c = state.cards.firstWhere((x) => x.id == id);
    return _putCard(c.copyWith(bookmarked: !c.bookmarked));
  }

  Future<void> deleteCard(String id) async {
    state = FlashcardState(decks: state.decks, cards: state.cards.where((c) => c.id != id).toList());
    await _cards.remove(id);
  }

  /// Applies a rating to a card's schedule.
  Future<void> review(String id, Rating rating, {DateTime? now}) {
    final c = state.cards.firstWhere((x) => x.id == id);
    return _putCard(c.copyWith(srs: c.srs.review(rating, now ?? DateTime.now()), reviews: c.reviews + 1));
  }

  /// Logs a finished study session (minutes + XP).
  Future<void> finishSession({required int reviewed, required int minutes, String? subjectId}) =>
      ref.read(learningProgressProvider.notifier).logActivity(ActivityKind.flashcards, minutes: minutes, xp: reviewed * 2, subjectId: subjectId);

  // ── Generators (simulated AI) ──

  List<(String, String)> cardsForChapter(String chapterId, AppLanguage lang) {
    final repo = ref.read(curriculumRepositoryProvider);
    final ch = repo.findChapter(chapterId);
    if (ch == null) return const [];
    final out = <(String, String)>[];
    for (final s in tutorScenarios.where((s) => s.chapterId == chapterId)) {
      out.add(('**${s.title.of(lang)}** — ${lang == AppLanguage.bn ? 'সংজ্ঞা?' : 'definition?'}', s.definition.of(lang)));
      if (s.formula != null) out.add((lang == AppLanguage.bn ? '${s.title.of(lang)} এর সূত্র?' : 'Formula for ${s.title.of(lang)}?', '\$\$${s.formula}\$\$'));
      out.add((s.practiceQ.of(lang), s.practiceA.of(lang)));
    }
    for (final q in ref.read(questionRepositoryProvider).cached.where((q) => q.chapterId == chapterId && q.type.isObjective)) {
      out.add((q.stem.of(lang), q.answer.of(lang)));
    }
    if (out.isEmpty) {
      for (final t in ch.chapter.topics) {
        out.add((t.title.of(lang), t.outcomes.first.text.of(lang)));
      }
    }
    return out;
  }

  /// Bullets "term: meaning" / "**term** — meaning" and headings with their first line.
  static List<(String, String)> cardsFromMarkdown(String md) {
    final out = <(String, String)>[];
    final lines = md.split('\n');
    final pair = RegExp(r'^\s*[-*]\s+\**(.+?)\**\s*(?::|—|–| - )\s*(.+)$');
    for (var i = 0; i < lines.length; i++) {
      final line = lines[i].trim();
      if (line.startsWith('>')) continue;
      final m = pair.firstMatch(line);
      if (m != null && m[2]!.trim().isNotEmpty) {
        out.add((m[1]!.trim(), m[2]!.trim()));
        continue;
      }
      if (line.startsWith('#')) {
        final title = line.replaceFirst(RegExp(r'^#+\s*'), '');
        final next = lines.skip(i + 1).map((l) => l.trim()).firstWhere((l) => l.isNotEmpty && !l.startsWith('#'), orElse: () => '');
        if (title.isNotEmpty && next.isNotEmpty && !next.startsWith('-')) out.add((title, next));
      }
    }
    return out;
  }

  List<(String, String)> cardsFromConversation(Conversation c, AppLanguage lang) {
    final out = <(String, String)>[];
    final seen = <String>{};
    for (final m in c.messages) {
      for (final s in m.sources) {
        if (!seen.add(s.id)) continue;
        final k = tutorScenarios.where((x) => x.id == s.id).firstOrNull;
        if (k == null) continue;
        out.add((k.title.of(lang), k.definition.of(lang)));
        out.add((k.practiceQ.of(lang), k.practiceA.of(lang)));
        out.add((lang == AppLanguage.bn ? 'সাধারণ ভুল: ${k.title.of(lang)}' : 'Common mistake: ${k.title.of(lang)}', k.mistake.of(lang)));
      }
    }
    if (out.isEmpty) {
      for (var i = 0; i + 1 < c.messages.length; i++) {
        if (c.messages[i].isUser && !c.messages[i + 1].isUser) out.add((c.messages[i].text, c.messages[i + 1].text));
      }
    }
    return out;
  }

  List<(String, String)> cardsFromMistakes(AppLanguage lang) {
    final wrong = ref.read(practiceProvider).wrongIds.toSet();
    final List<Question> qs = ref.read(questionRepositoryProvider).cached.where((q) => wrong.contains(q.id)).toList();
    return [for (final q in qs) (q.stem.of(lang), q.answer.of(lang))];
  }

  Future<Deck?> generateFromChapter(String chapterId, AppLanguage lang) async {
    final ch = ref.read(curriculumRepositoryProvider).findChapter(chapterId);
    final cards = cardsForChapter(chapterId, lang);
    if (ch == null || cards.isEmpty) return null;
    return createDeck(ch.chapter.title.of(lang), source: DeckSource.chapter, subjectId: ch.subject.id, chapterId: chapterId, cards: cards, ai: true);
  }

  Future<Deck?> generateFromNote(Note n) async {
    final cards = cardsFromMarkdown(n.body);
    if (cards.isEmpty) return null;
    return createDeck(n.title.isEmpty ? 'Note' : n.title, source: DeckSource.notes, subjectId: n.subjectId, chapterId: n.chapterId, cards: cards);
  }

  Future<Deck?> generateFromConversation(Conversation c, AppLanguage lang) async {
    final cards = cardsFromConversation(c, lang);
    if (cards.isEmpty) return null;
    return createDeck(c.title.isEmpty ? 'AI chat' : c.title, source: DeckSource.conversation, subjectId: c.context.subjectId, cards: cards, ai: true);
  }

  Future<Deck?> generateFromMistakes(AppLanguage lang) async {
    final cards = cardsFromMistakes(lang);
    if (cards.isEmpty) return null;
    return createDeck(lang == AppLanguage.bn ? 'ভুল উত্তরের রিভিশন' : 'Wrong-answer revision', source: DeckSource.mistakes, cards: cards);
  }

  ({List<Deck> decks, List<Flashcard> cards}) _seed() {
    final now = DateTime.now();
    final d1 = Deck(id: 'd-seed-phy', title: 'গতি ও বল — মূল ধারণা', createdAt: now.subtract(const Duration(days: 5)), source: DeckSource.chapter, subjectId: 'ssc-phy', chapterId: 'ssc-phy-p1-c3');
    final d2 = Deck(id: 'd-seed-eng', title: 'English grammar rules', createdAt: now.subtract(const Duration(days: 8)), subjectId: 'ssc-eng2');
    Flashcard card(Deck d, int i, String f, String b, {int reps = 0, double interval = 0, int dueInDays = 0}) => Flashcard(
      id: '${d.id}-$i',
      deckId: d.id,
      front: f,
      back: b,
      createdAt: d.createdAt,
      aiGenerated: d.source == DeckSource.chapter,
      reviews: reps,
      srs: reps == 0
          ? const SrsState()
          : SrsState(repetitions: reps, intervalDays: interval, due: now.add(Duration(days: dueInDays)), lastReviewed: now.subtract(Duration(days: interval.round()))),
    );
    return (
      decks: [d1, d2],
      cards: [
        card(d1, 1, 'নিউটনের দ্বিতীয় সূত্র', r'$F = ma$ — বল = ভর × ত্বরণ', reps: 2, interval: 3, dueInDays: -1),
        card(d1, 2, 'ভরবেগের সূত্র', r'$p = mv$', reps: 3, interval: 8, dueInDays: 4),
        card(d1, 3, 'জড়তা কী?', 'বস্তুর নিজের অবস্থা বজায় রাখার প্রবণতা', reps: 1, interval: 1, dueInDays: 0),
        card(d1, 4, 'ঘর্ষণ কমানোর দুটি উপায়', 'লুব্রিক্যান্ট ব্যবহার, বল বিয়ারিং'),
        card(d1, 5, r'$1\ \text{N}$ = ?', r'$1\ \text{kg m/s}^2$'),
        card(d2, 1, 'Each / every + ?', 'singular verb (Each of them **has**…)', reps: 2, interval: 3, dueInDays: -2),
        card(d2, 2, 'will → (indirect speech)', 'would', reps: 4, interval: 12, dueInDays: 6),
        card(d2, 3, 'Article before "honest"', 'an (silent h)'),
      ],
    );
  }
}

final flashcardsProvider = NotifierProvider<FlashcardsController, FlashcardState>(FlashcardsController.new);
