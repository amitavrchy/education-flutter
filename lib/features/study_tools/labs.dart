import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/l10n/tr.dart';
import '../../core/theme/app_spacing.dart';
import '../../shared/widgets/app_page_scaffold.dart';
import '../../shared/widgets/badges.dart';
import '../../shared/widgets/cards.dart';
import '../../shared/widgets/section_header.dart';

abstract final class LabStrings {
  static const labs = Tr('বিজ্ঞান ও গণিত ল্যাব', 'Science & maths labs');
  static const simulated = Tr('শিক্ষামূলক সিমুলেশন — সরলীকৃত মডেল।', 'Educational simulation — simplified model.');
  static const physics = Tr('পদার্থবিজ্ঞান', 'Physics');
  static const chemistry = Tr('রসায়ন', 'Chemistry');
  static const biology = Tr('জীববিজ্ঞান', 'Biology');
  static const math = Tr('গণিত', 'Mathematics');
  static const planned = Tr('শীঘ্রই আসছে', 'Coming soon');
  static const plannedNote = Tr('এই ল্যাবটি পরিকল্পনায় আছে — এখনো চালু হয়নি।', 'This lab is planned and not available yet.');
  static const alt = Tr('চিত্রের বিবরণ', 'Diagram description');
}

enum LabArea { physics, chemistry, biology, math }

class LabDef {
  const LabDef(this.id, this.area, this.title, this.icon, this.builder, {this.alt});

  final String id;
  final LabArea area;
  final Tr title;
  final IconData icon;
  final Widget Function()? builder;

  /// Text alternative for the lab's diagram (LAB-23).
  final Tr? alt;

  bool get available => builder != null;
}

final labCatalog = <LabDef>[
  LabDef(
    'motion',
    LabArea.physics,
    const Tr('গতি: v = u + at', 'Motion: v = u + at'),
    Icons.speed,
    () => const MotionLab(),
    alt: const Tr('বেগ-সময় লেখচিত্র: সময়ের সাথে বেগ সরলরেখায় বাড়ে বা কমে।', 'Velocity–time graph: velocity changes in a straight line with time.'),
  ),
  LabDef(
    'force',
    LabArea.physics,
    const Tr('বল ও ত্বরণ: F = ma', 'Force & acceleration: F = ma'),
    Icons.fitness_center,
    () => const ForceLab(),
    alt: const Tr('একটি বাক্সে তীর দিয়ে বল দেখানো; তীর যত লম্বা, বল তত বেশি।', 'An arrow pushes a box; a longer arrow means a larger force.'),
  ),
  LabDef(
    'newton',
    LabArea.physics,
    const Tr('নিউটনের সূত্র', "Newton's laws"),
    Icons.swap_horiz,
    () => const NewtonLab(),
    alt: const Tr('দুটি স্কেটারের পরস্পরকে ধাক্কা: সমান ও বিপরীত বল।', 'Two skaters push each other: equal and opposite forces.'),
  ),
  LabDef(
    'energy',
    LabArea.physics,
    const Tr('শক্তি: স্থিতি ও গতি', 'Energy: potential & kinetic'),
    Icons.bolt,
    () => const EnergyLab(),
    alt: const Tr('বার চার্টে স্থিতিশক্তি ও গতিশক্তি, মোট শক্তি সমান থাকে।', 'Bar chart of potential and kinetic energy; the total stays the same.'),
  ),
  LabDef(
    'circuit',
    LabArea.physics,
    const Tr('সরল বর্তনী: ওহমের সূত্র', "Simple circuit: Ohm's law"),
    Icons.electrical_services,
    () => const CircuitLab(),
    alt: const Tr('ব্যাটারি, রোধ ও বাল্ব; বিদ্যুৎ যত বেশি, বাল্ব তত উজ্জ্বল।', 'Battery, resistor and bulb; more current makes the bulb brighter.'),
  ),
  LabDef(
    'waves',
    LabArea.physics,
    const Tr('তরঙ্গ: v = fλ', 'Waves: v = fλ'),
    Icons.waves,
    () => const WaveLab(),
    alt: const Tr('সাইন তরঙ্গ; কম্পাঙ্ক বাড়লে তরঙ্গদৈর্ঘ্য কমে।', 'A sine wave; higher frequency gives a shorter wavelength.'),
  ),
  const LabDef('optics', LabArea.physics, Tr('আলোর প্রতিসরণ', 'Refraction of light'), Icons.light_mode_outlined, null),
  LabDef(
    'atom',
    LabArea.chemistry,
    const Tr('পরমাণুর গঠন', 'Atom structure'),
    Icons.blur_circular,
    () => const AtomLab(),
    alt: const Tr('কেন্দ্রে নিউক্লিয়াস, চারপাশে কক্ষপথে ইলেকট্রন।', 'Nucleus in the centre with electrons on shells around it.'),
  ),
  LabDef('periodic', LabArea.chemistry, const Tr('পর্যায় সারণি (১–২০)', 'Periodic table (1–20)'), Icons.grid_view, () => const PeriodicLab()),
  LabDef('bonds', LabArea.chemistry, const Tr('রাসায়নিক বন্ধন', 'Chemical bonds'), Icons.link, () => const BondLab()),
  LabDef(
    'molecules',
    LabArea.chemistry,
    const Tr('অণুর গঠন', 'Molecular structures'),
    Icons.hub_outlined,
    () => const MoleculeLab(),
    alt: const Tr('কেন্দ্রীয় পরমাণুর সাথে যুক্ত পরমাণু ও বন্ধন কোণ।', 'Atoms bonded to a central atom with the bond angle.'),
  ),
  LabDef('reactions', LabArea.chemistry, const Tr('রাসায়নিক বিক্রিয়া সমতাকরণ', 'Balancing reactions'), Icons.science_outlined, () => const ReactionLab()),
  const LabDef('organic', LabArea.chemistry, Tr('জৈব রসায়ন', 'Organic chemistry'), Icons.local_florist_outlined, null),
  LabDef(
    'cell',
    LabArea.biology,
    const Tr('কোষের চিত্র', 'Cell diagram'),
    Icons.circle_outlined,
    () => const CellLab(),
    alt: const Tr('কোষের চিত্র: কোষপর্দা, নিউক্লিয়াস, মাইটোকন্ড্রিয়া; উদ্ভিদকোষে কোষপ্রাচীর ও ক্লোরোপ্লাস্ট।', 'Cell: membrane, nucleus, mitochondria; plant cells add a wall and chloroplasts.'),
  ),
  LabDef('body', LabArea.biology, const Tr('মানবদেহের তন্ত্র', 'Human body systems'), Icons.accessibility_new, () => const BodyLab()),
  LabDef('plant', LabArea.biology, const Tr('উদ্ভিদের গঠন', 'Plant structure'), Icons.yard_outlined, () => const PlantLab()),
  LabDef('process', LabArea.biology, const Tr('প্রক্রিয়া: সালোকসংশ্লেষণ ও শ্বসন', 'Processes: photosynthesis & respiration'), Icons.autorenew, () => const ProcessLab()),
  LabDef(
    'graphs',
    LabArea.math,
    const Tr('ফাংশনের লেখচিত্র', 'Function graphs'),
    Icons.show_chart,
    () => const GraphLab(),
    alt: const Tr('লেখচিত্রে বক্ররেখা x-অক্ষকে মূলে ছেদ করে।', 'The curve crosses the x-axis at the roots.'),
  ),
  LabDef(
    'equations',
    LabArea.math,
    const Tr('সমীকরণ ভিজ্যুয়ালাইজার', 'Equation visualiser'),
    Icons.functions,
    () => const EquationLab(),
    alt: const Tr('দুটি সরলরেখা; ছেদবিন্দুই সমাধান।', 'Two straight lines; their intersection is the solution.'),
  ),
  LabDef('geometry', LabArea.math, const Tr('জ্যামিতি: ত্রিভুজ', 'Geometry: triangles'), Icons.change_history, () => const GeometryLab()),
  LabDef(
    'trig',
    LabArea.math,
    const Tr('ত্রিকোণমিতি: একক বৃত্ত', 'Trigonometry: unit circle'),
    Icons.radio_button_unchecked,
    () => const TrigLab(),
    alt: const Tr('একক বৃত্তে কোণ θ; অনুভূমিক দূরত্ব cos θ, উল্লম্ব দূরত্ব sin θ।', 'Angle θ on the unit circle; horizontal is cos θ, vertical is sin θ.'),
  ),
  LabDef('formulas', LabArea.math, const Tr('সূত্র এক্সপ্লোরার', 'Formula explorer'), Icons.menu_book_outlined, () => const FormulaLab()),
  LabDef('calculator', LabArea.math, const Tr('বৈজ্ঞানিক ক্যালকুলেটর', 'Scientific calculator'), Icons.calculate_outlined, () => const CalculatorLab()),
];

