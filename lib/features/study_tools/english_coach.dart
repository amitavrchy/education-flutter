import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/l10n/tr.dart';
import '../../core/mock/mock_simulator.dart';
import '../../core/network/api_exception.dart';
import '../../core/network/network_providers.dart';
import '../../core/storage/local_store.dart';
import '../progress/data/remote_progress.dart';
import '../../core/theme/app_spacing.dart';
import '../../shared/widgets/app_page_scaffold.dart';
import '../../shared/widgets/badges.dart';
import '../../shared/widgets/feedback.dart';
import '../../shared/widgets/progress.dart';
import '../../shared/widgets/rich_content.dart';
import '../../shared/widgets/section_header.dart';
import '../ai_tutor/data/ai_tutor_repository.dart';
import '../ai_tutor/domain/tutor_models.dart';
import '../book_avatar/application/avatar_voice.dart';
import '../flashcards/application/flashcards_controller.dart';

abstract final class EngStrings {
  static const title = Tr('ইংরেজি কোচ', 'English coach');
  static const progress = Tr('অগ্রগতি', 'Progress');
  static const writing = Tr('লেখা যাচাই', 'Writing check');
  static const vocab = Tr('শব্দভাণ্ডার', 'Vocabulary');
  static const grammar = Tr('গ্রামার কুইজ', 'Grammar quiz');
  static const correction = Tr('বাক্য সংশোধন', 'Sentence correction');
  static const reading = Tr('রিডিং', 'Reading');
  static const listening = Tr('লিসেনিং', 'Listening');
  static const speaking = Tr('বলা অনুশীলন', 'Speaking');
  static const exam = Tr('মক স্পিকিং পরীক্ষা', 'Mock speaking exam');
  static const writeHint = Tr('একটি বাক্য বা অনুচ্ছেদ লেখো…', 'Write a sentence or paragraph…');
  static const writingType = Tr('লেখার ধরন', 'Writing type');
  static const sentence = Tr('বাক্য', 'Sentence');
  static const paragraph = Tr('অনুচ্ছেদ', 'Paragraph');
  static const essay = Tr('রচনা', 'Essay');
  static const composition = Tr('কম্পোজিশন', 'Composition');
  static const email = Tr('ইমেইল', 'Email');
  static const prompt = Tr('বিষয়: {p}', 'Topic: {p}');
  static const words = Tr('{n} শব্দ (লক্ষ্য {t}+)', '{n} words (aim {t}+)');
  static const check = Tr('যাচাই করো', 'Check');
  static const structure = Tr('গঠন', 'Structure');
  static const structureOk = Tr('শুরু, মূল অংশ ও উপসংহার আছে', 'Has an opening, body and conclusion');
  static const structureMissing = Tr('অনুচ্ছেদে ভাগ করে শুরু ও উপসংহার যোগ করো', 'Split into paragraphs with an opening and a conclusion');
  static const emailParts = Tr('সম্বোধন ও সমাপ্তি', 'Greeting & sign-off');
  static const meaning = Tr('অর্থ', 'Meaning');
  static const example = Tr('উদাহরণ', 'Example');
  static const known = Tr('জানি', 'I know it');
  static const next = Tr('পরেরটা', 'Next');
  static const knownCount = Tr('{n}/{t} শব্দ শেখা', '{n}/{t} words learned');
  static const toFlashcards = Tr('ফ্ল্যাশকার্ডে যোগ', 'Add to flashcards');
  static const addedFlashcards = Tr('শব্দগুলো ফ্ল্যাশকার্ড ডেকে যোগ হয়েছে', 'Words added as a flashcard deck');
  static const score = Tr('স্কোর: {s}/{t}', 'Score: {s}/{t}');
  static const restart = Tr('আবার শুরু', 'Restart');
  static const why = Tr('কেন: {w}', 'Why: {w}');
  static const correctThis = Tr('ভুলটি ঠিক করে লেখো:', 'Rewrite it correctly:');
  static const correct = Tr('সঠিক!', 'Correct!');
  static const notQuite = Tr('প্রায় — সঠিক: {a}', 'Not quite — correct: {a}');
  static const passage = Tr('অনুচ্ছেদ', 'Passage');
  static const play = Tr('শোনো', 'Play');
  static const showTranscript = Tr('লেখা দেখাও', 'Show transcript');
  static const submit = Tr('জমা দাও', 'Submit');
  static const speakHint = Tr('মাইক চেপে একটি ইংরেজি বাক্য বলো — বা লিখে দাও। কোচ সংশোধন করবে ও উচ্চারণ শুনিয়ে দেবে।', 'Tap the mic and say an English sentence — or type it. The coach corrects it and reads it back.');
  static const listen = Tr('শোনো', 'Listen');
  static const micOff = Tr('এই ডিভাইসে কণ্ঠ শনাক্তকরণ নেই — লিখে দাও।', 'Speech recognition is unavailable here — type instead.');
  static const pronunciation = Tr('উচ্চারণ অনুশীলন (সিমুলেটেড)', 'Pronunciation practice (simulated)');
  static const sayThis = Tr('এই বাক্যটি বলো:', 'Say this sentence:');
  static const pronScore = Tr('উচ্চারণ স্কোর: {n}% — মিস হওয়া শব্দ: {w}', 'Pronunciation score: {n}% — missed words: {w}');
  static const examIntro = Tr('৩টি প্রশ্ন, প্রতিটিতে ৪৫ সেকেন্ড। মাইকে বা লিখে উত্তর দাও।', '3 prompts, 45 seconds each. Answer by voice or typing.');
  static const startExam = Tr('পরীক্ষা শুরু', 'Start exam');
  static const examQ = Tr('প্রশ্ন {n}/{t}', 'Prompt {n}/{t}');
  static const examDone = Tr('পরীক্ষা শেষ — আনুমানিক ব্যান্ড: {b}', 'Exam done — estimated band: {b}');
  static const fluency = Tr('সাবলীলতা', 'Fluency');
  static const vocabRange = Tr('শব্দভাণ্ডার', 'Vocabulary range');
  static const accuracy = Tr('নির্ভুলতা', 'Accuracy');
  static const plan = Tr('তোমার উন্নতির পরিকল্পনা', 'Your improvement plan');
  static const planLine = Tr('{s}: প্রতিদিন ১০ মিনিট — এখন {n}%', '{s}: 10 minutes a day — now {n}%');
  static const noScores = Tr('কোনো অনুশীলন এখনো হয়নি — যেকোনো ট্যাব থেকে শুরু করো।', 'No practice yet — start from any tab.');
  static const simulatedScore = Tr('স্কোর সিমুলেটেড — আসল পরীক্ষকের মূল্যায়ন নয়।', 'Scores are simulated — not an examiner’s assessment.');
}

