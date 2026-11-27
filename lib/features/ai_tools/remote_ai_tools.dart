import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/network/api_client.dart';
import '../../core/network/network_providers.dart';
import '../progress/data/remote_progress.dart';

/// The AI study tools on the backend (answered by education-ai): photo solver, answer-script
/// transcription and marking, voice tutor, audio lessons, flashcards, notes and English writing.
class RemoteAiTools {
  RemoteAiTools(this._api, this.studentId);

  final ApiClient _api;
  final String studentId;

  static Map<String, dynamic> _map(Object? d) => (d! as Map).cast<String, dynamic>();

  /// A picked photo as a `data:` URL (JPEG/PNG/WebP; the picker already scales it down).
  static Future<String> dataUrl(String path) async {
    final bytes = await XFile(path).readAsBytes();
    final ext = path.split('.').last.toLowerCase();
    final type = switch (ext) {
      'png' => 'image/png',
      'webp' => 'image/webp',
      _ => 'image/jpeg',
    };
    return 'data:$type;base64,${base64Encode(bytes)}';
  }

  /// Formats a server solution as Markdown (numbered steps, answer, explanation).
  static String solutionText(Map<String, dynamic> s) {
    final steps = [for (final st in s['steps'] as List? ?? const []) st as String];
    return [
      for (final (i, st) in steps.indexed) '${i + 1}. $st',
      if ((s['answer'] as String? ?? '').isNotEmpty) '\n**উত্তর:** ${s['answer']}',
      if ((s['explanation'] as String? ?? '').isNotEmpty) '\n${s['explanation']}',
    ].join('\n');
  }

  // ── Photo solver ──────────────────────────────────────────────────────

  /// Reads a photo; [save] keeps the job in the photo-solver history on the server.
  Future<({String? jobId, String text, String? subjectId, bool readable})> readPhoto(String path, {bool save = true}) async {
    final res = (await _api.post('/ocr/$studentId/solve', body: {'fileName': path.split('/').last, 'image': await dataUrl(path), 'solve': false, 'save': save}, parse: _map)).data;
    final job = _map(res['job']);
    return (jobId: save ? job['id'] as String? : null, text: job['extractedText'] as String? ?? '', subjectId: job['detectedSubjectId'] as String?, readable: job['status'] != 'unreadable');
  }

  /// Solves a photo job's corrected text (stored on the job), or a typed problem.
  Future<String> solve(String text, {String? jobId, String? subjectId, String? chapterId}) async {
    final body = {'correctedText': text, 'subjectId': ?subjectId, 'chapterId': ?chapterId};
    if (jobId != null) {
      final job = (await _api.post('/ocr/$studentId/$jobId/solve', body: body, parse: _map)).data;
      return solutionText(_map(job['solution']));
    }
    return solutionText((await _api.post('/solve/$studentId', body: body, parse: _map)).data);
  }

  // ── Answer scripts ────────────────────────────────────────────────────

  /// Transcribes the pages (nothing stored).
  Future<String> transcribe(List<String> paths) async {
    final out = <String>[];
    for (final (i, p) in paths.indexed) {
      final r = await readPhoto(p, save: false);
      out.add(paths.length > 1 ? '[পৃষ্ঠা ${i + 1}]\n${r.text}' : r.text);
    }
    return out.join('\n\n');
  }

