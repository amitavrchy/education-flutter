import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/mock/json_collection.dart';
import '../../../core/network/network_providers.dart';
import '../../../core/network/owner_sync.dart';
import '../../../core/storage/local_store.dart';
import '../../progress/application/learning_progress_controller.dart';
import '../../progress/data/remote_progress.dart';
import '../data/question_repository.dart';
import '../domain/question.dart';

/// One answer to one question, from practice or an exam.
@immutable
class QuestionAttempt {
  const QuestionAttempt({required this.id, required this.questionId, required this.correct, required this.at, this.context = 'practice'});

  factory QuestionAttempt.fromJson(Map<String, dynamic> j) => QuestionAttempt(
    id: j['id'] as String,
    questionId: j['questionId'] as String,
    correct: j['correct'] as bool,
    at: DateTime.parse(j['at'] as String),
    context: j['context'] as String? ?? 'practice',
  );

  final String id;
  final String questionId;
  final bool correct;
  final DateTime at;

  /// 'practice' or 'exam'.
  final String context;

  Map<String, dynamic> toJson() => {'id': id, 'questionId': questionId, 'correct': correct, 'at': at.toIso8601String(), 'context': context};
}

/// A named personal practice set.
@immutable
class PracticeSet {
  const PracticeSet({required this.id, required this.name, required this.questionIds, required this.createdAt});

  factory PracticeSet.fromJson(Map<String, dynamic> j) => PracticeSet(
    id: j['id'] as String,
    name: j['name'] as String,
    questionIds: List<String>.from(j['questionIds'] as List),
    createdAt: DateTime.parse(j['createdAt'] as String),
  );

  final String id;
  final String name;
  final List<String> questionIds;
  final DateTime createdAt;

  PracticeSet copyWith({String? name, List<String>? questionIds}) =>
      PracticeSet(id: id, name: name ?? this.name, questionIds: questionIds ?? this.questionIds, createdAt: createdAt);

  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'questionIds': questionIds, 'createdAt': createdAt.toIso8601String()};

  /// The web's `practiceSets` record (its `kind` and `updatedAt` are kept by the merge).
  factory PracticeSet.fromApi(Map<String, dynamic> j) => PracticeSet(
    id: j['id'] as String,
    name: j['name'] as String? ?? '',
    questionIds: [for (final q in j['questionIds'] as List? ?? const []) q as String],
    createdAt: DateTime.tryParse(j['createdAt'] as String? ?? '')?.toLocal() ?? DateTime.now(),
  );

  Map<String, dynamic> apiFields() => {'name': name, 'questionIds': questionIds, 'createdAt': createdAt.toUtc().toIso8601String()};
}

@immutable
class PracticeState {
  const PracticeState({required this.bookmarks, required this.attempts, required this.sets});

  final Set<String> bookmarks;

  /// Newest first.
  final List<QuestionAttempt> attempts;
  final List<PracticeSet> sets;

  bool isBookmarked(String id) => bookmarks.contains(id);

  /// Latest result per question.
  Map<String, bool> get latestResult {
    final out = <String, bool>{};
    for (final a in attempts) {
      out.putIfAbsent(a.questionId, () => a.correct);
    }
    return out;
  }

  /// Questions whose most recent attempt was wrong (the "reattempt" list).
  List<String> get wrongIds => [for (final e in latestResult.entries) if (!e.value) e.key];

  int attemptsFor(String questionId) => attempts.where((a) => a.questionId == questionId).length;
}

/// Bookmarks, practice history and personal sets. Recording an answer also updates
/// topic mastery in [learningProgressProvider], so practice feeds analytics.
class PracticeController extends Notifier<PracticeState> {
  late JsonCollection<QuestionAttempt> _attempts;
  late JsonCollection<PracticeSet> _sets;
  late LocalStore _store;

  static const _bookmarkCollection = 'bookmarks';

