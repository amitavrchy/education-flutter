import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/router/app_routes.dart';
import '../../core/l10n/tr.dart';
import '../../core/mock/mock_simulator.dart';
import '../../core/network/api_exception.dart';
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
import '../book_avatar/application/avatar_voice.dart';
import '../book_avatar/data/book_avatar_engine.dart';
import '../book_avatar/data/book_catalog.dart';
import '../flashcards/application/flashcards_controller.dart';
import '../library/library_controller.dart';
import '../notes/application/notes_controller.dart';

abstract final class AudioStrings {
  static const title = Tr('অডিও রিভিশন', 'Audio revision');
  static const hint = Tr('চলার পথে শুনে রিভিশন — প্রতিটি টপিকের ছোট অডিও লেসন (ডিভাইসের কণ্ঠে পড়ে শোনানো হয়)।', 'Revise on the go — short audio lessons per topic (read aloud with the device voice).');
  static const continueListening = Tr('শোনা চালিয়ে যাও', 'Continue listening');
  static const favorites = Tr('প্রিয়', 'Favourites');
  static const all = Tr('সব লেসন', 'All lessons');
  static const transcript = Tr('ট্রান্সক্রিপ্ট', 'Transcript');
  static const speed = Tr('গতি', 'Speed');
  static const offline = Tr('অফলাইন ডাউনলোড', 'Offline downloads');
  static const offlineHint = Tr('ইন্টারনেট ছাড়া যা ব্যবহার করা যায়। AI টিউটর ও অ্যাভাটারের জন্য ইন্টারনেট লাগে।', 'What you can use without internet. The AI tutor and avatar need internet.');
  static const online = Tr('অনলাইন', 'Online');
  static const offlineNow = Tr('অফলাইন (সিমুলেটেড)', 'Offline (simulated)');
  static const toggle = Tr('অফলাইন সিমুলেশন', 'Simulate offline');
  static const books = Tr('ডাউনলোড করা বই', 'Downloaded books');
  static const noBooks = Tr('কোনো বই ডাউনলোড করা নেই', 'No books downloaded');
  static const browse = Tr('লাইব্রেরিতে যাও', 'Open the library');
  static const remove = Tr('মুছুন', 'Remove');
  static const alwaysOffline = Tr('সবসময় অফলাইনে', 'Always available offline');
  static const notes = Tr('{n}টি নোট', '{n} notes');
  static const decks = Tr('{n}টি ফ্ল্যাশকার্ড ডেক', '{n} flashcard decks');
  static const storage = Tr('স্টোরেজ ব্যবহার: {n} KB', 'Storage used: {n} KB');
  static const sync = Tr('সিঙ্ক', 'Sync');
  static const lastSync = Tr('শেষ সিঙ্ক: {t}', 'Last sync: {t}');
  static const never = Tr('কখনো নয়', 'never');
  static const syncNow = Tr('এখন সিঙ্ক করো', 'Sync now');
  static const synced = Tr('সিঙ্ক সম্পন্ন — কোনো দ্বন্দ্ব নেই', 'Synced — no conflicts');
  static const version = Tr('কনটেন্ট সংস্করণ: NCTB 2025 (নমুনা)', 'Content version: NCTB 2025 (sample)');
}

/// Per-lesson listening progress (0–1) and favourites, persisted.
class AudioState {
  const AudioState({this.progress = const {}, this.favorites = const {}, this.lastId});

  final Map<String, double> progress;
  final Set<String> favorites;
  final String? lastId;
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
    );
  }

  Future<void> _save(AudioState s) async {
    state = s;
    await _store.put(_col, 'me', {'progress': s.progress, 'favorites': s.favorites.toList(), 'lastId': s.lastId});
  }

  Future<void> setProgress(String id, double p) => _save(AudioState(progress: {...state.progress, id: p.clamp(0, 1)}, favorites: state.favorites, lastId: id));

  Future<void> toggleFavorite(String id) =>
      _save(AudioState(progress: state.progress, favorites: state.favorites.contains(id) ? ({...state.favorites}..remove(id)) : {...state.favorites, id}, lastId: state.lastId));
}

