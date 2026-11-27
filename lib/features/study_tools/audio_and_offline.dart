import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/router/app_routes.dart';
import '../../core/l10n/tr.dart';
import '../../core/mock/mock_simulator.dart';
import '../../core/network/api_exception.dart';
import '../../core/network/network_providers.dart';
import '../../core/settings/app_settings.dart';
import '../../core/storage/local_store.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/time_format.dart';
import '../../mock/seed/curriculum_seed.dart';
import '../../mock/seed/tutor_knowledge_seed.dart';
import '../../shared/widgets/app_page_scaffold.dart';
import '../../shared/widgets/badges.dart';
import '../../shared/widgets/empty_state.dart';
import '../../shared/widgets/feedback.dart';
import '../../shared/widgets/section_header.dart';
import '../ai_tools/remote_ai_tools.dart';
import '../book_avatar/application/avatar_voice.dart';
import '../curriculum/data/curriculum_repository.dart';
import '../book_avatar/data/book_avatar_engine.dart';
import '../book_avatar/data/book_catalog.dart';
import '../curriculum/domain/curriculum_models.dart';
import '../flashcards/application/flashcards_controller.dart';
import '../library/library_controller.dart';
import '../notes/application/notes_controller.dart';
import '../profile/application/student_profile_controller.dart';
import '../question_bank/application/practice_controller.dart';

