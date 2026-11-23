import 'package:flutter/foundation.dart';

/// Per-topic learning state. Mastery blends lesson completion with practice accuracy.
@immutable
class TopicProgress {
  const TopicProgress({
    required this.topicId,
    this.completed = false,
    this.attempts = 0,
    this.correct = 0,
    this.lastStudied,
  });

  factory TopicProgress.fromJson(Map<String, dynamic> json) => TopicProgress(
    topicId: json['topicId'] as String,
    completed: json['completed'] as bool? ?? false,
    attempts: json['attempts'] as int? ?? 0,
    correct: json['correct'] as int? ?? 0,
    lastStudied: json['lastStudied'] == null ? null : DateTime.parse(json['lastStudied'] as String),
  );

  final String topicId;
  final bool completed;
  final int attempts;
  final int correct;
  final DateTime? lastStudied;

  double? get accuracy => attempts == 0 ? null : correct / attempts;

  /// 0..1. Finishing the lesson gives 0.3; practice accuracy gives up to 0.7, scaled by how
  /// much evidence there is (full weight from 8 answers).
  double get mastery {
    final lesson = completed ? 0.3 : 0.0;
    final confidence = (attempts / 8).clamp(0.0, 1.0);
    return (lesson + 0.7 * (accuracy ?? 0) * confidence).clamp(0.0, 1.0);
  }

  TopicProgress copyWith({bool? completed, int? attempts, int? correct, DateTime? lastStudied}) => TopicProgress(
    topicId: topicId,
    completed: completed ?? this.completed,
    attempts: attempts ?? this.attempts,
    correct: correct ?? this.correct,
    lastStudied: lastStudied ?? this.lastStudied,
  );

  Map<String, dynamic> toJson() => {
    'topicId': topicId,
    'completed': completed,
    'attempts': attempts,
    'correct': correct,
    'lastStudied': lastStudied?.toIso8601String(),
  };
}

enum ActivityKind { lesson, practice, exam, tutor, flashcards, notes }

/// One logged study session; feeds streaks, weekly charts and XP.
@immutable
class StudyActivity {
  const StudyActivity({
    required this.id,
    required this.kind,
    required this.at,
    required this.minutes,
    required this.xp,
    this.subjectId,
  });

  factory StudyActivity.fromJson(Map<String, dynamic> json) => StudyActivity(
    id: json['id'] as String,
    kind: ActivityKind.values.byName(json['kind'] as String),
    at: DateTime.parse(json['at'] as String),
    minutes: json['minutes'] as int,
    xp: json['xp'] as int,
    subjectId: json['subjectId'] as String?,
  );

  final String id;
  final ActivityKind kind;
  final DateTime at;
  final int minutes;
  final int xp;
  final String? subjectId;

  Map<String, dynamic> toJson() => {
    'id': id,
    'kind': kind.name,
    'at': at.toIso8601String(),
    'minutes': minutes,
    'xp': xp,
    'subjectId': subjectId,
  };
}

DateTime dayOf(DateTime t) => DateTime(t.year, t.month, t.day);

/// Consecutive days with activity ending today (or yesterday, if today is still open).
int computeStreak(Iterable<StudyActivity> activities, {DateTime? now}) {
  final days = {for (final a in activities) dayOf(a.at)};
  var cursor = dayOf(now ?? DateTime.now());
  if (!days.contains(cursor)) cursor = cursor.subtract(const Duration(days: 1));
  var streak = 0;
  while (days.contains(cursor)) {
    streak++;
    cursor = cursor.subtract(const Duration(days: 1));
  }
  return streak;
}

/// Level curve: each level needs 100 XP more than the previous (100, 200, 300…).
({int level, int intoLevel, int forNext}) levelFor(int xp) {
  var level = 1;
  var remaining = xp;
  while (remaining >= level * 100) {
    remaining -= level * 100;
    level++;
  }
  return (level: level, intoLevel: remaining, forNext: level * 100);
}