final audioProvider = NotifierProvider<AudioController, AudioState>(AudioController.new);

String _transcript(TutorScenario s, AppLanguage l) => [s.title.of(l), s.definition.of(l), s.excerpt.of(l), for (final k in s.keyPoints) k.of(l)].join('\n\n');

class AudioRevisionScreen extends ConsumerStatefulWidget {
  const AudioRevisionScreen({super.key});

  @override
  ConsumerState<AudioRevisionScreen> createState() => _AudioRevisionScreenState();
}

class _AudioRevisionScreenState extends ConsumerState<AudioRevisionScreen> {
  late final AvatarVoice _voice;
  String? _playing;
  double _rate = 1;
  Timer? _ticker;
  bool _favOnly = false;

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

  Future<void> _stop() async {
    _ticker?.cancel();
    await _voice.stopSpeaking();
    if (mounted) setState(() => _playing = null);
  }

  Future<void> _play(TutorScenario s) async {
    if (_playing == s.id) return _stop();
    final appLang = context.lang;
    final lang = appLang == AppLanguage.bn ? 'bn' : 'en';
    await _stop();
    if (!mounted) return;
    final text = BookAvatarEngine.toSpoken(_transcript(s, appLang), lang);
    final ctrl = ref.read(audioProvider.notifier);
    var p = ref.read(audioProvider).progress[s.id] ?? 0;
    if (p >= 0.99) p = 0;
    setState(() => _playing = s.id);
    // Progress advances at roughly reading speed (also while the device speaks).
    final totalMs = (text.length / 13 / _rate * 1000).clamp(3000, 120000);
    _ticker = Timer.periodic(const Duration(milliseconds: 500), (t) {
      p = (p + 500 / totalMs).clamp(0, 1);
      unawaited(ctrl.setProgress(s.id, p));
      if (p >= 1) unawaited(_stop());
    });
    final start = (text.length * p).floor();
    unawaited(_voice.speak(text.substring(start), lang: lang, rate: _rate));
  }

  @override
  Widget build(BuildContext context) {
    final audio = ref.watch(audioProvider);
    final lessons = [for (final s in tutorScenarios) if (!_favOnly || audio.favorites.contains(s.id)) s];
    final last = tutorScenarios.where((s) => s.id == audio.lastId).firstOrNull;
    final text = Theme.of(context).textTheme;
    return AppPageScaffold(
      title: context.tr(AudioStrings.title),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(context.tr(AudioStrings.hint)),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Text(context.tr(AudioStrings.speed)),
              for (final r in const [0.75, 1.0, 1.25, 1.5]) Padding(padding: const EdgeInsets.only(left: AppSpacing.xs), child: ChoiceChip(label: Text('${context.n(r)}×'), selected: _rate == r, onSelected: (_) => setState(() => _rate = r))),
            ],
          ),
          if (last != null && (audio.progress[last.id] ?? 0) < 1) ...[
            SectionHeader(title: context.tr(AudioStrings.continueListening)),
            _LessonTile(scenario: last, playing: _playing == last.id, onPlay: () => _play(last)),
          ],
          SectionHeader(
            title: context.tr(_favOnly ? AudioStrings.favorites : AudioStrings.all),
            actionLabel: context.tr(_favOnly ? AudioStrings.all : AudioStrings.favorites),
            onAction: () => setState(() => _favOnly = !_favOnly),
          ),
          if (lessons.isEmpty) EmptyState(title: context.tr(AudioStrings.favorites), compact: true, icon: Icons.favorite_border),
          for (final s in lessons) _LessonTile(scenario: s, playing: _playing == s.id, onPlay: () => _play(s)),
          if (_playing != null) ...[
            SectionHeader(title: context.tr(AudioStrings.transcript)),
            Text(_transcript(tutorScenarios.firstWhere((s) => s.id == _playing), context.lang), style: text.bodyMedium),
          ],
        ],
      ),
    );
  }
}

class _LessonTile extends ConsumerWidget {
  const _LessonTile({required this.scenario, required this.playing, required this.onPlay});

