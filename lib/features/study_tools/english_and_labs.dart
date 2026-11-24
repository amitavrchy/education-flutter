import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/l10n/tr.dart';
import '../../core/mock/mock_simulator.dart';
import '../../core/network/api_exception.dart';
import '../../core/theme/app_spacing.dart';
import '../../shared/widgets/app_page_scaffold.dart';
import '../../shared/widgets/badges.dart';
import '../../shared/widgets/feedback.dart';
import '../../shared/widgets/rich_content.dart';
import '../../shared/widgets/section_header.dart';
import '../ai_tutor/data/ai_tutor_repository.dart';
import '../ai_tutor/domain/tutor_models.dart';
import '../book_avatar/application/avatar_voice.dart';

abstract final class EngStrings {
  static const title = Tr('ইংরেজি কোচ', 'English coach');
  static const writing = Tr('লেখা যাচাই', 'Writing check');
  static const vocab = Tr('শব্দভাণ্ডার', 'Vocabulary');
  static const grammar = Tr('গ্রামার কুইজ', 'Grammar quiz');
  static const speaking = Tr('বলা অনুশীলন', 'Speaking');
  static const writeHint = Tr('একটি বাক্য বা অনুচ্ছেদ লেখো…', 'Write a sentence or paragraph…');
  static const check = Tr('যাচাই করো', 'Check');
  static const meaning = Tr('অর্থ', 'Meaning');
  static const example = Tr('উদাহরণ', 'Example');
  static const known = Tr('জানি', 'Known');
  static const next = Tr('পরেরটা', 'Next');
  static const score = Tr('স্কোর: {s}/{t}', 'Score: {s}/{t}');
  static const restart = Tr('আবার শুরু', 'Restart');
  static const speakHint = Tr('মাইক চেপে একটি ইংরেজি বাক্য বলো — বা লিখে দাও। কোচ সংশোধন করবে ও উচ্চারণ শুনিয়ে দেবে।', 'Tap the mic and say an English sentence — or type it. The coach corrects it and reads it back.');
  static const listen = Tr('শোনো', 'Listen');
  static const micOff = Tr('এই ডিভাইসে কণ্ঠ শনাক্তকরণ নেই — লিখে দাও।', 'Speech recognition is unavailable here — type instead.');
  static const labs = Tr('বিজ্ঞান ও গণিত ল্যাব', 'Science & maths labs');
  static const motion = Tr('গতি: v = u + at', 'Motion: v = u + at');
  static const ohm = Tr('সরল বর্তনী: ওহমের সূত্র', "Simple circuit: Ohm's law");
  static const periodic = Tr('পর্যায় সারণি (১–২০)', 'Periodic table (1–20)');
  static const graph = Tr('গ্রাফ: y = ax² + bx + c', 'Graph: y = ax² + bx + c');
  static const simulated = Tr('শিক্ষামূলক সিমুলেশন — সরলীকৃত মডেল।', 'Educational simulation — simplified model.');
}

const _vocab = [
  ('abundant', 'প্রচুর', 'The region has abundant rainfall.'),
  ('diligent', 'পরিশ্রমী', 'A diligent student revises every day.'),
  ('evaporate', 'বাষ্পীভূত হওয়া', 'Water evaporates in the sun.'),
  ('fragile', 'ভঙ্গুর', 'Handle the glass carefully; it is fragile.'),
  ('generous', 'উদার', 'She is generous with her time.'),
  ('hesitate', 'দ্বিধা করা', "Don't hesitate to ask questions."),
  ('inevitable', 'অনিবার্য', 'Change is inevitable.'),
  ('meticulous', 'অতি যত্নশীল', 'He keeps meticulous notes.'),
];

const _grammar = [
  ('She ___ to school every day.', ['go', 'goes', 'going', 'gone'], 1),
  ('Neither of the boys ___ his homework.', ['have done', 'has done', 'are doing', 'were done'], 1),
  ('I ___ him yesterday.', ['see', 'seen', 'saw', 'seeing'], 2),
  ('If it rains, we ___ at home.', ['stayed', 'will stay', 'would stayed', 'staying'], 1),
  ('He is good ___ mathematics.', ['in', 'at', 'on', 'for'], 1),
];

