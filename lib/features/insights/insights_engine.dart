import 'dart:math' as math;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/l10n/tr.dart';
import '../../core/network/network_providers.dart';
import '../../core/storage/local_store.dart';
import '../../mock/seed/curriculum_seed.dart';
import '../curriculum/domain/curriculum_models.dart';
import '../exams/application/exam_controller.dart';
import '../flashcards/application/flashcards_controller.dart';
import '../notifications/application/notifications_controller.dart';
import '../notifications/domain/app_notification.dart';
import '../planner/application/planner_controller.dart';
import '../profile/application/student_profile_controller.dart';
import '../progress/application/learning_progress_controller.dart';
import '../progress/data/remote_progress.dart';
import '../progress/domain/learning_progress.dart';
import '../question_bank/application/practice_controller.dart';
import '../question_bank/data/question_repository.dart';

DateTime _day(DateTime d) => DateTime(d.year, d.month, d.day);

/// One topic with its mastery, for heatmaps and gap lists.
class TopicCell {
  const TopicCell(this.subject, this.chapter, this.topic, this.progress);

  final Subject subject;
  final Chapter chapter;
  final Topic topic;
  final TopicProgress progress;

  double get mastery => progress.mastery;
  bool get started => progress.attempts > 0 || progress.completed;
}

/// A step in the weakness-to-mastery path (ADP-13).
enum PathStep {
  lesson(Tr('পাঠ আবার পড়ো', 'Re-read the lesson'), Icons.menu_book_outlined),
  practice(Tr('১০টি প্রশ্ন অনুশীলন', 'Practise 10 questions'), Icons.quiz_outlined),
  flashcards(Tr('ফ্ল্যাশকার্ডে রিভিশন', 'Revise with flashcards'), Icons.style_outlined),
  quiz(Tr('ছোট কুইজে যাচাই', 'Check with a short quiz'), Icons.fact_check_outlined);

  const PathStep(this.label, this.icon);

  final Tr label;
  final IconData icon;
}

/// Everything the adaptive analytics screen shows (web §19, ADP-01..24).
class AnalyticsData {
  const AnalyticsData({
    required this.subjects,
    required this.cells,
    required this.weeklyAccuracy,
    required this.byDifficulty,
    required this.mistakes,
    required this.gaps,
    required this.prerequisites,
    required this.revisionDue,
    required this.sequence,
    required this.minutes28,
    required this.thisWeekMinutes,
    required this.lastWeekMinutes,
    required this.thisWeekAccuracy,
    required this.lastWeekAccuracy,
    required this.suggestedDailyMinutes,
    required this.examTrend,
  });

  final List<Subject> subjects;
  final List<TopicCell> cells;

  /// Accuracy (0–1, null without answers) for the last 4 weeks, oldest first.
  final List<double?> weeklyAccuracy;

  /// (difficulty, answered, accuracy).
  final List<(Difficulty, int, double?)> byDifficulty;

  /// Topics with the most wrong answers (common mistakes).
  final List<(TopicCell, int wrong)> mistakes;

  /// Topics never touched in chapters the student has started (knowledge gaps).
  final List<TopicCell> gaps;

  /// (chapter, prerequisite chapter, prerequisite mastery) where the prerequisite is weak.
  final List<(Chapter, Chapter, double)> prerequisites;

  /// Studied topics not revisited for a week, weakest first.
  final List<TopicCell> revisionDue;

  /// Recommended next chapters, prerequisites first (ADP-14).
  final List<(Subject, Chapter)> sequence;

  /// Minutes per day for the last 28 days, oldest first (consistency graph).
  final List<int> minutes28;
  final int thisWeekMinutes;
  final int lastWeekMinutes;
  final double? thisWeekAccuracy;
  final double? lastWeekAccuracy;

  /// Personalised study adjustment (ADP-16).
  final int suggestedDailyMinutes;

  /// Exam percentages, oldest first.
  final List<double> examTrend;

  List<TopicCell> get weakest => [for (final c in cells) if (c.progress.attempts >= 2) c]..sort((a, b) => a.mastery.compareTo(b.mastery));

  List<TopicCell> get strongest => [for (final c in cells) if (c.progress.attempts >= 2) c]..sort((a, b) => b.mastery.compareTo(a.mastery));

  int get activeDays28 => minutes28.where((m) => m > 0).length;
}

