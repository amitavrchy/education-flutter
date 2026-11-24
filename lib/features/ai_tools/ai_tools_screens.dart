import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/router/app_routes.dart';
import '../../core/l10n/tr.dart';
import '../../core/mock/mock_simulator.dart';
import '../../core/network/api_exception.dart';
import '../../core/settings/app_settings.dart';
import '../../core/theme/app_spacing.dart';
import '../../shared/widgets/app_page_scaffold.dart';
import '../../shared/widgets/badges.dart';
import '../../shared/widgets/feedback.dart';
import '../../shared/widgets/rich_content.dart';
import '../../shared/widgets/section_header.dart';
import '../ai_tutor/data/ai_tutor_repository.dart';
import '../ai_tutor/domain/tutor_models.dart';
import '../book_avatar/application/avatar_voice.dart';
import '../book_avatar/data/book_avatar_engine.dart';
import '../profile/application/student_profile_controller.dart';
import '../question_bank/data/question_repository.dart';
import '../question_bank/domain/question.dart';

abstract final class AiToolStrings {
  static const voice = Tr('ভয়েস টিউটর', 'Voice tutor');
  static const voiceHint = Tr('কথা বলে প্রশ্ন করো — টিউটর মুখে উত্তর দেবে, লেখাও দেখাবে।', 'Ask by speaking — the tutor answers aloud with a transcript.');
  static const start = Tr('সেশন শুরু', 'Start session');
  static const end = Tr('সেশন শেষ', 'End session');
  static const pause = Tr('বিরতি', 'Pause');
  static const resume = Tr('চালু', 'Resume');
  static const listening = Tr('শুনছি…', 'Listening…');
  static const thinking = Tr('ভাবছি…', 'Thinking…');
  static const speaking = Tr('বলছি…', 'Speaking…');
  static const ready = Tr('মাইক চেপে প্রশ্ন বলো', 'Tap the mic and speak');
  static const handsFree = Tr('হ্যান্ডস-ফ্রি', 'Hands-free');
  static const mode = Tr('শেখানোর ধরন', 'Teaching mode');
  static const sample = Tr('নমুনা প্রশ্ন (মাইক না থাকলে)', 'Sample questions (no microphone)');
  static const transcript = Tr('কথোপকথন', 'Transcript');
  static const minutes = Tr('ব্যবহার: {n} মিনিট (প্রো: মাসে ৩০০)', 'Used: {n} min (Pro: 300/month)');
  static const photo = Tr('ছবি থেকে সমাধান', 'Photo solver');
  static const photoHint = Tr('প্রশ্নের ছবি তোলো বা গ্যালারি থেকে বেছে নাও। লেখা মিলিয়ে নিয়ে সমাধান চাও।', 'Take or pick a photo of a question, check the text, then ask for the solution.');
  static const camera = Tr('ক্যামেরা', 'Camera');
  static const gallery = Tr('গ্যালারি', 'Gallery');
  static const demoImage = Tr('নমুনা ছবি (ডেমো)', 'Sample image (demo)');
  static const reading = Tr('লেখা পড়ছি (সিমুলেটেড OCR)…', 'Reading text (simulated OCR)…');
  static const extracted = Tr('পড়া লেখা — দরকার হলে ঠিক করো', 'Extracted text — correct it if needed');
  static const detected = Tr('শনাক্ত বিষয়: {s}', 'Detected subject: {s}');
  static const solve = Tr('সমাধান দাও', 'Solve');
  static const solution = Tr('সমাধান', 'Solution');
  static const retake = Tr('আবার তোলো', 'Retake');
  static const rotate = Tr('ঘোরাও', 'Rotate');
  static const handwriting = Tr('হাতের লেখা মূল্যায়ন', 'Handwriting evaluation');
  static const hwHint = Tr('খাতার উত্তরের ছবি দাও — রুব্রিক অনুযায়ী আনুমানিক নম্বর ও মতামত পাবে।', 'Add photos of your written answer — get an estimated rubric score and feedback.');
  static const question = Tr('কোন প্রশ্নের উত্তর?', 'Which question?');
  static const pages = Tr('পৃষ্ঠা ({n})', 'Pages ({n})');
  static const addPage = Tr('পৃষ্ঠা যোগ', 'Add page');
  static const evaluate = Tr('মূল্যায়ন করো', 'Evaluate');
  static const estimate = Tr('AI আনুমানিক নম্বর', 'AI estimated marks');
  static const strengths = Tr('ভালো দিক', 'Strengths');
  static const missing = Tr('বাদ পড়া পয়েন্ট', 'Missing points');
  static const tips = Tr('উন্নতির পরামর্শ', 'How to improve');
  static const teacherReview = Tr('শিক্ষকের রিভিউ চাও', 'Request teacher review');
  static const reviewRequested = Tr('শিক্ষকের কাছে পাঠানো হয়েছে', 'Sent to your teacher');
  static const estimateNote = Tr('এটি AI-এর আনুমানিক নম্বর, চূড়ান্ত নয়। চূড়ান্ত নম্বর শিক্ষক দেবেন।', 'This is an AI estimate, not final. Your teacher gives the final mark.');
  static const needPage = Tr('অন্তত একটি পৃষ্ঠার ছবি দাও', 'Add at least one page photo');
}

