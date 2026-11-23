import 'dart:math';

import '../../features/progress/domain/learning_progress.dart';
import 'curriculum_seed.dart';

/// Believable starting history for the demo student: some SSC science chapters partly
/// studied, a 6-day streak and two weeks of activity. Deterministic (fixed seed).
({List<TopicProgress> topics, List<StudyActivity> activities}) seedProgress([DateTime? now]) {
  final rnd = Random(42);
  final t = now ?? DateTime.now();
  final topics = <TopicProgress>[];
  const studied = {'ssc-phy': 3, 'ssc-chem': 2, 'ssc-hmath': 2, 'ssc-gmath': 3, 'ssc-bio': 1, 'ssc-eng2': 2};
  for (final s in seedSubjects) {
    final chapters = studied[s.id];
    if (chapters == null) continue;
    for (final c in s.chapters.take(chapters)) {
      for (final topic in c.topics) {
        final attempts = rnd.nextInt(12);
        // Physics chapter 3 (force) is deliberately weak to demo weakness detection.
        final skill = c.id.contains('ssc-phy-p1-c3') ? 0.35 : 0.55 + rnd.nextDouble() * 0.4;
        topics.add(TopicProgress(
          topicId: topic.id,
          completed: rnd.nextDouble() < 0.7,
          attempts: attempts,
          correct: (attempts * skill).round(),
          lastStudied: t.subtract(Duration(days: rnd.nextInt(14), hours: rnd.nextInt(12))),
        ));
      }
    }
  }
  final subjects = studied.keys.toList();
  final activities = <StudyActivity>[];
  for (var d = 13; d >= 1; d--) {
    // Days 1–6 ago are continuous (the streak); earlier days have gaps.
    if (d > 6 && rnd.nextDouble() < 0.35) continue;
    final sessions = 1 + rnd.nextInt(3);
    for (var i = 0; i < sessions; i++) {
      final kind = ActivityKind.values[rnd.nextInt(4)];
      final minutes = 10 + rnd.nextInt(40);
      activities.add(StudyActivity(
        id: 'seed-$d-$i',
        kind: kind,
        at: t.subtract(Duration(days: d, hours: rnd.nextInt(8))),
        minutes: minutes,
        xp: minutes * 2,
        subjectId: subjects[rnd.nextInt(subjects.length)],
      ));
    }
  }
  return (topics: topics, activities: activities);
}
