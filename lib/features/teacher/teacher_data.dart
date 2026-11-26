import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/l10n/tr.dart';
import '../../core/network/api_exception.dart';
import '../../core/storage/local_store.dart';
import '../book_avatar/application/avatar_controller.dart' show mixHash;
import '../notifications/application/notifications_controller.dart';
import '../notifications/domain/app_notification.dart';
import 'remote_teacher.dart';

/// Teacher-side mock data: classes, students, assignments, answer-script submissions and
/// shared materials. One persisted document; seeded on first use.
class TeacherClass {
  const TeacherClass(this.id, this.name, this.subjectId, this.students);

  final String id;
  final String name;
  final String subjectId;
  final List<String> students;

  /// Deterministic demo mastery (0–100) per student.
  int masteryOf(String student) => 45 + mixHash('$id$student') % 50;
  int get average => students.isEmpty ? 0 : students.map(masteryOf).reduce((a, b) => a + b) ~/ students.length;
}

enum WorkStatus { submitted, late, missing }

/// One student's work on an assignment (TCH-15).
class StudentWork {
  const StudentWork(this.student, this.status, this.at, {this.grade, this.feedback});

  factory StudentWork.fromJson(Map<String, dynamic> j) => StudentWork(
    j['student'] as String,
    WorkStatus.values.byName(j['status'] as String),
    j['at'] == null ? null : DateTime.parse(j['at'] as String),
    grade: (j['grade'] as num?)?.toDouble(),
    feedback: j['feedback'] as String?,
  );

  StudentWork graded(double marks, String note) => StudentWork(student, status, at, grade: marks, feedback: note);

  Map<String, dynamic> toJson() => {'student': student, 'status': status.name, 'at': at?.toIso8601String(), 'grade': grade, 'feedback': feedback};

  final String student;
  final WorkStatus status;
  final DateTime? at;
  final double? grade;
  final String? feedback;
}

class Assignment {
  const Assignment({
    required this.id,
    required this.classId,
    required this.title,
    required this.dueAt,
    required this.questionIds,
    this.submitted = 0,
    this.grades = const {},
    this.feedback = const {},
    this.instructions = '',
    this.total = 10,
    this.serverWork,
  });

  factory Assignment.fromJson(Map<String, dynamic> j) => Assignment(
    id: j['id'] as String,
    classId: j['classId'] as String,
    title: j['title'] as String,
    dueAt: DateTime.parse(j['dueAt'] as String),
    questionIds: (j['questionIds'] as List).cast<String>(),
    submitted: j['submitted'] as int? ?? 0,
    grades: {for (final e in (j['grades'] as Map? ?? const {}).entries) e.key as String: (e.value as num).toDouble()},
    feedback: (j['feedback'] as Map? ?? const {}).cast<String, String>(),
    instructions: j['instructions'] as String? ?? '',
    total: j['total'] as int? ?? 10,
    serverWork: j['serverWork'] == null ? null : [for (final w in j['serverWork'] as List) StudentWork.fromJson((w as Map).cast<String, dynamic>())],
  );

  /// Marks given per student.
  final Map<String, double> grades;
  final Map<String, String> feedback;
  final String instructions;
  final int total;

  /// API mode: each student's real submission status (otherwise derived from [submitted]).
  final List<StudentWork>? serverWork;

  /// Who submitted (first [submitted] students of the class, one of them late), who did not.
  List<StudentWork> work() {
    if (serverWork case final w?) return w;
    final cls = teacherClasses.where((c) => c.id == classId).firstOrNull;
    if (cls == null) return const [];
    return [
      for (final (i, st) in cls.students.indexed)
        StudentWork(
          st,
          i < submitted ? (i == submitted - 1 && submitted > 2 ? WorkStatus.late : WorkStatus.submitted) : WorkStatus.missing,
          i < submitted ? dueAt.subtract(Duration(hours: 30 - i * 4)) : null,
          grade: grades[st],
          feedback: feedback[st],
        ),
    ];
  }

  Assignment grade(String student, double marks, String note) => Assignment(
    id: id,
    classId: classId,
    title: title,
    dueAt: dueAt,
    questionIds: questionIds,
    submitted: submitted,
    grades: {...grades, student: marks},
    feedback: {...feedback, student: note},
    instructions: instructions,
    total: total,
    serverWork: serverWork == null ? null : [for (final w in serverWork!) w.student == student ? w.graded(marks, note) : w],
  );

