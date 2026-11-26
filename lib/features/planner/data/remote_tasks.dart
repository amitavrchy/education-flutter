import '../../../core/l10n/tr.dart';
import '../domain/study_task.dart';

/// Maps planner tasks between the app and the backend's (web) records.
abstract final class TaskMapper {
  static TaskKind kindOf(String? type) => switch (type) {
    'revision' => TaskKind.revision,
    'practice' || 'assignment' => TaskKind.practice,
    'exam_prep' => TaskKind.exam,
    _ => TaskKind.study,
  };

  /// App kinds → web task types (flashcard sessions are revision on the web).
  static String typeOf(TaskKind k) => switch (k) {
    TaskKind.revision || TaskKind.flashcards => 'revision',
    TaskKind.practice => 'practice',
    TaskKind.exam => 'exam_prep',
    TaskKind.study => 'study',
  };

  static TaskStatus statusOf(String? s) => switch (s) {
    'completed' => TaskStatus.done,
    'missed' => TaskStatus.missed,
    _ => TaskStatus.scheduled,
  };

  static String serverStatus(TaskStatus s) => switch (s) {
    TaskStatus.done => 'completed',
    TaskStatus.missed => 'missed',
    TaskStatus.scheduled => 'scheduled',
  };

  static int _minuteOf(String? hhmm) {
    final parts = (hhmm ?? '17:00').split(':');
    return (int.tryParse(parts.first) ?? 17) * 60 + (parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0);
  }

  static String _hhmm(int minute) => '${(minute ~/ 60).toString().padLeft(2, '0')}:${(minute % 60).toString().padLeft(2, '0')}';

  static String _date(DateTime d) => '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  static StudyTask fromApi(Map<String, dynamic> j) {
    final day = DateTime.tryParse(j['date'] as String? ?? '') ?? DateTime.now();
    final reflection = (j['reflection'] as Map?)?.cast<String, dynamic>();
    return StudyTask(
      id: j['id'] as String,
      title: Tr.same(j['title'] as String? ?? ''),
      kind: kindOf(j['type'] as String?),
      day: DateTime(day.year, day.month, day.day),
      startMinute: _minuteOf(j['start'] as String?),
      minutes: (j['durationMinutes'] as num?)?.round() ?? 30,
      subjectId: j['subjectId'] as String?,
      chapterId: j['chapterId'] as String?,
      status: statusOf(j['status'] as String?),
      priority: Priority.values.where((p) => p.name == j['priority']).firstOrNull ?? Priority.medium,
      note: j['notes'] as String? ?? '',
      generated: j['source'] == 'generated',
      reminder: j['reminder'] as bool? ?? true,
      completedAt: j['completedAt'] == null ? null : DateTime.tryParse(j['completedAt'] as String),
      actualMinutes: (reflection?['actualMinutes'] as num?)?.round(),
      focus: (reflection?['rating'] as num?)?.round(),
    );
  }

  static Map<String, dynamic> fields(StudyTask t) => {
    'title': t.title.bn,
    'type': typeOf(t.kind),
    'date': _date(t.day),
    'start': _hhmm(t.startMinute),
    'durationMinutes': t.minutes,
    'subjectId': t.subjectId,
    'chapterId': t.chapterId,
    'status': serverStatus(t.status),
    'priority': t.priority.name,
    'notes': t.note.isEmpty ? null : t.note,
    'reminder': t.reminder,
    'source': t.generated ? 'generated' : 'manual',
    'completedAt': t.completedAt?.toUtc().toIso8601String(),
    'reflection': t.actualMinutes == null ? null : {'rating': (t.focus ?? 3).clamp(1, 5), 'actualMinutes': t.actualMinutes},
    'updatedAt': DateTime.now().toUtc().toIso8601String(),
  };
}
