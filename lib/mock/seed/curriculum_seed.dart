// Curriculum fixtures: subject/chapter structure modelled on the NCTB SSC & HSC syllabi.
// Chapter titles describe syllabus structure only; no textbook text is reproduced.
import 'package:material_ui/material_ui.dart';

import '../../core/l10n/tr.dart';
import '../../features/curriculum/domain/curriculum_models.dart';

const curriculumVersions = [
  CurriculumVersion(
    id: 'nctb-2025',
    name: Tr('জাতীয় শিক্ষাক্রম (পরিমার্জিত) ২০২৫', 'National Curriculum (revised) 2025'),
    year: 2025,
    isCurrent: true,
  ),
  CurriculumVersion(
    id: 'nctb-2013',
    name: Tr('জাতীয় শিক্ষাক্রম ২০১২ (পুরনো)', 'National Curriculum 2012 (previous)'),
    year: 2013,
    note: Tr('পুরনো সিলেবাস — কিছু অধ্যায় পরিবর্তিত হয়েছে', 'Previous syllabus — some chapters changed'),
  ),
];

const educationBoards = [
  EducationBoard('dhaka', Tr('ঢাকা', 'Dhaka')),
  EducationBoard('chattogram', Tr('চট্টগ্রাম', 'Chattogram')),
  EducationBoard('rajshahi', Tr('রাজশাহী', 'Rajshahi')),
  EducationBoard('cumilla', Tr('কুমিল্লা', 'Cumilla')),
  EducationBoard('jashore', Tr('যশোর', 'Jashore')),
  EducationBoard('barishal', Tr('বরিশাল', 'Barishal')),
  EducationBoard('sylhet', Tr('সিলেট', 'Sylhet')),
  EducationBoard('dinajpur', Tr('দিনাজপুর', 'Dinajpur')),
  EducationBoard('mymensingh', Tr('ময়মনসিংহ', 'Mymensingh')),
];

/// Topic spec: Bangla title, English title, outcome (bn), outcome (en).
typedef _T = (String, String, String, String);

class _C {
  const _C(this.n, this.bn, this.en, this.topics, {this.paper = 1, this.mins = 240, this.d = 2, this.r = 2, this.lab = false});

  final int n;
  final String bn;
  final String en;
  final List<_T> topics;
  final int paper;
  final int mins;
  final int d;
  final int r;
  final bool lab;
}

Subject _subject({
  required String id,
  required String code,
  required EducationLevel level,
  required String bn,
  required String en,
  required List<AcademicGroup> groups,
  required Color color,
  required IconData icon,
  required String descBn,
  required String descEn,
  required List<_C> chapters,
  int papers = 1,
  bool optional = false,
  bool compulsory = false,
}) {
  final built = <Chapter>[];
  for (final c in chapters) {
    final chapterId = '$id-p${c.paper}-c${c.n}';
    final topics = <Topic>[
      for (var i = 0; i < c.topics.length; i++)
        Topic(
          id: '$chapterId-t${i + 1}',
          chapterId: chapterId,
          number: i + 1,
          title: Tr(c.topics[i].$1, c.topics[i].$2),
          minutes: (c.mins / c.topics.length).round(),
          outcomes: [LearningOutcome(id: '$chapterId-t${i + 1}-o1', text: Tr(c.topics[i].$3, c.topics[i].$4))],
        ),
    ];
    final topicListBn = c.topics.map((t) => t.$1).join(', ');
    final topicListEn = c.topics.map((t) => t.$2).join(', ');
    final previous = built.where((b) => b.paper == c.paper).lastOrNull;
    built.add(
      Chapter(
        id: chapterId,
        subjectId: id,
        number: c.n,
        paper: c.paper,
        title: Tr(c.bn, c.en),
        description: Tr(
          'এই অধ্যায়ে তুমি শিখবে: $topicListBn। প্রতিটি টপিকের সাথে উদাহরণ, অনুশীলনী ও বোর্ড-ধাঁচের প্রশ্ন রয়েছে।',
          'In this chapter you will learn: $topicListEn. Each topic has worked examples, practice and board-style questions.',
        ),
        topics: topics,
        minutes: c.mins,
        difficulty: Difficulty.fromRank(c.d),
        relevance: ExamRelevance.values[3 - c.r.clamp(1, 3)],
        prerequisiteIds: previous == null ? const [] : [previous.id],
        hasLab: c.lab,
      ),
    );
  }
  return Subject(
    id: id,
    code: code,
    level: level,
    name: Tr(bn, en),
    groups: groups,
    color: color,
    icon: icon,
    chapters: built,
    description: Tr(descBn, descEn),
    papers: papers,
    optional: optional,
    compulsory: compulsory,
  );
}

const _sci = [AcademicGroup.science];
const _bus = [AcademicGroup.business];
const _hum = [AcademicGroup.humanities];
const _all = AcademicGroup.values;

const _physics = Color(0xFF2F7BE0);
const _chem = Color(0xFF1AA3A3);
const _bio = Color(0xFF2E9D57);
const _math = Color(0xFF8A4FD8);
const _bangla = Color(0xFFD64575);
const _english = Color(0xFFE07A2F);
const _ict = Color(0xFF5C6BC0);
const _commerce = Color(0xFFB08A12);
const _humanities = Color(0xFF8D6E63);

