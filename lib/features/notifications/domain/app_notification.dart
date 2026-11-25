import 'package:material_ui/material_ui.dart';

import '../../../core/l10n/tr.dart';

/// Notification types (web §43 NTF-01..04), grouped into the inbox filter chips.
///
/// Enum names are persisted; add new values at the end.
enum NotificationCategory {
  study(Tr('পড়াশোনা', 'Study'), Icons.menu_book_outlined),
  exam(Tr('পরীক্ষা', 'Exams'), Icons.assignment_outlined),
  achievement(Tr('অর্জন', 'Achievements'), Icons.emoji_events_outlined),
  ai(Tr('AI', 'AI'), Icons.auto_awesome_outlined),
  system(Tr('সিস্টেম', 'System'), Icons.info_outline),
  assignment(Tr('অ্যাসাইনমেন্ট', 'Assignments'), Icons.task_outlined),
  feedback(Tr('শিক্ষকের মতামত', 'Teacher feedback'), Icons.rate_review_outlined),
  billing(Tr('সাবস্ক্রিপশন ও পেমেন্ট', 'Subscription & payment'), Icons.receipt_long_outlined),
  announcement(Tr('বোর্ড ও কারিকুলাম', 'Board & curriculum'), Icons.campaign_outlined);

  const NotificationCategory(this.label, this.icon);

  final Tr label;
  final IconData icon;
}

/// Urgency shown as a coloured marker; `high` also pops an in-app banner.
enum NotificationPriority { low, normal, high }

@immutable
class AppNotification {
  const AppNotification({
    required this.id,
    required this.category,
    required this.title,
    required this.body,
    required this.createdAt,
    this.read = false,
    this.archived = false,
    this.route,
    this.audience,
    this.priority = NotificationPriority.normal,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) => AppNotification(
    id: json['id'] as String,
    category: NotificationCategory.values.byName(json['category'] as String),
    title: Tr.fromJson(json['title']),
    body: Tr.fromJson(json['body']),
    createdAt: DateTime.parse(json['createdAt'] as String),
    read: json['read'] as bool? ?? false,
    archived: json['archived'] as bool? ?? false,
    route: json['route'] as String?,
    audience: json['audience'] as String?,
    priority: NotificationPriority.values.byName(json['priority'] as String? ?? 'normal'),
  );

  final String id;
  final NotificationCategory category;
  final Tr title;
  final Tr body;
  final DateTime createdAt;
  final bool read;
  final bool archived;

  /// In-app deep link opened from the detail view.
  final String? route;

  /// Role path segment (`student`, `parent`, `teacher`) the notification is for; null = everyone.
  final String? audience;
  final NotificationPriority priority;

  bool isFor(String? role) => audience == null || role == null || audience == role;

  AppNotification copyWith({bool? read, bool? archived}) => AppNotification(
    id: id,
    category: category,
    title: title,
    body: body,
    createdAt: createdAt,
    read: read ?? this.read,
    archived: archived ?? this.archived,
    route: route,
    audience: audience,
    priority: priority,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'category': category.name,
    'title': title.toJson(),
    'body': body.toJson(),
    'createdAt': createdAt.toIso8601String(),
    'read': read,
    'archived': archived,
    'route': route,
    'audience': audience,
    'priority': priority.name,
  };
}

/// Per-category channel choices (web NTF-12..14). In-app is always on.
@immutable
class NotificationPrefs {
  const NotificationPrefs({
    this.push = const {},
    this.email = const {},
    this.muted = const {},
    this.pushPermission = PushPermission.unknown,
    this.quietHours = false,
    this.digest = false,
  });

  factory NotificationPrefs.fromJson(Map<String, dynamic> j) => NotificationPrefs(
    push: (j['push'] as Map? ?? const {}).cast<String, bool>(),
    email: (j['email'] as Map? ?? const {}).cast<String, bool>(),
    muted: {...(j['muted'] as List? ?? const []).cast<String>()},
    pushPermission: PushPermission.values.byName(j['pushPermission'] as String? ?? 'unknown'),
    quietHours: j['quietHours'] as bool? ?? false,
    digest: j['digest'] as bool? ?? false,
  );

  final Map<String, bool> push;
  final Map<String, bool> email;

  /// Categories hidden from the inbox entirely.
  final Set<String> muted;
  final PushPermission pushPermission;

  /// No push between 22:00 and 07:00.
  final bool quietHours;

  /// One weekly email instead of one per event.
  final bool digest;

  bool pushOn(NotificationCategory c) => pushPermission == PushPermission.granted && (push[c.name] ?? c != NotificationCategory.system);
  bool emailOn(NotificationCategory c) => email[c.name] ?? (c == NotificationCategory.billing || c == NotificationCategory.exam);
  bool mutedOn(NotificationCategory c) => muted.contains(c.name);

  NotificationPrefs copyWith({Map<String, bool>? push, Map<String, bool>? email, Set<String>? muted, PushPermission? pushPermission, bool? quietHours, bool? digest}) =>
      NotificationPrefs(
        push: push ?? this.push,
        email: email ?? this.email,
        muted: muted ?? this.muted,
        pushPermission: pushPermission ?? this.pushPermission,
        quietHours: quietHours ?? this.quietHours,
        digest: digest ?? this.digest,
      );

  Map<String, dynamic> toJson() => {
    'push': push,
    'email': email,
    'muted': muted.toList(),
    'pushPermission': pushPermission.name,
    'quietHours': quietHours,
    'digest': digest,
  };
}

/// Simulated OS permission state for push notifications.
enum PushPermission { unknown, granted, denied }