  /// Stores the script and has the AI mark it; returns the marked evaluation record.
  Future<Map<String, dynamic>> evaluate({
    required String id,
    required String studentName,
    required String title,
    required String subjectId,
    required String questionId,
    required String questionText,
    required String modelAnswer,
    required List<String> pagePaths,
    required List<(String criterion, int max)> rubric,
    required String ocrText,
    String? correctedText,
  }) async {
    final now = DateTime.now().toUtc().toIso8601String();
    await _api.post('/evaluations/$studentId', body: {
      'id': id,
      'studentId': studentId,
      'studentName': studentName,
      'title': title,
      'subjectId': subjectId,
      'questionId': questionId,
      'questionText': questionText,
      'modelAnswer': modelAnswer,
      'pages': [
        for (final (i, p) in pagePaths.indexed) {'id': '$id-p$i', 'name': p.split('/').last, 'preview': await dataUrl(p), 'rotation': 0},
      ],
      'ocrText': ocrText,
      'correctedText': ?correctedText,
      'stage': 'uploaded',
      'rubric': [for (final (c, m) in rubric) {'criterion': c, 'max': m, 'ai': 0}],
      'maxMarks': rubric.fold<int>(0, (n, r) => n + r.$2),
      'dimensions': {'concept': 0, 'calculation': 0, 'presentation': 0},
      'missingPoints': <String>[],
      'suggestions': <String>[],
      'createdAt': now,
      'updatedAt': now,
    }, parse: (d) => d);
    final res = (await _api.post('/evaluations/$studentId/$id/evaluate', parse: _map)).data;
    return _map(res['evaluation']);
  }

  Future<void> requestReview(String evaluationId) =>
      _api.patch('/evaluations/$studentId/$evaluationId', body: {'stage': 'teacher_review_requested'}, parse: (d) => d);

  // ── Voice, audio, flashcards, notes, English ──────────────────────────

  /// One voice-tutor turn: the reply text, and in an oral exam the next question and score.
  Future<({String text, String? nextQuestion, int? got, int? max})> voiceReply({
    required String text,
    required bool oralExam,
    required String language,
    String? subjectId,
    String? oralQuestion,
    List<(bool student, String text)> turns = const [],
  }) async {
    final r = (await _api.post('/voice/$studentId/reply', body: {
      'text': text,
      'mode': oralExam ? 'oral_exam' : 'tutor',
      'language': language,
      'subjectId': ?subjectId,
      'oralQuestion': ?oralQuestion,
      'turns': [
        for (final (student, t) in turns.length > 10 ? turns.sublist(turns.length - 10) : turns) {'speaker': student ? 'student' : 'tutor', 'text': t},
      ],
    }, parse: _map)).data;
    final score = r['score'] as Map?;
    return (text: r['text'] as String? ?? '', nextQuestion: r['nextQuestion'] as String?, got: (score?['got'] as num?)?.round(), max: (score?['max'] as num?)?.round());
  }

  /// A new audio lesson for a chapter (saved to the server catalogue).
  Future<Map<String, dynamic>> audioLesson(String chapterId, {int minutes = 5}) async =>
      (await _api.post('/audio-lessons/generate', body: {'chapterId': chapterId, 'minutes': minutes}, parse: _map)).data;

  Future<List<({String front, String back, String? hint})>> flashcards(String chapterId, {int count = 12}) async {
    final r = (await _api.post('/flashcards/$studentId/generate', body: {'chapterId': chapterId, 'count': count}, parse: _map)).data;
    return [
      for (final c in r['cards'] as List? ?? const []) (front: (c as Map)['front'] as String? ?? '', back: c['back'] as String? ?? '', hint: c['hint'] as String?),
    ];
  }

  Future<({String title, String html})> note({required String kind, String? chapterId, String? topicId, String? questionText, String? answerText, String? conversation}) async {
    final r = (await _api.post('/notes/$studentId/generate', body: {
      'kind': kind,
      'chapterId': ?chapterId,
      'topicId': ?topicId,
      'questionText': ?questionText,
      'answerText': ?answerText,
      'conversation': ?conversation,
    }, parse: _map)).data;
    return (title: r['title'] as String? ?? '', html: r['html'] as String? ?? '');
  }

  Future<Map<String, dynamic>> writing(String text, {required String kind, String prompt = '', int minWords = 0, int maxWords = 1000}) async =>
      (await _api.post('/english/$studentId/writing', body: {'text': text, 'kind': kind, 'prompt': prompt, 'minWords': minWords, 'maxWords': maxWords}, parse: _map)).data;
}

/// The signed-in student's AI tools on the server (API mode); null with the mock or other roles.
final remoteAiToolsProvider = Provider<RemoteAiTools?>((ref) {
  final progress = ref.watch(remoteProgressProvider);
  return progress == null ? null : RemoteAiTools(ref.watch(apiClientProvider), progress.studentId);
});