/// Lab catalogue grouped by subject (LAB-01..23).
class LabsScreen extends StatelessWidget {
  const LabsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const areas = {LabArea.physics: LabStrings.physics, LabArea.chemistry: LabStrings.chemistry, LabArea.biology: LabStrings.biology, LabArea.math: LabStrings.math};
    return AppPageScaffold(
      title: context.tr(LabStrings.labs),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InfoBanner(message: context.tr(LabStrings.simulated)),
          for (final e in areas.entries) ...[
            SectionHeader(title: context.tr(e.value)),
            for (final lab in labCatalog.where((l) => l.area == e.key))
              Card(
                margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: ListTile(
                  key: Key('lab.open.${lab.id}'),
                  enabled: lab.available,
                  leading: IconTile(icon: lab.icon, size: 40),
                  title: Text(context.tr(lab.title)),
                  trailing: lab.available ? const Icon(Icons.chevron_right) : Pill(context.tr(LabStrings.planned)),
                  onTap: lab.available
                      ? () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => LabScreen(lab: lab)))
                      : () => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.tr(LabStrings.plannedNote)))),
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class LabScreen extends StatelessWidget {
  const LabScreen({super.key, required this.lab});

  final LabDef lab;

  @override
  Widget build(BuildContext context) => AppPageScaffold(
    title: context.tr(lab.title),
    body: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        InfoBanner(message: context.tr(LabStrings.simulated)),
        const SizedBox(height: AppSpacing.md),
        lab.builder!(),
        if (lab.alt != null) ...[SectionHeader(title: context.tr(LabStrings.alt)), Text(context.tr(lab.alt!), style: Theme.of(context).textTheme.bodySmall)],
      ],
    ),
  );
}

// ───────────────────────── shared bits ─────────────────────────

class _Slider extends StatelessWidget {
  const _Slider(this.label, this.value, this.min, this.max, this.onChanged, {this.divisions});

  final String label;
  final double value;
  final double min;
  final double max;
  final ValueChanged<double> onChanged;
  final int? divisions;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      SizedBox(width: 110, child: Text('$label = ${value.toStringAsFixed(1)}')),
      Expanded(
        child: Slider(value: value, min: min, max: max, divisions: divisions ?? ((max - min) * 2).round(), onChanged: onChanged),
      ),
    ],
  );
}

Widget _result(BuildContext context, String text, String key) => Padding(
  padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
  child: Text(text, key: Key(key), style: Theme.of(context).textTheme.titleMedium),
);

class _Painted extends StatelessWidget {
  const _Painted({required this.painter, required this.label, this.height = 160});

  final CustomPainter painter;
  final String label;
  final double height;

  @override
  Widget build(BuildContext context) => Semantics(
    label: label,
    image: true,
    child: SizedBox(
      height: height,
      width: double.infinity,
      child: CustomPaint(painter: painter),
    ),
  );
}

// ───────────────────────── physics ─────────────────────────

class MotionLab extends StatefulWidget {
  const MotionLab({super.key});

  @override
  State<MotionLab> createState() => _MotionLabState();
}

class _MotionLabState extends State<MotionLab> {
  double _u = 2, _a = 1.5, _t = 4;

  @override
  Widget build(BuildContext context) {
    final v = _u + _a * _t;
    final s = _u * _t + 0.5 * _a * _t * _t;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Slider('u (m/s)', _u, 0, 10, (x) => setState(() => _u = x)),
        _Slider('a (m/s²)', _a, -2, 5, (x) => setState(() => _a = x)),
        _Slider('t (s)', _t, 0, 10, (x) => setState(() => _t = x)),
        _result(context, 'v = ${v.toStringAsFixed(1)} m/s · s = ${s.toStringAsFixed(1)} m', 'lab.motion'),
        SizedBox(
          height: 140,
          child: LineChart(
            LineChartData(
              gridData: const FlGridData(show: false),
              borderData: FlBorderData(show: false),
              titlesData: const FlTitlesData(topTitles: AxisTitles(), rightTitles: AxisTitles()),
              lineBarsData: [
                LineChartBarData(
                  spots: [for (var i = 0; i <= 10; i++) FlSpot(i * _t / 10, _u + _a * i * _t / 10)],
                  color: Theme.of(context).colorScheme.primary,
                  dotData: const FlDotData(show: false),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class ForceLab extends StatefulWidget {
  const ForceLab({super.key});

  @override
  State<ForceLab> createState() => _ForceLabState();
}

class _ForceLabState extends State<ForceLab> {
  double _f = 20, _m = 5, _friction = 0;

  @override
  Widget build(BuildContext context) {
    final net = math.max(0, _f - _friction);
    final a = net / _m;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Slider('F (N)', _f, 0, 100, (x) => setState(() => _f = x), divisions: 100),
        _Slider('m (kg)', _m, 1, 50, (x) => setState(() => _m = x), divisions: 49),
        _Slider('f (N)', _friction, 0, 50, (x) => setState(() => _friction = x), divisions: 50),
        _result(context, 'F(net) = ${net.toStringAsFixed(1)} N · a = ${a.toStringAsFixed(2)} m/s²', 'lab.force'),
        _Painted(painter: _ArrowPainter(_f / 100, Theme.of(context).colorScheme.primary), label: 'F = ${_f.round()} N', height: 80),
      ],
    );
  }
}

class _ArrowPainter extends CustomPainter {
  _ArrowPainter(this.v, this.color);

  final double v;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final box = Rect.fromCenter(center: Offset(size.width * 0.7, size.height / 2), width: 60, height: 50);
    canvas.drawRect(box, Paint()..color = color.withValues(alpha: 0.3));
    final p = Paint()
      ..color = color
      ..strokeWidth = 4;
    final end = Offset(box.left - 4, size.height / 2);
    final start = Offset(end.dx - 20 - 140 * v, end.dy);
    canvas.drawLine(start, end, p);
    canvas.drawPath(
      Path()
        ..moveTo(end.dx, end.dy)
        ..lineTo(end.dx - 10, end.dy - 7)
        ..lineTo(end.dx - 10, end.dy + 7)
        ..close(),
      p,
    );
  }

  @override
  bool shouldRepaint(_ArrowPainter old) => old.v != v;
}

class NewtonLab extends StatefulWidget {
  const NewtonLab({super.key});

  @override
  State<NewtonLab> createState() => _NewtonLabState();
}

class _NewtonLabState extends State<NewtonLab> {
  double _push = 60, _m1 = 40, _m2 = 60;

  @override
  Widget build(BuildContext context) {
    final a1 = _push / _m1, a2 = _push / _m2;
    final bn = context.isBangla;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          bn
              ? '১ম সূত্র: বাইরের বল না থাকলে বস্তু স্থির বা সমবেগে চলে।\n২য় সূত্র: F = ma\n৩য় সূত্র: প্রত্যেক ক্রিয়ার সমান ও বিপরীত প্রতিক্রিয়া আছে।'
              : '1st law: without a net force, objects stay at rest or keep moving.\n2nd law: F = ma\n3rd law: every action has an equal and opposite reaction.',
        ),
        const SizedBox(height: AppSpacing.sm),
        _Slider(bn ? 'ধাক্কা (N)' : 'Push (N)', _push, 0, 200, (x) => setState(() => _push = x), divisions: 200),
        _Slider('m₁ (kg)', _m1, 20, 100, (x) => setState(() => _m1 = x), divisions: 80),
        _Slider('m₂ (kg)', _m2, 20, 100, (x) => setState(() => _m2 = x), divisions: 80),
        _result(context, '${bn ? 'বল' : 'Force'}: ${_push.round()} N ↔ ${_push.round()} N · a₁ = ${a1.toStringAsFixed(2)} · a₂ = ${a2.toStringAsFixed(2)} m/s²', 'lab.newton'),
      ],
    );
  }
}

class EnergyLab extends StatefulWidget {
  const EnergyLab({super.key});