abstract final class AudioStrings {
  static const title = Tr('অডিও রিভিশন', 'Audio revision');
  static const hint = Tr('চলার পথে শুনে রিভিশন — প্রতিটি টপিকের ছোট অডিও লেসন।', 'Revise on the go — short audio lessons per topic.');
  static const continueListening = Tr('শোনা চালিয়ে যাও', 'Continue listening');
  static const favorites = Tr('প্রিয়', 'Favourites');
  static const all = Tr('সব লেসন', 'All lessons');
  static const byChapter = Tr('অধ্যায়ভিত্তিক', 'By chapter');
  static const podcasts = Tr('রিভিশন পডকাস্ট', 'Revision podcasts');
  static const podcastOf = Tr('{c} — পুরো অধ্যায় ({n}টি লেসন)', '{c} — whole chapter ({n} lessons)');
  static const history = Tr('শোনার ইতিহাস', 'Listening history');
  static const downloads = Tr('ডাউনলোড', 'Downloads');
  static const transcript = Tr('ট্রান্সক্রিপ্ট', 'Transcript');
  static const summary = Tr('সারাংশ', 'Summary');
  static const markers = Tr('অধ্যায় চিহ্ন', 'Chapter markers');
  static const speed = Tr('গতি', 'Speed');
  static const voice = Tr('কণ্ঠ', 'Voice');
  static const female = Tr('নারী', 'Female');
  static const male = Tr('পুরুষ', 'Male');
  static const playlist = Tr('প্লেলিস্ট ({n})', 'Playlist ({n})');
  static const playAll = Tr('সব চালাও', 'Play all');
  static const next = Tr('পরের লেসন', 'Next lesson');
  static const download = Tr('ডাউনলোড', 'Download');
  static const downloaded = Tr('ডাউনলোড করা', 'Downloaded');
  static const generate = Tr('AI দিয়ে অডিও লেসন তৈরি করো', 'Generate an audio lesson with AI');
  static const generated = Tr('নতুন অডিও লেসন তৈরি হয়েছে', 'New audio lesson created');
  static const pickTopic = Tr('টপিক বেছে নাও', 'Pick a topic');
  static const sectionTitle = Tr('শিরোনাম', 'Title');
  static const sectionDefinition = Tr('সংজ্ঞা', 'Definition');
  static const sectionExplain = Tr('ব্যাখ্যা', 'Explanation');
  static const sectionPoints = Tr('মূল পয়েন্ট', 'Key points');
  static const sectionExample = Tr('উদাহরণ', 'Example');
  static const offline = Tr('অফলাইন ডাউনলোড', 'Offline downloads');
  static const offlineHint = Tr('ইন্টারনেট ছাড়া যা ব্যবহার করা যায়। AI টিউটর ও অ্যাভাটারের জন্য ইন্টারনেট লাগে।', 'What you can use without internet. The AI tutor and avatar need internet.');
  static const online = Tr('অনলাইন', 'Online');
  static const offlineNow = Tr('অফলাইন (সিমুলেটেড)', 'Offline (simulated)');
  static const toggle = Tr('অফলাইন সিমুলেশন', 'Simulate offline');
  static const books = Tr('ডাউনলোড করা বই', 'Downloaded books');
  static const noBooks = Tr('কোনো বই ডাউনলোড করা নেই', 'No books downloaded');
  static const browse = Tr('লাইব্রেরিতে যাও', 'Open the library');
  static const remove = Tr('মুছুন', 'Remove');
  static const audioLessons = Tr('ডাউনলোড করা অডিও', 'Downloaded audio');
  static const alwaysOffline = Tr('সবসময় অফলাইনে', 'Always available offline');
  static const notes = Tr('{n}টি নোট', '{n} notes');
  static const decks = Tr('{n}টি ফ্ল্যাশকার্ড ডেক', '{n} flashcard decks');
  static const quizzes = Tr('অফলাইন কুইজ: {n}টি সংরক্ষিত প্রশ্ন', 'Offline quizzes: {n} saved questions');
  static const startQuiz = Tr('কুইজ শুরু', 'Start quiz');
  static const storage = Tr('স্টোরেজ ব্যবহার: {n} KB', 'Storage used: {n} KB');
  static const sizeKb = Tr('{n} KB', '{n} KB');
  static const sync = Tr('সিঙ্ক', 'Sync');
  static const lastSync = Tr('শেষ সিঙ্ক: {t}', 'Last sync: {t}');
  static const never = Tr('কখনো নয়', 'never');
  static const syncNow = Tr('এখন সিঙ্ক করো', 'Sync now');
  static const retry = Tr('আবার চেষ্টা', 'Retry');
  static const syncFailed = Tr('সিঙ্ক হয়নি — সংযোগ পেলে আবার চেষ্টা করো', 'Sync failed — retry when you are connected');
  static const synced = Tr('সিঙ্ক সম্পন্ন — কোনো দ্বন্দ্ব নেই', 'Synced — no conflicts');
  static const conflictFound = Tr('সিঙ্ক দ্বন্দ্ব পাওয়া গেছে', 'Sync conflict found');
  static const conflict = Tr('“{t}” নোটটি এই ফোনে আর অন্য ডিভাইসে আলাদাভাবে বদলানো হয়েছে।', 'The note “{t}” was changed on this phone and on another device.');
  static const keepMine = Tr('এই ফোনেরটা রাখো', 'Keep this phone’s');
  static const keepServer = Tr('অন্য ডিভাইসেরটা রাখো', 'Keep the other device’s');
  static const keepBoth = Tr('দুটোই রাখো', 'Keep both');
  static const resolved = Tr('দ্বন্দ্ব মীমাংসা হয়েছে', 'Conflict resolved');
  static const simulateConflict = Tr('দ্বন্দ্ব সিমুলেট করো (ডেমো)', 'Simulate a conflict (demo)');
  static const thisPhone = Tr('এই ফোন', 'This phone');
  static const otherDevice = Tr('অন্য ডিভাইস', 'Other device');
  static const version = Tr('কনটেন্ট সংস্করণ: NCTB 2025 (নমুনা)', 'Content version: NCTB 2025 (sample)');
  static const aiOffline = Tr('অফলাইনে AI টিউটর, ভয়েস টিউটর, অ্যাভাটার ও ছবি থেকে সমাধান কাজ করে না। ডাউনলোড করা বই, নোট, ফ্ল্যাশকার্ড ও সংরক্ষিত প্রশ্ন চলবে।', 'Offline, the AI tutor, voice tutor, avatar and photo solver do not work. Downloaded books, notes, flashcards and saved questions do.');
  static const available = Tr('অফলাইনে চলবে', 'Works offline');
  static const needsNet = Tr('ইন্টারনেট লাগে', 'Needs internet');
  static const appStorage = Tr('অ্যাপের নিজস্ব স্টোরেজে সংরক্ষিত — ব্রাউজার ক্যাশ লাগে না', "Stored in the app's own storage — no browser cache needed");
}

/// One playable lesson: a topic passage split into sections (chapter markers).
class AudioLesson {
  const AudioLesson({required this.id, required this.title, required this.subjectId, required this.chapterId, required this.sections, this.generated = false});

  final String id;
  final Tr title;
  final String subjectId;
  final String chapterId;
  final List<(Tr marker, Tr text)> sections;
  final bool generated;

  String transcript(AppLanguage l) => [for (final (_, t) in sections) t.of(l)].join('\n\n');
}

AudioLesson lessonFromScenario(TutorScenario s) => AudioLesson(
  id: s.id,
  title: s.title,
  subjectId: s.subjectId,
  chapterId: s.chapterId,
  sections: [
    (AudioStrings.sectionTitle, s.title),
    (AudioStrings.sectionDefinition, s.definition),
    (AudioStrings.sectionExplain, s.excerpt),
    (AudioStrings.sectionPoints, Tr(s.keyPoints.map((k) => k.bn).join('। '), s.keyPoints.map((k) => k.en).join('. '))),
    (AudioStrings.sectionExample, s.example),
  ],
);

