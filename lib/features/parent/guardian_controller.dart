import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/l10n/tr.dart';
import '../../core/mock/mock_simulator.dart';
import '../../core/network/api_exception.dart';
import '../../core/storage/local_store.dart';
import '../../mock/seed/curriculum_seed.dart';
import '../account/account_controller.dart';
import '../book_avatar/application/avatar_controller.dart' show mixHash;
import '../curriculum/domain/curriculum_models.dart' show EducationLevel;
import '../exams/application/exam_controller.dart';
import '../notifications/application/notifications_controller.dart';
import '../notifications/domain/app_notification.dart';
import '../planner/application/planner_controller.dart';
import '../planner/domain/study_task.dart';
import '../profile/application/student_profile_controller.dart';
import '../progress/application/learning_progress_controller.dart';
import '../progress/domain/learning_progress.dart';
import '../teacher/teacher_data.dart';

/// Guardian portal data (web §27): linked children with per-link sharing, goals and teacher
/// feedback. The first child is the student who uses this device, so every number shown for
/// them is live; other linked children get deterministic demo numbers.

/// Code a student finds under Privacy → "Link a guardian" (same demo code as the web).
const demoLinkCode = 'SHK-2741';
const demoOtp = '123456';

/// Name of the device's own student as the guardian and teacher portals see them.
const selfChildName = 'রাফি আহমেদ';

enum ShareKey {
  progress(Tr('অগ্রগতি ও দুর্বল টপিক', 'Progress & weak topics')),
  studyTime(Tr('পড়ার সময়', 'Study time')),
  scores(Tr('পরীক্ষার ফল', 'Exam scores')),
  calendar(Tr('স্টাডি ক্যালেন্ডার', 'Study calendar')),
  teacherFeedback(Tr('শিক্ষকের মন্তব্য', 'Teacher feedback')),
  aiConversations(Tr('AI কথোপকথন', 'AI conversations'));

  const ShareKey(this.label);

  final Tr label;
}

enum LinkStatus { pending, active }

class GuardianLink {
  const GuardianLink({
    required this.id,
    required this.studentName,
    required this.relation,
    required this.status,
    required this.permissions,
    this.linkedAt,
    this.self = false,
    this.studentClass = 10,
  });

  factory GuardianLink.fromJson(Map<String, dynamic> j) => GuardianLink(
    id: j['id'] as String,
    studentName: j['studentName'] as String,
    relation: j['relation'] as String,
    status: LinkStatus.values.byName(j['status'] as String),
    permissions: {for (final e in (j['permissions'] as Map).entries) ShareKey.values.byName(e.key as String): e.value as bool},
    linkedAt: j['linkedAt'] == null ? null : DateTime.parse(j['linkedAt'] as String),
    self: j['self'] as bool? ?? false,
    studentClass: j['studentClass'] as int? ?? 10,
  );

  final String id;
  final String studentName;
  final String relation;
  final LinkStatus status;
  final Map<ShareKey, bool> permissions;
  final DateTime? linkedAt;

  /// True for the device's own student (live data).
  final bool self;
  final int studentClass;

  bool get active => status == LinkStatus.active;

  GuardianLink copyWith({LinkStatus? status, Map<ShareKey, bool>? permissions, DateTime? linkedAt, String? relation}) => GuardianLink(
    id: id,
    studentName: studentName,
    relation: relation ?? this.relation,
    status: status ?? this.status,
    permissions: permissions ?? this.permissions,
    linkedAt: linkedAt ?? this.linkedAt,
    self: self,
    studentClass: studentClass,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'studentName': studentName,
    'relation': relation,
    'status': status.name,
    'permissions': {for (final e in permissions.entries) e.key.name: e.value},
    'linkedAt': linkedAt?.toIso8601String(),
    'self': self,
    'studentClass': studentClass,
  };
}

enum GoalMetric {
  minutes(Tr('পড়ার মিনিট', 'Study minutes')),
  exams(Tr('পরীক্ষা', 'Exams taken')),
  chapters(Tr('শেষ করা টপিক', 'Topics completed')),
  questions(Tr('অনুশীলিত প্রশ্ন', 'Questions practised'));

  const GoalMetric(this.label);

  final Tr label;
}