  @override
  State<EnergyLab> createState() => _EnergyLabState();
}

class _EnergyLabState extends State<EnergyLab> {
  double _m = 2, _h0 = 10, _h = 10;

  @override
  Widget build(BuildContext context) {
    const g = 9.8;
    final total = _m * g * _h0;
    final pe = _m * g * math.min(_h, _h0);
    final ke = total - pe;
    final v = math.sqrt(2 * ke / _m);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Slider('m (kg)', _m, 1, 10, (x) => setState(() => _m = x), divisions: 18),
        _Slider('h₀ (m)', _h0, 1, 20, (x) => setState(() => _h0 = x), divisions: 38),
        _Slider('h (m)', math.min(_h, _h0), 0, _h0, (x) => setState(() => _h = x), divisions: 40),
        _result(context, 'PE = ${pe.toStringAsFixed(0)} J · KE = ${ke.toStringAsFixed(0)} J · v = ${v.toStringAsFixed(1)} m/s', 'lab.energy'),
        SizedBox(
          height: 140,
          child: BarChart(
            BarChartData(
              maxY: total * 1.1,
              gridData: const FlGridData(show: false),
              borderData: FlBorderData(show: false),
              titlesData: FlTitlesData(
                topTitles: const AxisTitles(),
                rightTitles: const AxisTitles(),
                leftTitles: const AxisTitles(),
                bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, getTitlesWidget: (x, _) => Text(['PE', 'KE', 'E'][x.toInt()]))),
              ),
              barGroups: [
                for (final (i, val) in [pe, ke, total].indexed)
                  BarChartGroupData(
                    x: i,
                    barRods: [
                      BarChartRodData(toY: val, width: 28, color: [Colors.blue, Colors.orange, Colors.green][i]),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class CircuitLab extends StatefulWidget {
  const CircuitLab({super.key});

  @override
  State<CircuitLab> createState() => _CircuitLabState();
}

class _CircuitLabState extends State<CircuitLab> {
  double _v = 12, _r1 = 6, _r2 = 6;
  bool _parallel = false, _two = false;

  @override
  Widget build(BuildContext context) {
    final r = !_two ? _r1 : (_parallel ? 1 / (1 / _r1 + 1 / _r2) : _r1 + _r2);
    final current = _v / r;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Slider('V (V)', _v, 1, 24, (x) => setState(() => _v = x)),
        _Slider('R₁ (Ω)', _r1, 1, 20, (x) => setState(() => _r1 = x)),
        SwitchListTile(contentPadding: EdgeInsets.zero, title: Text(context.isBangla ? 'দ্বিতীয় রোধ যোগ' : 'Add a second resistor'), value: _two, onChanged: (v) => setState(() => _two = v)),
        if (_two) ...[
          _Slider('R₂ (Ω)', _r2, 1, 20, (x) => setState(() => _r2 = x)),
          SegmentedButton<bool>(
            segments: [
              ButtonSegment(value: false, label: Text(context.isBangla ? 'শ্রেণি' : 'Series')),
              ButtonSegment(value: true, label: Text(context.isBangla ? 'সমান্তরাল' : 'Parallel')),
            ],
            selected: {_parallel},
            onSelectionChanged: (v) => setState(() => _parallel = v.first),
          ),
        ],
        Row(
          children: [
            Icon(Icons.lightbulb, size: 40, color: Colors.amber.withValues(alpha: (current / 6).clamp(0.15, 1.0))),
            const SizedBox(width: AppSpacing.sm),
            Expanded(child: _result(context, 'R = ${r.toStringAsFixed(2)} Ω · I = V / R = ${current.toStringAsFixed(2)} A · P = ${(_v * current).toStringAsFixed(1)} W', 'lab.ohm')),
          ],
        ),
      ],
    );
  }
}

class WaveLab extends StatefulWidget {
  const WaveLab({super.key});

  @override
  State<WaveLab> createState() => _WaveLabState();
}

class _WaveLabState extends State<WaveLab> {
  double _f = 2, _amp = 1, _v = 340;

  @override
  Widget build(BuildContext context) {
    final lambda = _v / _f;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Slider('f (Hz)', _f, 1, 10, (x) => setState(() => _f = x), divisions: 18),
        _Slider('A', _amp, 0.2, 2, (x) => setState(() => _amp = x), divisions: 18),
        _Slider('v (m/s)', _v, 100, 400, (x) => setState(() => _v = x), divisions: 30),
        _result(context, 'λ = v / f = ${lambda.toStringAsFixed(1)} m · T = ${(1 / _f).toStringAsFixed(2)} s', 'lab.wave'),
        _Painted(painter: _WavePainter(_f, _amp, Theme.of(context).colorScheme.primary), label: 'f = ${_f.toStringAsFixed(1)} Hz, A = ${_amp.toStringAsFixed(1)}'),
      ],
    );
  }
}

class _WavePainter extends CustomPainter {
  _WavePainter(this.f, this.a, this.color);

  final double f;
  final double a;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final mid = size.height / 2;
    canvas.drawLine(Offset(0, mid), Offset(size.width, mid), Paint()..color = color.withValues(alpha: 0.2));
    final path = Path()..moveTo(0, mid);
    for (var x = 0.0; x <= size.width; x += 2) {
      path.lineTo(x, mid - a * size.height * 0.2 * math.sin(2 * math.pi * f * x / size.width));
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5,
    );
  }

  @override
  bool shouldRepaint(_WavePainter old) => old.f != f || old.a != a;
}

// ───────────────────────── chemistry ─────────────────────────

const _elements = [
  ('H', 'Hydrogen', 'হাইড্রোজেন', 1.008, 2.20),
  ('He', 'Helium', 'হিলিয়াম', 4.003, 0.0),
  ('Li', 'Lithium', 'লিথিয়াম', 6.94, 0.98),
  ('Be', 'Beryllium', 'বেরিলিয়াম', 9.012, 1.57),
  ('B', 'Boron', 'বোরন', 10.81, 2.04),
  ('C', 'Carbon', 'কার্বন', 12.011, 2.55),
  ('N', 'Nitrogen', 'নাইট্রোজেন', 14.007, 3.04),
  ('O', 'Oxygen', 'অক্সিজেন', 15.999, 3.44),
  ('F', 'Fluorine', 'ফ্লোরিন', 18.998, 3.98),
  ('Ne', 'Neon', 'নিয়ন', 20.180, 0.0),
  ('Na', 'Sodium', 'সোডিয়াম', 22.990, 0.93),
  ('Mg', 'Magnesium', 'ম্যাগনেসিয়াম', 24.305, 1.31),
  ('Al', 'Aluminium', 'অ্যালুমিনিয়াম', 26.982, 1.61),
  ('Si', 'Silicon', 'সিলিকন', 28.085, 1.90),
  ('P', 'Phosphorus', 'ফসফরাস', 30.974, 2.19),
  ('S', 'Sulfur', 'সালফার', 32.06, 2.58),
  ('Cl', 'Chlorine', 'ক্লোরিন', 35.45, 3.16),
  ('Ar', 'Argon', 'আর্গন', 39.948, 0.0),
  ('K', 'Potassium', 'পটাশিয়াম', 39.098, 0.82),
  ('Ca', 'Calcium', 'ক্যালসিয়াম', 40.078, 1.00),
];

int _period(int z) => z <= 2 ? 1 : (z <= 10 ? 2 : (z <= 18 ? 3 : 4));

List<int> shellsOf(int z) {
  final shells = <int>[];
  var left = z;
  for (final cap in const [2, 8, 8, 2]) {
    if (left <= 0) break;
    shells.add(math.min(cap, left));
    left -= cap;
  }
  return shells;
}

class AtomLab extends StatefulWidget {
  const AtomLab({super.key});