  /// API mode: personal sets sync with the web's `practiceSets`.
  OwnerSync? _setSync;
  bool _setsLoaded = false;
  bool _applyingServer = false;

  @override
  PracticeState build() {
    _store = watchStore(ref);
    final remote = ref.watch(remoteProgressProvider);
    _setSync = remote == null ? null : OwnerSync(ref.read(apiClientProvider), collection: 'practice-sets', studentId: remote.studentId);
    _setsLoaded = false;
    ref.onDispose(() => _setSync?.dispose());
    if (_setSync != null) {
      listenSelf((prev, next) {
        if (prev == null || _applyingServer || !_setsLoaded || identical(prev.sets, next.sets)) return;
        _setSync?.schedule(_setRecords);
      });
    }
    _attempts = JsonCollection<QuestionAttempt>(
      store: _store,
      name: 'question_attempts',
      fromJson: QuestionAttempt.fromJson,
      toJson: (a) => a.toJson(),
      idOf: (a) => a.id,
    );
    _sets = JsonCollection<PracticeSet>(
      store: _store,
      name: 'practice_sets',
      fromJson: PracticeSet.fromJson,
      toJson: (s) => s.toJson(),
      idOf: (s) => s.id,
    );
    final bookmarks = {for (final b in _store.all(_bookmarkCollection)) b['questionId'] as String};
    final attempts = _attempts.all()..sort((a, b) => b.at.compareTo(a.at));
    final sets = _sets.all()..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return PracticeState(bookmarks: bookmarks, attempts: attempts, sets: sets);
  }

  Future<bool> toggleBookmark(String questionId) async {
    final next = Set.of(state.bookmarks);
    final added = next.add(questionId);
    if (!added) next.remove(questionId);
    state = PracticeState(bookmarks: next, attempts: state.attempts, sets: state.sets);
    final remote = ref.read(remoteProgressProvider);
    if (added) {
      var serverId = _store.get(_bookmarkCollection, questionId)?['serverId'] as String?;
      if (remote != null) {
        final stem = ref.read(questionRepositoryProvider).cached.where((q) => q.id == questionId).firstOrNull?.stem.bn ?? questionId;
        try {
          serverId = await remote.addBookmark(questionId, title: stem.length > 80 ? '${stem.substring(0, 80)}…' : stem);
        } catch (_) {
          // Offline: kept locally, pushed on the next sync.
        }
      }
      await _store.put(_bookmarkCollection, questionId, {'questionId': questionId, 'at': DateTime.now().toIso8601String(), 'serverId': ?serverId});
    } else {
      final serverId = _store.get(_bookmarkCollection, questionId)?['serverId'] as String?;
      await _store.delete(_bookmarkCollection, questionId);
      if (remote != null && serverId != null) {
        try {
          await remote.removeBookmark(serverId);
        } catch (_) {}
      }
    }
    return added;
  }

  /// API mode: server question bookmarks replace the local set; local-only ones are pushed.
  Future<void> syncBookmarks() async {
    final remote = ref.read(remoteProgressProvider);
    if (remote == null) return;
    try {
      final server = await remote.questionBookmarks();
      for (final b in _store.all(_bookmarkCollection)) {
        final qid = b['questionId'] as String;
        if (b['serverId'] == null && !server.containsKey(qid)) server[qid] = await remote.addBookmark(qid, title: qid);
      }
      await _store.clearCollection(_bookmarkCollection);
      await _store.putAll(_bookmarkCollection, {for (final e in server.entries) e.key: {'questionId': e.key, 'serverId': e.value, 'at': DateTime.now().toIso8601String()}});
      if (ref.mounted) state = PracticeState(bookmarks: server.keys.toSet(), attempts: state.attempts, sets: state.sets);
    } catch (_) {
      // Offline: keep the local bookmarks.
    }
  }

