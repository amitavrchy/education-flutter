import '../../../core/l10n/tr.dart';

/// Per-book 2D teacher avatar: look, voice, persona and answer scope.
/// Mirrors `BookAvatar` in the web contracts (`src/contracts/learning.ts`) and
/// `docs/api/BOOK_AVATAR_CONTRACT.md` so the real API can replace the mock unchanged.

enum AvatarGender { female, male }

enum HairStyle { short, sidePart, long, bun, hijab, bald }

enum Outfit { saree, salwar, shirt, panjabi, blazer }

enum PersonaStyle {
  friendly(Tr('বন্ধুসুলভ', 'Friendly')),
  formal(Tr('আনুষ্ঠানিক', 'Formal')),
  socratic(Tr('প্রশ্ন করে শেখানো', 'Socratic'));

  const PersonaStyle(this.label);
  final Tr label;
}

enum AnswerLength {
  short(Tr('সংক্ষিপ্ত', 'Short')),
  balanced(Tr('মাঝারি', 'Balanced')),
  detailed(Tr('বিস্তারিত', 'Detailed'));

  const AnswerLength(this.label);
  final Tr label;
}

enum AvatarStatus {
  draft(Tr('ড্রাফট', 'Draft')),
  active(Tr('সক্রিয়', 'Active')),
  disabled(Tr('বন্ধ', 'Disabled'));

  const AvatarStatus(this.label);
  final Tr label;
}

/// Where an answer came from.
enum Grounding { book, greeting, outOfScope }

enum AvatarRole { student, avatar }

enum ReportStatus { open, resolved, dismissed }

T _enum<T extends Enum>(List<T> values, Object? name, T fallback) =>
    values.where((v) => v.name == name).firstOrNull ?? fallback;

class AvatarAppearance {
  const AvatarAppearance({
    required this.gender,
    required this.skinTone,
    required this.hairStyle,
    required this.hairColor,
    required this.outfit,
    required this.outfitColor,
    required this.accentColor,
    required this.glasses,
    required this.beard,
    required this.background,
  });

  factory AvatarAppearance.fromJson(Map<String, dynamic> j) => AvatarAppearance(
    gender: _enum(AvatarGender.values, j['gender'], AvatarGender.female),
    skinTone: j['skinTone'] as int,
    hairStyle: _enum(HairStyle.values, j['hairStyle'], HairStyle.short),
    hairColor: j['hairColor'] as int,
    outfit: _enum(Outfit.values, j['outfit'], Outfit.shirt),
    outfitColor: j['outfitColor'] as int,
    accentColor: j['accentColor'] as int,
    glasses: j['glasses'] as bool? ?? false,
    beard: j['beard'] as bool? ?? false,
    background: j['background'] as int,
  );

  final AvatarGender gender;

  /// ARGB colours.
  final int skinTone;
  final HairStyle hairStyle;
  final int hairColor;
  final Outfit outfit;
  final int outfitColor;
  final int accentColor;
  final bool glasses;
  final bool beard;
  final int background;

  Map<String, dynamic> toJson() => {
    'gender': gender.name,
    'skinTone': skinTone,
    'hairStyle': hairStyle.name,
    'hairColor': hairColor,
    'outfit': outfit.name,
    'outfitColor': outfitColor,
    'accentColor': accentColor,
    'glasses': glasses,
    'beard': beard,
    'background': background,
  };
}

class AvatarVoiceSettings {
  const AvatarVoiceSettings({this.language = 'bn', this.rate = 1, this.pitch = 1});

  factory AvatarVoiceSettings.fromJson(Map<String, dynamic> j) => AvatarVoiceSettings(
    language: j['language'] as String? ?? 'bn',
    rate: (j['rate'] as num?)?.toDouble() ?? 1,
    pitch: (j['pitch'] as num?)?.toDouble() ?? 1,
  );

  /// 'bn' | 'en'
  final String language;
  final double rate;
  final double pitch;