  @override
  State<AtomLab> createState() => _AtomLabState();
}

class _AtomLabState extends State<AtomLab> {
  double _z = 6;

  @override
  Widget build(BuildContext context) {
    final z = _z.round();
    final e = _elements[z - 1];
    final neutrons = (e.$4 - z).round();
    final shells = shellsOf(z);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Slider('Z', _z, 1, 20, (x) => setState(() => _z = x), divisions: 19),
        _result(context, '${e.$1} (${context.isBangla ? e.$3 : e.$2}) · p = $z · n = $neutrons · e = $z · ${shells.join(', ')}', 'lab.atom'),
        _Painted(painter: _AtomPainter(shells, Theme.of(context).colorScheme.primary), label: '${e.$2}: ${shells.join(', ')}', height: 200),
      ],
    );
  }
}

class _AtomPainter extends CustomPainter {
  _AtomPainter(this.shells, this.color);

  final List<int> shells;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    canvas.drawCircle(c, 12, Paint()..color = Colors.red.shade300);
    for (final (i, n) in shells.indexed) {
      final r = 28.0 + i * 22;
      canvas.drawCircle(
        c,
        r,
        Paint()
          ..color = color.withValues(alpha: 0.4)
          ..style = PaintingStyle.stroke,
      );
      for (var k = 0; k < n; k++) {
        final a = 2 * math.pi * k / n;
        canvas.drawCircle(c + Offset(r * math.cos(a), r * math.sin(a)), 4, Paint()..color = color);
      }
    }
  }

  @override
  bool shouldRepaint(_AtomPainter old) => old.shells.join() != shells.join();
}

class PeriodicLab extends StatefulWidget {
  const PeriodicLab({super.key});

  @override
  State<PeriodicLab> createState() => _PeriodicLabState();
}

class _PeriodicLabState extends State<PeriodicLab> {
  int? _el;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
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
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('${i + 1}', style: text.labelSmall),
                      Text(e.$1, style: text.titleMedium),
                    ],
                  ),
                ),
              ),
          ],
        ),
        if (_el case final i?)
          Card(
            child: ListTile(
              title: Text('${_elements[i].$1} — ${context.isBangla ? _elements[i].$3 : _elements[i].$2}'),
              subtitle: Text(
                'Z = ${i + 1} · ${context.isBangla ? 'পারমাণবিক ভর' : 'Atomic mass'} ${_elements[i].$4} · ${context.isBangla ? 'পর্যায়' : 'Period'} ${_period(i + 1)} · ${context.isBangla ? 'ইলেকট্রন বিন্যাস' : 'Shells'} ${shellsOf(i + 1).join(', ')}',
              ),
            ),
          ),
      ],
    );
  }
}

/// Bond type from the electronegativity difference (simplified rule).
String bondType(double en1, double en2) {
  if (en1 == 0 || en2 == 0) return 'none';
  final d = (en1 - en2).abs();
  if (d >= 1.7) return 'ionic';
  if (d >= 0.4) return 'polar';
  return 'covalent';
}

class BondLab extends StatefulWidget {
  const BondLab({super.key});

  @override
  State<BondLab> createState() => _BondLabState();
}

class _BondLabState extends State<BondLab> {
  int _a = 10, _b = 16;

  @override
  Widget build(BuildContext context) {
    final ea = _elements[_a], eb = _elements[_b];
    final t = bondType(ea.$5, eb.$5);
    final bn = context.isBangla;
    final label = switch (t) {
      'ionic' => bn ? 'আয়নিক বন্ধন (ইলেকট্রন স্থানান্তর)' : 'Ionic bond (electron transfer)',
      'polar' => bn ? 'পোলার সমযোজী বন্ধন' : 'Polar covalent bond',
      'covalent' => bn ? 'সমযোজী বন্ধন (ইলেকট্রন ভাগাভাগি)' : 'Covalent bond (shared electrons)',
      _ => bn ? 'নিষ্ক্রিয় গ্যাস — সাধারণত বন্ধন গঠন করে না' : 'Noble gas — usually forms no bond',
    };
    Widget pick(int value, ValueChanged<int> on) => DropdownButton<int>(
      value: value,
      items: [for (final (i, e) in _elements.indexed) DropdownMenuItem(value: i, child: Text(e.$1))],
      onChanged: (v) => setState(() => on(v ?? value)),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [pick(_a, (v) => _a = v), const Text('  +  '), pick(_b, (v) => _b = v)]),
        _result(context, 'ΔEN = ${(ea.$5 - eb.$5).abs().toStringAsFixed(2)} → $label', 'lab.bond'),
      ],
    );
  }
}

class MoleculeLab extends StatefulWidget {
  const MoleculeLab({super.key});

  @override
  State<MoleculeLab> createState() => _MoleculeLabState();
}

class _MoleculeLabState extends State<MoleculeLab> {
  static const _molecules = [
    ('H₂O', 'O', 'H', 2, 104.5, Tr('বাঁকা', 'Bent')),
    ('CO₂', 'C', 'O', 2, 180.0, Tr('সরলরৈখিক', 'Linear')),
    ('CH₄', 'C', 'H', 4, 109.5, Tr('চতুস্তলকীয়', 'Tetrahedral')),
    ('NH₃', 'N', 'H', 3, 107.0, Tr('ত্রিকোণীয় পিরামিড', 'Trigonal pyramidal')),
  ];
  int _i = 0;

  @override
  Widget build(BuildContext context) {
    final m = _molecules[_i];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: AppSpacing.xs,
          children: [for (final (i, x) in _molecules.indexed) ChoiceChip(label: Text(x.$1), selected: _i == i, onSelected: (_) => setState(() => _i = i))],
        ),
        _result(context, '${m.$1}: ${context.tr(m.$6)} · ${m.$5}°', 'lab.molecule'),
        _Painted(painter: _MoleculePainter(m.$2, m.$3, m.$4, m.$5, Theme.of(context).colorScheme.primary), label: '${m.$1} ${m.$6.en}, ${m.$5} degrees', height: 180),
      ],
    );
  }
}

class _MoleculePainter extends CustomPainter {
  _MoleculePainter(this.center, this.outer, this.n, this.angle, this.color);

  final String center;
  final String outer;
  final int n;
  final double angle;
  final Color color;

  void _label(Canvas canvas, Offset at, String t, Color bg) {
    canvas.drawCircle(at, 16, Paint()..color = bg);
    final tp = TextPainter(
      text: TextSpan(
        text: t,
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, at - Offset(tp.width / 2, tp.height / 2));
  }

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final rad = angle * math.pi / 180;
    final dirs = n == 2 ? [-math.pi / 2 - rad / 2 + math.pi, -math.pi / 2 + rad / 2 + math.pi] : [for (var k = 0; k < n; k++) 2 * math.pi * k / n - math.pi / 2];
    for (final d in dirs) {
      final p = c + Offset(60 * math.cos(d), 60 * math.sin(d));
      canvas.drawLine(
        c,
        p,
        Paint()
          ..color = Colors.grey
          ..strokeWidth = 3,
      );
      _label(canvas, p, outer, Colors.blueGrey);
    }
    _label(canvas, c, center, color);
  }