final analyticsProvider = Provider<AnalyticsData>((ref) {
  final p = ref.watch(learningProgressProvider);
  final attempts = ref.watch(practiceProvider).attempts;
  final bank = {for (final q in ref.watch(questionRepositoryProvider).cached) q.id: q};
  final exams = ref.watch(examProvider).finished;
  final profile = ref.watch(studentProfileProvider);
  final plannerMinutes = ref.watch(plannerProvider.select((s) => s.prefs.dailyMinutes));
  final now = DateTime.now();
  final today = _day(now);
  final subjects = [for (final s in seedSubjects) if (s.level == profile.level) s];
  final cells = [
    for (final s in subjects)
      for (final c in s.chapters)
        for (final t in c.topics) TopicCell(s, c, t, p.topic(t.id)),
  ];
  final byTopic = {for (final c in cells) c.topic.id: c};

  double? acc(Iterable<QuestionAttempt> list) {
    final l = list.toList();
    return l.isEmpty ? null : l.where((a) => a.correct).length / l.length;
  }

  final weekly = [
    for (var w = 3; w >= 0; w--)
      acc(attempts.where((a) => !a.at.isBefore(today.subtract(Duration(days: 7 * (w + 1) - 1))) && a.at.isBefore(today.subtract(Duration(days: 7 * w - 1))))),
  ];
  final byDifficulty = [
    for (final d in Difficulty.values)
      () {
        final list = attempts.where((a) => bank[a.questionId]?.difficulty == d);
        return (d, list.length, acc(list));
      }(),
  ];
  final wrong = <String, int>{};
  for (final a in attempts.where((a) => !a.correct)) {
    final topicId = bank[a.questionId]?.topicId;
    if (topicId != null && byTopic.containsKey(topicId)) wrong.update(topicId, (v) => v + 1, ifAbsent: () => 1);
  }
  final mistakes = [for (final e in wrong.entries) (byTopic[e.key]!, e.value)]..sort((a, b) => b.$2.compareTo(a.$2));
  final startedChapters = {for (final c in cells) if (c.started) c.chapter.id};
  final gaps = [for (final c in cells) if (startedChapters.contains(c.chapter.id) && !c.started) c];
  final chapterById = {for (final s in subjects) for (final c in s.chapters) c.id: c};
  final prerequisites = <(Chapter, Chapter, double)>[
    for (final s in subjects)
      for (final c in s.chapters)
        for (final pre in c.prerequisiteIds)
          if (chapterById[pre] case final pc? when p.chapterMastery(pc) < 0.5 && (startedChapters.contains(c.id) || p.chapterCompletion(c) > 0)) (c, pc, p.chapterMastery(pc)),
  ];
  final revisionDue = [
    for (final c in cells)
      if (c.started && c.progress.lastStudied != null && now.difference(c.progress.lastStudied!).inDays >= 7) c,
  ]..sort((a, b) => a.mastery.compareTo(b.mastery));
  // Sequencing: unfinished chapters whose prerequisites are reasonably mastered, high relevance first.
  final sequence = <(Subject, Chapter)>[
    for (final s in subjects)
      for (final c in s.chapters)
        if (p.chapterCompletion(c) < 1 && c.prerequisiteIds.every((id) => chapterById[id] == null || p.chapterMastery(chapterById[id]!) >= 0.4)) (s, c),
  ]..sort((a, b) {
      final weak = (profile.weakSubjectIds.contains(b.$1.id) ? 1 : 0) - (profile.weakSubjectIds.contains(a.$1.id) ? 1 : 0);
      if (weak != 0) return weak;
      final r = a.$2.relevance.index.compareTo(b.$2.relevance.index);
      return r != 0 ? r : a.$2.number.compareTo(b.$2.number);
    });
  final minutes28 = [for (var d = 27; d >= 0; d--) p.minutesOn(today.subtract(Duration(days: d)))];
  final thisWeek = minutes28.sublist(21).fold(0, (a, b) => a + b);
  final lastWeek = minutes28.sublist(14, 21).fold(0, (a, b) => a + b);
  final avgDaily = thisWeek / 7;
  final target = math.max(profile.dailyMinutes, plannerMinutes);
  final suggested = avgDaily < target * 0.6 ? math.max(20, (avgDaily * 1.25 / 5).round() * 5) : (weekly.last != null && weekly.last! < 0.6 ? target + 15 : target);
  return AnalyticsData(
    subjects: subjects,
    cells: cells,
    weeklyAccuracy: weekly,
    byDifficulty: byDifficulty,
    mistakes: mistakes,
    gaps: gaps,
    prerequisites: prerequisites,
    revisionDue: revisionDue,
    sequence: sequence,
    minutes28: minutes28,
    thisWeekMinutes: thisWeek,
    lastWeekMinutes: lastWeek,
    thisWeekAccuracy: weekly.last,
    lastWeekAccuracy: weekly[2],
    suggestedDailyMinutes: suggested,
    examTrend: [for (final e in exams.reversed) e.result!.percent * 100],
  );
});

