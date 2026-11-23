import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/mock/mock_simulator.dart';
import '../../../core/network/api_exception.dart';
import '../../../mock/seed/curriculum_seed.dart';
import '../domain/curriculum_models.dart';

/// Resolved location of a chapter or topic inside the curriculum tree.
class ChapterRef {
  const ChapterRef(this.subject, this.chapter);

  final Subject subject;
  final Chapter chapter;
}

class TopicRef {
  const TopicRef(this.subject, this.chapter, this.topic);

  final Subject subject;
  final Chapter chapter;
  final Topic topic;
}

/// Curriculum contract. The real implementation will call `GET /curriculum/...`
/// (see contracts/curriculum.schema.json); the UI only sees this interface.
abstract interface class CurriculumRepository {
  Future<List<Subject>> subjects({EducationLevel? level});

  Future<Subject> subject(String id);

  Future<ChapterRef> chapter(String id);

  Future<TopicRef> topic(String id);

  /// Synchronous lookups for already-cached structure (search, labels, tutor context).
  List<Subject> get cachedSubjects;

  ChapterRef? findChapter(String id);

  TopicRef? findTopic(String id);
}

/// Curriculum structure ships with the app, so it is available offline.
class MockCurriculumRepository implements CurriculumRepository {
  MockCurriculumRepository(this._sim, [List<Subject>? subjects]) : _subjects = subjects ?? seedSubjects {
    for (final s in _subjects) {
      for (final c in s.chapters) {
        _chapters[c.id] = ChapterRef(s, c);
        for (final t in c.topics) {
          _topics[t.id] = TopicRef(s, c, t);
        }
      }
    }
  }

  final MockSimulator _sim;
  final List<Subject> _subjects;
  final Map<String, ChapterRef> _chapters = {};
  final Map<String, TopicRef> _topics = {};

  @override
  List<Subject> get cachedSubjects => _subjects;

  @override
  ChapterRef? findChapter(String id) => _chapters[id];

  @override
  TopicRef? findTopic(String id) => _topics[id];

  @override
  Future<List<Subject>> subjects({EducationLevel? level}) => _sim.run(
    () => [for (final s in _subjects) if (level == null || s.level == level) s],
    requiresNetwork: false,
  );

  @override
  Future<Subject> subject(String id) => _sim.run(() {
    for (final s in _subjects) {
      if (s.id == id) return s;
    }
    throw const ApiException.notFound();
  }, requiresNetwork: false);

  @override
  Future<ChapterRef> chapter(String id) =>
      _sim.run(() => _chapters[id] ?? (throw const ApiException.notFound()), requiresNetwork: false);

  @override
  Future<TopicRef> topic(String id) =>
      _sim.run(() => _topics[id] ?? (throw const ApiException.notFound()), requiresNetwork: false);
}

final curriculumRepositoryProvider = Provider<CurriculumRepository>(
  (ref) => MockCurriculumRepository(ref.watch(mockSimulatorProvider)),
);
