import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/env.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/network_providers.dart';
import '../../auth/application/auth_controller.dart';
import '../../question_bank/application/practice_controller.dart';
import '../domain/learning_progress.dart';

/// Learning progress on the education-backend. Reads the student's mastery, chapter progress,
/// activity and attempts; writes go to `/progress/:studentId/*`, where the server computes
/// mastery, XP, streaks and badges.
class RemoteProgress {
  RemoteProgress(this._api, this.studentId);

  final ApiClient _api;
  final String studentId;

  Future<List<Map<String, dynamic>>> _all(String collection) async =>
      (await _api.get('/$collection/$studentId', query: {'all': true}, parse: (d) => [for (final x in d! as List) (x as Map).cast<String, dynamic>()])).data;

  static ActivityKind kindOf(String? kind) => switch (kind) {
    'practice' => ActivityKind.practice,
    'exam' => ActivityKind.exam,
    'tutor' || 'voice' => ActivityKind.tutor,
    'flashcards' => ActivityKind.flashcards,
    'notes' => ActivityKind.notes,
    _ => ActivityKind.lesson,
  };

  /// App kinds → the backend's activity kinds. Practice and exams are logged by the server
  /// when their answers are recorded, so they return null.
  static String? serverKind(ActivityKind kind) => switch (kind) {
    ActivityKind.lesson => 'study',
    ActivityKind.tutor => 'tutor',
    ActivityKind.flashcards => 'flashcards',
    ActivityKind.notes => 'notes',
    ActivityKind.practice || ActivityKind.exam => null,
  };

  /// Topic progress from `/mastery` + `/chapter-progress`.
  static List<TopicProgress> topicsFrom(List<Map<String, dynamic>> mastery, List<Map<String, dynamic>> chapters) {
    final done = {for (final c in chapters) for (final t in c['topicsCompleted'] as List? ?? const []) t as String};
    final out = <String, TopicProgress>{};
    for (final m in mastery) {
      final id = m['topicId'] as String;
      out[id] = TopicProgress(
        topicId: id,
        attempts: (m['attempts'] as num?)?.toInt() ?? 0,
        correct: (m['correct'] as num?)?.toInt() ?? 0,
        completed: done.contains(id),
        lastStudied: m['lastPracticedAt'] == null ? null : DateTime.tryParse(m['lastPracticedAt'] as String),
      );
    }
    for (final c in chapters) {
      final at = c['lastStudiedAt'] == null ? null : DateTime.tryParse(c['lastStudiedAt'] as String);
      for (final t in c['topicsCompleted'] as List? ?? const []) {
        out.putIfAbsent(t as String, () => TopicProgress(topicId: t, completed: true, lastStudied: at));
      }
    }
    return out.values.toList();
  }

  static StudyActivity activityFrom(Map<String, dynamic> a) => StudyActivity(
    id: a['id'] as String,
    kind: kindOf(a['kind'] as String?),
    at: DateTime.parse(a['at'] as String),
    minutes: (a['minutes'] as num?)?.round() ?? 0,
    xp: (a['xp'] as num?)?.round() ?? 0,
    subjectId: a['subjectId'] as String?,
  );

  static QuestionAttempt attemptFrom(Map<String, dynamic> a) => QuestionAttempt(
    id: a['id'] as String,
    questionId: a['questionId'] as String,
    correct: a['correct'] as bool? ?? false,
    at: DateTime.parse(a['answeredAt'] as String),
    context: a['source'] == 'exam' ? 'exam' : 'practice',
  );

  Future<({List<TopicProgress> topics, List<StudyActivity> activities, List<QuestionAttempt> attempts})> load() async {
    final results = await Future.wait([_all('mastery'), _all('chapter-progress'), _all('activity'), _all('attempts')]);
    return (
      topics: topicsFrom(results[0], results[1]),
      activities: [for (final a in results[2]) activityFrom(a)],
      attempts: [for (final a in results[3]) attemptFrom(a)],
    );
  }

  Future<void> recordAttempt(String questionId, {required bool correct, required String context}) =>
      _api.post('/progress/$studentId/attempts', body: {
        'attempts': [
          {'questionId': questionId, 'correct': correct, 'source': context == 'exam' ? 'exam' : 'practice'},
        ],
      }, parse: (d) => d);

  Future<void> logActivity(ActivityKind kind, {required int minutes, required String label}) async {
    final k = serverKind(kind);
    if (k == null || minutes <= 0) return;
    await _api.post('/progress/$studentId/activity', body: {'kind': k, 'minutes': minutes, 'label': label}, parse: (d) => d);
  }

  /// Question bookmarks: questionId → server bookmark id.
  Future<Map<String, String>> questionBookmarks() async => {
    for (final b in await _all('bookmarks'))
      if (b['kind'] == 'question' && b['refId'] != null) b['refId'] as String: b['id'] as String,
  };

  Future<String> addBookmark(String questionId, {required String title}) async {
    final id = 'bm-${DateTime.now().microsecondsSinceEpoch}';
    await _api.post('/bookmarks/$studentId', body: {
      'id': id,
      'kind': 'question',
      'refId': questionId,
      'title': title,
      'href': '/student/questions?q=$questionId',
      'createdAt': DateTime.now().toUtc().toIso8601String(),
    }, parse: (d) => d);
    return id;
  }

  Future<void> removeBookmark(String bookmarkId) => _api.sendNoContent('DELETE', '/bookmarks/$studentId/$bookmarkId');

  Future<void> topicDone(String chapterId, String topicId, int totalTopics) =>
      _api.post('/progress/$studentId/chapters/$chapterId', body: {
        'action': {'topicDone': topicId, 'totalTopics': totalTopics},
      }, parse: (d) => d);
}

/// The signed-in student's server progress (API mode); null with the mock or for other roles.
final remoteProgressProvider = Provider<RemoteProgress?>((ref) {
  if (Env.useMockApi) return null;
  final auth = ref.watch(authControllerProvider);
  if (auth is! Authenticated || auth.user.role.pathSegment != 'student') return null;
  return RemoteProgress(ref.watch(apiClientProvider), auth.user.id);
});