// ───────────────────────── Gamification (web §25) ─────────────────────────

class BadgeDef {
  const BadgeDef(this.id, this.icon, this.title, this.how, this.xp);

  final String id;
  final IconData icon;
  final Tr title;
  final Tr how;
  final int xp;
}

const badgeDefs = [
  BadgeDef('first-step', Icons.flag_outlined, Tr('প্রথম পদক্ষেপ', 'First step'), Tr('প্রথমবার পড়া', 'Study for the first time'), 10),
  BadgeDef('streak-3', Icons.local_fire_department_outlined, Tr('৩ দিনের ধারা', '3-day streak'), Tr('টানা ৩ দিন পড়ো', 'Study 3 days in a row'), 20),
  BadgeDef('streak-7', Icons.local_fire_department, Tr('৭ দিনের ধারা', '7-day streak'), Tr('টানা ৭ দিন পড়ো', 'Study 7 days in a row'), 50),
  BadgeDef('q-100', Icons.quiz, Tr('১০০ প্রশ্ন', '100 questions'), Tr('১০০টি প্রশ্ন অনুশীলন', 'Practise 100 questions'), 50),
  BadgeDef('exam-1', Icons.assignment_turned_in, Tr('প্রথম পরীক্ষা', 'First exam'), Tr('একটি পরীক্ষা শেষ করো', 'Finish an exam'), 20),
  BadgeDef('exam-80', Icons.military_tech, Tr('৮০% ক্লাব', '80% club'), Tr('পরীক্ষায় ৮০%+ পাও', 'Score 80%+ in an exam'), 40),
  BadgeDef('chapter-1', Icons.menu_book, Tr('অধ্যায় জয়', 'Chapter conquered'), Tr('একটি অধ্যায়ের সব টপিক শেষ করো', 'Finish every topic in a chapter'), 30),
  BadgeDef('level-5', Icons.workspace_premium, Tr('লেভেল ৫', 'Level 5'), Tr('লেভেল ৫-এ পৌঁছাও', 'Reach level 5'), 0),
  BadgeDef('cards-50', Icons.style, Tr('ফ্ল্যাশকার্ড অভ্যাস', 'Flashcard habit'), Tr('৫০টি কার্ড শেখো', 'Learn 50 cards'), 30),
  BadgeDef('goal-5', Icons.task_alt, Tr('লক্ষ্যভেদী', 'Goal getter'), Tr('৫ দিন দৈনিক লক্ষ্য পূরণ', 'Meet the daily goal on 5 days'), 30),
];

class Mission {
  const Mission(this.title, this.progress, this.xp);

  final Tr title;
  final double progress;
  final int xp;

  bool get done => progress >= 1;
}

class FriendChallenge {
  const FriendChallenge({required this.id, required this.friend, required this.goal, required this.target, required this.friendProgress, required this.endsAt, required this.startedAt});

  factory FriendChallenge.fromJson(Map<String, dynamic> j) => FriendChallenge(
    id: j['id'] as String,
    friend: j['friend'] as String,
    goal: j['goal'] as String,
    target: j['target'] as int,
    friendProgress: j['friendProgress'] as int,
    endsAt: DateTime.parse(j['endsAt'] as String),
    startedAt: DateTime.parse(j['startedAt'] as String),
  );

  final String id;
  final String friend;

  /// `minutes` | `questions`
  final String goal;
  final int target;
  final int friendProgress;
  final DateTime endsAt;
  final DateTime startedAt;

