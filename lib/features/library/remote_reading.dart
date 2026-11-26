import 'library_controller.dart';

/// Maps reading state between the app and the web's `reading` records.
abstract final class ReadingMapper {
  /// `book-ssc-chemistry-bn` (web, per language edition) → `book-ssc-chemistry` (app).
  static String appBookId(String serverId) => serverId.replaceFirst(RegExp(r'-(bn|en)$'), '');

  /// App books are the Bangla editions on the web.
  static String serverBookId(String appId) => RegExp(r'-(bn|en)$').hasMatch(appId) ? appId : '$appId-bn';

  static DateTime? _date(Object? v) => v is String ? DateTime.tryParse(v) : null;

  /// [local] keeps what only the device knows: the download flag and the timed page history.
  static BookReading fromApi(Map<String, dynamic> j, BookReading? local) {
    final bookId = appBookId(j['bookId'] as String? ?? j['id'] as String);
    final updated = _date(j['updatedAt']);
    final pages = [for (final p in j['pagesRead'] as List? ?? const []) (p as num).round()];
    return BookReading(
      bookId: bookId,
      lastPage: (j['lastPage'] as num?)?.round(),
      bookmarks: [for (final p in j['bookmarks'] as List? ?? const []) (p as num).round()]..sort(),
      downloaded: local?.downloaded ?? false,
      updatedAt: updated,
      notes: {
        for (final n in j['pageNotes'] as List? ?? const []) ((n as Map)['page'] as num).round(): n['text'] as String? ?? '',
      },
      highlights: [
        for (final h in j['highlights'] as List? ?? const [])
          Highlight(((h as Map)['page'] as num).round(), h['text'] as String? ?? '', _date(h['createdAt']) ?? DateTime.now()),
      ],
      history: local?.history.isNotEmpty ?? false ? local!.history : [for (final p in pages.reversed) (p, updated ?? DateTime.now())],
    );
  }

  static Map<String, dynamic> fields(BookReading r, {List<int> serverPages = const []}) => {
    'bookId': serverBookId(r.bookId),
    'lastPage': r.lastPage ?? 1,
    'pagesRead': ({...serverPages, for (final (p, _) in r.history) p}.toList()..sort()),
    'bookmarks': r.bookmarks,
    'pageNotes': [
      for (final e in r.notes.entries) {'id': 'pn-${r.bookId}-${e.key}', 'page': e.key, 'text': e.value, 'createdAt': (r.updatedAt ?? DateTime.now()).toUtc().toIso8601String()},
    ],
    'highlights': [
      for (final (i, h) in r.highlights.indexed) {'id': 'hl-${r.bookId}-$i', 'page': h.page, 'text': h.text, 'color': 'yellow', 'createdAt': h.at.toUtc().toIso8601String()},
    ],
    'updatedAt': (r.updatedAt ?? DateTime.now()).toUtc().toIso8601String(),
  };

  static const defaults = {'zoom': 1};
}
