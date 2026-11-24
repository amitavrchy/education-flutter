import 'package:material_ui/material_ui.dart';

import '../../../core/l10n/tr.dart';
import '../../curriculum/domain/curriculum_models.dart';
import '../../question_bank/domain/question.dart';

/// The 13 exam types from the spec (§16).
enum ExamType {
  chapter(Tr('অধ্যায় পরীক্ষা', 'Chapter exam'), Icons.bookmark_outline),
  topic(Tr('টপিক পরীক্ষা', 'Topic exam'), Icons.label_outline),
  subject(Tr('বিষয়ভিত্তিক পরীক্ষা', 'Subject exam'), Icons.menu_book_outlined),
  fullSyllabus(Tr('পূর্ণ সিলেবাস', 'Full syllabus'), Icons.library_books_outlined),
  modelTest(Tr('মডেল টেস্ট', 'Model test'), Icons.assignment_outlined),
  boardPrevious(Tr('বিগত বোর্ড (নমুনা)', 'Previous board (sample)'), Icons.history_edu_outlined),
  dailyChallenge(Tr('ডেইলি চ্যালেঞ্জ', 'Daily challenge'), Icons.bolt),
  adaptive(Tr('অ্যাডাপটিভ পরীক্ষা', 'Adaptive exam'), Icons.auto_graph),
  custom(Tr('কাস্টম পরীক্ষা', 'Custom exam'), Icons.tune),
  teacherAssigned(Tr('শিক্ষকের দেওয়া', 'Teacher-assigned'), Icons.person_outline),
  mixed(Tr('মিশ্র অনুশীলন', 'Mixed practice'), Icons.shuffle),
  oral(Tr('মৌখিক অনুশীলন', 'Oral practice'), Icons.record_voice_over_outlined);

  const ExamType(this.label, this.icon);

  final Tr label;
  final IconData icon;
}

enum ExamMode {
  exam(Tr('পরীক্ষা মোড', 'Exam mode')),
  practice(Tr('অনুশীলন মোড', 'Practice mode'));

  const ExamMode(this.label);

  final Tr label;
}

enum ReviewPolicy {
  afterSubmit(Tr('জমার পর উত্তর দেখাবে', 'Show answers after submitting')),
  immediate(Tr('প্রতিটি উত্তরের পরই', 'After each answer')),
  never(Tr('শুধু নম্বর দেখাবে', 'Score only'));

  const ReviewPolicy(this.label);

  final Tr label;
}

/// Everything chosen on the exam setup screen.
@immutable
class ExamConfig {
  const ExamConfig({
    this.subjectId,
    this.chapterIds = const [],
    this.types = const {},
    this.questionCount = 10,
    this.difficulty,
    this.timeLimitMinutes = 15,
    this.negativeMarking = false,
    this.mode = ExamMode.exam,
    this.randomize = true,
    this.reviewPolicy = ReviewPolicy.afterSubmit,
  });

  factory ExamConfig.fromJson(Map<String, dynamic> j) => ExamConfig(
    subjectId: j['subjectId'] as String?,
    chapterIds: List<String>.from(j['chapterIds'] as List? ?? const []),
    types: {for (final t in j['types'] as List? ?? const []) QuestionType.values.byName(t as String)},
    questionCount: j['questionCount'] as int? ?? 10,
    difficulty: j['difficulty'] == null ? null : Difficulty.values.byName(j['difficulty'] as String),
    timeLimitMinutes: j['timeLimitMinutes'] as int? ?? 15,
    negativeMarking: j['negativeMarking'] as bool? ?? false,
    mode: ExamMode.values.byName(j['mode'] as String? ?? 'exam'),
    randomize: j['randomize'] as bool? ?? true,
    reviewPolicy: ReviewPolicy.values.byName(j['reviewPolicy'] as String? ?? 'afterSubmit'),
  );

  final String? subjectId;
  final List<String> chapterIds;
  final Set<QuestionType> types;
  final int questionCount;
  final Difficulty? difficulty;
  final int timeLimitMinutes;

