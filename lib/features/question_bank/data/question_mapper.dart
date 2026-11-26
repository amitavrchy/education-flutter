import '../../../core/l10n/tr.dart';
import '../../curriculum/domain/curriculum_models.dart';
import '../domain/question.dart';

/// Maps a backend question record (the web app's shape) onto the app's [Question].
///
/// Backend text is single-language (Bangla, or English for English subjects), so every field
/// becomes `Tr.same`. Board ids drop the `brd-` prefix to match the app's board list.
QuestionType questionTypeFromApi(Object? type) => switch (type) {
  'true_false' => QuestionType.trueFalse,
  'fill_blank' => QuestionType.fillBlank,
  'case_based' => QuestionType.caseBased,
  final String t => QuestionType.values.where((v) => v.name == t).firstOrNull ?? QuestionType.short,
  _ => QuestionType.short,
};

String questionTypeToApi(QuestionType t) => switch (t) {
  QuestionType.trueFalse => 'true_false',
  QuestionType.fillBlank => 'fill_blank',
  QuestionType.caseBased => 'case_based',
  _ => t.name,
};

Question questionFromApi(Map<String, dynamic> j) {
  final type = questionTypeFromApi(j['type']);
  Tr t(Object? v) => Tr.same(v?.toString() ?? '');
  final rawOptions = [for (final o in j['options'] as List? ?? const []) (o as Map).cast<String, dynamic>()];
  var options = [for (final o in rawOptions) t(o['text'])];
  int? correct = rawOptions.indexWhere((o) => o['id'] == j['correctOptionId']);
  if (correct < 0) correct = null;
  if (type == QuestionType.trueFalse) {
    options = const [Tr('সত্য', 'True'), Tr('মিথ্যা', 'False')];
    correct = j['correctBoolean'] == false ? 1 : 0;
  }
  final numeric = j['numericAnswer'] as Map?;
  final source = (j['source'] as Map?)?.cast<String, dynamic>() ?? const {};
  final boardId = (source['boardId'] as String?)?.replaceFirst('brd-', '');
  final diagram = (j['diagram'] as Map?)?['alt'] as String?;
  final passage = j['passage'] as String?;
  final methods = [for (final m in j['methods'] as List? ?? const []) (m as Map).cast<String, dynamic>()];
  return Question(
    id: j['id'] as String,
    subjectId: j['subjectId'] as String,
    chapterId: j['chapterId'] as String,
    topicId: (j['topicId'] as String?) ?? (j['chapterId'] as String),
    type: type,
    difficulty: Difficulty.values.where((d) => d.name == j['difficulty']).firstOrNull ?? Difficulty.medium,
    marks: (j['marks'] as num?)?.round() ?? 1,
    stem: t(j['stem']),
    answer: t(j['answer']),
    explanation: j['explanation'] == null ? null : t(j['explanation']),
    options: options,
    correctIndex: correct,
    acceptedAnswers: [
      for (final b in j['blanks'] as List? ?? const [])
        for (final a in b is List ? b : [b]) a.toString(),
      if (numeric?['value'] != null) '${numeric!['value']}',
    ],
    steps: [for (final s in j['steps'] as List? ?? const []) t(s)],
    stimulus: passage != null ? t(passage) : (diagram != null ? Tr('চিত্র: $diagram', 'Diagram: $diagram') : null),
    parts: [
      for (final p in j['cqParts'] as List? ?? const [])
        CqPart(
          label: (p as Map)['label'] as String,
          level: CqLevel.values.where((l) => l.name == p['level']).firstOrNull ?? CqLevel.knowledge,
          marks: (p['marks'] as num?)?.round() ?? 1,
          prompt: t(p['prompt']),
          answer: t(p['answer']),
        ),
    ],
    pairs: [for (final p in j['matchingPairs'] as List? ?? const []) (t((p as Map)['left']), t(p['right']))],
    altMethod: methods.isEmpty ? null : Tr.same('${methods.first['title']}: ${(methods.first['steps'] as List? ?? const []).join(' → ')}'),
    rubric: [for (final r in j['rubric'] as List? ?? const []) Tr.same(r is Map ? '${r['criterion']} (${r['marks']})' : '$r')],
    source: boardId != null ? QuestionSource.board : QuestionSource.chapterBank,
    boardId: boardId,
    year: (source['year'] as num?)?.toInt(),
    verified: j['verification'] == 'verified',
    synthetic: source['kind'] == 'synthetic' || (j['provenance'] as String? ?? '').contains('synthetic'),
    relevance: ExamRelevance.values.where((r) => r.name == j['examRelevance']).firstOrNull ?? ExamRelevance.medium,
    frequency: (j['frequency'] as num?)?.toInt() ?? 0,
    createdAt: j['createdAt'] == null ? null : DateTime.tryParse(j['createdAt'] as String),
  );
}

/// The app's question in the backend's shape (teacher authoring). Text fields are Bangla.
Map<String, dynamic> questionToApi(Question q) {
  const letters = 'abcdefghij';
  return {
    'id': q.id,
    'type': questionTypeToApi(q.type),
    'stem': q.stem.bn,
    'answer': q.answer.bn,
    'explanation': q.explanation?.bn ?? '',
    'subjectId': q.subjectId,
    'chapterId': q.chapterId,
    'topicId': q.topicId,
    'difficulty': q.difficulty.name,
    'marks': q.marks,
    'levelCode': q.subjectId.startsWith('hsc') ? 'HSC' : 'SSC',
    'language': 'bn',
    if (q.options.isNotEmpty && q.type != QuestionType.trueFalse) ...{
      'options': [
        for (final (i, o) in q.options.indexed) {'id': letters[i], 'text': o.bn},
      ],
      'correctOptionId': ?(q.correctIndex == null ? null : letters[q.correctIndex!]),
    },
    if (q.type == QuestionType.trueFalse) 'correctBoolean': q.correctIndex == 0,
    if (q.acceptedAnswers.isNotEmpty) 'blanks': [q.acceptedAnswers],
  };
}