  Map<String, dynamic> toJson() => {'language': language, 'rate': rate, 'pitch': pitch};
}

class AvatarPersona {
  const AvatarPersona({this.style = PersonaStyle.friendly, this.answerLength = AnswerLength.balanced, this.useExamples = true});

  factory AvatarPersona.fromJson(Map<String, dynamic> j) => AvatarPersona(
    style: _enum(PersonaStyle.values, j['style'], PersonaStyle.friendly),
    answerLength: _enum(AnswerLength.values, j['answerLength'], AnswerLength.balanced),
    useExamples: j['useExamples'] as bool? ?? true,
  );

  final PersonaStyle style;
  final AnswerLength answerLength;
  final bool useExamples;

  Map<String, dynamic> toJson() => {'style': style.name, 'answerLength': answerLength.name, 'useExamples': useExamples};
}

class AvatarStats {
  const AvatarStats({this.sessions = 0, this.questions = 0, this.outOfScope = 0, this.helpful = 0, this.notHelpful = 0});

  factory AvatarStats.fromJson(Map<String, dynamic> j) => AvatarStats(
    sessions: j['sessions'] as int? ?? 0,
    questions: j['questions'] as int? ?? 0,
    outOfScope: j['outOfScope'] as int? ?? 0,
    helpful: j['helpful'] as int? ?? 0,
    notHelpful: j['notHelpful'] as int? ?? 0,
  );

  final int sessions;
  final int questions;
  final int outOfScope;
  final int helpful;
  final int notHelpful;

  /// 0–100, or null when nobody rated yet.
  int? get satisfaction => helpful + notHelpful == 0 ? null : (100 * helpful / (helpful + notHelpful)).round();

  AvatarStats copyWith({int? sessions, int? questions, int? outOfScope, int? helpful, int? notHelpful}) => AvatarStats(
    sessions: sessions ?? this.sessions,
    questions: questions ?? this.questions,
    outOfScope: outOfScope ?? this.outOfScope,
    helpful: helpful ?? this.helpful,
    notHelpful: notHelpful ?? this.notHelpful,
  );

  Map<String, dynamic> toJson() => {'sessions': sessions, 'questions': questions, 'outOfScope': outOfScope, 'helpful': helpful, 'notHelpful': notHelpful};
}

class BookAvatar {
  const BookAvatar({
    required this.id,
    required this.bookId,
    required this.name,
    required this.title,
    required this.appearance,
    required this.greeting,
    this.voice = const AvatarVoiceSettings(),
    this.persona = const AvatarPersona(),
    this.scopeChapterIds = const [],
    this.strictBookScope = true,
    this.status = AvatarStatus.active,
    this.stats = const AvatarStats(),
  });

  factory BookAvatar.fromJson(Map<String, dynamic> j) => BookAvatar(
    id: j['id'] as String,
    bookId: j['bookId'] as String,
    name: Tr.fromJson(j['name']),
    title: Tr.fromJson(j['title']),
    appearance: AvatarAppearance.fromJson((j['appearance'] as Map).cast<String, dynamic>()),
    greeting: Tr.fromJson(j['greeting']),
    voice: AvatarVoiceSettings.fromJson((j['voice'] as Map? ?? const {}).cast<String, dynamic>()),
    persona: AvatarPersona.fromJson((j['persona'] as Map? ?? const {}).cast<String, dynamic>()),
    scopeChapterIds: (j['scopeChapterIds'] as List? ?? const []).cast<String>(),
    strictBookScope: j['strictBookScope'] as bool? ?? true,
    status: _enum(AvatarStatus.values, j['status'], AvatarStatus.active),
    stats: AvatarStats.fromJson((j['stats'] as Map? ?? const {}).cast<String, dynamic>()),
  );

  final String id;
  final String bookId;
  final Tr name;
  final Tr title;
  final AvatarAppearance appearance;
  final Tr greeting;
  final AvatarVoiceSettings voice;
  final AvatarPersona persona;

