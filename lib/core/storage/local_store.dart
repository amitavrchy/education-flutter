import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ce/hive.dart';

/// Document store used by the mock repositories and settings.
///
/// Documents are JSON maps grouped in collections. Reads are synchronous (the backing box
/// is opened at startup), writes are async. Swapping in a real API never touches this:
/// repositories hide it behind their interfaces.
abstract class LocalStore {
  Map<String, dynamic>? get(String collection, String id);

  List<Map<String, dynamic>> all(String collection);

  Future<void> put(String collection, String id, Map<String, dynamic> doc);

  Future<void> putAll(String collection, Map<String, Map<String, dynamic>> docs);

  Future<void> delete(String collection, String id);

  Future<void> clearCollection(String collection);

  /// Removes everything except the [keep] collections (used by "reset demo data").
  Future<void> clearAll({Set<String> keep = const {}});

  /// Rough size in bytes, shown in storage settings.
  int get approximateBytes;
}

String _key(String collection, String id) => '$collection/$id';

/// Hive CE implementation: one box, keys `collection/id`, values JSON strings.
class HiveLocalStore extends LocalStore {
  HiveLocalStore(this._box);

  static const boxName = 'edumentor_store';

  static Future<HiveLocalStore> open() async => HiveLocalStore(await Hive.openBox<String>(boxName));

  final Box<String> _box;

  @override
  Map<String, dynamic>? get(String collection, String id) {
    final raw = _box.get(_key(collection, id));
    return raw == null ? null : jsonDecode(raw) as Map<String, dynamic>;
  }

  @override
  List<Map<String, dynamic>> all(String collection) {
    final prefix = '$collection/';
    return [
      for (final key in _box.keys)
        if (key is String && key.startsWith(prefix))
          jsonDecode(_box.get(key)!) as Map<String, dynamic>,
    ];
  }

  @override
  Future<void> put(String collection, String id, Map<String, dynamic> doc) =>
      _box.put(_key(collection, id), jsonEncode(doc));

  @override
  Future<void> putAll(String collection, Map<String, Map<String, dynamic>> docs) => _box.putAll({
    for (final entry in docs.entries) _key(collection, entry.key): jsonEncode(entry.value),
  });

  @override
  Future<void> delete(String collection, String id) => _box.delete(_key(collection, id));

  @override
  Future<void> clearCollection(String collection) =>
      _box.deleteAll(_box.keys.where((key) => key is String && key.startsWith('$collection/')));

  @override
  Future<void> clearAll({Set<String> keep = const {}}) => _box.deleteAll(
    _box.keys.where((key) => key is String && !keep.any((c) => key.startsWith('$c/'))),
  );

  @override
  int get approximateBytes =>
      _box.values.fold<int>(0, (sum, value) => sum + value.length) + _box.length * 24;
}

/// In-memory implementation for tests and as a fallback.
class MemoryLocalStore extends LocalStore {
  final Map<String, String> _data = {};

  @override
  Map<String, dynamic>? get(String collection, String id) {
    final raw = _data[_key(collection, id)];
    return raw == null ? null : jsonDecode(raw) as Map<String, dynamic>;
  }

  @override
  List<Map<String, dynamic>> all(String collection) => [
    for (final entry in _data.entries)
      if (entry.key.startsWith('$collection/')) jsonDecode(entry.value) as Map<String, dynamic>,
  ];

  @override
  Future<void> put(String collection, String id, Map<String, dynamic> doc) async =>
      _data[_key(collection, id)] = jsonEncode(doc);

  @override
  Future<void> putAll(String collection, Map<String, Map<String, dynamic>> docs) async {
    docs.forEach((id, doc) => _data[_key(collection, id)] = jsonEncode(doc));
  }

  @override
  Future<void> delete(String collection, String id) async => _data.remove(_key(collection, id));

  @override
  Future<void> clearCollection(String collection) async =>
      _data.removeWhere((key, _) => key.startsWith('$collection/'));

  @override
  Future<void> clearAll({Set<String> keep = const {}}) async =>
      _data.removeWhere((key, _) => !keep.any((c) => key.startsWith('$c/')));

  @override
  int get approximateBytes => _data.values.fold<int>(0, (sum, value) => sum + value.length);
}

/// Overridden in main.dart with the opened Hive store; tests use [MemoryLocalStore].
final localStoreProvider = Provider<LocalStore>((ref) => MemoryLocalStore());

/// Bumped by "reset demo data". Every store-backed controller watches it so a reset
/// rebuilds all features from their seeds without each feature knowing about the others.
class DataEpoch extends Notifier<int> {
  @override
  int build() => 0;

  void bump() => state++;
}

final dataEpochProvider = NotifierProvider<DataEpoch, int>(DataEpoch.new);

/// Store accessor for controllers: watches the store and the reset epoch.
LocalStore watchStore(Ref ref) {
  ref.watch(dataEpochProvider);
  return ref.watch(localStoreProvider);
}