TutorContext _context(WidgetRef ref, BuildContext context, TeachingMode mode) {
  final p = ref.read(studentProfileProvider);
  return TutorContext(level: p.level, classYear: p.classYear, curriculumVersionId: p.curriculumVersionId, mode: mode, language: context.isBangla ? TutorLanguage.bn : TutorLanguage.en);
}

// ═════════════════════════════════════════════════════════════════════════════
// Voice tutor
// ═════════════════════════════════════════════════════════════════════════════

class VoiceTutorScreen extends ConsumerStatefulWidget {
  const VoiceTutorScreen({super.key});

  @override
  ConsumerState<VoiceTutorScreen> createState() => _VoiceTutorScreenState();
}

enum _VState { idle, listening, thinking, speaking }

class _VoiceTutorScreenState extends ConsumerState<VoiceTutorScreen> {
  late final AvatarVoice _voice;
  final List<(bool, String)> _turns = [];
  bool _active = false;
  bool _paused = false;
  bool _handsFree = true;
  bool? _canListen;
  _VState _state = _VState.idle;
  TeachingMode _mode = TeachingMode.simple;
  String _interim = '';
  DateTime? _startedAt;
  int _speech = 0;

  @override
  void initState() {
    super.initState();
    _voice = ref.read(avatarVoiceProvider);
  }

  @override
  void dispose() {
    unawaited(_voice.stopSpeaking());
    unawaited(_voice.stopListening());
    super.dispose();
  }

  Future<void> _listen() async {
    if (!_active || _paused) return;
    final lang = context.isBangla ? 'bn' : 'en';
    _canListen ??= await _voice.canListen();
    if (_canListen != true || !mounted) return;
    setState(() => _state = _VState.listening);
    final ok = await _voice.listen(
      lang: lang,
      onResult: (w, fin) {
        if (!mounted) return;
        if (!fin) return setState(() => _interim = w);
        setState(() => _interim = '');
        if (w.trim().isNotEmpty) unawaited(_ask(w));
      },
      onDone: () {
        if (mounted && _state == _VState.listening) setState(() => _state = _VState.idle);
      },
    );
    if (!ok && mounted) setState(() => _canListen = false);
  }

