import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/l10n/tr.dart';
import '../../core/mock/mock_simulator.dart';
import '../../core/network/api_exception.dart';
import '../../core/storage/local_store.dart';
import '../notifications/application/notifications_controller.dart';
import '../notifications/domain/app_notification.dart';
import '../question_bank/domain/question.dart';

/// Editorial workflow (web §28, TCH-03..11, TCH-19, TCH-22/23):
/// draft → submitted → in review → changes requested → approved → published → archived.
/// Reviewers decide, authors submit; publishing and archiving belong to content managers
/// (admin web), so on mobile those steps are shown but locked.

enum ContentStatus {
  draft(Tr('খসড়া', 'Draft'), Icons.edit_note),
  submitted(Tr('জমা', 'Submitted'), Icons.outbox_outlined),
  inReview(Tr('পর্যালোচনায়', 'In review'), Icons.manage_search),
  changesRequested(Tr('পরিবর্তন প্রয়োজন', 'Changes requested'), Icons.change_circle_outlined),
  approved(Tr('অনুমোদিত', 'Approved'), Icons.verified_outlined),
  published(Tr('প্রকাশিত', 'Published'), Icons.public),
  archived(Tr('আর্কাইভ', 'Archived'), Icons.archive_outlined);

  const ContentStatus(this.label, this.icon);

  final Tr label;
  final IconData icon;
}

const Map<ContentStatus, List<ContentStatus>> contentTransitions = {
  ContentStatus.draft: [ContentStatus.submitted, ContentStatus.archived],
  ContentStatus.submitted: [ContentStatus.inReview, ContentStatus.draft],
  ContentStatus.inReview: [ContentStatus.changesRequested, ContentStatus.approved],
  ContentStatus.changesRequested: [ContentStatus.submitted, ContentStatus.archived],
  ContentStatus.approved: [ContentStatus.published, ContentStatus.changesRequested],
  ContentStatus.published: [ContentStatus.archived],
  ContentStatus.archived: [ContentStatus.draft],
};

enum ActorRole {
  teacher(Tr('শিক্ষক', 'Teacher')),
  reviewer(Tr('কনটেন্ট পর্যালোচক', 'Content reviewer')),
  manager(Tr('কনটেন্ট ম্যানেজার', 'Content manager'));

  const ActorRole(this.label);

  final Tr label;
}

class Actor {
  const Actor(this.name, this.role);

  factory Actor.fromJson(Map<String, dynamic> j) => Actor(j['name'] as String, ActorRole.values.byName(j['role'] as String));

  final String name;
  final ActorRole role;

  Map<String, dynamic> toJson() => {'name': name, 'role': role.name};
}

const teacherActor = Actor('নাসরিন সুলতানা', ActorRole.teacher);
const reviewerActor = Actor('ড. মাহমুদ হাসান', ActorRole.reviewer);
const managerActor = Actor('তানজিলা রহমান', ActorRole.manager);

/// Steps [role] may take from [from] (web `allowedTransitions`).
List<ContentStatus> allowedTransitions(ContentStatus from, ActorRole role) {
  final reviewer = role == ActorRole.reviewer || role == ActorRole.manager;
  return [
    for (final to in contentTransitions[from]!)
      if (to == ContentStatus.published || to == ContentStatus.archived)
        if (role == ActorRole.manager) to else ...[]
      else if (to == ContentStatus.inReview || to == ContentStatus.approved || to == ContentStatus.changesRequested)
        if (reviewer) to else ...[]
      else
        to,
  ];
}

enum ReviewKind {
  question(Tr('প্রশ্ন', 'Question'), Icons.quiz_outlined),
  aiAnswer(Tr('AI উত্তর', 'AI answer'), Icons.auto_awesome_outlined),
  chapter(Tr('অধ্যায়', 'Chapter'), Icons.menu_book_outlined),
  boardPaper(Tr('বোর্ড পত্র', 'Board paper'), Icons.history_edu_outlined),
  institutionPaper(Tr('প্রতিষ্ঠানের পত্র', 'Institution paper'), Icons.account_balance_outlined),
  rubric(Tr('রুব্রিক', 'Rubric'), Icons.rule),
  book(Tr('বই', 'Book'), Icons.local_library_outlined),
  note(Tr('নোট', 'Note'), Icons.sticky_note_2_outlined);