class GuardianGoal {
  const GuardianGoal({required this.id, required this.linkId, required this.title, required this.metric, required this.target, required this.createdAt});

  factory GuardianGoal.fromJson(Map<String, dynamic> j) => GuardianGoal(
    id: j['id'] as String,
    linkId: j['linkId'] as String,
    title: j['title'] as String,
    metric: GoalMetric.values.byName(j['metric'] as String),
    target: j['target'] as int,
    createdAt: DateTime.parse(j['createdAt'] as String),
  );

  final String id;
  final String linkId;
  final String title;
  final GoalMetric metric;

  /// Weekly target.
  final int target;
  final DateTime createdAt;

  Map<String, dynamic> toJson() => {'id': id, 'linkId': linkId, 'title': title, 'metric': metric.name, 'target': target, 'createdAt': createdAt.toIso8601String()};
}

class TeacherNote {
  const TeacherNote({required this.id, required this.linkId, required this.teacher, required this.subject, required this.message, required this.at, this.acknowledged = false, this.reply});

  factory TeacherNote.fromJson(Map<String, dynamic> j) => TeacherNote(
    id: j['id'] as String,
    linkId: j['linkId'] as String,
    teacher: j['teacher'] as String,
    subject: Tr.fromJson(j['subject']),
    message: j['message'] as String,
    at: DateTime.parse(j['at'] as String),
    acknowledged: j['acknowledged'] as bool? ?? false,
    reply: j['reply'] as String?,
  );

  final String id;
  final String linkId;
  final String teacher;
  final Tr subject;
  final String message;
  final DateTime at;
  final bool acknowledged;
  final String? reply;

  TeacherNote copyWith({bool? acknowledged, String? reply}) =>
      TeacherNote(id: id, linkId: linkId, teacher: teacher, subject: subject, message: message, at: at, acknowledged: acknowledged ?? this.acknowledged, reply: reply ?? this.reply);

  Map<String, dynamic> toJson() => {
    'id': id,
    'linkId': linkId,
    'teacher': teacher,
    'subject': subject.toJson(),
    'message': message,
    'at': at.toIso8601String(),
    'acknowledged': acknowledged,
    'reply': reply,
  };
}

class GuardianState {
  const GuardianState({required this.links, required this.selectedId, required this.goals, required this.notes, this.onboarded = false});

  final List<GuardianLink> links;
  final String? selectedId;
  final List<GuardianGoal> goals;
  final List<TeacherNote> notes;

  /// Guardian onboarding (PAR-01) seen.
  final bool onboarded;

  List<GuardianLink> get active => [for (final l in links) if (l.active) l];

  GuardianLink? get selected => active.where((l) => l.id == selectedId).firstOrNull ?? active.firstOrNull;

  GuardianState copyWith({List<GuardianLink>? links, String? Function()? selectedId, List<GuardianGoal>? goals, List<TeacherNote>? notes, bool? onboarded}) => GuardianState(
    links: links ?? this.links,
    selectedId: selectedId == null ? this.selectedId : selectedId(),
    goals: goals ?? this.goals,
    notes: notes ?? this.notes,
    onboarded: onboarded ?? this.onboarded,
  );
}

const _defaultPerms = {
  ShareKey.progress: true,
  ShareKey.studyTime: true,
  ShareKey.scores: true,
  ShareKey.calendar: true,
  ShareKey.teacherFeedback: true,
  ShareKey.aiConversations: false,
};

class GuardianController extends Notifier<GuardianState> {
  static const _col = 'guardian';
  late LocalStore _store;