  /// Empty = the whole book.
  final List<String> scopeChapterIds;
  final bool strictBookScope;
  final AvatarStatus status;
  final AvatarStats stats;

  BookAvatar copyWith({AvatarStats? stats, AvatarStatus? status}) => BookAvatar(
    id: id,
    bookId: bookId,
    name: name,
    title: title,
    appearance: appearance,
    greeting: greeting,
    voice: voice,
    persona: persona,
    scopeChapterIds: scopeChapterIds,
    strictBookScope: strictBookScope,
    status: status ?? this.status,
    stats: stats ?? this.stats,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'bookId': bookId,
    'name': {'bn': name.bn, 'en': name.en},
    'title': {'bn': title.bn, 'en': title.en},
    'appearance': appearance.toJson(),
    'greeting': {'bn': greeting.bn, 'en': greeting.en},
    'voice': voice.toJson(),
    'persona': persona.toJson(),
    'scopeChapterIds': scopeChapterIds,
    'strictBookScope': strictBookScope,
    'status': status.name,
    'stats': stats.toJson(),
  };
}

class AvatarCitation {
  const AvatarCitation({required this.page, required this.chapterTitle, this.heading, required this.excerpt});

  factory AvatarCitation.fromJson(Map<String, dynamic> j) => AvatarCitation(
    page: j['page'] as int,
    chapterTitle: j['chapterTitle'] as String,
    heading: j['heading'] as String?,
    excerpt: j['excerpt'] as String,
  );

  final int page;
  final String chapterTitle;
  final String? heading;
  final String excerpt;

  Map<String, dynamic> toJson() => {'page': page, 'chapterTitle': chapterTitle, 'heading': heading, 'excerpt': excerpt};
}

/// What the engine returns for one question.
class AvatarAnswer {
  const AvatarAnswer({required this.text, required this.spoken, required this.citations, required this.grounded, required this.followUps});

  /// Markdown + LaTeX (rendered with RichContent).
  final String text;

  /// Plain speakable text for TTS.
  final String spoken;
  final List<AvatarCitation> citations;
  final Grounding grounded;
  final List<String> followUps;
}

class AvatarMessage {
  const AvatarMessage({
    required this.id,
    required this.sessionId,
    required this.role,
    required this.text,
    required this.at,
    this.spoken,
    this.voiceInput = false,
    this.citations = const [],
    this.grounded,
    this.followUps = const [],
    this.feedback,
  });

  factory AvatarMessage.fromJson(Map<String, dynamic> j) => AvatarMessage(
    id: j['id'] as String,
    sessionId: j['sessionId'] as String,
    role: _enum(AvatarRole.values, j['role'], AvatarRole.student),
    text: j['text'] as String,
    at: DateTime.parse(j['at'] as String),
    spoken: j['spoken'] as String?,
    voiceInput: j['voiceInput'] as bool? ?? false,
    citations: [for (final c in j['citations'] as List? ?? const []) AvatarCitation.fromJson((c as Map).cast<String, dynamic>())],
    grounded: j['grounded'] == null ? null : _enum(Grounding.values, j['grounded'], Grounding.book),
    followUps: (j['followUps'] as List? ?? const []).cast<String>(),
    feedback: j['feedback'] as String?,
  );

  final String id;
  final String sessionId;
  final AvatarRole role;
  final String text;
  final DateTime at;
  final String? spoken;
  final bool voiceInput;
  final List<AvatarCitation> citations;
  final Grounding? grounded;
  final List<String> followUps;

  /// 'up' | 'down'
  final String? feedback;

  AvatarMessage withFeedback(String value) => AvatarMessage(
    id: id,
    sessionId: sessionId,
    role: role,
    text: text,
    at: at,
    spoken: spoken,
    voiceInput: voiceInput,
    citations: citations,
    grounded: grounded,
    followUps: followUps,
    feedback: value,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'sessionId': sessionId,
    'role': role.name,
    'text': text,
    'at': at.toIso8601String(),
    'spoken': spoken,
    'voiceInput': voiceInput,
    'citations': [for (final c in citations) c.toJson()],
    'grounded': grounded?.name,
    'followUps': followUps,
    'feedback': feedback,
  };
}

