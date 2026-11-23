import '../storage/local_store.dart';

/// Typed view over one [LocalStore] collection, seeded on first use.
///
/// Mock repositories compose this so seeding, listing and CRUD are written once.
class JsonCollection<T> {
  JsonCollection({
    required this.store,
    required this.name,
    required this.fromJson,
    required this.toJson,
    required this.idOf,
    this.seed,
  });

  static const _metaCollection = '_meta';

  final LocalStore store;
  final String name;
  final T Function(Map<String, dynamic> json) fromJson;
  final Map<String, dynamic> Function(T value) toJson;
  final String Function(T value) idOf;
  final List<T> Function()? seed;

  bool get _seeded => store.get(_metaCollection, 'seeded:$name') != null;

  Future<void> ensureSeeded() async {
    if (_seeded) return;
    final initial = seed?.call() ?? const [];
    await store.putAll(name, {for (final item in initial) idOf(item): toJson(item)});
    await store.put(_metaCollection, 'seeded:$name', {'at': DateTime.now().toIso8601String()});
  }

  /// Seeds synchronously-visible data on first read. Writes are fire-and-forget here
  /// because the in-memory view is built from the seed directly.
  List<T> all() {
    if (!_seeded) {
      final initial = seed?.call() ?? <T>[];
      store.putAll(name, {for (final item in initial) idOf(item): toJson(item)});
      store.put(_metaCollection, 'seeded:$name', {'at': DateTime.now().toIso8601String()});
      return List.of(initial);
    }
    return store.all(name).map(fromJson).toList();
  }

  T? get(String id) {
    if (!_seeded) {
      for (final item in all()) {
        if (idOf(item) == id) return item;
      }
      return null;
    }
    final json = store.get(name, id);
    return json == null ? null : fromJson(json);
  }

  Future<T> upsert(T value) async {
    if (!_seeded) await ensureSeeded();
    await store.put(name, idOf(value), toJson(value));
    return value;
  }

  Future<void> upsertAll(Iterable<T> values) async {
    if (!_seeded) await ensureSeeded();
    await store.putAll(name, {for (final value in values) idOf(value): toJson(value)});
  }

  Future<void> remove(String id) async {
    if (!_seeded) await ensureSeeded();
    await store.delete(name, id);
  }
}