  const ReviewKind(this.label, this.icon);

  final Tr label;
  final IconData icon;
}

enum ReviewPriority {
  low(Tr('নিম্ন', 'Low')),
  normal(Tr('সাধারণ', 'Normal')),
  high(Tr('উচ্চ', 'High')),
  urgent(Tr('জরুরি', 'Urgent'));

  const ReviewPriority(this.label);

  final Tr label;
}

class ReviewComment {
  const ReviewComment(this.author, this.text, this.at);

  factory ReviewComment.fromJson(Map<String, dynamic> j) => ReviewComment(Actor.fromJson((j['author'] as Map).cast()), j['text'] as String, DateTime.parse(j['at'] as String));

  final Actor author;
  final String text;
  final DateTime at;

  Map<String, dynamic> toJson() => {'author': author.toJson(), 'text': text, 'at': at.toIso8601String()};
}

enum SuggestionState { open, accepted, rejected }

class Suggestion {
  const Suggestion({required this.id, required this.from, required this.to, required this.by, required this.at, this.state = SuggestionState.open});

  factory Suggestion.fromJson(Map<String, dynamic> j) => Suggestion(
    id: j['id'] as String,
    from: j['from'] as String,
    to: j['to'] as String,
    by: Actor.fromJson((j['by'] as Map).cast()),
    at: DateTime.parse(j['at'] as String),
    state: SuggestionState.values.byName(j['state'] as String),
  );

  final String id;
  final String from;
  final String to;
  final Actor by;
  final DateTime at;
  final SuggestionState state;

  Suggestion withState(SuggestionState s) => Suggestion(id: id, from: from, to: to, by: by, at: at, state: s);

  Map<String, dynamic> toJson() => {'id': id, 'from': from, 'to': to, 'by': by.toJson(), 'at': at.toIso8601String(), 'state': state.name};
}

class ReviewEvent {
  const ReviewEvent(this.at, this.from, this.to, this.by, {this.note});

  factory ReviewEvent.fromJson(Map<String, dynamic> j) => ReviewEvent(
    DateTime.parse(j['at'] as String),
    j['from'] == null ? null : ContentStatus.values.byName(j['from'] as String),
    ContentStatus.values.byName(j['to'] as String),
    Actor.fromJson((j['by'] as Map).cast()),
    note: j['note'] as String?,
  );

  final DateTime at;
  final ContentStatus? from;
  final ContentStatus to;
  final Actor by;
  final String? note;

  Map<String, dynamic> toJson() => {'at': at.toIso8601String(), 'from': from?.name, 'to': to.name, 'by': by.toJson(), 'note': note};
}

class ReviewItem {
  const ReviewItem({
    required this.id,
    required this.kind,
    required this.title,
    required this.subjectId,
    required this.status,
    required this.priority,
    required this.submittedBy,
    required this.preview,
    required this.history,
    this.contentId,
    this.assignedTo,
    this.dueAt,
    this.comments = const [],
    this.suggestions = const [],
  });

  factory ReviewItem.fromJson(Map<String, dynamic> j) => ReviewItem(
    id: j['id'] as String,
    kind: ReviewKind.values.byName(j['kind'] as String),
    title: j['title'] as String,
    subjectId: j['subjectId'] as String,
    status: ContentStatus.values.byName(j['status'] as String),
    priority: ReviewPriority.values.byName(j['priority'] as String),
    submittedBy: Actor.fromJson((j['submittedBy'] as Map).cast()),
    preview: j['preview'] as String,
    history: [for (final e in j['history'] as List) ReviewEvent.fromJson((e as Map).cast())],
    contentId: j['contentId'] as String?,
    assignedTo: j['assignedTo'] == null ? null : Actor.fromJson((j['assignedTo'] as Map).cast()),
    dueAt: j['dueAt'] == null ? null : DateTime.parse(j['dueAt'] as String),
    comments: [for (final c in j['comments'] as List? ?? const []) ReviewComment.fromJson((c as Map).cast())],
    suggestions: [for (final s in j['suggestions'] as List? ?? const []) Suggestion.fromJson((s as Map).cast())],
  );

  final String id;
  final ReviewKind kind;
  final String title;
  final String subjectId;
  final ContentStatus status;
  final ReviewPriority priority;
  final Actor submittedBy;
  final String preview;
  final List<ReviewEvent> history;

