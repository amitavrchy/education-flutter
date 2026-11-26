import 'package:flutter_test/flutter_test.dart';
import 'package:shikkhaai_mobile/core/network/network_providers.dart';
import 'package:shikkhaai_mobile/features/library/library_controller.dart';
import 'package:shikkhaai_mobile/features/progress/data/remote_progress.dart';

import '../../helpers/fake_server.dart';
import '../../helpers/test_app.dart';

void main() {
  test('API mode: reading state loads from the server and changes push back with web fields kept', () async {
    final server = FakeServer({
      '/reading/u-student-1': [
        {
          'id': 'book-ssc-chemistry-bn', 'bookId': 'book-ssc-chemistry-bn', 'zoom': 1.4, 'lastPage': 32, 'pagesRead': [31, 32], 'bookmarks': [32],
          'pageNotes': [{'id': 'pn1', 'page': 31, 'text': 'মোল', 'createdAt': '2026-11-18T15:00:00.000Z'}],
          'highlights': [{'id': 'h1', 'page': 32, 'text': 'অ্যাভোগাড্রো', 'color': 'green', 'createdAt': '2026-11-18T15:00:00.000Z'}],
          'updatedAt': '2026-11-18T15:00:00.000Z',
        },
      ],
    });
    final c = testContainer(overrides: [
      apiClientProvider.overrideWithValue(server.client),
      remoteProgressProvider.overrideWithValue(RemoteProgress(server.client, 'u-student-1')),
    ]);
    c.read(libraryProvider);
    final ctl = c.read(libraryProvider.notifier);
    await ctl.refresh();
    final r = ctl.of('book-ssc-chemistry');
    expect(r.lastPage, 32);
    expect(r.notes[31], 'মোল');
    expect(r.highlights.single.text, 'অ্যাভোগাড্রো');

    await ctl.openedPage('book-ssc-chemistry', 40);
    await ctl.openedPage('book-ssc-physics', 5);
    await Future<void>.delayed(const Duration(milliseconds: 1300));
    final saved = {for (final x in server.data['/reading/u-student-1']!) x['id']: x};
    expect(saved.keys, containsAll(['book-ssc-chemistry-bn', 'book-ssc-physics-bn']));
    final chem = saved['book-ssc-chemistry-bn']!;
    expect(chem['lastPage'], 40);
    expect(chem['pagesRead'], containsAll([31, 32, 40]));
    expect(chem['zoom'], 1.4); // web-only field kept
  });
}
