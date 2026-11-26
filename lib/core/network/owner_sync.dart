import 'dart:async';

import 'api_client.dart';

/// Syncs one student-owned collection (`/:collection/:studentId`) with the backend.
///
/// The backend stores the web app's record shape, so each feature maps records to and from
/// its own model. The last server record per id is kept and the app's fields are merged on
/// top when pushing, so fields only the web app knows about survive a round trip.
class OwnerSync {
  OwnerSync(this._api, {required this.collection, required this.studentId, this.debounce = const Duration(seconds: 1)});

  final ApiClient _api;
  final String collection;
  final String studentId;
  final Duration debounce;

  final Map<String, Map<String, dynamic>> _server = {};
  Timer? _timer;
  List<Map<String, dynamic>> Function()? _pending;

  String get _path => '/$collection/$studentId';

  /// The server's records (also remembered for merging).
  Future<List<Map<String, dynamic>>> pull() async {
    final res = await _api.get(_path, query: {'all': true}, parse: (d) => [for (final x in d! as List) (x as Map).cast<String, dynamic>()]);
    _server
      ..clear()
      ..addAll({for (final r in res.data) r['id'] as String: r});
    return res.data;
  }

  /// Merges the app's fields over the last known server record with the same id.
  /// [defaults] only fill fields a new record doesn't have yet.
  Map<String, dynamic> merge(String id, Map<String, dynamic> appFields, {Map<String, dynamic> defaults = const {}}) => {...defaults, ...?_server[id], ...appFields, 'id': id};

  /// Replaces the whole collection on the server (`PUT {items}`).
  Future<void> push(List<Map<String, dynamic>> items) async {
    await _api.put(_path, body: {'items': items}, parse: (d) => d);
    _server
      ..clear()
      ..addAll({for (final r in items) r['id'] as String: r});
  }

  /// Debounced [push]: bursts of edits send one request with the latest list.
  void schedule(List<Map<String, dynamic>> Function() items) {
    _pending = items;
    _timer?.cancel();
    _timer = Timer(debounce, flush);
  }

  /// Sends a scheduled push now (errors are swallowed; the next change retries).
  Future<void> flush() async {
    _timer?.cancel();
    final build = _pending;
    _pending = null;
    if (build == null) return;
    try {
      await push(build());
    } catch (_) {
      // Offline or rejected: the local copy stays; the next edit pushes again.
    }
  }

  void dispose() => _timer?.cancel();
}