  final String id;
  final String classId;
  final String title;
  final DateTime dueAt;
  final List<String> questionIds;
  final int submitted;

  Map<String, dynamic> toJson() => {
    'id': id,
    'classId': classId,
    'title': title,
    'dueAt': dueAt.toIso8601String(),
    'questionIds': questionIds,
    'submitted': submitted,
    'grades': grades,
    'feedback': feedback,
    'instructions': instructions,
    'total': total,
    'serverWork': serverWork == null ? null : [for (final w in serverWork!) w.toJson()],
  };
}

/// Evaluation stages kept distinct (HWE-24 / TCH-16).
enum EvalStage {
  aiEstimated(Tr('AI আনুমানিক', 'AI estimate')),
  reviewRequested(Tr('শিক্ষকের পর্যালোচনা চাওয়া হয়েছে', 'Teacher review requested')),
  teacherReviewed(Tr('শিক্ষক পর্যালোচিত', 'Teacher reviewed')),
  official(Tr('চূড়ান্ত (অফিসিয়াল)', 'Official'));

  const EvalStage(this.label);

  final Tr label;
}

class Submission {
  const Submission({
    required this.id,
    required this.student,
    required this.classId,
    required this.title,
    required this.aiMarks,
    required this.total,
    this.pages = 2,
    this.finalMarks,
    this.feedback,
    this.reviewedAt,
    this.official = false,
    this.criterionMarks = const [],
    this.requested = true,
  });

  factory Submission.fromJson(Map<String, dynamic> j) => Submission(
    id: j['id'] as String,
    student: j['student'] as String,
    classId: j['classId'] as String,
    title: j['title'] as String,
    aiMarks: (j['aiMarks'] as num).toDouble(),
    total: j['total'] as int,
    pages: j['pages'] as int? ?? 2,
    finalMarks: (j['finalMarks'] as num?)?.toDouble(),
    feedback: j['feedback'] as String?,
    reviewedAt: j['reviewedAt'] == null ? null : DateTime.parse(j['reviewedAt'] as String),
    official: j['official'] as bool? ?? false,
    criterionMarks: [for (final m in j['criterionMarks'] as List? ?? const []) (m as num).toDouble()],
    requested: j['requested'] as bool? ?? true,
  );

  final String id;
  final String student;
  final String classId;
  final String title;
  final double aiMarks;
  final int total;
  final int pages;
  final double? finalMarks;
  final String? feedback;
  final DateTime? reviewedAt;

  /// Published as final official marks (cannot be edited afterwards).
  final bool official;

  /// Teacher marks per rubric criterion, when a rubric was used.
  final List<double> criterionMarks;

  /// The student asked for a teacher review (otherwise the AI estimate stands).
  final bool requested;

  bool get reviewed => finalMarks != null;

  EvalStage get stage => official ? EvalStage.official : (reviewed ? EvalStage.teacherReviewed : (requested ? EvalStage.reviewRequested : EvalStage.aiEstimated));

  Submission review(double marks, String note, {bool official = false, List<double> criterionMarks = const []}) => Submission(
    id: id,
    student: student,
    classId: classId,
    title: title,
    aiMarks: aiMarks,
    total: total,
    pages: pages,
    finalMarks: marks,
    feedback: note,
    reviewedAt: DateTime.now(),
    official: official,
    criterionMarks: criterionMarks,
    requested: requested,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'student': student,
    'classId': classId,
    'title': title,
    'aiMarks': aiMarks,
    'total': total,
    'pages': pages,
    'finalMarks': finalMarks,
    'feedback': feedback,
    'reviewedAt': reviewedAt?.toIso8601String(),
    'official': official,
    'criterionMarks': criterionMarks,
    'requested': requested,
  };
}

class TeachingMaterial {
  const TeachingMaterial(this.id, this.classId, this.title, this.kind, this.at);

  factory TeachingMaterial.fromJson(Map<String, dynamic> j) => TeachingMaterial(j['id'] as String, j['classId'] as String, j['title'] as String, j['kind'] as String, DateTime.parse(j['at'] as String));

  final String id;
  final String classId;
  final String title;

  /// 'pdf' | 'link' | 'video'
  final String kind;
  final DateTime at;

  Map<String, dynamic> toJson() => {'id': id, 'classId': classId, 'title': title, 'kind': kind, 'at': at.toIso8601String()};
}

/// The teacher's classes: the server's roster in API mode, the demo classes otherwise.
List<TeacherClass> get teacherClasses => TeacherRoster.classes;

