import '../../../core/l10n/tr.dart';
import '../../../core/network/api_client.dart';
import '../../curriculum/domain/curriculum_models.dart';
import '../../question_bank/data/question_mapper.dart';
import '../../question_bank/domain/question.dart';
import '../domain/exam.dart';

/// Exams on the education-backend. The server picks questions, keeps the timer and scores the
/// attempt (it also records the answers in progress and raises the result notification).
class RemoteExams {
  RemoteExams(this._api, this.studentId);

  final ApiClient _api;
  final String studentId;

  static const _letters = 'abcdefghij';

  // ── Mapping ───────────────────────────────────────────────────────────

  static ExamType typeOf(String? kind) => switch (kind) {
    'chapter' => ExamType.chapter,
    'topic' => ExamType.topic,
    'subject' => ExamType.subject,
    'full_syllabus' => ExamType.fullSyllabus,
    'model_test' || 'institution' => ExamType.modelTest,
    'board_previous' => ExamType.boardPrevious,
    'daily_challenge' => ExamType.dailyChallenge,
    'adaptive' => ExamType.adaptive,
    'teacher_assigned' => ExamType.teacherAssigned,
    'mixed' => ExamType.mixed,
    'oral' => ExamType.oral,
    _ => ExamType.custom,
  };

  static String kindOf(ExamType t) => switch (t) {
    ExamType.fullSyllabus => 'full_syllabus',
    ExamType.modelTest => 'model_test',
    ExamType.boardPrevious => 'board_previous',
    ExamType.dailyChallenge => 'daily_challenge',
    ExamType.teacherAssigned => 'teacher_assigned',
    _ => t.name,
  };

  static ReviewPolicy _policy(String? p) => switch (p) {
    'immediate' => ReviewPolicy.immediate,
    'after_publish' => ReviewPolicy.never,
    _ => ReviewPolicy.afterSubmit,
  };

  static String _serverPolicy(ReviewPolicy p) => switch (p) {
    ReviewPolicy.immediate => 'immediate',
    ReviewPolicy.never => 'after_publish',
    ReviewPolicy.afterSubmit => 'after_submit',
  };

  static DateTime? _date(Object? v) => v is String ? DateTime.tryParse(v) : null;

  static ExamConfig configFrom(Map<String, dynamic> e) {
    final ids = e['questionIds'] as List? ?? const [];
    final marks = (e['totalMarks'] as num?)?.toDouble() ?? 10;
    return ExamConfig(
      subjectId: e['subjectId'] as String?,
      chapterIds: [for (final c in e['chapterIds'] as List? ?? const []) c as String],
      types: {for (final t in e['questionTypes'] as List? ?? const []) questionTypeFromApi(t)},
      // Catalogue exams draw their questions when the attempt starts (same rule as the server).
      questionCount: ids.isNotEmpty ? ids.length : (marks / 1.2).round().clamp(5, 25),
      difficulty: Difficulty.values.where((d) => d.name == e['difficulty']).firstOrNull,
      timeLimitMinutes: (e['durationMinutes'] as num?)?.round() ?? 15,
      negativeMarking: ((e['negativeMarking'] as num?) ?? 0) > 0,
      mode: e['mode'] == 'practice' ? ExamMode.practice : ExamMode.exam,
      randomize: e['randomize'] as bool? ?? true,
      reviewPolicy: _policy(e['reviewPolicy'] as String?),
    );
  }

  /// Exams offered to the student. Personal custom exams and daily challenges are created per
  /// attempt, so they are not listed as templates.
  static bool isOffered(Map<String, dynamic> e) =>
      e['kind'] != 'custom' && e['kind'] != 'daily_challenge' && (e['status'] == 'published' || e['status'] == 'scheduled');

  static ExamTemplate templateFrom(Map<String, dynamic> e) {
    final by = (e['createdBy'] as Map?)?.cast<String, dynamic>();
    final instructions = [for (final i in e['instructions'] as List? ?? const []) i as String];
    return ExamTemplate(
      id: e['id'] as String,
      type: typeOf(e['kind'] as String?),
      title: Tr.same(e['title'] as String? ?? ''),
      config: configFrom(e),
      description: instructions.isEmpty ? null : Tr.same(instructions.join('\n')),
      questionIds: [for (final q in e['questionIds'] as List? ?? const []) q as String],
      scheduledAt: _date(e['scheduledAt']),
      dueAt: _date(e['closesAt']),
      assignedBy: by == null || by['role'] == 'system' ? null : Tr.same(by['name'] as String? ?? ''),
      createdAt: _date(e['createdAt']),
    );
  }