  /// Deducts 25% of a question's marks for a wrong objective answer.
  final bool negativeMarking;
  final ExamMode mode;
  final bool randomize;
  final ReviewPolicy reviewPolicy;

  static const negativeFraction = 0.25;

  bool accepts(Question q) =>
      (subjectId == null || q.subjectId == subjectId) &&
      (chapterIds.isEmpty || chapterIds.contains(q.chapterId)) &&
      (types.isEmpty || types.contains(q.type)) &&
      (difficulty == null || q.difficulty == difficulty);

  ExamConfig copyWith({
    String? Function()? subjectId,
    List<String>? chapterIds,
    Set<QuestionType>? types,
    int? questionCount,
    Difficulty? Function()? difficulty,
    int? timeLimitMinutes,
    bool? negativeMarking,
    ExamMode? mode,
    bool? randomize,
    ReviewPolicy? reviewPolicy,
  }) => ExamConfig(
    subjectId: subjectId == null ? this.subjectId : subjectId(),
    chapterIds: chapterIds ?? this.chapterIds,
    types: types ?? this.types,
    questionCount: questionCount ?? this.questionCount,
    difficulty: difficulty == null ? this.difficulty : difficulty(),
    timeLimitMinutes: timeLimitMinutes ?? this.timeLimitMinutes,
    negativeMarking: negativeMarking ?? this.negativeMarking,
    mode: mode ?? this.mode,
    randomize: randomize ?? this.randomize,
    reviewPolicy: reviewPolicy ?? this.reviewPolicy,
  );

  Map<String, dynamic> toJson() => {
    'subjectId': subjectId,
    'chapterIds': chapterIds,
    'types': [for (final t in types) t.name],
    'questionCount': questionCount,
    'difficulty': difficulty?.name,
    'timeLimitMinutes': timeLimitMinutes,
    'negativeMarking': negativeMarking,
    'mode': mode.name,
    'randomize': randomize,
    'reviewPolicy': reviewPolicy.name,
  };
}

/// A ready-made exam offered to the student (model tests, teacher exams…).
@immutable
class ExamTemplate {
  const ExamTemplate({
    required this.id,
    required this.type,
    required this.title,
    required this.config,
    this.description,
    this.questionIds = const [],
    this.scheduledAt,
    this.dueAt,
    this.assignedBy,
    this.createdAt,
  });

  factory ExamTemplate.fromJson(Map<String, dynamic> j) => ExamTemplate(
    id: j['id'] as String,
    type: ExamType.values.byName(j['type'] as String),
    title: Tr.fromJson(j['title']),
    config: ExamConfig.fromJson(j['config'] as Map<String, dynamic>),
    description: j['description'] == null ? null : Tr.fromJson(j['description']),
    questionIds: List<String>.from(j['questionIds'] as List? ?? const []),
    scheduledAt: j['scheduledAt'] == null ? null : DateTime.parse(j['scheduledAt'] as String),
    dueAt: j['dueAt'] == null ? null : DateTime.parse(j['dueAt'] as String),
    assignedBy: j['assignedBy'] == null ? null : Tr.fromJson(j['assignedBy']),
    createdAt: j['createdAt'] == null ? null : DateTime.parse(j['createdAt'] as String),
  );

  final String id;
  final ExamType type;
  final Tr title;
  final ExamConfig config;
  final Tr? description;

  /// Fixed paper. Empty → questions are drawn from [config] when the attempt starts.
  final List<String> questionIds;
  final DateTime? scheduledAt;
  final DateTime? dueAt;
  final Tr? assignedBy;
  final DateTime? createdAt;

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type.name,
    'title': title.toJson(),
    'config': config.toJson(),
    'description': description?.toJson(),
    'questionIds': questionIds,
    'scheduledAt': scheduledAt?.toIso8601String(),
    'dueAt': dueAt?.toIso8601String(),
    'assignedBy': assignedBy?.toJson(),
    'createdAt': createdAt?.toIso8601String(),
  };
}

