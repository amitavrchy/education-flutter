import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/tr.dart';
import '../../../core/mock/json_collection.dart';
import '../../../core/storage/local_store.dart';
import '../../../mock/seed/notifications_seed.dart';
import '../../auth/application/auth_controller.dart';
import '../domain/app_notification.dart';

/// Path segment of the signed-in role (`student`, `parent`, `teacher`), or null when signed out.
final currentRoleProvider = Provider<String?>((ref) {
  final auth = ref.watch(authControllerProvider);
  return auth is Authenticated ? auth.user.role.pathSegment : null;
});

/// Inbox state, newest first. Local-first: reads are synchronous from the store.
///
/// The device keeps one store for every role (demo), so each notification carries an
/// optional audience and the views filter by the signed-in role.
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

  List<AppNotification> _sorted(List<AppNotification> items) => items..sort((a, b) => b.createdAt.compareTo(a.createdAt));

  Future<void> _replace(AppNotification updated) async {
    state = [for (final n in state) n.id == updated.id ? updated : n];
    await _collection.upsert(updated);
  }

  Future<void> markRead(String id, {bool read = true}) async {
    final item = state.where((n) => n.id == id).firstOrNull;
    if (item == null || item.read == read) return;
    await _replace(item.copyWith(read: read));
  }

  /// Marks every notification visible to [role] as read.
  Future<void> markAllRead({String? role}) async {
    state = [for (final n in state) n.isFor(role) ? n.copyWith(read: true) : n];
    await _collection.upsertAll(state);
  }

  Future<void> archive(String id, {bool archived = true}) async {
    final item = state.where((n) => n.id == id).firstOrNull;
    if (item == null) return;
    await _replace(item.copyWith(archived: archived, read: true));
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

  /// In-app simulation (NTF-15): raises a sample notification of [category] for [role].
  Future<AppNotification> simulate(NotificationCategory category, {String? role}) async {
    final sample = _samples[category]!;
    final n = AppNotification(
      id: 'sim-${DateTime.now().microsecondsSinceEpoch}',
      category: category,
      title: sample.$1,
      body: sample.$2,
      createdAt: DateTime.now(),
      audience: role,
      // Sample links point into the student app; other roles get a plain notice.
      route: role == null || role == 'student' ? sample.$3 : null,
      priority: category == NotificationCategory.exam ? NotificationPriority.high : NotificationPriority.normal,
    );
    await push(n);
    return n;
  }

  static const Map<NotificationCategory, (Tr, Tr, String?)> _samples = {
    NotificationCategory.study: (Tr('পড়ার সময় হয়েছে', 'Time to study'), Tr('আজকের পরিকল্পনায় ৩০ মিনিটের রিভিশন বাকি।', '30 minutes of revision left in today’s plan.'), '/planner'),
    NotificationCategory.exam: (Tr('আগামীকাল মডেল টেস্ট', 'Model test tomorrow'), Tr('পদার্থবিজ্ঞান মডেল টেস্ট আগামীকাল সকাল ১০টায়।', 'Physics model test tomorrow at 10 am.'), '/student/practice/exams'),
    NotificationCategory.achievement: (Tr('নতুন ব্যাজ!', 'New badge!'), Tr('তুমি “নিয়মিত পাঠক” ব্যাজ পেয়েছ।', 'You earned the “Regular reader” badge.'), '/achievements'),
    NotificationCategory.ai: (Tr('রিভিশনের সময়', 'Revision reminder'), Tr('১২টি ফ্ল্যাশকার্ড আজ রিভিউ করার কথা।', '12 flashcards are due for review today.'), '/flashcards'),
    NotificationCategory.system: (Tr('রক্ষণাবেক্ষণ', 'Maintenance'), Tr('রাত ২টা থেকে ৩টা পর্যন্ত কিছু ফিচার বন্ধ থাকতে পারে (ডেমো)।', 'Some features may be unavailable 2–3 am (demo).'), null),
    NotificationCategory.assignment: (Tr('নতুন অ্যাসাইনমেন্ট', 'New assignment'), Tr('“বলের সমস্যা — অনুশীলন” জমা দিতে হবে ২ দিনের মধ্যে।', '“Force problems — practice” is due in 2 days.'), '/student/practice/exams'),
    NotificationCategory.feedback: (Tr('শিক্ষকের মতামত এসেছে', 'Teacher feedback received'), Tr('তোমার সৃজনশীল উত্তরের মূল্যায়ন সম্পন্ন হয়েছে।', 'Your creative answer has been reviewed.'), '/handwriting'),
    NotificationCategory.billing: (Tr('পেমেন্ট সফল', 'Payment successful'), Tr('স্টুডেন্ট প্রো নবায়ন হয়েছে (ডেমো)।', 'Student Pro renewed (demo).'), '/subscription'),
    NotificationCategory.announcement: (Tr('কারিকুলাম আপডেট', 'Curriculum update'), Tr('২০২৬ সংস্করণের রসায়ন অধ্যায় ৪ যোগ হয়েছে (নমুনা ঘোষণা)।', 'Chemistry chapter 4 of the 2026 edition was added (sample notice).'), '/student/learn'),
  };
}

final notificationsProvider = NotifierProvider<NotificationsController, List<AppNotification>>(NotificationsController.new);

/// Inbox for the signed-in role, without muted categories.
final visibleNotificationsProvider = Provider<List<AppNotification>>((ref) {
  final role = ref.watch(currentRoleProvider);
  final prefs = ref.watch(notificationPrefsProvider);
  return [
    for (final n in ref.watch(notificationsProvider))
      if (n.isFor(role) && !prefs.mutedOn(n.category)) n,
  ];
});

final unreadNotificationCountProvider = Provider<int>(
  (ref) => ref.watch(visibleNotificationsProvider).where((n) => !n.read && !n.archived).length,
);

/// Channel preferences, persisted per device.
class NotificationPrefsController extends Notifier<NotificationPrefs> {
  static const _col = 'notificationPrefs';
  late LocalStore _store;

  @override
  NotificationPrefs build() {
    _store = watchStore(ref);
    final j = _store.get(_col, 'me');
    return j == null ? const NotificationPrefs() : NotificationPrefs.fromJson(j);
  }

  Future<void> _save(NotificationPrefs p) async {
    state = p;
    await _store.put(_col, 'me', p.toJson());
  }

  Future<void> setPush(NotificationCategory c, bool on) => _save(state.copyWith(push: {...state.push, c.name: on}));
  Future<void> setEmail(NotificationCategory c, bool on) => _save(state.copyWith(email: {...state.email, c.name: on}));
  Future<void> setMuted(NotificationCategory c, bool muted) =>
      _save(state.copyWith(muted: muted ? {...state.muted, c.name} : ({...state.muted}..remove(c.name))));
  Future<void> setPermission(PushPermission p) => _save(state.copyWith(pushPermission: p));
  Future<void> setQuietHours(bool on) => _save(state.copyWith(quietHours: on));
  Future<void> setDigest(bool on) => _save(state.copyWith(digest: on));
}

final notificationPrefsProvider = NotifierProvider<NotificationPrefsController, NotificationPrefs>(NotificationPrefsController.new);
