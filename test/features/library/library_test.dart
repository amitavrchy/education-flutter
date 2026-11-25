import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shikkhaai_mobile/core/l10n/tr.dart';
import 'package:shikkhaai_mobile/core/storage/local_store.dart';
import 'package:shikkhaai_mobile/features/book_avatar/data/book_catalog.dart';
import 'package:shikkhaai_mobile/features/library/library_controller.dart';
import 'package:shikkhaai_mobile/features/library/library_screens.dart';
import 'package:shikkhaai_mobile/features/library/reader_tools.dart';
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

  test('page notes, highlights and history persist', () async {
    final c = testContainer();
    final lib = c.read(libraryProvider.notifier);
    await lib.openedPage('book-ssc-phy', 5);
    await lib.openedPage('book-ssc-phy', 6);
    await lib.openedPage('book-ssc-phy', 5);
    await lib.setNote('book-ssc-phy', 5, 'মনে রাখো');
    await lib.addHighlight('book-ssc-phy', 5, 'একটি বাক্য');
    await lib.addHighlight('book-ssc-phy', 5, 'একটি বাক্য');
    final r = c.read(libraryProvider)['book-ssc-phy']!;
    expect(r.history.first.$1, 5);
    expect(r.history.where((h) => h.$1 == 5).length, 1);
    expect(r.notes[5], 'মনে রাখো');
    expect(r.highlights.length, 1);
    await lib.setNote('book-ssc-phy', 5, '');
    expect(c.read(libraryProvider)['book-ssc-phy']!.notes.containsKey(5), isFalse);
  });

  test('sentences and highlight markup', () {
    expect(pageSentences('প্রথম বাক্যটি বেশ লম্বা। দ্বিতীয় বাক্যটিও লম্বা।').length, 2);
    final h = withHighlights('abc long sentence here.', [Highlight(1, 'long sentence', DateTime(2026))]);
    expect(h, contains('==long sentence=='));
  });

  testWidgets('reader saves a page note', (tester) async {
    await tester.pumpWidget(testApp(const BookReaderScreen(bookId: 'book-ssc-phy', page: 22), lang: AppLanguage.en));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('reader.note')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('reader.noteInput')), 'Remember units');
    await tester.tap(find.byKey(const Key('reader.noteSave')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('reader.noteCard')), findsOneWidget);
  });

  testWidgets('older edition shows a version warning and blocks download', (tester) async {
    final old = sampleBooks.firstWhere((b) => bookEdition(b) != 'nctb-2025');
    await tester.pumpWidget(testApp(BookScreen(bookId: old.id), lang: AppLanguage.en));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('book.versionWarning')), findsOneWidget);
    expect(find.text('Read online only'), findsOneWidget);
  });
}
