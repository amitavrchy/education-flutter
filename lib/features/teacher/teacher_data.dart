import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/storage/local_store.dart';
import '../book_avatar/application/avatar_controller.dart' show mixHash;

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

class Assignment {
  const Assignment({required this.id, required this.classId, required this.title, required this.dueAt, required this.questionIds, this.submitted = 0});

  factory Assignment.fromJson(Map<String, dynamic> j) => Assignment(
    id: j['id'] as String,
    classId: j['classId'] as String,
    title: j['title'] as String,
    dueAt: DateTime.parse(j['dueAt'] as String),
    questionIds: (j['questionIds'] as List).cast<String>(),
    submitted: j['submitted'] as int? ?? 0,
  );

  final String id;
  final String classId;
  final String title;
  final DateTime dueAt;
  final List<String> questionIds;
  final int submitted;

  Map<String, dynamic> toJson() => {'id': id, 'classId': classId, 'title': title, 'dueAt': dueAt.toIso8601String(), 'questionIds': questionIds, 'submitted': submitted};
}

class Submission {
  const Submission({required this.id, required this.student, required this.classId, required this.title, required this.aiMarks, required this.total, this.pages = 2, this.finalMarks, this.feedback, this.reviewedAt});

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

  bool get reviewed => finalMarks != null;

  Submission review(double marks, String note) =>
      Submission(id: id, student: student, classId: classId, title: title, aiMarks: aiMarks, total: total, pages: pages, finalMarks: marks, feedback: note, reviewedAt: DateTime.now());

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

const teacherClasses = [
  TeacherClass('c-10a-phy', '১০ম শ্রেণি (ক) — পদার্থবিজ্ঞান', 'ssc-phy', ['রাফি আহমেদ', 'নুসাইবা খান', 'তাহসিন হোসেন', 'ফাহিম ইসলাম', 'সুমাইয়া আক্তার', 'আরিয়ান রহমান', 'মেহজাবিন চৌধুরী']),
  TeacherClass('c-10b-phy', '১০ম শ্রেণি (খ) — পদার্থবিজ্ঞান', 'ssc-phy', ['তানভীর হাসান', 'রিয়া দাস', 'সাকিব আল মাহমুদ', 'জান্নাতুল ফেরদৌস', 'ইমরান কবির', 'নাফিসা ইসলাম']),
  TeacherClass('c-9a-math', '৯ম শ্রেণি (ক) — সাধারণ গণিত', 'ssc-gmath', ['অর্পিতা সাহা', 'মাহিন খান', 'রাইসা আহমেদ', 'তাসনিম জাহান', 'শুভ্র দেব']),
];

class TeacherState {
  const TeacherState({required this.assignments, required this.submissions, required this.materials});

  final List<Assignment> assignments;
  final List<Submission> submissions;
  final List<TeachingMaterial> materials;

  List<Submission> get pending => [for (final s in submissions) if (!s.reviewed) s];
}

class TeacherController extends Notifier<TeacherState> {
  static const _col = 'teacher';
  late LocalStore _store;

  @override
  TeacherState build() {
    _store = watchStore(ref);
    final d = _store.get(_col, 'me');
    if (d != null) {
      return TeacherState(
        assignments: [for (final a in d['assignments'] as List) Assignment.fromJson((a as Map).cast<String, dynamic>())],
        submissions: [for (final s in d['submissions'] as List) Submission.fromJson((s as Map).cast<String, dynamic>())],
        materials: [for (final m in d['materials'] as List) TeachingMaterial.fromJson((m as Map).cast<String, dynamic>())],
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
          Submission(id: 'sub-$i', student: st, classId: 'c-10a-phy', title: 'নিউটনের সূত্র — সৃজনশীল প্রশ্ন', aiMarks: 6.5 + (i % 3), total: 10, pages: 1 + i % 3),
      ],
      materials: [
        TeachingMaterial('m-1', 'c-10a-phy', 'গতির সমীকরণ — সারসংক্ষেপ.pdf', 'pdf', now.subtract(const Duration(days: 3))),
        TeachingMaterial('m-2', 'c-9a-math', 'বীজগণিত ভিডিও লেকচার', 'video', now.subtract(const Duration(days: 6))),
      ],
    );
  }

  Future<void> _save(TeacherState s) async {
    state = s;
    await _store.put(_col, 'me', {
      'assignments': [for (final a in s.assignments) a.toJson()],
      'submissions': [for (final x in s.submissions) x.toJson()],
      'materials': [for (final m in s.materials) m.toJson()],
    });
  }

  Future<void> addAssignment(Assignment a) => _save(TeacherState(assignments: [a, ...state.assignments], submissions: state.submissions, materials: state.materials));

  Future<void> review(String id, double marks, String note) => _save(TeacherState(
    assignments: state.assignments,
    submissions: [for (final s in state.submissions) s.id == id ? s.review(marks, note) : s],
    materials: state.materials,
  ));

  Future<void> addMaterial(TeachingMaterial m) => _save(TeacherState(assignments: state.assignments, submissions: state.submissions, materials: [m, ...state.materials]));
}

final teacherProvider = NotifierProvider<TeacherController, TeacherState>(TeacherController.new);
