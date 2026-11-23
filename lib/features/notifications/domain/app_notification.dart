import 'package:material_ui/material_ui.dart';

import '../../../core/l10n/tr.dart';

enum NotificationCategory {
  study(Tr('পড়াশোনা', 'Study'), Icons.menu_book_outlined),
  exam(Tr('পরীক্ষা', 'Exams'), Icons.assignment_outlined),
  achievement(Tr('অর্জন', 'Achievements'), Icons.emoji_events_outlined),
  ai(Tr('AI', 'AI'), Icons.auto_awesome_outlined),
  system(Tr('সিস্টেম', 'System'), Icons.info_outline);

  const NotificationCategory(this.label, this.icon);

  final Tr label;
  final IconData icon;
}

@immutable
class AppNotification {
  const AppNotification({
    required this.id,
    required this.category,
    required this.title,
    required this.body,
    required this.createdAt,
    this.read = false,
    this.route,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) => AppNotification(
    id: json['id'] as String,
    category: NotificationCategory.values.byName(json['category'] as String),
    title: Tr.fromJson(json['title']),
    body: Tr.fromJson(json['body']),
    createdAt: DateTime.parse(json['createdAt'] as String),
    read: json['read'] as bool? ?? false,
    route: json['route'] as String?,
  );

  final String id;
  final NotificationCategory category;
  final Tr title;
  final Tr body;
  final DateTime createdAt;
  final bool read;

  /// In-app deep link opened on tap.
  final String? route;

  AppNotification copyWith({bool? read}) => AppNotification(
    id: id,
    category: category,
    title: title,
    body: body,
    createdAt: createdAt,
    read: read ?? this.read,
    route: route,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'category': category.name,
    'title': title.toJson(),
    'body': body.toJson(),
    'createdAt': createdAt.toIso8601String(),
    'read': read,
    'route': route,
  };
}
