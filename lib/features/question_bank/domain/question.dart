import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/l10n/tr.dart';
import '../../curriculum/domain/curriculum_models.dart';

/// Every question type from the spec (§13). Objective types are auto-scored.
enum QuestionType {
  mcq(Tr('বহুনির্বাচনি', 'MCQ'), Icons.radio_button_checked),
  trueFalse(Tr('সত্য/মিথ্যা', 'True/false'), Icons.rule),
  fillBlank(Tr('শূন্যস্থান', 'Fill in the blank'), Icons.short_text),
  matching(Tr('মিলকরণ', 'Matching'), Icons.compare_arrows),
  short(Tr('সংক্ষিপ্ত', 'Short answer'), Icons.notes),
  definition(Tr('সংজ্ঞা', 'Definition'), Icons.menu_book_outlined),
  descriptive(Tr('বর্ণনামূলক', 'Descriptive'), Icons.subject),
  creative(Tr('সৃজনশীল', 'Creative (CQ)'), Icons.lightbulb_outline),
  numerical(Tr('গাণিতিক সমস্যা', 'Numerical'), Icons.calculate_outlined),
  proof(Tr('প্রমাণ', 'Proof'), Icons.functions),
  formula(Tr('সূত্রভিত্তিক', 'Formula-based'), Icons.science_outlined),
  diagram(Tr('চিত্রভিত্তিক', 'Diagram'), Icons.schema_outlined),
  caseBased(Tr('কেস-ভিত্তিক', 'Case-based'), Icons.cases_outlined),
  passage(Tr('অনুচ্ছেদভিত্তিক', 'Passage-based'), Icons.article_outlined),
  practical(Tr('ব্যবহারিক', 'Practical'), Icons.biotech_outlined);

  const QuestionType(this.label, this.icon);

  final Tr label;
  final IconData icon;

  /// Auto-scored locally; the rest are self-marked against the model answer.
  bool get isObjective => this == mcq || this == trueFalse || this == fillBlank;
}

/// Where a question comes from. Synthetic content is always labelled as such.
enum QuestionSource {
  chapterBank(Tr('অধ্যায়ভিত্তিক ব্যাংক', 'Chapter bank')),
  board(Tr('বোর্ড পরীক্ষা', 'Board exam')),
  institution(Tr('স্কুল/কলেজ', 'School/college')),
  modelTest(Tr('মডেল টেস্ট', 'Model test')),
  aiGenerated(Tr('AI-তৈরি', 'AI-generated'));

  const QuestionSource(this.label);

  final Tr label;
}

/// Bloom-style level of a creative-question part.
enum CqLevel {
  knowledge(Tr('জ্ঞানমূলক', 'Knowledge')),
  comprehension(Tr('অনুধাবনমূলক', 'Comprehension')),
  application(Tr('প্রয়োগমূলক', 'Application')),
  higher(Tr('উচ্চতর দক্ষতা', 'Higher-order'));

  const CqLevel(this.label);

  final Tr label;
}

/// One part (ক/খ/গ/ঘ) of a creative question.
@immutable
class CqPart {
  const CqPart({required this.label, required this.level, required this.marks, required this.prompt, required this.answer});

  factory CqPart.fromJson(Map<String, dynamic> j) => CqPart(
    label: j['label'] as String,
    level: CqLevel.values.byName(j['level'] as String),
    marks: j['marks'] as int,
    prompt: Tr.fromJson(j['prompt']),
    answer: Tr.fromJson(j['answer']),
  );

  final String label;
  final CqLevel level;
  final int marks;
  final Tr prompt;
  final Tr answer;

  Map<String, dynamic> toJson() => {
    'label': label,
    'level': level.name,
    'marks': marks,
    'prompt': prompt.toJson(),
    'answer': answer.toJson(),
  };
}

/// A textbook location backing an answer. Fixtures are synthetic sample books.
@immutable
class Citation {
  const Citation({required this.bookId, required this.page, this.excerpt});

  factory Citation.fromJson(Map<String, dynamic> j) =>
      Citation(bookId: j['bookId'] as String, page: j['page'] as int, excerpt: j['excerpt'] == null ? null : Tr.fromJson(j['excerpt']));

  final String bookId;
  final int page;
  final Tr? excerpt;

  Map<String, dynamic> toJson() => {'bookId': bookId, 'page': page, 'excerpt': excerpt?.toJson()};
}

@immutable
class Question {
  const Question({
    required this.id,
    required this.subjectId,
    required this.chapterId,
    required this.topicId,
    required this.type,
    required this.difficulty,
    required this.marks,
    required this.stem,
    required this.answer,
    this.explanation,
    this.options = const [],
    this.correctIndex,
    this.acceptedAnswers = const [],
    this.steps = const [],
    this.stimulus,
    this.parts = const [],
    this.pairs = const [],
    this.altMethod,
    this.rubric = const [],
    this.source = QuestionSource.chapterBank,
    this.boardId,
    this.year,
    this.verified = true,
    this.synthetic = true,
    this.relevance = ExamRelevance.medium,
    this.frequency = 0,
    this.citation,
    this.createdAt,
  });