  final TutorScenario scenario;
  final bool playing;
  final VoidCallback onPlay;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final a = ref.watch(audioProvider);
    final p = a.progress[scenario.id] ?? 0;
    final subject = subjectById(scenario.subjectId);
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: ListTile(
        key: Key('audio.${scenario.id}'),
        leading: IconButton.filledTonal(onPressed: onPlay, icon: Icon(playing ? Icons.pause : Icons.play_arrow)),
        title: Text(context.tr(scenario.title)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (subject != null) Text(context.tr(subject.name)),
            const SizedBox(height: AppSpacing.xxs),
            LinearProgressIndicator(value: p, minHeight: 3),
          ],
        ),
        trailing: IconButton(
          onPressed: () => ref.read(audioProvider.notifier).toggleFavorite(scenario.id),
          icon: Icon(a.favorites.contains(scenario.id) ? Icons.favorite : Icons.favorite_border),
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

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(appSettingsProvider);
    final reading = ref.watch(libraryProvider);
    final notes = ref.watch(notesProvider);
    final decks = ref.watch(flashcardsProvider).decks;
    final store = ref.watch(localStoreProvider);
    final lastSync = store.get('sync', 'meta')?['at'] as String?;
    final books = [for (final r in reading.values) if (r.downloaded) ?bookById(r.bookId)];
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
          SectionHeader(title: context.tr(AudioStrings.books)),
          if (books.isEmpty)
            EmptyState(title: context.tr(AudioStrings.noBooks), compact: true, icon: Icons.download_outlined, action: TextButton(onPressed: () => context.push(AppRoutes.library), child: Text(context.tr(AudioStrings.browse))))
          else
            for (final b in books)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(b.icon, color: b.color),
                title: Text(context.tr(b.title)),
                trailing: TextButton(onPressed: () => ref.read(libraryProvider.notifier).setDownloaded(b.id, false), child: Text(context.tr(AudioStrings.remove))),
                onTap: () => context.push(AppRoutes.book(b.id)),
              ),
          SectionHeader(title: context.tr(AudioStrings.alwaysOffline)),
          ListTile(contentPadding: EdgeInsets.zero, leading: const Icon(Icons.sticky_note_2_outlined), title: Text(context.tr(AudioStrings.notes.fill({'n': notes.length}))), onTap: () => context.push(AppRoutes.notes())),
          ListTile(contentPadding: EdgeInsets.zero, leading: const Icon(Icons.style_outlined), title: Text(context.tr(AudioStrings.decks.fill({'n': decks.length}))), onTap: () => context.push(AppRoutes.flashcards())),
          SectionHeader(title: context.tr(AudioStrings.sync)),
          Text(context.tr(AudioStrings.storage.fill({'n': (store.approximateBytes / 1024).round()}))),
          Text(context.tr(AudioStrings.lastSync.fill({'t': lastSync == null ? context.tr(AudioStrings.never) : relativeTime(DateTime.parse(lastSync), context.lang)}))),
          Text(context.tr(AudioStrings.version)),
          const SizedBox(height: AppSpacing.sm),
          FilledButton.icon(
            key: const Key('offline.sync'),
            onPressed: _syncing
                ? null
                : () async {
                    setState(() => _syncing = true);
                    try {
                      await ref.read(mockSimulatorProvider).run(() => store.put('sync', 'meta', {'at': DateTime.now().toIso8601String()}), latencyFactor: 2);
                      if (context.mounted) context.showSnack(AudioStrings.synced);
                    } on ApiException catch (e) {
                      if (context.mounted) context.showErrorSnack(e);
                    } finally {
                      if (mounted) setState(() => _syncing = false);
                    }
                  },
            icon: const Icon(Icons.sync),
            label: Text(context.tr(AudioStrings.syncNow)),
          ),
          const SizedBox(height: AppSpacing.sm),
          if (settings.simulateOffline) InfoBanner(message: context.tr(AudioStrings.offlineHint), tone: Tone.warning),
        ],
      ),
    );
  }
}