  Future<void> _ask(String q) async {
    final id = ++_speech;
    await _voice.stopListening();
    setState(() {
      _turns.add((true, q));
      _state = _VState.thinking;
    });
    try {
      final reply = await ref.read(mockSimulatorProvider).run(() => ref.read(mockTutorEngineProvider).answer(query: q, context: _context(ref, context, _mode)));
      if (!mounted || id != _speech) return;
      setState(() {
        _turns.add((false, reply.text));
        _state = _VState.speaking;
      });
      final lang = context.isBangla ? 'bn' : 'en';
      final spoken = BookAvatarEngine.toSpoken(reply.text, lang);
      final ok = await _voice.speak(spoken, lang: lang);
      if (!ok) await Future<void>.delayed(Duration(milliseconds: (math.min(8000, spoken.length * 60) * _voice.simulationScale).round()));
      if (!mounted || id != _speech) return;
      setState(() => _state = _VState.idle);
      if (_handsFree) unawaited(_listen());
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _state = _VState.idle);
      context.showErrorSnack(e);
    }
  }

  void _toggleSession() {
    if (_active) {
      _speech++;
      unawaited(_voice.stopSpeaking());
      unawaited(_voice.stopListening());
      setState(() {
        _active = false;
        _state = _VState.idle;
      });
    } else {
      setState(() {
        _active = true;
        _paused = false;
        _startedAt = DateTime.now();
      });
      unawaited(_listen());
    }
  }

  @override
  Widget build(BuildContext context) {
    final offline = ref.watch(appSettingsProvider.select((s) => s.simulateOffline));
    final text = Theme.of(context).textTheme;
    final c = Theme.of(context).colorScheme;
    final status = switch (_state) {
      _VState.listening => AiToolStrings.listening,
      _VState.thinking => AiToolStrings.thinking,
      _VState.speaking => AiToolStrings.speaking,
      _VState.idle => AiToolStrings.ready,
    };
    final samples = context.isBangla ? const ['নিউটনের দ্বিতীয় সূত্র কী?', 'ত্বরণ কাকে বলে?', 'মোল কী?'] : const ["What is Newton's second law?", 'What is acceleration?', 'What is a mole?'];
    return AppPageScaffold(
      title: context.tr(AiToolStrings.voice),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(children: [Expanded(child: Text(context.tr(AiToolStrings.voiceHint))), const SimulatedBadge()]),
          const SizedBox(height: AppSpacing.md),
          DropdownButtonFormField<TeachingMode>(
            isExpanded: true,
            initialValue: _mode,
            decoration: InputDecoration(labelText: context.tr(AiToolStrings.mode)),
            items: [for (final m in TeachingMode.values.where((m) => m != TeachingMode.englishCoach)) DropdownMenuItem(value: m, child: Text(context.tr(m.label)))],
            onChanged: (m) => setState(() => _mode = m ?? _mode),
          ),
          const SizedBox(height: AppSpacing.lg),
          Center(
            child: _Waveform(active: _state == _VState.listening || _state == _VState.speaking, color: _state == _VState.listening ? c.error : c.primary),
          ),
          const SizedBox(height: AppSpacing.sm),
          Center(child: Semantics(liveRegion: true, child: Text(context.tr(status), style: text.titleMedium))),
          if (_interim.isNotEmpty) Center(child: Text('“$_interim”', style: text.bodySmall?.copyWith(fontStyle: FontStyle.italic))),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              FilledButton.icon(key: const Key('voice.session'), onPressed: offline ? null : _toggleSession, icon: Icon(_active ? Icons.call_end : Icons.play_arrow), label: Text(context.tr(_active ? AiToolStrings.end : AiToolStrings.start))),
              if (_active)
                IconButton.filled(
                  tooltip: context.tr(AiToolStrings.listening),
                  onPressed: _state == _VState.thinking ? null : _listen,
                  icon: Icon(_state == _VState.listening ? Icons.mic : Icons.mic_none),
                ),
              if (_active)
                OutlinedButton(
                  onPressed: () {
                    setState(() => _paused = !_paused);
                    if (_paused) {
                      unawaited(_voice.stopListening());
                      unawaited(_voice.stopSpeaking());
                    }
                  },
                  child: Text(context.tr(_paused ? AiToolStrings.resume : AiToolStrings.pause)),
                ),
              Row(mainAxisSize: MainAxisSize.min, children: [Text(context.tr(AiToolStrings.handsFree)), Switch(value: _handsFree, onChanged: (v) => setState(() => _handsFree = v))]),
            ],
          ),
          if (_active && _canListen == false) ...[
            SectionHeader(title: context.tr(AiToolStrings.sample)),
            Wrap(spacing: AppSpacing.xs, children: [for (final s in samples) ActionChip(label: Text(s), onPressed: () => _ask(s))]),
          ],
          if (_startedAt != null) Padding(padding: const EdgeInsets.only(top: AppSpacing.sm), child: Text(context.tr(AiToolStrings.minutes.fill({'n': DateTime.now().difference(_startedAt!).inMinutes})), style: text.bodySmall)),
          if (_turns.isNotEmpty) SectionHeader(title: context.tr(AiToolStrings.transcript)),
          for (final (student, t) in _turns)
            Align(
              alignment: student ? Alignment.centerRight : Alignment.centerLeft,
              child: Container(
                margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                padding: const EdgeInsets.all(AppSpacing.md),
                constraints: const BoxConstraints(maxWidth: 520),
                decoration: BoxDecoration(color: student ? c.primaryContainer : c.surfaceContainerHighest, borderRadius: BorderRadius.circular(14)),
                child: student ? Text(t) : RichContent(t),
              ),
            ),
        ],
      ),
    );
  }
}