  /// Authored question id for `question` items created on this device.
  final String? contentId;
  final Actor? assignedTo;
  final DateTime? dueAt;
  final List<ReviewComment> comments;
  final List<Suggestion> suggestions;

  DateTime get updatedAt => history.last.at;

  ReviewItem copyWith({
    ContentStatus? status,
    String? preview,
    String? title,
    List<ReviewEvent>? history,
    Actor? assignedTo,
    List<ReviewComment>? comments,
    List<Suggestion>? suggestions,
  }) => ReviewItem(
    id: id,
    kind: kind,
    title: title ?? this.title,
    subjectId: subjectId,
    status: status ?? this.status,
    priority: priority,
    submittedBy: submittedBy,
    preview: preview ?? this.preview,
    history: history ?? this.history,
    contentId: contentId,
    assignedTo: assignedTo ?? this.assignedTo,
    dueAt: dueAt,
    comments: comments ?? this.comments,
    suggestions: suggestions ?? this.suggestions,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'kind': kind.name,
    'title': title,
    'subjectId': subjectId,
    'status': status.name,
    'priority': priority.name,
    'submittedBy': submittedBy.toJson(),
    'preview': preview,
    'history': [for (final e in history) e.toJson()],
    'contentId': contentId,
    'assignedTo': assignedTo?.toJson(),
    'dueAt': dueAt?.toIso8601String(),
    'comments': [for (final c in comments) c.toJson()],
    'suggestions': [for (final s in suggestions) s.toJson()],
  };
}

enum RubricUse {
  creative(Tr('সৃজনশীল', 'Creative')),
  descriptive(Tr('বর্ণনামূলক', 'Descriptive')),
  handwriting(Tr('হাতের লেখা', 'Handwriting')),
  essay(Tr('রচনা', 'Essay'));

  const RubricUse(this.label);

  final Tr label;
}

class RubricCriterion {
  const RubricCriterion(this.criterion, this.marks, this.description);

  factory RubricCriterion.fromJson(Map<String, dynamic> j) => RubricCriterion(j['criterion'] as String, (j['marks'] as num).toDouble(), j['description'] as String? ?? '');

  final String criterion;
  final double marks;
  final String description;

  Map<String, dynamic> toJson() => {'criterion': criterion, 'marks': marks, 'description': description};
}

class Rubric {
  const Rubric({required this.id, required this.name, required this.use, required this.criteria, required this.status, required this.owner, this.subjectId});

  factory Rubric.fromJson(Map<String, dynamic> j) => Rubric(
    id: j['id'] as String,
    name: j['name'] as String,
    use: RubricUse.values.byName(j['use'] as String),
    criteria: [for (final c in j['criteria'] as List) RubricCriterion.fromJson((c as Map).cast())],
    status: ContentStatus.values.byName(j['status'] as String),
    owner: j['owner'] as String,
    subjectId: j['subjectId'] as String?,
  );

  final String id;
  final String name;
  final RubricUse use;
  final List<RubricCriterion> criteria;
  final ContentStatus status;
  final String owner;
  final String? subjectId;

  double get total => criteria.fold(0, (s, c) => s + c.marks);

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'use': use.name,
    'criteria': [for (final c in criteria) c.toJson()],
    'status': status.name,
    'owner': owner,
    'subjectId': subjectId,
  };
}

/// A question the teacher wrote, with its editorial status and version log.
class AuthoredQuestion {
  const AuthoredQuestion({required this.question, required this.status, required this.version, required this.versions});

  factory AuthoredQuestion.fromJson(Map<String, dynamic> j) => AuthoredQuestion(
    question: Question.fromJson((j['question'] as Map).cast()),
    status: ContentStatus.values.byName(j['status'] as String),
    version: j['version'] as int,
    versions: [for (final v in j['versions'] as List? ?? const []) (DateTime.parse((v as Map)['at'] as String), v['summary'] as String)],
  );

  final Question question;
  final ContentStatus status;
  final int version;
  final List<(DateTime at, String summary)> versions;

  Map<String, dynamic> toJson() => {
    'question': question.toJson(),
    'status': status.name,
    'version': version,
    'versions': [for (final (at, s) in versions) {'at': at.toIso8601String(), 'summary': s}],
  };
}