enum EngSkill {
  grammar(EngStrings.grammar),
  vocabulary(EngStrings.vocab),
  writing(EngStrings.writing),
  reading(EngStrings.reading),
  listening(EngStrings.listening),
  speaking(EngStrings.speaking);

  const EngSkill(this.label);

  final Tr label;
}

/// Scores per skill (0–100, newest last) and learned words, persisted (ENG-17).
class EnglishProgress {
  const EnglishProgress({this.scores = const {}, this.known = const {}});

  final Map<EngSkill, List<int>> scores;
  final Set<String> known;

  int? average(EngSkill s) {
    final l = scores[s] ?? const [];
    if (l.isEmpty) return null;
    final recent = l.length > 5 ? l.sublist(l.length - 5) : l;
    return (recent.reduce((a, b) => a + b) / recent.length).round();
  }

  /// Weakest skills first (ENG-18); untried skills count as weakest.
  List<EngSkill> get plan => [...EngSkill.values]..sort((a, b) => (average(a) ?? -1).compareTo(average(b) ?? -1));
}

/// The web's `english:<studentId>` document ↔ the app's score lists. Known words are kept in
/// the same document (`knownWords`), which the web leaves alone.
abstract final class EnglishDoc {
  static EnglishProgress fromDoc(Map<String, dynamic> d) {
    final skills = (d['skills'] as Map? ?? const {}).cast<String, dynamic>();
    return EnglishProgress(
      scores: {
        for (final skill in EngSkill.values)
          if (skills[skill.name] case final Map<dynamic, dynamic> s)
            skill: [
              for (final h in s['history'] as List? ?? const []) ((h as Map)['score'] as num).round(),
              // An average without history (seed data) still counts as one score.
              if ((s['history'] as List? ?? const []).isEmpty && ((s['attempts'] as num?) ?? 0) > 0) ((s['score'] as num?) ?? 0).round(),
            ],
      },
      known: {for (final w in d['knownWords'] as List? ?? const []) w as String},
    );
  }

  /// [doc] with one more [score] for [skill] (running average and last 20 scores, like the web).
  static Map<String, dynamic> record(Map<String, dynamic> doc, EngSkill skill, int score, DateTime now) {
    final skills = {...(doc['skills'] as Map? ?? const {}).cast<String, dynamic>()};
    final s = (skills[skill.name] as Map? ?? const {'attempts': 0, 'score': 0, 'history': <Object>[]}).cast<String, dynamic>();
    final attempts = ((s['attempts'] as num?) ?? 0).round() + 1;
    final avg = ((((s['score'] as num?) ?? 0) * (attempts - 1) + score) / attempts).round();
    final date = '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    final history = [...s['history'] as List? ?? const [], {'date': date, 'score': score}];
    skills[skill.name] = {'attempts': attempts, 'score': avg, 'history': history.length > 20 ? history.sublist(history.length - 20) : history};
    return {'id': 'english', 'writing': <Object>[], ...doc, 'skills': skills};
  }
}

