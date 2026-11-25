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
  static const filters = Tr('ফিল্টার', 'Filters');
  static const clearFilters = Tr('সব ফিল্টার মুছুন', 'Clear all filters');
  static const classFilter = Tr('শ্রেণি', 'Class');
  static const subjectFilter = Tr('বিষয়', 'Subject');
  static const curriculumFilter = Tr('শিক্ষাক্রম', 'Curriculum');
  static const languageFilter = Tr('ভাষা', 'Language');
  static const yearFilter = Tr('শিক্ষাবর্ষ', 'Academic year');
  static const oldEdition = Tr('পুরনো সংস্করণ', 'Older edition');
  static const versionWarning = Tr('এই বইটি তোমার প্রোফাইলের শিক্ষাক্রমের চেয়ে ভিন্ন সংস্করণের — কিছু অধ্যায় মিলবে না।', 'This book follows a different curriculum edition from your profile — some chapters may not match.');
  static const readOnline = Tr('শুধু অনলাইনে পড়া যাবে', 'Read online only');
  static const permissionNote = Tr('প্রকাশকের অনুমতি অনুযায়ী এই সংস্করণ ডাউনলোড করা যায় না।', "This edition can't be downloaded under the publisher's permission.");
  static const onlineOnly = Tr('এখন শুধু অনলাইনে — ডাউনলোড করলে অফলাইনেও পড়া যাবে', 'Online for now — download to read offline');
  static const availableOffline = Tr('অফলাইনে পড়া যাবে', 'Available offline');
  static const downloadLimit = Tr('ফ্রি প্ল্যানে ৩টি বই ডাউনলোড করা যায় — প্রো নিলে ৫০টি।', 'The Free plan allows 3 downloads — Pro allows 50.');
  static const myNotes = Tr('আমার নোট ও হাইলাইট', 'My notes & highlights');
  static const history = Tr('পড়ার ইতিহাস', 'Reading history');
  static const pageNote = Tr('পৃষ্ঠার নোট', 'Page note');
  static const noteHint = Tr('এই পৃষ্ঠা নিয়ে তোমার নোট…', 'Your note on this page…');
  static const noteSaved = Tr('নোট সংরক্ষিত', 'Note saved');
  static const selectPassage = Tr('অংশ বেছে নাও', 'Pick a passage');
  static const selectHint = Tr('একটি বাক্য বেছে নিয়ে হাইলাইট করো বা AI দিয়ে ব্যাখ্যা নাও।', 'Pick a sentence to highlight it or get an AI explanation.');
  static const highlight = Tr('হাইলাইট', 'Highlight');
  static const highlighted = Tr('হাইলাইট করা হয়েছে', 'Highlighted');
  static const explain = Tr('AI ব্যাখ্যা', 'Explain with AI');
  static const askPage = Tr('এই পৃষ্ঠা নিয়ে AI-কে জিজ্ঞেস করো', 'Ask AI about this page');
  static const related = Tr('সম্পর্কিত', 'Related');
  static const relatedQuestions = Tr('সম্পর্কিত প্রশ্ন', 'Related questions');
  static const relatedNotes = Tr('সম্পর্কিত নোট', 'Related notes');
  static const resources = Tr('অধ্যায়ের রিসোর্স', 'Chapter resources');
  static const noRelated = Tr('কিছু পাওয়া যায়নি', 'Nothing found');
  static const practiseChapter = Tr('এই অধ্যায়ে অনুশীলন', 'Practise this chapter');
  static const flashcards = Tr('ফ্ল্যাশকার্ড', 'Flashcards');
  static const audio = Tr('অডিও রিভিশন', 'Audio revision');
  static const lab = Tr('ইন্টারঅ্যাক্টিভ ল্যাব', 'Interactive lab');
  static const lesson = Tr('পাঠ খুলুন', 'Open the lesson');
}

/// A highlighted passage on one page (LIB-19).
class Highlight {
  const Highlight(this.page, this.text, this.at);

  factory Highlight.fromJson(Map<String, dynamic> j) => Highlight(j['page'] as int, j['text'] as String, DateTime.parse(j['at'] as String));

  final int page;
  final String text;
  final DateTime at;

  Map<String, dynamic> toJson() => {'page': page, 'text': text, 'at': at.toIso8601String()};
}

