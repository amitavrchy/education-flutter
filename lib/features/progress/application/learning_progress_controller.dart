import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/mock/json_collection.dart';
import '../../../core/storage/local_store.dart';
import '../../../mock/seed/progress_seed.dart';
import '../../curriculum/domain/curriculum_models.dart';
import '../domain/learning_progress.dart';

@immutable
class LearningState {
  const LearningState({required this.topics, required this.activities});

  final Map<String, TopicProgress> topics;

  /// Newest first.
  final List<StudyActivity> activities;

  TopicProgress topic(String id) => topics[id] ?? TopicProgress(topicId: id);

  double chapterMastery(Chapter c) =>
      c.topics.isEmpty ? 0 : c.topics.fold<double>(0, (s, t) => s + topic(t.id).mastery) / c.topics.length;

  double chapterCompletion(Chapter c) =>
      c.topics.isEmpty ? 0 : c.topics.where((t) => topic(t.id).completed).length / c.topics.length;

  double subjectMastery(Subject s) {
    final all = [for (final c in s.chapters) ...c.topics];
    return all.isEmpty ? 0 : all.fold<double>(0, (sum, t) => sum + topic(t.id).mastery) / all.length;
  }

  double subjectCompletion(Subject s) {
    final all = [for (final c in s.chapters) ...c.topics];
    return all.isEmpty ? 0 : all.where((t) => topic(t.id).completed).length / all.length;
  }

  int get totalXp => activities.fold(0, (s, a) => s + a.xp);

  int get streak => computeStreak(activities);

  int minutesOn(DateTime day) =>
      activities.where((a) => dayOf(a.at) == dayOf(day)).fold(0, (s, a) => s + a.minutes);

  /// Minutes per day for the last [days] days, oldest first.
  List<int> recentMinutes({int days = 7, DateTime? now}) {
    final today = dayOf(now ?? DateTime.now());
    return [for (var i = days - 1; i >= 0; i--) minutesOn(today.subtract(Duration(days: i)))];
  }

  int get practicedQuestions => topics.values.fold(0, (s, t) => s + t.attempts);

  double? get overallAccuracy {
    final attempts = practicedQuestions;
    if (attempts == 0) return null;
    return topics.values.fold<int>(0, (s, t) => s + t.correct) / attempts;
  }
}

class LearningProgressController extends Notifier<LearningState> {
  late JsonCollection<TopicProgress> _topics;
  late JsonCollection<StudyActivity> _activities;
  ({List<TopicProgress> topics, List<StudyActivity> activities})? _seed;

  ({List<TopicProgress> topics, List<StudyActivity> activities}) get _seedData => _seed ??= seedProgress();

  @override
  LearningState build() {
    final store = watchStore(ref);
    _seed = null;
    _topics = JsonCollection<TopicProgress>(
      store: store,
      name: 'topic_progress',
      fromJson: TopicProgress.fromJson,
      toJson: (t) => t.toJson(),
      idOf: (t) => t.topicId,
      seed: () => _seedData.topics,
    );
    _activities = JsonCollection<StudyActivity>(
      store: store,
      name: 'activities',
      fromJson: StudyActivity.fromJson,
      toJson: (a) => a.toJson(),
      idOf: (a) => a.id,
      seed: () => _seedData.activities,
    );
    final activities = _activities.all()..sort((a, b) => b.at.compareTo(a.at));
    return LearningState(topics: {for (final t in _topics.all()) t.topicId: t}, activities: activities);
  }

  Future<void> _saveTopic(TopicProgress t) async {
    state = LearningState(topics: {...state.topics, t.topicId: t}, activities: state.activities);
    await _topics.upsert(t);
  }

  Future<void> setTopicCompleted(String topicId, {bool completed = true}) =>
      _saveTopic(state.topic(topicId).copyWith(completed: completed, lastStudied: DateTime.now()));

  /// Records one practice/exam answer against a topic.
  Future<void> recordAnswer(String topicId, {required bool correct}) {
    final t = state.topic(topicId);
    return _saveTopic(
      t.copyWith(attempts: t.attempts + 1, correct: t.correct + (correct ? 1 : 0), lastStudied: DateTime.now()),
    );
  }

  Future<void> logActivity(ActivityKind kind, {required int minutes, int? xp, String? subjectId}) async {
    final now = DateTime.now();
    final activity = StudyActivity(
      id: '${kind.name}-${now.microsecondsSinceEpoch}',
      kind: kind,
      at: now,
      minutes: minutes,
      xp: xp ?? minutes * 2,
      subjectId: subjectId,
    );
    state = LearningState(topics: state.topics, activities: [activity, ...state.activities]);
    await _activities.upsert(activity);
  }
}

final learningProgressProvider = NotifierProvider<LearningProgressController, LearningState>(
  LearningProgressController.new,
);