class ReviewState {
  const ReviewState({required this.items, required this.rubrics, required this.questions, this.actingAs = ActorRole.teacher});

  final List<ReviewItem> items;
  final List<Rubric> rubrics;
  final List<AuthoredQuestion> questions;

  /// Simulated permission switch (TCH-23): the same person acting as teacher or reviewer.
  final ActorRole actingAs;

  Actor get actor => actingAs == ActorRole.reviewer ? reviewerActor : teacherActor;

  /// Items waiting for a reviewer decision.
  List<ReviewItem> get queue => [for (final i in items) if (i.status == ContentStatus.submitted || i.status == ContentStatus.inReview) i];

  ReviewItem? item(String id) => items.where((i) => i.id == id).firstOrNull;

  ReviewState copyWith({List<ReviewItem>? items, List<Rubric>? rubrics, List<AuthoredQuestion>? questions, ActorRole? actingAs}) =>
      ReviewState(items: items ?? this.items, rubrics: rubrics ?? this.rubrics, questions: questions ?? this.questions, actingAs: actingAs ?? this.actingAs);
}

class ReviewController extends Notifier<ReviewState> {
  static const _col = 'teacherReview';
  late LocalStore _store;

  @override
  ReviewState build() {
    _store = watchStore(ref);
    final d = _store.get(_col, 'me');
    if (d != null) {
      return ReviewState(
        items: [for (final i in d['items'] as List) ReviewItem.fromJson((i as Map).cast())],
        rubrics: [for (final r in d['rubrics'] as List) Rubric.fromJson((r as Map).cast())],
        questions: [for (final q in d['questions'] as List) AuthoredQuestion.fromJson((q as Map).cast())],
        actingAs: ActorRole.values.byName(d['actingAs'] as String? ?? 'teacher'),
      );
    }
    return ReviewState(items: _seedItems(DateTime.now()), rubrics: _seedRubrics, questions: const []);
  }

  Future<void> _save(ReviewState s) async {
    state = s;
    await _store.put(_col, 'me', {
      'items': [for (final i in s.items) i.toJson()],
      'rubrics': [for (final r in s.rubrics) r.toJson()],
      'questions': [for (final q in s.questions) q.toJson()],
      'actingAs': s.actingAs.name,
    });
  }

  ReviewItem _get(String id) => state.item(id) ?? (throw const ApiException(statusCode: 404, code: 'NOT_FOUND', message: 'পাওয়া যায়নি'));

  Future<void> _put(ReviewItem item) => _save(state.copyWith(items: [for (final i in state.items) i.id == item.id ? item : i]));

  Future<void> actAs(ActorRole role) => _save(state.copyWith(actingAs: role));

  /// Validated status change; a decision note is required to request changes.
  Future<void> transition(String id, ContentStatus to, {String? note}) async {
    await ref.read(mockSimulatorProvider).run(() {});
    final item = _get(id);
    final actor = state.actor;
    if (!contentTransitions[item.status]!.contains(to)) {
      throw const ApiException(statusCode: 400, code: 'INVALID_TRANSITION', message: 'এই ধাপে যাওয়া যায় না');
    }
    if (!allowedTransitions(item.status, actor.role).contains(to)) {
      throw const ApiException(statusCode: 403, code: 'FORBIDDEN', message: 'আপনার এই অনুমতি নেই');
    }
    if (to == ContentStatus.changesRequested && (note == null || note.trim().isEmpty)) {
      throw const ApiException(statusCode: 400, code: 'NOTE_REQUIRED', message: 'পরিবর্তন চাইলে কারণ লিখুন');
    }
    await _put(item.copyWith(
      status: to,
      assignedTo: to == ContentStatus.inReview ? actor : null,
      history: [...item.history, ReviewEvent(DateTime.now(), item.status, to, actor, note: note?.trim())],
    ));
    if (item.contentId != null) {
      await _save(state.copyWith(questions: [
        for (final q in state.questions) q.question.id == item.contentId ? AuthoredQuestion(question: q.question, status: to, version: q.version, versions: q.versions) : q,
      ]));
    }
    if (to == ContentStatus.changesRequested || to == ContentStatus.approved) {
      await ref.read(notificationsProvider.notifier).push(AppNotification(
        id: 'rv-${DateTime.now().microsecondsSinceEpoch}',
        category: NotificationCategory.feedback,
        title: to == ContentStatus.changesRequested ? const Tr('পরিবর্তনের অনুরোধ', 'Changes requested') : const Tr('কনটেন্ট অনুমোদিত', 'Content approved'),
        body: Tr.same(item.title),
        createdAt: DateTime.now(),
        audience: 'teacher',
        route: '/teacher-history',
        priority: to == ContentStatus.changesRequested ? NotificationPriority.high : NotificationPriority.normal,
      ));
    }
  }

