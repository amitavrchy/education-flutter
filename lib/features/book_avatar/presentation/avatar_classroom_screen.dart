import 'dart:async';
import 'dart:math' as math;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/l10n/tr.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/settings/app_settings.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/time_format.dart';
import '../../../shared/widgets/app_page_scaffold.dart';
import '../../../shared/widgets/badges.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/feedback.dart';
import '../../../shared/widgets/rich_content.dart';
import '../application/avatar_controller.dart';
import '../application/avatar_voice.dart';
import '../avatar_strings.dart';
import '../data/book_catalog.dart';
import '../domain/avatar_models.dart';
import 'teacher_avatar.dart';

/// Student classroom with one book's avatar teacher: ask by text or voice, the avatar answers
/// aloud (lip-synced, captioned) from that book only, with page citations.
class AvatarClassroomScreen extends ConsumerStatefulWidget {
  const AvatarClassroomScreen({super.key, required this.bookId, this.sessionId});

  final String bookId;
  final String? sessionId;

  @override
  ConsumerState<AvatarClassroomScreen> createState() => _AvatarClassroomScreenState();
}

class _AvatarClassroomScreenState extends ConsumerState<AvatarClassroomScreen> {
  final _input = TextEditingController();
  final _scroll = ScrollController();
  final _rand = math.Random(7);
  late final AvatarVoice _voice = ref.read(avatarVoiceProvider);

  String? _sessionId;
  bool _starting = false;
  bool _asking = false;
  bool _listening = false;
  bool _speaking = false;
  bool _muted = false;
  bool _handsFree = false;
  bool _noVoice = false;
  bool? _canListen;
  double _rate = 1;
  double _mouth = 0;
  double _boost = 0;
  int _tick = 0;
  int _speechId = 0;
  String _caption = '';
  String _interim = '';
  Timer? _mouthTimer;

  Book get _book => bookById(widget.bookId)!;

  @override
  void initState() {
    super.initState();
    _sessionId = widget.sessionId;
  }

