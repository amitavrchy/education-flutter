import 'package:flutter_test/flutter_test.dart';
import 'package:shikkhaai_mobile/core/network/network_providers.dart';
import 'package:shikkhaai_mobile/features/progress/data/remote_progress.dart';
import 'package:shikkhaai_mobile/features/study_tools/english_coach.dart';

import '../helpers/fake_server.dart';
import '../helpers/test_app.dart';

void main() {
  const key = '/documents/english:u-student-1';
  Map<String, dynamic> doc() => {
    'id': 'english',
    'skills': {
      'grammar': {'attempts': 2, 'score': 70, 'history': [{'date': '2026-11-20', 'score': 60}, {'date': '2026-11-21', 'score': 80}]},
      'speaking': {'attempts': 1, 'score': 55, 'history': <Object>[]},
    },
    'writing': [{'taskId': 'w1', 'at': '2026-11-20T03:00:00.000Z', 'overall': 58}],
  };

  test('API mode: English scores load from the document and a new score keeps the rest', () async {
    final server = FakeServer();
    server.responses['GET $key'] = doc();
    final c = testContainer(overrides: [
      apiClientProvider.overrideWithValue(server.client),
      remoteProgressProvider.overrideWithValue(RemoteProgress(server.client, 'u-student-1')),
    ]);
    c.read(englishProvider);
    await c.read(englishProvider.notifier).refresh();
    expect(c.read(englishProvider).scores[EngSkill.grammar], [60, 80]);
    expect(c.read(englishProvider).scores[EngSkill.speaking], [55]);

    await c.read(englishProvider.notifier).record(EngSkill.grammar, 100);
    final saved = server.lastBody[key]! as Map;
    final grammar = (saved['skills'] as Map)['grammar'] as Map;
    expect(grammar['attempts'], 3);
    expect(grammar['score'], 80); // (70×2 + 100) / 3
    expect((grammar['history'] as List).length, 3);
    expect((saved['skills'] as Map)['speaking'], isNotNull);
    expect(saved['writing'], hasLength(1)); // web-only data kept
  });

  test('a score recorded before the first load still merges into the server document', () async {
    final server = FakeServer();
    server.responses['GET $key'] = doc();
    final c = testContainer(overrides: [
      apiClientProvider.overrideWithValue(server.client),
      remoteProgressProvider.overrideWithValue(RemoteProgress(server.client, 'u-student-1')),
    ]);
    await c.read(englishProvider.notifier).markKnown('library');
    final saved = server.lastBody[key]! as Map;
    expect(saved['knownWords'], ['library']);
    expect((saved['skills'] as Map).keys, containsAll(['grammar', 'speaking']));
  });
}