class EnglishCoachScreen extends ConsumerStatefulWidget {
  const EnglishCoachScreen({super.key});

  @override
  ConsumerState<EnglishCoachScreen> createState() => _EnglishCoachScreenState();
}

class _EnglishCoachScreenState extends ConsumerState<EnglishCoachScreen> {
  final _write = TextEditingController();
  final _speak = TextEditingController();
  String? _feedback;
  String? _speakFeedback;
  int _card = 0;
  bool _showMeaning = false;
  int _q = 0;
  int _score = 0;
  int? _picked;
  bool _busy = false;

  @override
  void dispose() {
    _write.dispose();
    _speak.dispose();
    super.dispose();
  }

  Future<String?> _coach(String text) async {
    if (text.trim().isEmpty) return null;
    try {
      final r = await ref.read(mockSimulatorProvider).run(
        () => ref.read(mockTutorEngineProvider).answer(query: text, context: TutorContext(mode: TeachingMode.englishCoach, language: context.isBangla ? TutorLanguage.bn : TutorLanguage.en)),
      );
      return r.text;
    } on ApiException catch (e) {
      if (mounted) context.showErrorSnack(e);
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final voice = ref.read(avatarVoiceProvider);
    final (word, meaning, example) = _vocab[_card % _vocab.length];
    final (stem, options, answer) = _grammar[_q % _grammar.length];
    return DefaultTabController(
      length: 4,
      child: AppPageScaffold(
        title: context.tr(EngStrings.title),
        scrollable: false,
        bottom: TabBar(
          isScrollable: true,
          tabs: [Tab(text: context.tr(EngStrings.writing)), Tab(text: context.tr(EngStrings.vocab)), Tab(text: context.tr(EngStrings.grammar)), Tab(text: context.tr(EngStrings.speaking))],
        ),
        body: TabBarView(
          children: [
            ListView(
              children: [
                TextField(key: const Key('eng.write'), controller: _write, minLines: 3, maxLines: 8, decoration: InputDecoration(hintText: context.tr(EngStrings.writeHint))),
                const SizedBox(height: AppSpacing.sm),
                FilledButton(
                  key: const Key('eng.check'),
                  onPressed: _busy
                      ? null
                      : () async {
                          setState(() => _busy = true);
                          final f = await _coach(_write.text);
                          if (mounted) {
                            setState(() {
                              _feedback = f;
                              _busy = false;
                            });
                          }
                        },
                  child: Text(context.tr(EngStrings.check)),
                ),
                if (_feedback != null) Card(child: Padding(padding: const EdgeInsets.all(AppSpacing.md), child: RichContent(_feedback!))),
              ],
            ),
            ListView(
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Column(
                      children: [
                        Text(word, style: text.headlineMedium),
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
                FilledButton(
                  onPressed: () => setState(() {
                    _card++;
                    _showMeaning = false;
                  }),
                  child: Text(context.tr(EngStrings.next)),
                ),
              ],
            ),
            ListView(
              children: [
                Text(context.tr(EngStrings.score.fill({'s': _score, 't': _grammar.length})), style: text.labelLarge),
                const SizedBox(height: AppSpacing.sm),
                if (_q < _grammar.length) ...[
                  Text(stem, style: text.titleMedium),
                  const SizedBox(height: AppSpacing.sm),
                  for (final (i, o) in options.indexed)
                    Card(
                      color: _picked == null ? null : (i == answer ? Colors.green.withValues(alpha: 0.15) : (i == _picked ? Colors.red.withValues(alpha: 0.15) : null)),
                      child: ListTile(
                        key: Key('eng.opt.$i'),
                        title: Text(o),
                        onTap: _picked != null
                            ? null
                            : () => setState(() {
                                _picked = i;
                                if (i == answer) _score++;
                              }),
                      ),
                    ),
                  if (_picked != null)
                    FilledButton(
                      onPressed: () => setState(() {
                        _q++;
                        _picked = null;
                      }),
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
            ),
            ListView(
              children: [
                Text(context.tr(EngStrings.speakHint)),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    Expanded(child: TextField(controller: _speak, decoration: const InputDecoration(hintText: 'He go to school every day.'))),
                    IconButton.filled(
                      icon: const Icon(Icons.mic),
                      onPressed: () async {
                        final ok = await voice.listen(
                          lang: 'en',
                          onResult: (w, fin) {
                            _speak.text = w;
                            if (fin) setState(() {});
                          },
                        );
                        if (!ok && context.mounted) context.showSnack(EngStrings.micOff);
                      },
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    FilledButton(
                      onPressed: () async {
                        final f = await _coach(_speak.text);
                        if (mounted) setState(() => _speakFeedback = f);
                      },
                      child: Text(context.tr(EngStrings.check)),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    OutlinedButton.icon(onPressed: () => voice.speak(_speak.text, lang: 'en'), icon: const Icon(Icons.volume_up_outlined), label: Text(context.tr(EngStrings.listen))),
                  ],
                ),
                if (_speakFeedback != null) Card(child: Padding(padding: const EdgeInsets.all(AppSpacing.md), child: RichContent(_speakFeedback!))),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// Labs
// ═════════════════════════════════════════════════════════════════════════════

const _elements = [
  ('H', 'Hydrogen', 'হাইড্রোজেন', 1.008), ('He', 'Helium', 'হিলিয়াম', 4.003), ('Li', 'Lithium', 'লিথিয়াম', 6.94), ('Be', 'Beryllium', 'বেরিলিয়াম', 9.012),
  ('B', 'Boron', 'বোরন', 10.81), ('C', 'Carbon', 'কার্বন', 12.011), ('N', 'Nitrogen', 'নাইট্রোজেন', 14.007), ('O', 'Oxygen', 'অক্সিজেন', 15.999),
  ('F', 'Fluorine', 'ফ্লোরিন', 18.998), ('Ne', 'Neon', 'নিয়ন', 20.180), ('Na', 'Sodium', 'সোডিয়াম', 22.990), ('Mg', 'Magnesium', 'ম্যাগনেসিয়াম', 24.305),
  ('Al', 'Aluminium', 'অ্যালুমিনিয়াম', 26.982), ('Si', 'Silicon', 'সিলিকন', 28.085), ('P', 'Phosphorus', 'ফসফরাস', 30.974), ('S', 'Sulfur', 'সালফার', 32.06),
  ('Cl', 'Chlorine', 'ক্লোরিন', 35.45), ('Ar', 'Argon', 'আর্গন', 39.948), ('K', 'Potassium', 'পটাশিয়াম', 39.098), ('Ca', 'Calcium', 'ক্যালসিয়াম', 40.078),
];

int _period(int z) => z <= 2 ? 1 : (z <= 10 ? 2 : (z <= 18 ? 3 : 4));

String _shell(int z) {
  final shells = <int>[];
  var left = z;
  for (final cap in const [2, 8, 8, 2]) {
    if (left <= 0) break;
    shells.add(math.min(cap, left));
    left -= cap;
  }
  return shells.join(', ');
}

class LabsScreen extends StatefulWidget {
  const LabsScreen({super.key});

  @override
  State<LabsScreen> createState() => _LabsScreenState();
}

class _LabsScreenState extends State<LabsScreen> {
  double _u = 2, _a = 1.5, _t = 4;
  double _v = 12, _r = 6;
  double _qa = 1, _qb = 0, _qc = -4;
  int? _el;

  Widget _slider(String label, double value, double min, double max, ValueChanged<double> on) => Row(
    children: [
      SizedBox(width: 96, child: Text('$label = ${value.toStringAsFixed(1)}')),
      Expanded(child: Slider(value: value, min: min, max: max, divisions: ((max - min) * 2).round(), onChanged: on)),
    ],
  );

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final v = _u + _a * _t;
    final s = _u * _t + 0.5 * _a * _t * _t;
    final current = _v / _r;
    return AppPageScaffold(
      title: context.tr(EngStrings.labs),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InfoBanner(message: context.tr(EngStrings.simulated)),
          SectionHeader(title: context.tr(EngStrings.motion)),
          _slider('u (m/s)', _u, 0, 10, (x) => setState(() => _u = x)),
          _slider('a (m/s²)', _a, -2, 5, (x) => setState(() => _a = x)),
          _slider('t (s)', _t, 0, 10, (x) => setState(() => _t = x)),
          Text('v = ${v.toStringAsFixed(1)} m/s · s = ${s.toStringAsFixed(1)} m', key: const Key('lab.motion'), style: text.titleMedium),
          SizedBox(
            height: 120,
            child: LineChart(
              LineChartData(
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
                titlesData: const FlTitlesData(topTitles: AxisTitles(), rightTitles: AxisTitles()),
                lineBarsData: [LineChartBarData(spots: [for (var i = 0; i <= 10; i++) FlSpot(i * _t / 10, _u + _a * i * _t / 10)], color: Theme.of(context).colorScheme.primary, dotData: const FlDotData(show: false))],
              ),
            ),
          ),
          SectionHeader(title: context.tr(EngStrings.ohm)),
          _slider('V (V)', _v, 1, 24, (x) => setState(() => _v = x)),
          _slider('R (Ω)', _r, 1, 20, (x) => setState(() => _r = x)),
          Row(
            children: [
              Icon(Icons.lightbulb, size: 40, color: Colors.amber.withValues(alpha: (current / 6).clamp(0.15, 1.0))),
              const SizedBox(width: AppSpacing.sm),
              Text('I = V / R = ${current.toStringAsFixed(2)} A · P = ${(_v * current).toStringAsFixed(1)} W', key: const Key('lab.ohm'), style: text.titleMedium),
            ],
          ),
          SectionHeader(title: context.tr(EngStrings.periodic)),
          GridView.count(
            crossAxisCount: 5,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 4,
            crossAxisSpacing: 4,
            children: [
              for (final (i, e) in _elements.indexed)
                InkWell(
                  key: Key('lab.el.${e.$1}'),
                  onTap: () => setState(() => _el = i),
                  child: Container(
                    decoration: BoxDecoration(
                      color: _el == i ? Theme.of(context).colorScheme.primaryContainer : Theme.of(context).colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    alignment: Alignment.center,
                    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Text('${i + 1}', style: text.labelSmall), Text(e.$1, style: text.titleMedium)]),
                  ),
                ),
            ],
          ),
          if (_el case final i?)
            Card(
              child: ListTile(
                title: Text('${_elements[i].$1} — ${context.isBangla ? _elements[i].$3 : _elements[i].$2}'),
                subtitle: Text('Z = ${i + 1} · ${context.isBangla ? 'পারমাণবিক ভর' : 'Atomic mass'} ${_elements[i].$4} · ${context.isBangla ? 'পর্যায়' : 'Period'} ${_period(i + 1)} · ${context.isBangla ? 'ইলেকট্রন বিন্যাস' : 'Shells'} ${_shell(i + 1)}'),
              ),
            ),
          SectionHeader(title: context.tr(EngStrings.graph)),
          _slider('a', _qa, -3, 3, (x) => setState(() => _qa = x)),
          _slider('b', _qb, -5, 5, (x) => setState(() => _qb = x)),
          _slider('c', _qc, -5, 5, (x) => setState(() => _qc = x)),
          Builder(
            builder: (context) {
              final d = _qb * _qb - 4 * _qa * _qc;
              final roots = _qa == 0
                  ? (_qb == 0 ? '—' : (-_qc / _qb).toStringAsFixed(2))
                  : d < 0
                  ? (context.isBangla ? 'বাস্তব মূল নেই' : 'no real roots')
                  : [(-_qb + math.sqrt(d)) / (2 * _qa), (-_qb - math.sqrt(d)) / (2 * _qa)].map((r) => r.toStringAsFixed(2)).toSet().join(', ');
              return Text('D = ${d.toStringAsFixed(2)} · x = $roots', key: const Key('lab.roots'), style: text.titleMedium);
            },
          ),
          SizedBox(
            height: 160,
            child: LineChart(
              LineChartData(
                minY: -10,
                maxY: 10,
                gridData: const FlGridData(drawVerticalLine: false),
                borderData: FlBorderData(show: false),
                titlesData: const FlTitlesData(topTitles: AxisTitles(), rightTitles: AxisTitles()),
                lineBarsData: [
                  LineChartBarData(
                    spots: [for (var x = -5.0; x <= 5.0; x += 0.25) FlSpot(x, (_qa * x * x + _qb * x + _qc).clamp(-10, 10))],
                    isCurved: true,
                    color: Theme.of(context).colorScheme.tertiary,
                    dotData: const FlDotData(show: false),
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
