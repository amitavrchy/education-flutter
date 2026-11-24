import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/tr.dart';
import '../../../core/mock/json_collection.dart';
import '../../../core/mock/mock_simulator.dart';
import '../../../core/storage/local_store.dart';
import '../../auth/application/auth_controller.dart';
import '../data/book_avatar_engine.dart';
import '../data/book_catalog.dart';
import '../domain/avatar_models.dart';

/// Demo student every seed belongs to (the mock login id for students).
const demoStudentId = 'mock-student';

// ── Default look per book (deterministic, varied) ─────────────────────────────

const _skin = [0xFFF2C9A0, 0xFFE0AC7E, 0xFFC68B5E, 0xFFA86F4A, 0xFF8D5A3B];
const _hair = [0xFF1F1A17, 0xFF2E2420, 0xFF4A3426, 0xFF6B4A35, 0xFF8A8A8A];
const _outfit = [0xFF0F766E, 0xFF1D4ED8, 0xFF7C3AED, 0xFFB45309, 0xFFBE123C, 0xFF334155, 0xFF15803D];
const _bg = [0xFFE6F4F1, 0xFFE8EEFB, 0xFFF1ECFB, 0xFFFBF1E4, 0xFFFCE9EE, 0xFFEEF2F6];
const _female = [('নাসরিন আপা', 'Nasrin Apa'), ('ফারহানা ম্যাডাম', 'Farhana Madam'), ('তাহমিনা আপা', 'Tahmina Apa'), ('রুমানা ম্যাডাম', 'Rumana Madam'), ('সাবরিনা আপা', 'Sabrina Apa')];
const _male = [('রফিক স্যার', 'Rafiq Sir'), ('মাহফুজ স্যার', 'Mahfuz Sir'), ('কামাল স্যার', 'Kamal Sir'), ('আরিফ স্যার', 'Arif Sir'), ('শফিক স্যার', 'Shafiq Sir')];

/// FNV-1a + murmur3 fmix32: stable across runs and platforms, well-mixed low bits.
int mixHash(String s) {
  var h = 0x811c9dc5;
  for (final c in s.codeUnits) {
    h ^= c;
    h = (h * 0x01000193) & 0xFFFFFFFF;
  }
  h ^= h >> 16;
  h = (h * 0x85ebca6b) & 0xFFFFFFFF;
  h ^= h >> 13;
  h = (h * 0xc2b2ae35) & 0xFFFFFFFF;
  h ^= h >> 16;
  return h;
}

AvatarAppearance defaultAppearance(String seed) {
  final h = mixHash(seed);
  T pick<T>(List<T> list, int salt) => list[(h >> salt) % list.length];
  final female = h.isOdd;
  return AvatarAppearance(
    gender: female ? AvatarGender.female : AvatarGender.male,
    skinTone: pick(_skin, 1),
    hairStyle: female ? pick(const [HairStyle.long, HairStyle.bun, HairStyle.hijab, HairStyle.long], 3) : pick(const [HairStyle.short, HairStyle.sidePart, HairStyle.short, HairStyle.bald], 3),
    hairColor: pick(_hair, 5),
    outfit: female ? pick(const [Outfit.saree, Outfit.salwar, Outfit.blazer], 7) : pick(const [Outfit.shirt, Outfit.panjabi, Outfit.blazer], 7),
    outfitColor: pick(_outfit, 9),
    accentColor: pick(_outfit, 11),
    glasses: (h >> 13) % 3 == 0,
    beard: !female && (h >> 15) % 3 == 0,
    background: pick(_bg, 17),
  );
}

