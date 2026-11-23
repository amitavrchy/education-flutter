import 'package:material_ui/material_ui.dart';

import '../../../core/l10n/tr.dart';
import '../../curriculum/domain/curriculum_models.dart';

/// The ten teaching modes (§8). Each changes how the mock engine shapes its answer.
enum TeachingMode {
  simple(Tr('সহজ ব্যাখ্যা', 'Simple explanation'), Tr('সহজ ভাষায়, উদাহরণসহ', 'Plain words with an example'), Icons.lightbulb_outline),
  socratic(Tr('প্রাইভেট টিউটর (প্রশ্নোত্তর)', 'Private tutor (Socratic)'), Tr('উত্তর না বলে প্রশ্নে প্রশ্নে বোঝায়', 'Guides you with questions instead of answers'), Icons.psychology_alt_outlined),
  boardAnswer(Tr('বোর্ড পরীক্ষার উত্তর', 'Board exam answer'), Tr('পরীক্ষার খাতার মতো সাজানো উত্তর', 'Structured like an exam script'), Icons.history_edu_outlined),
  quickRevision(Tr('দ্রুত রিভিশন', 'Quick revision'), Tr('মূল পয়েন্টগুলো এক নজরে', 'Key points at a glance'), Icons.flash_on_outlined),
  stepByStep(Tr('ধাপে ধাপে সমাধান', 'Step-by-step solver'), Tr('প্রতিটি ধাপ আলাদা করে', 'Every step spelled out'), Icons.format_list_numbered),
  deepConcept(Tr('গভীর ধারণা', 'Deep concept'), Tr('কেন ও কীভাবে — বিস্তারিত', 'The why and how, in depth'), Icons.layers_outlined),
  practice(Tr('অনুশীলন প্রশ্ন', 'Practice question'), Tr('প্রশ্ন দেবে, তুমি উত্তর দেবে', 'Gives you a question to answer'), Icons.quiz_outlined),
  oralExam(Tr('মৌখিক পরীক্ষা', 'Oral exam'), Tr('ভাইভার মতো প্রশ্ন ও মূল্যায়ন', 'Viva-style questions and feedback'), Icons.record_voice_over_outlined),
  formula(Tr('সূত্র ব্যাখ্যা', 'Formula explainer'), Tr('সূত্র, প্রতীক ও প্রয়োগ', 'Formula, symbols and use'), Icons.functions),
  englishCoach(Tr('ইংরেজি স্পিকিং কোচ', 'English speaking coach'), Tr('বাক্য সংশোধন ও টিপস', 'Corrects sentences with tips'), Icons.translate);

  const TeachingMode(this.label, this.hint, this.icon);

  final Tr label;
  final Tr hint;
  final IconData icon;
}

/// Answer language. Mixed = Bangla sentences with English technical terms.
enum TutorLanguage {
  bn(Tr('বাংলা', 'Bangla')),
  en(Tr('ইংরেজি', 'English')),
  mixed(Tr('বাংলা-ইংরেজি মিশ্র', 'Mixed Bangla-English'));

  const TutorLanguage(this.label);

  final Tr label;
}

/// Academic context of a conversation; shown as chips and used by retrieval.
@immutable
class TutorContext {
  const TutorContext({
    this.level = EducationLevel.ssc,
    this.classYear = 10,
    this.subjectId,
    this.paper,
    this.chapterId,
    this.topicId,
    this.curriculumVersionId = 'nctb-2025',
    this.language = TutorLanguage.bn,
    this.mode = TeachingMode.simple,
  });

  factory TutorContext.fromJson(Map<String, dynamic> j) => TutorContext(
    level: EducationLevel.fromCode(j['level'] as String? ?? 'ssc'),
    classYear: j['classYear'] as int? ?? 10,
    subjectId: j['subjectId'] as String?,
    paper: j['paper'] as int?,
    chapterId: j['chapterId'] as String?,
    topicId: j['topicId'] as String?,
    curriculumVersionId: j['curriculumVersionId'] as String? ?? 'nctb-2025',
    language: TutorLanguage.values.byName(j['language'] as String? ?? 'bn'),
    mode: TeachingMode.values.byName(j['mode'] as String? ?? 'simple'),
  );