  Map<String, dynamic> toJson() => {
    'id': id,
    'friend': friend,
    'goal': goal,
    'target': target,
    'friendProgress': friendProgress,
    'endsAt': endsAt.toIso8601String(),
    'startedAt': startedAt.toIso8601String(),
  };
}

class GamificationData {
  const GamificationData({
    required this.xp,
    required this.points,
    required this.streak,
    required this.earned,
    required this.missions,
    required this.challenges,
    required this.milestones,
    required this.goalDays,
    required this.chaptersCompleted,
    required this.history,
    required this.unseen,
    required this.friendChallenges,
    required this.myMinutesSince,
    required this.myQuestionsSince,
  });

  final int xp;

  /// Study points: one per minute studied plus ten per finished topic (GAM-02).
  final int points;
  final int streak;

  /// Badge id → when it was first seen as earned.
  final Map<String, DateTime> earned;
  final List<Mission> missions;

  /// Daily learning challenges (GAM-06).
  final List<Mission> challenges;

  /// Monthly milestones (GAM-08).
  final List<Mission> milestones;

  /// Days in the last 30 on which the daily goal was met (GAM-10).
  final int goalDays;
  final int chaptersCompleted;

  /// XP history (GAM-15), newest first.
  final List<StudyActivity> history;

  /// Badges earned but not yet celebrated (GAM-14).
  final List<BadgeDef> unseen;
  final List<FriendChallenge> friendChallenges;
  final int Function(DateTime since) myMinutesSince;
  final int Function(DateTime since) myQuestionsSince;

  /// Motivational line based on the numbers (GAM-16).
  Tr get motivation {
    if (streak >= 7) return Tr('দারুণ! টানা $streak দিন — এই ধারা ধরে রাখো।', 'Amazing! $streak days in a row — keep it going.');
    if (streak >= 2) return const Tr('ভালো চলছে — আজ পড়লে ধারা আরও লম্বা হবে।', "You're on a roll — study today to extend your streak.");
    if (xp == 0) return const Tr('প্রথম টপিকটা শুরু করো — প্রথম ব্যাজ অপেক্ষা করছে!', 'Start your first topic — your first badge is waiting!');
    return const Tr('আজ ১৫ মিনিট পড়লেই নতুন ধারা শুরু হবে।', 'Just 15 minutes today starts a new streak.');
  }
}

/// Persisted gamification state: celebrated badges and friend challenges.
class GameStore {
  const GameStore(this.seen, this.challenges);

  final Map<String, DateTime> seen;
  final List<FriendChallenge> challenges;
}

class GamificationController extends Notifier<GameStore> {
  static const _col = 'gamification';
  late LocalStore _store;

  @override
  GameStore build() {
    _store = watchStore(ref);
    final d = _store.get(_col, 'me');
    return GameStore(
      {for (final e in (d?['seen'] as Map? ?? const {}).entries) e.key as String: DateTime.parse(e.value as String)},
      [for (final c in d?['challenges'] as List? ?? const []) FriendChallenge.fromJson((c as Map).cast())],
    );
  }

  Future<void> _save(GameStore s) async {
    state = s;
    await _store.put(_col, 'me', {
      'seen': {for (final e in s.seen.entries) e.key: e.value.toIso8601String()},
      'challenges': [for (final c in s.challenges) c.toJson()],
    });
  }

  /// Marks badges as celebrated and raises a reward notification for each (GAM-17).
  Future<void> celebrate(List<BadgeDef> badges) async {
    if (badges.isEmpty) return;
    final now = DateTime.now();
    await _save(GameStore({...state.seen, for (final b in badges) b.id: now}, state.challenges));
    for (final b in badges) {
      await ref.read(notificationsProvider.notifier).push(AppNotification(
        id: 'badge-${b.id}',
        category: NotificationCategory.achievement,
        title: Tr('নতুন ব্যাজ: ${b.title.bn}', 'New badge: ${b.title.en}'),
        body: b.how,
        createdAt: now,
        audience: 'student',
        route: '/achievements',
      ));
    }
  }

  Future<void> startChallenge(String friend, String goal, int target, int days) => _save(GameStore(state.seen, [
    FriendChallenge(
      id: 'fc-${DateTime.now().microsecondsSinceEpoch}',
      friend: friend,
      goal: goal,
      target: target,
      friendProgress: (target * (0.3 + (friend.length % 5) / 10)).round(),
      endsAt: DateTime.now().add(Duration(days: days)),
      startedAt: DateTime.now(),
    ),
    ...state.challenges,
  ]));