  @override
  void dispose() {
    _mouthTimer?.cancel();
    unawaited(_voice.stopSpeaking());
    unawaited(_voice.stopListening());
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  BookAvatar get _avatar => ref.read(avatarControllerProvider.notifier).avatarFor(_book);

  AvatarMood get _mood => _listening
      ? AvatarMood.listening
      : _asking
      ? AvatarMood.thinking
      : _speaking
      ? AvatarMood.speaking
      : AvatarMood.idle;

  // ── Speech ──────────────────────────────────────────────────────────────

  void _startMouth() {
    _mouthTimer?.cancel();
    _mouthTimer = Timer.periodic(const Duration(milliseconds: 70), (_) {
      if (!mounted) return;
      _tick++;
      _boost = math.max(0, _boost - 0.06);
      final base = 0.25 + 0.35 * math.sin(_tick * 0.42).abs() + 0.2 * math.sin(_tick * 1.3).abs();
      setState(() => _mouth = math.min(1, base * (0.6 + _rand.nextDouble() * 0.5) + _boost));
    });
  }

  void _endSpeech() {
    _mouthTimer?.cancel();
    _mouthTimer = null;
    if (mounted) {
      setState(() {
        _speaking = false;
        _mouth = 0;
        _caption = '';
      });
    }
  }

  Future<void> _speak(String text) async {
    if (text.trim().isEmpty) return;
    await _voice.stopListening();
    final id = ++_speechId;
    setState(() {
      _listening = false;
      _speaking = true;
      _caption = text;
    });
    _startMouth();
    final a = _avatar;
    final spoke = !_muted && await _voice.speak(text, lang: a.voice.language, rate: _rate, pitch: a.voice.pitch, onWord: () => _boost = 0.35);
    if (!spoke && id == _speechId) {
      if (!_muted && mounted) setState(() => _noVoice = true);
      // No audio → animate for roughly the time it would take to say it.
      final ms = (text.length / 13 / _rate * 1000).clamp(1500, 14000) * _voice.simulationScale;
      await Future<void>.delayed(Duration(milliseconds: ms.round()));
    }
    if (id != _speechId || !mounted) return;
    _endSpeech();
    if (_handsFree) unawaited(_listen());
  }

  Future<void> _stopSpeaking() async {
    _speechId++;
    await _voice.stopSpeaking();
    _endSpeech();
  }

  Future<void> _listen() async {
    if (_listening) {
      await _voice.stopListening();
      if (mounted) setState(() => _listening = false);
      return;
    }
    await _stopSpeaking();
    _canListen ??= await _voice.canListen();
    if (_canListen != true) {
      if (mounted) await _sampleQuestions();
      return;
    }
    setState(() {
      _listening = true;
      _interim = '';
    });
    final ok = await _voice.listen(
      lang: _avatar.voice.language,
      onResult: (words, isFinal) {
        if (!mounted) return;
        if (!isFinal) {
          setState(() => _interim = words);
          return;
        }
        setState(() {
          _interim = '';
          _listening = false;
        });
        if (words.trim().isNotEmpty) unawaited(_send(words, voice: true));
      },
      onDone: () {
        if (mounted) setState(() => _listening = false);
      },
    );
    if (!ok && mounted) {
      setState(() {
        _listening = false;
        _canListen = false;
      });
      await _sampleQuestions();
    }
  }

  Future<void> _sampleQuestions() async {
    final book = _book;
    final lang = _avatar.voice.language;
    final samples = [
      for (final s in book.scenarios.take(2)) lang == 'en' ? 'What is ${s.title.en}?' : '${s.title.bn} বুঝিয়ে দাও',
      for (final c in book.chapters.take(3 - math.min(2, book.scenarios.length)))
        if (c.topics.isNotEmpty) lang == 'en' ? 'What is ${c.topics.first.title.en}?' : '${c.topics.first.title.bn} কী?',
    ];
    final picked = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: InfoBanner(message: context.tr(AvatarStrings.micUnavailable), tone: Tone.warning),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.xs),
              child: Text(context.tr(AvatarStrings.sampleVoiceQuestions), style: Theme.of(context).textTheme.titleSmall),
            ),
            for (final s in samples)
              ListTile(leading: const Icon(Icons.record_voice_over_outlined), title: Text(s), onTap: () => Navigator.pop(context, s)),
          ],
        ),
      ),
    );
    if (picked != null) await _send(picked, voice: true);
  }

  // ── Class & questions ───────────────────────────────────────────────────

  Future<String> _ensureSession({bool greet = true}) async {
    final existing = _sessionId;
    if (existing != null) return existing;
    setState(() => _starting = true);
    final session = await ref.read(avatarControllerProvider.notifier).startSession(widget.bookId);
    if (!mounted) return session.id;
    setState(() {
      _sessionId = session.id;
      _starting = false;
    });
    if (greet) {
      final a = _avatar;
      unawaited(_speak(a.voice.language == 'en' ? a.greeting.en : a.greeting.bn));
    }
    return session.id;
  }

  Future<void> _send(String text, {bool voice = false}) async {
    final q = text.trim();
    if (q.isEmpty || _asking) return;
    _input.clear();
    final sessionId = await _ensureSession(greet: false);
    if (!mounted) return;
    await _stopSpeaking();
    setState(() => _asking = true);
    _scrollToEnd();
    try {
      final reply = await ref.read(avatarControllerProvider.notifier).ask(sessionId, q, voice: voice);
      if (!mounted) return;
      setState(() => _asking = false);
      _scrollToEnd();
      unawaited(_speak(reply.spoken ?? reply.text));
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _asking = false);
      context.showSnack(e.code == 'OFFLINE' ? AvatarStrings.offline : Tr.same(e.message));
    }
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) _scroll.animateTo(_scroll.position.maxScrollExtent + 200, duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
    });
  }

  Future<void> _history() async {
    final ctrl = ref.read(avatarControllerProvider.notifier);
    final sessions = [for (final s in ref.read(avatarControllerProvider).sessionsOf(ctrl.currentUserId)) if (s.bookId == widget.bookId) s];
    final picked = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            ListTile(leading: const Icon(Icons.add), title: Text(context.tr(AvatarStrings.newClass)), onTap: () => Navigator.pop(context, '')),
            if (sessions.isEmpty)
              Padding(padding: const EdgeInsets.all(AppSpacing.lg), child: Text(context.tr(AvatarStrings.noHistory)))
            else
              for (final s in sessions)
                ListTile(
                  leading: const Icon(Icons.history),
                  title: Text(s.title, maxLines: 1, overflow: TextOverflow.ellipsis),
                  subtitle: Text(relativeTime(s.lastAt, context.lang)),
                  selected: s.id == _sessionId,
                  onTap: () => Navigator.pop(context, s.id),
                ),
          ],
        ),
      ),
    );
    if (picked == null || !mounted) return;
    await _stopSpeaking();
    setState(() => _sessionId = picked.isEmpty ? null : picked);
  }

  Future<void> _report(AvatarMessage m) async {
    final reason = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.tr(AvatarStrings.report)),
        content: TextField(
          key: const Key('avatar.reportReason'),
          controller: reason,
          maxLines: 3,
          decoration: InputDecoration(hintText: context.tr(AvatarStrings.reportReason)),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(context.tr(AvatarStrings.cancel))),
          FilledButton(onPressed: () => Navigator.pop(context, reason.text.trim().isNotEmpty), child: Text(context.tr(AvatarStrings.submit))),
        ],
      ),
    );
    if (ok == true) {
      await ref.read(avatarControllerProvider.notifier).report(m.id, reason.text);
      if (mounted) context.showSnack(AvatarStrings.reportSent);
    }
    reason.dispose();
  }

  void _showSource(AvatarCitation c) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(context.tr(AvatarStrings.sourceSheet), style: Theme.of(context).textTheme.labelLarge),
              const SizedBox(height: AppSpacing.xs),
              Text(context.tr(_book.title), style: Theme.of(context).textTheme.titleMedium),
              Text('${context.tr(AvatarStrings.page.fill({'n': c.page}))} · ${c.chapterTitle}', style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: AppSpacing.md),
              if (c.heading != null) Text(c.heading!, style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: AppSpacing.xs),
              RichContent(c.excerpt),
              const SizedBox(height: AppSpacing.md),
              InfoBanner(message: context.tr(AvatarStrings.sampleBookNote)),
            ],
          ),
        ),
      ),
    );
  }

  // ── UI ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(avatarControllerProvider);
    final offline = ref.watch(appSettingsProvider.select((s) => s.simulateOffline));
    final a = ref.read(avatarControllerProvider.notifier).avatarFor(_book);
    final messages = _sessionId == null ? const <AvatarMessage>[] : state.messagesOf(_sessionId!);
    final last = messages.where((m) => m.role == AvatarRole.avatar).lastOrNull;
    final text = Theme.of(context).textTheme;
    final status = switch (_mood) {
      AvatarMood.listening => AvatarStrings.listening,
      AvatarMood.thinking => AvatarStrings.thinking,
      AvatarMood.speaking => AvatarStrings.speaking,
      AvatarMood.idle => AvatarStrings.idle,
    };

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(context.tr(a.name)),
            Text(context.tr(a.title), style: text.bodySmall),
          ],
        ),
        actions: [IconButton(tooltip: context.tr(AvatarStrings.history), icon: const Icon(Icons.history), onPressed: _history)],
      ),
      body: Column(
        children: [
          if (offline) const OfflineBanner(),
          // Stage
          Container(
            color: Color(a.appearance.background).withValues(alpha: 0.6),
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TeacherAvatar(appearance: a.appearance, mood: _mood, mouth: _mouth, size: 112, semanticLabel: '${context.tr(a.name)} — ${context.tr(status)}'),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: AppSpacing.xs,
                        runSpacing: AppSpacing.xs,
                        children: [Pill(context.tr(AvatarStrings.onlyThisBook), tone: Tone.success, icon: Icons.menu_book_outlined), const SimulatedBadge()],
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Semantics(liveRegion: true, child: Text(context.tr(status), style: text.titleSmall)),
                      const SizedBox(height: AppSpacing.xs),
                      if (_interim.isNotEmpty)
                        Text('“$_interim”', maxLines: 3, overflow: TextOverflow.ellipsis, style: text.bodySmall?.copyWith(fontStyle: FontStyle.italic))
                      else if (_caption.isNotEmpty)
                        Text(_caption, key: const Key('avatar.caption'), maxLines: 4, overflow: TextOverflow.ellipsis, style: text.bodySmall)
                      else if (_sessionId == null)
                        Text(context.tr(a.voice.language == 'en' ? Tr.same(a.greeting.en) : Tr.same(a.greeting.bn)), maxLines: 4, overflow: TextOverflow.ellipsis, style: text.bodySmall),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Controls
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
            child: Row(
              children: [
                IconButton.filled(
                  key: const Key('avatar.mic'),
                  iconSize: 28,
                  tooltip: context.tr(_listening ? AvatarStrings.stopListening : AvatarStrings.askByVoice),
                  style: _listening ? IconButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.error) : null,
                  onPressed: offline || _asking ? null : _listen,
                  icon: Icon(_listening ? Icons.mic_off : Icons.mic),
                ),
                if (_speaking) IconButton(tooltip: context.tr(AvatarStrings.stopSpeaking), onPressed: _stopSpeaking, icon: const Icon(Icons.stop_circle_outlined)),
                IconButton(
                  key: const Key('avatar.mute'),
                  tooltip: context.tr(_muted ? AvatarStrings.unmute : AvatarStrings.mute),
                  onPressed: () => setState(() => _muted = !_muted),
                  icon: Icon(_muted ? Icons.volume_off : Icons.volume_up),
                ),
                PopupMenuButton<double>(
                  tooltip: context.tr(AvatarStrings.speed),
                  initialValue: _rate,
                  onSelected: (v) => setState(() => _rate = v),
                  itemBuilder: (context) => [for (final r in const [0.75, 1.0, 1.25]) PopupMenuItem(value: r, child: Text('${context.n(r)}×'))],
                  child: Padding(padding: const EdgeInsets.all(AppSpacing.sm), child: Text('${context.n(_rate)}×', style: text.labelLarge)),
                ),
                const Spacer(),
                Flexible(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(child: Text(context.tr(AvatarStrings.handsFree), maxLines: 2, overflow: TextOverflow.ellipsis, style: text.labelSmall, textAlign: TextAlign.end)),
                      Switch(value: _handsFree, onChanged: (v) => setState(() => _handsFree = v)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (_noVoice && !_muted)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: Text(context.tr(AvatarStrings.noVoice), style: text.labelSmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)),
            ),
          const Divider(height: AppSpacing.md),
          // Conversation
          Expanded(
            child: _sessionId == null
                ? ListView(
                    padding: AppSpacing.screen,
                    children: [
                      EmptyState(
                        icon: Icons.co_present_outlined,
                        title: context.tr(AvatarStrings.idle),
                        message: context.tr(AvatarStrings.galleryHint),
                        action: FilledButton.icon(
                          key: const Key('avatar.start'),
                          onPressed: offline || _starting ? null : () => _ensureSession(),
                          icon: const Icon(Icons.play_arrow),
                          label: Text(context.tr(AvatarStrings.startClass)),
                        ),
                      ),
                    ],
                  )
                : ListView(
                    controller: _scroll,
                    padding: AppSpacing.screen,
                    children: [
                      for (final m in messages)
                        m.role == AvatarRole.student
                            ? _StudentBubble(message: m)
                            : _AvatarBubble(
                                message: m,
                                avatar: a,
                                onReplay: () => _speak(m.spoken ?? m.text),
                                onSource: _showSource,
                                onReport: () => _report(m),
                              ),
                      if (_asking) const Padding(padding: EdgeInsets.all(AppSpacing.md), child: LinearProgressIndicator()),
                      if (!_asking && last != null && last.followUps.isNotEmpty)
                        Wrap(
                          spacing: AppSpacing.xs,
                          runSpacing: AppSpacing.xs,
                          children: [for (final f in last.followUps.take(3)) ActionChip(label: Text(f), onPressed: offline ? null : () => _send(f))],
                        ),
                    ],
                  ),
          ),
          // Composer
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.xs, AppSpacing.md, AppSpacing.sm),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      key: const Key('avatar.input'),
                      controller: _input,
                      enabled: !offline,
                      minLines: 1,
                      maxLines: 4,
                      textInputAction: TextInputAction.send,
                      onSubmitted: _send,
                      decoration: InputDecoration(hintText: context.tr(AvatarStrings.askHint)),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  IconButton.filled(
                    key: const Key('avatar.send'),
                    tooltip: context.tr(AvatarStrings.send),
                    onPressed: offline || _asking ? null : () => _send(_input.text),
                    icon: const Icon(Icons.send),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StudentBubble extends StatelessWidget {
  const _StudentBubble({required this.message});

  final AvatarMessage message;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).colorScheme;
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.sm, left: AppSpacing.xxl),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
        decoration: BoxDecoration(color: c.primary, borderRadius: BorderRadius.circular(16)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (message.voiceInput) ...[Icon(Icons.mic, size: 14, color: c.onPrimary), const SizedBox(width: AppSpacing.xs)],
            Flexible(child: Text(message.text, style: TextStyle(color: c.onPrimary))),
          ],
        ),
      ),
    );
  }
}