class EnglishController extends Notifier<EnglishProgress> {
  static const _col = 'english';
  late LocalStore _store;
  String? _docKey;
  Map<String, dynamic> _doc = {};

  /// The server document has been read, so pushing it back can't drop fields we never saw.
  bool _loaded = false;

  @override
  EnglishProgress build() {
    _store = watchStore(ref);
    final remote = ref.watch(remoteProgressProvider);
    _docKey = remote == null ? null : 'english:${remote.studentId}';
    if (_docKey != null) Future.microtask(refresh);
    final d = _store.get(_col, 'me');
    if (d == null) return const EnglishProgress();
    return EnglishProgress(
      scores: {for (final e in (d['scores'] as Map).entries) EngSkill.values.byName(e.key as String): (e.value as List).cast<int>()},
      known: {...(d['known'] as List).cast<String>()},
    );
  }

  Future<void> _save(EnglishProgress p) async {
    state = p;
    await _store.put(_col, 'me', {
      'scores': {for (final e in p.scores.entries) e.key.name: e.value},
      'known': p.known.toList(),
    });
  }

  /// API mode: the server document replaces the local scores.
  Future<void> refresh() async {
    final key = _docKey;
    if (key == null || !ref.mounted) return;
    try {
      final doc = (await ref.read(apiClientProvider).get('/documents/$key', parse: (d) => d == null ? <String, dynamic>{} : (d as Map).cast<String, dynamic>())).data;
      if (!ref.mounted) return;
      _loaded = true;
      if (doc.isEmpty) return;
      _doc = doc;
      await _save(EnglishDoc.fromDoc(doc));
    } catch (_) {
      // Offline: keep the cached scores.
    }
  }

  /// Applies [change] to the server document (read first if needed) and saves it whole.
  Future<void> _push(Map<String, dynamic> Function(Map<String, dynamic> doc) change) async {
    final key = _docKey;
    if (key == null) return;
    if (!_loaded) await refresh();
    if (!_loaded) return; // offline: kept on the device
    final doc = change(_doc);
    _doc = doc;
    final merged = EnglishDoc.fromDoc(doc);
    await _save(EnglishProgress(scores: merged.scores, known: {...state.known, ...merged.known}));
    try {
      await ref.read(apiClientProvider).put('/documents/$key', body: doc, parse: (d) => d);
    } catch (_) {
      // Saved on the device; the next change sends the whole document again.
    }
  }

  Future<void> record(EngSkill skill, int score) async {
    final clamped = score.clamp(0, 100);
    await _save(EnglishProgress(scores: {...state.scores, skill: [...?state.scores[skill], clamped]}, known: state.known));
    if (_docKey != null) await _push((doc) => EnglishDoc.record(doc, skill, clamped, DateTime.now()));
  }

  Future<void> markKnown(String word) async {
    final known = {...state.known, word};
    await _save(EnglishProgress(scores: state.scores, known: known));
    if (_docKey != null) {
      await _push((doc) => {
        'id': 'english',
        'skills': <String, dynamic>{},
        'writing': <Object>[],
        ...doc,
        'knownWords': {...known, for (final w in doc['knownWords'] as List? ?? const []) w as String}.toList(),
      });
    }
  }
}

final englishProvider = NotifierProvider<EnglishController, EnglishProgress>(EnglishController.new);

const _vocab = [
  ('abundant', 'প্রচুর', 'The region has abundant rainfall.'),
  ('diligent', 'পরিশ্রমী', 'A diligent student revises every day.'),
  ('evaporate', 'বাষ্পীভূত হওয়া', 'Water evaporates in the sun.'),
  ('fragile', 'ভঙ্গুর', 'Handle the glass carefully; it is fragile.'),
  ('generous', 'উদার', 'She is generous with her time.'),
  ('hesitate', 'দ্বিধা করা', "Don't hesitate to ask questions."),
  ('inevitable', 'অনিবার্য', 'Change is inevitable.'),
  ('meticulous', 'অতি যত্নশীল', 'He keeps meticulous notes.'),
  ('perseverance', 'অধ্যবসায়', 'Perseverance leads to success.'),
  ('scarce', 'দুষ্প্রাপ্য', 'Clean water is scarce in some areas.'),
];

/// (stem, options, answer, explanation)
const _grammar = [
  ('She ___ to school every day.', ['go', 'goes', 'going', 'gone'], 1, 'Third person singular in the present simple takes -s/-es.'),
  ('Neither of the boys ___ his homework.', ['have done', 'has done', 'are doing', 'were done'], 1, '"Neither of" takes a singular verb.'),
  ('I ___ him yesterday.', ['see', 'seen', 'saw', 'seeing'], 2, '"Yesterday" needs the past simple: saw.'),
  ('If it rains, we ___ at home.', ['stayed', 'will stay', 'would stayed', 'staying'], 1, 'First conditional: if + present, will + verb.'),
  ('He is good ___ mathematics.', ['in', 'at', 'on', 'for'], 1, 'We say "good at" a subject or skill.'),
];