  @override
  bool shouldRepaint(_MoleculePainter old) => old.center != center || old.angle != angle;
}

class ReactionLab extends StatefulWidget {
  const ReactionLab({super.key});

  @override
  State<ReactionLab> createState() => _ReactionLabState();
}

class _ReactionLabState extends State<ReactionLab> {
  /// Each reaction: species (formula, atom counts, isProduct) and the balanced coefficients.
  static const _reactions = [
    (
      [
        ('H₂', {'H': 2}, false),
        ('O₂', {'O': 2}, false),
        ('H₂O', {'H': 2, 'O': 1}, true),
      ],
      [2, 1, 2],
    ),
    (
      [
        ('CH₄', {'C': 1, 'H': 4}, false),
        ('O₂', {'O': 2}, false),
        ('CO₂', {'C': 1, 'O': 2}, true),
        ('H₂O', {'H': 2, 'O': 1}, true),
      ],
      [1, 2, 1, 2],
    ),
    (
      [
        ('N₂', {'N': 2}, false),
        ('H₂', {'H': 2}, false),
        ('NH₃', {'N': 1, 'H': 3}, true),
      ],
      [1, 3, 2],
    ),
  ];
  int _r = 0;
  late List<int> _coef = List.filled(_reactions[0].$1.length, 1);

  bool get _balanced {
    final atoms = <String, int>{};
    for (final (i, (_, counts, product)) in _reactions[_r].$1.indexed) {
      counts.forEach((el, n) => atoms.update(el, (v) => v + (product ? -1 : 1) * n * _coef[i], ifAbsent: () => (product ? -1 : 1) * n * _coef[i]));
    }
    return atoms.values.every((v) => v == 0);
  }

  @override
  Widget build(BuildContext context) {
    final species = _reactions[_r].$1;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: AppSpacing.xs,
          children: [
            for (var i = 0; i < _reactions.length; i++)
              ChoiceChip(
                label: Text('${i + 1}'),
                selected: _r == i,
                onSelected: (_) => setState(() {
                  _r = i;
                  _coef = List.filled(_reactions[i].$1.length, 1);
                }),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 4,
          children: [
            for (final (i, s) in species.indexed) ...[
              if (i > 0) Text(s.$3 && !species[i - 1].$3 ? ' → ' : ' + '),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(visualDensity: VisualDensity.compact, icon: const Icon(Icons.remove, size: 16), onPressed: _coef[i] > 1 ? () => setState(() => _coef[i]--) : null),
                  Text('${_coef[i]}${s.$1}', key: Key('rx.$i')),
                  IconButton(key: Key('rx.plus.$i'), visualDensity: VisualDensity.compact, icon: const Icon(Icons.add, size: 16), onPressed: () => setState(() => _coef[i]++)),
                ],
              ),
            ],
          ],
        ),
        _result(context, _balanced ? (context.isBangla ? '✓ সমতাকৃত!' : '✓ Balanced!') : (context.isBangla ? 'এখনো সমতাকৃত নয়' : 'Not balanced yet'), 'lab.reaction'),
      ],
    );
  }
}

// ───────────────────────── biology ─────────────────────────

class _PartsLab extends StatefulWidget {
  const _PartsLab({required this.groups, this.diagram});

  /// (group name, parts (name, description)).
  final List<(Tr, List<(Tr, Tr)>)> groups;
  final Widget Function(int group, int? part)? diagram;

  @override
  State<_PartsLab> createState() => _PartsLabState();
}

class _PartsLabState extends State<_PartsLab> {
  int _g = 0;
  int? _p;

  @override
  Widget build(BuildContext context) {
    final groups = widget.groups;
    final parts = groups[_g].$2;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: AppSpacing.xs,
          children: [
            for (final (i, e) in groups.indexed)
              ChoiceChip(
                label: Text(context.tr(e.$1)),
                selected: _g == i,
                onSelected: (_) => setState(() {
                  _g = i;
                  _p = null;
                }),
              ),
          ],
        ),
        if (widget.diagram != null) widget.diagram!(_g, _p),
        const SizedBox(height: AppSpacing.sm),
        for (final (i, (name, desc)) in parts.indexed)
          Card(
            color: _p == i ? Theme.of(context).colorScheme.primaryContainer : null,
            margin: const EdgeInsets.only(bottom: AppSpacing.xs),
            child: ListTile(title: Text(context.tr(name)), subtitle: _p == i ? Text(context.tr(desc)) : null, onTap: () => setState(() => _p = i)),
          ),
      ],
    );
  }
}

class CellLab extends StatelessWidget {
  const CellLab({super.key});

  static const _common = [
    (Tr('কোষপর্দা', 'Cell membrane'), Tr('কোষের ভেতরে-বাইরে পদার্থের চলাচল নিয়ন্ত্রণ করে।', 'Controls what enters and leaves the cell.')),
    (Tr('নিউক্লিয়াস', 'Nucleus'), Tr('DNA ধারণ করে, কোষের কাজ নিয়ন্ত্রণ করে।', 'Holds DNA and controls the cell.')),
    (Tr('মাইটোকন্ড্রিয়া', 'Mitochondria'), Tr('শ্বসনে শক্তি (ATP) উৎপন্ন করে।', 'Releases energy (ATP) in respiration.')),
    (Tr('সাইটোপ্লাজম', 'Cytoplasm'), Tr('জেলির মতো অংশ, যেখানে বিক্রিয়া ঘটে।', 'Jelly-like part where reactions happen.')),
  ];

  @override
  Widget build(BuildContext context) => _PartsLab(
    groups: [
      (const Tr('প্রাণিকোষ', 'Animal cell'), _common),
      (
        const Tr('উদ্ভিদকোষ', 'Plant cell'),
        [
          ..._common,
          (const Tr('কোষপ্রাচীর', 'Cell wall'), const Tr('সেলুলোজের শক্ত প্রাচীর, আকার ধরে রাখে।', 'Rigid cellulose wall that keeps the shape.')),
          (const Tr('ক্লোরোপ্লাস্ট', 'Chloroplast'), const Tr('সালোকসংশ্লেষণ ঘটে; ক্লোরোফিল থাকে।', 'Site of photosynthesis; contains chlorophyll.')),
          (const Tr('কোষগহ্বর', 'Vacuole'), const Tr('কোষরস জমা রাখে।', 'Stores cell sap.')),
        ],
      ),
    ],
    diagram: (g, p) => _Painted(painter: _CellPainter(g == 1, p, Theme.of(context).colorScheme.primary), label: g == 1 ? 'Plant cell diagram' : 'Animal cell diagram', height: 170),
  );
}

class _CellPainter extends CustomPainter {
  _CellPainter(this.plant, this.part, this.color);

  final bool plant;
  final int? part;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    Paint stroke(int i) => Paint()
      ..color = part == i ? Colors.orange : color
      ..style = PaintingStyle.stroke
      ..strokeWidth = part == i ? 4 : 2;
    if (plant) canvas.drawRect(Rect.fromCenter(center: c, width: 220, height: 150), stroke(4));
    final membrane = plant ? Rect.fromCenter(center: c, width: 206, height: 136) : Rect.fromCenter(center: c, width: 200, height: 140);
    plant ? canvas.drawRect(membrane, stroke(0)) : canvas.drawOval(membrane, stroke(0));
    canvas.drawCircle(c + const Offset(-30, -10), 24, stroke(1));
    canvas.drawOval(Rect.fromCenter(center: c + const Offset(50, 30), width: 36, height: 18), stroke(2));
    if (plant) {
      canvas.drawOval(Rect.fromCenter(center: c + const Offset(60, -35), width: 30, height: 16), stroke(5)..color = part == 5 ? Colors.orange : Colors.green);
      canvas.drawRect(Rect.fromCenter(center: c + const Offset(20, 0), width: 50, height: 60), stroke(6));
    }
  }

  @override
  bool shouldRepaint(_CellPainter old) => old.plant != plant || old.part != part;
}