  Future<void> removeChallenge(String id) => _save(GameStore(state.seen, state.challenges.where((c) => c.id != id).toList()));
}

/// API mode: the server's XP, points, streak and badges (`GET /progress/:id/gamification`).
/// Refetched when new study activity arrives; null with the mock.
final serverGamificationProvider = FutureProvider<ServerGamification?>((ref) async {
  final remote = ref.watch(remoteProgressProvider);
  if (remote == null) return null;
  ref.watch(learningProgressProvider.select((p) => p.activities.length));
  final res = await ref.read(apiClientProvider).get('/progress/${remote.studentId}/gamification', parse: (d) => (d! as Map).cast<String, dynamic>());
  return ServerGamification.fromJson(res.data);
});

class ServerGamification {
  const ServerGamification({required this.xp, required this.points, required this.streak, required this.badges});

  factory ServerGamification.fromJson(Map<String, dynamic> j) => ServerGamification(
    xp: (j['xp'] as num?)?.round() ?? 0,
    points: (j['points'] as num?)?.round() ?? 0,
    streak: ((j['streak'] as Map?)?['current'] as num?)?.round() ?? 0,
    badges: {
      for (final b in j['badges'] as List? ?? const [])
        ?_badgeIds[(b as Map)['id']]: DateTime.tryParse(b['earnedAt'] as String? ?? '') ?? DateTime.now(),
    },
  );

  /// Server badge ids → the app's badge ids (badges the app doesn't show are ignored).
  static const _badgeIds = {
    'first-steps': 'first-step',
    'first-step': 'first-step',
    'streak-3': 'streak-3',
    'streak-7': 'streak-7',
    'questions-100': 'q-100',
    'exam-1': 'exam-1',
    'chapter-1': 'chapter-1',
    'cards-50': 'cards-50',
  };

  final int xp;
  final int points;
  final int streak;
  final Map<String, DateTime> badges;
}

final gamificationStoreProvider = NotifierProvider<GamificationController, GameStore>(GamificationController.new);