/// (wrong, correct)
const _corrections = [
  ('He go to school every day.', 'He goes to school every day.'),
  ('They was playing football.', 'They were playing football.'),
  ('I have seen him yesterday.', 'I saw him yesterday.'),
  ('She is more taller than me.', 'She is taller than me.'),
  ('Each of the students have a book.', 'Each of the students has a book.'),
];

const _passage =
    'Bangladesh is a land of rivers. More than seven hundred rivers flow through the country, and they shape the lives of millions of people. '
    'Farmers depend on the rivers for water, and fishermen depend on them for food. However, floods during the monsoon can destroy crops and homes. '
    'Many villages now build raised platforms and plant trees along the banks to reduce the damage.';

/// (question, options, answer)
const _readingQs = [
  ('How many rivers flow through Bangladesh?', ['About seventy', 'More than seven hundred', 'Exactly one hundred', 'Fewer than fifty'], 1),
  ('Who depends on the rivers for food?', ['Teachers', 'Farmers', 'Fishermen', 'Doctors'], 2),
  ('What do villages do to reduce flood damage?', ['Move to cities', 'Build raised platforms', 'Stop farming', 'Dig new rivers'], 1),
];

const _listeningText = 'Good morning, students. Tomorrow our class will visit the National Museum. Please bring water, a notebook and a pen. The bus will leave at eight thirty, so arrive by eight fifteen.';

const _listeningQs = [
  ('Where will the class go?', ['The zoo', 'The National Museum', 'The library', 'A river'], 1),
  ('What time does the bus leave?', ['8:00', '8:15', '8:30', '9:00'], 2),
];

const _writingPrompts = {
  'sentence': ('My daily routine', 10),
  'paragraph': ('The importance of trees', 80),
  'essay': ('Digital Bangladesh', 200),
  'composition': ('A memorable journey', 150),
  'email': ('Write to a friend about your exam preparation', 80),
};

const _examPrompts = ['Tell me about your favourite hobby.', 'Describe your school.', 'What would you like to do in the future, and why?'];

const _pronSentences = ['The weather is pleasant today.', 'I usually study in the evening.', 'Rivers are very important for our country.'];

/// Simulated pronunciation score: share of target words recognised (ENG-11).
(int, List<String>) pronunciationScore(String target, String heard) {
  String norm(String s) => s.toLowerCase().replaceAll(RegExp(r'[^a-z\s]'), '');
  final t = norm(target).split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
  final h = norm(heard).split(RegExp(r'\s+')).toSet();
  final missed = [for (final w in t) if (!h.contains(w)) w];
  return (t.isEmpty ? 0 : (100 * (t.length - missed.length) / t.length).round(), missed);
}

class EnglishCoachScreen extends ConsumerWidget {
  const EnglishCoachScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tabs = [EngStrings.progress, EngStrings.writing, EngStrings.vocab, EngStrings.grammar, EngStrings.correction, EngStrings.reading, EngStrings.listening, EngStrings.speaking, EngStrings.exam];
    return DefaultTabController(
      length: tabs.length,
      initialIndex: 1,
      child: AppPageScaffold(
        title: context.tr(EngStrings.title),
        scrollable: false,
        bottom: TabBar(isScrollable: true, tabAlignment: TabAlignment.start, tabs: [for (final t in tabs) Tab(text: context.tr(t))]),
        body: const TabBarView(children: [_ProgressTab(), _WritingTab(), _VocabTab(), _GrammarTab(), _CorrectionTab(), _ReadingTab(), _ListeningTab(), _SpeakingTab(), _ExamTab()]),
      ),
    );
  }
}

Future<String?> _coach(WidgetRef ref, BuildContext context, String text) async {
  if (text.trim().isEmpty) return null;
  try {
    final r = await ref.read(mockSimulatorProvider).run(
      () => ref.read(mockTutorEngineProvider).answer(query: text, context: TutorContext(mode: TeachingMode.englishCoach, language: context.isBangla ? TutorLanguage.bn : TutorLanguage.en)),
    );
    return r.text;
  } on ApiException catch (e) {
    if (context.mounted) context.showErrorSnack(e);
    return null;
  }
}

class _ProgressTab extends ConsumerWidget {
  const _ProgressTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = ref.watch(englishProvider);
    final any = EngSkill.values.any((s) => p.average(s) != null);
    return ListView(
      children: [
        SectionHeader(title: context.tr(EngStrings.progress)),
        if (!any) Text(context.tr(EngStrings.noScores), style: Theme.of(context).textTheme.bodySmall),
        for (final s in EngSkill.values)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: LabeledProgress(label: context.tr(s.label), value: (p.average(s) ?? 0) / 100, trailing: p.average(s) == null ? '—' : context.pct(p.average(s)!)),
          ),
        Text(context.tr(EngStrings.knownCount.fill({'n': p.known.length, 't': _vocab.length})), style: Theme.of(context).textTheme.bodySmall),
        SectionHeader(title: context.tr(EngStrings.plan)),
        for (final s in p.plan.take(3))
          ListTile(contentPadding: EdgeInsets.zero, leading: const Icon(Icons.trending_up), title: Text(context.tr(EngStrings.planLine.fill({'s': context.tr(s.label), 'n': p.average(s) ?? 0})))),
        const SizedBox(height: AppSpacing.sm),
        InfoBanner(message: context.tr(EngStrings.simulatedScore)),
      ],
    );
  }
}