  Future<void> comment(String id, String text) async {
    final item = _get(id);
    await _put(item.copyWith(comments: [...item.comments, ReviewComment(state.actor, text.trim(), DateTime.now())]));
  }

  Future<void> suggest(String id, String from, String to) async {
    final item = _get(id);
    if (from.trim().isEmpty || !item.preview.contains(from.trim())) {
      throw const ApiException(statusCode: 400, code: 'TEXT_NOT_FOUND', message: 'বর্তমান লেখাটি কনটেন্টে পাওয়া যায়নি');
    }
    await _put(item.copyWith(suggestions: [
      ...item.suggestions,
      Suggestion(id: 's-${DateTime.now().microsecondsSinceEpoch}', from: from.trim(), to: to.trim(), by: state.actor, at: DateTime.now()),
    ]));
  }

  /// Accepting replaces the text in the preview.
  Future<void> resolveSuggestion(String id, String suggestionId, {required bool accept}) async {
    final item = _get(id);
    final s = item.suggestions.firstWhere((x) => x.id == suggestionId);
    await _put(item.copyWith(
      preview: accept ? item.preview.replaceAll(s.from, s.to) : item.preview,
      suggestions: [for (final x in item.suggestions) x.id == suggestionId ? x.withState(accept ? SuggestionState.accepted : SuggestionState.rejected) : x],
    ));
  }

  /// Teacher authoring: saves the question as a draft (or submits it) and keeps one open
  /// review item per question.
  Future<AuthoredQuestion> saveQuestion(Question q, {required bool submit}) async {
    await ref.read(mockSimulatorProvider).run(() {});
    final now = DateTime.now();
    final existing = state.questions.where((x) => x.question.id == q.id).firstOrNull;
    final status = submit ? ContentStatus.submitted : ContentStatus.draft;
    final authored = AuthoredQuestion(
      question: q,
      status: status,
      version: (existing?.version ?? 0) + 1,
      versions: [...?existing?.versions, (now, existing == null ? 'তৈরি' : 'সম্পাদনা')],
    );
    final title = 'প্রশ্ন: ${q.stem.bn.length > 60 ? q.stem.bn.substring(0, 60) : q.stem.bn}';
    final preview = '${q.stem.bn}\n\nউত্তর: ${q.answer.bn}${q.explanation == null ? '' : '\n\nব্যাখ্যা: ${q.explanation!.bn}'}';
    final open = state.items.where((i) => i.contentId == q.id && i.status != ContentStatus.published && i.status != ContentStatus.archived).firstOrNull;
    final items = open != null
        ? [
            for (final i in state.items)
              i.id == open.id ? i.copyWith(status: status, preview: preview, title: title, history: [...i.history, ReviewEvent(now, i.status, status, teacherActor)]) : i,
          ]
        : [
            ReviewItem(
              id: 'rv-q-${now.microsecondsSinceEpoch}',
              kind: ReviewKind.question,
              title: title,
              subjectId: q.subjectId,
              status: status,
              priority: ReviewPriority.normal,
              submittedBy: teacherActor,
              preview: preview,
              contentId: q.id,
              dueAt: now.add(const Duration(days: 5)),
              history: [ReviewEvent(now, null, status, teacherActor)],
            ),
            ...state.items,
          ];
    await _save(state.copyWith(questions: [authored, ...state.questions.where((x) => x.question.id != q.id)], items: items));
    return authored;
  }

  Future<void> saveRubric(Rubric r) async {
    if (r.name.trim().isEmpty || r.criteria.isEmpty) {
      throw const ApiException(statusCode: 400, code: 'INVALID', message: 'নাম ও অন্তত একটি মানদণ্ড দিন');
    }
    await _save(state.copyWith(rubrics: [r, ...state.rubrics.where((x) => x.id != r.id)]));
  }

  Future<void> removeRubric(String id) => _save(state.copyWith(rubrics: state.rubrics.where((r) => r.id != id).toList()));
}