BookAvatar defaultAvatarFor(Book book) {
  final look = defaultAppearance('${book.subject.id}${book.id}');
  final names = look.gender == AvatarGender.female ? _female : _male;
  final (bn, en) = names[mixHash('name:${book.id}') % names.length];
  final subject = book.subject.name;
  return BookAvatar(
    id: 'av-${book.id}',
    bookId: book.id,
    name: Tr(bn, en),
    title: Tr('${subject.bn} শিক্ষক', '${subject.en} teacher'),
    appearance: look,
    voice: AvatarVoiceSettings(language: book.language, pitch: look.gender == AvatarGender.female ? 1.1 : 0.9),
    greeting: Tr(
      'আসসালামু আলাইকুম! আমি $bn। "${book.title.bn}" বইয়ের যেকোনো অধ্যায় থেকে প্রশ্ন করো — লিখে বা কথা বলে। আমি বইয়ের পৃষ্ঠা দেখিয়ে বুঝিয়ে দেব।',
      'Hello! I\'m $en. Ask me anything from "${book.title.en}" — by typing or speaking. I\'ll explain with the book\'s page numbers.',
    ),
    stats: AvatarStats(
      sessions: 40 + mixHash('s${book.id}') % 300,
      questions: 200 + mixHash('q${book.id}') % 1300,
      outOfScope: 5 + mixHash('o${book.id}') % 40,
      helpful: 60 + mixHash('h${book.id}') % 700,
      notHelpful: 2 + mixHash('n${book.id}') % 60,
    ),
  );
}

// ── State ──────────────────────────────────────────────────────────────────────

class AvatarState {
  const AvatarState({required this.avatars, required this.sessions, required this.messages, required this.reports});

  final List<BookAvatar> avatars;
  final List<AvatarSession> sessions;
  final List<AvatarMessage> messages;
  final List<AvatarReport> reports;

  BookAvatar? avatarForBook(String bookId) => avatars.where((a) => a.bookId == bookId).firstOrNull;

  /// Books a student can talk to: every book whose avatar is active.
  List<(Book, BookAvatar)> get available => [
    for (final b in sampleBooks)
      if (avatarForBook(b.id) case final a? when a.status == AvatarStatus.active) (b, a),
  ];

  List<AvatarSession> sessionsOf(String studentId) =>
      [for (final s in sessions) if (s.studentId == studentId) s]..sort((a, b) => b.lastAt.compareTo(a.lastAt));

  List<AvatarMessage> messagesOf(String sessionId) =>
      [for (final m in messages) if (m.sessionId == sessionId) m]..sort((a, b) => a.at.compareTo(b.at));

  AvatarSession? session(String id) => sessions.where((s) => s.id == id).firstOrNull;
}

/// Usage counts a guardian may see — never message text.
class AvatarUsage {
  const AvatarUsage({required this.sessions, required this.questions, required this.minutes, required this.byBook});

  final int sessions;
  final int questions;
  final int minutes;

  /// (book, sessions, questions, minutes, last activity)
  final List<(Book, int, int, int, DateTime)> byBook;
}

class AvatarController extends Notifier<AvatarState> {
  late JsonCollection<BookAvatar> _avatars;
  late JsonCollection<AvatarSession> _sessions;
  late JsonCollection<AvatarMessage> _messages;
  late JsonCollection<AvatarReport> _reports;
  final _engine = const BookAvatarEngine();

  MockSimulator get _sim => ref.read(mockSimulatorProvider);

  String get currentUserId => ref.read(avatarUserIdProvider);

  @override
  AvatarState build() {
    final store = watchStore(ref);
    _avatars = JsonCollection(store: store, name: 'book_avatars', fromJson: BookAvatar.fromJson, toJson: (a) => a.toJson(), idOf: (a) => a.id, seed: () => [for (final b in sampleBooks) defaultAvatarFor(b)]);
    _sessions = JsonCollection(store: store, name: 'avatar_sessions', fromJson: AvatarSession.fromJson, toJson: (s) => s.toJson(), idOf: (s) => s.id, seed: _seedSessions);
    _messages = JsonCollection(store: store, name: 'avatar_messages', fromJson: AvatarMessage.fromJson, toJson: (m) => m.toJson(), idOf: (m) => m.id, seed: () => const []);
    _reports = JsonCollection(store: store, name: 'avatar_reports', fromJson: AvatarReport.fromJson, toJson: (r) => r.toJson(), idOf: (r) => r.id, seed: _seedReports);
    return AvatarState(avatars: _avatars.all(), sessions: _sessions.all(), messages: _messages.all(), reports: _reports.all());
  }