class _WritingTab extends ConsumerStatefulWidget {
  const _WritingTab();

  @override
  ConsumerState<_WritingTab> createState() => _WritingTabState();
}

class _WritingTabState extends ConsumerState<_WritingTab> {
  final _c = TextEditingController();
  String _type = 'sentence';
  String? _feedback;
  bool _busy = false;

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  int get _words => _c.text.trim().isEmpty ? 0 : _c.text.trim().split(RegExp(r'\s+')).length;

  @override
  Widget build(BuildContext context) {
    final (topic, target) = _writingPrompts[_type]!;
    final paras = _c.text.trim().split(RegExp(r'\n\s*\n')).where((x) => x.trim().isNotEmpty).length;
    final emailOk = RegExp(r'^(dear|hi|hello)', caseSensitive: false).hasMatch(_c.text.trim()) && RegExp(r'(regards|yours|best wishes|sincerely)', caseSensitive: false).hasMatch(_c.text);
    return ListView(
      children: [
        Text(context.tr(EngStrings.writingType), style: Theme.of(context).textTheme.labelLarge),
        Wrap(
          spacing: AppSpacing.xs,
          children: [
            for (final (k, l) in [('sentence', EngStrings.sentence), ('paragraph', EngStrings.paragraph), ('essay', EngStrings.essay), ('composition', EngStrings.composition), ('email', EngStrings.email)])
              ChoiceChip(key: Key('eng.type.$k'), label: Text(context.tr(l)), selected: _type == k, onSelected: (_) => setState(() => _type = k)),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(context.tr(EngStrings.prompt.fill({'p': topic})), style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: AppSpacing.sm),
        TextField(key: const Key('eng.write'), controller: _c, minLines: 3, maxLines: 12, onChanged: (_) => setState(() {}), decoration: InputDecoration(hintText: context.tr(EngStrings.writeHint))),
        Text(context.tr(EngStrings.words.fill({'n': _words, 't': target})), style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: AppSpacing.sm),
        FilledButton(
          key: const Key('eng.check'),
          onPressed: _busy
              ? null
              : () async {
                  setState(() => _busy = true);
                  final f = await _coach(ref, context, _c.text);
                  if (!mounted) return;
                  setState(() {
                    _feedback = f;
                    _busy = false;
                  });
                  if (f != null) {
                    final lengthScore = (_words / target).clamp(0.0, 1.0);
                    await ref.read(englishProvider.notifier).record(EngSkill.writing, (50 + 50 * lengthScore).round());
                  }
                },
          child: Text(context.tr(EngStrings.check)),
        ),
        if (_feedback != null) ...[
          if (_type != 'sentence')
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(paras >= 3 || _type == 'paragraph' ? Icons.check_circle_outline : Icons.info_outline),
              title: Text(context.tr(EngStrings.structure)),
              subtitle: Text(context.tr(paras >= 3 || _type == 'paragraph' ? EngStrings.structureOk : EngStrings.structureMissing)),
            ),
          if (_type == 'email')
            ListTile(contentPadding: EdgeInsets.zero, leading: Icon(emailOk ? Icons.check_circle_outline : Icons.info_outline), title: Text(context.tr(EngStrings.emailParts))),
          Card(child: Padding(padding: const EdgeInsets.all(AppSpacing.md), child: RichContent(_feedback!))),
        ],
      ],
    );
  }
}

class _VocabTab extends ConsumerStatefulWidget {
  const _VocabTab();