AudioLesson lessonFromTopic(Subject s, Chapter c, Topic t) => AudioLesson(
  id: 'gen-${t.id}',
  title: t.title,
  subjectId: s.id,
  chapterId: c.id,
  generated: true,
  sections: [
    (AudioStrings.sectionTitle, t.title),
    (AudioStrings.sectionExplain, c.description),
    (AudioStrings.sectionPoints, Tr(t.outcomes.map((o) => o.text.bn).join('। '), t.outcomes.map((o) => o.text.en).join('. '))),
  ],
);

/// Per-lesson listening progress (0–1), favourites, downloads, history and generated lessons.
class AudioState {
  const AudioState({this.progress = const {}, this.favorites = const {}, this.lastId, this.downloads = const {}, this.history = const [], this.generatedTopics = const []});

  final Map<String, double> progress;
  final Set<String> favorites;
  final String? lastId;
  final Set<String> downloads;

  /// (lesson id, when) newest first.
  final List<(String, DateTime)> history;
  final List<String> generatedTopics;

  AudioState copyWith({Map<String, double>? progress, Set<String>? favorites, String? lastId, Set<String>? downloads, List<(String, DateTime)>? history, List<String>? generatedTopics}) => AudioState(
    progress: progress ?? this.progress,
    favorites: favorites ?? this.favorites,
    lastId: lastId ?? this.lastId,
    downloads: downloads ?? this.downloads,
    history: history ?? this.history,
    generatedTopics: generatedTopics ?? this.generatedTopics,
  );
}

class AudioController extends Notifier<AudioState> {
  static const _col = 'audio';
  late LocalStore _store;

  @override
  AudioState build() {
    _store = watchStore(ref);
    final d = _store.get(_col, 'me');
    if (d == null) return const AudioState();
    return AudioState(
      progress: (d['progress'] as Map? ?? const {}).map((k, v) => MapEntry(k as String, (v as num).toDouble())),
      favorites: {...(d['favorites'] as List? ?? const []).cast<String>()},
      lastId: d['lastId'] as String?,
      downloads: {...(d['downloads'] as List? ?? const []).cast<String>()},
      history: [for (final h in d['history'] as List? ?? const []) ((h as Map)['id'] as String, DateTime.parse(h['at'] as String))],
      generatedTopics: (d['generated'] as List? ?? const []).cast<String>(),
    );
  }

  Future<void> _save(AudioState s) async {
    state = s;
    await _store.put(_col, 'me', {
      'progress': s.progress,
      'favorites': s.favorites.toList(),
      'lastId': s.lastId,
      'downloads': s.downloads.toList(),
      'history': [for (final (id, at) in s.history) {'id': id, 'at': at.toIso8601String()}],
      'generated': s.generatedTopics,
    });
  }

  Future<void> setProgress(String id, double p) => _save(state.copyWith(progress: {...state.progress, id: p.clamp(0, 1)}, lastId: id));

  Future<void> started(String id) => _save(state.copyWith(lastId: id, history: [(id, DateTime.now()), ...state.history.where((h) => h.$1 != id)].take(30).toList()));

  Future<void> toggleFavorite(String id) => _save(state.copyWith(favorites: state.favorites.contains(id) ? ({...state.favorites}..remove(id)) : {...state.favorites, id}));

  Future<void> toggleDownload(String id) => _save(state.copyWith(downloads: state.downloads.contains(id) ? ({...state.downloads}..remove(id)) : {...state.downloads, id}));

  Future<void> generate(String topicId) async {
    final remote = ref.read(remoteAiToolsProvider);
    if (remote != null) {
      // API mode: the AI service writes a lesson for the topic's chapter (saved on the server).
      final chapterId = ref.read(curriculumRepositoryProvider).findTopic(topicId)?.chapter.id;
      if (chapterId == null) return;
      await remote.audioLesson(chapterId);
      ref.invalidate(serverAudioLessonsProvider);
      return;
    }
    await ref.read(mockSimulatorProvider).run(() {}, latencyFactor: 2);
    if (state.generatedTopics.contains(topicId)) return;
    await _save(state.copyWith(generatedTopics: [topicId, ...state.generatedTopics]));
  }
}

final audioProvider = NotifierProvider<AudioController, AudioState>(AudioController.new);

/// API mode: the server's lesson catalogue (chapter lessons, podcasts and AI-generated ones).
final serverAudioLessonsProvider = FutureProvider<List<AudioLesson>?>((ref) async {
  if (ref.watch(remoteAiToolsProvider) == null) return null;
  final res = await ref.read(apiClientProvider).get('/audio-lessons', query: {'all': true}, parse: (d) => [for (final x in d! as List) (x as Map).cast<String, dynamic>()]);
  return [for (final j in res.data) audioLessonFromApi(j)];
});

