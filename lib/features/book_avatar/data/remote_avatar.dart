import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/env.dart';
import '../../../core/l10n/tr.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/network_providers.dart';
import '../../auth/application/auth_controller.dart';
import '../../auth/domain/app_user.dart';
import '../../library/remote_reading.dart';
import '../../parent/remote_guardian.dart';
import '../domain/avatar_models.dart';
import 'book_catalog.dart';

/// Book avatar on the education-backend: avatars and reports through `/book-avatars` and
/// `/avatar-reports`, a student's history in `/avatar-sessions/:sid` + `/avatar-messages/:sid`
/// (read-only), and everything that answers or counts through `/avatar/*`.
class RemoteAvatar {
  RemoteAvatar(this._api, this.userId);

  final ApiClient _api;
  final String userId;

  // ── Mapping (the web stores colours as #RRGGBB and snake_case enum values) ──

  static int _color(Object? v, int fallback) {
    if (v is int) return v;
    final hex = (v as String?)?.replaceFirst('#', '') ?? '';
    final n = int.tryParse(hex, radix: 16);
    return n == null ? fallback : (hex.length <= 6 ? 0xFF000000 | n : n);
  }

  static String _hex(int argb) => '#${(argb & 0xFFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase()}';

  static const _hair = {'side_part': HairStyle.sidePart};
  static const _grounding = {'out_of_scope': Grounding.outOfScope};

  static T _enum<T extends Enum>(List<T> values, Object? name, T fallback, [Map<String, T> aliases = const {}]) =>
      aliases[name] ?? values.where((v) => v.name == name).firstOrNull ?? fallback;

  static DateTime _date(Object? v) => (v is String ? DateTime.tryParse(v)?.toLocal() : null) ?? DateTime.now();

  static Tr _tr(Object? v) => v is Map ? Tr(v['bn'] as String? ?? '', v['en'] as String? ?? '') : Tr.same(v as String? ?? '');

  static AvatarAppearance appearanceFrom(Map<String, dynamic> j) => AvatarAppearance(
    gender: _enum(AvatarGender.values, j['gender'], AvatarGender.female),
    skinTone: _color(j['skinTone'], 0xFFE0AC7E),
    hairStyle: _enum(HairStyle.values, j['hairStyle'], HairStyle.short, _hair),
    hairColor: _color(j['hairColor'], 0xFF1F1A17),
    outfit: _enum(Outfit.values, j['outfit'], Outfit.shirt),
    outfitColor: _color(j['outfitColor'], 0xFF1D4ED8),
    accentColor: _color(j['accentColor'], 0xFF0F766E),
    glasses: j['glasses'] as bool? ?? false,
    beard: j['beard'] as bool? ?? false,
    background: _color(j['background'], 0xFFEEF2F6),
  );

  static Map<String, dynamic> appearanceToApi(AvatarAppearance a) => {
    'gender': a.gender.name,
    'skinTone': _hex(a.skinTone),
    'hairStyle': a.hairStyle == HairStyle.sidePart ? 'side_part' : a.hairStyle.name,
    'hairColor': _hex(a.hairColor),
    'outfit': a.outfit.name,
    'outfitColor': _hex(a.outfitColor),
    'accentColor': _hex(a.accentColor),
    'glasses': a.glasses,
    'beard': a.beard,
    'background': _hex(a.background),
  };

  /// Server book ids are language editions (`book-ssc-physics-bn`); the app's are per subject.
  static BookAvatar avatarFrom(Map<String, dynamic> j) {
    final bookId = ReadingMapper.appBookId(j['bookId'] as String);
    return BookAvatar(
      id: j['id'] as String,
      bookId: bookId,
      name: _tr(j['name']),
      title: _tr(j['title']),
      appearance: appearanceFrom((j['appearance'] as Map? ?? const {}).cast<String, dynamic>()),
      greeting: _tr(j['greeting']),
      voice: AvatarVoiceSettings.fromJson((j['voice'] as Map? ?? const {}).cast<String, dynamic>()),
      persona: AvatarPersona.fromJson((j['persona'] as Map? ?? const {}).cast<String, dynamic>()),
      scopeChapterIds: [for (final c in j['scopeChapterIds'] as List? ?? const []) c as String],
      strictBookScope: j['strictBookScope'] as bool? ?? true,
      status: _enum(AvatarStatus.values, j['status'], AvatarStatus.active),
      stats: AvatarStats.fromJson((j['stats'] as Map? ?? const {}).map((k, v) => MapEntry(k as String, (v as num?)?.round()))),
    );
  }

