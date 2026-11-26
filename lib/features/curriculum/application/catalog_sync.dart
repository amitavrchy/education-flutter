import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/env.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/network_providers.dart';
import '../../../core/storage/local_store.dart';
import '../../auth/application/auth_controller.dart';
import '../../question_bank/data/question_mapper.dart';
import '../../question_bank/data/question_repository.dart';
import '../data/curriculum_catalog.dart';
import '../data/curriculum_repository.dart';

/// Status of the server curriculum + question bank on this device (API mode).
class CatalogState {
  const CatalogState({required this.ready, this.syncing = false, this.error, this.syncedAt, this.questions = 0});

  /// A curriculum is available (bundled in mock mode, cached or freshly synced in API mode).
  final bool ready;
  final bool syncing;
  final Object? error;
  final DateTime? syncedAt;
  final int questions;

  CatalogState copyWith({bool? ready, bool? syncing, Object? Function()? error, DateTime? syncedAt, int? questions}) => CatalogState(
    ready: ready ?? this.ready,
    syncing: syncing ?? this.syncing,
    error: error == null ? this.error : error(),
    syncedAt: syncedAt ?? this.syncedAt,
    questions: questions ?? this.questions,
  );
}

/// Pulls the backend's curriculum (`/subjects`, `/papers`, `/chapters`, `/topics`, `/outcomes`)
/// and question bank (`/questions`) into the local store, so every screen works on the
/// server's ids and stays usable offline. Mock mode keeps the bundled sample data.
class CatalogSync extends Notifier<CatalogState> {
  static const collection = 'catalog';
  static const curriculumKey = 'curriculum';
  static const _resources = ['subjects', 'papers', 'chapters', 'topics', 'outcomes'];

  LocalStore get _store => ref.read(localStoreProvider);

  @override
  CatalogState build() {
    if (Env.useMockApi) return const CatalogState(ready: true);
    final cached = _store.get(collection, curriculumKey);
    if (cached != null) apply(cached);
    ref.listen(authControllerProvider, (prev, next) {
      if (next is Authenticated && prev is! Authenticated) Future.microtask(sync);
    }, fireImmediately: true);
    return CatalogState(ready: cached != null, syncedAt: cached == null ? null : DateTime.tryParse(cached['syncedAt'] as String? ?? ''));
  }

  /// Installs a cached/raw curriculum document as the active catalog.
  static void apply(Map<String, dynamic> doc) {
    List<Map<String, dynamic>> list(String k) => [for (final x in doc[k] as List? ?? const []) (x as Map).cast<String, dynamic>()];
    CurriculumCatalog.use(subjectsFromApi(subjects: list('subjects'), papers: list('papers'), chapters: list('chapters'), topics: list('topics'), outcomes: list('outcomes')));
  }

  Future<List<Map<String, dynamic>>> _all(ApiClient api, String path) async {
    final res = await api.get(path, query: {'all': true}, parse: (d) => [for (final x in d! as List) (x as Map).cast<String, dynamic>()]);
    return res.data;
  }

  Future<void> sync() async {
    if (Env.useMockApi || state.syncing || !ref.mounted) return;
    state = state.copyWith(syncing: true, error: () => null);
    try {
      final api = ref.read(apiClientProvider);
      final doc = <String, dynamic>{for (final r in _resources) r: await _all(api, '/$r')};
      doc['syncedAt'] = DateTime.now().toIso8601String();
      apply(doc);
      final questions = questionsWithKnownChapter(await _all(api, '/questions'), CurriculumCatalog.subjects);
      final store = _store;
      await store.put(collection, curriculumKey, doc);
      await store.clearCollection('questions');
      await store.putAll('questions', {for (final q in questions) q['id'] as String: questionFromApi(q).toJson()});
      await store.put('_meta', 'seeded:questions', {'at': doc['syncedAt']});
      if (!ref.mounted) return;
      ref
        ..invalidate(curriculumRepositoryProvider)
        ..invalidate(questionRepositoryProvider);
      state = CatalogState(ready: true, syncedAt: DateTime.now(), questions: questions.length);
    } catch (e) {
      if (ref.mounted) state = state.copyWith(syncing: false, error: () => e);
    }
  }
}

final catalogSyncProvider = NotifierProvider<CatalogSync, CatalogState>(CatalogSync.new);