class _Waveform extends StatefulWidget {
  const _Waveform({required this.active, required this.color});

  final bool active;
  final Color color;

  @override
  State<_Waveform> createState() => _WaveformState();
}

class _WaveformState extends State<_Waveform> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));

  @override
  void didUpdateWidget(_Waveform old) {
    super.didUpdateWidget(old);
    if (widget.active && !_c.isAnimating) _c.repeat();
    if (!widget.active) _c.stop();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _c,
    builder: (context, _) => Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < 9; i++)
          Container(
            width: 6,
            height: widget.active ? 14 + 34 * (0.5 + 0.5 * math.sin(2 * math.pi * (_c.value + i / 9))) : 10,
            margin: const EdgeInsets.symmetric(horizontal: 3),
            decoration: BoxDecoration(color: widget.color, borderRadius: BorderRadius.circular(3)),
          ),
      ],
    ),
  );
}

// ═════════════════════════════════════════════════════════════════════════════
// Photo solver
// ═════════════════════════════════════════════════════════════════════════════

/// Simulated OCR: deterministically "reads" one of the bank's questions from the image.
Question _ocr(List<Question> bank, int seed) => bank[seed.abs() % bank.length];

class PhotoSolverScreen extends ConsumerStatefulWidget {
  const PhotoSolverScreen({super.key});

  @override
  ConsumerState<PhotoSolverScreen> createState() => _PhotoSolverScreenState();
}

