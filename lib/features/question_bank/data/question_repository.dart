import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/mock/json_collection.dart';
import '../../../core/mock/mock_simulator.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/storage/local_store.dart';
import '../../../mock/seed/questions_seed.dart';
import '../domain/question.dart';

/// Question bank contract. The real adapter will call `GET /questions` with the same
/// filter fields as query parameters (see contracts/question.schema.json).
abstract interface class QuestionRepository {
  Future<QuestionPage> search(QuestionFilter filter, {int page = 0, int pageSize = 20});

  Future<Question> question(String id);

  /// Same topic first, then same chapter, excluding [q].
  Future<List<Question>> related(Question q, {int limit = 4});

  Future<void> report(String questionId, String reason);

  /// Adds a question (teacher authoring, AI-generated quizzes). Returns the stored copy.
  Future<Question> save(Question q);

  /// Synchronous snapshot of everything available locally (exam builder, search, coverage).
  List<Question> get cached;
}

class MockQuestionRepository implements QuestionRepository {
  MockQuestionRepository(this._sim, LocalStore store)
    : _collection = JsonCollection<Question>(
        store: store,
        name: 'questions',
        fromJson: Question.fromJson,
        toJson: (q) => q.toJson(),
        idOf: (q) => q.id,
        seed: seedQuestions,
      ),
      _reports = store;

  final MockSimulator _sim;
  final JsonCollection<Question> _collection;
  final LocalStore _reports;

  @override
  List<Question> get cached => _collection.all();

  List<Question> _sorted(List<Question> items, QuestionSort sort) {
    final out = List.of(items);
    switch (sort) {
      case QuestionSort.recent:
        out.sort((a, b) => (b.createdAt ?? DateTime(2000)).compareTo(a.createdAt ?? DateTime(2000)));
      case QuestionSort.difficulty:
        out.sort((a, b) => b.difficulty.rank.compareTo(a.difficulty.rank));
      case QuestionSort.frequency:
        out.sort((a, b) => b.frequency.compareTo(a.frequency));
    }
    return out;
  }

  @override
  Future<QuestionPage> search(QuestionFilter filter, {int page = 0, int pageSize = 20}) => _sim.run(() {
    final all = _sorted(cached.where(filter.matches).toList(), filter.sort);
    final start = (page * pageSize).clamp(0, all.length);
    final end = (start + pageSize).clamp(0, all.length);
    return QuestionPage(items: all.sublist(start, end), total: all.length, page: page, pageSize: pageSize);
  }, requiresNetwork: false, latencyFactor: 0.6);

  @override
  Future<Question> question(String id) =>
      _sim.run(() => _collection.get(id) ?? (throw const ApiException.notFound()), requiresNetwork: false);

  @override
  Future<List<Question>> related(Question q, {int limit = 4}) => _sim.run(() {
    final others = cached.where((o) => o.id != q.id).toList();
    final sameTopic = others.where((o) => o.topicId == q.topicId);
    final sameChapter = others.where((o) => o.chapterId == q.chapterId && o.topicId != q.topicId);
    return [...sameTopic, ...sameChapter].take(limit).toList();
  }, requiresNetwork: false, latencyFactor: 0.4);

  @override
  Future<void> report(String questionId, String reason) => _sim.run(() async {
    final id = 'r-${DateTime.now().microsecondsSinceEpoch}';
    await _reports.put('question_reports', id, {
      'id': id,
      'questionId': questionId,
      'reason': reason,
      'at': DateTime.now().toIso8601String(),
      'status': 'open',
    });
  });

  @override
  Future<Question> save(Question q) => _sim.run(() => _collection.upsert(q), requiresNetwork: false);
}

final questionRepositoryProvider = Provider<QuestionRepository>(
  (ref) => MockQuestionRepository(ref.watch(mockSimulatorProvider), watchStore(ref)),
);
