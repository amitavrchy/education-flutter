import 'dart:math';

import '../../question_bank/domain/question.dart';
import '../domain/exam.dart';

/// Picks the questions for an attempt. Deterministic for a given [seed].
List<Question> selectExamQuestions(ExamConfig config, List<Question> all, {int seed = 0, double Function(String topicId)? masteryOf}) {
  final pool = all.where(config.accepts).toList();
  if (masteryOf != null) {
    // Adaptive: weakest topics first, shuffled within similar mastery.
    pool
      ..shuffle(Random(seed))
      ..sort((a, b) => masteryOf(a.topicId).compareTo(masteryOf(b.topicId)));
  } else if (config.randomize) {
    pool.shuffle(Random(seed));
  }
  return pool.take(config.questionCount).toList();
}

/// Simulated AI estimate for a written answer: overlap between the student's words and the
/// model answer's key terms. Deterministic and clearly labelled as non-authoritative in the UI.
double estimateWrittenMarks(Question q, ExamAnswer a) {
  if (!a.isAnswered) return 0;
  final text = (a.text ?? '').toLowerCase();
  if (text.trim().isEmpty && a.imagePaths.isNotEmpty) {
    // Handwritten upload only: OCR is simulated, so award a cautious half-credit estimate.
    return (q.marks * 0.5 * 2).round() / 2;
  }
  final words = RegExp(r'[\p{L}\p{N}]{3,}', unicode: true);
  final model = [q.answer.bn, q.answer.en, for (final p in q.parts) ...[p.answer.bn, p.answer.en]].join(' ').toLowerCase();
  final keys = {for (final m in words.allMatches(model)) m[0]!}..removeAll(const {'the', 'and', 'for', 'with', 'this', 'that', 'from', 'are', 'হয়', 'এবং', 'থেকে'});
  if (keys.isEmpty) return q.marks * 0.5;
  final student = {for (final m in words.allMatches(text)) m[0]!};
  final hit = keys.intersection(student).length;
  final ratio = (hit / min(keys.length, 10)).clamp(0.0, 1.0);
  // Round to half marks.
  return (q.marks * ratio * 2).round() / 2;
}

/// Scores an attempt locally. Objective types are exact; written types are simulated estimates.
ExamResult scoreAttempt(ExamAttempt attempt, Map<String, Question> questions, {required int timeSpentSeconds, String? teacherFeedbackBn, String? teacherFeedbackEn}) {
  final scores = <QuestionScore>[];
  for (final id in attempt.questionIds) {
    final q = questions[id];
    if (q == null) continue;
    final a = attempt.answerFor(id);
    final penalty = attempt.config.negativeMarking ? -ExamConfig.negativeFraction * q.marks : 0.0;
    switch (q.type) {
      case QuestionType.mcq || QuestionType.trueFalse:
        if (a.choice == null) {
          scores.add(QuestionScore(questionId: id, outcome: Outcome.unanswered, marks: 0, maxMarks: q.marks));
        } else if (q.isCorrectChoice(a.choice!)) {
          scores.add(QuestionScore(questionId: id, outcome: Outcome.correct, marks: q.marks.toDouble(), maxMarks: q.marks));
        } else {
          scores.add(QuestionScore(questionId: id, outcome: Outcome.incorrect, marks: penalty, maxMarks: q.marks));
        }
      case QuestionType.fillBlank:
        if (!a.isAnswered) {
          scores.add(QuestionScore(questionId: id, outcome: Outcome.unanswered, marks: 0, maxMarks: q.marks));
        } else if (q.isAcceptedText(a.text ?? '')) {
          scores.add(QuestionScore(questionId: id, outcome: Outcome.correct, marks: q.marks.toDouble(), maxMarks: q.marks));
        } else {
          scores.add(QuestionScore(questionId: id, outcome: Outcome.incorrect, marks: penalty, maxMarks: q.marks));
        }
      default:
        scores.add(a.isAnswered
            ? QuestionScore(questionId: id, outcome: Outcome.estimated, marks: estimateWrittenMarks(q, a), maxMarks: q.marks)
            : QuestionScore(questionId: id, outcome: Outcome.unanswered, marks: 0, maxMarks: q.marks));
    }
  }
  return ExamResult(scores: scores, timeSpentSeconds: timeSpentSeconds);
}

/// Correct/total per key (topic, chapter or difficulty), for the analysis charts.
Map<K, ({double earned, int max, int count})> breakdown<K>(ExamResult r, Map<String, Question> questions, K Function(Question q) keyOf) {
  final out = <K, ({double earned, int max, int count})>{};
  for (final s in r.scores) {
    final q = questions[s.questionId];
    if (q == null) continue;
    final k = keyOf(q);
    final prev = out[k] ?? (earned: 0.0, max: 0, count: 0);
    out[k] = (earned: prev.earned + max(0, s.marks), max: prev.max + s.maxMarks, count: prev.count + 1);
  }
  return out;
}

/// Topics scoring under 50% in this attempt, weakest first.
List<String> weakTopics(ExamResult r, Map<String, Question> questions) {
  final byTopic = breakdown(r, questions, (q) => q.topicId);
  final weak = byTopic.entries.where((e) => e.value.max > 0 && e.value.earned / e.value.max < 0.5).toList()
    ..sort((a, b) => (a.value.earned / a.value.max).compareTo(b.value.earned / b.value.max));
  return [for (final e in weak) e.key];
}