  final EducationLevel level;
  final int classYear;
  final String? subjectId;
  final int? paper;
  final String? chapterId;
  final String? topicId;
  final String curriculumVersionId;
  final TutorLanguage language;
  final TeachingMode mode;

  TutorContext copyWith({
    EducationLevel? level,
    int? classYear,
    String? Function()? subjectId,
    int? Function()? paper,
    String? Function()? chapterId,
    String? Function()? topicId,
    String? curriculumVersionId,
    TutorLanguage? language,
    TeachingMode? mode,
  }) => TutorContext(
    level: level ?? this.level,
    classYear: classYear ?? this.classYear,
    subjectId: subjectId == null ? this.subjectId : subjectId(),
    paper: paper == null ? this.paper : paper(),
    chapterId: chapterId == null ? this.chapterId : chapterId(),
    topicId: topicId == null ? this.topicId : topicId(),
    curriculumVersionId: curriculumVersionId ?? this.curriculumVersionId,
    language: language ?? this.language,
    mode: mode ?? this.mode,
  );

  Map<String, dynamic> toJson() => {
    'level': level.name,
    'classYear': classYear,
    'subjectId': subjectId,
    'paper': paper,
    'chapterId': chapterId,
    'topicId': topicId,
    'curriculumVersionId': curriculumVersionId,
    'language': language.name,
    'mode': mode.name,
  };
}

/// How well an answer is backed by the (sample) knowledge base.
enum Grounding {
  verified(Tr('উৎস-সমর্থিত', 'Source-supported'), Icons.verified_outlined),
  partial(Tr('আংশিক সমর্থিত', 'Partially supported'), Icons.rule_outlined),
  general(Tr('সাধারণ AI ব্যাখ্যা', 'General AI explanation'), Icons.auto_awesome_outlined),
  unavailable(Tr('উৎস পাওয়া যায়নি', 'Source unavailable'), Icons.help_outline);

  const Grounding(this.label, this.icon);

  final Tr label;
  final IconData icon;
}

/// A retrieved passage from a sample textbook.
@immutable
class SourceRef {
  const SourceRef({
    required this.id,
    required this.bookId,
    required this.bookTitle,
    required this.chapterTitle,
    required this.page,
    required this.excerpt,
    required this.curriculumVersionId,
    required this.score,
  });

  factory SourceRef.fromJson(Map<String, dynamic> j) => SourceRef(
    id: j['id'] as String,
    bookId: j['bookId'] as String,
    bookTitle: Tr.fromJson(j['bookTitle']),
    chapterTitle: Tr.fromJson(j['chapterTitle']),
    page: j['page'] as int,
    excerpt: Tr.fromJson(j['excerpt']),
    curriculumVersionId: j['curriculumVersionId'] as String,
    score: (j['score'] as num).toDouble(),
  );

  final String id;
  final String bookId;
  final Tr bookTitle;
  final Tr chapterTitle;
  final int page;
  final Tr excerpt;
  final String curriculumVersionId;

  /// Retrieval relevance 0..1.
  final double score;

  Map<String, dynamic> toJson() => {
    'id': id,
    'bookId': bookId,
    'bookTitle': bookTitle.toJson(),
    'chapterTitle': chapterTitle.toJson(),
    'page': page,
    'excerpt': excerpt.toJson(),
    'curriculumVersionId': curriculumVersionId,
    'score': score,
  };
}

enum ChatRole { user, assistant }

enum MessageStatus { streaming, done, error }

