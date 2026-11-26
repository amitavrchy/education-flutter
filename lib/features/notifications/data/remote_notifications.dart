import '../../../core/l10n/tr.dart';
import '../../../core/network/api_client.dart';
import '../domain/app_notification.dart';

/// Server notifications (`/notifications`, scoped to the signed-in user). The backend uses the
/// web app's shape (`type`, `href`, `portal`); this maps it onto the app's model.
class RemoteNotifications {
  RemoteNotifications(this._api);

  final ApiClient _api;

  /// Server ids start with `ntf-`; anything else was raised on this device.
  static bool isServerId(String id) => id.startsWith('ntf-');

  static NotificationCategory categoryOf(String type) => switch (type) {
    'exam_result' || 'upcoming_exam' => NotificationCategory.exam,
    'achievement' => NotificationCategory.achievement,
    'study_reminder' || 'revision_reminder' => NotificationCategory.study,
    'new_assignment' => NotificationCategory.assignment,
    'teacher_feedback' => NotificationCategory.feedback,
    'subscription' || 'payment' => NotificationCategory.billing,
    'curriculum_update' || 'board_announcement' || 'content_correction' => NotificationCategory.announcement,
    _ => NotificationCategory.system,
  };

  /// Web paths → app routes (best effort; unknown paths open nothing).
  static String? routeOf(String? href) {
    if (href == null) return null;
    const map = {
      '/student/exams': '/student/practice/exams',
      '/student/results': '/student/practice/results',
      '/student/achievements': '/achievements',
      '/student/study-planner': '/planner',
      '/student/subscription': '/subscription',
      '/student/curriculum': '/student/learn',
      '/student/questions': '/student/practice/bank',
      '/student/flashcards': '/flashcards',
      '/student/notes': '/notes',
      '/student/library': '/library',
      '/student/answer-evaluation': '/handwriting',
      '/parent/reports': '/parent-reports',
      '/parent/results': '/parent-results',
      '/parent/feedback': '/parent-feedback',
      '/parent': '/parent/home',
      '/teacher/review': '/teacher-review',
      '/teacher/evaluations': '/teacher/evaluation',
      '/teacher/students': '/teacher-students',
      '/teacher/history': '/teacher-history',
      '/teacher': '/teacher/home',
    };
    for (final e in map.entries) {
      if (href == e.key || href.startsWith('${e.key}/')) return e.value;
    }
    return null;
  }

  static AppNotification fromJson(Map<String, dynamic> j) => AppNotification(
    id: j['id'] as String,
    category: categoryOf(j['type'] as String? ?? ''),
    title: Tr.same(j['title'] as String? ?? ''),
    body: Tr.same(j['body'] as String? ?? ''),
    createdAt: DateTime.parse(j['createdAt'] as String),
    read: j['read'] as bool? ?? false,
    archived: j['archived'] as bool? ?? false,
    route: routeOf(j['href'] as String?),
    audience: j['portal'] as String?,
    priority: switch (j['priority']) {
      'high' || 'urgent' => NotificationPriority.high,
      'low' => NotificationPriority.low,
      _ => NotificationPriority.normal,
    },
  );

  Future<List<AppNotification>> all() async {
    final res = await _api.get('/notifications', query: {'all': true}, parse: (d) => [for (final x in d! as List) fromJson((x as Map).cast<String, dynamic>())]);
    return res.data;
  }

  Future<void> update(String id, {bool? read, bool? archived}) =>
      _api.patch('/notifications/$id', body: {'read': ?read, 'archived': ?archived}, parse: (d) => d);

  Future<void> remove(String id) => _api.sendNoContent('DELETE', '/notifications/$id');

  Future<void> markAllRead(String? portal) => _api.post('/notifications/read-all', body: {'portal': ?portal}, parse: (d) => d);
}
