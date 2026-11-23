import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../profile/application/student_profile_controller.dart';
import '../data/curriculum_repository.dart';
import '../domain/curriculum_models.dart';

/// Subjects for the student's level and group (compulsory subjects always included).
final mySubjectsProvider = FutureProvider<List<Subject>>((ref) async {
  final profile = ref.watch(studentProfileProvider);
  final all = await ref.watch(curriculumRepositoryProvider).subjects(level: profile.level);
  return [for (final s in all) if (s.availableFor(profile.group)) s];
});

final subjectsByLevelProvider = FutureProvider.family<List<Subject>, EducationLevel>(
  (ref, level) => ref.watch(curriculumRepositoryProvider).subjects(level: level),
);

final subjectProvider = FutureProvider.family<Subject, String>(
  (ref, id) => ref.watch(curriculumRepositoryProvider).subject(id),
);

final chapterProvider = FutureProvider.family<ChapterRef, String>(
  (ref, id) => ref.watch(curriculumRepositoryProvider).chapter(id),
);

final topicProvider = FutureProvider.family<TopicRef, String>(
  (ref, id) => ref.watch(curriculumRepositoryProvider).topic(id),
);