  static List<AvatarSession> _seedSessions() {
    final now = DateTime.now();
    AvatarSession s(String id, String bookId, String title, int daysAgo, int msgs, int voice, int mins) => AvatarSession(
      id: id,
      bookId: bookId,
      avatarId: 'av-$bookId',
      studentId: demoStudentId,
      title: title,
      startedAt: now.subtract(Duration(days: daysAgo, minutes: mins)),
      lastAt: now.subtract(Duration(days: daysAgo)),
      messageCount: msgs,
      voiceTurns: voice,
      minutes: mins,
    );
    return [
      s('as-seed-1', 'book-ssc-gmath', 'বীজগাণিতিক রাশি', 4, 10, 2, 22),
      s('as-seed-2', 'book-ssc-chem', 'মোল ধারণা', 5, 8, 0, 17),
      s('as-seed-3', 'book-ssc-phy', 'গতি ও ত্বরণ', 6, 6, 3, 12),
    ];
  }

  static List<AvatarReport> _seedReports() {
    final now = DateTime.now();
    return [
      AvatarReport(id: 'ar-1', bookId: 'book-ssc-phy', avatarId: 'av-book-ssc-phy', studentId: 'u-gen-3', question: 'ত্বরণের একক কী?', answer: 'বেগ ও ত্বরণ — …', reason: 'উত্তরে এককটা আরও পরিষ্কার করে বলা দরকার', createdAt: now.subtract(const Duration(days: 1))),
      AvatarReport(id: 'ar-2', bookId: 'book-ssc-chem', avatarId: 'av-book-ssc-chem', studentId: 'u-gen-7', question: 'মোল কাকে বলে?', answer: 'মোল ধারণা — …', reason: 'উদাহরণ ভুল মনে হচ্ছে', createdAt: now.subtract(const Duration(days: 2))),
      AvatarReport(id: 'ar-3', bookId: 'book-ssc-gmath', avatarId: 'av-book-ssc-gmath', studentId: 'u-gen-9', question: 'বর্গের সূত্র', answer: '…', reason: 'বইয়ের পৃষ্ঠা নম্বর মেলেনি', createdAt: now.subtract(const Duration(days: 3)), status: ReportStatus.resolved, resolution: 'পৃষ্ঠা নম্বর ঠিক করা হয়েছে', resolvedBy: 'নাসরিন সুলতানা'),
    ];
  }

  void _emit() => state = AvatarState(avatars: _avatars.all(), sessions: _sessions.all(), messages: _messages.all(), reports: _reports.all());

  Future<BookAvatar> _updateAvatar(BookAvatar a) async {
    await _avatars.upsert(a);
    _emit();
    return a;
  }

  /// Avatar of a book (created on first access, like an upload would).
  BookAvatar avatarFor(Book book) => state.avatarForBook(book.id) ?? defaultAvatarFor(book);

  /// Starts a class: stores the avatar's greeting as the first message.
  Future<AvatarSession> startSession(String bookId) async {
    final book = bookById(bookId)!;
    final avatar = avatarFor(book);
    final now = DateTime.now();
    final session = AvatarSession(
      id: 'as-${now.microsecondsSinceEpoch}',
      bookId: bookId,
      avatarId: avatar.id,
      studentId: currentUserId,
      title: book.subject.name.bn,
      startedAt: now,
      lastAt: now,
    );
    await _sessions.upsert(session);
    final greeting = avatar.voice.language == 'en' ? avatar.greeting.en : avatar.greeting.bn;
    await _messages.upsert(AvatarMessage(id: 'am-${now.microsecondsSinceEpoch}', sessionId: session.id, role: AvatarRole.avatar, text: greeting, spoken: greeting, at: now, grounded: Grounding.greeting));
    await _updateAvatar(avatar.copyWith(stats: avatar.stats.copyWith(sessions: avatar.stats.sessions + 1)));
    return session;
  }

