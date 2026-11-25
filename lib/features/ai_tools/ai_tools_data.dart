import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/l10n/tr.dart';
import '../../core/storage/local_store.dart';
import '../account/account_controller.dart';

/// Saved voice-tutor session (VOICE-26, VOICE-30).
class VoiceSession {
  const VoiceSession({required this.id, required this.startedAt, required this.endedAt, required this.mode, required this.language, required this.turns});

  factory VoiceSession.fromJson(Map<String, dynamic> j) => VoiceSession(
    id: j['id'] as String,
    startedAt: DateTime.parse(j['startedAt'] as String),
    endedAt: DateTime.parse(j['endedAt'] as String),
    mode: j['mode'] as String,
    language: j['language'] as String,
    turns: [for (final t in j['turns'] as List) ((t as Map)['student'] as bool, t['text'] as String)],
  );

  final String id;
  final DateTime startedAt;
  final DateTime endedAt;

  /// TeachingMode name.
  final String mode;

  /// `bn` | `en` | `mixed`
  final String language;
  final List<(bool student, String text)> turns;

  /// Billed minutes (at least one per session with an answer).
  int get minutes => turns.any((t) => !t.$1) ? (endedAt.difference(startedAt).inSeconds / 60).ceil().clamp(1, 600) : 0;

  String get title {
    final first = turns.where((t) => t.$1).firstOrNull?.$2 ?? '';
    return first.length > 60 ? '${first.substring(0, 60)}…' : first;
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'startedAt': startedAt.toIso8601String(),
    'endedAt': endedAt.toIso8601String(),
    'mode': mode,
    'language': language,
    'turns': [for (final (s, t) in turns) {'student': s, 'text': t}],
  };
}

/// One photo solved (history, saved to notes / practice).
class PhotoSolve {
  const PhotoSolve({required this.id, required this.at, required this.text, required this.subjectId, required this.answer, this.chapterId, this.images = 1});

  factory PhotoSolve.fromJson(Map<String, dynamic> j) => PhotoSolve(
    id: j['id'] as String,
    at: DateTime.parse(j['at'] as String),
    text: j['text'] as String,
    subjectId: j['subjectId'] as String,
    answer: j['answer'] as String,
    chapterId: j['chapterId'] as String?,
    images: j['images'] as int? ?? 1,
  );

  final String id;
  final DateTime at;
  final String text;
  final String subjectId;
  final String answer;
  final String? chapterId;
  final int images;

  Map<String, dynamic> toJson() => {'id': id, 'at': at.toIso8601String(), 'text': text, 'subjectId': subjectId, 'answer': answer, 'chapterId': chapterId, 'images': images};
}

/// One handwriting evaluation (HWE-19..22).
class EvaluationRecord {
  const EvaluationRecord({
    required this.id,
    required this.at,
    required this.questionId,
    required this.pages,
    required this.marks,
    required this.total,
    required this.criteria,
    required this.extracted,
    this.submissionId,
  });

  factory EvaluationRecord.fromJson(Map<String, dynamic> j) => EvaluationRecord(
    id: j['id'] as String,
    at: DateTime.parse(j['at'] as String),
    questionId: j['questionId'] as String,
    pages: j['pages'] as int,
    marks: (j['marks'] as num).toDouble(),
    total: j['total'] as int,
    criteria: [for (final c in j['criteria'] as List) (Tr.fromJson((c as Map)['name']), (c['got'] as num).toDouble(), c['max'] as int)],
    extracted: j['extracted'] as String,
    submissionId: j['submissionId'] as String?,
  );

  final String id;
  final DateTime at;
  final String questionId;
  final int pages;
  final double marks;
  final int total;
  final List<(Tr, double, int)> criteria;

  /// OCR text (as corrected by the student).
  final String extracted;

  /// Teacher-portal submission when a teacher review was requested.
  final String? submissionId;

  EvaluationRecord withSubmission(String id) =>
      EvaluationRecord(id: this.id, at: at, questionId: questionId, pages: pages, marks: marks, total: total, criteria: criteria, extracted: extracted, submissionId: id);

  Map<String, dynamic> toJson() => {
    'id': id,
    'at': at.toIso8601String(),
    'questionId': questionId,
    'pages': pages,
    'marks': marks,
    'total': total,
    'criteria': [for (final (n, g, m) in criteria) {'name': n.toJson(), 'got': g, 'max': m}],
    'extracted': extracted,
    'submissionId': submissionId,
  };
}

class AiToolsState {
  const AiToolsState({this.sessions = const [], this.solves = const [], this.evaluations = const [], this.ocrReports = 0});

  final List<VoiceSession> sessions;
  final List<PhotoSolve> solves;
  final List<EvaluationRecord> evaluations;
  final int ocrReports;

  /// Voice minutes used this calendar month (VOICE-27).
  int minutesThisMonth(DateTime now) => sessions.where((s) => s.startedAt.year == now.year && s.startedAt.month == now.month).fold(0, (a, s) => a + s.minutes);

  AiToolsState copyWith({List<VoiceSession>? sessions, List<PhotoSolve>? solves, List<EvaluationRecord>? evaluations, int? ocrReports}) => AiToolsState(
    sessions: sessions ?? this.sessions,
    solves: solves ?? this.solves,
    evaluations: evaluations ?? this.evaluations,
    ocrReports: ocrReports ?? this.ocrReports,
  );
}

/// Monthly voice allowance per plan (minutes).
int voiceAllowance(PlanCode plan) => plan == PlanCode.free ? 30 : 300;

class AiToolsController extends Notifier<AiToolsState> {
  static const _col = 'aiTools';
  late LocalStore _store;

  @override
  AiToolsState build() {
    _store = watchStore(ref);
    final d = _store.get(_col, 'me');
    if (d == null) return const AiToolsState();
    return AiToolsState(
      sessions: [for (final s in d['sessions'] as List? ?? const []) VoiceSession.fromJson((s as Map).cast())],
      solves: [for (final s in d['solves'] as List? ?? const []) PhotoSolve.fromJson((s as Map).cast())],
      evaluations: [for (final e in d['evaluations'] as List? ?? const []) EvaluationRecord.fromJson((e as Map).cast())],
      ocrReports: d['ocrReports'] as int? ?? 0,
    );
  }

  Future<void> _save(AiToolsState s) async {
    state = s;
    await _store.put(_col, 'me', {
      'sessions': [for (final x in s.sessions) x.toJson()],
      'solves': [for (final x in s.solves) x.toJson()],
      'evaluations': [for (final x in s.evaluations) x.toJson()],
      'ocrReports': s.ocrReports,
    });
  }

  Future<void> saveSession(VoiceSession s) async {
    if (s.turns.isEmpty) return;
    await _save(state.copyWith(sessions: [s, ...state.sessions.where((x) => x.id != s.id)]));
  }

  Future<void> deleteSession(String id) => _save(state.copyWith(sessions: state.sessions.where((s) => s.id != id).toList()));

  Future<void> addSolve(PhotoSolve s) => _save(state.copyWith(solves: [s, ...state.solves].take(30).toList()));

  Future<void> reportOcr() => _save(state.copyWith(ocrReports: state.ocrReports + 1));

  Future<void> addEvaluation(EvaluationRecord e) => _save(state.copyWith(evaluations: [e, ...state.evaluations]));

  Future<void> linkSubmission(String evaluationId, String submissionId) =>
      _save(state.copyWith(evaluations: [for (final e in state.evaluations) e.id == evaluationId ? e.withSubmission(submissionId) : e]));
}

final aiToolsProvider = NotifierProvider<AiToolsController, AiToolsState>(AiToolsController.new);