  Future<void> recordAttempt(Question q, {required bool correct, String context = 'practice'}) async {
    final now = DateTime.now();
    final attempt = QuestionAttempt(id: 'a-${now.microsecondsSinceEpoch}', questionId: q.id, correct: correct, at: now, context: context);
    state = PracticeState(bookmarks: state.bookmarks, attempts: [attempt, ...state.attempts], sets: state.sets);
    await _attempts.upsert(attempt);
    await ref.read(learningProgressProvider.notifier).recordAnswer(q.topicId, correct: correct);
    final remote = ref.read(remoteProgressProvider);
    if (remote != null) {
      try {
        await remote.recordAttempt(q.id, correct: correct, context: context);
      } catch (_) {
        // Offline: the local attempt stays; the next refresh reconciles.
      }
    }
  }

  List<Map<String, dynamic>> _setRecords() {
    final now = DateTime.now().toUtc().toIso8601String();
    return [for (final s in state.sets) {..._setSync!.merge(s.id, s.apiFields(), defaults: {'kind': 'manual'}), 'updatedAt': now}];
  }

  /// API mode: the server's sets replace the local ones; sets made offline are added and pushed.
  Future<void> syncSets() async {
    final sync = _setSync;
    if (sync == null) return;
    try {
      final server = [for (final r in await sync.pull()) PracticeSet.fromApi(r)];
      if (!ref.mounted) return;
      final serverIds = {for (final s in server) s.id};
      final localOnly = _setsLoaded ? const <PracticeSet>[] : [for (final s in state.sets) if (!serverIds.contains(s.id)) s];
      final sets = [...server, ...localOnly]..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      await _store.clearCollection('practice_sets');
      await _sets.upsertAll(sets);
      _applyingServer = true;
      state = PracticeState(bookmarks: state.bookmarks, attempts: state.attempts, sets: sets);
      _applyingServer = false;
      _setsLoaded = true;
      if (localOnly.isNotEmpty) {
        sync.schedule(_setRecords);
        await sync.flush();
      }
    } catch (_) {
      // Offline: keep the local sets.
    }
  }

  /// API mode: the server's attempt history replaces the local one.
  Future<void> replaceAttempts(List<QuestionAttempt> attempts) async {
    await syncBookmarks();
    await syncSets();
    await _store.clearCollection('question_attempts');
    await _attempts.upsertAll(attempts);
    state = PracticeState(bookmarks: state.bookmarks, attempts: [...attempts]..sort((a, b) => b.at.compareTo(a.at)), sets: state.sets);
  }

  Future<PracticeSet> createSet(String name, {List<String> questionIds = const []}) async {
    final set = PracticeSet(id: 'set-${DateTime.now().microsecondsSinceEpoch}', name: name, questionIds: questionIds, createdAt: DateTime.now());
    state = PracticeState(bookmarks: state.bookmarks, attempts: state.attempts, sets: [set, ...state.sets]);
    await _sets.upsert(set);
    return set;
  }

  Future<void> addToSet(String setId, String questionId) async {
    final set = state.sets.firstWhere((s) => s.id == setId);
    if (set.questionIds.contains(questionId)) return;
    await _saveSet(set.copyWith(questionIds: [...set.questionIds, questionId]));
  }

  Future<void> removeFromSet(String setId, String questionId) async {
    final set = state.sets.firstWhere((s) => s.id == setId);
    await _saveSet(set.copyWith(questionIds: set.questionIds.where((id) => id != questionId).toList()));
  }

  Future<void> renameSet(String setId, String name) async =>
      _saveSet(state.sets.firstWhere((s) => s.id == setId).copyWith(name: name));

  Future<void> deleteSet(String setId) async {
    state = PracticeState(bookmarks: state.bookmarks, attempts: state.attempts, sets: state.sets.where((s) => s.id != setId).toList());
    await _sets.remove(setId);
  }

