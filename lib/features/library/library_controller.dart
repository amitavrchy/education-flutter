import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/l10n/tr.dart';
import '../../core/mock/json_collection.dart';
import '../../core/storage/local_store.dart';

abstract final class LibraryStrings {
  static const title = Tr('পাঠ্যবই লাইব্রেরি', 'Textbook library');
  static const hint = Tr('নমুনা পাঠ্যবই পড়ো, বুকমার্ক রাখো, অফলাইনে ডাউনলোড করো, আর বইয়ের শিক্ষককে প্রশ্ন করো।', 'Read sample textbooks, bookmark pages, download for offline and ask each book\'s teacher.');
  static const search = Tr('বই খুঁজুন', 'Search books');
  static const all = Tr('সব', 'All');
  static const downloaded = Tr('ডাউনলোড করা', 'Downloaded');
  static const continueReading = Tr('পড়া চালিয়ে যাও', 'Continue reading');
  static const read = Tr('পড়ো', 'Read');
  static const contents = Tr('সূচিপত্র', 'Contents');
  static const chapter = Tr('অধ্যায় {n}', 'Chapter {n}');
  static const page = Tr('পৃষ্ঠা {n}', 'Page {n}');
  static const pageOf = Tr('পৃষ্ঠা {n} / {t}', 'Page {n} / {t}');
  static const pages = Tr('{n} পৃষ্ঠা', '{n} pages');
  static const download = Tr('অফলাইনের জন্য ডাউনলোড', 'Download for offline');
  static const removeDownload = Tr('ডাউনলোড মুছুন', 'Remove download');
  static const downloadedNote = Tr('ডাউনলোড হয়েছে — অফলাইনেও পড়া যাবে', 'Downloaded — readable offline');
  static const bookmarks = Tr('বুকমার্ক', 'Bookmarks');
  static const noBookmarks = Tr('কোনো বুকমার্ক নেই', 'No bookmarks');
  static const bookmark = Tr('বুকমার্ক', 'Bookmark');
  static const goToPage = Tr('পৃষ্ঠায় যাও', 'Go to page');
  static const go = Tr('যাও', 'Go');
  static const textSize = Tr('লেখার আকার', 'Text size');
  static const askTeacher = Tr('এই বইয়ের শিক্ষককে জিজ্ঞেস করো', "Ask this book's teacher");
  static const offlineNotDownloaded = Tr('অফলাইন — এই বইটি ডাউনলোড করা নেই। অনলাইনে এসে ডাউনলোড করে নাও।', 'Offline — this book is not downloaded. Download it when you are back online.');
  static const sample = Tr('নমুনা পাঠ্যবই — ডেমোর জন্য লেখা কৃত্রিম বিষয়বস্তু, আসল NCTB বই নয়।', 'Sample textbook — synthetic content written for the demo, not a real NCTB book.');
  static const noBooks = Tr('কোনো বই পাওয়া যায়নি', 'No books found');
}

/// Per-book reading state (last page, bookmarks, offline download).
class BookReading {
  const BookReading({required this.bookId, this.lastPage, this.bookmarks = const [], this.downloaded = false, this.updatedAt});

  factory BookReading.fromJson(Map<String, dynamic> j) => BookReading(
    bookId: j['bookId'] as String,
    lastPage: j['lastPage'] as int?,
    bookmarks: (j['bookmarks'] as List? ?? const []).cast<int>(),
    downloaded: j['downloaded'] as bool? ?? false,
    updatedAt: j['updatedAt'] == null ? null : DateTime.parse(j['updatedAt'] as String),
  );

  final String bookId;
  final int? lastPage;
  final List<int> bookmarks;
  final bool downloaded;
  final DateTime? updatedAt;

  BookReading copyWith({int? lastPage, List<int>? bookmarks, bool? downloaded}) => BookReading(
    bookId: bookId,
    lastPage: lastPage ?? this.lastPage,
    bookmarks: bookmarks ?? this.bookmarks,
    downloaded: downloaded ?? this.downloaded,
    updatedAt: DateTime.now(),
  );

  Map<String, dynamic> toJson() => {'bookId': bookId, 'lastPage': lastPage, 'bookmarks': bookmarks, 'downloaded': downloaded, 'updatedAt': updatedAt?.toIso8601String()};
}

class LibraryController extends Notifier<Map<String, BookReading>> {
  late JsonCollection<BookReading> _col;

  @override
  Map<String, BookReading> build() {
    _col = JsonCollection(
      store: watchStore(ref),
      name: 'library_reading',
      fromJson: BookReading.fromJson,
      toJson: (r) => r.toJson(),
      idOf: (r) => r.bookId,
      seed: () => [
        BookReading(bookId: 'book-ssc-phy', lastPage: 22, bookmarks: const [22, 46], downloaded: true, updatedAt: DateTime.now().subtract(const Duration(hours: 5))),
        BookReading(bookId: 'book-ssc-chem', lastPage: 9, updatedAt: DateTime.now().subtract(const Duration(days: 2))),
      ],
    );
    return {for (final r in _col.all()) r.bookId: r};
  }

  BookReading of(String bookId) => state[bookId] ?? BookReading(bookId: bookId);

  Future<void> _put(BookReading r) async {
    state = {...state, r.bookId: r};
    await _col.upsert(r);
  }

  Future<void> openedPage(String bookId, int page) => _put(of(bookId).copyWith(lastPage: page));

  Future<bool> toggleBookmark(String bookId, int page) async {
    final r = of(bookId);
    final on = !r.bookmarks.contains(page);
    await _put(r.copyWith(bookmarks: on ? ([...r.bookmarks, page]..sort()) : [for (final p in r.bookmarks) if (p != page) p]));
    return on;
  }

  Future<void> setDownloaded(String bookId, bool value) => _put(of(bookId).copyWith(downloaded: value));
}

final libraryProvider = NotifierProvider<LibraryController, Map<String, BookReading>>(LibraryController.new);
