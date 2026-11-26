import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shikkhaai_mobile/core/network/api_client.dart';
import 'package:shikkhaai_mobile/features/progress/application/learning_progress_controller.dart';
import 'package:shikkhaai_mobile/features/progress/data/remote_progress.dart';
import 'package:shikkhaai_mobile/features/progress/domain/learning_progress.dart';
import 'package:shikkhaai_mobile/features/question_bank/application/practice_controller.dart';
import 'package:shikkhaai_mobile/features/question_bank/data/question_repository.dart';

import '../../helpers/test_app.dart';

class _FakeRemote extends RemoteProgress {
  _FakeRemote() : super(ApiClient(Dio()), 'u-student-1');

  final List<String> calls = [];

  @override
  Future<({List<TopicProgress> topics, List<StudyActivity> activities, List<QuestionAttempt> attempts})> load() async => (
    topics: RemoteProgress.topicsFrom(
      [{'topicId': 'ssc-physics-c1-t1', 'attempts': 4, 'correct': 3, 'lastPracticedAt': '2026-11-20T00:00:00.000Z'}],
      [{'topicsCompleted': ['ssc-physics-c1-t2'], 'lastStudiedAt': '2026-11-21T00:00:00.000Z'}],
    ),
    activities: [RemoteProgress.activityFrom({'id': 'act-1', 'kind': 'reading', 'at': '2026-11-25T00:00:00.000Z', 'minutes': 20, 'xp': 30})],
    attempts: [RemoteProgress.attemptFrom({'id': 'att-1', 'questionId': 'q-1', 'correct': true, 'answeredAt': '2026-11-25T00:00:00.000Z', 'source': 'exam'})],
  );

  @override
  Future<void> recordAttempt(String questionId, {required bool correct, required String context}) async => calls.add('attempt $questionId $correct $context');

  final Map<String, String> bookmarks = {'q-server': 'bm-1'};

  @override
  Future<Map<String, String>> questionBookmarks() async => {...bookmarks};

  @override
  Future<String> addBookmark(String questionId, {required String title}) async {
    calls.add('bookmark+ $questionId');
    return bookmarks[questionId] = 'bm-${bookmarks.length + 1}';
  }

  @override
  Future<void> removeBookmark(String bookmarkId) async => calls.add('bookmark- $bookmarkId');

  @override
  Future<void> logActivity(ActivityKind kind, {required int minutes, required String label}) async => calls.add('activity ${kind.name} $minutes');
}

void main() {
  test('server mastery and chapter progress become topic progress', () {
    final topics = RemoteProgress.topicsFrom(
      [{'topicId': 't1', 'attempts': 2, 'correct': 1}],
      [{'topicsCompleted': ['t1', 't2']}],
    );
    final byId = {for (final t in topics) t.topicId: t};
    expect(byId['t1']!.attempts, 2);
    expect(byId['t1']!.completed, isTrue);
    expect(byId['t2']!.completed, isTrue);
  });

  test('activity kinds map both ways; practice/exam activity is left to the server', () {
    expect(RemoteProgress.kindOf('voice'), ActivityKind.tutor);
    expect(RemoteProgress.kindOf('reading'), ActivityKind.lesson);
    expect(RemoteProgress.serverKind(ActivityKind.lesson), 'study');
    expect(RemoteProgress.serverKind(ActivityKind.exam), isNull);
  });

  test('API mode: refresh replaces local progress and history; answers go to the server', () async {
    final fake = _FakeRemote();
    final c = testContainer(overrides: [remoteProgressProvider.overrideWithValue(fake)]);
    c.read(learningProgressProvider);
    await c.read(learningProgressProvider.notifier).refresh();
    final p = c.read(learningProgressProvider);
    expect(p.topic('ssc-physics-c1-t1').attempts, 4);
    expect(p.topic('ssc-physics-c1-t2').completed, isTrue);
    expect(p.activities.single.minutes, 20);
    expect(c.read(practiceProvider).attempts.single.context, 'exam');

    final q = c.read(questionRepositoryProvider).cached.first;
    await c.read(practiceProvider.notifier).recordAttempt(q, correct: true);
    await c.read(learningProgressProvider.notifier).logActivity(ActivityKind.lesson, minutes: 15);
    expect(fake.calls, ['attempt ${q.id} true practice', 'activity lesson 15']);
  });

  test('API mode: bookmarks come from the server and toggles reach it', () async {
    final fake = _FakeRemote();
    final c = testContainer(overrides: [remoteProgressProvider.overrideWithValue(fake)]);
    await c.read(practiceProvider.notifier).syncBookmarks();
    expect(c.read(practiceProvider).bookmarks, {'q-server'});
    await c.read(practiceProvider.notifier).toggleBookmark('q-new');
    await c.read(practiceProvider.notifier).toggleBookmark('q-server');
    expect(fake.calls, ['bookmark+ q-new', 'bookmark- bm-1']);
    expect(c.read(practiceProvider).bookmarks, {'q-new'});
  });
}