class BodyLab extends StatelessWidget {
  const BodyLab({super.key});

  @override
  Widget build(BuildContext context) => const _PartsLab(
    groups: [
      (
        Tr('পরিপাকতন্ত্র', 'Digestive'),
        [
          (Tr('মুখ', 'Mouth'), Tr('চিবানো ও লালার এনজাইম দিয়ে পরিপাক শুরু।', 'Chewing and saliva start digestion.')),
          (Tr('পাকস্থলী', 'Stomach'), Tr('অ্যাসিড ও এনজাইমে প্রোটিন ভাঙে।', 'Acid and enzymes break down protein.')),
          (Tr('ক্ষুদ্রান্ত্র', 'Small intestine'), Tr('খাদ্যের সার শোষণ হয়।', 'Nutrients are absorbed.')),
        ],
      ),
      (
        Tr('শ্বসনতন্ত্র', 'Respiratory'),
        [
          (Tr('শ্বাসনালি', 'Trachea'), Tr('বায়ু ফুসফুসে পৌঁছায়।', 'Carries air to the lungs.')),
          (Tr('ফুসফুস', 'Lungs'), Tr('অ্যালভিওলাইতে গ্যাস বিনিময়।', 'Gas exchange in the alveoli.')),
          (Tr('মধ্যচ্ছদা', 'Diaphragm'), Tr('শ্বাস নেওয়া-ছাড়ায় সাহায্য করে।', 'Helps breathing in and out.')),
        ],
      ),
      (
        Tr('রক্তসংবহন', 'Circulatory'),
        [
          (Tr('হৃৎপিণ্ড', 'Heart'), Tr('রক্ত পাম্প করে।', 'Pumps blood.')),
          (Tr('ধমনি', 'Arteries'), Tr('হৃৎপিণ্ড থেকে রক্ত বয়ে নেয়।', 'Carry blood away from the heart.')),
          (Tr('শিরা', 'Veins'), Tr('রক্ত হৃৎপিণ্ডে ফেরত আনে।', 'Return blood to the heart.')),
        ],
      ),
      (
        Tr('স্নায়ুতন্ত্র', 'Nervous'),
        [
          (Tr('মস্তিষ্ক', 'Brain'), Tr('চিন্তা ও নিয়ন্ত্রণের কেন্দ্র।', 'Centre of thinking and control.')),
          (Tr('সুষুম্নাকাণ্ড', 'Spinal cord'), Tr('মস্তিষ্ক ও দেহের মধ্যে সংকেত বহন।', 'Carries signals between brain and body.')),
          (Tr('স্নায়ু', 'Nerves'), Tr('সংকেত পরিবহন করে।', 'Transmit signals.')),
        ],
      ),
    ],
  );
}

class PlantLab extends StatelessWidget {
  const PlantLab({super.key});

  @override
  Widget build(BuildContext context) => const _PartsLab(
    groups: [
      (
        Tr('অংশ', 'Parts'),
        [
          (Tr('মূল', 'Root'), Tr('মাটি থেকে পানি ও খনিজ শোষণ, গাছকে ধরে রাখে।', 'Absorbs water and minerals; anchors the plant.')),
          (Tr('কাণ্ড', 'Stem'), Tr('জাইলেম ও ফ্লোয়েম দিয়ে পরিবহন।', 'Transports through xylem and phloem.')),
          (Tr('পাতা', 'Leaf'), Tr('সালোকসংশ্লেষণ ও প্রস্বেদন।', 'Photosynthesis and transpiration.')),
          (Tr('ফুল', 'Flower'), Tr('প্রজননের অঙ্গ।', 'Reproductive organ.')),
        ],
      ),
      (
        Tr('ফুলের অংশ', 'Flower parts'),
        [
          (Tr('বৃতি', 'Sepal'), Tr('কুঁড়িকে রক্ষা করে।', 'Protects the bud.')),
          (Tr('দল', 'Petal'), Tr('পরাগবাহককে আকর্ষণ করে।', 'Attracts pollinators.')),
          (Tr('পুংকেশর', 'Stamen'), Tr('পরাগরেণু উৎপন্ন করে।', 'Produces pollen.')),
          (Tr('গর্ভকেশর', 'Carpel'), Tr('ডিম্বক ধারণ করে।', 'Contains the ovules.')),
        ],
      ),
    ],
  );
}

class ProcessLab extends StatefulWidget {
  const ProcessLab({super.key});

  @override
  State<ProcessLab> createState() => _ProcessLabState();
}

class _ProcessLabState extends State<ProcessLab> {
  static const _processes = [
    (
      Tr('সালোকসংশ্লেষণ', 'Photosynthesis'),
      '6CO₂ + 6H₂O → C₆H₁₂O₆ + 6O₂',
      [
        Tr('পাতা আলো শোষণ করে (ক্লোরোফিল)।', 'The leaf absorbs light (chlorophyll).'),
        Tr('মূল থেকে পানি আসে, পত্ররন্ধ্র দিয়ে CO₂ ঢোকে।', 'Water comes from the roots; CO₂ enters through stomata.'),
        Tr('আলোর শক্তিতে পানি ভেঙে O₂ বের হয়।', 'Light energy splits water and releases O₂.'),
        Tr('CO₂ থেকে গ্লুকোজ তৈরি হয়।', 'Glucose is made from CO₂.'),
      ],
    ),
    (
      Tr('শ্বসন', 'Respiration'),
      'C₆H₁₂O₆ + 6O₂ → 6CO₂ + 6H₂O + ATP',
      [
        Tr('গ্লুকোজ কোষে পৌঁছায়।', 'Glucose reaches the cell.'),
        Tr('সাইটোপ্লাজমে গ্লাইকোলাইসিস।', 'Glycolysis in the cytoplasm.'),
        Tr('মাইটোকন্ড্রিয়ায় অক্সিজেন দিয়ে ভাঙন।', 'Breakdown with oxygen in mitochondria.'),
        Tr('শক্তি (ATP), CO₂ ও পানি উৎপন্ন হয়।', 'Energy (ATP), CO₂ and water are produced.'),
      ],
    ),
  ];
  int _p = 0;
  int _step = 0;

  @override
  Widget build(BuildContext context) {
    final (name, eq, steps) = _processes[_p];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: AppSpacing.xs,
          children: [
            for (final (i, x) in _processes.indexed)
              ChoiceChip(
                label: Text(context.tr(x.$1)),
                selected: _p == i,
                onSelected: (_) => setState(() {
                  _p = i;
                  _step = 0;
                }),
              ),
          ],
        ),
        _result(context, eq, 'lab.process'),
        LinearProgressIndicator(value: (_step + 1) / steps.length),
        const SizedBox(height: AppSpacing.sm),
        for (final (i, s) in steps.indexed)
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: CircleAvatar(
              radius: 12,
              backgroundColor: i <= _step ? Theme.of(context).colorScheme.primary : null,
              child: Text('${i + 1}', style: const TextStyle(fontSize: 11)),
            ),
            title: Text(context.tr(s), style: TextStyle(color: i <= _step ? null : Theme.of(context).disabledColor)),
          ),
        Row(
          children: [
            TextButton(onPressed: _step > 0 ? () => setState(() => _step--) : null, child: const Icon(Icons.chevron_left)),
            const Spacer(),
            FilledButton(key: const Key('process.next'), onPressed: _step < steps.length - 1 ? () => setState(() => _step++) : null, child: const Icon(Icons.chevron_right)),
          ],
        ),
      ],
    );
  }
}