  factory Question.fromJson(Map<String, dynamic> j) => Question(
    id: j['id'] as String,
    subjectId: j['subjectId'] as String,
    chapterId: j['chapterId'] as String,
    topicId: j['topicId'] as String,
    type: QuestionType.values.byName(j['type'] as String),
    difficulty: Difficulty.values.byName(j['difficulty'] as String),
    marks: j['marks'] as int,
    stem: Tr.fromJson(j['stem']),
    answer: Tr.fromJson(j['answer']),
    explanation: j['explanation'] == null ? null : Tr.fromJson(j['explanation']),
    options: [for (final o in j['options'] as List? ?? const []) Tr.fromJson(o)],
    correctIndex: j['correctIndex'] as int?,
    acceptedAnswers: List<String>.from(j['acceptedAnswers'] as List? ?? const []),
    steps: [for (final s in j['steps'] as List? ?? const []) Tr.fromJson(s)],
    stimulus: j['stimulus'] == null ? null : Tr.fromJson(j['stimulus']),
    parts: [for (final p in j['parts'] as List? ?? const []) CqPart.fromJson(p as Map<String, dynamic>)],
    pairs: [
      for (final p in j['pairs'] as List? ?? const [])
        (Tr.fromJson((p as Map<String, dynamic>)['left']), Tr.fromJson(p['right'])),
    ],
    altMethod: j['altMethod'] == null ? null : Tr.fromJson(j['altMethod']),
    rubric: [for (final r in j['rubric'] as List? ?? const []) Tr.fromJson(r)],
    source: QuestionSource.values.byName(j['source'] as String? ?? 'chapterBank'),
    boardId: j['boardId'] as String?,
    year: j['year'] as int?,
    verified: j['verified'] as bool? ?? true,
    synthetic: j['synthetic'] as bool? ?? true,
    relevance: ExamRelevance.values.byName(j['relevance'] as String? ?? 'medium'),
    frequency: j['frequency'] as int? ?? 0,
    citation: j['citation'] == null ? null : Citation.fromJson(j['citation'] as Map<String, dynamic>),
    createdAt: j['createdAt'] == null ? null : DateTime.parse(j['createdAt'] as String),
  );

  final String id;
  final String subjectId;
  final String chapterId;
  final String topicId;
  final QuestionType type;
  final Difficulty difficulty;
  final int marks;
  final Tr stem;

  /// Model answer (rich content: markdown + math). Never empty.
  final Tr answer;
  final Tr? explanation;

  /// MCQ / true-false options and the correct one.
  final List<Tr> options;
  final int? correctIndex;

  /// Fill-in-the-blank: accepted answers (case/space-insensitive).
  final List<String> acceptedAnswers;

  /// Step-by-step solution.
  final List<Tr> steps;

  /// Creative question stimulus (উদ্দীপক) or passage text.
  final Tr? stimulus;
  final List<CqPart> parts;

  /// Matching pairs (left → right).
  final List<(Tr, Tr)> pairs;

  /// A second valid solution method.
  final Tr? altMethod;

  /// Marking points for descriptive answers.
  final List<Tr> rubric;

  final QuestionSource source;
  final String? boardId;
  final int? year;
  final bool verified;

  /// True for every fixture: content written for the demo, not taken from real papers.
  final bool synthetic;
  final ExamRelevance relevance;

  /// How often this concept appeared in past papers (synthetic sample statistic).
  final int frequency;
  final Citation? citation;
  final DateTime? createdAt;

  bool isCorrectChoice(int index) => correctIndex == index;

  bool isAcceptedText(String input) {
    String norm(String s) => s.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
    final n = norm(input);
    return n.isNotEmpty && acceptedAnswers.any((a) => norm(a) == n);
  }

  /// Plain text for search and copying.
  String searchText(AppLanguage lang) =>
      [stem.of(lang), stimulus?.of(lang) ?? '', for (final o in options) o.of(lang), for (final p in parts) p.prompt.of(lang)].join(' ');

  Map<String, dynamic> toJson() => {
    'id': id,
    'subjectId': subjectId,
    'chapterId': chapterId,
    'topicId': topicId,
    'type': type.name,
    'difficulty': difficulty.name,
    'marks': marks,
    'stem': stem.toJson(),
    'answer': answer.toJson(),
    'explanation': explanation?.toJson(),
    'options': [for (final o in options) o.toJson()],
    'correctIndex': correctIndex,
    'acceptedAnswers': acceptedAnswers,
    'steps': [for (final s in steps) s.toJson()],
    'stimulus': stimulus?.toJson(),
    'parts': [for (final p in parts) p.toJson()],
    'pairs': [for (final p in pairs) {'left': p.$1.toJson(), 'right': p.$2.toJson()}],
    'altMethod': altMethod?.toJson(),
    'rubric': [for (final r in rubric) r.toJson()],
    'source': source.name,
    'boardId': boardId,
    'year': year,
    'verified': verified,
    'synthetic': synthetic,
    'relevance': relevance.name,
    'frequency': frequency,
    'citation': citation?.toJson(),
    'createdAt': createdAt?.toIso8601String(),
  };
}