  @override
  GuardianState build() {
    _store = watchStore(ref);
    final d = _store.get(_col, 'state');
    if (d != null) {
      return GuardianState(
        links: [for (final l in d['links'] as List) GuardianLink.fromJson((l as Map).cast<String, dynamic>())],
        selectedId: d['selectedId'] as String?,
        goals: [for (final g in d['goals'] as List) GuardianGoal.fromJson((g as Map).cast<String, dynamic>())],
        notes: [for (final n in d['notes'] as List) TeacherNote.fromJson((n as Map).cast<String, dynamic>())],
        onboarded: d['onboarded'] as bool? ?? false,
      );
    }
    final now = DateTime.now();
    return GuardianState(
      links: [
        GuardianLink(id: 'gl-self', studentName: selfChildName, relation: 'বাবা', status: LinkStatus.active, permissions: _defaultPerms, linkedAt: now.subtract(const Duration(days: 40)), self: true),
        GuardianLink(
          id: 'gl-2',
          studentName: 'নুসরাত জাহান',
          relation: 'বাবা',
          status: LinkStatus.active,
          permissions: {..._defaultPerms, ShareKey.calendar: false},
          linkedAt: now.subtract(const Duration(days: 12)),
          studentClass: 8,
        ),
      ],
      selectedId: 'gl-self',
      goals: [
        GuardianGoal(id: 'gg-1', linkId: 'gl-self', title: 'সপ্তাহে ১০ ঘণ্টা পড়াশোনা', metric: GoalMetric.minutes, target: 600, createdAt: now.subtract(const Duration(days: 10))),
        GuardianGoal(id: 'gg-2', linkId: 'gl-self', title: 'সপ্তাহে ২টি মডেল টেস্ট', metric: GoalMetric.exams, target: 2, createdAt: now.subtract(const Duration(days: 10))),
        GuardianGoal(id: 'gg-3', linkId: 'gl-2', title: 'সপ্তাহে ৮ ঘণ্টা পড়াশোনা', metric: GoalMetric.minutes, target: 480, createdAt: now.subtract(const Duration(days: 6))),
      ],
      notes: [
        TeacherNote(
          id: 'tn-1',
          linkId: 'gl-self',
          teacher: 'নাসরিন সুলতানা',
          subject: const Tr('পদার্থবিজ্ঞান', 'Physics'),
          message: 'রাফি গতির অঙ্কে ভালো করছে, তবে উত্তরে একক লিখতে ভুলে যায়। বাসায় একটু মনে করিয়ে দেবেন।',
          at: now.subtract(const Duration(hours: 9)),
        ),
        TeacherNote(
          id: 'tn-2',
          linkId: 'gl-self',
          teacher: 'মাহমুদুল হাসান',
          subject: const Tr('সাধারণ গণিত', 'General Mathematics'),
          message: 'বীজগণিতের অ্যাসাইনমেন্ট সময়মতো জমা দিয়েছে। উৎপাদকে বিশ্লেষণ আরও অনুশীলন দরকার।',
          at: now.subtract(const Duration(days: 3)),
          acknowledged: true,
        ),
        TeacherNote(
          id: 'tn-3',
          linkId: 'gl-2',
          teacher: 'ফারহানা ইয়াসমিন',
          subject: const Tr('বিজ্ঞান', 'Science'),
          message: 'নুসরাত ক্লাসে প্রশ্ন করে, এটা খুব ভালো লক্ষণ।',
          at: now.subtract(const Duration(days: 2)),
        ),
      ],
    );
  }

  Future<void> _save(GuardianState s) async {
    state = s;
    await _store.put(_col, 'state', {
      'links': [for (final l in s.links) l.toJson()],
      'selectedId': s.selectedId,
      'goals': [for (final g in s.goals) g.toJson()],
      'notes': [for (final n in s.notes) n.toJson()],
      'onboarded': s.onboarded,
    });
  }

  MockSimulator get _sim => ref.read(mockSimulatorProvider);

  Future<void> select(String linkId) => _save(state.copyWith(selectedId: () => linkId));

  Future<void> finishOnboarding() => _save(state.copyWith(onboarded: true));

  /// Step 1 of linking: the code the student shared → a pending link (OTP goes to the guardian).
  Future<GuardianLink> requestLink(String code, String relation) async {
    await _sim.run(() {});
    if (code.trim().toUpperCase() != demoLinkCode) {
      throw const ApiException(statusCode: 400, message: 'লিংক কোড সঠিক নয়', code: 'LINK_CODE_INVALID');
    }
    final existing = state.links.where((l) => l.id == 'gl-3').firstOrNull;
    if (existing != null && existing.active) {
      throw const ApiException(statusCode: 409, message: 'এই শিক্ষার্থী আগেই যুক্ত আছে', code: 'ALREADY_LINKED');
    }
    final link = GuardianLink(id: 'gl-3', studentName: 'তাহসিন রহমান', relation: relation, status: LinkStatus.pending, permissions: _defaultPerms, studentClass: 9);
    await _save(state.copyWith(links: [...state.links.where((l) => l.id != link.id), link]));
    return link;
  }