/// Per-book reading state: last page, bookmarks, offline download, page notes, highlights
/// and reading history.
class BookReading {
  const BookReading({
    required this.bookId,
    this.lastPage,
    this.bookmarks = const [],
    this.downloaded = false,
    this.updatedAt,
    this.notes = const {},
    this.highlights = const [],
    this.history = const [],
  });

  factory BookReading.fromJson(Map<String, dynamic> j) => BookReading(
    bookId: j['bookId'] as String,
    lastPage: j['lastPage'] as int?,
    bookmarks: (j['bookmarks'] as List? ?? const []).cast<int>(),
    downloaded: j['downloaded'] as bool? ?? false,
    updatedAt: j['updatedAt'] == null ? null : DateTime.parse(j['updatedAt'] as String),
    notes: {for (final e in (j['notes'] as Map? ?? const {}).entries) int.parse(e.key as String): e.value as String},
    highlights: [for (final h in j['highlights'] as List? ?? const []) Highlight.fromJson((h as Map).cast())],
    history: [for (final h in j['history'] as List? ?? const []) ((h as Map)['page'] as int, DateTime.parse(h['at'] as String))],
  );

  final String bookId;
  final int? lastPage;
  final List<int> bookmarks;
  final bool downloaded;
  final DateTime? updatedAt;

  /// Page number → the student's note on that page (LIB-18).
  final Map<int, String> notes;
  final List<Highlight> highlights;

  /// Pages opened, newest first (LIB-16), capped at 30.
  final List<(int page, DateTime at)> history;

  List<Highlight> highlightsOn(int page) => [for (final h in highlights) if (h.page == page) h];

  BookReading copyWith({int? lastPage, List<int>? bookmarks, bool? downloaded, Map<int, String>? notes, List<Highlight>? highlights, List<(int, DateTime)>? history}) => BookReading(
    bookId: bookId,
    lastPage: lastPage ?? this.lastPage,
    bookmarks: bookmarks ?? this.bookmarks,
    downloaded: downloaded ?? this.downloaded,
    updatedAt: DateTime.now(),
    notes: notes ?? this.notes,
    highlights: highlights ?? this.highlights,
    history: history ?? this.history,
  );

  Map<String, dynamic> toJson() => {
    'bookId': bookId,
    'lastPage': lastPage,
    'bookmarks': bookmarks,
    'downloaded': downloaded,
    'updatedAt': updatedAt?.toIso8601String(),
    'notes': {for (final e in notes.entries) '${e.key}': e.value},
    'highlights': [for (final h in highlights) h.toJson()],
    'history': [for (final (p, at) in history) {'page': p, 'at': at.toIso8601String()}],
  };
}

/// Free plan download limit (LIB-25, same as the plan list).
const freeDownloadLimit = 3;

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

  Future<void> openedPage(String bookId, int page) {
    final r = of(bookId);
    final history = [(page, DateTime.now()), ...r.history.where((h) => h.$1 != page)].take(30).toList();
    return _put(r.copyWith(lastPage: page, history: history));
  }

  /// Saves (or clears, when [text] is empty) the note on a page.
  Future<void> setNote(String bookId, int page, String text) {
    final r = of(bookId);
    final notes = {...r.notes};
    if (text.trim().isEmpty) {
      notes.remove(page);
    } else {
      notes[page] = text.trim();
    }
    return _put(r.copyWith(notes: notes));
  }

  Future<void> addHighlight(String bookId, int page, String text) {
    final r = of(bookId);
    if (text.trim().isEmpty || r.highlights.any((h) => h.page == page && h.text == text.trim())) return Future.value();
    return _put(r.copyWith(highlights: [...r.highlights, Highlight(page, text.trim(), DateTime.now())]));
  }

  Future<void> removeHighlight(String bookId, Highlight h) {
    final r = of(bookId);
    return _put(r.copyWith(highlights: [for (final x in r.highlights) if (!(x.page == h.page && x.text == h.text)) x]));
  }

  int get downloadedCount => state.values.where((r) => r.downloaded).length;

  Future<bool> toggleBookmark(String bookId, int page) async {
    final r = of(bookId);
    final on = !r.bookmarks.contains(page);
    await _put(r.copyWith(bookmarks: on ? ([...r.bookmarks, page]..sort()) : [for (final p in r.bookmarks) if (p != page) p]));
    return on;
  }

  Future<void> setDownloaded(String bookId, bool value) => _put(of(bookId).copyWith(downloaded: value));
}

final libraryProvider = NotifierProvider<LibraryController, Map<String, BookReading>>(LibraryController.new);