// ───────────────────────── maths ─────────────────────────

class GraphLab extends StatefulWidget {
  const GraphLab({super.key});

  @override
  State<GraphLab> createState() => _GraphLabState();
}

class _GraphLabState extends State<GraphLab> {
  double _qa = 1, _qb = 0, _qc = -4;
  String _kind = 'quad';

  double _f(double x) => switch (_kind) {
    'line' => _qa * x + _qb,
    'sin' => _qa * math.sin(x + _qb) + _qc,
    _ => _qa * x * x + _qb * x + _qc,
  };

  @override
  Widget build(BuildContext context) {
    final d = _qb * _qb - 4 * _qa * _qc;
    final roots = _qa == 0
        ? (_qb == 0 ? '—' : (-_qc / _qb).toStringAsFixed(2))
        : d < 0
        ? (context.isBangla ? 'বাস্তব মূল নেই' : 'no real roots')
        : [(-_qb + math.sqrt(d)) / (2 * _qa), (-_qb - math.sqrt(d)) / (2 * _qa)].map((r) => r.toStringAsFixed(2)).toSet().join(', ');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SegmentedButton<String>(
          segments: const [
            ButtonSegment(value: 'quad', label: Text('ax²+bx+c')),
            ButtonSegment(value: 'line', label: Text('ax+b')),
            ButtonSegment(value: 'sin', label: Text('a·sin(x+b)+c')),
          ],
          selected: {_kind},
          onSelectionChanged: (v) => setState(() => _kind = v.first),
        ),
        _Slider('a', _qa, -3, 3, (x) => setState(() => _qa = x)),
        _Slider('b', _qb, -5, 5, (x) => setState(() => _qb = x)),
        if (_kind != 'line') _Slider('c', _qc, -5, 5, (x) => setState(() => _qc = x)),
        if (_kind == 'quad') _result(context, 'D = ${d.toStringAsFixed(2)} · x = $roots', 'lab.roots'),
        if (_kind == 'line') _result(context, _qa == 0 ? '—' : 'x = ${(-_qb / _qa).toStringAsFixed(2)}', 'lab.lineRoot'),
        SizedBox(
          height: 180,
          child: LineChart(
            LineChartData(
              minY: -10,
              maxY: 10,
              gridData: const FlGridData(drawVerticalLine: false),
              borderData: FlBorderData(show: false),
              titlesData: const FlTitlesData(topTitles: AxisTitles(), rightTitles: AxisTitles()),
              lineBarsData: [
                LineChartBarData(
                  spots: [for (var x = -5.0; x <= 5.0; x += 0.25) FlSpot(x, _f(x).clamp(-10, 10))],
                  isCurved: true,
                  color: Theme.of(context).colorScheme.tertiary,
                  dotData: const FlDotData(show: false),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class EquationLab extends StatefulWidget {
  const EquationLab({super.key});

  @override
  State<EquationLab> createState() => _EquationLabState();
}

class _EquationLabState extends State<EquationLab> {
  double _m1 = 1, _c1 = 1, _m2 = -1, _c2 = 3;

  @override
  Widget build(BuildContext context) {
    final parallel = (_m1 - _m2).abs() < 1e-9;
    final x = parallel ? null : (_c2 - _c1) / (_m1 - _m2);
    final y = x == null ? null : _m1 * x + _c1;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Slider('m₁', _m1, -3, 3, (v) => setState(() => _m1 = v)),
        _Slider('c₁', _c1, -5, 5, (v) => setState(() => _c1 = v)),
        _Slider('m₂', _m2, -3, 3, (v) => setState(() => _m2 = v)),
        _Slider('c₂', _c2, -5, 5, (v) => setState(() => _c2 = v)),
        _result(context, x == null ? (context.isBangla ? 'সমান্তরাল — সমাধান নেই' : 'Parallel — no solution') : '(x, y) = (${x.toStringAsFixed(2)}, ${y!.toStringAsFixed(2)})', 'lab.equation'),
        SizedBox(
          height: 180,
          child: LineChart(
            LineChartData(
              minY: -10,
              maxY: 10,
              minX: -5,
              maxX: 5,
              gridData: const FlGridData(drawVerticalLine: false),
              borderData: FlBorderData(show: false),
              titlesData: const FlTitlesData(topTitles: AxisTitles(), rightTitles: AxisTitles()),
              lineBarsData: [
                LineChartBarData(spots: [FlSpot(-5, (_m1 * -5 + _c1).clamp(-10, 10)), FlSpot(5, (_m1 * 5 + _c1).clamp(-10, 10))], color: Colors.blue, dotData: const FlDotData(show: false)),
                LineChartBarData(spots: [FlSpot(-5, (_m2 * -5 + _c2).clamp(-10, 10)), FlSpot(5, (_m2 * 5 + _c2).clamp(-10, 10))], color: Colors.red, dotData: const FlDotData(show: false)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class GeometryLab extends StatefulWidget {
  const GeometryLab({super.key});

  @override
  State<GeometryLab> createState() => _GeometryLabState();
}

class _GeometryLabState extends State<GeometryLab> {
  double _a = 3, _b = 4, _c = 5;

  @override
  Widget build(BuildContext context) {
    final valid = _a + _b > _c && _a + _c > _b && _b + _c > _a;
    final s = (_a + _b + _c) / 2;
    final area = valid ? math.sqrt(s * (s - _a) * (s - _b) * (s - _c)) : 0.0;
    double angle(double opp, double x, double y) => math.acos(((x * x + y * y - opp * opp) / (2 * x * y)).clamp(-1, 1)) * 180 / math.pi;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Slider('a', _a, 1, 10, (v) => setState(() => _a = v)),
        _Slider('b', _b, 1, 10, (v) => setState(() => _b = v)),
        _Slider('c', _c, 1, 10, (v) => setState(() => _c = v)),
        _result(
          context,
          valid
              ? '${context.isBangla ? 'ক্ষেত্রফল' : 'Area'} = ${area.toStringAsFixed(2)} · A = ${angle(_a, _b, _c).toStringAsFixed(1)}° · B = ${angle(_b, _a, _c).toStringAsFixed(1)}° · C = ${angle(_c, _a, _b).toStringAsFixed(1)}°'
              : (context.isBangla ? 'এই বাহুগুলো দিয়ে ত্রিভুজ হয় না' : 'These sides do not form a triangle'),
          'lab.geometry',
        ),
      ],
    );
  }
}

class TrigLab extends StatefulWidget {
  const TrigLab({super.key});

  @override
  State<TrigLab> createState() => _TrigLabState();
}

class _TrigLabState extends State<TrigLab> {
  double _deg = 30;

  @override
  Widget build(BuildContext context) {
    final r = _deg * math.pi / 180;
    final tan = (math.cos(r)).abs() < 1e-9 ? '∞' : math.tan(r).toStringAsFixed(3);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Slider('θ (°)', _deg, 0, 360, (v) => setState(() => _deg = v), divisions: 72),
        _result(context, 'sin = ${math.sin(r).toStringAsFixed(3)} · cos = ${math.cos(r).toStringAsFixed(3)} · tan = $tan', 'lab.trig'),
        _Painted(painter: _UnitCirclePainter(r, Theme.of(context).colorScheme.primary), label: 'theta ${_deg.round()} degrees', height: 200),
      ],
    );
  }
}

class _UnitCirclePainter extends CustomPainter {
  _UnitCirclePainter(this.r, this.color);

  final double r;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final rad = size.height * 0.42;
    final grey = Paint()..color = Colors.grey;
    canvas.drawLine(Offset(c.dx - rad - 10, c.dy), Offset(c.dx + rad + 10, c.dy), grey);
    canvas.drawLine(Offset(c.dx, c.dy - rad - 10), Offset(c.dx, c.dy + rad + 10), grey);
    canvas.drawCircle(
      c,
      rad,
      Paint()
        ..color = color.withValues(alpha: 0.4)
        ..style = PaintingStyle.stroke,
    );
    final p = c + Offset(rad * math.cos(r), -rad * math.sin(r));
    canvas.drawLine(
      c,
      p,
      Paint()
        ..color = color
        ..strokeWidth = 3,
    );
    canvas.drawLine(
      p,
      Offset(p.dx, c.dy),
      Paint()
        ..color = Colors.red
        ..strokeWidth = 2,
    );
    canvas.drawLine(
      c,
      Offset(p.dx, c.dy),
      Paint()
        ..color = Colors.blue
        ..strokeWidth = 2,
    );
    canvas.drawCircle(p, 5, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_UnitCirclePainter old) => old.r != r;
}

class FormulaLab extends StatefulWidget {
  const FormulaLab({super.key});

  @override
  State<FormulaLab> createState() => _FormulaLabState();
}

class _FormulaLabState extends State<FormulaLab> {
  static final _formulas = <(String, String, List<String>, double Function(List<double>))>[
    ('Area of a circle', 'A = πr²', ['r'], (v) => math.pi * v[0] * v[0]),
    ('Pythagoras', 'c = √(a² + b²)', ['a', 'b'], (v) => math.sqrt(v[0] * v[0] + v[1] * v[1])),
    ('Speed', 'v = s / t', ['s', 't'], (v) => v[1] == 0 ? double.nan : v[0] / v[1]),
    ('Density', 'ρ = m / V', ['m', 'V'], (v) => v[1] == 0 ? double.nan : v[0] / v[1]),
    ('Simple interest', 'I = Prt / 100', ['P', 'r', 't'], (v) => v[0] * v[1] * v[2] / 100),
    ('Kinetic energy', 'KE = ½mv²', ['m', 'v'], (v) => 0.5 * v[0] * v[1] * v[1]),
  ];
  String _q = '';
  int _open = 0;
  final Map<String, double> _values = {};

  @override
  Widget build(BuildContext context) {
    final list = [
      for (final (i, f) in _formulas.indexed)
        if (_q.isEmpty || f.$1.toLowerCase().contains(_q.toLowerCase()) || f.$2.toLowerCase().contains(_q.toLowerCase())) (i, f),
    ];
    final (name, eq, vars, fn) = _formulas[_open];
    final values = [for (final v in vars) _values['$_open$v'] ?? 1];
    final out = fn(values);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          decoration: const InputDecoration(prefixIcon: Icon(Icons.search)),
          onChanged: (v) => setState(() => _q = v),
        ),
        Wrap(
          spacing: AppSpacing.xs,
          children: [for (final (i, f) in list) ChoiceChip(label: Text(f.$1), selected: _open == i, onSelected: (_) => setState(() => _open = i))],
        ),
        const SizedBox(height: AppSpacing.sm),
        Text('$name: $eq', style: Theme.of(context).textTheme.titleSmall),
        for (final (k, v) in vars.indexed) _Slider(v, values[k], 0, 100, (x) => setState(() => _values['$_open$v'] = x), divisions: 200),
        _result(context, out.isNaN ? '—' : '= ${out.toStringAsFixed(3)}', 'lab.formula'),
      ],
    );
  }
}

/// Small expression evaluator for the calculator: + − × ÷ ^, parentheses, sin cos tan √ log ln, π.
double evaluateExpression(String input, {bool degrees = true}) {
  final s = input.replaceAll(' ', '').replaceAll('×', '*').replaceAll('÷', '/').replaceAll('π', '(${math.pi})').replaceAll('√', 'sqrt');
  var i = 0;
  late double Function() expr;
  double number() {
    final start = i;
    while (i < s.length && (RegExp(r'[0-9.]').hasMatch(s[i]))) {
      i++;
    }
    if (start == i) throw const FormatException('number');
    return double.parse(s.substring(start, i));
  }

  double factor() {
    if (i < s.length && s[i] == '-') {
      i++;
      return -factor();
    }
    for (final fn in const ['sqrt', 'sin', 'cos', 'tan', 'log', 'ln']) {
      if (s.startsWith(fn, i)) {
        i += fn.length;
        final v = factor();
        final r = degrees ? v * math.pi / 180 : v;
        return switch (fn) {
          'sqrt' => math.sqrt(v),
          'sin' => math.sin(r),
          'cos' => math.cos(r),
          'tan' => math.tan(r),
          'log' => math.log(v) / math.ln10,
          _ => math.log(v),
        };
      }
    }
    double base;
    if (i < s.length && s[i] == '(') {
      i++;
      base = expr();
      if (i >= s.length || s[i] != ')') throw const FormatException(')');
      i++;
    } else {
      base = number();
    }
    if (i < s.length && s[i] == '^') {
      i++;
      return math.pow(base, factor()).toDouble();
    }
    return base;
  }

  double term() {
    var v = factor();
    while (i < s.length && (s[i] == '*' || s[i] == '/')) {
      final op = s[i++];
      final r = factor();
      v = op == '*' ? v * r : v / r;
    }
    return v;
  }

  expr = () {
    var v = term();
    while (i < s.length && (s[i] == '+' || s[i] == '-')) {
      final op = s[i++];
      final r = term();
      v = op == '+' ? v + r : v - r;
    }
    return v;
  };
  final v = expr();
  if (i != s.length) throw const FormatException('trailing');
  return v;
}

class CalculatorLab extends StatefulWidget {
  const CalculatorLab({super.key});

  @override
  State<CalculatorLab> createState() => _CalculatorLabState();
}

class _CalculatorLabState extends State<CalculatorLab> {
  String _expr = '';
  String _out = '';
  bool _deg = true;

  void _press(String k) => setState(() {
    if (k == 'C') {
      _expr = '';
      _out = '';
    } else if (k == '⌫') {
      if (_expr.isNotEmpty) _expr = _expr.substring(0, _expr.length - 1);
    } else if (k == '=') {
      try {
        final v = evaluateExpression(_expr, degrees: _deg);
        _out = v.isNaN || v.isInfinite ? 'Error' : (v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(6).replaceAll(RegExp(r'0+$'), ''));
      } on Object {
        _out = 'Error';
      }
    } else {
      _expr += ['sin', 'cos', 'tan', 'log', 'ln', '√'].contains(k) ? '$k(' : k;
    }
  });

  @override
  Widget build(BuildContext context) {
    const keys = ['sin', 'cos', 'tan', '√', 'log', 'ln', '(', ')', '^', 'π', '7', '8', '9', '÷', 'C', '4', '5', '6', '×', '⌫', '1', '2', '3', '-', '=', '0', '.', '+'];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(color: Theme.of(context).colorScheme.surfaceContainerHighest, borderRadius: BorderRadius.circular(8)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(_expr.isEmpty ? '0' : _expr, key: const Key('calc.expr')),
              Text(_out, key: const Key('calc.out'), style: Theme.of(context).textTheme.headlineSmall),
            ],
          ),
        ),
        SwitchListTile(contentPadding: EdgeInsets.zero, title: Text(_deg ? 'DEG' : 'RAD'), value: _deg, onChanged: (v) => setState(() => _deg = v)),
        GridView.count(
          crossAxisCount: 5,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: 1.4,
          mainAxisSpacing: 4,
          crossAxisSpacing: 4,
          children: [
            for (final k in keys)
              FilledButton.tonal(
                key: Key('calc.$k'),
                style: FilledButton.styleFrom(padding: EdgeInsets.zero),
                onPressed: () => _press(k),
                child: Text(k),
              ),
          ],
        ),
      ],
    );
  }
}