/// The student's answer to one exam question.
@immutable
class ExamAnswer {
  const ExamAnswer({this.choice, this.text, this.imagePaths = const [], this.markedForReview = false});

  factory ExamAnswer.fromJson(Map<String, dynamic> j) => ExamAnswer(
    choice: j['choice'] as int?,
    text: j['text'] as String?,
    imagePaths: List<String>.from(j['imagePaths'] as List? ?? const []),
    markedForReview: j['markedForReview'] as bool? ?? false,
  );

  final int? choice;
  final String? text;

  /// Photos of a handwritten answer (file paths on the device).
  final List<String> imagePaths;
  final bool markedForReview;

  bool get isAnswered => choice != null || (text?.trim().isNotEmpty ?? false) || imagePaths.isNotEmpty;

  ExamAnswer copyWith({int? Function()? choice, String? text, List<String>? imagePaths, bool? markedForReview}) => ExamAnswer(
    choice: choice == null ? this.choice : choice(),
    text: text ?? this.text,
    imagePaths: imagePaths ?? this.imagePaths,
    markedForReview: markedForReview ?? this.markedForReview,
  );

  Map<String, dynamic> toJson() => {'choice': choice, 'text': text, 'imagePaths': imagePaths, 'markedForReview': markedForReview};
}

enum AttemptStatus { inProgress, submitted, expired }

/// One sitting of an exam. Saved on every change so it can be recovered after a crash.
@immutable
class ExamAttempt {
  const ExamAttempt({
    required this.id,
    required this.type,
    required this.title,
    required this.config,
    required this.questionIds,
    required this.startedAt,
    this.templateId,
    this.answers = const {},
    this.currentIndex = 0,
    this.remainingSeconds,
    this.status = AttemptStatus.inProgress,
    this.submittedAt,
    this.result,
  });

  factory ExamAttempt.fromJson(Map<String, dynamic> j) => ExamAttempt(
    id: j['id'] as String,
    type: ExamType.values.byName(j['type'] as String),
    title: Tr.fromJson(j['title']),
    config: ExamConfig.fromJson(j['config'] as Map<String, dynamic>),
    questionIds: List<String>.from(j['questionIds'] as List),
    startedAt: DateTime.parse(j['startedAt'] as String),
    templateId: j['templateId'] as String?,
    answers: {
      for (final e in (j['answers'] as Map<String, dynamic>? ?? const {}).entries)
        e.key: ExamAnswer.fromJson(e.value as Map<String, dynamic>),
    },
    currentIndex: j['currentIndex'] as int? ?? 0,
    remainingSeconds: j['remainingSeconds'] as int?,
    status: AttemptStatus.values.byName(j['status'] as String? ?? 'inProgress'),
    submittedAt: j['submittedAt'] == null ? null : DateTime.parse(j['submittedAt'] as String),
    result: j['result'] == null ? null : ExamResult.fromJson(j['result'] as Map<String, dynamic>),
  );

  final String id;
  final ExamType type;
  final Tr title;
  final ExamConfig config;
  final List<String> questionIds;
  final DateTime startedAt;
  final String? templateId;
  final Map<String, ExamAnswer> answers;
  final int currentIndex;

  /// Saved by the timer (autosave), so a recovered session continues with the right time.
  final int? remainingSeconds;
  final AttemptStatus status;
  final DateTime? submittedAt;
  final ExamResult? result;

  bool get isFinished => status != AttemptStatus.inProgress;
  int get answeredCount => answers.values.where((a) => a.isAnswered).length;
  int get reviewCount => answers.values.where((a) => a.markedForReview).length;
  ExamAnswer answerFor(String questionId) => answers[questionId] ?? const ExamAnswer();

