import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/services.dart';
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
import '../../core/utils/time_format.dart';
import '../../mock/seed/curriculum_seed.dart';
import '../../shared/widgets/badges.dart';
import '../../shared/widgets/empty_state.dart';
import '../../shared/widgets/feedback.dart';
import '../../shared/widgets/rich_content.dart';
import '../../shared/widgets/section_header.dart';
import '../settings/learning_prefs.dart';
import '../teacher/teacher_data.dart';
import 'remote_ai_tools.dart';
import 'remote_evaluation.dart';
import 'ai_tools_data.dart';
import '../account/account_controller.dart';
import '../ai_tutor/data/ai_tutor_repository.dart';
import '../ai_tutor/domain/tutor_models.dart';
import '../book_avatar/application/avatar_voice.dart';
import '../book_avatar/data/book_avatar_engine.dart';
import '../flashcards/application/flashcards_controller.dart';
import '../flashcards/domain/flashcard.dart';
import '../notes/application/notes_controller.dart';
import '../parent/guardian_controller.dart' show selfChildName;
import '../notes/domain/note.dart';
import '../profile/application/student_profile_controller.dart';
import '../question_bank/application/practice_controller.dart';
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
  static const settings = Tr('ভয়েস সেটিংস', 'Voice settings');
  static const language = Tr('ভাষা', 'Language');
  static const mixed = Tr('বাংলা-ইংরেজি মিশ্র', 'Mixed Bangla-English');
  static const voiceType = Tr('কণ্ঠ', 'Voice');
  static const voiceFemale = Tr('নারী কণ্ঠ', 'Female voice');
  static const voiceMale = Tr('পুরুষ কণ্ঠ', 'Male voice');
  static const speed = Tr('কথার গতি', 'Speaking speed');
  static const mic = Tr('মাইক্রোফোন', 'Microphone');
  static const micPhone = Tr('ফোনের মাইক', 'Phone microphone');
  static const micHeadset = Tr('হেডসেট / ইয়ারফোন', 'Headset / earphones');
  static const micDenied = Tr(
    'মাইক্রোফোনের অনুমতি নেই বা স্পিচ রিকগনিশন নেই। ফোনের সেটিংসে অনুমতি দাও, অথবা নিচের নমুনা প্রশ্ন বা লেখা ব্যবহার করো।',
    'No microphone permission or speech recognition. Allow it in phone settings, or use the sample questions or typing below.',
  );
  static const typeInstead = Tr('অথবা লিখে জিজ্ঞেস করো…', 'Or type your question…');
  static const interrupt = Tr('থামিয়ে প্রশ্ন করো', 'Interrupt and ask');
  static const network = Tr('নেটওয়ার্ক', 'Network');
  static const netGood = Tr('ভালো', 'Good');
  static const netPoor = Tr('দুর্বল', 'Poor');
  static const netOffline = Tr('অফলাইন', 'Offline');
  static const limitReached = Tr('এই মাসের ভয়েস মিনিট শেষ ({n} মিনিট)। প্রো নিলে মাসে ৩০০ মিনিট।', "This month's voice minutes are used up ({n} min). Pro gives 300 a month.");
  static const usage = Tr('এই মাসে ব্যবহার: {a}/{b} মিনিট', 'Used this month: {a}/{b} min');
  static const toNotes = Tr('নোটে রাখো', 'Save as notes');
  static const toSummary = Tr('সারাংশ', 'Summary');
  static const toCards = Tr('ফ্ল্যাশকার্ড বানাও', 'Make flashcards');
  static const savedNotes = Tr('নোট তৈরি হয়েছে', 'Notes created');
  static const savedCards = Tr('ফ্ল্যাশকার্ড ডেক তৈরি হয়েছে', 'Flashcard deck created');
  static const summaryTitle = Tr('কথোপকথনের সারাংশ', 'Conversation summary');
  static const history = Tr('আগের সেশন', 'Past sessions');
  static const noHistory = Tr('কোনো সংরক্ষিত সেশন নেই', 'No saved sessions');
  static const sessionSaved = Tr('সেশন সংরক্ষিত হয়েছে', 'Session saved');
  static const multi = Tr('একাধিক ছবি একসাথে ({n})', 'Multiple images ({n})');
  static const crop = Tr('ক্রপ', 'Crop');
  static const cropFull = Tr('পুরো ছবি', 'Full image');
  static const cropTop = Tr('উপরের অর্ধেক', 'Top half');
  static const cropBottom = Tr('নিচের অর্ধেক', 'Bottom half');
  static const cropCenter = Tr('মাঝখান', 'Centre');
  static const badFile = Tr('শুধু JPG/PNG/HEIC ছবি, ১০ MB পর্যন্ত', 'Only JPG/PNG/HEIC images up to 10 MB');
  static const chapter = Tr('অধ্যায়', 'Chapter');
  static const explanation = Tr('ব্যাখ্যা', 'Explanation');
  static const saveNote = Tr('নোটে সংরক্ষণ', 'Save to notes');
  static const addPractice = Tr('অনুশীলন তালিকায় যোগ', 'Add to practice list');
  static const addedPractice = Tr('অনুশীলন তালিকায় (বুকমার্ক) যোগ হয়েছে', 'Added to your practice list (bookmarks)');
  static const reportOcr = Tr('OCR ভুল রিপোর্ট', 'Report OCR error');
  static const reportedOcr = Tr('ধন্যবাদ — OCR ভুল রিপোর্ট হয়েছে', 'Thanks — OCR error reported');
  static const recent = Tr('সাম্প্রতিক সমাধান', 'Recent solves');
  static const original = Tr('মূল লেখা (ছবি)', 'Original (image)');
  static const ocrText = Tr('পড়া লেখা — ঠিক করে নাও', 'Extracted text — correct it');
  static const mapped = Tr('প্রশ্নের সাথে মিলানো', 'Mapped to question');
  static const compare = Tr('মডেল উত্তরের সাথে তুলনা', 'Compared with the model answer');
  static const modelAnswer = Tr('মডেল উত্তর', 'Model answer');
  static const evalHistory = Tr('মূল্যায়নের ইতিহাস', 'Evaluation history');
  static const beforeAfter = Tr('আগের চেষ্টার তুলনায়: {d}', 'Compared with the last attempt: {d}');
  static const reattempt = Tr('আবার চেষ্টা করো', 'Reattempt');
  static const export = Tr('মতামত কপি', 'Copy feedback');
  static const exported = Tr('মতামত কপি হয়েছে', 'Feedback copied');
  static const stageAi = Tr('AI আনুমানিক', 'AI estimate');
  static const stageTeacher = Tr('শিক্ষক পর্যালোচিত', 'Teacher reviewed');
  static const stageOfficial = Tr('চূড়ান্ত (অফিসিয়াল)', 'Official');
  static const stageRequested = Tr('শিক্ষকের অপেক্ষায়', 'Waiting for teacher');
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

  /// API mode, oral exam: the question the student is answering.
  String? _oralQuestion;
  final _typed = TextEditingController();
  bool _active = false;
  bool _paused = false;
  bool _handsFree = true;
  bool? _canListen;
  _VState _state = _VState.idle;
  TeachingMode _mode = TeachingMode.simple;
  String _interim = '';
  DateTime? _startedAt;
  int _speech = 0;
  String _lang = 'auto';
  bool _male = false;
  double _rate = 1;
  bool _headset = false;
  String? _sessionId;

  @override
  void initState() {
    super.initState();
    _voice = ref.read(avatarVoiceProvider);
    final prefs = ref.read(learningPrefsProvider);
    _male = prefs.voiceMale;
    _rate = prefs.voiceRate;
    _handsFree = prefs.handsFree;
    if (prefs.tutorMode != TeachingMode.englishCoach) _mode = prefs.tutorMode;
  }

  @override
  void dispose() {
    _typed.dispose();
    unawaited(_voice.stopSpeaking());
    unawaited(_voice.stopListening());
    super.dispose();
  }

  /// Recognition / speech language: Bangla, English, or mixed (Bangla engine, English terms kept).
  String _speechLang(BuildContext context) => switch (_lang) {
    'en' => 'en',
    'bn' || 'mixed' => 'bn',
    _ => context.isBangla ? 'bn' : 'en',
  };

  TutorLanguage _tutorLang(BuildContext context) => switch (_lang) {
    'en' => TutorLanguage.en,
    'mixed' => TutorLanguage.mixed,
    'bn' => TutorLanguage.bn,
    _ => context.isBangla ? TutorLanguage.bn : TutorLanguage.en,
  };

  bool get _overLimit {
    final used = ref.read(aiToolsProvider).minutesThisMonth(DateTime.now()) + (_startedAt == null ? 0 : DateTime.now().difference(_startedAt!).inMinutes);
    return used >= voiceAllowance(ref.read(accountProvider).plan);
  }

  Future<void> _listen() async {
    if (!_active || _paused) return;
    final lang = _speechLang(context);
    _canListen ??= await _voice.canListen();
    if (_canListen != true || !mounted) return setState(() {});
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

  /// Stops the tutor mid-answer and listens again (VOICE-16).
  Future<void> _interrupt() async {
    _speech++;
    await _voice.stopSpeaking();
    if (!mounted) return;
    setState(() => _state = _VState.idle);
    unawaited(_listen());
  }

  Future<void> _ask(String q) async {
    if (_overLimit) {
      if (mounted) context.showSnack(AiToolStrings.limitReached.fill({'n': voiceAllowance(ref.read(accountProvider).plan)}));
      return;
    }
    final id = ++_speech;
    final base = _context(ref, context, _mode);
    final ctx = TutorContext(level: base.level, classYear: base.classYear, curriculumVersionId: base.curriculumVersionId, mode: _mode, language: _tutorLang(context));
    await _voice.stopListening();
    if (!mounted) return;
    setState(() {
      _turns.add((true, q));
      _state = _VState.thinking;
    });
    try {
      final remote = ref.read(remoteAiToolsProvider);
      final String replyText;
      if (remote != null) {
        // API mode: the AI service writes the spoken reply (oral exams get the next question).
        final r = await remote.voiceReply(
          text: q,
          oralExam: _mode == TeachingMode.oralExam,
          language: ctx.language.name,
          oralQuestion: _oralQuestion,
          turns: _turns.sublist(0, _turns.length - 1),
        );
        if (r.nextQuestion != null && r.nextQuestion!.isNotEmpty) _oralQuestion = r.nextQuestion;
        replyText = r.text;
      } else {
        replyText = (await ref.read(mockSimulatorProvider).run(() => ref.read(mockTutorEngineProvider).answer(query: q, context: ctx))).text;
      }
      if (!mounted || id != _speech) return;
      setState(() {
        _turns.add((false, replyText));
        _state = _VState.speaking;
      });
      final lang = _speechLang(context);
      final spoken = BookAvatarEngine.toSpoken(replyText, lang);
      final ok = await _voice.speak(spoken, lang: lang, rate: _rate, pitch: _male ? 0.8 : 1.1);
      if (!ok) await Future<void>.delayed(Duration(milliseconds: (math.min(8000, spoken.length * 60) / _rate * _voice.simulationScale).round()));
      if (!mounted || id != _speech) return;
      setState(() => _state = _VState.idle);
      if (_handsFree) unawaited(_listen());
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _state = _VState.idle);
      context.showErrorSnack(e);
    }
  }

  Future<void> _toggleSession() async {
    if (_active) {
      _speech++;
      unawaited(_voice.stopSpeaking());
      unawaited(_voice.stopListening());
      final started = _startedAt ?? DateTime.now();
      setState(() {
        _active = false;
        _state = _VState.idle;
      });
      if (_turns.isNotEmpty) {
        await ref
            .read(aiToolsProvider.notifier)
            .saveSession(
              VoiceSession(
                id: _sessionId ?? 'vs-${started.microsecondsSinceEpoch}',
                startedAt: started,
                endedAt: DateTime.now(),
                mode: _mode.name,
                language: _lang == 'auto' ? _speechLang(context) : _lang,
                turns: [..._turns],
              ),
            );
        if (mounted) context.showSnack(AiToolStrings.sessionSaved);
      }
    } else {
      if (_overLimit) return context.showSnack(AiToolStrings.limitReached.fill({'n': voiceAllowance(ref.read(accountProvider).plan)}));
      setState(() {
        _active = true;
        _paused = false;
        _startedAt = DateTime.now();
        _sessionId = 'vs-${_startedAt!.microsecondsSinceEpoch}';
        _turns.clear();
      });
      unawaited(_listen());
    }
  }

  String get _transcript => [for (final (s, t) in _turns) '${s ? '🧑' : '🤖'} $t'].join('\n\n');

  Future<void> _toNotes() async {
    await ref
        .read(notesProvider.notifier)
        .create(
          title: '${context.tr(AiToolStrings.voice)} — ${_turns.firstWhere((t) => t.$1, orElse: () => (true, '')).$2}',
          body: _transcript,
          source: NoteSource.conversation,
          type: NoteType.detailed,
          aiGenerated: true,
        );
    if (mounted) context.showSnack(AiToolStrings.savedNotes);
  }

  Future<void> _toCards() async {
    final pairs = <(String, String)>[
      for (var i = 0; i + 1 < _turns.length; i++)
        if (_turns[i].$1 && !_turns[i + 1].$1) (_turns[i].$2, _turns[i + 1].$2.split('\n').first.replaceAll(RegExp(r'[*#>]'), '').trim()),
    ];
    await ref.read(flashcardsProvider.notifier).createDeck(context.tr(AiToolStrings.voice), source: DeckSource.conversation, cards: pairs, ai: true);
    if (mounted) context.showSnack(AiToolStrings.savedCards);
  }

  void _summary() {
    final points = [
      for (final (s, t) in _turns)
        if (!s) t.split('\n').firstWhere((l) => l.trim().isNotEmpty, orElse: () => '').replaceAll(RegExp(r'[*#>]'), '').trim(),
    ];
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(ctx.tr(AiToolStrings.summaryTitle)),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [for (final p in points) Padding(padding: const EdgeInsets.only(bottom: 6), child: Text('• $p'))],
          ),
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: Text(ctx.tr(const Tr('ঠিক আছে', 'OK'))))],
      ),
    );
  }

  void _history() => showModalBottomSheet<void>(context: context, isScrollControlled: true, showDragHandle: true, builder: (_) => const _VoiceHistorySheet());

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(appSettingsProvider);
    final offline = settings.simulateOffline;
    final tools = ref.watch(aiToolsProvider);
    final plan = ref.watch(accountProvider.select((a) => a.plan));
    final text = Theme.of(context).textTheme;
    final c = Theme.of(context).colorScheme;
    final status = switch (_state) {
      _VState.listening => AiToolStrings.listening,
      _VState.thinking => AiToolStrings.thinking,
      _VState.speaking => AiToolStrings.speaking,
      _VState.idle => AiToolStrings.ready,
    };
    final (netLabel, netIcon, netColor) = offline
        ? (AiToolStrings.netOffline, Icons.signal_wifi_off, c.error)
        : settings.simulateErrors
        ? (AiToolStrings.netPoor, Icons.network_check, Colors.orange)
        : (AiToolStrings.netGood, Icons.signal_wifi_4_bar, Colors.green);
    final samples = context.isBangla ? const ['নিউটনের দ্বিতীয় সূত্র কী?', 'ত্বরণ কাকে বলে?', 'মোল কী?'] : const ["What is Newton's second law?", 'What is acceleration?', 'What is a mole?'];
    final used = tools.minutesThisMonth(DateTime.now());
    return AppPageScaffold(
      title: context.tr(AiToolStrings.voice),
      actions: [IconButton(key: const Key('voice.history'), tooltip: context.tr(AiToolStrings.history), icon: const Icon(Icons.history), onPressed: _history)],
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(child: Text(context.tr(AiToolStrings.voiceHint))),
              const SimulatedBadge(),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Icon(netIcon, size: 16, color: netColor),
              const SizedBox(width: 4),
              Text('${context.tr(AiToolStrings.network)}: ${context.tr(netLabel)}', key: const Key('voice.network'), style: text.labelSmall),
              const Spacer(),
              Text(context.tr(AiToolStrings.usage.fill({'a': used, 'b': voiceAllowance(plan)})), style: text.labelSmall),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          DropdownButtonFormField<TeachingMode>(
            isExpanded: true,
            initialValue: _mode,
            decoration: InputDecoration(labelText: context.tr(AiToolStrings.mode)),
            items: [for (final m in TeachingMode.values.where((m) => m != TeachingMode.englishCoach)) DropdownMenuItem(value: m, child: Text(context.tr(m.label)))],
            onChanged: (m) => setState(() => _mode = m ?? _mode),
          ),
          ExpansionTile(
            key: const Key('voice.settings'),
            tilePadding: EdgeInsets.zero,
            title: Text(context.tr(AiToolStrings.settings)),
            children: [
              SegmentedButton<String>(
                segments: [
                  const ButtonSegment(value: 'bn', label: Text('বাংলা')),
                  const ButtonSegment(value: 'en', label: Text('English')),
                  ButtonSegment(
                    value: 'mixed',
                    label: Text(context.tr(AiToolStrings.mixed), overflow: TextOverflow.ellipsis),
                  ),
                ],
                emptySelectionAllowed: true,
                selected: {if (_lang != 'auto') _lang},
                onSelectionChanged: (v) => setState(() => _lang = v.isEmpty ? 'auto' : v.first),
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<bool>(
                      initialValue: _male,
                      decoration: InputDecoration(labelText: context.tr(AiToolStrings.voiceType)),
                      items: [
                        DropdownMenuItem(value: false, child: Text(context.tr(AiToolStrings.voiceFemale))),
                        DropdownMenuItem(value: true, child: Text(context.tr(AiToolStrings.voiceMale))),
                      ],
                      onChanged: (v) => setState(() => _male = v ?? _male),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: DropdownButtonFormField<bool>(
                      initialValue: _headset,
                      isExpanded: true,
                      decoration: InputDecoration(labelText: context.tr(AiToolStrings.mic)),
                      items: [
                        DropdownMenuItem(value: false, child: Text(context.tr(AiToolStrings.micPhone))),
                        DropdownMenuItem(value: true, child: Text(context.tr(AiToolStrings.micHeadset))),
                      ],
                      onChanged: (v) => setState(() => _headset = v ?? _headset),
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  Text('${context.tr(AiToolStrings.speed)}: ${_rate.toStringAsFixed(2)}×'),
                  Expanded(
                    child: Slider(key: const Key('voice.speed'), value: _rate, min: 0.5, max: 1.5, divisions: 4, onChanged: (v) => setState(() => _rate = v)),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Center(
            child: _Waveform(active: _state == _VState.listening || _state == _VState.speaking, color: _state == _VState.listening ? c.error : c.primary),
          ),
          const SizedBox(height: AppSpacing.sm),
          Center(
            child: Semantics(liveRegion: true, child: Text(context.tr(status), style: text.titleMedium)),
          ),
          if (_interim.isNotEmpty)
            Center(
              child: Text('“$_interim”', style: text.bodySmall?.copyWith(fontStyle: FontStyle.italic)),
            ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              FilledButton.icon(
                key: const Key('voice.session'),
                onPressed: offline ? null : _toggleSession,
                icon: Icon(_active ? Icons.call_end : Icons.play_arrow),
                label: Text(context.tr(_active ? AiToolStrings.end : AiToolStrings.start)),
              ),
              if (_active && _state == _VState.speaking)
                OutlinedButton.icon(key: const Key('voice.interrupt'), onPressed: _interrupt, icon: const Icon(Icons.pan_tool_outlined), label: Text(context.tr(AiToolStrings.interrupt)))
              else if (_active)
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
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(context.tr(AiToolStrings.handsFree)),
                  Switch(value: _handsFree, onChanged: (v) => setState(() => _handsFree = v)),
                ],
              ),
            ],
          ),
          if (_active && _canListen == false) ...[
            const SizedBox(height: AppSpacing.sm),
            InfoBanner(key: const Key('voice.micDenied'), message: context.tr(AiToolStrings.micDenied), tone: Tone.warning, icon: Icons.mic_off_outlined),
            SectionHeader(title: context.tr(AiToolStrings.sample)),
            Wrap(
              spacing: AppSpacing.xs,
              children: [for (final s in samples) ActionChip(label: Text(s), onPressed: () => _ask(s))],
            ),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              key: const Key('voice.typed'),
              controller: _typed,
              textInputAction: TextInputAction.send,
              decoration: InputDecoration(
                hintText: context.tr(AiToolStrings.typeInstead),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: () {
                    if (_typed.text.trim().isEmpty) return;
                    unawaited(_ask(_typed.text.trim()));
                    _typed.clear();
                  },
                ),
              ),
              onSubmitted: (v) {
                if (v.trim().isEmpty) return;
                unawaited(_ask(v.trim()));
                _typed.clear();
              },
            ),
          ],
          if (_turns.isNotEmpty) ...[
            SectionHeader(title: context.tr(AiToolStrings.transcript)),
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
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                OutlinedButton.icon(key: const Key('voice.toNotes'), onPressed: _toNotes, icon: const Icon(Icons.sticky_note_2_outlined), label: Text(context.tr(AiToolStrings.toNotes))),
                OutlinedButton.icon(key: const Key('voice.summary'), onPressed: _summary, icon: const Icon(Icons.summarize_outlined), label: Text(context.tr(AiToolStrings.toSummary))),
                OutlinedButton.icon(key: const Key('voice.toCards'), onPressed: _toCards, icon: const Icon(Icons.style_outlined), label: Text(context.tr(AiToolStrings.toCards))),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _VoiceHistorySheet extends ConsumerWidget {
  const _VoiceHistorySheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessions = ref.watch(aiToolsProvider).sessions;
    return SizedBox(
      height: MediaQuery.sizeOf(context).height * 0.7,
      child: sessions.isEmpty
          ? EmptyState(title: context.tr(AiToolStrings.noHistory), icon: Icons.history)
          : ListView(
              padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.lg),
              children: [
                Text(context.tr(AiToolStrings.history), style: Theme.of(context).textTheme.titleMedium),
                for (final s in sessions)
                  ExpansionTile(
                    tilePadding: EdgeInsets.zero,
                    title: Text(s.title.isEmpty ? '—' : s.title),
                    subtitle: Text('${relativeTime(s.startedAt, context.lang)} · ${context.n(s.minutes)} min · ${context.tr(TeachingMode.values.byName(s.mode).label)}'),
                    trailing: IconButton(icon: const Icon(Icons.delete_outline), onPressed: () => ref.read(aiToolsProvider.notifier).deleteSession(s.id)),
                    children: [
                      for (final (st, t) in s.turns)
                        ListTile(
                          dense: true,
                          leading: Icon(st ? Icons.person_outline : Icons.smart_toy_outlined, size: 18),
                          title: Text(t, maxLines: 4, overflow: TextOverflow.ellipsis),
                        ),
                    ],
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

/// Accepted image types and size (IMG-08).
bool validImageFile(String path, int bytes) {
  final ext = path.split('.').last.toLowerCase();
  return const {'jpg', 'jpeg', 'png', 'heic', 'webp'}.contains(ext) && bytes <= 10 * 1024 * 1024;
}

enum CropArea {
  full(AiToolStrings.cropFull, Alignment.center, 1),
  top(AiToolStrings.cropTop, Alignment.topCenter, 0.5),
  bottom(AiToolStrings.cropBottom, Alignment.bottomCenter, 0.5),
  center(AiToolStrings.cropCenter, Alignment.center, 0.6);

  const CropArea(this.label, this.alignment, this.heightFactor);

  final Tr label;
  final Alignment alignment;
  final double heightFactor;
}

class _Shot {
  _Shot(this.path);

  final String? path;
  int turns = 0;
  CropArea crop = CropArea.full;
}

class PhotoSolverScreen extends ConsumerStatefulWidget {
  const PhotoSolverScreen({super.key});

  @override
  ConsumerState<PhotoSolverScreen> createState() => _PhotoSolverScreenState();
}

class _PhotoSolverScreenState extends ConsumerState<PhotoSolverScreen> {
  final List<_Shot> _shots = [];
  int _current = 0;
  bool _reading = false;
  final _text = TextEditingController();
  Question? _detected;
  String? _chapterId;
  TutorReply? _answer;
  bool _solving = false;

  /// API mode: the server's photo-solver job and the subject it detected.
  String? _jobId;
  String? _subjectId;

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  Future<void> _pick(ImageSource? source, {bool add = false, bool multi = false}) async {
    final paths = <String?>[];
    if (source == null) {
      paths.add(null);
    } else {
      try {
        final picker = ImagePicker();
        final files = multi ? await picker.pickMultiImage(maxWidth: 1600, imageQuality: 80) : [?await picker.pickImage(source: source, maxWidth: 1600, imageQuality: 80)];
        for (final f in files) {
          if (!validImageFile(f.path, await f.length())) {
            if (mounted) context.showSnack(AiToolStrings.badFile);
            continue;
          }
          paths.add(f.path);
        }
      } on Object {
        // Picker unavailable (simulator / tests).
      }
      if (paths.isEmpty) return;
    }
    setState(() {
      if (!add) _shots.clear();
      _shots.addAll(paths.map(_Shot.new));
      _current = _shots.length - 1;
      _answer = null;
    });
    await _read();
  }

  Future<void> _read() async {
    setState(() => _reading = true);
    final remote = ref.read(remoteAiToolsProvider);
    final path = _shots.isEmpty ? null : _shots[_current].path;
    if (remote != null && path != null) {
      // API mode: the AI service reads the photo; the job is kept in the server history.
      try {
        final r = await remote.readPhoto(path);
        if (!mounted) return;
        setState(() {
          _jobId = r.jobId;
          _subjectId = r.subjectId;
          _detected = null;
          _chapterId = null;
          _text.text = r.text;
          _reading = false;
        });
        if (!r.readable && mounted) context.showSnack(AiToolStrings.badFile);
      } on ApiException catch (e) {
        if (!mounted) return;
        setState(() => _reading = false);
        context.showErrorSnack(e);
      }
      return;
    }
    _jobId = null;
    try {
      final key = _shots.map((s) => s.path ?? 'demo').join('|');
      final q = await ref.read(mockSimulatorProvider).run(() {
        final bank = ref.read(questionRepositoryProvider).cached;
        return _ocr(bank, key.hashCode);
      }, latencyFactor: 3);
      if (!mounted) return;
      setState(() {
        _detected = q;
        _chapterId = q.chapterId;
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
      final remote = ref.read(remoteAiToolsProvider);
      final ctx = _context(ref, context, TeachingMode.stepByStep);
      final r = remote != null
          // API mode: step-by-step solution from the AI service (stored on the photo job).
          ? TutorReply(
              text: await remote.solve(_text.text, jobId: _jobId, subjectId: _subjectId ?? _detected?.subjectId, chapterId: _chapterId),
              grounding: Grounding.general,
              confidence: 0.8,
            )
          : await ref
          .read(mockSimulatorProvider)
          .run(
            () => ref
                .read(mockTutorEngineProvider)
                .answer(
                  query: _text.text,
                  context: TutorContext(
                    level: ctx.level,
                    classYear: ctx.classYear,
                    curriculumVersionId: ctx.curriculumVersionId,
                    mode: ctx.mode,
                    language: ctx.language,
                    subjectId: _detected?.subjectId,
                    chapterId: _chapterId,
                  ),
                ),
            latencyFactor: 2,
          );
      if (!mounted) return;
      setState(() => _answer = r);
      await ref
          .read(aiToolsProvider.notifier)
          .addSolve(
            PhotoSolve(
              id: 'ps-${DateTime.now().microsecondsSinceEpoch}',
              at: DateTime.now(),
              text: _text.text,
              subjectId: _subjectId ?? _detected?.subjectId ?? '',
              chapterId: _chapterId,
              answer: r.text,
              images: _shots.length,
            ),
          );
    } on ApiException catch (e) {
      if (mounted) context.showErrorSnack(e);
    } finally {
      if (mounted) setState(() => _solving = false);
    }
  }

  Future<void> _crop() async {
    final shot = _shots[_current];
    final c = await showDialog<CropArea>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: Text(ctx.tr(AiToolStrings.crop)),
        children: [
          for (final a in CropArea.values)
            ListTile(leading: Icon(a == shot.crop ? Icons.radio_button_checked : Icons.radio_button_unchecked), title: Text(ctx.tr(a.label)), onTap: () => Navigator.pop(ctx, a)),
        ],
      ),
    );
    if (c != null) setState(() => shot.crop = c);
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final has = _shots.isNotEmpty;
    final subject = _detected == null ? null : subjectById(_detected!.subjectId);
    final recent = ref.watch(aiToolsProvider).solves;
    final bookmarks = ref.watch(practiceProvider).bookmarks;
    return AppPageScaffold(
      title: context.tr(AiToolStrings.photo),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(child: Text(context.tr(AiToolStrings.photoHint))),
              const SimulatedBadge(),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              FilledButton.icon(onPressed: () => _pick(ImageSource.camera), icon: const Icon(Icons.photo_camera_outlined), label: Text(context.tr(AiToolStrings.camera))),
              OutlinedButton.icon(onPressed: () => _pick(ImageSource.gallery, multi: true), icon: const Icon(Icons.photo_library_outlined), label: Text(context.tr(AiToolStrings.gallery))),
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
                  quarterTurns: _shots[_current].turns,
                  child: ClipRect(
                    child: Align(
                      alignment: _shots[_current].crop.alignment,
                      heightFactor: _shots[_current].crop.heightFactor,
                      child: _shots[_current].path != null && File(_shots[_current].path!).existsSync()
                          ? Image.file(File(_shots[_current].path!), fit: BoxFit.cover, width: double.infinity)
                          : SizedBox(
                              height: 180,
                              child: ColoredBox(
                                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                                child: const Center(child: Icon(Icons.description_outlined, size: 64)),
                              ),
                            ),
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(
              height: 44,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  for (var i = 0; i < _shots.length; i++)
                    Padding(
                      padding: const EdgeInsets.only(right: AppSpacing.xs, top: AppSpacing.xs),
                      child: ChoiceChip(label: Text(context.n(i + 1)), selected: i == _current, onSelected: (_) => setState(() => _current = i)),
                    ),
                  Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.xs),
                    child: ActionChip(
                      key: const Key('photo.addImage'),
                      avatar: const Icon(Icons.add, size: 16),
                      label: Text(context.tr(AiToolStrings.multi.fill({'n': _shots.length}))),
                      onPressed: () => _pick(null, add: true),
                    ),
                  ),
                ],
              ),
            ),
            Wrap(
              children: [
                TextButton.icon(
                  onPressed: () => setState(() => _shots[_current].turns = (_shots[_current].turns + 1) % 4),
                  icon: const Icon(Icons.rotate_right),
                  label: Text(context.tr(AiToolStrings.rotate)),
                ),
                TextButton.icon(key: const Key('photo.crop'), onPressed: _crop, icon: const Icon(Icons.crop), label: Text(context.tr(AiToolStrings.crop))),
                TextButton.icon(onPressed: () => _pick(ImageSource.camera), icon: const Icon(Icons.refresh), label: Text(context.tr(AiToolStrings.retake))),
              ],
            ),
          ],
          if (_reading) ...[const LinearProgressIndicator(), const SizedBox(height: AppSpacing.xs), Text(context.tr(AiToolStrings.reading))],
          if (_detected != null && !_reading) ...[
            SectionHeader(title: context.tr(AiToolStrings.extracted)),
            TextField(key: const Key('photo.text'), controller: _text, minLines: 2, maxLines: 6),
            const SizedBox(height: AppSpacing.xs),
            Row(
              children: [
                Expanded(child: Text(context.tr(AiToolStrings.detected.fill({'s': subject == null ? _detected!.subjectId : context.tr(subject.name)})), style: text.bodySmall)),
                TextButton.icon(
                  key: const Key('photo.report'),
                  onPressed: () async {
                    await ref.read(aiToolsProvider.notifier).reportOcr();
                    if (context.mounted) context.showSnack(AiToolStrings.reportedOcr);
                  },
                  icon: const Icon(Icons.flag_outlined, size: 18),
                  label: Text(context.tr(AiToolStrings.reportOcr)),
                ),
              ],
            ),
            if (subject != null)
              DropdownButtonFormField<String>(
                isExpanded: true,
                initialValue: subject.chapters.any((c) => c.id == _chapterId) ? _chapterId : subject.chapters.first.id,
                decoration: InputDecoration(labelText: context.tr(AiToolStrings.chapter)),
                items: [
                  for (final ch in subject.chapters)
                    DropdownMenuItem(
                      value: ch.id,
                      child: Text(context.tr(ch.title), overflow: TextOverflow.ellipsis),
                    ),
                ],
                onChanged: (v) => setState(() => _chapterId = v),
              ),
            const SizedBox(height: AppSpacing.sm),
            FilledButton.icon(key: const Key('photo.solve'), onPressed: _solving ? null : _solve, icon: const Icon(Icons.auto_awesome), label: Text(context.tr(AiToolStrings.solve))),
          ],
          if (_solving) const Padding(padding: EdgeInsets.all(AppSpacing.md), child: LinearProgressIndicator()),
          if (_answer != null) ...[
            SectionHeader(title: context.tr(AiToolStrings.solution)),
            Card(
              margin: EdgeInsets.zero,
              child: Padding(padding: const EdgeInsets.all(AppSpacing.md), child: RichContent(_answer!.text)),
            ),
            if (_detected?.explanation != null) ...[SectionHeader(title: context.tr(AiToolStrings.explanation)), RichContent(context.tr(_detected!.explanation!))],
            if (_answer!.sources.isNotEmpty)
              Wrap(
                spacing: AppSpacing.xs,
                children: [
                  for (final s in _answer!.sources)
                    ActionChip(
                      avatar: const Icon(Icons.menu_book_outlined, size: 16),
                      label: Text('${s.chapterTitle} · ${context.n(s.page)}'),
                      onPressed: () => context.push(AppRoutes.bookReader(s.bookId, page: s.page)),
                    ),
                ],
              ),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                OutlinedButton.icon(
                  key: const Key('photo.saveNote'),
                  onPressed: () async {
                    await ref
                        .read(notesProvider.notifier)
                        .create(
                          title: _text.text.length > 50 ? '${_text.text.substring(0, 50)}…' : _text.text,
                          body: '${_text.text}\n\n${_answer!.text}',
                          source: NoteSource.question,
                          subjectId: _detected?.subjectId,
                          chapterId: _chapterId,
                          aiGenerated: true,
                        );
                    if (context.mounted) context.showSnack(AiToolStrings.savedNotes);
                  },
                  icon: const Icon(Icons.sticky_note_2_outlined),
                  label: Text(context.tr(AiToolStrings.saveNote)),
                ),
                OutlinedButton.icon(
                  key: const Key('photo.practice'),
                  onPressed: _detected == null || bookmarks.contains(_detected!.id)
                      ? null
                      : () async {
                          await ref.read(practiceProvider.notifier).toggleBookmark(_detected!.id);
                          if (context.mounted) context.showSnack(AiToolStrings.addedPractice);
                        },
                  icon: Icon(_detected != null && bookmarks.contains(_detected!.id) ? Icons.bookmark_added : Icons.playlist_add),
                  label: Text(context.tr(AiToolStrings.addPractice)),
                ),
              ],
            ),
          ],
          if (recent.isNotEmpty) ...[
            SectionHeader(title: context.tr(AiToolStrings.recent)),
            for (final r in recent.take(5))
              ExpansionTile(
                tilePadding: EdgeInsets.zero,
                leading: const Icon(Icons.history),
                title: Text(r.text, maxLines: 1, overflow: TextOverflow.ellipsis),
                subtitle: Text(relativeTime(r.at, context.lang)),
                children: [RichContent(r.answer)],
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

/// Simulated OCR of an answer script: the model answer with a few student-style slips.
String simulatedScriptText(Question q, AppLanguage lang, int pages) {
  final answer = q.answer.of(lang).replaceAll(RegExp(r'[*#$=]'), '');
  final words = answer.split(RegExp(r'\s+'));
  final keep = (words.length * (0.6 + math.min(0.35, pages * 0.1))).round().clamp(1, words.length);
  return words.take(keep).join(' ');
}

class HandwritingScreen extends ConsumerStatefulWidget {
  const HandwritingScreen({super.key});

  @override
  ConsumerState<HandwritingScreen> createState() => _HandwritingScreenState();
}

class _HandwritingScreenState extends ConsumerState<HandwritingScreen> {
  final List<_Shot> _pages = [];
  final _ocrText = TextEditingController();
  String? _questionId;
  HandwritingResult? _result;
  EvaluationRecord? _record;
  bool _busy = false;
  bool _ocrDone = false;

  @override
  void dispose() {
    _ocrText.dispose();
    super.dispose();
  }

  Future<void> _add(ImageSource? source) async {
    if (source == null) return setState(() => _pages.add(_Shot(null)));
    try {
      final f = await ImagePicker().pickImage(source: source, maxWidth: 1600, imageQuality: 80);
      if (f == null) return;
      if (!validImageFile(f.path, await f.length())) {
        if (mounted) context.showSnack(AiToolStrings.badFile);
        return;
      }
      setState(() => _pages.add(_Shot(f.path)));
    } on Object {
      // Picker unavailable (simulator/tests): ignore.
    }
  }

  /// API mode: the evaluation record marked on the server.
  String? _serverEvalId;

  void _reset() => setState(() {
    _serverEvalId = null;
    _pages.clear();
    _result = null;
    _record = null;
    _ocrDone = false;
    _ocrText.clear();
  });

  Future<void> _runOcr(Question q) async {
    if (_pages.isEmpty) return context.showSnack(AiToolStrings.needPage);
    final lang = context.lang;
    setState(() => _busy = true);
    try {
      final remote = ref.read(remoteAiToolsProvider);
      final paths = [for (final p in _pages) ?p.path];
      // API mode: the AI service transcribes the photographed pages.
      final t = remote != null && paths.isNotEmpty
          ? await remote.transcribe(paths)
          : await ref.read(mockSimulatorProvider).run(() => simulatedScriptText(q, lang, _pages.length), latencyFactor: 2);
      if (mounted) {
        setState(() {
          _ocrText.text = t;
          _ocrDone = true;
        });
      }
    } on ApiException catch (e) {
      if (mounted) context.showErrorSnack(e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// API mode: marks the script with the AI service (pages, or the corrected transcription).
  Future<HandwritingResult?> _evaluateRemote(RemoteAiTools remote, Question q) async {
    final paths = [for (final p in _pages) ?p.path];
    if (paths.isEmpty) return null;
    final total = math.max(q.marks, 4);
    final n = q.rubric.length;
    final rubric = n > 0
        ? [for (final (i, r) in q.rubric.indexed) (r.bn, i == n - 1 ? total - (total ~/ n) * (n - 1) : total ~/ n)]
        : [('ধারণার নির্ভুলতা', (total * 0.4).round()), ('হিসাব / যুক্তি', (total * 0.3).round()), ('উপস্থাপন ও একক', total - (total * 0.4).round() - (total * 0.3).round())];
    final id = 'ev-${DateTime.now().microsecondsSinceEpoch}';
    final ev = await remote.evaluate(
      id: id,
      studentName: ref.read(studentProfileProvider).name,
      title: q.stem.bn.replaceAll(RegExp(r'[*#$]'), '').split('\n').first,
      subjectId: q.subjectId,
      questionId: q.id,
      questionText: q.stem.bn,
      modelAnswer: q.answer.bn,
      pagePaths: paths,
      rubric: rubric,
      ocrText: _ocrText.text,
      correctedText: _ocrDone && _ocrText.text.trim().isNotEmpty ? _ocrText.text : null,
    );
    _serverEvalId = id;
    final crit = [
      for (final r in ev['rubric'] as List? ?? const [])
        (Tr.same((r as Map)['criterion'] as String? ?? ''), ((r['ai'] as num?) ?? 0).toDouble(), ((r['max'] as num?) ?? 0).round()),
    ];
    List<Tr> texts(Object? v) => [for (final x in v as List? ?? const []) Tr.same('$x')];
    return HandwritingResult(
      marks: ((ev['aiMarks'] as num?) ?? 0).toDouble(),
      total: ((ev['maxMarks'] as num?) ?? total).round(),
      criteria: crit,
      strengths: const [],
      missing: texts(ev['missingPoints']),
      tips: texts(ev['suggestions']),
    );
  }

  Future<void> _evaluate(Question q) async {
    setState(() => _busy = true);
    try {
      final remote = ref.read(remoteAiToolsProvider);
      final server = remote == null ? null : await _evaluateRemote(remote, q);
      final HandwritingResult r = server ?? await ref.read(mockSimulatorProvider).run(() => evaluateHandwriting(q, _pages.length), latencyFactor: 3);
      final rec = EvaluationRecord(
        id: 'ev-${DateTime.now().microsecondsSinceEpoch}',
        at: DateTime.now(),
        questionId: q.id,
        pages: _pages.length,
        marks: r.marks,
        total: r.total,
        criteria: r.criteria,
        extracted: _ocrText.text,
      );
      await ref.read(aiToolsProvider.notifier).addEvaluation(rec);
      if (mounted) {
        setState(() {
          _result = r;
          _record = rec;
        });
      }
    } on ApiException catch (e) {
      if (mounted) context.showErrorSnack(e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// Sends the script to the teacher portal's evaluation queue.
  Future<void> _requestReview(Question q) async {
    final rec = _record;
    final r = _result;
    if (rec == null || r == null) return;
    final remote = ref.read(remoteEvaluationProvider);
    final title = context.tr(q.stem).replaceAll(RegExp(r'[*#$]'), '').split('\n').first;
    // API mode: the script the AI marked is already on the server; ask a teacher to review it.
    final tools = ref.read(remoteAiToolsProvider);
    if (tools != null && _serverEvalId != null) {
      try {
        await tools.requestReview(_serverEvalId!);
      } on ApiException catch (e) {
        if (mounted) context.showErrorSnack(e);
        return;
      }
      await ref.read(aiToolsProvider.notifier).linkSubmission(rec.id, _serverEvalId!);
      if (mounted) {
        setState(() => _record = rec.withSubmission(_serverEvalId!));
        context.showSnack(AiToolStrings.reviewRequested);
      }
      return;
    }
    if (remote != null) {
      try {
        await remote.send(RemoteEvaluation.recordFor(
          id: 'ev-${rec.id}',
          studentId: remote.studentId,
          studentName: ref.read(studentProfileProvider).name,
          question: q,
          title: title,
          pages: rec.pages,
          aiMarks: r.marks,
          maxMarks: r.total,
          criteria: r.criteria,
          missing: r.missing,
          tips: r.tips,
          ocrText: rec.extracted,
        ));
      } on ApiException catch (e) {
        if (mounted) context.showErrorSnack(e);
        return;
      }
      await ref.read(aiToolsProvider.notifier).linkSubmission(rec.id, 'ev-${rec.id}');
      if (mounted) {
        setState(() => _record = rec.withSubmission('ev-${rec.id}'));
        context.showSnack(AiToolStrings.reviewRequested);
      }
      return;
    }
    final sub = Submission(
      id: 'sub-${rec.id}',
      student: selfChildName,
      classId: teacherClasses.firstWhere((c) => c.subjectId == q.subjectId, orElse: () => teacherClasses.first).id,
      title: context.tr(q.stem).replaceAll(RegExp(r'[*#$]'), '').split('\n').first,
      aiMarks: r.marks,
      total: r.total,
      pages: rec.pages,
    );
    await ref.read(teacherProvider.notifier).addSubmission(sub);
    await ref.read(aiToolsProvider.notifier).linkSubmission(rec.id, sub.id);
    if (mounted) {
      setState(() => _record = rec.withSubmission(sub.id));
      context.showSnack(AiToolStrings.reviewRequested);
    }
  }

  String _feedbackText(Question q, HandwritingResult r) => [
    '${context.tr(AiToolStrings.handwriting)} — ${context.tr(q.stem).replaceAll(RegExp(r'[*#$]'), '')}',
    '${context.tr(AiToolStrings.estimate)}: ${r.marks}/${r.total}',
    for (final (n, g, m) in r.criteria) '• ${context.tr(n)}: ${math.min(g, m.toDouble())}/$m',
    '',
    '${context.tr(AiToolStrings.strengths)}: ${r.strengths.map(context.tr).join('; ')}',
    '${context.tr(AiToolStrings.missing)}: ${r.missing.map(context.tr).join('; ')}',
    '${context.tr(AiToolStrings.tips)}: ${r.tips.map(context.tr).join('; ')}',
    '',
    context.tr(AiToolStrings.estimateNote),
  ].join('\n');

  @override
  Widget build(BuildContext context) {
    final bank = [
      for (final q in ref.watch(questionRepositoryProvider).cached)
        if (q.type != QuestionType.mcq) q,
    ];
    final q = bank.where((x) => x.id == _questionId).firstOrNull ?? (bank.isEmpty ? null : bank.first);
    final text = Theme.of(context).textTheme;
    final history = ref.watch(aiToolsProvider).evaluations;
    final submissions = {for (final s in ref.watch(teacherProvider).submissions) s.id: s};
    final previous = q == null || _record == null ? null : history.where((e) => e.questionId == q.id && e.id != _record!.id).firstOrNull;
    final sub = _record?.submissionId == null ? null : submissions[_record!.submissionId];
    return AppPageScaffold(
      title: context.tr(AiToolStrings.handwriting),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(child: Text(context.tr(AiToolStrings.hwHint))),
              const SimulatedBadge(),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          if (q != null)
            DropdownButtonFormField<String>(
              isExpanded: true,
              initialValue: q.id,
              decoration: InputDecoration(labelText: context.tr(AiToolStrings.question)),
              items: [
                for (final x in bank)
                  DropdownMenuItem(
                    value: x.id,
                    child: Text(context.tr(x.stem).replaceAll(RegExp(r'[*#$]'), ''), maxLines: 1, overflow: TextOverflow.ellipsis),
                  ),
              ],
              onChanged: (v) => setState(() {
                _questionId = v;
                _result = null;
                _record = null;
                _ocrDone = false;
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
                      key: ObjectKey(p),
                      width: 72,
                      margin: const EdgeInsets.only(right: AppSpacing.sm),
                      decoration: BoxDecoration(color: Theme.of(context).colorScheme.surfaceContainerHighest, borderRadius: BorderRadius.circular(8)),
                      child: Stack(
                        children: [
                          Center(child: Text(context.n(i + 1), style: text.titleLarge)),
                          Positioned(
                            right: 0,
                            top: 0,
                            child: IconButton(visualDensity: VisualDensity.compact, iconSize: 16, onPressed: () => setState(() => _pages.removeAt(i)), icon: const Icon(Icons.close)),
                          ),
                          Positioned(
                            left: 0,
                            bottom: 0,
                            child: IconButton(
                              tooltip: context.tr(AiToolStrings.crop),
                              visualDensity: VisualDensity.compact,
                              iconSize: 16,
                              onPressed: () => setState(() => p.crop = CropArea.values[(p.crop.index + 1) % CropArea.values.length]),
                              icon: Icon(p.crop == CropArea.full ? Icons.crop_free : Icons.crop),
                            ),
                          ),
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
          if (!_ocrDone)
            FilledButton.icon(
              key: const Key('hw.evaluate'),
              onPressed: _busy || q == null
                  ? null
                  : () async {
                      await _runOcr(q);
                      if (_ocrDone && mounted) await _evaluate(q);
                    },
              icon: const Icon(Icons.fact_check_outlined),
              label: Text(context.tr(AiToolStrings.evaluate)),
            ),
          if (_busy) const Padding(padding: EdgeInsets.all(AppSpacing.md), child: LinearProgressIndicator()),
          if (_ocrDone && q != null) ...[
            SectionHeader(title: context.tr(AiToolStrings.mapped)),
            Text(context.tr(q.stem).replaceAll(RegExp(r'[*#$]'), ''), style: text.bodySmall),
            const SizedBox(height: AppSpacing.sm),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(context.tr(AiToolStrings.original), style: text.labelMedium),
                      const SizedBox(height: 4),
                      Container(
                        height: 120,
                        decoration: BoxDecoration(color: Theme.of(context).colorScheme.surfaceContainerHighest, borderRadius: BorderRadius.circular(8)),
                        child: const Center(child: Icon(Icons.draw_outlined, size: 40)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(context.tr(AiToolStrings.ocrText), style: text.labelMedium),
                      const SizedBox(height: 4),
                      TextField(key: const Key('hw.ocr'), controller: _ocrText, minLines: 5, maxLines: 5, style: text.bodySmall),
                    ],
                  ),
                ),
              ],
            ),
            SectionHeader(title: context.tr(AiToolStrings.compare)),
            ExpansionTile(tilePadding: EdgeInsets.zero, title: Text(context.tr(AiToolStrings.modelAnswer)), children: [RichContent(context.tr(q.answer))]),
          ],
          if (_result case final r?) ...[
            SectionHeader(title: context.tr(AiToolStrings.estimate)),
            Row(
              children: [
                Text('${context.n(r.marks)} / ${context.n(r.total)}', key: const Key('hw.marks'), style: text.headlineMedium),
                const SizedBox(width: AppSpacing.sm),
                Pill(
                  context.tr(switch (sub) {
                    null => AiToolStrings.stageAi,
                    final x when x.official => AiToolStrings.stageOfficial,
                    final x when x.reviewed => AiToolStrings.stageTeacher,
                    _ => AiToolStrings.stageRequested,
                  }),
                  tone: sub == null ? Tone.warning : (sub.reviewed ? Tone.success : Tone.info),
                ),
              ],
            ),
            if (sub != null && sub.reviewed)
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.xs),
                child: Text(
                  '${context.tr(sub.official ? AiToolStrings.stageOfficial : AiToolStrings.stageTeacher)}: ${context.n(sub.finalMarks!)}/${context.n(sub.total)}${(sub.feedback ?? '').isEmpty ? '' : ' — ${sub.feedback}'}',
                  style: text.titleSmall,
                ),
              ),
            if (previous != null)
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.xs),
                child: Text(
                  context.tr(
                    AiToolStrings.beforeAfter.fill({'d': '${context.n(previous.marks)} → ${context.n(r.marks)} (${r.marks >= previous.marks ? '+' : ''}${context.n(r.marks - previous.marks)})'}),
                  ),
                  key: const Key('hw.compare'),
                  style: text.bodySmall,
                ),
              ),
            for (final (name, got, max) in r.criteria)
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.xs),
                child: Row(
                  children: [
                    Expanded(child: Text(context.tr(name))),
                    Text('${context.n(math.min(got, max.toDouble()))} / ${context.n(max)}'),
                  ],
                ),
              ),
            const SizedBox(height: AppSpacing.sm),
            for (final (title, items, icon) in [
              (AiToolStrings.strengths, r.strengths, Icons.check_circle_outline),
              (AiToolStrings.missing, r.missing, Icons.error_outline),
              (AiToolStrings.tips, r.tips, Icons.lightbulb_outline),
            ]) ...[
              Text(context.tr(title), style: text.titleSmall),
              for (final t in items) ListTile(dense: true, contentPadding: EdgeInsets.zero, leading: Icon(icon, size: 18), title: Text(context.tr(t))),
            ],
            InfoBanner(message: context.tr(AiToolStrings.estimateNote), tone: Tone.warning),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                OutlinedButton.icon(
                  key: const Key('hw.review'),
                  onPressed: _record?.submissionId != null || q == null ? null : () => _requestReview(q),
                  icon: Icon(_record?.submissionId != null ? Icons.check : Icons.send_outlined),
                  label: Text(context.tr(_record?.submissionId != null ? AiToolStrings.reviewRequested : AiToolStrings.teacherReview)),
                ),
                OutlinedButton.icon(
                  key: const Key('hw.export'),
                  onPressed: q == null
                      ? null
                      : () async {
                          await Clipboard.setData(ClipboardData(text: _feedbackText(q, r)));
                          if (context.mounted) context.showSnack(AiToolStrings.exported);
                        },
                  icon: const Icon(Icons.copy),
                  label: Text(context.tr(AiToolStrings.export)),
                ),
                OutlinedButton.icon(key: const Key('hw.reattempt'), onPressed: _reset, icon: const Icon(Icons.replay), label: Text(context.tr(AiToolStrings.reattempt))),
              ],
            ),
          ],
          if (history.isNotEmpty) ...[
            SectionHeader(title: context.tr(AiToolStrings.evalHistory)),
            for (final e in history.take(8))
              Builder(
                builder: (context) {
                  final hq = ref.read(questionRepositoryProvider).cached.where((x) => x.id == e.questionId).firstOrNull;
                  final s = e.submissionId == null ? null : submissions[e.submissionId];
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(s?.official ?? false ? Icons.verified : Icons.description_outlined),
                    title: Text(hq == null ? '—' : context.tr(hq.stem).replaceAll(RegExp(r'[*#$]'), ''), maxLines: 1, overflow: TextOverflow.ellipsis),
                    subtitle: Text(
                      '${relativeTime(e.at, context.lang)} · ${context.tr(s == null ? AiToolStrings.stageAi : (s.official ? AiToolStrings.stageOfficial : (s.reviewed ? AiToolStrings.stageTeacher : AiToolStrings.stageRequested)))}',
                    ),
                    trailing: Text(s?.finalMarks != null ? '${context.n(s!.finalMarks!)}/${context.n(e.total)}' : '~${context.n(e.marks)}/${context.n(e.total)}'),
                  );
                },
              ),
          ],
        ],
      ),
    );
  }
}