abstract final class TeacherRoster {
  static List<TeacherClass> classes = demoTeacherClasses;
}

const demoTeacherClasses = [
  TeacherClass('c-10a-phy', '১০ম শ্রেণি (ক) — পদার্থবিজ্ঞান', 'ssc-phy', ['রাফি আহমেদ', 'নুসাইবা খান', 'তাহসিন হোসেন', 'ফাহিম ইসলাম', 'সুমাইয়া আক্তার', 'আরিয়ান রহমান', 'মেহজাবিন চৌধুরী']),
  TeacherClass('c-10b-phy', '১০ম শ্রেণি (খ) — পদার্থবিজ্ঞান', 'ssc-phy', ['তানভীর হাসান', 'রিয়া দাস', 'সাকিব আল মাহমুদ', 'জান্নাতুল ফেরদৌস', 'ইমরান কবির', 'নাফিসা ইসলাম']),
  TeacherClass('c-9a-math', '৯ম শ্রেণি (ক) — সাধারণ গণিত', 'ssc-gmath', ['অর্পিতা সাহা', 'মাহিন খান', 'রাইসা আহমেদ', 'তাসনিম জাহান', 'শুভ্র দেব']),
];

/// Free-text feedback a teacher sends about one student (TCH-17); guardians see it too.
class StudentNote {
  const StudentNote(this.id, this.student, this.text, this.at);

  factory StudentNote.fromJson(Map<String, dynamic> j) => StudentNote(j['id'] as String, j['student'] as String, j['text'] as String, DateTime.parse(j['at'] as String));

  final String id;
  final String student;
  final String text;
  final DateTime at;

  Map<String, dynamic> toJson() => {'id': id, 'student': student, 'text': text, 'at': at.toIso8601String()};
}

class TeacherState {
  const TeacherState({required this.assignments, required this.submissions, required this.materials, this.notes = const []});

  final List<Assignment> assignments;
  final List<Submission> submissions;
  final List<TeachingMaterial> materials;
  final List<StudentNote> notes;

  List<Submission> get pending => [for (final s in submissions) if (!s.reviewed) s];
}

class TeacherController extends Notifier<TeacherState> {
  static const _col = 'teacher';
  late LocalStore _store;
  RemoteTeacher? _remote;
  Map<String, String> _studentIds = {};
  Map<String, String> _submissionIds = {};
  Map<String, String> _evaluationOwners = {};
  String? _institutionId;
  Future<void>? _refreshing;

  @override
  TeacherState build() {
    _store = watchStore(ref);
    _remote = ref.watch(remoteTeacherProvider);
    if (_remote != null) {
      Future.microtask(refresh);
      final cached = _store.get(_col, 'remote');
      if (cached == null) {
        TeacherRoster.classes = const [];
        return const TeacherState(assignments: [], submissions: [], materials: []);
      }
      TeacherRoster.classes = [
        for (final c in cached['classes'] as List? ?? const [])
          TeacherClass(c['id'] as String, c['name'] as String, c['subjectId'] as String, (c['students'] as List).cast<String>()),
      ];
      _studentIds = (cached['studentIds'] as Map? ?? const {}).cast<String, String>();
      _submissionIds = (cached['submissionIds'] as Map? ?? const {}).cast<String, String>();
      _evaluationOwners = (cached['evaluationOwners'] as Map? ?? const {}).cast<String, String>();
      _institutionId = cached['institutionId'] as String?;
      return _decode(cached);
    }
    TeacherRoster.classes = demoTeacherClasses;
    final d = _store.get(_col, 'me');
    if (d != null) {
      return TeacherState(
        assignments: [for (final a in d['assignments'] as List) Assignment.fromJson((a as Map).cast<String, dynamic>())],
        submissions: [for (final s in d['submissions'] as List) Submission.fromJson((s as Map).cast<String, dynamic>())],
        materials: [for (final m in d['materials'] as List) TeachingMaterial.fromJson((m as Map).cast<String, dynamic>())],
        notes: [for (final n in d['notes'] as List? ?? const []) StudentNote.fromJson((n as Map).cast<String, dynamic>())],
      );
    }
    final now = DateTime.now();
    return TeacherState(
      assignments: [
        Assignment(id: 'as-1', classId: 'c-10a-phy', title: 'বলের সমস্যা — অনুশীলন', dueAt: now.add(const Duration(days: 2)), questionIds: const [], submitted: 5),
        Assignment(id: 'as-2', classId: 'c-9a-math', title: 'বীজগাণিতিক রাশি', dueAt: now.add(const Duration(days: 4)), questionIds: const [], submitted: 2),
      ],
      submissions: [
        for (final (i, st) in teacherClasses.first.students.take(4).indexed)
          Submission(id: 'sub-$i', student: st, classId: 'c-10a-phy', title: 'নিউটনের সূত্র — সৃজনশীল প্রশ্ন', aiMarks: 6.5 + (i % 3), total: 10, pages: 1 + i % 3, requested: i != 3),
      ],
      materials: [
        TeachingMaterial('m-1', 'c-10a-phy', 'গতির সমীকরণ — সারসংক্ষেপ.pdf', 'pdf', now.subtract(const Duration(days: 3))),
        TeachingMaterial('m-2', 'c-9a-math', 'বীজগণিত ভিডিও লেকচার', 'video', now.subtract(const Duration(days: 6))),
      ],
    );
  }