  ExamAttempt copyWith({
    Map<String, ExamAnswer>? answers,
    int? currentIndex,
    int? remainingSeconds,
    AttemptStatus? status,
    DateTime? submittedAt,
    ExamResult? result,
  }) => ExamAttempt(
    id: id,
    type: type,
    title: title,
    config: config,
    questionIds: questionIds,
    startedAt: startedAt,
    templateId: templateId,
    answers: answers ?? this.answers,
    currentIndex: currentIndex ?? this.currentIndex,
    remainingSeconds: remainingSeconds ?? this.remainingSeconds,
    status: status ?? this.status,
    submittedAt: submittedAt ?? this.submittedAt,
    result: result ?? this.result,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type.name,
    'title': title.toJson(),
    'config': config.toJson(),
    'questionIds': questionIds,
    'startedAt': startedAt.toIso8601String(),
    'templateId': templateId,
    'answers': {for (final e in answers.entries) e.key: e.value.toJson()},
    'currentIndex': currentIndex,
    'remainingSeconds': remainingSeconds,
    'status': status.name,
    'submittedAt': submittedAt?.toIso8601String(),
    'result': result?.toJson(),
  };
}

enum Outcome { correct, incorrect, unanswered, estimated }

/// Per-question scoring line.
@immutable
class QuestionScore {
  const QuestionScore({required this.questionId, required this.outcome, required this.marks, required this.maxMarks});

  factory QuestionScore.fromJson(Map<String, dynamic> j) => QuestionScore(
    questionId: j['questionId'] as String,
    outcome: Outcome.values.byName(j['outcome'] as String),
    marks: (j['marks'] as num).toDouble(),
    maxMarks: j['maxMarks'] as int,
  );

  final String questionId;
  final Outcome outcome;

  /// May be negative with negative marking.
  final double marks;
  final int maxMarks;

  Map<String, dynamic> toJson() => {'questionId': questionId, 'outcome': outcome.name, 'marks': marks, 'maxMarks': maxMarks};
}

@immutable
class ExamResult {
  const ExamResult({required this.scores, required this.timeSpentSeconds, this.teacherFeedback});

  factory ExamResult.fromJson(Map<String, dynamic> j) => ExamResult(
    scores: [for (final s in j['scores'] as List) QuestionScore.fromJson(s as Map<String, dynamic>)],
    timeSpentSeconds: j['timeSpentSeconds'] as int,
    teacherFeedback: j['teacherFeedback'] == null ? null : Tr.fromJson(j['teacherFeedback']),
  );

  final List<QuestionScore> scores;
  final int timeSpentSeconds;
  final Tr? teacherFeedback;

  double get score => scores.fold<double>(0, (s, q) => s + q.marks).clamp(0, double.infinity);
  int get totalMarks => scores.fold(0, (s, q) => s + q.maxMarks);
  int count(Outcome o) => scores.where((s) => s.outcome == o).length;

  /// Share of answered objective questions that were right.
  double? get accuracy {
    final judged = count(Outcome.correct) + count(Outcome.incorrect);
    return judged == 0 ? null : count(Outcome.correct) / judged;
  }

  double get percent => totalMarks == 0 ? 0 : score / totalMarks;
  bool get hasEstimates => count(Outcome.estimated) > 0;

  Map<String, dynamic> toJson() => {
    'scores': [for (final s in scores) s.toJson()],
    'timeSpentSeconds': timeSpentSeconds,
    'teacherFeedback': teacherFeedback?.toJson(),
  };
}

/// Grade letter on the Bangladesh SSC/HSC scale.
({String grade, double gpa}) gradeFor(double percent) {
  final p = percent * 100;
  if (p >= 80) return (grade: 'A+', gpa: 5.0);
  if (p >= 70) return (grade: 'A', gpa: 4.0);
  if (p >= 60) return (grade: 'A-', gpa: 3.5);
  if (p >= 50) return (grade: 'B', gpa: 3.0);
  if (p >= 40) return (grade: 'C', gpa: 2.0);
  if (p >= 33) return (grade: 'D', gpa: 1.0);
  return (grade: 'F', gpa: 0.0);
}