  /// Student question → book-grounded answer. Needs the network (the real AI is server-side).
  Future<AvatarMessage> ask(String sessionId, String text, {bool voice = false}) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) throw ArgumentError('EMPTY_QUESTION');
    final session = state.session(sessionId)!;
    final book = bookById(session.bookId)!;
    final avatar = avatarFor(book);
    final now = DateTime.now();
    await _messages.upsert(AvatarMessage(id: 'am-${now.microsecondsSinceEpoch}', sessionId: sessionId, role: AvatarRole.student, text: trimmed, at: now, voiceInput: voice));
    _emit();
    final a = await _sim.run(() => _engine.answer(book: book, avatar: avatar, query: trimmed), latencyFactor: 2);
    final at = DateTime.now();
    final reply = AvatarMessage(
      id: 'am-${at.microsecondsSinceEpoch}',
      sessionId: sessionId,
      role: AvatarRole.avatar,
      text: a.text,
      spoken: a.spoken,
      at: at,
      citations: a.citations,
      grounded: a.grounded,
      followUps: a.followUps,
    );
    await _messages.upsert(reply);
    final first = session.messageCount == 0;
    await _sessions.upsert(session.copyWith(
      lastAt: at,
      messageCount: session.messageCount + 2,
      voiceTurns: session.voiceTurns + (voice ? 1 : 0),
      minutes: at.difference(session.startedAt).inMinutes.clamp(1, 600),
      title: first ? (trimmed.length > 48 ? '${trimmed.substring(0, 48)}…' : trimmed) : null,
    ));
    await _updateAvatar(avatar.copyWith(
      stats: avatar.stats.copyWith(questions: avatar.stats.questions + 1, outOfScope: avatar.stats.outOfScope + (a.grounded == Grounding.outOfScope ? 1 : 0)),
    ));
    return reply;
  }

  /// Teacher/admin test chat — nothing is stored.
  Future<AvatarAnswer> preview(BookAvatar avatar, String query) => _sim.run(() => _engine.answer(book: bookById(avatar.bookId)!, avatar: avatar, query: query));

  Future<void> feedback(String messageId, String value) async {
    final m = state.messages.where((x) => x.id == messageId).firstOrNull;
    if (m == null || m.feedback == value) return;
    await _messages.upsert(m.withFeedback(value));
    final s = state.session(m.sessionId);
    final avatar = s == null ? null : state.avatars.where((a) => a.id == s.avatarId).firstOrNull;
    if (avatar != null) {
      await _avatars.upsert(avatar.copyWith(
        stats: avatar.stats.copyWith(helpful: avatar.stats.helpful + (value == 'up' ? 1 : 0), notHelpful: avatar.stats.notHelpful + (value == 'down' ? 1 : 0)),
      ));
    }
    _emit();
  }

  Future<void> report(String messageId, String reason) async {
    final m = state.messages.firstWhere((x) => x.id == messageId);
    final s = state.session(m.sessionId)!;
    final thread = state.messagesOf(s.id);
    final i = thread.indexWhere((x) => x.id == messageId);
    final question = thread.take(i).lastWhere((x) => x.role == AvatarRole.student, orElse: () => m).text;
    final now = DateTime.now();
    await _reports.upsert(AvatarReport(
      id: 'ar-${now.microsecondsSinceEpoch}',
      bookId: s.bookId,
      avatarId: s.avatarId,
      studentId: s.studentId,
      question: question,
      answer: m.text,
      reason: reason.trim(),
      createdAt: now,
    ));
    _emit();
  }

  Future<void> resolveReport(String id, ReportStatus to, String note, String by) async {
    final r = state.reports.firstWhere((x) => x.id == id);
    await _reports.upsert(r.resolve(to, note, by));
    _emit();
  }

  /// Counts only, for the guardian view.
  AvatarUsage usageFor(String studentId) {
    final mine = state.sessionsOf(studentId);
    final byBook = <String, (int, int, int, DateTime)>{};
    for (final s in mine) {
      final prev = byBook[s.bookId];
      byBook[s.bookId] = (
        (prev?.$1 ?? 0) + 1,
        (prev?.$2 ?? 0) + s.messageCount ~/ 2,
        (prev?.$3 ?? 0) + s.minutes,
        prev == null || s.lastAt.isAfter(prev.$4) ? s.lastAt : prev.$4,
      );
    }
    final rows = [
      for (final e in byBook.entries)
        if (bookById(e.key) case final b?) (b, e.value.$1, e.value.$2, e.value.$3, e.value.$4),
    ]..sort((a, b) => b.$5.compareTo(a.$5));
    return AvatarUsage(
      sessions: mine.length,
      questions: mine.fold(0, (n, s) => n + s.messageCount ~/ 2),
      minutes: mine.fold(0, (n, s) => n + s.minutes),
      byBook: rows,
    );
  }
}

/// Signed-in user's id (sessions and reports belong to it). Tests override it.
final avatarUserIdProvider = Provider<String>(
  (ref) => switch (ref.watch(authControllerProvider)) {
    Authenticated(:final user) => user.id,
    _ => demoStudentId,
  },
);

final avatarControllerProvider = NotifierProvider<AvatarController, AvatarState>(AvatarController.new);
