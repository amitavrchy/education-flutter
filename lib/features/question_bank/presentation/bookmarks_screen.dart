import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../app/router/app_routes.dart';
import '../../../core/l10n/common_strings.dart';
import '../../../core/l10n/tr.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/time_format.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/feedback.dart';
import '../application/practice_controller.dart';
import '../data/question_repository.dart';
import '../domain/question.dart';
import '../question_strings.dart';
import 'widgets/question_widgets.dart';

/// Saved questions, wrong answers (reattempt), personal practice sets and history.
class BookmarksScreen extends ConsumerWidget {
  const BookmarksScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final practice = ref.watch(practiceProvider);
    final all = {for (final q in ref.watch(questionRepositoryProvider).cached) q.id: q};
    List<Question> resolve(Iterable<String> ids) => [for (final id in ids) ?all[id]];

    Widget list(List<Question> items, Widget empty, {Widget? header}) => items.isEmpty
        ? empty
        : ListView(
            padding: AppSpacing.screen,
            children: [
              ?header,
              for (final q in items)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: QuestionListTile(
                    question: q,
                    status: practice.latestResult[q.id],
                    onTap: () => context.push(AppRoutes.question(q.id)),
                  ),
                ),
            ],
          );

    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: Text(context.tr(QStrings.bookmarks)),
          bottom: TabBar(
            isScrollable: true,
            tabs: [
              Tab(text: '${context.tr(QStrings.bookmarks)} (${context.n(practice.bookmarks.length)})'),
              Tab(text: '${context.tr(QStrings.wrong)} (${context.n(practice.wrongIds.length)})'),
              Tab(text: context.tr(QStrings.sets)),
              Tab(text: context.tr(QStrings.history)),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            list(
              resolve(practice.bookmarks),
              EmptyState(icon: Icons.bookmark_border, title: context.tr(QStrings.noBookmarks), message: context.tr(QStrings.noBookmarksHint)),
              header: Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                child: OutlinedButton.icon(
                  onPressed: () => context.push(AppRoutes.practiceSession(mode: 'bookmarks')),
                  icon: const Icon(Icons.play_arrow),
                  label: Text(context.tr(QStrings.practiceThese)),
                ),
              ),
            ),
            list(
              resolve(practice.wrongIds),
              EmptyState(icon: Icons.emoji_events_outlined, title: context.tr(QStrings.noWrong)),
              header: Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                child: FilledButton.icon(
                  key: const Key('bookmarks.reattempt'),
                  onPressed: () => context.push(AppRoutes.practiceSession(mode: 'wrong')),
                  icon: const Icon(Icons.replay),
                  label: Text(context.tr(QStrings.reattemptAll)),
                ),
              ),
            ),
            _SetsTab(sets: practice.sets),
            practice.attempts.isEmpty
                ? EmptyState(icon: Icons.history, title: context.tr(QStrings.noHistory))
                : ListView.builder(
                    padding: AppSpacing.screen,
                    itemCount: practice.attempts.length.clamp(0, 100),
                    itemBuilder: (context, i) {
                      final a = practice.attempts[i];
                      final q = all[a.questionId];
                      if (q == null) return const SizedBox.shrink();
                      return ListTile(
                        leading: Icon(a.correct ? Icons.check_circle : Icons.cancel,
                            color: a.correct ? Colors.green.shade600 : Theme.of(context).colorScheme.error),
                        title: Text(plainStem(context, q), maxLines: 2, overflow: TextOverflow.ellipsis),
                        subtitle: Text('${context.tr(q.type.label)} · ${relativeTime(a.at, context.lang)}'),
                        onTap: () => context.push(AppRoutes.question(q.id)),
                      );
                    },
                  ),
          ],
        ),
      ),
    );
  }
}

String plainStem(BuildContext context, Question q) => q.stem.of(context.lang).replaceAll(RegExp(r'[\$\\{}]'), '');

class _SetsTab extends ConsumerWidget {
  const _SetsTab({required this.sets});

  final List<PracticeSet> sets;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(practiceProvider.notifier);
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'newSet',
        onPressed: () async {
          final name = await showTextInputDialog(context, title: QStrings.newSet, label: QStrings.setName);
          if (name != null) await controller.createSet(name);
        },
        icon: const Icon(Icons.add),
        label: Text(context.tr(QStrings.newSet)),
      ),
      body: sets.isEmpty
          ? EmptyState(icon: Icons.playlist_add, title: context.tr(QStrings.noSets))
          : ListView(
              padding: AppSpacing.screen,
              children: [
                for (final s in sets)
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.playlist_play),
                      title: Text(s.name),
                      subtitle: Text(context.tr(QStrings.setQuestions.fill({'n': s.questionIds.length}))),
                      onTap: s.questionIds.isEmpty
                          ? null
                          : () => context.push(Uri(path: '/practice-session', queryParameters: {'mode': 'set', 'set': s.id}).toString()),
                      trailing: PopupMenuButton<String>(
                        onSelected: (v) async {
                          if (v == 'rename') {
                            final name = await showTextInputDialog(context, title: S.rename, initial: s.name);
                            if (name != null) await controller.renameSet(s.id, name);
                          } else if (v == 'delete') {
                            final ok = await showConfirmDialog(context, title: QStrings.deleteSet, destructive: true, confirmLabel: S.delete);
                            if (ok) await controller.deleteSet(s.id);
                          }
                        },
                        itemBuilder: (context) => [
                          PopupMenuItem(value: 'rename', child: Text(context.tr(S.rename))),
                          PopupMenuItem(value: 'delete', child: Text(context.tr(S.delete))),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
    );
  }
}
