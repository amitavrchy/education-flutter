import 'package:flutter_test/flutter_test.dart';
import 'package:shikkhaai_mobile/core/network/network_providers.dart';
import 'package:shikkhaai_mobile/features/notes/application/notes_controller.dart';
import 'package:shikkhaai_mobile/features/notes/data/remote_notes.dart';
import 'package:shikkhaai_mobile/features/notes/domain/note.dart';
import 'package:shikkhaai_mobile/features/progress/data/remote_progress.dart';

import '../../helpers/fake_server.dart';
import '../../helpers/test_app.dart';

void main() {
  test('HTML ↔ Markdown covers headings, lists and emphasis', () {
    const html = '<h2>নিউটন</h2><p>প্রথম <strong>সূত্র</strong> ও <em>জড়তা</em></p><ul><li>এক</li><li>দুই</li></ul>';
    final md = htmlToMarkdown(html);
    expect(md, contains('## নিউটন'));
    expect(md, contains('**সূত্র**'));
    expect(md, contains('*জড়তা*'));
    expect(md, contains('- এক'));
    expect(markdownToHtml(md), html);
  });

  test('API mode: notes load from the server and edits keep web-only fields', () async {
    final server = FakeServer({
      '/notes/u-student-1': [
        {
          'id': 'note-1',
          'title': 'গতি',
          'content': '<p>বেগ ও <strong>ত্বরণ</strong></p>',
          'kind': 'formula',
          'source': {'type': 'chapter', 'refId': 'ssc-phy-c2'},
          'tags': ['ভৌত'],
          'favorite': true,
          'offline': true,
          'createdAt': '2026-11-04T03:00:00.000Z',
          'updatedAt': '2026-11-05T03:00:00.000Z',
        },
      ],
    });
    final c = testContainer(
      overrides: [apiClientProvider.overrideWithValue(server.client), remoteProgressProvider.overrideWithValue(RemoteProgress(server.client, 'u-student-1'))],
    );
    c.read(notesProvider);
    await c.read(notesProvider.notifier).refresh();
    final n = c.read(notesProvider).single;
    expect(n.type, NoteType.formulaSheet);
    expect(n.body, 'বেগ ও **ত্বরণ**');
    expect(n.chapterId, 'ssc-phy-c2');
    expect(n.favorite, isTrue);

    await c.read(notesProvider.notifier).create(title: 'নতুন', body: '- এক');
    await Future<void>.delayed(const Duration(milliseconds: 1300));
    final notes = server.data['/notes/u-student-1']!;
    expect(notes.length, 2);
    final old = notes.firstWhere((x) => x['id'] == 'note-1');
    expect(old['offline'], isTrue);
    expect((old['source'] as Map)['refId'], 'ssc-phy-c2');
    final added = notes.firstWhere((x) => x['id'] != 'note-1');
    expect(added['content'], '<ul><li>এক</li></ul>');
    expect(added['kind'], 'custom');
  });
}