AudioLesson audioLessonFromApi(Map<String, dynamic> j) {
  final title = j['title'];
  return AudioLesson(
    id: j['id'] as String,
    title: title is Map ? Tr(title['bn'] as String? ?? '', title['en'] as String? ?? '') : Tr.same('$title'),
    subjectId: j['subjectId'] as String? ?? '',
    chapterId: j['chapterId'] as String? ?? '',
    generated: j['kind'] == 'generated',
    sections: [
      for (final seg in j['segments'] as List? ?? const []) (Tr.same((seg as Map)['title'] as String? ?? ''), Tr.same(seg['text'] as String? ?? '')),
    ],
  );
}

/// Every lesson: the server's catalogue in API mode, else the textbook passages plus the
/// student's generated ones.
final audioLessonsProvider = Provider<List<AudioLesson>>((ref) {
  final server = ref.watch(serverAudioLessonsProvider).value;
  if (server != null) return [...server.where((l) => l.generated), ...server.where((l) => !l.generated)];
  final generated = ref.watch(audioProvider.select((s) => s.generatedTopics));
  final out = [for (final s in tutorScenarios) lessonFromScenario(s)];
  for (final id in generated) {
    for (final s in seedSubjects) {
      for (final c in s.chapters) {
        for (final t in c.topics) {
          if (t.id == id) out.insert(0, lessonFromTopic(s, c, t));
        }
      }
    }
  }
  return out;
});

class AudioRevisionScreen extends ConsumerStatefulWidget {
  const AudioRevisionScreen({super.key});

  @override
  ConsumerState<AudioRevisionScreen> createState() => _AudioRevisionScreenState();
}

class _AudioRevisionScreenState extends ConsumerState<AudioRevisionScreen> {
  late final AvatarVoice _voice;
  String? _playing;
  double _rate = 1;
  bool _male = false;
  Timer? _ticker;
  bool _favOnly = false;
  List<String> _queue = const [];

  @override
  void initState() {
    super.initState();
    _voice = ref.read(avatarVoiceProvider);
  }

  @override
  void dispose() {
    _ticker?.cancel();
    unawaited(_voice.stopSpeaking());
    super.dispose();
  }

  AudioLesson? _lesson(String? id) => ref.read(audioLessonsProvider).where((l) => l.id == id).firstOrNull;

  Future<void> _stop() async {
    _ticker?.cancel();
    await _voice.stopSpeaking();
    if (mounted) setState(() => _playing = null);
  }

  Future<void> _play(AudioLesson s, {double? from}) async {
    if (_playing == s.id && from == null) return _stop();
    final appLang = context.lang;
    final lang = appLang == AppLanguage.bn ? 'bn' : 'en';
    await _stop();
    if (!mounted) return;
    final text = BookAvatarEngine.toSpoken(s.transcript(appLang), lang);
    final ctrl = ref.read(audioProvider.notifier);
    var p = from ?? ref.read(audioProvider).progress[s.id] ?? 0;
    if (p >= 0.99) p = 0;
    await ctrl.started(s.id);
    await ctrl.setProgress(s.id, p);
    if (!mounted) return;
    setState(() => _playing = s.id);
    // Progress advances at roughly reading speed (also while the device speaks).
    final totalMs = (text.length / 13 / _rate * 1000).clamp(3000, 120000);
    _ticker = Timer.periodic(const Duration(milliseconds: 500), (t) {
      p = (p + 500 / totalMs).clamp(0, 1);
      unawaited(ctrl.setProgress(s.id, p));
      if (p >= 1) unawaited(_finished(s.id));
    });
    final start = (text.length * p).floor().clamp(0, text.length);
    unawaited(_voice.speak(text.substring(start), lang: lang, rate: _rate, pitch: _male ? 0.8 : 1.1));
  }

  /// Playlist: moves to the next queued lesson.
  Future<void> _finished(String id) async {
    await _stop();
    final i = _queue.indexOf(id);
    if (i >= 0 && i + 1 < _queue.length && mounted) {
      final next = _lesson(_queue[i + 1]);
      if (next != null) await _play(next, from: 0);
    }
  }

  void _playAll(List<AudioLesson> lessons) {
    if (lessons.isEmpty) return;
    setState(() => _queue = [for (final l in lessons) l.id]);
    unawaited(_play(lessons.first, from: 0));
  }

