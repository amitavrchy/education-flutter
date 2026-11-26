import 'package:flutter_test/flutter_test.dart';
import 'package:shikkhaai_mobile/core/network/network_providers.dart';
import 'package:shikkhaai_mobile/features/parent/guardian_controller.dart';
import 'package:shikkhaai_mobile/features/parent/remote_guardian.dart';

import '../../helpers/fake_server.dart';
import '../../helpers/test_app.dart';

const _gid = 'u-parent-1';

Map<String, dynamic> _link(String id, String sid, {String status = 'active', bool studyTime = true}) => {
  'id': id, 'status': status, 'relation': 'বাবা', 'studentId': sid, 'guardianId': _gid, 'studentName': 'রাফি আহমেদ',
  'linkedAt': '2026-02-21T08:00:00.000Z',
  'permissions': {'scores': true, 'calendar': true, 'progress': true, 'studyTime': studyTime, 'aiConversations': false, 'teacherFeedback': true},
};

void main() {
  test('a child summary combines /guardian/children with the records the link may read', () {
    final now = DateTime(2026, 11, 26, 12);
    final s = RemoteGuardian.summaryFrom(
      RemoteGuardian.linkFrom(_link('gl-1', 'u-student-1')),
      {'minutesPrevWeek': 252, 'tasksDone': 10, 'tasksMissed': 4, 'avgScore': 68, 'streak': 3, 'weakTopicIds': ['ssc-phy-p1-c3-t1', 'missing-topic'], 'subjectMastery': [{'subjectId': 'ssc-phy', 'mastery': 61}]},
      activity: [
        {'date': '2026-11-26', 'minutes': 30},
        {'date': '2026-11-20', 'minutes': 15},
        {'date': '2026-11-10', 'minutes': 99}, // outside the week
      ],
      examAttempts: [
        {'examTitle': 'মডেল টেস্ট', 'status': 'submitted', 'submittedAt': '2026-11-25T03:00:00.000Z', 'result': {'percent': 80}},
        {'examTitle': 'চলমান', 'status': 'in_progress'},
      ],
      tasks: [
        {'id': 't1', 'title': 'পড়া', 'date': '2026-11-27', 'start': '18:00', 'durationMinutes': 45, 'status': 'scheduled'},
        {'id': 't2', 'title': 'পুরনো', 'date': '2026-10-01', 'start': '18:00', 'durationMinutes': 45, 'status': 'completed'},
      ],
      mastery: [{'topicId': 'ssc-phy-p1-c3-t1', 'mastery': 35}],
      answers: [{'answeredAt': '2026-11-24T03:00:00.000Z'}, {'answeredAt': '2026-11-01T03:00:00.000Z'}],
      now: now,
    );
    expect(s.weekMinutes, [15, 0, 0, 0, 0, 0, 30]);
    expect(s.minutesWeek, 45);
    expect(s.avgScore, 68);
    expect(s.weakTopics.single.$3, 0.35);
    expect(s.subjectMastery.single.$2, 0.61);
    expect(s.results.single.percent, 80);
    expect(s.calendar.single.minutes, 45);
    expect(s.goalValues[GoalMetric.exams], 1);
    expect(s.goalValues[GoalMetric.questions], 1);
  });

  test('API mode: portal loads from the server; goals and permissions are saved there', () async {
    final server = FakeServer({
      '/guardian/links': [_link('gl-1', 'u-student-1'), _link('gl-9', 'u-student-9', status: 'revoked')],
      '/guardian/children': [
        {'link': _link('gl-1', 'u-student-1'), 'minutesPrevWeek': 100, 'tasksDone': 2, 'tasksMissed': 1, 'avgScore': 70, 'streak': 4, 'weakTopicIds': <String>[], 'subjectMastery': <Object>[]},
      ],
      '/teacher-feedback': [
        {'id': 'tf-1', 'studentId': 'u-student-1', 'teacherName': 'নাসরিন সুলতানা', 'subjectId': 'ssc-phy', 'text': 'ভালো করছে', 'at': '2026-11-22T03:00:00.000Z', 'acknowledged': false, 'kind': 'praise'},
      ],
      '/activity/u-student-1': [{'date': '2026-11-26', 'minutes': 20}],
    });
    server.responses['GET /documents/guardianGoals:$_gid'] = {
      'id': 'goals',
      'items': [{'id': 'gg-1', 'studentId': 'u-student-1', 'title': 'সপ্তাহে ১০ ঘণ্টা', 'metric': 'minutes', 'target': 600, 'createdAt': '2026-11-14T03:00:00.000Z'}],
    };
    final c = testContainer(overrides: [
      apiClientProvider.overrideWithValue(server.client),
      remoteGuardianProvider.overrideWithValue(RemoteGuardian(server.client, _gid)),
    ]);
    c.read(guardianProvider);
    final ctl = c.read(guardianProvider.notifier);
    await ctl.refresh();
    final g = c.read(guardianProvider);
    expect(g.links.map((l) => l.id), ['gl-1']);
    expect(g.selected?.id, 'gl-1');
    expect(g.notes.single.teacher, 'নাসরিন সুলতানা');
    expect(g.goals.single.linkId, 'gl-1');
    expect(c.read(childSummaryProvider('gl-1'))!.streak, 4);

    await ctl.saveGoal(GuardianGoal(id: 'gg-2', linkId: 'gl-1', title: 'দুটি পরীক্ষা', metric: GoalMetric.exams, target: 2, createdAt: DateTime(2026, 11, 26)));
    final saved = server.lastBody['/documents/guardianGoals:$_gid']! as Map;
    expect([for (final i in saved['items'] as List) (i as Map)['studentId']], ['u-student-1', 'u-student-1']);

    await ctl.setPermission('gl-1', ShareKey.studyTime, false);
    expect(((server.lastBody['/guardian-links/gl-1']! as Map)['permissions'] as Map)['studyTime'], false);

    await ctl.acknowledge(g.notes.single);
    expect(server.lastBody['/teacher-feedback/tf-1'], {'acknowledged': true});
  });
}