  /// Step 2: OTP sent to the guardian's phone (demo 123456).
  Future<void> confirmLink(String linkId, String otp) async {
    await _sim.run(() {});
    if (otp.trim() != demoOtp) throw const ApiException(statusCode: 400, message: 'OTP সঠিক নয়', code: 'OTP_INVALID');
    await _save(state.copyWith(
      links: [for (final l in state.links) l.id == linkId ? l.copyWith(status: LinkStatus.active, linkedAt: DateTime.now()) : l],
      selectedId: () => linkId,
    ));
  }

  Future<void> unlink(String linkId) async {
    await _sim.run(() {});
    final links = state.links.where((l) => l.id != linkId).toList();
    await _save(state.copyWith(links: links, selectedId: () => state.selectedId == linkId ? links.where((l) => l.active).firstOrNull?.id : state.selectedId));
  }

  /// Guardians may switch sharing off. Turning AI-conversation sharing on needs the student.
  Future<void> setPermission(String linkId, ShareKey key, bool value) async {
    if (key == ShareKey.aiConversations && value) {
      throw const ApiException(statusCode: 403, message: 'শুধু শিক্ষার্থী নিজে AI কথোপকথন শেয়ার চালু করতে পারে', code: 'STUDENT_CONSENT_REQUIRED');
    }
    await _save(state.copyWith(links: [
      for (final l in state.links) l.id == linkId ? l.copyWith(permissions: {...l.permissions, key: value}) : l,
    ]));
  }

  Future<void> saveGoal(GuardianGoal goal) => _save(state.copyWith(goals: [goal, ...state.goals.where((g) => g.id != goal.id)]));

  Future<void> removeGoal(String id) => _save(state.copyWith(goals: state.goals.where((g) => g.id != id).toList()));

  /// Upserts [note] (notes derived from teacher reviews are stored on first interaction).
  Future<void> _upsertNote(TeacherNote note) => _save(state.copyWith(notes: [note, ...state.notes.where((n) => n.id != note.id)]));

  Future<void> acknowledge(TeacherNote note) => _upsertNote(note.copyWith(acknowledged: true));

  /// Reply goes to the teacher's inbox (teacher portal notification).
  Future<void> reply(TeacherNote note, String message) async {
    await _sim.run(() {});
    await _upsertNote(note.copyWith(acknowledged: true, reply: message));
    await ref.read(notificationsProvider.notifier).push(AppNotification(
      id: 'gr-${DateTime.now().microsecondsSinceEpoch}',
      category: NotificationCategory.feedback,
      title: const Tr('অভিভাবকের বার্তা', 'Message from a guardian'),
      body: Tr.same(message.length > 120 ? '${message.substring(0, 120)}…' : message),
      createdAt: DateTime.now(),
      audience: 'teacher',
      route: '/teacher-students',
    ));
  }
}

final guardianProvider = NotifierProvider<GuardianController, GuardianState>(GuardianController.new);

/// What the guardian may see for [link]: the guardian's switches AND the student's own
/// privacy choices (the student always has the final say).
Map<ShareKey, bool> effectivePermissions(GuardianLink link, Map<String, bool> studentPrivacy) {
  if (!link.self) return link.permissions;
  bool student(String key, {bool fallback = true}) => studentPrivacy[key] ?? fallback;
  return {
    ShareKey.progress: (link.permissions[ShareKey.progress] ?? false) && student('progress'),
    ShareKey.studyTime: (link.permissions[ShareKey.studyTime] ?? false) && student('progress'),
    ShareKey.scores: (link.permissions[ShareKey.scores] ?? false) && student('scores'),
    ShareKey.calendar: (link.permissions[ShareKey.calendar] ?? false) && student('calendar'),
    ShareKey.teacherFeedback: (link.permissions[ShareKey.teacherFeedback] ?? false) && student('feedback'),
    ShareKey.aiConversations: student('conversations', fallback: false),
  };
}

class CalendarItem {
  const CalendarItem(this.day, this.title, this.minutes, this.status, {this.startMinute = 17 * 60});