  @override
  ConsumerState<_VocabTab> createState() => _VocabTabState();
}

class _VocabTabState extends ConsumerState<_VocabTab> {
  int _card = 0;
  bool _showMeaning = false;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final voice = ref.read(avatarVoiceProvider);
    final known = ref.watch(englishProvider).known;
    final (word, meaning, example) = _vocab[_card % _vocab.length];
    return ListView(
      children: [
        Text(context.tr(EngStrings.knownCount.fill({'n': known.length, 't': _vocab.length})), style: text.labelLarge),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              children: [
                Row(mainAxisAlignment: MainAxisAlignment.center, children: [Text(word, style: text.headlineMedium), if (known.contains(word)) const Icon(Icons.check_circle, color: Colors.green)]),
                IconButton(onPressed: () => voice.speak(word, lang: 'en'), icon: const Icon(Icons.volume_up_outlined)),
                if (_showMeaning) ...[
                  Text('${context.tr(EngStrings.meaning)}: $meaning', style: text.titleMedium),
                  const SizedBox(height: AppSpacing.xs),
                  Text('${context.tr(EngStrings.example)}: $example', textAlign: TextAlign.center),
                ] else
                  TextButton(onPressed: () => setState(() => _showMeaning = true), child: Text(context.tr(EngStrings.meaning))),
              ],
            ),
          ),
        ),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                key: const Key('eng.known'),
                onPressed: () async {
                  await ref.read(englishProvider.notifier).markKnown(word);
                  await ref.read(englishProvider.notifier).record(EngSkill.vocabulary, (100 * (known.length + 1) / _vocab.length).round());
                  setState(() {
                    _card++;
                    _showMeaning = false;
                  });
                },
                child: Text(context.tr(EngStrings.known)),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: FilledButton(
                onPressed: () => setState(() {
                  _card++;
                  _showMeaning = false;
                }),
                child: Text(context.tr(EngStrings.next)),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        OutlinedButton.icon(
          key: const Key('eng.toCards'),
          onPressed: () async {
            await ref.read(flashcardsProvider.notifier).createDeck('English vocabulary', cards: [for (final (w, m, e) in _vocab) (w, '$m — $e')]);
            if (context.mounted) context.showSnack(EngStrings.addedFlashcards);
          },
          icon: const Icon(Icons.style_outlined),
          label: Text(context.tr(EngStrings.toFlashcards)),
        ),
      ],
    );
  }
}

/// Multiple-choice quiz used by grammar, reading and listening.
class _Mcq extends ConsumerStatefulWidget {
  const _Mcq({required this.questions, required this.skill, this.explanations, this.keyPrefix = 'eng'});

  final List<(String, List<String>, int)> questions;
  final List<String>? explanations;
  final EngSkill skill;
  final String keyPrefix;

  @override
  ConsumerState<_Mcq> createState() => _McqState();
}

class _McqState extends ConsumerState<_Mcq> {
  int _q = 0;
  int _score = 0;
  int? _picked;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final total = widget.questions.length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(context.tr(EngStrings.score.fill({'s': _score, 't': total})), style: text.labelLarge),
        const SizedBox(height: AppSpacing.sm),
        if (_q < total) ...[
          Text(widget.questions[_q].$1, style: text.titleMedium),
          const SizedBox(height: AppSpacing.sm),
          for (final (i, o) in widget.questions[_q].$2.indexed)
            Card(
              color: _picked == null ? null : (i == widget.questions[_q].$3 ? Colors.green.withValues(alpha: 0.15) : (i == _picked ? Colors.red.withValues(alpha: 0.15) : null)),
              child: ListTile(
                key: Key('${widget.keyPrefix}.opt.$i'),
                title: Text(o),
                onTap: _picked != null
                    ? null
                    : () => setState(() {
                        _picked = i;
                        if (i == widget.questions[_q].$3) _score++;
                      }),
              ),
            ),
          if (_picked != null && widget.explanations != null) Text(context.tr(EngStrings.why.fill({'w': widget.explanations![_q]})), style: text.bodySmall),
          if (_picked != null)
            FilledButton(
              onPressed: () async {
                final last = _q == total - 1;
                setState(() {
                  _q++;
                  _picked = null;
                });
                if (last) await ref.read(englishProvider.notifier).record(widget.skill, (100 * _score / total).round());
              },
              child: Text(context.tr(EngStrings.next)),
            ),
        ] else
          FilledButton(
            onPressed: () => setState(() {
              _q = 0;
              _score = 0;
            }),
            child: Text(context.tr(EngStrings.restart)),
          ),
      ],
    );
  }
}

class _GrammarTab extends StatelessWidget {
  const _GrammarTab();

  @override
  Widget build(BuildContext context) => ListView(
    children: [
      _Mcq(questions: [for (final (s, o, a, _) in _grammar) (s, o, a)], explanations: [for (final g in _grammar) g.$4], skill: EngSkill.grammar),
    ],
  );
}

class _CorrectionTab extends ConsumerStatefulWidget {
  const _CorrectionTab();

  @override
  ConsumerState<_CorrectionTab> createState() => _CorrectionTabState();
}

class _CorrectionTabState extends ConsumerState<_CorrectionTab> {
  final _c = TextEditingController();
  int _i = 0;
  bool? _ok;

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  String _norm(String s) => s.trim().toLowerCase().replaceAll(RegExp(r'[^a-z ]'), '').replaceAll(RegExp(r'\s+'), ' ');

