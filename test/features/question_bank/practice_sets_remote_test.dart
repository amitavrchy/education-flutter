import 'package:flutter_test/flutter_test.dart';
import 'package:shikkhaai_mobile/core/network/network_providers.dart';
import 'package:shikkhaai_mobile/features/progress/data/remote_progress.dart';
import 'package:shikkhaai_mobile/features/question_bank/application/practice_controller.dart';

import '../../helpers/fake_server.dart';
import '../../helpers/test_app.dart';

void main() {
  test('API mode: practice sets load from the server and edits push back with web fields kept', () async {
    final server = FakeServer({
      '/practice-sets/u-student-1': [
        {
          'id': 'ps-1',
          'name': 'গতি — কঠিন',
          'questionIds': ['q-1'],
          'kind': 'photo_solver',
          'createdAt': '2026-11-01T00:00:00.000Z',
          'updatedAt': '2026-11-01T00:00:00.000Z',
        },
      ],
    });
    final c = testContainer(
      overrides: [apiClientProvider.overrideWithValue(server.client), remoteProgressProvider.overrideWithValue(RemoteProgress(server.client, 'u-student-1'))],
    );
    c.read(practiceProvider);
    final ctl = c.read(practiceProvider.notifier);
    await ctl.syncSets();
    expect(c.read(practiceProvider).sets.single.name, 'গতি — কঠিন');

    await ctl.addToSet('ps-1', 'q-2');
    await ctl.createSet('নতুন সেট', questionIds: ['q-3']);
    await Future<void>.delayed(const Duration(milliseconds: 1300));
    final saved = {for (final x in server.data['/practice-sets/u-student-1']!) x['id']: x};
    expect(saved['ps-1']!['questionIds'], ['q-1', 'q-2']);
    expect(saved['ps-1']!['kind'], 'photo_solver'); // web-only field kept
    final fresh = saved.values.firstWhere((x) => x['name'] == 'নতুন সেট');
    expect(fresh['kind'], 'manual');

    await ctl.deleteSet('ps-1');
    await Future<void>.delayed(const Duration(milliseconds: 1300));
    expect(server.data['/practice-sets/u-student-1']!.map((x) => x['id']), isNot(contains('ps-1')));
  });
}
