import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/mock/json_collection.dart';
import '../../../core/storage/local_store.dart';
import '../../../mock/seed/notifications_seed.dart';
import '../domain/app_notification.dart';

/// Inbox state, newest first. Local-first: reads are synchronous from the store.
class NotificationsController extends Notifier<List<AppNotification>> {
  late JsonCollection<AppNotification> _collection;

  @override
  List<AppNotification> build() {
    _collection = JsonCollection<AppNotification>(
      store: watchStore(ref),
      name: 'notifications',
      fromJson: AppNotification.fromJson,
      toJson: (n) => n.toJson(),
      idOf: (n) => n.id,
      seed: seedNotifications,
    );
    return _sorted(_collection.all());
  }

  List<AppNotification> _sorted(List<AppNotification> items) =>
      items..sort((a, b) => b.createdAt.compareTo(a.createdAt));

  Future<void> markRead(String id) async {
    final item = state.where((n) => n.id == id).firstOrNull;
    if (item == null || item.read) return;
    final updated = item.copyWith(read: true);
    state = [for (final n in state) n.id == id ? updated : n];
    await _collection.upsert(updated);
  }

  Future<void> markAllRead() async {
    state = [for (final n in state) n.copyWith(read: true)];
    await _collection.upsertAll(state);
  }

  Future<void> remove(String id) async {
    state = state.where((n) => n.id != id).toList();
    await _collection.remove(id);
  }

  /// Adds a notification raised by another feature (exam graded, badge earned…).
  Future<void> push(AppNotification notification) async {
    state = _sorted([notification, ...state]);
    await _collection.upsert(notification);
  }
}

final notificationsProvider = NotifierProvider<NotificationsController, List<AppNotification>>(
  NotificationsController.new,
);

final unreadNotificationCountProvider = Provider<int>(
  (ref) => ref.watch(notificationsProvider).where((n) => !n.read).length,
);