  @override
  Widget build(BuildContext context) {
    final (wrong, right) = _corrections[_i % _corrections.length];
    return ListView(
      children: [
        Text(context.tr(EngStrings.correctThis), style: Theme.of(context).textTheme.labelLarge),
        Card(child: Padding(padding: const EdgeInsets.all(AppSpacing.md), child: Text(wrong, style: Theme.of(context).textTheme.titleMedium))),
        TextField(key: const Key('eng.fix'), controller: _c),
        const SizedBox(height: AppSpacing.sm),
        FilledButton(
          key: const Key('eng.fixCheck'),
          onPressed: () async {
            final ok = _norm(_c.text) == _norm(right);
            setState(() => _ok = ok);
            await ref.read(englishProvider.notifier).record(EngSkill.grammar, ok ? 100 : 30);
          },
          child: Text(context.tr(EngStrings.check)),
        ),
        if (_ok != null)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.sm),
            child: Text(context.tr(_ok! ? EngStrings.correct : EngStrings.notQuite.fill({'a': right})), style: TextStyle(color: _ok! ? Colors.green : Colors.orange)),
          ),
        TextButton(
          onPressed: () => setState(() {
            _i++;
            _ok = null;
            _c.clear();
          }),
          child: Text(context.tr(EngStrings.next)),
        ),
      ],
    );
  }
}

class _ReadingTab extends StatelessWidget {
  const _ReadingTab();

  @override
  Widget build(BuildContext context) => ListView(
    children: [
      Text(context.tr(EngStrings.passage), style: Theme.of(context).textTheme.labelLarge),
      const Card(child: Padding(padding: EdgeInsets.all(AppSpacing.md), child: Text(_passage))),
      const SizedBox(height: AppSpacing.sm),
      const _Mcq(questions: _readingQs, skill: EngSkill.reading, keyPrefix: 'read'),
    ],
  );
}

class _ListeningTab extends ConsumerStatefulWidget {
  const _ListeningTab();

  @override
  ConsumerState<_ListeningTab> createState() => _ListeningTabState();
}

class _ListeningTabState extends ConsumerState<_ListeningTab> {
  bool _transcript = false;

  @override
  Widget build(BuildContext context) {
    final voice = ref.read(avatarVoiceProvider);
    return ListView(
      children: [
        FilledButton.icon(key: const Key('listen.play'), onPressed: () => voice.speak(_listeningText, lang: 'en', rate: 0.9), icon: const Icon(Icons.play_arrow), label: Text(context.tr(EngStrings.play))),
        SwitchListTile(contentPadding: EdgeInsets.zero, title: Text(context.tr(EngStrings.showTranscript)), value: _transcript, onChanged: (v) => setState(() => _transcript = v)),
        if (_transcript) const Card(child: Padding(padding: EdgeInsets.all(AppSpacing.md), child: Text(_listeningText))),
        const SizedBox(height: AppSpacing.sm),
        const _Mcq(questions: _listeningQs, skill: EngSkill.listening, keyPrefix: 'listen'),
      ],
    );
  }
}

class _SpeakingTab extends ConsumerStatefulWidget {
  const _SpeakingTab();

  @override
  ConsumerState<_SpeakingTab> createState() => _SpeakingTabState();
}

class _SpeakingTabState extends ConsumerState<_SpeakingTab> {
  final _speak = TextEditingController();
  final _pron = TextEditingController();
  String? _feedback;
  int _target = 0;
  (int, List<String>)? _pronResult;

  @override
  void dispose() {
    _speak.dispose();
    _pron.dispose();
    super.dispose();
  }

  Future<void> _mic(TextEditingController c) async {
    final ok = await ref.read(avatarVoiceProvider).listen(
      lang: 'en',
      onResult: (w, fin) {
        c.text = w;
        if (fin && mounted) setState(() {});
      },
    );
    if (!ok && mounted) context.showSnack(EngStrings.micOff);
  }