  static Map<String, dynamic> avatarToApi(BookAvatar a) => {
    'id': a.id,
    'bookId': ReadingMapper.serverBookId(a.bookId),
    'name': {'bn': a.name.bn, 'en': a.name.en},
    'title': {'bn': a.title.bn, 'en': a.title.en},
    'appearance': appearanceToApi(a.appearance),
    'greeting': {'bn': a.greeting.bn, 'en': a.greeting.en},
    'voice': a.voice.toJson(),
    'persona': a.persona.toJson(),
    'scopeChapterIds': a.scopeChapterIds,
    'strictBookScope': a.strictBookScope,
    'status': a.status.name,
    'stats': a.stats.toJson(),
  };

  static AvatarCitation citationFrom(Map<String, dynamic> c) => AvatarCitation(
    page: (c['page'] as num?)?.round() ?? 0,
    chapterTitle: c['chapterTitle'] as String? ?? '',
    heading: c['heading'] as String?,
    excerpt: c['excerpt'] as String? ?? '',
  );

  static AvatarMessage messageFrom(Map<String, dynamic> m) => AvatarMessage(
    id: m['id'] as String,
    sessionId: m['sessionId'] as String,
    role: m['role'] == 'avatar' ? AvatarRole.avatar : AvatarRole.student,
    text: m['text'] as String? ?? '',
    at: _date(m['at']),
    spoken: m['spoken'] as String?,
    voiceInput: m['inputMode'] == 'voice',
    citations: [for (final c in m['citations'] as List? ?? const []) citationFrom((c as Map).cast<String, dynamic>())],
    grounded: m['grounded'] == null ? null : _enum(Grounding.values, m['grounded'], Grounding.book, _grounding),
    followUps: [for (final f in m['followUps'] as List? ?? const []) f as String],
    feedback: m['feedback'] as String?,
  );

  static AvatarSession sessionFrom(Map<String, dynamic> s) => AvatarSession(
    id: s['id'] as String,
    bookId: ReadingMapper.appBookId(s['bookId'] as String),
    avatarId: s['avatarId'] as String? ?? '',
    studentId: s['studentId'] as String? ?? '',
    title: s['title'] as String? ?? '',
    startedAt: _date(s['startedAt']),
    lastAt: _date(s['lastAt']),
    messageCount: (s['messageCount'] as num?)?.round() ?? 0,
    voiceTurns: (s['voiceTurns'] as num?)?.round() ?? 0,
    minutes: (s['minutes'] as num?)?.round() ?? 0,
  );

  static AvatarReport reportFrom(Map<String, dynamic> r) => AvatarReport(
    id: r['id'] as String,
    bookId: ReadingMapper.appBookId(r['bookId'] as String? ?? ''),
    avatarId: r['avatarId'] as String? ?? '',
    studentId: r['studentId'] as String? ?? '',
    question: r['question'] as String? ?? '',
    answer: r['answer'] as String? ?? '',
    reason: r['reason'] as String? ?? '',
    createdAt: _date(r['createdAt']),
    status: _enum(ReportStatus.values, r['status'], ReportStatus.open),
    resolution: r['resolution'] as String?,
    resolvedBy: r['resolvedBy'] as String?,
  );

  static AvatarAnswer answerFrom(Map<String, dynamic> a) => AvatarAnswer(
    text: a['text'] as String? ?? '',
    spoken: a['spoken'] as String? ?? '',
    citations: [for (final c in a['citations'] as List? ?? const []) citationFrom((c as Map).cast<String, dynamic>())],
    grounded: _enum(Grounding.values, a['grounded'], Grounding.book, _grounding),
    followUps: [for (final f in a['followUps'] as List? ?? const []) f as String],
  );

  // ── Requests ──────────────────────────────────────────────────────────

  List<Map<String, dynamic>> _list(Object? d) => [for (final x in d! as List) (x as Map).cast<String, dynamic>()];
  Map<String, dynamic> _map(Object? d) => (d! as Map).cast<String, dynamic>();

  Future<List<Map<String, dynamic>>> _all(String path) async => (await _api.get(path, query: {'all': true}, parse: _list)).data;

  Future<List<BookAvatar>> avatars() async => [for (final a in await _all('/book-avatars')) avatarFrom(a)];

