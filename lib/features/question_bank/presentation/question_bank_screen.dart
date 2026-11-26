import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../app/router/app_routes.dart';
import '../../../core/l10n/common_strings.dart';
import '../../../core/l10n/tr.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../mock/seed/curriculum_seed.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/error_view.dart';
import '../../../shared/widgets/progress.dart';
import '../../../shared/widgets/search_field.dart';
import '../../../shared/widgets/skeleton.dart';
import '../../curriculum/application/curriculum_providers.dart';
import '../../curriculum/data/curriculum_repository.dart';
import '../../curriculum/domain/curriculum_models.dart';
import '../../progress/application/learning_progress_controller.dart';
import '../application/practice_controller.dart';
import '../data/question_repository.dart';
import '../domain/question.dart';
import '../question_strings.dart';
import 'widgets/question_widgets.dart';

/// Browse, search, filter, sort and paginate the question bank.
class QuestionBankScreen extends ConsumerStatefulWidget {
  const QuestionBankScreen({super.key, this.subjectId, this.chapterId, this.topicId});

  final String? subjectId;
  final String? chapterId;
  final String? topicId;

  @override
  ConsumerState<QuestionBankScreen> createState() => _QuestionBankScreenState();
}

class _QuestionBankScreenState extends ConsumerState<QuestionBankScreen> {
  late QuestionFilter _filter = QuestionFilter(subjectId: widget.subjectId, chapterId: widget.chapterId, topicId: widget.topicId);
  final List<Question> _items = [];
  int _page = 0;
  int _total = 0;
  bool _loading = false;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _load(reset: true);
  }

  Future<void> _load({bool reset = false}) async {
    if (_loading) return;
    setState(() {
      _loading = true;
      _error = null;
      if (reset) {
        _items.clear();
        _page = 0;
      }
    });
    try {
      final result = await ref.read(questionRepositoryProvider).search(_filter, page: reset ? 0 : _page + 1);
      if (!mounted) return;
      setState(() {
        _items.addAll(result.items);
        _page = result.page;
        _total = result.total;
      });
    } catch (e) {
      if (mounted) setState(() => _error = e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _apply(QuestionFilter f) {
    _filter = f;
    _load(reset: true);
  }

  @override
  Widget build(BuildContext context) {
    final subjects = ref.watch(mySubjectsProvider).value ?? const <Subject>[];
    final repo = ref.watch(curriculumRepositoryProvider);
    final subject = subjects.where((s) => s.id == _filter.subjectId).firstOrNull ??
        repo.cachedSubjects.where((s) => s.id == _filter.subjectId).firstOrNull;
    final latest = ref.watch(practiceProvider.select((s) => s.latestResult));

    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr(QStrings.bank)),
        actions: [
          PopupMenuButton<QuestionSort>(
            tooltip: context.tr(S.sort),
            icon: const Icon(Icons.sort),
            initialValue: _filter.sort,
            onSelected: (s) => _apply(_filter.copyWith(sort: s)),
            itemBuilder: (context) => [
              for (final s in QuestionSort.values) PopupMenuItem(value: s, child: Text(context.tr(s.label))),
            ],
          ),
          IconButton(
            key: const Key('bank.filters'),
            tooltip: context.tr(QStrings.filters),
            icon: Badge(
              isLabelVisible: _filter.activeCount > 0,
              label: Text(context.n(_filter.activeCount)),
              child: const Icon(Icons.tune),
            ),
            onPressed: () async {
              final f = await showModalBottomSheet<QuestionFilter>(
                context: context,
                isScrollControlled: true,
                showDragHandle: true,
                builder: (_) => _FilterSheet(initial: _filter),
              );
              if (f != null) _apply(f);
            },
          ),
        ],
      ),
      floatingActionButton: _total > 0
          ? FloatingActionButton.extended(
              onPressed: () => context.push(AppRoutes.practiceSession(
                subjectId: _filter.subjectId,
                chapterId: _filter.chapterId,
                topicId: _filter.topicId,
              )),
              icon: const Icon(Icons.play_arrow),
              label: Text(context.tr(QStrings.practiceThese)),
            )
          : null,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: AppSpacing.maxContentWidth),
          child: CustomScrollView(
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, 0),
                sliver: SliverList.list(children: [
                  DebouncedSearchField(
                    hint: context.tr(QStrings.searchHint),
                    initial: _filter.query,
                    onChanged: (q) => _apply(_filter.copyWith(query: q)),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _ScopeChip(
                          label: subject == null ? context.tr(S.subject) : context.tr(subject.name),
                          active: subject != null,
                          onTap: () async {
                            final picked = await _pickSubject(context, subjects);
                            if (picked != null) {
                              _apply(_filter.copyWith(subjectId: () => picked.isEmpty ? null : picked, chapterId: () => null, topicId: () => null));
                            }
                          },
                        ),
                        if (subject != null)
                          _ScopeChip(
                            label: _filter.chapterId == null
                                ? context.tr(S.chapter)
                                : context.tr(repo.findChapter(_filter.chapterId!)?.chapter.title ?? S.chapter),
                            active: _filter.chapterId != null,
                            onTap: () async {
                              final picked = await _pickChapter(context, subject);
                              if (picked != null) {
                                _apply(_filter.copyWith(chapterId: () => picked.isEmpty ? null : picked, topicId: () => null));
                              }
                            },
                          ),
                        for (final d in Difficulty.values)
                          Padding(
                            padding: const EdgeInsetsDirectional.only(end: AppSpacing.xs),
                            child: FilterChip(
                              label: Text(context.tr(d.label)),
                              selected: _filter.difficulty == d,
                              onSelected: (on) => _apply(_filter.copyWith(difficulty: () => on ? d : null)),
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (subject != null) _Coverage(subject: subject, chapterId: _filter.chapterId),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                    child: Row(
                      children: [
                        Text(context.tr(QStrings.results.fill({'n': _total})), style: context.text.labelLarge),
                        const Spacer(),
                        if (_filter.activeCount > 0)
                          TextButton(onPressed: () => _apply(_filter.cleared()), child: Text(context.tr(S.clearFilters))),
                      ],
                    ),
                  ),
                ]),
              ),
              if (_items.isEmpty && _loading)
                const SliverToBoxAdapter(child: SkeletonList(count: 4))
              else if (_items.isEmpty && _error != null)
                SliverToBoxAdapter(child: ErrorView(error: _error, onRetry: () => _load(reset: true)))
              else if (_items.isEmpty)
                SliverToBoxAdapter(
                  child: EmptyState(
                    icon: Icons.search_off,
                    title: context.tr(QStrings.emptyBank),
                    message: context.tr(S.noResultsHint),
                    action: _filter.activeCount > 0
                        ? OutlinedButton(onPressed: () => _apply(_filter.cleared()), child: Text(context.tr(S.clearFilters)))
                        : null,
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                  sliver: SliverList.builder(
                    itemCount: _items.length + 1,
                    itemBuilder: (context, i) {
                      if (i == _items.length) {
                        return Padding(
                          padding: const EdgeInsets.only(top: AppSpacing.sm, bottom: 96),
                          child: _loading
                              ? const Center(child: CircularProgressIndicator())
                              : _items.length < _total
                                  ? OutlinedButton(onPressed: _load, child: Text(context.tr(QStrings.loadMore)))
                                  : const SizedBox.shrink(),
                        );
                      }
                      final q = _items[i];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                        child: QuestionListTile(
                          question: q,
                          status: latest[q.id],
                          onTap: () => context.push(AppRoutes.question(q.id)),
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<String?> _pickSubject(BuildContext context, List<Subject> subjects) => showModalBottomSheet<String>(
    context: context,
    showDragHandle: true,
    builder: (context) => ListView(
      shrinkWrap: true,
      children: [
        ListTile(leading: const Icon(Icons.all_inclusive), title: Text(context.tr(S.all)), onTap: () => Navigator.pop(context, '')),
        for (final s in subjects)
          ListTile(
            leading: Icon(s.icon, color: s.color),
            title: Text(context.tr(s.name)),
            onTap: () => Navigator.pop(context, s.id),
          ),
      ],
    ),
  );

  Future<String?> _pickChapter(BuildContext context, Subject subject) => showModalBottomSheet<String>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (context) => ListView(
      shrinkWrap: true,
      children: [
        ListTile(leading: const Icon(Icons.all_inclusive), title: Text(context.tr(S.all)), onTap: () => Navigator.pop(context, '')),
        for (final c in subject.chapters)
          ListTile(
            leading: CircleAvatar(radius: 14, child: Text(context.n(c.number))),
            title: Text(context.tr(c.title)),
            onTap: () => Navigator.pop(context, c.id),
          ),
      ],
    ),
  );
}

class _ScopeChip extends StatelessWidget {
  const _ScopeChip({required this.label, required this.active, required this.onTap});

  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsetsDirectional.only(end: AppSpacing.xs),
    child: InputChip(
      label: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 160), child: Text(label, overflow: TextOverflow.ellipsis)),
      selected: active,
      onPressed: onTap,
      avatar: const Icon(Icons.arrow_drop_down, size: 18),
    ),
  );
}

/// How many of the scope's topics the student has practised (topic coverage indicator).
class _Coverage extends ConsumerWidget {
  const _Coverage({required this.subject, this.chapterId});

  final Subject subject;
  final String? chapterId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progress = ref.watch(learningProgressProvider);
    final topics = [
      for (final c in subject.chapters)
        if (chapterId == null || c.id == chapterId) ...c.topics,
    ];
    if (topics.isEmpty) return const SizedBox.shrink();
    final done = topics.where((t) => progress.topic(t.id).attempts > 0).length;
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.sm),
      child: LabeledProgress(
        dense: true,
        label: context.tr(QStrings.coverage),
        value: done / topics.length,
        trailing: context.tr(QStrings.coverageValue.fill({'done': done, 'total': topics.length})),
        color: subject.color,
      ),
    );
  }
}