  final DateTime day;
  final Tr title;
  final int minutes;
  final TaskStatus status;
  final int startMinute;
}

class ExamLine {
  const ExamLine(this.title, this.percent, this.at);

  final Tr title;
  final int percent;
  final DateTime at;
}

/// Everything the guardian portal shows about one child, before permission filtering.
class ChildSummary {
  const ChildSummary({
    required this.link,
    required this.perms,
    required this.weekMinutes,
    required this.minutesPrevWeek,
    required this.tasksDone,
    required this.tasksMissed,
    required this.avgScore,
    required this.streak,
    required this.weakTopics,
    required this.subjectMastery,
    required this.results,
    required this.calendar,
    required this.goalValues,
  });

  final GuardianLink link;
  final Map<ShareKey, bool> perms;

  /// Last 7 days, oldest first.
  final List<int> weekMinutes;
  final int minutesPrevWeek;
  final int tasksDone;
  final int tasksMissed;

  /// 0–100, null without results.
  final int? avgScore;
  final int streak;
  final List<(Tr topic, Tr subject, double mastery)> weakTopics;
  final List<(Tr subject, double mastery)> subjectMastery;
  final List<ExamLine> results;
  final List<CalendarItem> calendar;
  final Map<GoalMetric, int> goalValues;

  int get minutesWeek => weekMinutes.fold(0, (a, b) => a + b);
  bool can(ShareKey k) => perms[k] ?? false;
}

DateTime _day(DateTime d) => DateTime(d.year, d.month, d.day);

final childSummaryProvider = Provider.family<ChildSummary?, String>((ref, linkId) {
  final link = ref.watch(guardianProvider).links.where((l) => l.id == linkId).firstOrNull;
  if (link == null) return null;
  final privacy = ref.watch(accountProvider).privacy;
  final perms = effectivePermissions(link, privacy);
  final now = DateTime.now();
  final weekStart = _day(now).subtract(const Duration(days: 6));
  if (link.self) {
    final p = ref.watch(learningProgressProvider);
    final exams = ref.watch(examProvider).finished;
    final plan = ref.watch(plannerProvider);
    final level = ref.watch(studentProfileProvider.select((s) => s.level));
    final week = plan.between(weekStart, now);
    final subjects = [for (final s in seedSubjects) if (s.level == level) s];
    final weak = <(Tr, Tr, double)>[
      for (final s in subjects)
        for (final c in s.chapters)
          for (final t in c.topics)
            if (p.topic(t.id).attempts >= 2 && p.topic(t.id).mastery < 0.55) (t.title, s.name, p.topic(t.id).mastery),
    ]..sort((a, b) => a.$3.compareTo(b.$3));
    final prev = p.recentMinutes(days: 14);
    final completedThisWeek = [
      for (final s in subjects)
        for (final c in s.chapters)
          for (final t in c.topics)
            if (p.topic(t.id).completed && (p.topic(t.id).lastStudied?.isAfter(weekStart) ?? false)) t.id,
    ].length;
    return ChildSummary(
      link: link,
      perms: perms,
      weekMinutes: p.recentMinutes(),
      minutesPrevWeek: prev.take(7).fold(0, (a, b) => a + b),
      tasksDone: week.where((t) => t.status == TaskStatus.done).length,
      tasksMissed: week.where((t) => t.status == TaskStatus.missed).length,
      avgScore: exams.isEmpty ? null : (exams.map((a) => a.result!.percent).reduce((a, b) => a + b) / exams.length * 100).round(),
      streak: p.streak,
      weakTopics: weak.take(5).toList(),
      subjectMastery: [for (final s in subjects) (s.name, p.subjectMastery(s))]..sort((a, b) => b.$2.compareTo(a.$2)),
      results: [for (final a in exams) ExamLine(a.title, (a.result!.percent * 100).round(), a.submittedAt ?? a.startedAt)],
      calendar: [
        for (final t in plan.between(weekStart, now.add(const Duration(days: 7)))) CalendarItem(t.day, t.title, t.minutes, t.status, startMinute: t.startMinute),
      ]..sort((a, b) => a.day.compareTo(b.day)),
      goalValues: {
        GoalMetric.minutes: p.recentMinutes().fold(0, (a, b) => a + b),
        GoalMetric.exams: exams.where((a) => (a.submittedAt ?? a.startedAt).isAfter(weekStart)).length,
        GoalMetric.chapters: completedThisWeek,
        GoalMetric.questions: p.activities.where((a) => a.kind == ActivityKind.practice && a.at.isAfter(weekStart)).length * 5,
      },
    );
  }
  // Deterministic demo child.
  int h(String k) => mixHash('${link.id}:$k');
  final sscSubjects = [for (final s in seedSubjects) if (s.level == EducationLevel.ssc) s].take(5).toList();
  final mins = [for (var i = 0; i < 7; i++) 20 + h('m$i') % 70];
  return ChildSummary(
    link: link,
    perms: perms,
    weekMinutes: mins,
    minutesPrevWeek: 250 + h('prev') % 200,
    tasksDone: 6 + h('done') % 6,
    tasksMissed: h('missed') % 4,
    avgScore: 58 + h('avg') % 30,
    streak: 2 + h('streak') % 9,
    weakTopics: [
      for (final s in sscSubjects.take(3))
        if (s.chapters.isNotEmpty && s.chapters.first.topics.isNotEmpty) (s.chapters.first.topics.first.title, s.name, 0.3 + (h(s.id) % 20) / 100),
    ],
    subjectMastery: [for (final s in sscSubjects) (s.name, 0.4 + (h('sm${s.id}') % 50) / 100)]..sort((a, b) => b.$2.compareTo(a.$2)),
    results: [
      for (var i = 0; i < 4; i++)
        ExamLine(Tr('মডেল টেস্ট ${i + 1}', 'Model test ${i + 1}'), 55 + h('r$i') % 40, now.subtract(Duration(days: 3 + i * 5))),
    ],
    calendar: [
      for (var d = -6; d <= 7; d++)
        if (h('c$d') % 3 != 0)
          CalendarItem(
            _day(now).add(Duration(days: d)),
            sscSubjects.isEmpty ? const Tr('পড়া', 'Study') : sscSubjects[h('cs$d') % sscSubjects.length].name,
            30 + h('cm$d') % 4 * 15,
            d > 0 ? TaskStatus.scheduled : (h('st$d') % 4 == 0 ? TaskStatus.missed : TaskStatus.done),
          ),
    ],
    goalValues: {
      GoalMetric.minutes: mins.fold(0, (a, b) => a + b),
      GoalMetric.exams: 1 + h('ge') % 2,
      GoalMetric.chapters: h('gc') % 5,
      GoalMetric.questions: 20 + h('gq') % 60,
    },
  );
});

