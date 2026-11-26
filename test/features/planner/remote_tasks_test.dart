import 'package:flutter_test/flutter_test.dart';
import 'package:shikkhaai_mobile/core/network/network_providers.dart';
import 'package:shikkhaai_mobile/features/planner/application/planner_controller.dart';
import 'package:shikkhaai_mobile/features/planner/domain/study_task.dart';
import 'package:shikkhaai_mobile/features/progress/data/remote_progress.dart';

import '../../helpers/fake_server.dart';
import '../../helpers/test_app.dart';

void main() {
  test('API mode: tasks load from the server and completing one pushes it', () async {
    final server = FakeServer({
      '/tasks/u-student-1': [
        {
          'id': 'task-1',
          'title': 'গতি অধ্যায় পড়া',
          'type': 'exam_prep',
          'date': '2026-11-26',
          'start': '18:30',
          'durationMinutes': 45,
          'status': 'scheduled',
          'priority': 'high',
          'source': 'generated',
          'color': 'web-only',
          'createdAt': '2026-11-20T03:00:00.000Z',
        },
      ],
      '/activity/u-student-1': const [],
      '/mastery/u-student-1': const [],
      '/chapter-progress/u-student-1': const [],
      '/attempts/u-student-1': const [],
    });
    final c = testContainer(
      overrides: [apiClientProvider.overrideWithValue(server.client), remoteProgressProvider.overrideWithValue(RemoteProgress(server.client, 'u-student-1'))],
    );
    c.read(plannerProvider);
    await c.read(plannerProvider.notifier).refresh();
    final t = c.read(plannerProvider).tasks.single;
    expect(t.kind, TaskKind.exam);
    expect(t.startMinute, 18 * 60 + 30);
    expect(t.priority, Priority.high);
    expect(t.generated, isTrue);

    await c.read(plannerProvider.notifier).complete('task-1', actualMinutes: 40, focus: 4);
    await Future<void>.delayed(const Duration(milliseconds: 1300));
    final pushed = server.data['/tasks/u-student-1']!.single;
    expect(pushed['status'], 'completed');
    expect(pushed['start'], '18:30');
    expect(pushed['color'], 'web-only');
    expect(pushed['reflection'], {'rating': 4, 'actualMinutes': 40});
  });

  test('API mode: plan settings come from the planSettings document and save back merged', () async {
    final server = FakeServer({'/tasks/u-student-1': const []});
    const key = '/documents/planSettings:u-student-1';
    server.responses['GET $key'] = {
      'id': 'settings', 'targetGpa': 4.5, 'dailyMinutes': 150, 'preferredTime': 'early_morning', 'studyDays': [0, 1, 2],
      'examDate': '2027-02-15', 'subjectPriority': {'ssc-phy': 3}, 'chapterPriority': <String, int>{}, 'remindersEnabled': false,
    };
    server.responses['PUT $key'] = null;
    final c = testContainer(
      overrides: [apiClientProvider.overrideWithValue(server.client), remoteProgressProvider.overrideWithValue(RemoteProgress(server.client, 'u-student-1'))],
    );
    c.read(plannerProvider);
    await c.read(plannerProvider.notifier).refresh();
    final prefs = c.read(plannerProvider).prefs;
    expect(prefs.dailyMinutes, 150);
    expect(prefs.studyTime, StudyTime.morning);
    expect(prefs.targetGpa, 4.5);
    expect(prefs.reminders, isFalse);
    expect(prefs.examDate, DateTime(2027, 2, 15));

    await c.read(plannerProvider.notifier).setPrefs(prefs.copyWith(dailyMinutes: 200, studyTime: StudyTime.night));
    final saved = server.lastBody[key]! as Map;
    expect(saved['dailyMinutes'], 200);
    expect(saved['preferredTime'], 'night');
    expect(saved['examDate'], '2027-02-15');
    expect(saved['subjectPriority'], {'ssc-phy': 3}); // web-only fields kept
    expect(saved['studyDays'], [0, 1, 2]);
  });
}