  TeacherState _decode(Map<String, dynamic> d) => TeacherState(
    assignments: [for (final a in d['assignments'] as List) Assignment.fromJson((a as Map).cast<String, dynamic>())],
    submissions: [for (final s in d['submissions'] as List) Submission.fromJson((s as Map).cast<String, dynamic>())],
    materials: [for (final m in d['materials'] as List) TeachingMaterial.fromJson((m as Map).cast<String, dynamic>())],
    notes: [for (final n in d['notes'] as List? ?? const []) StudentNote.fromJson((n as Map).cast<String, dynamic>())],
  );

  /// API mode: roster, assignments, answer scripts, resources and feedback from the server.
  Future<void> refresh() => _refreshing ??= _refresh().whenComplete(() => _refreshing = null);

  Future<void> _refresh() async {
    final remote = _remote;
    if (remote == null || !ref.mounted) return;
    try {
      final snap = await remote.load();
      if (!ref.mounted) return;
      TeacherRoster.classes = snap.classes;
      _studentIds = snap.studentIds;
      _submissionIds = snap.submissionIds;
      _evaluationOwners = snap.evaluationOwners;
      _institutionId = snap.institutionId;
      await _save(snap.state);
    } catch (_) {
      // Offline: keep the cached portal.
    }
  }

  Future<void> _save(TeacherState s) async {
    state = s;
    if (_remote != null) {
      await _store.put(_col, 'remote', {
        'classes': [for (final c in teacherClasses) {'id': c.id, 'name': c.name, 'subjectId': c.subjectId, 'students': c.students}],
        'studentIds': _studentIds,
        'submissionIds': _submissionIds,
        'evaluationOwners': _evaluationOwners,
        'institutionId': _institutionId,
        'assignments': [for (final a in s.assignments) a.toJson()],
        'submissions': [for (final x in s.submissions) x.toJson()],
        'materials': [for (final m in s.materials) m.toJson()],
        'notes': [for (final n in s.notes) n.toJson()],
      });
      return;
    }
    await _store.put(_col, 'me', {
      'assignments': [for (final a in s.assignments) a.toJson()],
      'submissions': [for (final x in s.submissions) x.toJson()],
      'materials': [for (final m in s.materials) m.toJson()],
      'notes': [for (final n in s.notes) n.toJson()],
    });
  }

  Future<void> addAssignment(Assignment a) async {
    if (_remote != null) {
      await _remote!.createAssignment(a, institutionId: _institutionId);
      final cls = teacherClasses.where((c) => c.id == a.classId).firstOrNull;
      a = Assignment(
        id: a.id,
        classId: a.classId,
        title: a.title,
        dueAt: a.dueAt,
        questionIds: a.questionIds,
        instructions: a.instructions,
        total: a.total,
        serverWork: [for (final st in cls?.students ?? const <String>[]) StudentWork(st, WorkStatus.missing, null)],
      );
    }
    await _addAssignment(a);
  }

  Future<void> _addAssignment(Assignment a) => _save(TeacherState(assignments: [a, ...state.assignments], submissions: state.submissions, materials: state.materials, notes: state.notes));