final gamificationProvider = Provider<GamificationData>((ref) {
  final p = ref.watch(learningProgressProvider);
  final exams = ref.watch(examProvider).finished;
  final cards = ref.watch(flashcardsProvider);
  final practice = ref.watch(practiceProvider);
  final daily = ref.watch(plannerProvider.select((s) => s.prefs.dailyMinutes));
  final store = ref.watch(gamificationStoreProvider);
  final server = ref.watch(serverGamificationProvider).value;
  final level = ref.watch(studentProfileProvider.select((s) => s.level));
  final now = DateTime.now();
  final today = _day(now);
  final chapters = [for (final s in seedSubjects) if (s.level == level) ...s.chapters];
  final chaptersDone = chapters.where((c) => c.topics.isNotEmpty && p.chapterCompletion(c) >= 1).length;
  final topicsDone = p.topics.values.where((t) => t.completed).length;
  final goalDays = [for (var d = 0; d < 30; d++) p.minutesOn(today.subtract(Duration(days: d)))].where((m) => daily > 0 && m >= daily).length;
  final lvl = levelFor(server?.xp ?? p.totalXp);
  final conditions = <String, bool>{
    'first-step': p.activities.isNotEmpty,
    'streak-3': p.streak >= 3,
    'streak-7': p.streak >= 7,
    'q-100': p.practicedQuestions >= 100,
    'exam-1': exams.isNotEmpty,
    'exam-80': exams.any((e) => e.result!.percent >= 0.8),
    'chapter-1': chaptersDone > 0,
    'level-5': lvl.level >= 5,
    'cards-50': cards.learned >= 50,
    'goal-5': goalDays >= 5,
  };
  // Badges the server awarded count as earned too (with the server's date).
  for (final id in server?.badges.keys ?? const <String>[]) {
    conditions[id] = true;
  }
  final earned = <String, DateTime>{
    for (final b in badgeDefs)
      if (conditions[b.id] ?? false) b.id: server?.badges[b.id] ?? store.seen[b.id] ?? now,
  };
  final unseen = [for (final b in badgeDefs) if ((conditions[b.id] ?? false) && !store.seen.containsKey(b.id)) b];
  final weekStart = today.subtract(const Duration(days: 6));
  final monthStart = DateTime(now.year, now.month);
  final weekMinutes = p.recentMinutes().fold(0, (a, b) => a + b);
  final weekKinds = {for (final a in p.activities.where((a) => !a.at.isBefore(weekStart))) a.kind};
  final weekExams = exams.where((e) => !(e.submittedAt ?? e.startedAt).isBefore(weekStart)).length;
  final todayAttempts = practice.attempts.where((a) => _day(a.at) == today).length;
  final monthMinutes = p.activities.where((a) => !a.at.isBefore(monthStart)).fold(0, (s, a) => s + a.minutes);
  final monthExams = exams.where((e) => !(e.submittedAt ?? e.startedAt).isBefore(monthStart)).length;
  final monthTopics = p.topics.values.where((t) => t.completed && (t.lastStudied?.isAfter(monthStart) ?? false)).length;
  int minutesSince(DateTime since) => p.activities.where((a) => !a.at.isBefore(since)).fold(0, (s, a) => s + a.minutes);
  int questionsSince(DateTime since) => practice.attempts.where((a) => !a.at.isBefore(since)).length;
  return GamificationData(
    xp: server?.xp ?? p.totalXp,
    points: server?.points ?? p.activities.fold(0, (s, a) => s + a.minutes) + topicsDone * 10,
    streak: server?.streak ?? p.streak,
    earned: earned,
    missions: [
      Mission(const Tr('এই সপ্তাহে ১২০ মিনিট পড়ো', 'Study 120 minutes this week'), (weekMinutes / 120).clamp(0.0, 1.0), 50),
      Mission(const Tr('একটি পরীক্ষা দাও', 'Take one exam'), weekExams > 0 ? 1.0 : 0.0, 30),
      Mission(const Tr('৩ ধরনের পড়া করো (পাঠ, অনুশীলন, টিউটর…)', 'Do 3 kinds of study (lesson, practice, tutor…)'), (weekKinds.length / 3).clamp(0.0, 1.0), 30),
    ],
    challenges: [
      Mission(const Tr('আজ ১০টি প্রশ্নের উত্তর দাও', 'Answer 10 questions today'), (todayAttempts / 10).clamp(0.0, 1.0), 15),
      Mission(const Tr('আজকের দৈনিক লক্ষ্য পূরণ করো', "Meet today's daily goal"), daily == 0 ? 0.0 : (p.minutesOn(now) / daily).clamp(0.0, 1.0), 20),
      Mission(const Tr('আজ ৫টি ফ্ল্যাশকার্ড রিভিউ করো', 'Review 5 flashcards today'), (cards.reviewedOn(now) / 5).clamp(0.0, 1.0), 10),
    ],
    milestones: [
      Mission(const Tr('এই মাসে ১০ ঘণ্টা পড়ো', 'Study 10 hours this month'), (monthMinutes / 600).clamp(0.0, 1.0), 100),
      Mission(const Tr('এই মাসে ৪টি পরীক্ষা', '4 exams this month'), (monthExams / 4).clamp(0.0, 1.0), 80),
      Mission(const Tr('এই মাসে ১৫টি টপিক শেষ করো', 'Finish 15 topics this month'), (monthTopics / 15).clamp(0.0, 1.0), 80),
    ],
    goalDays: goalDays,
    chaptersCompleted: chaptersDone,
    history: [...p.activities.where((a) => a.xp > 0)]..sort((a, b) => b.at.compareTo(a.at)),
    unseen: unseen,
    friendChallenges: store.challenges,
    myMinutesSince: minutesSince,
    myQuestionsSince: questionsSince,
  );
});

/// Label for a study activity kind (XP history).
Tr activityLabel(ActivityKind k) => switch (k) {
  ActivityKind.lesson => const Tr('পাঠ শেষ', 'Lesson completed'),
  ActivityKind.practice => const Tr('অনুশীলন', 'Practice'),
  ActivityKind.exam => const Tr('পরীক্ষা', 'Exam'),
  ActivityKind.tutor => const Tr('AI টিউটর', 'AI tutor'),
  ActivityKind.flashcards => const Tr('ফ্ল্যাশকার্ড', 'Flashcards'),
  ActivityKind.notes => const Tr('নোট', 'Notes'),
};