final reviewProvider = NotifierProvider<ReviewController, ReviewState>(ReviewController.new);

List<ReviewItem> _seedItems(DateTime now) {
  DateTime ago(int d, [int h = 0]) => now.subtract(Duration(days: d, hours: h));
  const statuses = [
    ContentStatus.submitted,
    ContentStatus.inReview,
    ContentStatus.inReview,
    ContentStatus.changesRequested,
    ContentStatus.approved,
    ContentStatus.submitted,
    ContentStatus.published,
    ContentStatus.draft,
    ContentStatus.inReview,
    ContentStatus.submitted,
    ContentStatus.approved,
    ContentStatus.archived,
  ];
  const kinds = [
    ReviewKind.question,
    ReviewKind.question,
    ReviewKind.question,
    ReviewKind.aiAnswer,
    ReviewKind.chapter,
    ReviewKind.boardPaper,
    ReviewKind.institutionPaper,
    ReviewKind.rubric,
    ReviewKind.question,
    ReviewKind.book,
    ReviewKind.question,
    ReviewKind.note,
  ];
  const questions = [
    ('বল কাকে বলে? এর SI একক লেখো।', 'যা কোনো বস্তুর গতির অবস্থা পরিবর্তন করে বা করতে চায় তাকে বল বলে। SI একক নিউটন (N)।'),
    ('১০ kg ভরের বস্তুতে ২ m/s² ত্বরণ সৃষ্টি করতে কত বল লাগবে?', 'F = ma = ১০ × ২ = ২০ N'),
    ('নিউটনের তৃতীয় সূত্রটি উদাহরণসহ ব্যাখ্যা করো।', 'প্রত্যেক ক্রিয়ারই সমান ও বিপরীত প্রতিক্রিয়া আছে। যেমন: বন্দুক থেকে গুলি ছুড়লে বন্দুক পিছনে ধাক্কা দেয়।'),
    ('ঘর্ষণ কীভাবে কমানো যায়?', 'পিচ্ছিলকারী পদার্থ, বল-বিয়ারিং ও মসৃণ তল ব্যবহার করে।'),
    ('(x + 2)(x − 3) এর গুণফল নির্ণয় করো।', 'x² − x − ৬'),
  ];
  final out = <ReviewItem>[];
  for (var i = 0; i < statuses.length; i++) {
    final status = statuses[i];
    final kind = kinds[i];
    final (stem, answer) = questions[i % questions.length];
    final submitter = i % 3 == 0 ? managerActor : teacherActor;
    final title = switch (kind) {
      ReviewKind.question => 'প্রশ্ন: $stem',
      ReviewKind.aiAnswer => 'AI উত্তর যাচাই: ত্বরণের একক',
      ReviewKind.chapter => 'অধ্যায় বিবরণ হালনাগাদ: রাসায়নিক বিক্রিয়া',
      ReviewKind.boardPaper => 'বোর্ড-ধাঁচ পত্র ২০২৪ (কৃত্রিম) — সমাধান যাচাই',
      ReviewKind.institutionPaper => 'প্রতিষ্ঠানের প্রশ্নপত্র: অর্ধবার্ষিক ২০২৬',
      ReviewKind.rubric => 'রুব্রিক: সৃজনশীল প্রশ্ন (পদার্থবিজ্ঞান)',
      ReviewKind.book => 'পাঠ্যবই পৃষ্ঠা সংশোধন: পৃষ্ঠা ৪২',
      ReviewKind.note => 'নোট টেমপ্লেট: সূত্র শিট',
    };
    final preview = switch (kind) {
      ReviewKind.question => '$stem\n\nউত্তর: $answer',
      ReviewKind.aiAnswer => 'প্রশ্ন: ত্বরণের একক কী?\n\nAI উত্তর: ত্বরণের একক m/s (মিটার প্রতি সেকেন্ড)।\n\nশিক্ষার্থী রিপোর্ট করেছে: উত্তরটি ভুল মনে হচ্ছে।',
      _ => '$title\n\nকৃত্রিম ডেমো কনটেন্ট — পর্যালোচনার জন্য নমুনা।',
    };
    final history = <ReviewEvent>[ReviewEvent(ago(8 + i % 4), null, ContentStatus.draft, submitter)];
    if (status != ContentStatus.draft) history.add(ReviewEvent(ago(4, i), ContentStatus.draft, ContentStatus.submitted, submitter));
    const reviewed = {ContentStatus.inReview, ContentStatus.changesRequested, ContentStatus.approved, ContentStatus.published, ContentStatus.archived};
    if (reviewed.contains(status)) history.add(ReviewEvent(ago(2, i), ContentStatus.submitted, ContentStatus.inReview, reviewerActor));
    if (status == ContentStatus.changesRequested) history.add(ReviewEvent(ago(1), ContentStatus.inReview, ContentStatus.changesRequested, reviewerActor, note: 'উত্তরে একক নেই'));
    if ({ContentStatus.approved, ContentStatus.published, ContentStatus.archived}.contains(status)) {
      history.add(ReviewEvent(ago(1, 2), ContentStatus.inReview, ContentStatus.approved, reviewerActor));
    }
    if ({ContentStatus.published, ContentStatus.archived}.contains(status)) history.add(ReviewEvent(ago(0, 6), ContentStatus.approved, ContentStatus.published, managerActor));
    if (status == ContentStatus.archived) history.add(ReviewEvent(ago(0, 3), ContentStatus.published, ContentStatus.archived, managerActor));
    out.add(ReviewItem(
      id: 'rv-${i + 1}',
      kind: kind,
      title: title,
      subjectId: i % 5 == 4 ? 'ssc-gmath' : 'ssc-phy',
      status: status,
      priority: const [ReviewPriority.normal, ReviewPriority.high, ReviewPriority.normal, ReviewPriority.urgent, ReviewPriority.low, ReviewPriority.normal][i % 6],
      submittedBy: submitter,
      preview: preview,
      history: history,
      assignedTo: status == ContentStatus.draft ? null : reviewerActor,
      dueAt: now.add(Duration(days: (i % 7) - 1)),
      comments: i.isOdd ? [ReviewComment(reviewerActor, 'বানান ও একক মিলিয়ে নিন।', ago(1))] : const [],
      suggestions: kind == ReviewKind.aiAnswer ? [Suggestion(id: 's-$i', from: 'm/s (মিটার প্রতি সেকেন্ড)', to: 'm/s² (মিটার প্রতি বর্গসেকেন্ড)', by: reviewerActor, at: ago(1))] : const [],
    ));
  }
  return out;
}

