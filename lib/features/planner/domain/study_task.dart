import 'package:material_ui/material_ui.dart';

import '../../../core/l10n/tr.dart';

enum TaskKind {
  study(Tr('নতুন পড়া', 'Study'), Icons.menu_book_outlined),
  revision(Tr('রিভিশন', 'Revision'), Icons.replay),
  practice(Tr('অনুশীলন', 'Practice'), Icons.quiz_outlined),
  exam(Tr('মডেল টেস্ট', 'Model test'), Icons.assignment_outlined),
  flashcards(Tr('ফ্ল্যাশকার্ড', 'Flashcards'), Icons.style_outlined);

  const TaskKind(this.label, this.icon);

  final Tr label;
  final IconData icon;
}

enum TaskStatus { scheduled, done, missed }

enum Priority {
  high(Tr('উচ্চ', 'High')),
  medium(Tr('মাঝারি', 'Medium')),
  low(Tr('কম', 'Low'));

  const Priority(this.label);

  final Tr label;
}

enum StudyTime {
  morning(Tr('সকাল', 'Morning'), 7 * 60),
  afternoon(Tr('বিকেল', 'Afternoon'), 15 * 60),
  evening(Tr('সন্ধ্যা', 'Evening'), 19 * 60),
  night(Tr('রাত', 'Night'), 21 * 60);

  const StudyTime(this.label, this.startMinute);

  final Tr label;
  final int startMinute;
}

@immutable
class StudyTask {
  const StudyTask({
    required this.id,
    required this.title,
    required this.kind,
    required this.day,
    required this.startMinute,
    required this.minutes,
    this.subjectId,
    this.chapterId,
    this.topicId,
    this.status = TaskStatus.scheduled,
    this.priority = Priority.medium,
    this.note = '',
    this.generated = false,
    this.reminder = true,
    this.completedAt,
    this.actualMinutes,
    this.focus,
  });

  factory StudyTask.fromJson(Map<String, dynamic> j) => StudyTask(
    id: j['id'] as String,
    title: Tr.fromJson(j['title']),
    kind: TaskKind.values.byName(j['kind'] as String),
    day: DateTime.parse(j['day'] as String),
    startMinute: j['startMinute'] as int,
    minutes: j['minutes'] as int,
    subjectId: j['subjectId'] as String?,
    chapterId: j['chapterId'] as String?,
    topicId: j['topicId'] as String?,
    status: TaskStatus.values.byName(j['status'] as String? ?? 'scheduled'),
    priority: Priority.values.byName(j['priority'] as String? ?? 'medium'),
    note: j['note'] as String? ?? '',
    generated: j['generated'] as bool? ?? false,
    reminder: j['reminder'] as bool? ?? true,
    completedAt: j['completedAt'] == null ? null : DateTime.parse(j['completedAt'] as String),
    actualMinutes: j['actualMinutes'] as int?,
    focus: j['focus'] as int?,
  );

  final String id;
  final Tr title;
  final TaskKind kind;

  /// Calendar day (time part ignored).
  final DateTime day;
  final int startMinute;
  final int minutes;
  final String? subjectId;
  final String? chapterId;
  final String? topicId;
  final TaskStatus status;
  final Priority priority;
  final String note;
  final bool generated;
  final bool reminder;
  final DateTime? completedAt;
  final int? actualMinutes;

  /// Self-rated focus 1–5 from the completion modal.
  final int? focus;

  DateTime get start => DateTime(day.year, day.month, day.day).add(Duration(minutes: startMinute));

  StudyTask copyWith({
    Tr? title,
    TaskKind? kind,
    DateTime? day,
    int? startMinute,
    int? minutes,
    TaskStatus? status,
    Priority? priority,
    String? note,
    bool? reminder,
    DateTime? Function()? completedAt,
    int? actualMinutes,
    int? focus,
    String? Function()? subjectId,
    String? Function()? chapterId,
  }) => StudyTask(
    id: id,
    title: title ?? this.title,
    kind: kind ?? this.kind,
    day: day ?? this.day,
    startMinute: startMinute ?? this.startMinute,
    minutes: minutes ?? this.minutes,
    subjectId: subjectId == null ? this.subjectId : subjectId(),
    chapterId: chapterId == null ? this.chapterId : chapterId(),
    topicId: topicId,
    status: status ?? this.status,
    priority: priority ?? this.priority,
    note: note ?? this.note,
    generated: generated,
    reminder: reminder ?? this.reminder,
    completedAt: completedAt == null ? this.completedAt : completedAt(),
    actualMinutes: actualMinutes ?? this.actualMinutes,
    focus: focus ?? this.focus,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title.toJson(),
    'kind': kind.name,
    'day': day.toIso8601String(),
    'startMinute': startMinute,
    'minutes': minutes,
    'subjectId': subjectId,
    'chapterId': chapterId,
    'topicId': topicId,
    'status': status.name,
    'priority': priority.name,
    'note': note,
    'generated': generated,
    'reminder': reminder,
    'completedAt': completedAt?.toIso8601String(),
    'actualMinutes': actualMinutes,
    'focus': focus,
  };
}

/// Planner preferences (goal tracking and generation inputs).
@immutable
class PlannerPrefs {
  const PlannerPrefs({required this.examDate, this.dailyMinutes = 90, this.studyTime = StudyTime.evening, this.targetGpa = 5.0, this.reminders = true});

  factory PlannerPrefs.fromJson(Map<String, dynamic> j) => PlannerPrefs(
    examDate: DateTime.parse(j['examDate'] as String),
    dailyMinutes: j['dailyMinutes'] as int? ?? 90,
    studyTime: StudyTime.values.byName(j['studyTime'] as String? ?? 'evening'),
    targetGpa: (j['targetGpa'] as num?)?.toDouble() ?? 5.0,
    reminders: j['reminders'] as bool? ?? true,
  );

  final DateTime examDate;
  final int dailyMinutes;
  final StudyTime studyTime;
  final double targetGpa;
  final bool reminders;

  PlannerPrefs copyWith({DateTime? examDate, int? dailyMinutes, StudyTime? studyTime, double? targetGpa, bool? reminders}) => PlannerPrefs(
    examDate: examDate ?? this.examDate,
    dailyMinutes: dailyMinutes ?? this.dailyMinutes,
    studyTime: studyTime ?? this.studyTime,
    targetGpa: targetGpa ?? this.targetGpa,
    reminders: reminders ?? this.reminders,
  );

  Map<String, dynamic> toJson() => {
    'examDate': examDate.toIso8601String(),
    'dailyMinutes': dailyMinutes,
    'studyTime': studyTime.name,
    'targetGpa': targetGpa,
    'reminders': reminders,
  };
}
