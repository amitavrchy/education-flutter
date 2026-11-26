import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/config/env.dart';
import '../../core/l10n/tr.dart';
import '../../core/network/api_client.dart';
import '../../core/network/network_providers.dart';
import '../auth/application/auth_controller.dart';
import 'archive_data.dart';

/// The backend's paper archive (`/board-papers`, `/institution-papers`, `/institutions`), kept in
/// memory once loaded. While it is loaded, `archive_data.dart` builds papers from it instead of
/// the demo generator; the question ids are the server's (the bank is synced from the server).
abstract final class ArchiveCatalog {
  static List<Map<String, dynamic>>? _board;
  static List<Map<String, dynamic>>? _institution;
  static Map<String, DemoInstitution> _institutions = const {};

  static bool get loaded => _board != null;

  static void load({
    required List<Map<String, dynamic>> board,
    required List<Map<String, dynamic>> institution,
    required List<Map<String, dynamic>> institutions,
  }) {
    _institutions = {for (final i in institutions) i['id'] as String: institutionFrom(i)};
    _board = board;
    // Students see approved, licensed papers only (the server also hides other schools' private ones).
    _institution = [
      for (final p in institution)
        if (p['moderation'] == 'approved' && p['license'] == 'granted') p,
    ];
  }

  /// Back to the demo generator (sign-out, mock mode, tests).
  static void clear() {
    _board = null;
    _institution = null;
    _institutions = const {};
  }

  static const _districts = {
    'Dhaka': 'ঢাকা',
    'Chattogram': 'চট্টগ্রাম',
    'Rajshahi': 'রাজশাহী',
    'Khulna': 'খুলনা',
    'Barishal': 'বরিশাল',
    'Sylhet': 'সিলেট',
    'Rangpur': 'রংপুর',
    'Mymensingh': 'ময়মনসিংহ',
    'Cumilla': 'কুমিল্লা',
    'Jashore': 'যশোর',
    'Dinajpur': 'দিনাজপুর',
    'Gazipur': 'গাজীপুর',
    'Narayanganj': 'নারায়ণগঞ্জ',
    'Bogura': 'বগুড়া',
  };

  static DemoInstitution institutionFrom(Map<String, dynamic> j) {
    final name = j['name'];
    final district = j['district'] as String? ?? '';
    return DemoInstitution(
      j['id'] as String,
      name is Map ? Tr(name['bn'] as String? ?? '', name['en'] as String? ?? '') : Tr.same(name as String? ?? ''),
      Tr(_districts[district] ?? district, district),
      j['type'] == 'college',
    );
  }

  static const _categories = {
    'half_yearly': PaperCategory.halfYearly,
    'annual': PaperCategory.annual,
    'test': PaperCategory.test,
    'pre_test': PaperCategory.preTest,
    'selection_test': PaperCategory.selection,
    'model_test': PaperCategory.model,
  };

  static PaperCategory categoryOf(String? c) => _categories[c] ?? PaperCategory.test;

  static List<DemoInstitution> get institutions => _institutions.values.toList();

  /// Server papers (MCQ and creative) of one subject, board and year.
  static List<Map<String, dynamic>> boardPapers(String subjectId, String boardId, int year) => [
    for (final p in _board ?? const <Map<String, dynamic>>[])
      if (p['subjectId'] == subjectId && p['boardId'] == 'brd-$boardId' && p['year'] == year) p,
  ];

  static List<Map<String, dynamic>> get institutionPapers => _institution ?? const [];

  /// The web's bookmark id for an app paper: board papers save their first server paper.
  static String? serverPaperId(String appId) {
    if (!appId.startsWith('bp-')) return appId;
    final parts = appId.split('-');
    final papers = boardPapers(parts.sublist(3).join('-'), parts[1], int.tryParse(parts[2]) ?? 0);
    return papers.isEmpty ? null : papers.first['id'] as String;
  }

  /// `bp-ssc-physics-dhaka-2016-mcq` (web) → `bp-dhaka-2016-ssc-physics` (app).
  static String appPaperId(String serverId) {
    final p = (_board ?? const <Map<String, dynamic>>[]).where((x) => x['id'] == serverId).firstOrNull;
    if (p == null) return serverId;
    return 'bp-${(p['boardId'] as String).replaceFirst('brd-', '')}-${p['year']}-${p['subjectId']}';
  }
}

class RemoteArchive {
  RemoteArchive(this._api, this.userId);

  final ApiClient _api;
  final String userId;

  List<Map<String, dynamic>> _list(Object? d) => [for (final x in d! as List) (x as Map).cast<String, dynamic>()];

  Future<List<Map<String, dynamic>>> _all(String path) async => (await _api.get(path, query: {'all': true}, parse: _list)).data;

  Future<void> loadCatalog() async {
    final (board, institution, institutions) = await (_all('/board-papers'), _all('/institution-papers'), _all('/institutions')).wait;
    ArchiveCatalog.load(board: board, institution: institution, institutions: institutions);
  }

  /// Saved papers are the web's `board_paper` / `institution_paper` bookmarks: app id → bookmark id.
  Future<Map<String, String>> savedPapers() async => {
    for (final b in await _all('/bookmarks/$userId'))
      if ((b['kind'] == 'board_paper' || b['kind'] == 'institution_paper') && b['refId'] is String)
        ArchiveCatalog.appPaperId(b['refId'] as String): b['id'] as String,
  };

  Future<String?> save(ArchivePaper paper) async {
    final refId = ArchiveCatalog.serverPaperId(paper.id);
    if (refId == null) return null;
    final id = 'bm-${DateTime.now().microsecondsSinceEpoch}';
    await _api.post(
      '/bookmarks/$userId',
      body: {
        'id': id,
        'kind': paper.isBoard ? 'board_paper' : 'institution_paper',
        'refId': refId,
        'title': paper.title.bn,
        'subtitle': paper.isBoard ? 'বোর্ড প্রশ্ন (কৃত্রিম)' : (paper.institution?.name.bn ?? ''),
        'href': paper.isBoard ? '/student/board-questions/$refId' : '/student/institution-questions/$refId',
        'createdAt': DateTime.now().toUtc().toIso8601String(),
      },
      parse: (d) => d,
    );
    return id;
  }

  Future<void> unsave(String bookmarkId) => _api.sendNoContent('DELETE', '/bookmarks/$userId/$bookmarkId');

  /// Moderators see it in the content-report queue (the server stamps the reporter).
  Future<void> report(ArchivePaper paper, String reason) => _api.post(
    '/content-reports',
    body: {
      'id': 'rep-${DateTime.now().microsecondsSinceEpoch}',
      'kind': paper.isBoard ? 'board_paper' : 'institution_paper',
      'refId': ArchiveCatalog.serverPaperId(paper.id) ?? paper.id,
      'reason': reason,
      'reporterId': userId,
      'status': 'open',
      'createdAt': DateTime.now().toUtc().toIso8601String(),
    },
    parse: (d) => d,
  );
}

/// The signed-in user's archive on the server (API mode); null with the mock.
final remoteArchiveProvider = Provider<RemoteArchive?>((ref) {
  if (Env.useMockApi) return null;
  final auth = ref.watch(authControllerProvider);
  if (auth is! Authenticated) return null;
  return RemoteArchive(ref.watch(apiClientProvider), auth.user.id);
});
