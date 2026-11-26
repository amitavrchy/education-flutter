import 'package:flutter_test/flutter_test.dart';
import 'package:shikkhaai_mobile/core/network/network_providers.dart';
import 'package:shikkhaai_mobile/features/account/account_controller.dart';
import 'package:shikkhaai_mobile/features/curriculum/domain/curriculum_models.dart';
import 'package:shikkhaai_mobile/features/profile/application/student_profile_controller.dart';
import 'package:shikkhaai_mobile/features/progress/data/remote_progress.dart';

import '../helpers/fake_server.dart';
import '../helpers/test_app.dart';

void main() {
  test('API mode: profile and guardian privacy come from the server and changes go back', () async {
    final server = FakeServer();
    server.responses['GET /student-profiles/u-student-1'] = {
      'id': 'u-student-1', 'name': 'রাফি আহমেদ', 'levelCode': 'SSC', 'grade': 9, 'group': 'business', 'version': 'en', 'boardId': 'brd-chattogram',
      'institutionName': 'আইডিয়াল স্কুল', 'examYear': 2028, 'targetGpa': 4.5, 'dailyMinutes': 120, 'weakSubjectIds': ['ssc-chem'],
      'privacy': {'showOnLeaderboard': true, 'dataRetentionMonths': 24, 'shareScoresWithGuardian': false, 'shareProgressWithGuardian': true, 'shareConversationsWithGuardian': false},
    };
    final c = testContainer(overrides: [
      apiClientProvider.overrideWithValue(server.client),
      remoteProgressProvider.overrideWithValue(RemoteProgress(server.client, 'u-student-1')),
    ]);
    c.read(studentProfileProvider);
    await c.read(studentProfileProvider.notifier).refresh();
    final p = c.read(studentProfileProvider);
    expect(p.classYear, 9);
    expect(p.group, AcademicGroup.business);
    expect(p.medium, CurriculumMedium.english);
    expect(p.boardId, 'chattogram');
    expect(p.onboarded, isTrue);
    expect(c.read(accountProvider).privacy['scores'], isFalse);

    await c.read(studentProfileProvider.notifier).update((x) => x.copyWith(dailyMinutes: 90));
    expect((server.lastBody['/student-profiles/u-student-1']! as Map)['dailyMinutes'], 90);

    await c.read(accountProvider.notifier).setPrivacy('conversations', true);
    final privacy = (server.lastBody['/student-profiles/u-student-1']! as Map)['privacy'] as Map;
    expect(privacy['shareConversationsWithGuardian'], isTrue);
    expect(privacy['dataRetentionMonths'], 24); // the rest of the object is sent back unchanged
  });
}