class AvatarSession {
  const AvatarSession({
    required this.id,
    required this.bookId,
    required this.avatarId,
    required this.studentId,
    required this.title,
    required this.startedAt,
    required this.lastAt,
    this.messageCount = 0,
    this.voiceTurns = 0,
    this.minutes = 0,
  });

  factory AvatarSession.fromJson(Map<String, dynamic> j) => AvatarSession(
    id: j['id'] as String,
    bookId: j['bookId'] as String,
    avatarId: j['avatarId'] as String,
    studentId: j['studentId'] as String,
    title: j['title'] as String,
    startedAt: DateTime.parse(j['startedAt'] as String),
    lastAt: DateTime.parse(j['lastAt'] as String),
    messageCount: j['messageCount'] as int? ?? 0,
    voiceTurns: j['voiceTurns'] as int? ?? 0,
    minutes: j['minutes'] as int? ?? 0,
  );

  final String id;
  final String bookId;
  final String avatarId;
  final String studentId;
  final String title;
  final DateTime startedAt;
  final DateTime lastAt;
  final int messageCount;
  final int voiceTurns;
  final int minutes;

  AvatarSession copyWith({String? title, DateTime? lastAt, int? messageCount, int? voiceTurns, int? minutes}) => AvatarSession(
    id: id,
    bookId: bookId,
    avatarId: avatarId,
    studentId: studentId,
    title: title ?? this.title,
    startedAt: startedAt,
    lastAt: lastAt ?? this.lastAt,
    messageCount: messageCount ?? this.messageCount,
    voiceTurns: voiceTurns ?? this.voiceTurns,
    minutes: minutes ?? this.minutes,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'bookId': bookId,
    'avatarId': avatarId,
    'studentId': studentId,
    'title': title,
    'startedAt': startedAt.toIso8601String(),
    'lastAt': lastAt.toIso8601String(),
    'messageCount': messageCount,
    'voiceTurns': voiceTurns,
    'minutes': minutes,
  };
}

class AvatarReport {
  const AvatarReport({
    required this.id,
    required this.bookId,
    required this.avatarId,
    required this.studentId,
    required this.question,
    required this.answer,
    required this.reason,
    required this.createdAt,
    this.status = ReportStatus.open,
    this.resolution,
    this.resolvedBy,
  });

  factory AvatarReport.fromJson(Map<String, dynamic> j) => AvatarReport(
    id: j['id'] as String,
    bookId: j['bookId'] as String,
    avatarId: j['avatarId'] as String,
    studentId: j['studentId'] as String,
    question: j['question'] as String,
    answer: j['answer'] as String,
    reason: j['reason'] as String,
    createdAt: DateTime.parse(j['createdAt'] as String),
    status: _enum(ReportStatus.values, j['status'], ReportStatus.open),
    resolution: j['resolution'] as String?,
    resolvedBy: j['resolvedBy'] as String?,
  );

  final String id;
  final String bookId;
  final String avatarId;
  final String studentId;
  final String question;
  final String answer;
  final String reason;
  final DateTime createdAt;
  final ReportStatus status;
  final String? resolution;
  final String? resolvedBy;

  AvatarReport resolve(ReportStatus to, String note, String by) => AvatarReport(
    id: id,
    bookId: bookId,
    avatarId: avatarId,
    studentId: studentId,
    question: question,
    answer: answer,
    reason: reason,
    createdAt: createdAt,
    status: to,
    resolution: note,
    resolvedBy: by,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'bookId': bookId,
    'avatarId': avatarId,
    'studentId': studentId,
    'question': question,
    'answer': answer,
    'reason': reason,
    'createdAt': createdAt.toIso8601String(),
    'status': status.name,
    'resolution': resolution,
    'resolvedBy': resolvedBy,
  };
}
