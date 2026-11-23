import 'package:flutter/foundation.dart';

import '../../curriculum/domain/curriculum_models.dart';

/// Academic context captured during onboarding; drives curriculum filtering,
/// tutor context and recommendations.
@immutable
class StudentProfile {
  const StudentProfile({
    this.name = '',
    this.level = EducationLevel.ssc,
    this.classYear = 10,
    this.group = AcademicGroup.science,
    this.medium = CurriculumMedium.bangla,
    this.boardId = 'dhaka',
    this.curriculumVersionId = 'nctb-2025',
    this.institution = '',
    this.examYear = 2027,
    this.targetGpa = 5.0,
    this.dailyMinutes = 60,
    this.weakSubjectIds = const [],
    this.onboarded = false,
  });

  factory StudentProfile.fromJson(Map<String, dynamic> json) => StudentProfile(
    name: json['name'] as String? ?? '',
    level: EducationLevel.fromCode(json['level'] as String? ?? 'ssc'),
    classYear: json['classYear'] as int? ?? 10,
    group: AcademicGroup.values.byName(json['group'] as String? ?? 'science'),
    medium: CurriculumMedium.values.byName(json['medium'] as String? ?? 'bangla'),
    boardId: json['boardId'] as String? ?? 'dhaka',
    curriculumVersionId: json['curriculumVersionId'] as String? ?? 'nctb-2025',
    institution: json['institution'] as String? ?? '',
    examYear: json['examYear'] as int? ?? 2027,
    targetGpa: (json['targetGpa'] as num?)?.toDouble() ?? 5.0,
    dailyMinutes: json['dailyMinutes'] as int? ?? 60,
    weakSubjectIds: List<String>.from(json['weakSubjectIds'] as List? ?? const []),
    onboarded: json['onboarded'] as bool? ?? false,
  );

  final String name;
  final EducationLevel level;
  final int classYear;
  final AcademicGroup group;
  final CurriculumMedium medium;
  final String boardId;
  final String curriculumVersionId;
  final String institution;
  final int examYear;
  final double targetGpa;
  final int dailyMinutes;
  final List<String> weakSubjectIds;
  final bool onboarded;

  StudentProfile copyWith({
    String? name,
    EducationLevel? level,
    int? classYear,
    AcademicGroup? group,
    CurriculumMedium? medium,
    String? boardId,
    String? curriculumVersionId,
    String? institution,
    int? examYear,
    double? targetGpa,
    int? dailyMinutes,
    List<String>? weakSubjectIds,
    bool? onboarded,
  }) => StudentProfile(
    name: name ?? this.name,
    level: level ?? this.level,
    classYear: classYear ?? this.classYear,
    group: group ?? this.group,
    medium: medium ?? this.medium,
    boardId: boardId ?? this.boardId,
    curriculumVersionId: curriculumVersionId ?? this.curriculumVersionId,
    institution: institution ?? this.institution,
    examYear: examYear ?? this.examYear,
    targetGpa: targetGpa ?? this.targetGpa,
    dailyMinutes: dailyMinutes ?? this.dailyMinutes,
    weakSubjectIds: weakSubjectIds ?? this.weakSubjectIds,
    onboarded: onboarded ?? this.onboarded,
  );

  Map<String, dynamic> toJson() => {
    'name': name,
    'level': level.name,
    'classYear': classYear,
    'group': group.name,
    'medium': medium.name,
    'boardId': boardId,
    'curriculumVersionId': curriculumVersionId,
    'institution': institution,
    'examYear': examYear,
    'targetGpa': targetGpa,
    'dailyMinutes': dailyMinutes,
    'weakSubjectIds': weakSubjectIds,
    'onboarded': onboarded,
  };
}