  static ExamAnswer answerFrom(Question? q, Map<String, dynamic> a, {bool marked = false}) {
    int? choice;
    if (a['optionId'] is String) {
      final i = _letters.indexOf(a['optionId'] as String);
      choice = i < 0 ? null : i;
    } else if (a['booleanValue'] is bool) {
      choice = a['booleanValue'] == true ? 0 : 1;
    }
    final text = a['text'] as String? ??
        (a['blanks'] is List ? (a['blanks'] as List).join(', ') : null) ??
        (a['numeric'] is num ? '${a['numeric']}' : null);
    return ExamAnswer(
      choice: choice,
      text: text,
      imagePaths: [for (final n in a['uploadNames'] as List? ?? const []) n as String],
      markedForReview: marked,
    );
  }

  /// The app's answer in the server's shape for the question's type.
  static Map<String, dynamic>? answerToApi(Question? q, ExamAnswer a) {
    if (!a.isAnswered) return null;
    final text = a.text?.trim();
    final out = <String, dynamic>{};
    if (a.choice != null) {
      if (q?.type == QuestionType.trueFalse) {
        out['booleanValue'] = a.choice == 0;
      } else if (a.choice! < _letters.length) {
        out['optionId'] = _letters[a.choice!];
      }
    }
    if (text != null && text.isNotEmpty) {
      switch (q?.type) {
        case QuestionType.fillBlank:
          out['blanks'] = [for (final b in text.split(',')) b.trim()];
        case QuestionType.numerical:
          final n = num.tryParse(text.replaceAll(RegExp('[^0-9.+-eE]'), ''));
          if (n != null) out['numeric'] = n;
          out['text'] = text;
        default:
          out['text'] = text;
      }
    }
    if (a.imagePaths.isNotEmpty) out['uploadNames'] = [for (final p in a.imagePaths) p.split(RegExp(r'[/\\]')).last];
    return out;
  }

  static Map<String, dynamic> answersToApi(ExamAttempt a, Map<String, Question> questions) => {
    for (final e in a.answers.entries)
      e.key: ?answerToApi(questions[e.key], e.value),
  };

  static Outcome _outcome(String? status) => switch (status) {
    'correct' => Outcome.correct,
    'incorrect' => Outcome.incorrect,
    'pending_review' || 'partial' => Outcome.estimated,
    _ => Outcome.unanswered,
  };

  static ExamResult resultFrom(Map<String, dynamic> r) {
    final feedback = (r['teacherFeedback'] as Map?)?['text'] as String?;
    return ExamResult(
      scores: [
        for (final q in r['questions'] as List? ?? const [])
          QuestionScore(
            questionId: (q as Map)['questionId'] as String,
            outcome: _outcome(q['status'] as String?),
            marks: (q['awarded'] as num?)?.toDouble() ?? 0,
            maxMarks: (q['max'] as num?)?.round() ?? 1,
          ),
      ],
      timeSpentSeconds: (r['timeSpentSec'] as num?)?.round() ?? 0,
      teacherFeedback: feedback == null ? null : Tr.same(feedback),
    );
  }

  /// [exams] are all of the student's exam records (for the type and setup of each attempt).
  static ExamAttempt attemptFrom(Map<String, dynamic> a, {required Map<String, Map<String, dynamic>> exams, Map<String, Question> questions = const {}}) {
    final exam = exams[a['examId']];
    final marked = {for (final id in a['markedForReview'] as List? ?? const []) id as String};
    final order = [for (final q in a['questionOrder'] as List? ?? const []) q as String];
    final answers = <String, ExamAnswer>{
      for (final e in (a['answers'] as Map? ?? const {}).entries)
        e.key as String: answerFrom(questions[e.key], (e.value as Map).cast<String, dynamic>(), marked: marked.contains(e.key)),
    };
    for (final id in marked) {
      answers.putIfAbsent(id, () => const ExamAnswer(markedForReview: true));
    }
    final status = switch (a['status']) {
      'submitted' => AttemptStatus.submitted,
      'expired' => AttemptStatus.expired,
      _ => AttemptStatus.inProgress,
    };
    return ExamAttempt(
      id: a['id'] as String,
      type: typeOf(exam?['kind'] as String?),
      title: Tr.same(a['examTitle'] as String? ?? exam?['title'] as String? ?? ''),
      config: exam == null ? ExamConfig(questionCount: order.length) : configFrom(exam),
      questionIds: order,
      startedAt: _date(a['startedAt']) ?? DateTime.now(),
      templateId: exam != null && isOffered(exam) ? exam['id'] as String : null,
      answers: answers,
      currentIndex: (a['currentIndex'] as num?)?.round() ?? 0,
      remainingSeconds: _remaining(a, exam, status),
      status: status,
      submittedAt: _date(a['submittedAt']),
      result: a['result'] is Map ? resultFrom((a['result'] as Map).cast<String, dynamic>()) : null,
    );
  }