final List<Subject> seedSubjects = [
  // ───────────────────────────── SSC ─────────────────────────────
  _subject(
    id: 'ssc-phy', code: '136', level: EducationLevel.ssc, bn: 'পদার্থবিজ্ঞান', en: 'Physics',
    groups: _sci, color: _physics, icon: Icons.bolt_outlined,
    descBn: 'গতি, বল, শক্তি, তরঙ্গ, আলো ও বিদ্যুতের মৌলিক ধারণা।',
    descEn: 'Foundations of motion, force, energy, waves, light and electricity.',
    chapters: const [
      _C(1, 'ভৌত রাশি ও পরিমাপ', 'Physical Quantities and Measurement', [
        ('মৌলিক ও লব্ধ রাশি', 'Fundamental and derived quantities', 'মৌলিক ও লব্ধ রাশির পার্থক্য ব্যাখ্যা করতে পারবে', 'Distinguish fundamental and derived quantities'),
        ('এককের আন্তর্জাতিক পদ্ধতি (SI)', 'The SI system of units', 'SI একক ও মাত্রা লিখতে পারবে', 'Write SI units and dimensions'),
        ('পরিমাপের ত্রুটি', 'Errors in measurement', 'যান্ত্রিক ও ব্যক্তিগত ত্রুটি চিহ্নিত করতে পারবে', 'Identify instrumental and personal errors'),
      ], mins: 180, d: 1, r: 2),
      _C(2, 'গতি', 'Motion', [
        ('দূরত্ব ও সরণ', 'Distance and displacement', 'স্কেলার ও ভেক্টর রাশির পার্থক্য করতে পারবে', 'Differentiate scalar and vector quantities'),
        ('বেগ ও ত্বরণ', 'Velocity and acceleration', 'বেগ ও ত্বরণ গণনা করতে পারবে', 'Calculate velocity and acceleration'),
        ('গতির সমীকরণ', 'Equations of motion', r'v = u + at সহ গতির সমীকরণ প্রয়োগ করতে পারবে', r'Apply the equations of motion including v = u + at'),
        ('মুক্তভাবে পড়ন্ত বস্তু', 'Free fall', 'অভিকর্ষজ ত্বরণে পড়ন্ত বস্তুর গতি বিশ্লেষণ করতে পারবে', 'Analyse free fall under gravity'),
      ], mins: 300, d: 2, r: 3),
      _C(3, 'বল', 'Force', [
        ('নিউটনের গতিসূত্র', "Newton's laws of motion", 'নিউটনের তিনটি সূত্র ব্যাখ্যা করতে পারবে', "Explain Newton's three laws"),
        ('ভরবেগ ও এর সংরক্ষণ', 'Momentum and its conservation', 'ভরবেগের সংরক্ষণ সূত্র প্রয়োগ করতে পারবে', 'Apply conservation of momentum'),
        ('ঘর্ষণ', 'Friction', 'ঘর্ষণের সুবিধা-অসুবিধা বর্ণনা করতে পারবে', 'Describe advantages and drawbacks of friction'),
      ], mins: 300, d: 2, r: 3, lab: true),
      _C(4, 'কাজ, ক্ষমতা ও শক্তি', 'Work, Power and Energy', [
        ('কাজ', 'Work', 'বল ও সরণের সাহায্যে কাজ নির্ণয় করতে পারবে', 'Calculate work from force and displacement'),
        ('গতিশক্তি ও বিভবশক্তি', 'Kinetic and potential energy', 'শক্তির রূপান্তর ব্যাখ্যা করতে পারবে', 'Explain energy transformation'),
        ('ক্ষমতা ও কর্মদক্ষতা', 'Power and efficiency', 'ক্ষমতা ও কর্মদক্ষতা হিসাব করতে পারবে', 'Calculate power and efficiency'),
      ], mins: 270, d: 2, r: 3, lab: true),
      _C(7, 'তরঙ্গ ও শব্দ', 'Waves and Sound', [
        ('তরঙ্গের প্রকারভেদ', 'Types of waves', 'অনুপ্রস্থ ও অনুদৈর্ঘ্য তরঙ্গের পার্থক্য করতে পারবে', 'Differentiate transverse and longitudinal waves'),
        ('তরঙ্গের বৈশিষ্ট্য', 'Wave properties', r'v = f\lambda সম্পর্ক প্রয়োগ করতে পারবে', r'Apply v = f\lambda'),
        ('প্রতিধ্বনি', 'Echo', 'প্রতিধ্বনির শর্ত ব্যাখ্যা করতে পারবে', 'Explain conditions for an echo'),
      ], mins: 240, d: 2, r: 2, lab: true),
      _C(9, 'আলোর প্রতিসরণ', 'Refraction of Light', [
        ('প্রতিসরণের সূত্র', 'Laws of refraction', 'স্নেলের সূত্র ব্যবহার করতে পারবে', "Use Snell's law"),
        ('পূর্ণ অভ্যন্তরীণ প্রতিফলন', 'Total internal reflection', 'সংকট কোণ ব্যাখ্যা করতে পারবে', 'Explain the critical angle'),
        ('লেন্স', 'Lenses', 'উত্তল ও অবতল লেন্সে প্রতিবিম্ব আঁকতে পারবে', 'Draw images formed by lenses'),
      ], mins: 270, d: 3, r: 2),
      _C(11, 'চল তড়িৎ', 'Current Electricity', [
        ('তড়িৎ প্রবাহ ও বিভব পার্থক্য', 'Current and potential difference', 'তড়িৎ প্রবাহের একক ব্যাখ্যা করতে পারবে', 'Explain the unit of current'),
        ('ওহমের সূত্র', "Ohm's law", 'V = IR ব্যবহার করে গণনা করতে পারবে', 'Calculate with V = IR'),
        ('রোধের সন্নিবেশ', 'Resistors in series and parallel', 'শ্রেণি ও সমান্তরাল রোধ নির্ণয় করতে পারবে', 'Find series and parallel resistance'),
        ('তড়িৎ শক্তি ও বিল', 'Electrical energy and bills', 'বিদ্যুৎ বিল হিসাব করতে পারবে', 'Calculate an electricity bill'),
      ], mins: 300, d: 3, r: 3, lab: true),
    ],
  ),
  _subject(
    id: 'ssc-chem', code: '137', level: EducationLevel.ssc, bn: 'রসায়ন', en: 'Chemistry',
    groups: _sci, color: _chem, icon: Icons.science_outlined,
    descBn: 'পদার্থের গঠন, পর্যায় সারণি, বন্ধন, মোল ও বিক্রিয়া।',
    descEn: 'Structure of matter, periodic table, bonding, the mole and reactions.',
    chapters: const [
      _C(3, 'পদার্থের গঠন', 'Structure of Matter', [
        ('পরমাণুর মৌলিক কণা', 'Fundamental particles of the atom', 'ইলেকট্রন, প্রোটন ও নিউট্রনের বৈশিষ্ট্য লিখতে পারবে', 'Describe electrons, protons and neutrons'),
        ('পারমাণবিক সংখ্যা ও ভরসংখ্যা', 'Atomic number and mass number', 'আইসোটোপ শনাক্ত করতে পারবে', 'Identify isotopes'),
        ('ইলেকট্রন বিন্যাস', 'Electron configuration', 'প্রথম ২০টি মৌলের ইলেকট্রন বিন্যাস লিখতে পারবে', 'Write configurations of the first 20 elements'),
      ], mins: 240, d: 2, r: 3, lab: true),
      _C(4, 'পর্যায় সারণি', 'Periodic Table', [
        ('পর্যায় ও গ্রুপ', 'Periods and groups', 'ইলেকট্রন বিন্যাস থেকে অবস্থান নির্ণয় করতে পারবে', 'Locate an element from its configuration'),
        ('পর্যায়বৃত্ত ধর্ম', 'Periodic properties', 'পারমাণবিক আকার ও তড়িৎ ঋণাত্মকতার ধারা ব্যাখ্যা করতে পারবে', 'Explain trends in atomic size and electronegativity'),
      ], mins: 210, d: 2, r: 2, lab: true),
      _C(5, 'রাসায়নিক বন্ধন', 'Chemical Bonds', [
        ('আয়নিক বন্ধন', 'Ionic bonds', 'আয়নিক যৌগ গঠন ব্যাখ্যা করতে পারবে', 'Explain formation of ionic compounds'),
        ('সমযোজী বন্ধন', 'Covalent bonds', 'ডট-ক্রস চিত্র আঁকতে পারবে', 'Draw dot-and-cross diagrams'),
        ('ধাতব বন্ধন', 'Metallic bonds', 'ধাতুর পরিবাহিতা ব্যাখ্যা করতে পারবে', 'Explain conductivity of metals'),
      ], mins: 240, d: 3, r: 3, lab: true),
      _C(6, 'মোলের ধারণা ও রাসায়নিক গণনা', 'Mole Concept and Chemical Calculations', [
        ('মোল ও অ্যাভোগেড্রো সংখ্যা', "The mole and Avogadro's number", 'মোল সংখ্যা ও কণার সংখ্যা নির্ণয় করতে পারবে', 'Convert between moles and particles'),
        ('আণবিক ভর', 'Molecular mass', 'যৌগের আণবিক ভর হিসাব করতে পারবে', 'Calculate molecular mass'),
        ('দ্রবণের ঘনমাত্রা', 'Concentration of solutions', 'মোলারিটি নির্ণয় করতে পারবে', 'Calculate molarity'),
      ], mins: 300, d: 3, r: 3),
      _C(7, 'রাসায়নিক বিক্রিয়া', 'Chemical Reactions', [
        ('বিক্রিয়ার প্রকারভেদ', 'Types of reactions', 'বিক্রিয়ার ধরন শনাক্ত করতে পারবে', 'Classify reactions'),
        ('জারণ-বিজারণ', 'Oxidation and reduction', 'জারক ও বিজারক চিহ্নিত করতে পারবে', 'Identify oxidising and reducing agents'),
        ('সমীকরণ সমতাকরণ', 'Balancing equations', 'রাসায়নিক সমীকরণ সমতা করতে পারবে', 'Balance chemical equations'),
      ], mins: 270, d: 2, r: 3),
    ],
  ),
  _subject(
    id: 'ssc-bio', code: '138', level: EducationLevel.ssc, bn: 'জীববিজ্ঞান', en: 'Biology',
    groups: _sci, color: _bio, icon: Icons.eco_outlined,
    descBn: 'কোষ, বিভাজন, সালোকসংশ্লেষণ, পুষ্টি ও পরিবহন।',
    descEn: 'Cells, division, photosynthesis, nutrition and transport.',
    chapters: const [
      _C(2, 'জীবকোষ ও টিস্যু', 'Cell and Tissue', [
        ('উদ্ভিদ ও প্রাণীকোষ', 'Plant and animal cells', 'উদ্ভিদ ও প্রাণীকোষের পার্থক্য লিখতে পারবে', 'Compare plant and animal cells'),
        ('কোষ অঙ্গাণু', 'Cell organelles', 'মাইটোকন্ড্রিয়া ও ক্লোরোপ্লাস্টের কাজ বর্ণনা করতে পারবে', 'Describe mitochondria and chloroplasts'),
        ('টিস্যু', 'Tissues', 'ভাজক ও স্থায়ী টিস্যু শনাক্ত করতে পারবে', 'Identify meristematic and permanent tissue'),
      ], mins: 240, d: 1, r: 3, lab: true),
      _C(3, 'কোষ বিভাজন', 'Cell Division', [
        ('মাইটোসিস', 'Mitosis', 'মাইটোসিসের ধাপগুলো বর্ণনা করতে পারবে', 'Describe the stages of mitosis'),
        ('মিয়োসিস', 'Meiosis', 'মাইটোসিস ও মিয়োসিসের পার্থক্য করতে পারবে', 'Compare mitosis and meiosis'),
      ], mins: 210, d: 2, r: 3),
      _C(4, 'জীবনীশক্তি', 'Bioenergetics', [
        ('সালোকসংশ্লেষণ', 'Photosynthesis', 'সালোকসংশ্লেষণের সমীকরণ লিখতে পারবে', 'Write the equation of photosynthesis'),
        ('শ্বসন', 'Respiration', 'সবাত ও অবাত শ্বসনের পার্থক্য করতে পারবে', 'Compare aerobic and anaerobic respiration'),
        ('ATP', 'ATP', 'ATP-কে শক্তির মুদ্রা হিসেবে ব্যাখ্যা করতে পারবে', 'Explain ATP as the energy currency'),
      ], mins: 270, d: 2, r: 3, lab: true),
      _C(5, 'খাদ্য, পুষ্টি এবং পরিপাক', 'Food, Nutrition and Digestion', [
        ('খাদ্য উপাদান', 'Food components', 'খাদ্যের ছয়টি উপাদান বর্ণনা করতে পারবে', 'Describe the six food components'),
        ('মানব পরিপাকতন্ত্র', 'Human digestive system', 'পরিপাকতন্ত্রের অংশগুলো চিহ্নিত করতে পারবে', 'Label the digestive system'),
      ], mins: 210, d: 1, r: 2),
      _C(6, 'জীবে পরিবহন', 'Transport in Organisms', [
        ('উদ্ভিদে পানি পরিবহন', 'Water transport in plants', 'প্রস্বেদন ব্যাখ্যা করতে পারবে', 'Explain transpiration'),
        ('রক্ত ও রক্ত সংবহনতন্ত্র', 'Blood and circulation', 'হৃৎপিণ্ডের গঠন বর্ণনা করতে পারবে', 'Describe the structure of the heart'),
      ], mins: 240, d: 2, r: 3),
    ],
  ),
  _subject(
    id: 'ssc-hmath', code: '126', level: EducationLevel.ssc, bn: 'উচ্চতর গণিত', en: 'Higher Mathematics',
    groups: _sci, color: _math, icon: Icons.functions, optional: true,
    descBn: 'সেট ও ফাংশন, বীজগণিত, ত্রিকোণমিতি, লগারিদম ও স্থানাঙ্ক জ্যামিতি।',
    descEn: 'Sets and functions, algebra, trigonometry, logarithms and coordinate geometry.',
    chapters: const [
      _C(1, 'সেট ও ফাংশন', 'Sets and Functions', [
        ('সেট প্রক্রিয়া', 'Set operations', 'সংযোগ, ছেদ ও পূরক সেট নির্ণয় করতে পারবে', 'Find union, intersection and complement'),
        ('ফাংশন ও এর ডোমেন-রেঞ্জ', 'Functions, domain and range', 'ফাংশনের ডোমেন ও রেঞ্জ নির্ণয় করতে পারবে', 'Find domain and range'),
      ], mins: 240, d: 2, r: 3),
      _C(3, 'জ্যামিতি', 'Geometry', [
        ('পিথাগোরাসের উপপাদ্যের বিস্তৃতি', "Extension of Pythagoras' theorem", 'স্থূলকোণী ত্রিভুজে উপপাদ্য প্রয়োগ করতে পারবে', 'Apply the theorem to obtuse triangles'),
        ('অ্যাপোলোনিয়াসের উপপাদ্য', "Apollonius' theorem", 'মধ্যমা সংক্রান্ত সমস্যা সমাধান করতে পারবে', 'Solve median problems'),
      ], mins: 240, d: 3, r: 2),
      _C(8, 'ত্রিকোণমিতি', 'Trigonometry', [
        ('রেডিয়ান পরিমাপ', 'Radian measure', 'ডিগ্রি ও রেডিয়ানে রূপান্তর করতে পারবে', 'Convert degrees and radians'),
        ('ত্রিকোণমিতিক অনুপাত ও লেখচিত্র', 'Trigonometric ratios and graphs', r'\sin x ও \cos x এর লেখচিত্র আঁকতে পারবে', r'Sketch \sin x and \cos x'),
      ], mins: 300, d: 3, r: 3),
      _C(9, 'সূচকীয় ও লগারিদমীয় ফাংশন', 'Exponential and Logarithmic Functions', [
        ('সূচকের নিয়ম', 'Laws of indices', 'সূচকের নিয়ম প্রয়োগ করতে পারবে', 'Apply index laws'),
        ('লগারিদম', 'Logarithms', 'লগারিদমের সূত্র প্রমাণ ও প্রয়োগ করতে পারবে', 'Prove and apply log laws'),
      ], mins: 240, d: 2, r: 2),
      _C(10, 'দ্বিপদী বিস্তৃতি', 'Binomial Expansion', [
        ('দ্বিপদী উপপাদ্য', 'The binomial theorem', r'(1+x)^n বিস্তৃত করতে পারবে', r'Expand (1+x)^n'),
        ('প্যাসকেলের ত্রিভুজ', "Pascal's triangle", 'প্যাসকেলের ত্রিভুজ ব্যবহার করতে পারবে', "Use Pascal's triangle"),
      ], mins: 210, d: 2, r: 3),
      _C(11, 'স্থানাঙ্ক জ্যামিতি', 'Coordinate Geometry', [
        ('দুই বিন্দুর দূরত্ব', 'Distance between two points', 'দূরত্বের সূত্র প্রয়োগ করতে পারবে', 'Apply the distance formula'),
        ('সরলরেখার ঢাল ও সমীকরণ', 'Slope and equation of a line', 'সরলরেখার সমীকরণ নির্ণয় করতে পারবে', 'Find the equation of a line'),
      ], mins: 270, d: 2, r: 3),
    ],
  ),
  _subject(
    id: 'ssc-gmath', code: '109', level: EducationLevel.ssc, bn: 'গণিত', en: 'General Mathematics',
    groups: _all, compulsory: true, color: _math, icon: Icons.calculate_outlined,
    descBn: 'বাস্তব সংখ্যা, বীজগণিত, সমীকরণ, ত্রিকোণমিতি ও পরিসংখ্যান।',
    descEn: 'Real numbers, algebra, equations, trigonometry and statistics.',
    chapters: const [
      _C(1, 'বাস্তব সংখ্যা', 'Real Numbers', [
        ('মূলদ ও অমূলদ সংখ্যা', 'Rational and irrational numbers', r'\sqrt{2} অমূলদ প্রমাণ করতে পারবে', r'Prove \sqrt{2} is irrational'),
        ('আবৃত্ত দশমিক', 'Recurring decimals', 'আবৃত্ত দশমিককে ভগ্নাংশে রূপান্তর করতে পারবে', 'Convert recurring decimals to fractions'),
      ], mins: 180, d: 1, r: 2),
      _C(3, 'বীজগাণিতিক রাশি', 'Algebraic Expressions', [
        ('বর্গ ও ঘনের সূত্র', 'Square and cube identities', r'(a+b)^2 ও (a+b)^3 সূত্র প্রয়োগ করতে পারবে', r'Apply (a+b)^2 and (a+b)^3 identities'),
        ('উৎপাদকে বিশ্লেষণ', 'Factorisation', 'রাশিকে উৎপাদকে বিশ্লেষণ করতে পারবে', 'Factorise expressions'),
      ], mins: 270, d: 2, r: 3),
      _C(6, 'সরল সহসমীকরণ', 'Simultaneous Linear Equations', [
        ('প্রতিস্থাপন ও অপনয়ন পদ্ধতি', 'Substitution and elimination', 'দুই চলকের সমীকরণ সমাধান করতে পারবে', 'Solve two-variable equations'),
        ('লেখচিত্রের সাহায্যে সমাধান', 'Graphical solution', 'লেখচিত্রে সমাধান দেখাতে পারবে', 'Show the solution on a graph'),
      ], mins: 240, d: 2, r: 3),
      _C(9, 'ত্রিকোণমিতিক অনুপাত', 'Trigonometric Ratios', [
        ('সূক্ষ্মকোণের অনুপাত', 'Ratios of acute angles', 'ছয়টি অনুপাত নির্ণয় করতে পারবে', 'Find the six ratios'),
        ('উচ্চতা ও দূরত্ব', 'Heights and distances', 'উন্নতি কোণ ব্যবহার করে উচ্চতা নির্ণয় করতে পারবে', 'Find heights using angles of elevation'),
      ], mins: 270, d: 2, r: 3),
      _C(17, 'পরিসংখ্যান', 'Statistics', [
        ('গড়, মধ্যক ও প্রচুরক', 'Mean, median and mode', 'শ্রেণিবিন্যস্ত উপাত্তের গড় নির্ণয় করতে পারবে', 'Find the mean of grouped data'),
        ('অজিভ রেখা ও আয়তলেখ', 'Ogive and histogram', 'আয়তলেখ আঁকতে পারবে', 'Draw a histogram'),
      ], mins: 210, d: 1, r: 3),
    ],
  ),
  _subject(
    id: 'ssc-bangla1', code: '101', level: EducationLevel.ssc, bn: 'বাংলা প্রথম পত্র', en: 'Bangla 1st Paper',
    groups: _all, compulsory: true, color: _bangla, icon: Icons.menu_book_outlined,
    descBn: 'গদ্য ও কবিতা পাঠ, সৃজনশীল প্রশ্নের প্রস্তুতি।',
    descEn: 'Prose and poetry, creative-question preparation.',
    chapters: const [
      _C(1, 'গদ্য: সুভা', 'Prose: Subha', [
        ('লেখক পরিচিতি ও প্রেক্ষাপট', 'Author and context', 'রবীন্দ্রনাথের ছোটগল্পের বৈশিষ্ট্য বলতে পারবে', "Describe Tagore's short-story style"),
        ('চরিত্র বিশ্লেষণ', 'Character analysis', 'সুভা চরিত্রের বৈশিষ্ট্য বিশ্লেষণ করতে পারবে', "Analyse Subha's character"),
      ], mins: 150, d: 1, r: 3),
      _C(2, 'গদ্য: বই পড়া', 'Prose: Boi Pora', [
        ('মূলভাব', 'Central idea', 'প্রবন্ধের মূলভাব লিখতে পারবে', 'Summarise the central idea'),
        ('শিক্ষা ও স্বশিক্ষা', 'Education and self-learning', 'স্বশিক্ষার গুরুত্ব ব্যাখ্যা করতে পারবে', 'Explain the value of self-learning'),
      ], mins: 150, d: 2, r: 2),
      _C(3, 'কবিতা: কপোতাক্ষ নদ', 'Poem: Kopotakkho Nod', [
        ('সনেটের গঠন', 'Structure of a sonnet', 'সনেটের বৈশিষ্ট্য চিহ্নিত করতে পারবে', 'Identify sonnet features'),
        ('স্মৃতিকাতরতা ও দেশপ্রেম', 'Nostalgia and patriotism', 'কবিতার ভাব ব্যাখ্যা করতে পারবে', 'Explain the mood of the poem'),
      ], mins: 120, d: 2, r: 3),
      _C(4, 'কবিতা: আমার পথ', 'Poem: Amar Poth', [
        ('আত্মবিশ্বাসের বাণী', 'A message of self-belief', 'কবির আত্মপ্রত্যয়ের দর্শন ব্যাখ্যা করতে পারবে', "Explain the poet's philosophy of self-belief"),
      ], mins: 120, d: 2, r: 2),
    ],
  ),
  _subject(
    id: 'ssc-eng2', code: '108', level: EducationLevel.ssc, bn: 'ইংরেজি দ্বিতীয় পত্র', en: 'English 2nd Paper',
    groups: _all, compulsory: true, color: _english, icon: Icons.translate,
    descBn: 'গ্রামার ও কম্পোজিশন — বোর্ড পরীক্ষার ধাঁচে।',
    descEn: 'Grammar and composition in the board exam pattern.',
    chapters: const [
      _C(1, 'আর্টিকেল ও প্রিপোজিশন', 'Articles and Prepositions', [
        ('আর্টিকেলের ব্যবহার', 'Use of articles', 'a, an, the সঠিকভাবে ব্যবহার করতে পারবে', 'Use a, an and the correctly'),
        ('প্রিপোজিশনের ব্যবহার', 'Use of prepositions', 'সময় ও স্থানের প্রিপোজিশন ব্যবহার করতে পারবে', 'Use prepositions of time and place'),
      ], mins: 150, d: 1, r: 3),
      _C(2, 'রাইট ফর্ম অব ভার্বস', 'Right Form of Verbs', [
        ('টেন্সের নিয়ম', 'Rules of tense', 'বাক্যে সঠিক টেন্স ব্যবহার করতে পারবে', 'Choose the correct tense'),
        ('সাবজেক্ট-ভার্ব এগ্রিমেন্ট', 'Subject-verb agreement', 'কর্তা অনুযায়ী ক্রিয়া মেলাতে পারবে', 'Match verbs with subjects'),
      ], mins: 180, d: 2, r: 3),
      _C(3, 'ন্যারেশন', 'Narration', [
        ('অ্যাসার্টিভ বাক্য', 'Assertive sentences', 'ডিরেক্ট থেকে ইনডিরেক্ট করতে পারবে', 'Change direct to indirect speech'),
        ('প্রশ্নবোধক ও অনুজ্ঞাসূচক', 'Interrogative and imperative', 'প্রশ্ন ও আদেশের ন্যারেশন পরিবর্তন করতে পারবে', 'Report questions and commands'),
      ], mins: 180, d: 2, r: 2),
      _C(4, 'ট্রান্সফরমেশন অব সেনটেন্সেস', 'Transformation of Sentences', [
        ('সিম্পল, কমপ্লেক্স, কম্পাউন্ড', 'Simple, complex, compound', 'বাক্যের গঠন পরিবর্তন করতে পারবে', 'Transform sentence structures'),
        ('ভয়েস পরিবর্তন', 'Change of voice', 'অ্যাকটিভ থেকে প্যাসিভ করতে পারবে', 'Change active to passive'),
      ], mins: 180, d: 2, r: 3),
      _C(5, 'কম্পোজিশন', 'Composition', [
        ('প্যারাগ্রাফ', 'Paragraph writing', 'সুসংগঠিত প্যারাগ্রাফ লিখতে পারবে', 'Write a well-organised paragraph'),
        ('ইমেইল ও চিঠি', 'Email and letter', 'ফরমাল ইমেইল লিখতে পারবে', 'Write a formal email'),
        ('রচনা', 'Essay', 'ভূমিকা-মূল অংশ-উপসংহারসহ রচনা লিখতে পারবে', 'Write an essay with intro, body and conclusion'),
      ], mins: 240, d: 2, r: 3),
    ],
  ),
  _subject(
    id: 'ssc-ict', code: '154', level: EducationLevel.ssc, bn: 'তথ্য ও যোগাযোগ প্রযুক্তি', en: 'ICT',
    groups: _all, compulsory: true, color: _ict, icon: Icons.computer_outlined,
    descBn: 'ডিজিটাল বাংলাদেশ, কম্পিউটার নিরাপত্তা, স্প্রেডশিট ও ডেটাবেজ।',
    descEn: 'Digital Bangladesh, computer safety, spreadsheets and databases.',
    chapters: const [
      _C(1, 'তথ্য ও যোগাযোগ প্রযুক্তি এবং আমাদের বাংলাদেশ', 'ICT and Our Bangladesh', [
        ('ICT-র ধারণা', 'What is ICT', 'ICT-র উপাদান বর্ণনা করতে পারবে', 'Describe components of ICT'),
        ('ই-সেবা', 'E-services', 'সরকারি ই-সেবার উদাহরণ দিতে পারবে', 'Give examples of public e-services'),
      ], mins: 150, d: 1, r: 2),
      _C(2, 'কম্পিউটার ও কম্পিউটার ব্যবহারকারীর নিরাপত্তা', 'Computer and User Safety', [
        ('হার্ডওয়্যার ও সফটওয়্যার', 'Hardware and software', 'ইনপুট-আউটপুট ডিভাইস শনাক্ত করতে পারবে', 'Identify input/output devices'),
        ('সাইবার নিরাপত্তা', 'Cyber safety', 'নিরাপদ পাসওয়ার্ডের নিয়ম বলতে পারবে', 'State rules for safe passwords'),
      ], mins: 180, d: 1, r: 3),
      _C(5, 'ডেটাবেজের ব্যবহার', 'Using Databases', [
        ('টেবিল, রেকর্ড ও ফিল্ড', 'Tables, records and fields', 'ডেটাবেজের গঠন ব্যাখ্যা করতে পারবে', 'Explain database structure'),
        ('কুয়েরি', 'Queries', 'সাধারণ কুয়েরি তৈরি করতে পারবে', 'Create simple queries'),
      ], mins: 180, d: 2, r: 2, lab: true),
    ],
  ),
  _subject(
    id: 'ssc-acc', code: '146', level: EducationLevel.ssc, bn: 'হিসাববিজ্ঞান', en: 'Accounting',
    groups: _bus, color: _commerce, icon: Icons.receipt_long_outlined,
    descBn: 'লেনদেন, দুতরফা দাখিলা, জাবেদা, খতিয়ান ও রেওয়ামিল।',
    descEn: 'Transactions, double entry, journal, ledger and trial balance.',
    chapters: const [
      _C(1, 'হিসাববিজ্ঞান পরিচিতি', 'Introduction to Accounting', [
        ('হিসাববিজ্ঞানের উদ্দেশ্য', 'Objectives of accounting', 'হিসাববিজ্ঞানের উদ্দেশ্য বর্ণনা করতে পারবে', 'Describe the objectives of accounting'),
        ('হিসাবের ব্যবহারকারী', 'Users of accounts', 'অভ্যন্তরীণ ও বাহ্যিক ব্যবহারকারী চিহ্নিত করতে পারবে', 'Identify internal and external users'),
      ], mins: 150, d: 1, r: 2),
      _C(2, 'লেনদেন', 'Transactions', [
        ('লেনদেনের বৈশিষ্ট্য', 'Features of a transaction', 'লেনদেন ও অলেনদেন পার্থক্য করতে পারবে', 'Separate transactions from non-transactions'),
        ('হিসাব সমীকরণ', 'The accounting equation', 'সম্পদ = দায় + মালিকানাস্বত্ব প্রয়োগ করতে পারবে', 'Apply Assets = Liabilities + Equity'),
      ], mins: 210, d: 2, r: 3),
      _C(3, 'দুতরফা দাখিলা পদ্ধতি', 'Double Entry System', [
        ('ডেবিট ও ক্রেডিট', 'Debit and credit', 'ডেবিট-ক্রেডিট নির্ণয়ের নিয়ম প্রয়োগ করতে পারবে', 'Apply debit and credit rules'),
      ], mins: 180, d: 2, r: 3),
      _C(5, 'জাবেদা', 'Journal', [
        ('জাবেদা দাখিলা', 'Journal entries', 'সাধারণ জাবেদা লিখতে পারবে', 'Write general journal entries'),
        ('যৌগিক জাবেদা', 'Compound entries', 'যৌগিক জাবেদা প্রস্তুত করতে পারবে', 'Prepare compound entries'),
      ], mins: 240, d: 2, r: 3),
      _C(6, 'খতিয়ান', 'Ledger', [
        ('খতিয়ানে স্থানান্তর', 'Posting to the ledger', 'জাবেদা থেকে খতিয়ানে স্থানান্তর করতে পারবে', 'Post journal entries to the ledger'),
        ('জের নির্ণয়', 'Balancing accounts', 'হিসাবের জের নির্ণয় করতে পারবে', 'Balance an account'),
      ], mins: 240, d: 2, r: 3),
      _C(7, 'রেওয়ামিল', 'Trial Balance', [
        ('রেওয়ামিল প্রস্তুতি', 'Preparing a trial balance', 'রেওয়ামিল প্রস্তুত করতে পারবে', 'Prepare a trial balance'),
        ('ভুল সংশোধন', 'Correcting errors', 'রেওয়ামিলে প্রভাব ফেলে না এমন ভুল চিহ্নিত করতে পারবে', 'Identify errors not shown by a trial balance'),
      ], mins: 210, d: 3, r: 3),
    ],
  ),
  _subject(
    id: 'ssc-fin', code: '152', level: EducationLevel.ssc, bn: 'ফিন্যান্স ও ব্যাংকিং', en: 'Finance and Banking',
    groups: _bus, color: _commerce, icon: Icons.savings_outlined,
    descBn: 'অর্থায়ন, অর্থের সময়মূল্য, ব্যাংক ও বিমা।',
    descEn: 'Finance, time value of money, banking and insurance.',
    chapters: const [
      _C(1, 'অর্থায়নের ধারণা', 'Concept of Finance', [
        ('অর্থায়নের কার্যাবলি', 'Functions of finance', 'বিনিয়োগ, অর্থসংস্থান ও লভ্যাংশ সিদ্ধান্ত ব্যাখ্যা করতে পারবে', 'Explain investment, financing and dividend decisions'),
      ], mins: 150, d: 1, r: 2),
      _C(3, 'অর্থের সময়মূল্য', 'Time Value of Money', [
        ('ভবিষ্যৎ মূল্য', 'Future value', 'চক্রবৃদ্ধি সুদে ভবিষ্যৎ মূল্য নির্ণয় করতে পারবে', 'Compute future value with compound interest'),
        ('বর্তমান মূল্য', 'Present value', 'বর্তমান মূল্য নির্ণয় করতে পারবে', 'Compute present value'),
      ], mins: 240, d: 3, r: 3),
      _C(7, 'ব্যাংক ব্যবস্থা', 'The Banking System', [
        ('কেন্দ্রীয় ব্যাংকের কাজ', 'Functions of the central bank', 'বাংলাদেশ ব্যাংকের কাজ বর্ণনা করতে পারবে', 'Describe the functions of Bangladesh Bank'),
        ('বাণিজ্যিক ব্যাংক', 'Commercial banks', 'আমানত হিসাবের প্রকারভেদ বলতে পারবে', 'Describe types of deposit accounts'),
      ], mins: 210, d: 2, r: 3),
    ],
  ),
  _subject(
    id: 'ssc-econ', code: '141', level: EducationLevel.ssc, bn: 'অর্থনীতি', en: 'Economics',
    groups: _hum, color: _humanities, icon: Icons.trending_up,
    descBn: 'চাহিদা-যোগান, উৎপাদন ও জাতীয় আয়ের ধারণা।',
    descEn: 'Demand and supply, production and national income.',
    chapters: const [
      _C(1, 'অর্থনীতি পরিচয়', 'Introduction to Economics', [
        ('অভাব ও নির্বাচন', 'Scarcity and choice', 'সুযোগ ব্যয় ব্যাখ্যা করতে পারবে', 'Explain opportunity cost'),
      ], mins: 150, d: 1, r: 2),
      _C(3, 'চাহিদা, যোগান ও ভারসাম্য', 'Demand, Supply and Equilibrium', [
        ('চাহিদা বিধি', 'Law of demand', 'চাহিদা রেখা আঁকতে পারবে', 'Draw a demand curve'),
        ('বাজার ভারসাম্য', 'Market equilibrium', 'ভারসাম্য দাম নির্ণয় করতে পারবে', 'Find the equilibrium price'),
      ], mins: 240, d: 2, r: 3),
      _C(6, 'জাতীয় আয়', 'National Income', [
        ('GDP ও GNI', 'GDP and GNI', 'GDP ও GNI-এর পার্থক্য করতে পারবে', 'Distinguish GDP and GNI'),
      ], mins: 180, d: 2, r: 3),
    ],
  ),
  _subject(
    id: 'ssc-hist', code: '153', level: EducationLevel.ssc, bn: 'বাংলাদেশের ইতিহাস ও বিশ্বসভ্যতা', en: 'History of Bangladesh and World Civilisation',
    groups: _hum, color: _humanities, icon: Icons.account_balance,
    descBn: 'প্রাচীন সভ্যতা থেকে ভাষা আন্দোলন ও মুক্তিযুদ্ধ।',
    descEn: 'From ancient civilisations to the Language Movement and the Liberation War.',
    chapters: const [
      _C(1, 'ইতিহাস পরিচিতি', 'Introduction to History', [
        ('ইতিহাসের উপাদান', 'Sources of history', 'লিখিত ও অলিখিত উপাদান চিহ্নিত করতে পারবে', 'Identify written and unwritten sources'),
      ], mins: 120, d: 1, r: 2),
      _C(9, 'ভাষা আন্দোলন', 'The Language Movement', [
        ('১৯৫২ সালের ঘটনাপ্রবাহ', 'Events of 1952', '২১ ফেব্রুয়ারির তাৎপর্য ব্যাখ্যা করতে পারবে', 'Explain the significance of 21 February'),
      ], mins: 180, d: 2, r: 3),
      _C(11, 'মুক্তিযুদ্ধ', 'The Liberation War', [
        ('১৯৭১ সালের মুক্তিযুদ্ধ', 'The 1971 Liberation War', 'মুক্তিযুদ্ধের প্রধান ঘটনাগুলো ক্রমানুসারে লিখতে পারবে', 'Sequence the main events of 1971'),
      ], mins: 240, d: 2, r: 3),
    ],
  ),
  _subject(
    id: 'ssc-geo', code: '110', level: EducationLevel.ssc, bn: 'ভূগোল ও পরিবেশ', en: 'Geography and Environment',
    groups: _hum, color: _humanities, icon: Icons.public,
    descBn: 'সৌরজগৎ, বায়ুমণ্ডল ও বাংলাদেশের জলবায়ু।',
    descEn: 'The solar system, atmosphere and the climate of Bangladesh.',
    chapters: const [
      _C(2, 'মহাবিশ্ব ও আমাদের পৃথিবী', 'The Universe and Our Earth', [
        ('সৌরজগৎ', 'The solar system', 'গ্রহগুলোর বৈশিষ্ট্য তুলনা করতে পারবে', 'Compare the planets'),
      ], mins: 150, d: 1, r: 2),
      _C(6, 'বায়ুমণ্ডল', 'The Atmosphere', [
        ('বায়ুমণ্ডলের স্তর', 'Layers of the atmosphere', 'বায়ুমণ্ডলের স্তরগুলো বর্ণনা করতে পারবে', 'Describe atmospheric layers'),
      ], mins: 180, d: 2, r: 3),
    ],
  ),

  // ───────────────────────────── HSC ─────────────────────────────
  _subject(
    id: 'hsc-phy', code: '174', level: EducationLevel.hsc, bn: 'পদার্থবিজ্ঞান', en: 'Physics',
    groups: _sci, color: _physics, icon: Icons.bolt_outlined, papers: 2,
    descBn: 'ভেক্টর, গতিবিদ্যা, নিউটনীয় বলবিদ্যা, মহাকর্ষ, তাপগতিবিদ্যা ও তড়িৎ।',
    descEn: 'Vectors, dynamics, Newtonian mechanics, gravitation, thermodynamics and electricity.',
    chapters: const [
      _C(2, 'ভেক্টর', 'Vectors', [
        ('ভেক্টরের যোগ', 'Vector addition', 'ত্রিভুজ ও সামান্তরিক সূত্র প্রয়োগ করতে পারবে', 'Apply triangle and parallelogram laws'),
        ('ডট ও ক্রস গুণন', 'Dot and cross products', 'স্কেলার ও ভেক্টর গুণফল নির্ণয় করতে পারবে', 'Compute scalar and vector products'),
      ], mins: 300, d: 3, r: 3),
      _C(3, 'গতিবিদ্যা', 'Dynamics', [
        ('প্রাসের গতি', 'Projectile motion', 'প্রাসের সর্বোচ্চ উচ্চতা ও পাল্লা নির্ণয় করতে পারবে', 'Find maximum height and range'),
        ('বৃত্তীয় গতি', 'Circular motion', 'কেন্দ্রমুখী ত্বরণ নির্ণয় করতে পারবে', 'Find centripetal acceleration'),
      ], mins: 330, d: 3, r: 3),
      _C(4, 'নিউটনিয়ান বলবিদ্যা', 'Newtonian Mechanics', [
        ('জড়তার ভ্রামক', 'Moment of inertia', 'জড়তার ভ্রামক ব্যাখ্যা করতে পারবে', 'Explain moment of inertia'),
        ('কৌণিক ভরবেগ', 'Angular momentum', 'কৌণিক ভরবেগের সংরক্ষণ প্রয়োগ করতে পারবে', 'Apply conservation of angular momentum'),
      ], mins: 360, d: 3, r: 3),
      _C(6, 'মহাকর্ষ ও অভিকর্ষ', 'Gravitation', [
        ('নিউটনের মহাকর্ষ সূত্র', "Newton's law of gravitation", 'মহাকর্ষ বল নির্ণয় করতে পারবে', 'Calculate gravitational force'),
        ('মুক্তিবেগ', 'Escape velocity', 'মুক্তিবেগের রাশিমালা প্রতিপাদন করতে পারবে', 'Derive escape velocity'),
      ], mins: 300, d: 3, r: 3),
      _C(1, 'তাপগতিবিদ্যা', 'Thermodynamics', [
        ('তাপগতিবিদ্যার প্রথম সূত্র', 'First law of thermodynamics', 'অভ্যন্তরীণ শক্তির পরিবর্তন নির্ণয় করতে পারবে', 'Find change in internal energy'),
        ('এনট্রপি', 'Entropy', 'এনট্রপির ধারণা ব্যাখ্যা করতে পারবে', 'Explain entropy'),
      ], paper: 2, mins: 330, d: 3, r: 3),
      _C(3, 'চল তড়িৎ', 'Current Electricity', [
        ('কার্শফের সূত্র', "Kirchhoff's laws", 'কার্শফের সূত্র দিয়ে বর্তনী বিশ্লেষণ করতে পারবে', "Analyse circuits with Kirchhoff's laws"),
        ('হুইটস্টোন ব্রিজ', 'Wheatstone bridge', 'অজানা রোধ নির্ণয় করতে পারবে', 'Find an unknown resistance'),
      ], paper: 2, mins: 300, d: 3, r: 3, lab: true),
    ],
  ),
  _subject(
    id: 'hsc-chem', code: '176', level: EducationLevel.hsc, bn: 'রসায়ন', en: 'Chemistry',
    groups: _sci, color: _chem, icon: Icons.science_outlined, papers: 2,
    descBn: 'গুণগত রসায়ন, পর্যায়বৃত্ত ধর্ম, জৈব ও পরিমাণগত রসায়ন।',
    descEn: 'Qualitative chemistry, periodic properties, organic and quantitative chemistry.',
    chapters: const [
      _C(2, 'গুণগত রসায়ন', 'Qualitative Chemistry', [
        ('কোয়ান্টাম সংখ্যা', 'Quantum numbers', 'চারটি কোয়ান্টাম সংখ্যা ব্যাখ্যা করতে পারবে', 'Explain the four quantum numbers'),
        ('দ্রাব্যতা গুণফল', 'Solubility product', 'Ksp থেকে দ্রাব্যতা নির্ণয় করতে পারবে', 'Find solubility from Ksp'),
      ], mins: 330, d: 3, r: 3, lab: true),
      _C(3, 'মৌলের পর্যায়বৃত্ত ধর্ম ও রাসায়নিক বন্ধন', 'Periodic Properties and Chemical Bonding', [
        ('সংকরণ', 'Hybridisation', 'অণুর আকৃতি সংকরণ দিয়ে ব্যাখ্যা করতে পারবে', 'Explain molecular shape via hybridisation'),
      ], mins: 300, d: 3, r: 3),
      _C(2, 'জৈব রসায়ন', 'Organic Chemistry', [
        ('কার্যকরী মূলক', 'Functional groups', 'কার্যকরী মূলক শনাক্ত করতে পারবে', 'Identify functional groups'),
        ('সমাণুতা', 'Isomerism', 'গাঠনিক সমাণু আঁকতে পারবে', 'Draw structural isomers'),
      ], paper: 2, mins: 360, d: 3, r: 3),
      _C(3, 'পরিমাণগত রসায়ন', 'Quantitative Chemistry', [
        ('টাইট্রেশন', 'Titration', 'টাইট্রেশনের উপাত্ত থেকে ঘনমাত্রা নির্ণয় করতে পারবে', 'Find concentration from titration data'),
      ], paper: 2, mins: 270, d: 3, r: 3, lab: true),
    ],
  ),
  _subject(
    id: 'hsc-bio', code: '178', level: EducationLevel.hsc, bn: 'জীববিজ্ঞান', en: 'Biology',
    groups: _sci, color: _bio, icon: Icons.eco_outlined, papers: 2,
    descBn: 'উদ্ভিদবিজ্ঞান ও প্রাণিবিজ্ঞান — কোষ থেকে মানব শারীরতত্ত্ব।',
    descEn: 'Botany and zoology — from the cell to human physiology.',
    chapters: const [
      _C(1, 'কোষ ও এর গঠন', 'The Cell and Its Structure', [
        ('কোষপ্রাচীর ও কোষঝিল্লি', 'Cell wall and membrane', 'ফ্লুইড মোজাইক মডেল ব্যাখ্যা করতে পারবে', 'Explain the fluid mosaic model'),
        ('নিউক্লিক এসিড', 'Nucleic acids', 'DNA ও RNA-র পার্থক্য করতে পারবে', 'Compare DNA and RNA'),
      ], mins: 300, d: 2, r: 3, lab: true),
      _C(5, 'অণুজীব', 'Microorganisms', [
        ('ভাইরাস', 'Viruses', 'ভাইরাসের গঠন বর্ণনা করতে পারবে', 'Describe virus structure'),
        ('ব্যাকটেরিয়া', 'Bacteria', 'ব্যাকটেরিয়ার উপকারিতা ও অপকারিতা বলতে পারবে', 'Describe benefits and harms of bacteria'),
      ], mins: 270, d: 2, r: 3),
      _C(4, 'মানব শারীরতত্ত্ব: রক্ত ও সঞ্চালন', 'Human Physiology: Blood and Circulation', [
        ('রক্তের উপাদান', 'Components of blood', 'রক্তকণিকার কাজ বর্ণনা করতে পারবে', 'Describe blood cells'),
        ('হৃদচক্র', 'The cardiac cycle', 'হৃদচক্রের ধাপ ব্যাখ্যা করতে পারবে', 'Explain the cardiac cycle'),
      ], paper: 2, mins: 300, d: 3, r: 3),
    ],
  ),
  _subject(
    id: 'hsc-hmath', code: '265', level: EducationLevel.hsc, bn: 'উচ্চতর গণিত', en: 'Higher Mathematics',
    groups: _sci, color: _math, icon: Icons.functions, papers: 2, optional: true,
    descBn: 'ম্যাট্রিক্স, সরলরেখা, বৃত্ত, অন্তরীকরণ ও যোগজীকরণ।',
    descEn: 'Matrices, straight lines, circles, differentiation and integration.',
    chapters: const [
      _C(1, 'ম্যাট্রিক্স ও নির্ণায়ক', 'Matrices and Determinants', [
        ('ম্যাট্রিক্সের গুণন', 'Matrix multiplication', 'দুটি ম্যাট্রিক্স গুণ করতে পারবে', 'Multiply two matrices'),
        ('বিপরীত ম্যাট্রিক্স', 'Inverse matrix', 'বিপরীত ম্যাট্রিক্স নির্ণয় করতে পারবে', 'Find an inverse matrix'),
      ], mins: 330, d: 3, r: 3),
      _C(3, 'সরলরেখা', 'Straight Lines', [
        ('রেখার সমীকরণ', 'Equation of a line', 'বিভিন্ন আকারে রেখার সমীকরণ লিখতে পারবে', 'Write line equations in several forms'),
      ], mins: 300, d: 2, r: 3),
      _C(4, 'বৃত্ত', 'Circles', [
        ('বৃত্তের সমীকরণ', 'Equation of a circle', 'কেন্দ্র ও ব্যাসার্ধ নির্ণয় করতে পারবে', 'Find centre and radius'),
      ], mins: 270, d: 3, r: 3),
      _C(9, 'অন্তরীকরণ', 'Differentiation', [
        ('অন্তরীকরণের নিয়ম', 'Rules of differentiation', 'গুণ ও ভাগের নিয়ম প্রয়োগ করতে পারবে', 'Apply product and quotient rules'),
        ('সর্বোচ্চ ও সর্বনিম্ন মান', 'Maxima and minima', 'চরম মান নির্ণয় করতে পারবে', 'Find extreme values'),
      ], mins: 360, d: 3, r: 3),
      _C(10, 'যোগজীকরণ', 'Integration', [
        ('অনির্দিষ্ট যোগজ', 'Indefinite integrals', 'আদর্শ যোগজ নির্ণয় করতে পারবে', 'Evaluate standard integrals'),
        ('নির্দিষ্ট যোগজ ও ক্ষেত্রফল', 'Definite integrals and area', 'বক্ররেখার নিচের ক্ষেত্রফল নির্ণয় করতে পারবে', 'Find the area under a curve'),
      ], mins: 360, d: 3, r: 3),
    ],
  ),
  _subject(
    id: 'hsc-ict', code: '275', level: EducationLevel.hsc, bn: 'তথ্য ও যোগাযোগ প্রযুক্তি', en: 'ICT',
    groups: _all, compulsory: true, color: _ict, icon: Icons.computer_outlined,
    descBn: 'নেটওয়ার্কিং, সংখ্যা পদ্ধতি, HTML, প্রোগ্রামিং ও ডেটাবেজ।',
    descEn: 'Networking, number systems, HTML, programming and databases.',
    chapters: const [
      _C(1, 'তথ্য ও যোগাযোগ প্রযুক্তি: বিশ্ব ও বাংলাদেশ প্রেক্ষিত', 'ICT: Global and Bangladesh Perspective', [
        ('ভার্চুয়াল রিয়েলিটি ও AI', 'Virtual reality and AI', 'উদীয়মান প্রযুক্তির প্রয়োগ বর্ণনা করতে পারবে', 'Describe uses of emerging technology'),
      ], mins: 240, d: 1, r: 3),
      _C(2, 'কমিউনিকেশন সিস্টেমস ও নেটওয়ার্কিং', 'Communication Systems and Networking', [
        ('ডেটা ট্রান্সমিশন মোড', 'Data transmission modes', 'সিমপ্লেক্স, হাফ ও ফুল ডুপ্লেক্স পার্থক্য করতে পারবে', 'Compare simplex, half and full duplex'),
        ('নেটওয়ার্ক টপোলজি', 'Network topologies', 'বিভিন্ন টপোলজির সুবিধা বলতে পারবে', 'Compare network topologies'),
      ], mins: 300, d: 2, r: 3),
      _C(3, 'সংখ্যা পদ্ধতি ও ডিজিটাল ডিভাইস', 'Number Systems and Digital Devices', [
        ('বাইনারি ও হেক্সাডেসিমেল', 'Binary and hexadecimal', 'সংখ্যা পদ্ধতিতে রূপান্তর করতে পারবে', 'Convert between number systems'),
        ('লজিক গেট', 'Logic gates', 'লজিক গেটের সত্যক সারণি লিখতে পারবে', 'Write truth tables for logic gates'),
      ], mins: 360, d: 3, r: 3, lab: true),
      _C(4, 'ওয়েব ডিজাইন পরিচিতি ও HTML', 'Web Design and HTML', [
        ('HTML ট্যাগ', 'HTML tags', 'মৌলিক HTML পেজ তৈরি করতে পারবে', 'Build a basic HTML page'),
      ], mins: 300, d: 2, r: 3, lab: true),
      _C(5, 'প্রোগ্রামিং ভাষা', 'Programming Languages', [
        ('অ্যালগরিদম ও ফ্লোচার্ট', 'Algorithms and flowcharts', 'সমস্যার ফ্লোচার্ট আঁকতে পারবে', 'Draw a flowchart for a problem'),
        ('C প্রোগ্রামিং: লুপ', 'C programming: loops', 'লুপ ব্যবহার করে প্রোগ্রাম লিখতে পারবে', 'Write programs with loops'),
      ], mins: 420, d: 3, r: 3, lab: true),
      _C(6, 'ডেটাবেজ ম্যানেজমেন্ট সিস্টেম', 'Database Management System', [
        ('SQL', 'SQL', 'SELECT কুয়েরি লিখতে পারবে', 'Write SELECT queries'),
      ], mins: 240, d: 2, r: 2),
    ],
  ),
  _subject(
    id: 'hsc-eng2', code: '108', level: EducationLevel.hsc, bn: 'ইংরেজি দ্বিতীয় পত্র', en: 'English 2nd Paper',
    groups: _all, compulsory: true, color: _english, icon: Icons.translate,
    descBn: 'উচ্চতর গ্রামার, অনুচ্ছেদ, রিপোর্ট ও ইমেইল লেখা।',
    descEn: 'Advanced grammar, paragraphs, reports and emails.',
    chapters: const [
      _C(1, 'মডিফায়ার ও কানেক্টর', 'Modifiers and Connectors', [
        ('প্রি-মডিফায়ার ও পোস্ট-মডিফায়ার', 'Pre- and post-modifiers', 'বাক্যে মডিফায়ার যোগ করতে পারবে', 'Add modifiers to sentences'),
        ('লিংকিং ওয়ার্ড', 'Linking words', 'সংযোজক শব্দ দিয়ে বাক্য যুক্ত করতে পারবে', 'Join sentences with connectors'),
      ], mins: 180, d: 2, r: 3),
      _C(2, 'রিপোর্ট ও ইমেইল', 'Reports and Emails', [
        ('সংবাদ প্রতিবেদন', 'News reports', 'সংবাদপত্রের জন্য প্রতিবেদন লিখতে পারবে', 'Write a newspaper report'),
        ('ফরমাল ইমেইল', 'Formal emails', 'আবেদনমূলক ইমেইল লিখতে পারবে', 'Write an application email'),
      ], mins: 210, d: 2, r: 3),
    ],
  ),
  _subject(
    id: 'hsc-bangla1', code: '101', level: EducationLevel.hsc, bn: 'বাংলা প্রথম পত্র', en: 'Bangla 1st Paper',
    groups: _all, compulsory: true, color: _bangla, icon: Icons.menu_book_outlined,
    descBn: 'গদ্য, কবিতা ও উপন্যাস — সৃজনশীল প্রশ্নের গভীর প্রস্তুতি।',
    descEn: 'Prose, poetry and novel — in-depth creative question practice.',
    chapters: const [
      _C(1, 'গদ্য: অপরিচিতা', 'Prose: Oporichita', [
        ('কাহিনি ও চরিত্র', 'Plot and characters', 'অনুপম ও কল্যাণী চরিত্র বিশ্লেষণ করতে পারবে', 'Analyse Anupam and Kalyani'),
        ('যৌতুক প্রথার বিরুদ্ধে প্রতিবাদ', 'Protest against dowry', 'গল্পের সামাজিক বার্তা ব্যাখ্যা করতে পারবে', 'Explain the social message'),
      ], mins: 180, d: 2, r: 3),
      _C(2, 'গদ্য: বিলাসী', 'Prose: Bilasi', [
        ('সামাজিক কুসংস্কার', 'Social prejudice', 'গল্পে জাতপ্রথার সমালোচনা ব্যাখ্যা করতে পারবে', 'Explain the critique of caste'),
      ], mins: 150, d: 2, r: 3),
      _C(3, 'কবিতা: সোনার তরী', 'Poem: Sonar Tori', [
        ('রূপক ও প্রতীক', 'Metaphor and symbol', 'কবিতার প্রতীকী অর্থ ব্যাখ্যা করতে পারবে', 'Explain the symbolic meaning'),
      ], mins: 150, d: 3, r: 3),
    ],
  ),
  _subject(
    id: 'hsc-acc', code: '253', level: EducationLevel.hsc, bn: 'হিসাববিজ্ঞান', en: 'Accounting',
    groups: _bus, color: _commerce, icon: Icons.receipt_long_outlined, papers: 2,
    descBn: 'ব্যাংক সমন্বয় বিবরণী, আর্থিক বিবরণী ও অংশীদারি হিসাব।',
    descEn: 'Bank reconciliation, financial statements and partnership accounts.',
    chapters: const [
      _C(3, 'ব্যাংক সমন্বয় বিবরণী', 'Bank Reconciliation Statement', [
        ('অমিলের কারণ', 'Causes of difference', 'নগদান বই ও ব্যাংক বিবরণীর অমিলের কারণ বলতে পারবে', 'Explain why cash book and bank statement differ'),
        ('সমন্বয় বিবরণী প্রস্তুতি', 'Preparing the statement', 'ব্যাংক সমন্বয় বিবরণী প্রস্তুত করতে পারবে', 'Prepare a bank reconciliation'),
      ], mins: 240, d: 2, r: 3),
      _C(8, 'আর্থিক বিবরণী', 'Financial Statements', [
        ('আয় বিবরণী', 'Income statement', 'আয় বিবরণী প্রস্তুত করতে পারবে', 'Prepare an income statement'),
        ('আর্থিক অবস্থার বিবরণী', 'Statement of financial position', 'উদ্বর্তপত্র প্রস্তুত করতে পারবে', 'Prepare a balance sheet'),
      ], mins: 330, d: 3, r: 3),
    ],
  ),
  _subject(
    id: 'hsc-econ', code: '109', level: EducationLevel.hsc, bn: 'অর্থনীতি', en: 'Economics',
    groups: [AcademicGroup.humanities, AcademicGroup.business], color: _humanities, icon: Icons.trending_up, papers: 2,
    descBn: 'ব্যষ্টিক ও সামষ্টিক অর্থনীতি, বাংলাদেশের অর্থনীতি।',
    descEn: 'Micro and macroeconomics and the economy of Bangladesh.',
    chapters: const [
      _C(2, 'ভোক্তা ও উৎপাদকের আচরণ', 'Consumer and Producer Behaviour', [
        ('উপযোগ', 'Utility', 'প্রান্তিক উপযোগ ক্রমহ্রাস বিধি ব্যাখ্যা করতে পারবে', 'Explain diminishing marginal utility'),
        ('চাহিদার স্থিতিস্থাপকতা', 'Elasticity of demand', 'দাম স্থিতিস্থাপকতা নির্ণয় করতে পারবে', 'Calculate price elasticity'),
      ], mins: 270, d: 3, r: 3),
      _C(4, 'বাংলাদেশের কৃষি', 'Agriculture in Bangladesh', [
        ('কৃষির গুরুত্ব', 'Importance of agriculture', 'অর্থনীতিতে কৃষির অবদান ব্যাখ্যা করতে পারবে', 'Explain agriculture’s role in the economy'),
      ], paper: 2, mins: 180, d: 1, r: 2),
    ],
  ),
  _subject(
    id: 'hsc-civics', code: '269', level: EducationLevel.hsc, bn: 'পৌরনীতি ও সুশাসন', en: 'Civics and Good Governance',
    groups: _hum, color: _humanities, icon: Icons.gavel_outlined, papers: 2,
    descBn: 'রাষ্ট্র, সরকার, সংবিধান ও সুশাসন।',
    descEn: 'State, government, constitution and good governance.',
    chapters: const [
      _C(1, 'পৌরনীতি ও সুশাসন পরিচিতি', 'Introduction to Civics and Good Governance', [
        ('সুশাসনের উপাদান', 'Elements of good governance', 'সুশাসনের বৈশিষ্ট্য বর্ণনা করতে পারবে', 'Describe features of good governance'),
      ], mins: 180, d: 1, r: 2),
      _C(3, 'আইন, স্বাধীনতা ও সাম্য', 'Law, Liberty and Equality', [
        ('আইনের উৎস', 'Sources of law', 'আইনের উৎসগুলো চিহ্নিত করতে পারবে', 'Identify sources of law'),
      ], mins: 210, d: 2, r: 3),
    ],
  ),
];

Subject? subjectById(String id) {
  for (final s in seedSubjects) {
    if (s.id == id) return s;
  }
  return null;
}
