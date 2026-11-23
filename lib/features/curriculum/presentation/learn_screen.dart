import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../app/router/app_routes.dart';
import '../../../core/l10n/common_strings.dart';
import '../../../core/l10n/tr.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/app_page_scaffold.dart';
import '../../../shared/widgets/async_value_view.dart';
import '../../../shared/widgets/cards.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/progress.dart';
import '../../../shared/widgets/search_field.dart';
import '../../../shared/widgets/section_header.dart';
import '../../profile/application/student_profile_controller.dart';
import '../../progress/application/learning_progress_controller.dart';
import '../application/curriculum_providers.dart';
import '../curriculum_strings.dart';
import '../data/curriculum_repository.dart';
import '../domain/curriculum_models.dart';

/// Curriculum explorer: the student's subjects (or every subject of a level), with
/// progress, quick search across chapters, and a "continue learning" shortcut.
class LearnScreen extends ConsumerStatefulWidget {
  const LearnScreen({super.key});

  @override
  ConsumerState<LearnScreen> createState() => _LearnScreenState();
}

class _LearnScreenState extends ConsumerState<LearnScreen> {
  bool _showAll = false;
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(studentProfileProvider);
    final subjects = _showAll ? ref.watch(subjectsByLevelProvider(profile.level)) : ref.watch(mySubjectsProvider);
    return AppPageScaffold(
      title: context.tr(CurriculumStrings.learn),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DebouncedSearchField(
            hint: context.tr(CurriculumStrings.searchSubjects),
            onChanged: (q) => setState(() => _query = q),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: Text(
                  '${context.tr(profile.level.label)} · ${context.tr(profile.group.label)}',
                  style: context.text.labelLarge?.copyWith(color: context.colors.onSurfaceVariant),
                ),
              ),
              SegmentedButton<bool>(
                showSelectedIcon: false,
                segments: [
                  ButtonSegment(value: false, label: Text(context.tr(CurriculumStrings.mySubjects))),
                  ButtonSegment(value: true, label: Text(context.tr(S.all))),
                ],
                selected: {_showAll},
                onSelectionChanged: (s) => setState(() => _showAll = s.first),
              ),
            ],
          ),
          if (_query.isEmpty) const _ContinueLearning(),
          AsyncValueView<List<Subject>>(
            value: subjects,
            onRetry: () => ref.invalidate(mySubjectsProvider),
            data: (list) => _query.isEmpty ? _SubjectGrid(subjects: list) : _SearchResults(subjects: list, query: _query),
          ),
        ],
      ),
    );
  }
}

class _ContinueLearning extends ConsumerWidget {
  const _ContinueLearning();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progress = ref.watch(learningProgressProvider);
    final repo = ref.watch(curriculumRepositoryProvider);
    final recent = progress.topics.values.where((t) => t.lastStudied != null).toList()
      ..sort((a, b) => b.lastStudied!.compareTo(a.lastStudied!));
    final ref0 = recent.map((t) => repo.findTopic(t.topicId)).nonNulls.firstOrNull;
    if (ref0 == null) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(title: context.tr(CurriculumStrings.continueLearning)),
        NavTile(
          icon: ref0.subject.icon,
          color: ref0.subject.color,
          title: context.tr(ref0.topic.title),
          subtitle: '${context.tr(ref0.subject.name)} · ${context.tr(ref0.chapter.title)}',
          onTap: () => context.push(AppRoutes.topic(ref0.topic.id)),
          trailing: ProgressRing(value: progress.chapterMastery(ref0.chapter), size: 40, stroke: 4),
        ),
      ],
    );
  }
}

class _SubjectGrid extends ConsumerWidget {
  const _SubjectGrid({required this.subjects});

  final List<Subject> subjects;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (subjects.isEmpty) {
      return EmptyState(icon: Icons.menu_book_outlined, title: context.tr(S.emptyTitle));
    }
    final progress = ref.watch(learningProgressProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(title: context.tr(CurriculumStrings.allSubjects)),
        LayoutBuilder(
          builder: (context, constraints) {
            final columns = constraints.maxWidth >= 600 ? 3 : 2;
            final width = (constraints.maxWidth - AppSpacing.md * (columns - 1)) / columns;
            return Wrap(
              spacing: AppSpacing.md,
              runSpacing: AppSpacing.md,
              children: [
                for (final s in subjects)
                  SizedBox(
                    width: width,
                    child: _SubjectCard(subject: s, mastery: progress.subjectMastery(s)),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _SubjectCard extends StatelessWidget {
  const _SubjectCard({required this.subject, required this.mastery});

  final Subject subject;
  final double mastery;

  @override
  Widget build(BuildContext context) {
    return TapCard(
      key: Key('subject.${subject.id}'),
      semanticLabel: '${context.tr(subject.name)}, ${context.tr(CurriculumStrings.mastery)} ${context.pct(mastery * 100)}',
      onTap: () => context.push(AppRoutes.subject(subject.id)),
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconTile(icon: subject.icon, color: subject.color, size: 40),
              const Spacer(),
              ProgressRing(value: mastery, size: 38, stroke: 4, color: subject.color),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            context.tr(subject.name),
            style: context.text.titleSmall,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            context.tr(CurriculumStrings.chapterCount.fill({'n': subject.chapters.length})),
            style: context.text.bodySmall?.copyWith(color: context.colors.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

class _SearchResults extends StatelessWidget {
  const _SearchResults({required this.subjects, required this.query});

  final List<Subject> subjects;
  final String query;

  @override
  Widget build(BuildContext context) {
    final hits = <Widget>[];
    for (final s in subjects) {
      if (s.name.matches(query)) {
        hits.add(NavTile(
          icon: s.icon,
          color: s.color,
          title: context.tr(s.name),
          subtitle: context.tr(S.subject),
          onTap: () => context.push(AppRoutes.subject(s.id)),
        ));
      }
      for (final c in s.chapters) {
        if (c.title.matches(query) || c.topics.any((t) => t.title.matches(query))) {
          hits.add(NavTile(
            icon: Icons.bookmark_border,
            color: s.color,
            title: context.tr(c.title),
            subtitle: '${context.tr(s.name)} · ${context.tr(S.chapter)} ${context.n(c.number)}',
            onTap: () => context.push(AppRoutes.chapter(c.id)),
          ));
        }
      }
    }
    if (hits.isEmpty) {
      return EmptyState(
        icon: Icons.search_off,
        title: context.tr(S.noResults),
        message: context.tr(S.noResultsHint),
        compact: true,
      );
    }
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [for (final h in hits) Padding(padding: const EdgeInsets.only(bottom: AppSpacing.sm), child: h)],
      ),
    );
  }
}