  Future<void> review(String id, double marks, String note, {bool official = false, List<double> criterionMarks = const []}) async {
    final current = state.submissions.firstWhere((s) => s.id == id);
    if (current.official) {
      throw const ApiException(statusCode: 409, code: 'ALREADY_OFFICIAL', message: 'চূড়ান্ত নম্বর আর বদলানো যায় না');
    }
    if (_remote != null) {
      // The server notifies the student.
      final owner = _evaluationOwners[id];
      if (owner != null) await _remote!.reviewEvaluation(owner, id, marks, note, official: official);
      await _save(TeacherState(
        assignments: state.assignments,
        submissions: [for (final s in state.submissions) s.id == id ? s.review(marks, note, official: official, criterionMarks: criterionMarks) : s],
        materials: state.materials,
        notes: state.notes,
      ));
      return;
    }
    await _save(TeacherState(
      assignments: state.assignments,
      submissions: [for (final s in state.submissions) s.id == id ? s.review(marks, note, official: official, criterionMarks: criterionMarks) : s],
      materials: state.materials,
      notes: state.notes,
    ));
    await ref.read(notificationsProvider.notifier).push(AppNotification(
      id: 'eval-$id-${DateTime.now().millisecondsSinceEpoch}',
      category: NotificationCategory.feedback,
      title: official ? const Tr('চূড়ান্ত নম্বর প্রকাশিত', 'Final marks published') : const Tr('শিক্ষক খাতা দেখেছেন', 'Your teacher reviewed your script'),
      body: Tr('${current.title}: ${marks.toStringAsFixed(1)}/${current.total}', '${current.title}: ${marks.toStringAsFixed(1)}/${current.total}'),
      createdAt: DateTime.now(),
      audience: 'student',
      route: '/handwriting',
    ));
  }

  /// A student's answer script sent for teacher review (from the handwriting evaluator).
  Future<void> addSubmission(Submission s) => _save(TeacherState(assignments: state.assignments, submissions: [s, ...state.submissions], materials: state.materials, notes: state.notes));

  /// Grades one student's assignment work (TCH-15, TCH-17).
  Future<void> gradeWork(String assignmentId, String student, double marks, String note) async {
    if (_remote != null) {
      final sub = _submissionIds['$assignmentId/$student'];
      if (sub == null) throw const ApiException(statusCode: 409, code: 'NOT_SUBMITTED', message: 'এই শিক্ষার্থী এখনো জমা দেয়নি');
      await _remote!.gradeSubmission(sub, marks, note);
    }
    await _gradeWork(assignmentId, student, marks, note);
  }

  Future<void> _gradeWork(String assignmentId, String student, double marks, String note) => _save(TeacherState(
    assignments: [for (final a in state.assignments) a.id == assignmentId ? a.grade(student, marks, note) : a],
    submissions: state.submissions,
    materials: state.materials,
    notes: state.notes,
  ));

  Future<void> addMaterial(TeachingMaterial m) async {
    if (_remote != null) {
      final subject = teacherClasses.where((c) => c.id == m.classId).firstOrNull?.subjectId;
      await _remote!.createResource(m, institutionId: _institutionId, subjectId: subject);
    }
    await _addMaterial(m);
  }

  Future<void> _addMaterial(TeachingMaterial m) => _save(TeacherState(assignments: state.assignments, submissions: state.submissions, materials: [m, ...state.materials], notes: state.notes));

  /// Sends feedback about one student: stored for the guardian portal and pushed to the student.
  Future<void> sendStudentFeedback(String student, String text) async {
    final note = StudentNote('sn-${DateTime.now().microsecondsSinceEpoch}', student, text, DateTime.now());
    if (_remote != null) {
      final sid = _studentIds[student];
      if (sid == null) throw const ApiException(statusCode: 409, code: 'NO_ACCOUNT', message: 'এই শিক্ষার্থীর অ্যাপ অ্যাকাউন্ট নেই');
      final subject = teacherClasses.where((c) => c.students.contains(student)).firstOrNull?.subjectId ?? '';
      // The server makes it visible to the student and linked guardians.
      await _remote!.sendFeedback(sid, subject, text, 'tf-${note.id}');
      await _save(TeacherState(assignments: state.assignments, submissions: state.submissions, materials: state.materials, notes: [note, ...state.notes]));
      return;
    }
    await _save(TeacherState(assignments: state.assignments, submissions: state.submissions, materials: state.materials, notes: [note, ...state.notes]));
    await ref.read(notificationsProvider.notifier).push(AppNotification(
      id: 'tf-${note.id}',
      category: NotificationCategory.feedback,
      title: const Tr('শিক্ষকের মতামত', 'Teacher feedback'),
      body: Tr.same(text),
      createdAt: note.at,
      audience: 'student',
    ));
  }
}

final teacherProvider = NotifierProvider<TeacherController, TeacherState>(TeacherController.new);
