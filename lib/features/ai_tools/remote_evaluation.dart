import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/l10n/tr.dart';
import '../../core/network/network_providers.dart';
import '../progress/data/remote_progress.dart';
import '../question_bank/domain/question.dart';

/// Sends a handwritten answer script to the teacher queue on the server: an evaluation record
/// at the `teacher_review_requested` stage (the server notifies the teachers).
class RemoteEvaluation {
  RemoteEvaluation(this._ref, this.studentId);

  final Ref _ref;
  final String studentId;

  static Map<String, dynamic> recordFor({
    required String id,
    required String studentId,
    required String studentName,
    required Question question,
    required String title,
    required int pages,
    required double aiMarks,
    required int maxMarks,
    required List<(Tr, double, int)> criteria,
    required List<Tr> missing,
    required List<Tr> tips,
    required String ocrText,
  }) {
    final now = DateTime.now().toUtc().toIso8601String();
    return {
      'id': id,
      'studentId': studentId,
      'studentName': studentName,
      'title': title,
      'subjectId': question.subjectId,
      'questionId': question.id,
      'questionText': question.stem.bn,
      'modelAnswer': question.answer.bn,
      // Photos stay on the phone; the teacher sees page placeholders and the extracted text.
      'pages': [for (var i = 0; i < pages; i++) {'id': '$id-p$i', 'name': 'page-${i + 1}.jpg', 'preview': '', 'rotation': 0}],
      'ocrText': ocrText,
      'stage': 'teacher_review_requested',
      'rubric': [for (final (name, ai, max) in criteria) {'criterion': name.bn, 'max': max, 'ai': ai}],
      'maxMarks': maxMarks,
      'aiMarks': aiMarks,
      'missingPoints': [for (final m in missing) m.bn],
      'suggestions': [for (final t in tips) t.bn],
      'createdAt': now,
      'updatedAt': now,
    };
  }

  Future<void> send(Map<String, dynamic> record) => _ref.read(apiClientProvider).post('/evaluations/$studentId', body: record, parse: (d) => d);
}

/// Null with the mock or for non-students.
final remoteEvaluationProvider = Provider<RemoteEvaluation?>((ref) {
  final progress = ref.watch(remoteProgressProvider);
  return progress == null ? null : RemoteEvaluation(ref, progress.studentId);
});