  Future<List<AvatarReport>> reports() async => [for (final r in await _all('/avatar-reports')) reportFrom(r)];

  /// The student's sessions and messages.
  Future<(List<AvatarSession>, List<AvatarMessage>)> history() async {
    final (s, m) = await (_all('/avatar-sessions/$userId'), _all('/avatar-messages/$userId')).wait;
    return ([for (final x in s) sessionFrom(x)], [for (final x in m) messageFrom(x)]);
  }

  Future<(AvatarSession, AvatarMessage)> startSession(String bookId) async {
    final r = (await _api.post('/avatar/$userId/sessions', body: {'bookId': ReadingMapper.serverBookId(bookId)}, parse: _map)).data;
    return (sessionFrom(_map(r['session'])), messageFrom(_map(r['greeting'])));
  }

  Future<(AvatarMessage, AvatarMessage)> ask(String sessionId, String text, {bool voice = false}) async {
    final r = (await _api.post('/avatar/$userId/sessions/$sessionId/messages', body: {'text': text, 'inputMode': voice ? 'voice' : 'text'}, parse: _map)).data;
    return (messageFrom(_map(r['question'])), messageFrom(_map(r['reply'])));
  }

  Future<AvatarMessage> feedback(String messageId, String value) async =>
      messageFrom((await _api.post('/avatar/$userId/messages/$messageId/feedback', body: {'value': value}, parse: _map)).data);

  Future<AvatarReport> report(String messageId, String reason) async =>
      reportFrom((await _api.post('/avatar/$userId/messages/$messageId/report', body: {'reason': reason}, parse: _map)).data);

  Future<void> resolveReport(String id, ReportStatus to, String note, String by) =>
      _api.patch('/avatar-reports/$id', body: {'status': to.name, 'resolution': note, 'resolvedBy': by}, parse: (d) => d);

  Future<AvatarAnswer> preview(BookAvatar avatar, String query) async =>
      answerFrom((await _api.post('/avatar/preview', body: {'avatar': avatarToApi(avatar), 'query': query}, parse: _map)).data);

  /// Session counts per (app) book id for one student.
  Future<List<Map<String, dynamic>>> usage(String studentId) async => (await _api.get('/avatar/$studentId/usage', parse: _list)).data;
}

/// The signed-in user's avatar data on the server (API mode); null with the mock.
final remoteAvatarProvider = Provider<RemoteAvatar?>((ref) {
  if (Env.useMockApi) return null;
  final auth = ref.watch(authControllerProvider);
  if (auth is! Authenticated) return null;
  return RemoteAvatar(ref.watch(apiClientProvider), auth.user.id);
});

/// Guardian (API mode): the linked children's avatar usage, summed per book (counts only).
final guardianAvatarUsageProvider = FutureProvider<List<(Book, int, int, int, DateTime)>?>((ref) async {
  final avatar = ref.watch(remoteAvatarProvider);
  final guardian = ref.watch(remoteGuardianProvider);
  final auth = ref.watch(authControllerProvider);
  if (avatar == null || guardian == null || auth is! Authenticated || auth.user.role != UserRole.parent) return null;
  final links = [
    for (final l in await guardian.links())
      if (l['status'] == 'active') l['studentId'] as String,
  ];
  final rows = <String, (int, int, int, DateTime)>{};
  for (final sid in links) {
    final List<Map<String, dynamic>> usage;
    try {
      usage = await avatar.usage(sid);
    } on Exception {
      continue; // The link doesn't share study time.
    }
    for (final u in usage) {
      final id = ReadingMapper.appBookId(u['bookId'] as String);
      final last = DateTime.tryParse(u['lastAt'] as String? ?? '')?.toLocal() ?? DateTime.now();
      final p = rows[id];
      rows[id] = (
        (p?.$1 ?? 0) + ((u['sessions'] as num?)?.round() ?? 0),
        (p?.$2 ?? 0) + ((u['questions'] as num?)?.round() ?? 0),
        (p?.$3 ?? 0) + ((u['minutes'] as num?)?.round() ?? 0),
        p == null || last.isAfter(p.$4) ? last : p.$4,
      );
    }
  }
  return [
    for (final e in rows.entries)
      if (bookById(e.key) case final b?) (b, e.value.$1, e.value.$2, e.value.$3, e.value.$4),
  ]..sort((a, b) => b.$5.compareTo(a.$5));
});
