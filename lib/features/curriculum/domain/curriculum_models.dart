import 'package:material_ui/material_ui.dart';

import '../../../core/l10n/common_strings.dart';
import '../../../core/l10n/tr.dart';

enum EducationLevel {
  ssc('SSC', Tr('এসএসসি', 'SSC'), [9, 10]),
  hsc('HSC', Tr('এইচএসসি', 'HSC'), [11, 12]);

  const EducationLevel(this.code, this.label, this.classes);

  final String code;
  final Tr label;
  final List<int> classes;

  static EducationLevel fromCode(String code) =>
      values.firstWhere((v) => v.code == code || v.name == code, orElse: () => EducationLevel.ssc);
}

enum AcademicGroup {
  science(Tr('বিজ্ঞান', 'Science'), Icons.science_outlined),
  business(Tr('ব্যবসায় শিক্ষা', 'Business Studies'), Icons.account_balance_outlined),
  humanities(Tr('মানবিক', 'Humanities'), Icons.public_outlined);

  const AcademicGroup(this.label, this.icon);

  final Tr label;
  final IconData icon;
}

enum CurriculumMedium {
  bangla(Tr('বাংলা ভার্সন', 'Bangla Version')),
  english(Tr('ইংলিশ ভার্সন', 'English Version'));

  const CurriculumMedium(this.label);

  final Tr label;
}

enum Difficulty {
  easy(S.easy, 1),
  medium(S.medium, 2),
  hard(S.hard, 3);

  const Difficulty(this.label, this.rank);

  final Tr label;
  final int rank;

  static Difficulty fromRank(int rank) => values.firstWhere((d) => d.rank == rank, orElse: () => medium);
}

class CurriculumVersion {
  const CurriculumVersion({required this.id, required this.name, required this.year, this.isCurrent = false, this.note});

  final String id;
  final Tr name;
  final int year;
  final bool isCurrent;
  final Tr? note;
}

class EducationBoard {
  const EducationBoard(this.id, this.name);

  final String id;
  final Tr name;
}

class LearningOutcome {
  const LearningOutcome({required this.id, required this.text});

  final String id;
  final Tr text;
}

class Topic {
  const Topic({
    required this.id,
    required this.chapterId,
    required this.number,
    required this.title,
    required this.outcomes,
    this.minutes = 30,
  });

  final String id;
  final String chapterId;
  final int number;
  final Tr title;
  final List<LearningOutcome> outcomes;
  final int minutes;
}

enum ExamRelevance {
  high(Tr('বোর্ডে খুব গুরুত্বপূর্ণ', 'High board relevance')),
  medium(Tr('মাঝারি গুরুত্ব', 'Medium relevance')),
  low(Tr('কম গুরুত্ব', 'Lower relevance'));

  const ExamRelevance(this.label);

  final Tr label;
}

class Chapter {
  const Chapter({
    required this.id,
    required this.subjectId,
    required this.number,
    required this.title,
    required this.description,
    required this.topics,
    this.paper = 1,
    this.minutes = 240,
    this.difficulty = Difficulty.medium,
    this.relevance = ExamRelevance.medium,
    this.prerequisiteIds = const [],
    this.hasLab = false,
  });

  final String id;
  final String subjectId;
  final int number;
  final int paper;
  final Tr title;
  final Tr description;
  final List<Topic> topics;
  final int minutes;
  final Difficulty difficulty;
  final ExamRelevance relevance;
  final List<String> prerequisiteIds;
  final bool hasLab;

  List<LearningOutcome> get outcomes => [for (final t in topics) ...t.outcomes];
}

class Subject {
  const Subject({
    required this.id,
    required this.code,
    required this.level,
    required this.name,
    required this.groups,
    required this.color,
    required this.icon,
    required this.chapters,
    required this.description,
    this.papers = 1,
    this.optional = false,
    this.compulsory = false,
  });

  final String id;
  final String code;
  final EducationLevel level;
  final Tr name;
  final List<AcademicGroup> groups;
  final Color color;
  final IconData icon;
  final List<Chapter> chapters;
  final Tr description;
  final int papers;
  final bool optional;
  final bool compulsory;

  int get topicCount => chapters.fold(0, (sum, c) => sum + c.topics.length);
  int get totalMinutes => chapters.fold(0, (sum, c) => sum + c.minutes);

  bool availableFor(AcademicGroup group) => compulsory || groups.contains(group);
}