/// Advanced filters: type, source, year, board, marks, verified, relevance.
class _FilterSheet extends StatefulWidget {
  const _FilterSheet({required this.initial});

  final QuestionFilter initial;

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  late QuestionFilter f = widget.initial;

  @override
  Widget build(BuildContext context) {
    Widget title(Tr t) => Padding(
      padding: const EdgeInsets.only(top: AppSpacing.md, bottom: AppSpacing.xs),
      child: Text(context.tr(t), style: context.text.titleSmall),
    );
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.8,
      maxChildSize: 0.95,
      builder: (context, controller) => Column(
        children: [
          Expanded(
            child: ListView(
              controller: controller,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              children: [
                Text(context.tr(QStrings.filters), style: context.text.titleLarge),
                title(QStrings.type),
                Wrap(spacing: AppSpacing.xs, runSpacing: AppSpacing.xs, children: [
                  for (final t in QuestionType.values)
                    FilterChip(
                      label: Text(context.tr(t.label)),
                      selected: f.types.contains(t),
                      onSelected: (on) => setState(() {
                        final next = Set.of(f.types);
                        on ? next.add(t) : next.remove(t);
                        f = f.copyWith(types: next);
                      }),
                    ),
                ]),
                title(QStrings.source),
                Wrap(spacing: AppSpacing.xs, runSpacing: AppSpacing.xs, children: [
                  for (final s in QuestionSource.values)
                    ChoiceChip(
                      label: Text(context.tr(s.label)),
                      selected: f.source == s,
                      onSelected: (on) => setState(() => f = f.copyWith(source: () => on ? s : null)),
                    ),
                ]),
                title(QStrings.board),
                Wrap(spacing: AppSpacing.xs, runSpacing: AppSpacing.xs, children: [
                  for (final b in educationBoards)
                    ChoiceChip(
                      label: Text(context.tr(b.name)),
                      selected: f.boardId == b.id,
                      onSelected: (on) => setState(() => f = f.copyWith(boardId: () => on ? b.id : null)),
                    ),
                ]),
                title(QStrings.year),
                Wrap(spacing: AppSpacing.xs, runSpacing: AppSpacing.xs, children: [
                  for (var y = 2024; y >= 2015; y--)
                    ChoiceChip(
                      label: Text(context.n(y)),
                      selected: f.year == y,
                      onSelected: (on) => setState(() => f = f.copyWith(year: () => on ? y : null)),
                    ),
                ]),
                title(QStrings.marks),
                Wrap(spacing: AppSpacing.xs, runSpacing: AppSpacing.xs, children: [
                  for (final m in const [1, 2, 3, 4, 10])
                    ChoiceChip(
                      label: Text(context.n(m)),
                      selected: f.marks == m,
                      onSelected: (on) => setState(() => f = f.copyWith(marks: () => on ? m : null)),
                    ),
                ]),
                const SizedBox(height: AppSpacing.sm),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(context.tr(QStrings.verifiedOnly)),
                  value: f.verifiedOnly,
                  onChanged: (v) => setState(() => f = f.copyWith(verifiedOnly: v)),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(context.tr(QStrings.highRelevance)),
                  value: f.highRelevanceOnly,
                  onChanged: (v) => setState(() => f = f.copyWith(highRelevanceOnly: v)),
                ),
              ],
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => setState(() => f = f.cleared()),
                      child: Text(context.tr(S.clearFilters)),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: FilledButton(
                      key: const Key('filters.apply'),
                      onPressed: () => Navigator.pop(context, f),
                      child: Text(context.tr(S.apply)),
                    ),
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
