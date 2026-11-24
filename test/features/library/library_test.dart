import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shikkhaai_mobile/core/storage/local_store.dart';
import 'package:shikkhaai_mobile/features/book_avatar/data/book_catalog.dart';
import 'package:shikkhaai_mobile/features/library/library_controller.dart';
import 'package:shikkhaai_mobile/features/library/library_screens.dart';
import 'package:shikkhaai_mobile/shared/widgets/error_view.dart';

import '../../helpers/test_app.dart';

void main() {
  test('every subject has a sample book; passage pages keep their printed numbers', () {
    expect(sampleBooks, isNotEmpty);
    final physics = bookById('book-ssc-phy')!;
    expect(physics.pages.map((p) => p.page).toSet().length, physics.pages.length, reason: 'page numbers are unique');
    expect(physics.pages.any((p) => p.page == 22 && p.heading.en.contains('acceleration')), isTrue);
    expect(physics.indexOfPage(22), physics.pages.indexWhere((p) => p.page == 22));
  });

  test('reading state: last page, bookmarks, downloads persist', () async {
    final store = MemoryLocalStore();
    final c = testContainer(store: store);
    final lib = c.read(libraryProvider.notifier);
    await lib.openedPage('book-ssc-bio', 5);
    expect(await lib.toggleBookmark('book-ssc-bio', 5), isTrue);
    await lib.setDownloaded('book-ssc-bio', true);
    final again = testContainer(store: store).read(libraryProvider)['book-ssc-bio']!;
    expect(again.lastPage, 5);
    expect(again.bookmarks, [5]);
    expect(again.downloaded, isTrue);
    expect(await lib.toggleBookmark('book-ssc-bio', 5), isFalse);
  });

  testWidgets('reader opens at a page, bookmarks it and moves to the next page', (tester) async {
    await tester.pumpWidget(testApp(const BookReaderScreen(bookId: 'book-ssc-phy', page: 22)));
    await tester.pumpAndSettle();
    expect(find.textContaining('২২'), findsWidgets);
    await tester.tap(find.byKey(const Key('reader.bookmark')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('reader.next')));
    await tester.pumpAndSettle();
    expect(find.textContaining('২২'), findsNothing);
  });

  testWidgets('library lists books', (tester) async {
    await tester.pumpWidget(testApp(const LibraryScreen()));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('library.book.book-ssc-phy')), findsOneWidget);
    expect(find.byType(ErrorView), findsNothing);
  });
}