/// Feedback the guardian sees for [linkId]: seeded notes plus the device student's answer
/// scripts that a teacher reviewed in the teacher portal.
final teacherNotesProvider = Provider.family<List<TeacherNote>, String>((ref, linkId) {
  final g = ref.watch(guardianProvider);
  final link = g.links.where((l) => l.id == linkId).firstOrNull;
  final notes = [for (final n in g.notes) if (n.linkId == linkId) n];
  if (link?.self ?? false) {
    for (final sn in ref.watch(teacherProvider).notes) {
      if (sn.student == selfChildName && !notes.any((n) => n.id == 'tn-${sn.id}')) {
        notes.add(TeacherNote(id: 'tn-${sn.id}', linkId: linkId, teacher: 'নাসরিন সুলতানা', subject: const Tr('পদার্থবিজ্ঞান', 'Physics'), message: sn.text, at: sn.at));
      }
    }
    for (final s in ref.watch(teacherProvider).submissions) {
      if (s.student == selfChildName && s.reviewed && !notes.any((n) => n.id == 'sub-${s.id}')) {
        notes.add(TeacherNote(
          id: 'sub-${s.id}',
          linkId: linkId,
          teacher: 'নাসরিন সুলতানা',
          subject: Tr.same(s.title),
          message: '${s.feedback?.isNotEmpty ?? false ? s.feedback! : 'খাতা মূল্যায়ন সম্পন্ন'} (${s.finalMarks!.toStringAsFixed(1)}/${s.total})',
          at: s.reviewedAt!,
        ));
      }
    }
  }
  return notes..sort((a, b) => b.at.compareTo(a.at));
});