/// Warnings the safety layer can attach to an answer.
enum AnswerWarning {
  lowConfidence(Tr('কম নিশ্চয়তা — শিক্ষকের সাথে মিলিয়ে নাও', 'Low confidence — check with a teacher')),
  missingKnowledge(Tr('এই বিষয়ে জ্ঞানভাণ্ডারে কনটেন্ট নেই', 'No knowledge-base content for this yet')),
  conflictingSources(Tr('উৎসগুলোর মধ্যে অমিল আছে', 'Sources disagree')),
  oldCurriculum(Tr('পুরনো সিলেবাসের উৎস — নতুন বইয়ের সাথে মেলাও', 'Source is from the previous syllabus — compare with the new book')),
  integrity(Tr('একাডেমিক সততা: নিজে চেষ্টা করে শেখো', 'Academic integrity: learn by trying yourself')),
  offTopic(Tr('পড়াশোনার বাইরের প্রশ্ন', 'Outside study topics'));

  const AnswerWarning(this.label);

  final Tr label;
}

@immutable
class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.role,
    required this.text,
    required this.createdAt,
    this.status = MessageStatus.done,
    this.mode,
    this.sources = const [],
    this.grounding,
    this.confidence,
    this.followUps = const [],
    this.relatedQuestionIds = const [],
    this.warnings = const [],
    this.feedback,
    this.bookmarked = false,
    this.reported = false,
    this.teacherReview = false,
    this.versions = const [],
    this.editedAt,
    this.error,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> j) => ChatMessage(
    id: j['id'] as String,
    role: ChatRole.values.byName(j['role'] as String),
    text: j['text'] as String,
    createdAt: DateTime.parse(j['createdAt'] as String),
    status: MessageStatus.values.byName(j['status'] as String? ?? 'done'),
    mode: j['mode'] == null ? null : TeachingMode.values.byName(j['mode'] as String),
    sources: [for (final s in j['sources'] as List? ?? const []) SourceRef.fromJson(s as Map<String, dynamic>)],
    grounding: j['grounding'] == null ? null : Grounding.values.byName(j['grounding'] as String),
    confidence: (j['confidence'] as num?)?.toDouble(),
    followUps: List<String>.from(j['followUps'] as List? ?? const []),
    relatedQuestionIds: List<String>.from(j['relatedQuestionIds'] as List? ?? const []),
    warnings: [for (final w in j['warnings'] as List? ?? const []) AnswerWarning.values.byName(w as String)],
    feedback: j['feedback'] as int?,
    bookmarked: j['bookmarked'] as bool? ?? false,
    reported: j['reported'] as bool? ?? false,
    teacherReview: j['teacherReview'] as bool? ?? false,
    versions: List<String>.from(j['versions'] as List? ?? const []),
    editedAt: j['editedAt'] == null ? null : DateTime.parse(j['editedAt'] as String),
    error: j['error'] as String?,
  );

  final String id;
  final ChatRole role;
  final String text;
  final DateTime createdAt;
  final MessageStatus status;
  final TeachingMode? mode;
  final List<SourceRef> sources;
  final Grounding? grounding;
  final double? confidence;
  final List<String> followUps;
  final List<String> relatedQuestionIds;
  final List<AnswerWarning> warnings;

  /// 1 helpful, -1 not helpful.
  final int? feedback;
  final bool bookmarked;
  final bool reported;
  final bool teacherReview;

  /// Earlier versions of this answer (regenerations) — the correction history.
  final List<String> versions;
  final DateTime? editedAt;
  final String? error;

  bool get isUser => role == ChatRole.user;

  ChatMessage copyWith({
    String? text,
    MessageStatus? status,
    List<SourceRef>? sources,
    Grounding? grounding,
    double? confidence,
    List<String>? followUps,
    List<String>? relatedQuestionIds,
    List<AnswerWarning>? warnings,
    int? Function()? feedback,
    bool? bookmarked,
    bool? reported,
    bool? teacherReview,
    List<String>? versions,
    DateTime? editedAt,
    String? Function()? error,
    TeachingMode? mode,
  }) => ChatMessage(
    id: id,
    role: role,
    text: text ?? this.text,
    createdAt: createdAt,
    status: status ?? this.status,
    mode: mode ?? this.mode,
    sources: sources ?? this.sources,
    grounding: grounding ?? this.grounding,
    confidence: confidence ?? this.confidence,
    followUps: followUps ?? this.followUps,
    relatedQuestionIds: relatedQuestionIds ?? this.relatedQuestionIds,
    warnings: warnings ?? this.warnings,
    feedback: feedback == null ? this.feedback : feedback(),
    bookmarked: bookmarked ?? this.bookmarked,
    reported: reported ?? this.reported,
    teacherReview: teacherReview ?? this.teacherReview,
    versions: versions ?? this.versions,
    editedAt: editedAt ?? this.editedAt,
    error: error == null ? this.error : error(),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'role': role.name,
    'text': text,
    'createdAt': createdAt.toIso8601String(),
    'status': status.name,
    'mode': mode?.name,
    'sources': [for (final s in sources) s.toJson()],
    'grounding': grounding?.name,
    'confidence': confidence,
    'followUps': followUps,
    'relatedQuestionIds': relatedQuestionIds,
    'warnings': [for (final w in warnings) w.name],
    'feedback': feedback,
    'bookmarked': bookmarked,
    'reported': reported,
    'teacherReview': teacherReview,
    'versions': versions,
    'editedAt': editedAt?.toIso8601String(),
    'error': error,
  };
}