  /// The stored `remainingSec` is from the last autosave; the deadline runs from `startedAt`.
  static int? _remaining(Map<String, dynamic> a, Map<String, dynamic>? exam, AttemptStatus status) {
    final saved = (a['remainingSec'] as num?)?.round();
    final started = _date(a['startedAt']);
    final minutes = (exam?['durationMinutes'] as num?)?.round();
    if (status != AttemptStatus.inProgress || started == null || minutes == null) return saved;
    return (minutes * 60 - DateTime.now().difference(started).inSeconds).clamp(0, minutes * 60);
  }

  static Map<String, dynamic> setupBody(ExamConfig c, ExamType type, Tr? title) => {
    'kind': kindOf(type),
    'title': ?title?.bn,
    'subjectId': ?c.subjectId,
    'chapterIds': c.chapterIds,
    'types': [for (final t in c.types) questionTypeToApi(t)],
    'count': c.questionCount,
    'difficulty': c.difficulty?.name ?? 'mixed',
    'durationMinutes': c.timeLimitMinutes,
    'negativeMarking': c.negativeMarking ? ExamConfig.negativeFraction : 0,
    'mode': c.mode.name,
    'randomize': c.randomize,
    'reviewPolicy': _serverPolicy(c.reviewPolicy),
    'levelCode': (c.subjectId ?? '').startsWith('hsc') ? 'HSC' : 'SSC',
  };

  // ── Requests ──────────────────────────────────────────────────────────

  List<Map<String, dynamic>> _list(Object? d) => [for (final x in d! as List) (x as Map).cast<String, dynamic>()];

  Future<List<Map<String, dynamic>>> exams() async => (await _api.get('/exams', query: {'all': true}, parse: _list)).data;

  Future<List<Map<String, dynamic>>> attempts() async => (await _api.get('/exam-attempts/$studentId', query: {'all': true}, parse: _list)).data;

  Future<Map<String, dynamic>> attempt(String id) async =>
      (await _api.get('/exam-attempts/$studentId/$id', parse: (d) => (d! as Map).cast<String, dynamic>())).data;

  /// The attempt's questions (answer keys hidden while it is in progress).
  Future<List<Question>> questions(String attemptId) async =>
      [for (final q in (await _api.get('/exam-attempts/$studentId/$attemptId/questions', parse: _list)).data) questionFromApi(q)];

  Future<String> _attemptId(Future<dynamic> req) async => ((await req).data as Map)['attemptId'] as String;

  Future<String> startExam(String examId) => _attemptId(_api.post('/exams/$examId/attempts', parse: (d) => d));

  Future<String> startDaily({String levelCode = 'SSC'}) => _attemptId(_api.post('/exams/daily-challenge', body: {'levelCode': levelCode}, parse: (d) => d));

  Future<String> startCustom(ExamConfig c, ExamType type, Tr? title) => _attemptId(_api.post('/exams/custom', body: setupBody(c, type, title), parse: (d) => d));

  Future<void> save(String attemptId, {required Map<String, dynamic> answers, required List<String> marked, required int currentIndex}) =>
      _api.patch('/exam-attempts/$studentId/$attemptId', body: {'answers': answers, 'markedForReview': marked, 'currentIndex': currentIndex}, parse: (d) => d);

  Future<Map<String, dynamic>> submit(String attemptId, {required Map<String, dynamic> answers, bool expired = false}) async =>
      (await _api.post('/exam-attempts/$studentId/$attemptId/submit', body: {'reason': expired ? 'time_expired' : 'manual', 'answers': answers}, parse: (d) => (d! as Map).cast<String, dynamic>())).data;

  Future<void> discard(String attemptId) => _api.sendNoContent('DELETE', '/exam-attempts/$studentId/$attemptId');
}
