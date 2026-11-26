import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/network_providers.dart';
import '../../../core/storage/local_store.dart';
import '../../account/account_controller.dart';
import '../../progress/data/remote_progress.dart';
import '../data/remote_profile.dart';
import '../domain/student_profile.dart';

class StudentProfileController extends Notifier<StudentProfile> {
  static const collection = 'profile';
  static const _id = 'student';

  RemoteProfile? _remote;
  bool _exists = false;

  /// The server profile's privacy object (sent back whole, since a patch replaces it).
  Map<String, dynamic> _serverPrivacy = {};
  Future<void>? _refreshing;

  @override
  StudentProfile build() {
    final json = ref.watch(localStoreProvider).get(collection, _id);
    final progress = ref.watch(remoteProgressProvider);
    _remote = progress == null ? null : RemoteProfile(ref.read(apiClientProvider), progress.studentId);
    if (_remote != null) Future.microtask(refresh);
    return json == null ? const StudentProfile() : StudentProfile.fromJson(json);
  }

  /// API mode: the server profile replaces the local one (single-flight).
  Future<void> refresh() => _refreshing ??= _refresh().whenComplete(() => _refreshing = null);

  Future<void> _refresh() async {
    final remote = _remote;
    if (remote == null || !ref.mounted) return;
    try {
      final j = await remote.load();
      if (j == null || !ref.mounted) return;
      _exists = true;
      _serverPrivacy = (j['privacy'] as Map? ?? const {}).cast<String, dynamic>();
      state = RemoteProfile.fromApi(j, state);
      await ref.read(localStoreProvider).put(collection, _id, state.toJson());
      await ref.read(accountProvider.notifier).applyServerPrivacy(RemoteProfile.privacyFrom(j));
    } catch (_) {
      // Offline: keep the cached profile.
    }
  }

  Future<void> update(StudentProfile Function(StudentProfile current) change) async {
    state = change(state);
    await ref.read(localStoreProvider).put(collection, _id, state.toJson());
    final remote = _remote;
    if (remote == null || !state.onboarded) return;
    try {
      await remote.save(state, exists: _exists);
      _exists = true;
    } catch (_) {
      // Saved on the device; the next change or refresh tries again.
    }
  }

  /// Mirrors an app privacy switch onto the server profile when the server knows it.
  Future<void> syncPrivacy(String key, bool value) async {
    final remote = _remote;
    final serverKey = RemoteProfile.privacyKeys[key];
    if (remote == null || serverKey == null || !_exists) return;
    _serverPrivacy = {..._serverPrivacy, serverKey: value};
    await remote.savePrivacy(_serverPrivacy);
  }
}

final studentProfileProvider = NotifierProvider<StudentProfileController, StudentProfile>(
  StudentProfileController.new,
);