const _seedRubrics = [
  Rubric(
    id: 'rb-1',
    name: 'সৃজনশীল প্রশ্ন — পদার্থবিজ্ঞান',
    subjectId: 'ssc-phy',
    use: RubricUse.creative,
    criteria: [
      RubricCriterion('জ্ঞান (ক)', 1, 'সঠিক সংজ্ঞা'),
      RubricCriterion('অনুধাবন (খ)', 2, 'কারণসহ ব্যাখ্যা'),
      RubricCriterion('প্রয়োগ (গ)', 3, 'সূত্র ও হিসাব, একক'),
      RubricCriterion('উচ্চতর দক্ষতা (ঘ)', 4, 'বিশ্লেষণ ও সিদ্ধান্ত'),
    ],
    status: ContentStatus.published,
    owner: 'ড. মাহমুদ হাসান',
  ),
  Rubric(
    id: 'rb-2',
    name: 'বর্ণনামূলক উত্তর (সাধারণ)',
    use: RubricUse.descriptive,
    criteria: [RubricCriterion('বিষয়বস্তু', 3, 'মূল পয়েন্ট'), RubricCriterion('উদাহরণ', 1, 'প্রাসঙ্গিক উদাহরণ'), RubricCriterion('উপস্থাপনা', 1, 'গোছানো লেখা')],
    status: ContentStatus.published,
    owner: 'ড. মাহমুদ হাসান',
  ),
  Rubric(
    id: 'rb-3',
    name: 'হাতের লেখা মূল্যায়ন — গণিত',
    subjectId: 'ssc-gmath',
    use: RubricUse.handwriting,
    criteria: [RubricCriterion('পদ্ধতি', 3, 'সঠিক ধাপ'), RubricCriterion('হিসাব', 2, 'নির্ভুল গণনা'), RubricCriterion('যাচাই', 1, 'উত্তর যাচাই')],
    status: ContentStatus.inReview,
    owner: 'নাসরিন সুলতানা',
  ),
];