  Future<void> _generate() async {
    final level = ref.read(studentProfileProvider).level;
    final topics = [for (final s in seedSubjects) if (s.level == level) for (final c in s.chapters) for (final t in c.topics) (s, c, t)];
    final picked = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) => SizedBox(
        height: MediaQuery.sizeOf(ctx).height * 0.7,
        child: ListView(
          children: [
            Padding(padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg), child: Text(ctx.tr(AudioStrings.pickTopic), style: Theme.of(ctx).textTheme.titleMedium)),
            for (final (s, c, t) in topics.take(60)) ListTile(key: Key('gen.${t.id}'), title: Text(ctx.tr(t.title)), subtitle: Text('${ctx.tr(s.name)} · ${ctx.tr(c.title)}'), onTap: () => Navigator.pop(ctx, t.id)),
          ],
        ),
      ),
    );
    if (picked == null) return;
    try {
      await ref.read(audioProvider.notifier).generate(picked);
      if (mounted) context.showSnack(AudioStrings.generated);
    } on ApiException catch (e) {
      if (mounted) context.showErrorSnack(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final audio = ref.watch(audioProvider);
    final all = ref.watch(audioLessonsProvider);
    final lessons = [for (final s in all) if (!_favOnly || audio.favorites.contains(s.id)) s];
    final last = all.where((s) => s.id == audio.lastId).firstOrNull;
    final playing = all.where((s) => s.id == _playing).firstOrNull;
    final text = Theme.of(context).textTheme;
    final byChapter = <String, List<AudioLesson>>{};
    for (final l in all) {
      (byChapter[l.chapterId] ??= []).add(l);
    }
    final podcasts = [for (final e in byChapter.entries) if (e.value.length >= 2) e];
    Chapter? chapterOf(String subjectId, String chapterId) => subjectById(subjectId)?.chapters.where((c) => c.id == chapterId).firstOrNull;
    return DefaultTabController(
      length: 4,
      child: AppPageScaffold(
        title: context.tr(AudioStrings.title),
        scrollable: false,
        bottom: TabBar(
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          tabs: [Tab(text: context.tr(AudioStrings.all)), Tab(text: context.tr(AudioStrings.byChapter)), Tab(text: context.tr(AudioStrings.history)), Tab(text: context.tr(AudioStrings.downloads))],
        ),
        bottomBar: playing == null ? null : _PlayerBar(lesson: playing, onStop: _stop, onSeek: (v) => _play(playing, from: v), queue: _queue, onNext: () => _finished(playing.id)),
        body: TabBarView(
          children: [
            ListView(
              children: [
                Text(context.tr(AudioStrings.hint)),
                const SizedBox(height: AppSpacing.sm),
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: AppSpacing.xs,
                  children: [
                    Text(context.tr(AudioStrings.speed)),
                    for (final r in const [0.75, 1.0, 1.25, 1.5]) ChoiceChip(label: Text('${context.n(r)}×'), selected: _rate == r, onSelected: (_) => setState(() => _rate = r)),
                  ],
                ),
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: AppSpacing.xs,
                  children: [
                    Text(context.tr(AudioStrings.voice)),
                    ChoiceChip(label: Text(context.tr(AudioStrings.female)), selected: !_male, onSelected: (_) => setState(() => _male = false)),
                    ChoiceChip(label: Text(context.tr(AudioStrings.male)), selected: _male, onSelected: (_) => setState(() => _male = true)),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                OutlinedButton.icon(key: const Key('audio.generate'), onPressed: _generate, icon: const Icon(Icons.auto_awesome), label: Text(context.tr(AudioStrings.generate))),
                if (last != null && (audio.progress[last.id] ?? 0) < 1) ...[
                  SectionHeader(title: context.tr(AudioStrings.continueListening)),
                  _LessonTile(lesson: last, playing: _playing == last.id, onPlay: () => _play(last)),
                ],
                SectionHeader(
                  title: context.tr(_favOnly ? AudioStrings.favorites : AudioStrings.all),
                  actionLabel: context.tr(_favOnly ? AudioStrings.all : AudioStrings.favorites),
                  onAction: () => setState(() => _favOnly = !_favOnly),
                ),
                if (lessons.isEmpty) EmptyState(title: context.tr(AudioStrings.favorites), compact: true, icon: Icons.favorite_border),
                for (final s in lessons) _LessonTile(lesson: s, playing: _playing == s.id, onPlay: () => _play(s)),
                if (playing != null) ...[
                  SectionHeader(title: context.tr(AudioStrings.markers)),
                  Wrap(
                    spacing: AppSpacing.xs,
                    children: [
                      for (final (i, (marker, _)) in playing.sections.indexed)
                        ActionChip(key: Key('marker.$i'), label: Text(context.tr(marker)), onPressed: () => _play(playing, from: i / playing.sections.length)),
                    ],
                  ),
                  SectionHeader(title: context.tr(AudioStrings.summary)),
                  for (final (marker, t) in playing.sections.skip(1)) ListTile(dense: true, contentPadding: EdgeInsets.zero, title: Text(context.tr(marker), style: text.labelLarge), subtitle: Text(context.tr(t), maxLines: 2, overflow: TextOverflow.ellipsis)),
                  SectionHeader(title: context.tr(AudioStrings.transcript)),
                  Text(playing.transcript(context.lang), style: text.bodyMedium),
                ],
              ],
            ),
            ListView(
              children: [
                SectionHeader(title: context.tr(AudioStrings.podcasts)),
                for (final e in podcasts)
                  Card(
                    margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: ListTile(
                      key: Key('podcast.${e.key}'),
                      leading: const Icon(Icons.podcasts),
                      title: Text(context.tr(AudioStrings.podcastOf.fill({'c': context.tr(chapterOf(e.value.first.subjectId, e.key)?.title ?? e.value.first.title), 'n': e.value.length}))),
                      trailing: IconButton.filledTonal(icon: const Icon(Icons.playlist_play), tooltip: context.tr(AudioStrings.playAll), onPressed: () => _playAll(e.value)),
                    ),
                  ),
                for (final e in byChapter.entries) ...[
                  SectionHeader(title: context.tr(chapterOf(e.value.first.subjectId, e.key)?.title ?? const Tr.same('—'))),
                  for (final l in e.value) _LessonTile(lesson: l, playing: _playing == l.id, onPlay: () => _play(l)),
                ],
              ],
            ),
            ListView(
              children: [
                if (audio.history.isEmpty) EmptyState(title: context.tr(AudioStrings.history), compact: true, icon: Icons.history),
                for (final (id, at) in audio.history)
                  if (all.where((l) => l.id == id).firstOrNull case final l?)
                    ListTile(
                      leading: const Icon(Icons.history),
                      title: Text(context.tr(l.title)),
                      subtitle: Text('${relativeTime(at, context.lang)} · ${context.pct((audio.progress[id] ?? 0) * 100)}'),
                      onTap: () => _play(l),
                    ),
              ],
            ),
            ListView(
              children: [
                if (audio.downloads.isEmpty) EmptyState(title: context.tr(AudioStrings.downloads), compact: true, icon: Icons.download_outlined),
                for (final l in all.where((l) => audio.downloads.contains(l.id))) _LessonTile(lesson: l, playing: _playing == l.id, onPlay: () => _play(l)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PlayerBar extends ConsumerWidget {
  const _PlayerBar({required this.lesson, required this.onStop, required this.onSeek, required this.queue, required this.onNext});

  final AudioLesson lesson;
  final VoidCallback onStop;
  final ValueChanged<double> onSeek;
  final List<String> queue;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = ref.watch(audioProvider.select((s) => s.progress[lesson.id] ?? 0));
    final i = queue.indexOf(lesson.id);
    return Material(
      elevation: 6,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.xs, AppSpacing.md, AppSpacing.xs),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  IconButton(onPressed: onStop, icon: const Icon(Icons.pause_circle_filled, size: 32)),
                  Expanded(child: Text(context.tr(lesson.title), maxLines: 1, overflow: TextOverflow.ellipsis)),
                  if (i >= 0) Text(context.tr(AudioStrings.playlist.fill({'n': '${i + 1}/${queue.length}'})), style: Theme.of(context).textTheme.labelSmall),
                  if (i >= 0 && i + 1 < queue.length) IconButton(tooltip: context.tr(AudioStrings.next), onPressed: onNext, icon: const Icon(Icons.skip_next)),
                ],
              ),
              Slider(key: const Key('audio.seek'), value: p, onChanged: onSeek),
            ],
          ),
        ),
      ),
    );
  }
}

class _LessonTile extends ConsumerWidget {
  const _LessonTile({required this.lesson, required this.playing, required this.onPlay});

  final AudioLesson lesson;
  final bool playing;
  final VoidCallback onPlay;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final a = ref.watch(audioProvider);
    final p = a.progress[lesson.id] ?? 0;
    final subject = subjectById(lesson.subjectId);
    final dl = a.downloads.contains(lesson.id);
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: ListTile(
        key: Key('audio.${lesson.id}'),
        leading: IconButton.filledTonal(onPressed: onPlay, icon: Icon(playing ? Icons.pause : Icons.play_arrow)),
        title: Row(children: [Expanded(child: Text(context.tr(lesson.title))), if (lesson.generated) const Icon(Icons.auto_awesome, size: 14)]),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (subject != null) Text(context.tr(subject.name)),
            const SizedBox(height: AppSpacing.xxs),
            LinearProgressIndicator(value: p, minHeight: 3),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              key: Key('audio.dl.${lesson.id}'),
              tooltip: context.tr(dl ? AudioStrings.downloaded : AudioStrings.download),
              onPressed: () => ref.read(audioProvider.notifier).toggleDownload(lesson.id),
              icon: Icon(dl ? Icons.download_done : Icons.download_outlined),
            ),
            IconButton(onPressed: () => ref.read(audioProvider.notifier).toggleFavorite(lesson.id), icon: Icon(a.favorites.contains(lesson.id) ? Icons.favorite : Icons.favorite_border)),
          ],
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// Offline
// ═════════════════════════════════════════════════════════════════════════════

class OfflineScreen extends ConsumerStatefulWidget {
  const OfflineScreen({super.key});

  @override
  ConsumerState<OfflineScreen> createState() => _OfflineScreenState();
}

class _OfflineScreenState extends ConsumerState<OfflineScreen> {
  bool _syncing = false;
  bool _failed = false;
  String? _conflictNoteId;

  Future<void> _sync() async {
    final store = ref.read(localStoreProvider);
    setState(() {
      _syncing = true;
      _failed = false;
    });
    try {
      await ref.read(mockSimulatorProvider).run(() => store.put('sync', 'meta', {'at': DateTime.now().toIso8601String()}), latencyFactor: 2);
      if (mounted) context.showSnack(_conflictNoteId == null ? AudioStrings.synced : AudioStrings.conflictFound);
    } on ApiException catch (e) {
      if (mounted) {
        setState(() => _failed = true);
        context.showErrorSnack(e);
      }
    } finally {
      if (mounted) setState(() => _syncing = false);
    }
  }

  Future<void> _resolve(String choice) async {
    final notes = ref.read(notesProvider);
    final n = notes.where((x) => x.id == _conflictNoteId).firstOrNull;
    final device = context.tr(AudioStrings.otherDevice);
    if (n != null) {
      final other = '${n.body}\n\n($device) ✎';
      final ctl = ref.read(notesProvider.notifier);
      if (choice == 'server') await ctl.save(n.id, body: other, snapshot: true);
      if (choice == 'both') await ctl.create(title: '${n.title} ($device)', body: other, chapterId: n.chapterId);
    }
    if (mounted) {
      setState(() => _conflictNoteId = null);
      context.showSnack(AudioStrings.resolved);
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(appSettingsProvider);
    final reading = ref.watch(libraryProvider);
    final notes = ref.watch(notesProvider);
    final decks = ref.watch(flashcardsProvider).decks;
    final bookmarks = ref.watch(practiceProvider).bookmarks;
    final audio = ref.watch(audioProvider);
    final lessons = ref.watch(audioLessonsProvider);
    final store = ref.watch(localStoreProvider);
    final lastSync = store.get('sync', 'meta')?['at'] as String?;
    final books = [for (final r in reading.values) if (r.downloaded) ?bookById(r.bookId)];
    final conflictNote = notes.where((n) => n.id == _conflictNoteId).firstOrNull;
    return AppPageScaffold(
      title: context.tr(AudioStrings.offline),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(context.tr(AudioStrings.offlineHint)),
          const SizedBox(height: AppSpacing.sm),
          Card(
            margin: EdgeInsets.zero,
            child: SwitchListTile(
              key: const Key('offline.toggle'),
              secondary: Icon(settings.simulateOffline ? Icons.cloud_off : Icons.cloud_done_outlined),
              title: Text(context.tr(settings.simulateOffline ? AudioStrings.offlineNow : AudioStrings.online)),
              subtitle: Text(context.tr(AudioStrings.toggle)),
              value: settings.simulateOffline,
              onChanged: (v) => ref.read(appSettingsProvider.notifier).update((s) => s.copyWith(simulateOffline: v)),
            ),
          ),
          if (settings.simulateOffline) ...[
            const SizedBox(height: AppSpacing.sm),
            InfoBanner(key: const Key('offline.aiUnavailable'), message: context.tr(AudioStrings.aiOffline), tone: Tone.warning, icon: Icons.smart_toy_outlined),
          ],
          SectionHeader(title: context.tr(AudioStrings.books)),
          if (books.isEmpty)
            EmptyState(title: context.tr(AudioStrings.noBooks), compact: true, icon: Icons.download_outlined, action: TextButton(onPressed: () => context.push(AppRoutes.library), child: Text(context.tr(AudioStrings.browse))))
          else
            for (final b in books)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(b.icon, color: b.color),
                title: Text(context.tr(b.title)),
                subtitle: Row(children: [Pill(context.tr(AudioStrings.available), tone: Tone.success, icon: Icons.offline_pin_outlined), const SizedBox(width: 6), Text(context.tr(AudioStrings.sizeKb.fill({'n': b.pageCount * 18})))]),
                trailing: TextButton(onPressed: () => ref.read(libraryProvider.notifier).setDownloaded(b.id, false), child: Text(context.tr(AudioStrings.remove))),
                onTap: () => context.push(AppRoutes.book(b.id)),
              ),
          SectionHeader(title: context.tr(AudioStrings.audioLessons)),
          if (audio.downloads.isEmpty) Text('—', style: Theme.of(context).textTheme.bodySmall),
          for (final l in lessons.where((l) => audio.downloads.contains(l.id)))
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.headphones_outlined),
              title: Text(context.tr(l.title)),
              subtitle: Text(context.tr(AudioStrings.sizeKb.fill({'n': l.transcript(AppLanguage.bn).length ~/ 4}))),
              trailing: TextButton(onPressed: () => ref.read(audioProvider.notifier).toggleDownload(l.id), child: Text(context.tr(AudioStrings.remove))),
            ),
          SectionHeader(title: context.tr(AudioStrings.alwaysOffline)),
          ListTile(contentPadding: EdgeInsets.zero, leading: const Icon(Icons.sticky_note_2_outlined), title: Text(context.tr(AudioStrings.notes.fill({'n': notes.length}))), trailing: Pill(context.tr(AudioStrings.available), tone: Tone.success), onTap: () => context.push(AppRoutes.notes())),
          ListTile(contentPadding: EdgeInsets.zero, leading: const Icon(Icons.style_outlined), title: Text(context.tr(AudioStrings.decks.fill({'n': decks.length}))), trailing: Pill(context.tr(AudioStrings.available), tone: Tone.success), onTap: () => context.push(AppRoutes.flashcards())),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.quiz_outlined),
            title: Text(context.tr(AudioStrings.quizzes.fill({'n': bookmarks.length}))),
            trailing: TextButton(key: const Key('offline.quiz'), onPressed: bookmarks.isEmpty ? null : () => context.push(AppRoutes.practiceSession(mode: 'bookmarks')), child: Text(context.tr(AudioStrings.startQuiz))),
          ),
          for (final (label, ok) in [(const Tr('AI টিউটর / ভয়েস / অ্যাভাটার', 'AI tutor / voice / avatar'), false), (const Tr('ছবি থেকে সমাধান', 'Photo solver'), false), (const Tr('প্রশ্নব্যাংক অনুশীলন (সংরক্ষিত)', 'Question practice (saved)'), true)])
            ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              leading: Icon(ok ? Icons.offline_pin_outlined : Icons.wifi_off, size: 20),
              title: Text(context.tr(label)),
              trailing: Pill(context.tr(ok ? AudioStrings.available : AudioStrings.needsNet), tone: ok ? Tone.success : Tone.neutral),
            ),
          SectionHeader(title: context.tr(AudioStrings.sync)),
          Text(context.tr(AudioStrings.storage.fill({'n': (store.approximateBytes / 1024).round()}))),
          Text(context.tr(AudioStrings.lastSync.fill({'t': lastSync == null ? context.tr(AudioStrings.never) : relativeTime(DateTime.parse(lastSync), context.lang)}))),
          Text(context.tr(AudioStrings.version)),
          Text(context.tr(AudioStrings.appStorage), style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: AppSpacing.sm),
          FilledButton.icon(key: const Key('offline.sync'), onPressed: _syncing ? null : _sync, icon: const Icon(Icons.sync), label: Text(context.tr(AudioStrings.syncNow))),
          if (_failed) ...[
            const SizedBox(height: AppSpacing.sm),
            InfoBanner(
              message: context.tr(AudioStrings.syncFailed),
              tone: Tone.danger,
              action: TextButton(key: const Key('offline.retry'), onPressed: _syncing ? null : _sync, child: Text(context.tr(AudioStrings.retry))),
            ),
          ],
          const SizedBox(height: AppSpacing.sm),
          if (conflictNote != null)
            Card(
              key: const Key('offline.conflict'),
              color: Theme.of(context).colorScheme.errorContainer.withValues(alpha: 0.4),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(context.tr(AudioStrings.conflictFound), style: Theme.of(context).textTheme.titleSmall),
                    Text(context.tr(AudioStrings.conflict.fill({'t': conflictNote.title}))),
                    const SizedBox(height: AppSpacing.sm),
                    Row(
                      children: [
                        Expanded(child: _VersionBox(label: AudioStrings.thisPhone, text: conflictNote.body)),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(child: _VersionBox(label: AudioStrings.otherDevice, text: '${conflictNote.body}\n✎')),
                      ],
                    ),
                    Wrap(
                      spacing: AppSpacing.xs,
                      children: [
                        TextButton(key: const Key('conflict.mine'), onPressed: () => _resolve('mine'), child: Text(context.tr(AudioStrings.keepMine))),
                        TextButton(key: const Key('conflict.server'), onPressed: () => _resolve('server'), child: Text(context.tr(AudioStrings.keepServer))),
                        TextButton(key: const Key('conflict.both'), onPressed: () => _resolve('both'), child: Text(context.tr(AudioStrings.keepBoth))),
                      ],
                    ),
                  ],
                ),
              ),
            )
          else if (notes.isNotEmpty)
            OutlinedButton.icon(key: const Key('offline.simConflict'), onPressed: () => setState(() => _conflictNoteId = notes.first.id), icon: const Icon(Icons.merge_type), label: Text(context.tr(AudioStrings.simulateConflict))),
        ],
      ),
    );
  }
}

class _VersionBox extends StatelessWidget {
  const _VersionBox({required this.label, required this.text});

  final Tr label;
  final String text;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(AppSpacing.sm),
    decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface, borderRadius: BorderRadius.circular(8)),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [Text(context.tr(label), style: Theme.of(context).textTheme.labelMedium), Text(text, maxLines: 4, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.bodySmall)],
    ),
  );
}