class _PhotoSolverScreenState extends ConsumerState<PhotoSolverScreen> {
  String? _path;
  bool _demo = false;
  int _turns = 0;
  bool _reading = false;
  final _text = TextEditingController();
  Question? _detected;
  TutorReply? _answer;
  bool _solving = false;

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  Future<void> _pick(ImageSource? source) async {
    String? path;
    if (source != null) {
      try {
        path = (await ImagePicker().pickImage(source: source, maxWidth: 1600, imageQuality: 80))?.path;
      } on Object {
        path = null;
      }
      if (path == null) return;
    }
    setState(() {
      _path = path;
      _demo = source == null;
      _turns = 0;
      _reading = true;
      _answer = null;
    });
    try {
      final q = await ref.read(mockSimulatorProvider).run(() {
        final bank = ref.read(questionRepositoryProvider).cached;
        return _ocr(bank, (path ?? 'demo').hashCode);
      }, latencyFactor: 3);
      if (!mounted) return;
      setState(() {
        _detected = q;
        _text.text = context.tr(q.stem).replaceAll(RegExp(r'[*#]'), '');
        _reading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _reading = false);
      context.showErrorSnack(e);
    }
  }

  Future<void> _solve() async {
    setState(() => _solving = true);
    try {
      final ctx = _context(ref, context, TeachingMode.stepByStep);
      final r = await ref.read(mockSimulatorProvider).run(
        () => ref.read(mockTutorEngineProvider).answer(query: _text.text, context: TutorContext(level: ctx.level, classYear: ctx.classYear, curriculumVersionId: ctx.curriculumVersionId, mode: ctx.mode, language: ctx.language, subjectId: _detected?.subjectId)),
        latencyFactor: 2,
      );
      if (mounted) setState(() => _answer = r);
    } on ApiException catch (e) {
      if (mounted) context.showErrorSnack(e);
    } finally {
      if (mounted) setState(() => _solving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final has = _path != null || _demo;
    return AppPageScaffold(
      title: context.tr(AiToolStrings.photo),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(children: [Expanded(child: Text(context.tr(AiToolStrings.photoHint))), const SimulatedBadge()]),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              FilledButton.icon(onPressed: () => _pick(ImageSource.camera), icon: const Icon(Icons.photo_camera_outlined), label: Text(context.tr(AiToolStrings.camera))),
              OutlinedButton.icon(onPressed: () => _pick(ImageSource.gallery), icon: const Icon(Icons.photo_library_outlined), label: Text(context.tr(AiToolStrings.gallery))),
              OutlinedButton.icon(key: const Key('photo.demo'), onPressed: () => _pick(null), icon: const Icon(Icons.image_outlined), label: Text(context.tr(AiToolStrings.demoImage))),
            ],
          ),
          if (has) ...[
            const SizedBox(height: AppSpacing.md),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(
                height: 180,
                child: RotatedBox(
                  quarterTurns: _turns,
                  child: _path != null && File(_path!).existsSync()
                      ? Image.file(File(_path!), fit: BoxFit.cover)
                      : ColoredBox(color: Theme.of(context).colorScheme.surfaceContainerHighest, child: const Center(child: Icon(Icons.description_outlined, size: 64))),
                ),
              ),
            ),
            Row(
              children: [
                TextButton.icon(onPressed: () => setState(() => _turns = (_turns + 1) % 4), icon: const Icon(Icons.rotate_right), label: Text(context.tr(AiToolStrings.rotate))),
                TextButton.icon(onPressed: () => _pick(ImageSource.camera), icon: const Icon(Icons.refresh), label: Text(context.tr(AiToolStrings.retake))),
              ],
            ),
          ],
          if (_reading) ...[const LinearProgressIndicator(), const SizedBox(height: AppSpacing.xs), Text(context.tr(AiToolStrings.reading))],
          if (_detected != null && !_reading) ...[
            SectionHeader(title: context.tr(AiToolStrings.extracted)),
            TextField(key: const Key('photo.text'), controller: _text, minLines: 2, maxLines: 6),
            const SizedBox(height: AppSpacing.xs),
            Text(context.tr(AiToolStrings.detected.fill({'s': _detected!.subjectId})), style: text.bodySmall),
            const SizedBox(height: AppSpacing.sm),
            FilledButton.icon(key: const Key('photo.solve'), onPressed: _solving ? null : _solve, icon: const Icon(Icons.auto_awesome), label: Text(context.tr(AiToolStrings.solve))),
          ],
          if (_solving) const Padding(padding: EdgeInsets.all(AppSpacing.md), child: LinearProgressIndicator()),
          if (_answer != null) ...[
            SectionHeader(title: context.tr(AiToolStrings.solution)),
            Card(margin: EdgeInsets.zero, child: Padding(padding: const EdgeInsets.all(AppSpacing.md), child: RichContent(_answer!.text))),
            if (_answer!.sources.isNotEmpty)
              Wrap(
                spacing: AppSpacing.xs,
                children: [
                  for (final s in _answer!.sources)
                    ActionChip(avatar: const Icon(Icons.menu_book_outlined, size: 16), label: Text('${s.chapterTitle} · ${context.n(s.page)}'), onPressed: () => context.push(AppRoutes.bookReader(s.bookId, page: s.page))),
                ],
              ),
          ],
        ],
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// Handwriting evaluation
// ═════════════════════════════════════════════════════════════════════════════

class HandwritingResult {
  const HandwritingResult({required this.marks, required this.total, required this.criteria, required this.strengths, required this.missing, required this.tips});

  final double marks;
  final int total;
  final List<(Tr, double, int)> criteria;
  final List<Tr> strengths;
  final List<Tr> missing;
  final List<Tr> tips;
}

/// Simulated rubric scoring: deterministic per question + page count.
HandwritingResult evaluateHandwriting(Question q, int pages) {
  final total = math.max(q.marks, 4);
  final seed = (q.id.hashCode ^ pages * 7919).abs();
  final ratio = 0.55 + (seed % 35) / 100 + math.min(0.1, pages * 0.03);
  final criteria = <(Tr, double, int)>[
    (const Tr('ধারণার নির্ভুলতা', 'Concept accuracy'), (total * 0.4 * ratio * 2).roundToDouble() / 2, (total * 0.4).round()),
    (const Tr('হিসাব / যুক্তি', 'Calculation / reasoning'), (total * 0.3 * (ratio - 0.05).clamp(0, 1) * 2).roundToDouble() / 2, (total * 0.3).round()),
    (const Tr('উপস্থাপন ও একক', 'Presentation & units'), (total * 0.3 * (ratio + 0.05).clamp(0, 1) * 2).roundToDouble() / 2, total - (total * 0.4).round() - (total * 0.3).round()),
  ];
  final marks = criteria.fold<double>(0, (s, c) => s + math.min(c.$2, c.$3.toDouble()));
  return HandwritingResult(
    marks: marks,
    total: total,
    criteria: criteria,
    strengths: const [Tr('মূল সংজ্ঞা সঠিকভাবে লেখা হয়েছে', 'Key definition written correctly'), Tr('ধাপগুলো ধারাবাহিক', 'Steps are in order')],
    missing: [if (ratio < 0.8) const Tr('একক উল্লেখ করা হয়নি', 'Units not stated'), const Tr('একটি উদাহরণ যোগ করলে পূর্ণ নম্বর পাওয়া যেত', 'An example would earn full marks')],
    tips: const [Tr('উত্তরের শেষে মূল সূত্রটি আলাদা করে লেখো', 'Write the key formula separately at the end'), Tr('চিত্র থাকলে লেবেল দাও', 'Label any diagram')],
  );
}

class HandwritingScreen extends ConsumerStatefulWidget {
  const HandwritingScreen({super.key});

  @override
  ConsumerState<HandwritingScreen> createState() => _HandwritingScreenState();
}

class _HandwritingScreenState extends ConsumerState<HandwritingScreen> {
  final List<String> _pages = [];
  String? _questionId;
  HandwritingResult? _result;
  bool _busy = false;
  bool _requested = false;

  Future<void> _add(ImageSource? source) async {
    if (source == null) return setState(() => _pages.add('demo-${_pages.length + 1}'));
    try {
      final f = await ImagePicker().pickImage(source: source, maxWidth: 1600, imageQuality: 80);
      if (f != null) setState(() => _pages.add(f.path));
    } on Object {
      // Picker unavailable (simulator/tests): ignore.
    }
  }

  @override
  Widget build(BuildContext context) {
    final bank = [for (final q in ref.watch(questionRepositoryProvider).cached) if (q.type != QuestionType.mcq) q];
    final q = bank.where((x) => x.id == _questionId).firstOrNull ?? (bank.isEmpty ? null : bank.first);
    final text = Theme.of(context).textTheme;
    return AppPageScaffold(
      title: context.tr(AiToolStrings.handwriting),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(children: [Expanded(child: Text(context.tr(AiToolStrings.hwHint))), const SimulatedBadge()]),
          const SizedBox(height: AppSpacing.md),
          if (q != null)
            DropdownButtonFormField<String>(
              isExpanded: true,
              initialValue: q.id,
              decoration: InputDecoration(labelText: context.tr(AiToolStrings.question)),
              items: [for (final x in bank) DropdownMenuItem(value: x.id, child: Text(context.tr(x.stem).replaceAll(RegExp(r'[*#$]'), ''), maxLines: 1, overflow: TextOverflow.ellipsis))],
              onChanged: (v) => setState(() {
                _questionId = v;
                _result = null;
              }),
            ),
          SectionHeader(title: context.tr(AiToolStrings.pages.fill({'n': _pages.length}))),
          if (_pages.isNotEmpty)
            SizedBox(
              height: 96,
              child: ReorderableListView(
                scrollDirection: Axis.horizontal,
                onReorderItem: (a, b) => setState(() => _pages.insert(b, _pages.removeAt(a))),
                children: [
                  for (final (i, p) in _pages.indexed)
                    Container(
                      key: ValueKey('$p-$i'),
                      width: 72,
                      margin: const EdgeInsets.only(right: AppSpacing.sm),
                      decoration: BoxDecoration(color: Theme.of(context).colorScheme.surfaceContainerHighest, borderRadius: BorderRadius.circular(8)),
                      child: Stack(
                        children: [
                          Center(child: Text(context.n(i + 1), style: text.titleLarge)),
                          Positioned(right: 0, top: 0, child: IconButton(visualDensity: VisualDensity.compact, iconSize: 16, onPressed: () => setState(() => _pages.removeAt(i)), icon: const Icon(Icons.close))),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          Wrap(
            spacing: AppSpacing.sm,
            children: [
              OutlinedButton.icon(onPressed: () => _add(ImageSource.camera), icon: const Icon(Icons.photo_camera_outlined), label: Text(context.tr(AiToolStrings.camera))),
              OutlinedButton.icon(onPressed: () => _add(ImageSource.gallery), icon: const Icon(Icons.photo_library_outlined), label: Text(context.tr(AiToolStrings.gallery))),
              OutlinedButton.icon(key: const Key('hw.demo'), onPressed: () => _add(null), icon: const Icon(Icons.add), label: Text(context.tr(AiToolStrings.demoImage))),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          FilledButton.icon(
            key: const Key('hw.evaluate'),
            onPressed: _busy || q == null
                ? null
                : () async {
                    if (_pages.isEmpty) return context.showSnack(AiToolStrings.needPage);
                    setState(() => _busy = true);
                    try {
                      final r = await ref.read(mockSimulatorProvider).run(() => evaluateHandwriting(q, _pages.length), latencyFactor: 3);
                      if (mounted) setState(() => _result = r);
                    } on ApiException catch (e) {
                      if (context.mounted) context.showErrorSnack(e);
                    } finally {
                      if (mounted) setState(() => _busy = false);
                    }
                  },
            icon: const Icon(Icons.fact_check_outlined),
            label: Text(context.tr(AiToolStrings.evaluate)),
          ),
          if (_busy) const Padding(padding: EdgeInsets.all(AppSpacing.md), child: LinearProgressIndicator()),
          if (_result case final r?) ...[
            SectionHeader(title: context.tr(AiToolStrings.estimate)),
            Text('${context.n(r.marks)} / ${context.n(r.total)}', key: const Key('hw.marks'), style: text.headlineMedium),
            for (final (name, got, max) in r.criteria)
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.xs),
                child: Row(children: [Expanded(child: Text(context.tr(name))), Text('${context.n(math.min(got, max.toDouble()))} / ${context.n(max)}')]),
              ),
            const SizedBox(height: AppSpacing.sm),
            for (final (title, items, icon) in [(AiToolStrings.strengths, r.strengths, Icons.check_circle_outline), (AiToolStrings.missing, r.missing, Icons.error_outline), (AiToolStrings.tips, r.tips, Icons.lightbulb_outline)]) ...[
              Text(context.tr(title), style: text.titleSmall),
              for (final t in items) ListTile(dense: true, contentPadding: EdgeInsets.zero, leading: Icon(icon, size: 18), title: Text(context.tr(t))),
            ],
            InfoBanner(message: context.tr(AiToolStrings.estimateNote), tone: Tone.warning),
            const SizedBox(height: AppSpacing.sm),
            OutlinedButton.icon(
              onPressed: _requested ? null : () => setState(() => _requested = true),
              icon: Icon(_requested ? Icons.check : Icons.send_outlined),
              label: Text(context.tr(_requested ? AiToolStrings.reviewRequested : AiToolStrings.teacherReview)),
            ),
          ],
        ],
      ),
    );
  }
}