  @override
  Widget build(BuildContext context) {
    final voice = ref.read(avatarVoiceProvider);
    final target = _pronSentences[_target % _pronSentences.length];
    return ListView(
      children: [
        Text(context.tr(EngStrings.speakHint)),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            Expanded(child: TextField(controller: _speak, decoration: const InputDecoration(hintText: 'He go to school every day.'))),
            IconButton.filled(icon: const Icon(Icons.mic), onPressed: () => _mic(_speak)),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            FilledButton(
              onPressed: () async {
                final f = await _coach(ref, context, _speak.text);
                if (!mounted) return;
                setState(() => _feedback = f);
                if (f != null) await ref.read(englishProvider.notifier).record(EngSkill.speaking, 70);
              },
              child: Text(context.tr(EngStrings.check)),
            ),
            const SizedBox(width: AppSpacing.sm),
            OutlinedButton.icon(onPressed: () => voice.speak(_speak.text, lang: 'en'), icon: const Icon(Icons.volume_up_outlined), label: Text(context.tr(EngStrings.listen))),
          ],
        ),
        if (_feedback != null) Card(child: Padding(padding: const EdgeInsets.all(AppSpacing.md), child: RichContent(_feedback!))),
        SectionHeader(title: context.tr(EngStrings.pronunciation)),
        Text(context.tr(EngStrings.sayThis)),
        Row(
          children: [
            Expanded(child: Text(target, style: Theme.of(context).textTheme.titleMedium)),
            IconButton(onPressed: () => voice.speak(target, lang: 'en'), icon: const Icon(Icons.volume_up_outlined)),
          ],
        ),
        Row(
          children: [
            Expanded(child: TextField(key: const Key('pron.heard'), controller: _pron)),
            IconButton.filled(icon: const Icon(Icons.mic), onPressed: () => _mic(_pron)),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            FilledButton(
              key: const Key('pron.check'),
              onPressed: () async {
                final r = pronunciationScore(target, _pron.text);
                setState(() => _pronResult = r);
                await ref.read(englishProvider.notifier).record(EngSkill.speaking, r.$1);
              },
              child: Text(context.tr(EngStrings.check)),
            ),
            TextButton(
              onPressed: () => setState(() {
                _target++;
                _pron.clear();
                _pronResult = null;
              }),
              child: Text(context.tr(EngStrings.next)),
            ),
          ],
        ),
        if (_pronResult case (final s, final missed)) Text(context.tr(EngStrings.pronScore.fill({'n': s, 'w': missed.isEmpty ? '—' : missed.join(', ')})), key: const Key('pron.result')),
      ],
    );
  }
}

class _ExamTab extends ConsumerStatefulWidget {
  const _ExamTab();

  @override
  ConsumerState<_ExamTab> createState() => _ExamTabState();
}

class _ExamTabState extends ConsumerState<_ExamTab> {
  final _answer = TextEditingController();
  final List<String> _answers = [];
  bool _started = false;

  @override
  void dispose() {
    _answer.dispose();
    super.dispose();
  }

  (int, int, int) get _scores {
    final all = _answers.join(' ');
    final words = all.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
    final unique = words.map((w) => w.toLowerCase()).toSet().length;
    final fluency = (words.length / (_examPrompts.length * 25) * 100).clamp(20, 100).round();
    final range = words.isEmpty ? 0 : (unique / words.length * 130).clamp(20, 100).round();
    final accuracy = (100 - RegExp(r'\b(he|she|it) (go|have|do)\b', caseSensitive: false).allMatches(all).length * 15).clamp(30, 100);
    return (fluency, range, accuracy);
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final done = _answers.length >= _examPrompts.length;
    if (!_started) {
      return ListView(
        children: [
          Text(context.tr(EngStrings.examIntro)),
          const SizedBox(height: AppSpacing.md),
          FilledButton(key: const Key('exam.start'), onPressed: () => setState(() => _started = true), child: Text(context.tr(EngStrings.startExam))),
        ],
      );
    }
    if (done) {
      final (f, r, a) = _scores;
      final band = ((f + r + a) / 3 / 100 * 9).clamp(1, 9).toStringAsFixed(1);
      return ListView(
        children: [
          Text(context.tr(EngStrings.examDone.fill({'b': band})), key: const Key('exam.done'), style: text.titleMedium),
          const SizedBox(height: AppSpacing.sm),
          LabeledProgress(label: context.tr(EngStrings.fluency), value: f / 100, trailing: context.pct(f)),
          LabeledProgress(label: context.tr(EngStrings.vocabRange), value: r / 100, trailing: context.pct(r)),
          LabeledProgress(label: context.tr(EngStrings.accuracy), value: a / 100, trailing: context.pct(a)),
          const SizedBox(height: AppSpacing.sm),
          InfoBanner(message: context.tr(EngStrings.simulatedScore)),
          FilledButton(
            onPressed: () => setState(() {
              _answers.clear();
              _started = false;
            }),
            child: Text(context.tr(EngStrings.restart)),
          ),
        ],
      );
    }
    final i = _answers.length;
    return ListView(
      children: [
        Text(context.tr(EngStrings.examQ.fill({'n': i + 1, 't': _examPrompts.length})), style: text.labelLarge),
        const SizedBox(height: AppSpacing.xs),
        Text(_examPrompts[i], style: text.titleMedium),
        IconButton(onPressed: () => ref.read(avatarVoiceProvider).speak(_examPrompts[i], lang: 'en'), icon: const Icon(Icons.volume_up_outlined)),
        TextField(key: const Key('exam.answer'), controller: _answer, minLines: 3, maxLines: 6),
        const SizedBox(height: AppSpacing.sm),
        FilledButton(
          key: const Key('exam.submit'),
          onPressed: () async {
            setState(() {
              _answers.add(_answer.text);
              _answer.clear();
            });
            if (_answers.length == _examPrompts.length) {
              final (f, r, a) = _scores;
              await ref.read(englishProvider.notifier).record(EngSkill.speaking, ((f + r + a) / 3).round());
            }
          },
          child: Text(context.tr(EngStrings.submit)),
        ),
      ],
    );
  }
}