/// Filters for browsing the bank. Null = no constraint.
@immutable
class QuestionFilter {
  const QuestionFilter({
    this.subjectId,
    this.chapterId,
    this.topicId,
    this.types = const {},
    this.difficulty,
    this.source,
    this.year,
    this.boardId,
    this.marks,
    this.verifiedOnly = false,
    this.highRelevanceOnly = false,
    this.query = '',
    this.sort = QuestionSort.recent,
  });

  final String? subjectId;
  final String? chapterId;
  final String? topicId;
  final Set<QuestionType> types;
  final Difficulty? difficulty;
  final QuestionSource? source;
  final int? year;
  final String? boardId;
  final int? marks;
  final bool verifiedOnly;
  final bool highRelevanceOnly;
  final String query;
  final QuestionSort sort;

  int get activeCount => [
    types.isNotEmpty,
    difficulty != null,
    source != null,
    year != null,
    boardId != null,
    marks != null,
    verifiedOnly,
    highRelevanceOnly,
  ].where((b) => b).length;

  QuestionFilter copyWith({
    String? Function()? subjectId,
    String? Function()? chapterId,
    String? Function()? topicId,
    Set<QuestionType>? types,
    Difficulty? Function()? difficulty,
    QuestionSource? Function()? source,
    int? Function()? year,
    String? Function()? boardId,
    int? Function()? marks,
    bool? verifiedOnly,
    bool? highRelevanceOnly,
    String? query,
    QuestionSort? sort,
  }) => QuestionFilter(
    subjectId: subjectId == null ? this.subjectId : subjectId(),
    chapterId: chapterId == null ? this.chapterId : chapterId(),
    topicId: topicId == null ? this.topicId : topicId(),
    types: types ?? this.types,
    difficulty: difficulty == null ? this.difficulty : difficulty(),
    source: source == null ? this.source : source(),
    year: year == null ? this.year : year(),
    boardId: boardId == null ? this.boardId : boardId(),
    marks: marks == null ? this.marks : marks(),
    verifiedOnly: verifiedOnly ?? this.verifiedOnly,
    highRelevanceOnly: highRelevanceOnly ?? this.highRelevanceOnly,
    query: query ?? this.query,
    sort: sort ?? this.sort,
  );

  /// Clears the advanced filters but keeps the curriculum scope and search.
  QuestionFilter cleared() => QuestionFilter(subjectId: subjectId, chapterId: chapterId, topicId: topicId, query: query, sort: sort);

  bool matches(Question q) =>
      (subjectId == null || q.subjectId == subjectId) &&
      (chapterId == null || q.chapterId == chapterId) &&
      (topicId == null || q.topicId == topicId) &&
      (types.isEmpty || types.contains(q.type)) &&
      (difficulty == null || q.difficulty == difficulty) &&
      (source == null || q.source == source) &&
      (year == null || q.year == year) &&
      (boardId == null || q.boardId == boardId) &&
      (marks == null || q.marks == marks) &&
      (!verifiedOnly || q.verified) &&
      (!highRelevanceOnly || q.relevance == ExamRelevance.high) &&
      (query.isEmpty || Tr.same(q.searchText(AppLanguage.bn) + q.searchText(AppLanguage.en)).matches(query));

  @override
  bool operator ==(Object other) =>
      other is QuestionFilter &&
      other.subjectId == subjectId &&
      other.chapterId == chapterId &&
      other.topicId == topicId &&
      setEquals(other.types, types) &&
      other.difficulty == difficulty &&
      other.source == source &&
      other.year == year &&
      other.boardId == boardId &&
      other.marks == marks &&
      other.verifiedOnly == verifiedOnly &&
      other.highRelevanceOnly == highRelevanceOnly &&
      other.query == query &&
      other.sort == sort;

  @override
  int get hashCode => Object.hash(subjectId, chapterId, topicId, Object.hashAllUnordered(types), difficulty, source, year,
      boardId, marks, verifiedOnly, highRelevanceOnly, query, sort);
}

enum QuestionSort {
  recent(Tr('সাম্প্রতিক', 'Most recent')),
  difficulty(Tr('কাঠিন্য', 'Difficulty')),
  frequency(Tr('বেশি এসেছে', 'Most frequent'));

  const QuestionSort(this.label);

  final Tr label;
}

/// One page of results.
@immutable
class QuestionPage {
  const QuestionPage({required this.items, required this.total, required this.page, required this.pageSize});

  final List<Question> items;
  final int total;
  final int page;
  final int pageSize;

  bool get hasMore => (page + 1) * pageSize < total;
}