@immutable
class Conversation {
  const Conversation({
    required this.id,
    required this.title,
    required this.createdAt,
    required this.updatedAt,
    required this.context,
    this.messages = const [],
    this.pinned = false,
    this.archived = false,
    this.folder,
  });

  factory Conversation.fromJson(Map<String, dynamic> j) => Conversation(
    id: j['id'] as String,
    title: j['title'] as String,
    createdAt: DateTime.parse(j['createdAt'] as String),
    updatedAt: DateTime.parse(j['updatedAt'] as String),
    context: TutorContext.fromJson(j['context'] as Map<String, dynamic>),
    messages: [for (final m in j['messages'] as List? ?? const []) ChatMessage.fromJson(m as Map<String, dynamic>)],
    pinned: j['pinned'] as bool? ?? false,
    archived: j['archived'] as bool? ?? false,
    folder: j['folder'] as String?,
  );

  final String id;
  final String title;
  final DateTime createdAt;
  final DateTime updatedAt;
  final TutorContext context;
  final List<ChatMessage> messages;
  final bool pinned;
  final bool archived;
  final String? folder;

  bool get isStreaming => messages.any((m) => m.status == MessageStatus.streaming);

  String get preview => messages.isEmpty ? '' : messages.last.text.replaceAll(RegExp(r'[#*>$\\|`]'), '').trim();

  Conversation copyWith({
    String? title,
    DateTime? updatedAt,
    TutorContext? context,
    List<ChatMessage>? messages,
    bool? pinned,
    bool? archived,
    String? Function()? folder,
  }) => Conversation(
    id: id,
    title: title ?? this.title,
    createdAt: createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    context: context ?? this.context,
    messages: messages ?? this.messages,
    pinned: pinned ?? this.pinned,
    archived: archived ?? this.archived,
    folder: folder == null ? this.folder : folder(),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
    'context': context.toJson(),
    'messages': [for (final m in messages) m.toJson()],
    'pinned': pinned,
    'archived': archived,
    'folder': folder,
  };
}

/// Final metadata of an answer, delivered after the streamed text.
@immutable
class TutorReply {
  const TutorReply({
    required this.text,
    required this.grounding,
    required this.confidence,
    this.sources = const [],
    this.followUps = const [],
    this.relatedQuestionIds = const [],
    this.warnings = const [],
  });

  final String text;
  final Grounding grounding;
  final double confidence;
  final List<SourceRef> sources;
  final List<String> followUps;
  final List<String> relatedQuestionIds;
  final List<AnswerWarning> warnings;
}

/// Streaming protocol of the tutor (mirrors the planned server-sent events).
sealed class TutorEvent {
  const TutorEvent();
}

class TutorDelta extends TutorEvent {
  const TutorDelta(this.text);

  final String text;
}

class TutorDone extends TutorEvent {
  const TutorDone(this.reply);

  final TutorReply reply;
}