  Future<void> _saveSet(PracticeSet set) async {
    state = PracticeState(
      bookmarks: state.bookmarks,
      attempts: state.attempts,
      sets: [for (final s in state.sets) s.id == set.id ? set : s],
    );
    await _sets.upsert(set);
  }
}

final practiceProvider = NotifierProvider<PracticeController, PracticeState>(PracticeController.new);

/// What a practice session draws from (see [buildPracticeSession]).
@immutable
class PracticeRequest {
  const PracticeRequest({this.mode = 'chapter', this.subjectId, this.chapterId, this.topicId, this.setId});

  final String mode;
  final String? subjectId;
  final String? chapterId;
  final String? topicId;
  final String? setId;

  @override
  bool operator ==(Object other) =>
      other is PracticeRequest &&
      other.mode == mode &&
      other.subjectId == subjectId &&
      other.chapterId == chapterId &&
      other.topicId == topicId &&
      other.setId == setId;

  @override
  int get hashCode => Object.hash(mode, subjectId, chapterId, topicId, setId);
}

/// Picks the questions for a session. Pure, so it is unit-tested.
///
/// - `quick`: up to 5 from the topic, topped up from the chapter
/// - `daily`: 5 from the weakest topics (by mastery), deterministic per day
/// - `mixed`: 10 random questions across subjects
/// - `wrong`: questions last answered wrong
/// - `bookmarks` / `set`: saved questions
/// - default (`chapter`): up to 10 from the subject/chapter scope
List<Question> buildPracticeSession({
  required PracticeRequest request,
  required List<Question> all,
  required PracticeState practice,
  required double Function(String topicId) masteryOf,
  DateTime? now,
}) {
  final today = now ?? DateTime.now();
  List<Question> objectiveFirst(Iterable<Question> qs) =>
      [...qs.where((q) => q.type.isObjective), ...qs.where((q) => !q.type.isObjective)];

  switch (request.mode) {
    case 'quick':
      final topic = all.where((q) => q.topicId == request.topicId);
      final chapter = all.where((q) => q.chapterId == request.chapterId && q.topicId != request.topicId);
      return objectiveFirst([...topic, ...chapter]).take(5).toList();
    case 'daily':
      final rnd = Random(today.year * 1000 + today.month * 40 + today.day);
      final ranked = List.of(all)..shuffle(rnd);
      ranked.sort((a, b) => masteryOf(a.topicId).compareTo(masteryOf(b.topicId)));
      return objectiveFirst(ranked.take(12)).take(5).toList();
    case 'mixed':
      return (List.of(all)..shuffle(Random(today.millisecondsSinceEpoch))).take(10).toList();
    case 'wrong':
      final ids = practice.wrongIds.toSet();
      return all.where((q) => ids.contains(q.id)).toList();
    case 'bookmarks':
      return all.where((q) => practice.bookmarks.contains(q.id)).toList();
    case 'set':
      final set = practice.sets.where((s) => s.id == request.setId).firstOrNull;
      if (set == null) return const [];
      return [for (final id in set.questionIds) ...all.where((q) => q.id == id)];
    default:
      final scoped = all.where(
        (q) =>
            (request.subjectId == null || q.subjectId == request.subjectId) &&
            (request.chapterId == null || q.chapterId == request.chapterId) &&
            (request.topicId == null || q.topicId == request.topicId),
      );
      return objectiveFirst(scoped).take(10).toList();
  }
}

final practiceSessionProvider = FutureProvider.autoDispose.family<List<Question>, PracticeRequest>((ref, request) async {
  final repo = ref.watch(questionRepositoryProvider);
  // Goes through the repository once so loading and error states are real.
  await repo.search(const QuestionFilter(), pageSize: 1);
  final progress = ref.read(learningProgressProvider);
  return buildPracticeSession(
    request: request,
    all: repo.cached,
    practice: ref.read(practiceProvider),
    masteryOf: (id) => progress.topic(id).mastery,
  );
});