class _AvatarBubble extends ConsumerWidget {
  const _AvatarBubble({required this.message, required this.avatar, required this.onReplay, required this.onSource, required this.onReport});

  final AvatarMessage message;
  final BookAvatar avatar;
  final VoidCallback onReplay;
  final ValueChanged<AvatarCitation> onSource;
  final VoidCallback onReport;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = Theme.of(context).textTheme;
    final m = message;
    final ctrl = ref.read(avatarControllerProvider.notifier);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm, right: AppSpacing.lg),
      child: Card(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(context.tr(avatar.name), style: text.labelLarge),
                  const SizedBox(width: AppSpacing.xs),
                  if (m.grounded == Grounding.book) Pill(context.tr(AvatarStrings.fromBook), tone: Tone.success),
                  if (m.grounded == Grounding.outOfScope) Pill(context.tr(AvatarStrings.outsideBook), tone: Tone.warning),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              RichContent(m.text),
              if (m.citations.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.sm),
                Wrap(
                  spacing: AppSpacing.xs,
                  runSpacing: AppSpacing.xs,
                  children: [
                    for (final c in m.citations)
                      ActionChip(
                        key: Key('avatar.citation.${c.page}'),
                        avatar: const Icon(Icons.menu_book_outlined, size: 16),
                        label: Text('${context.tr(AvatarStrings.page.fill({'n': c.page}))} · ${c.chapterTitle}', overflow: TextOverflow.ellipsis),
                        onPressed: () => onSource(c),
                      ),
                  ],
                ),
              ],
              if (m.grounded != Grounding.greeting)
                Row(
                  children: [
                    IconButton(tooltip: context.tr(AvatarStrings.replay), visualDensity: VisualDensity.compact, onPressed: onReplay, icon: const Icon(Icons.volume_up_outlined, size: 18)),
                    IconButton(
                      tooltip: context.tr(AvatarStrings.helpful),
                      visualDensity: VisualDensity.compact,
                      isSelected: m.feedback == 'up',
                      onPressed: () async {
                        await ctrl.feedback(m.id, 'up');
                        if (context.mounted) context.showSnack(AvatarStrings.thanks);
                      },
                      icon: const Icon(Icons.thumb_up_outlined, size: 18),
                      selectedIcon: const Icon(Icons.thumb_up, size: 18),
                    ),
                    IconButton(
                      tooltip: context.tr(AvatarStrings.notHelpful),
                      visualDensity: VisualDensity.compact,
                      isSelected: m.feedback == 'down',
                      onPressed: () => ctrl.feedback(m.id, 'down'),
                      icon: const Icon(Icons.thumb_down_outlined, size: 18),
                      selectedIcon: const Icon(Icons.thumb_down, size: 18),
                    ),
                    IconButton(key: Key('avatar.report.${m.id}'), tooltip: context.tr(AvatarStrings.report), visualDensity: VisualDensity.compact, onPressed: onReport, icon: const Icon(Icons.flag_outlined, size: 18)),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}
