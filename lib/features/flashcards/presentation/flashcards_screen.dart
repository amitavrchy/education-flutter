import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../app/router/app_routes.dart';
import '../../../core/l10n/common_strings.dart';
import '../../../core/l10n/tr.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/app_page_scaffold.dart';
import '../../../shared/widgets/badges.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/feedback.dart';
import '../../../shared/widgets/rich_content.dart';
import '../../../shared/widgets/search_field.dart';
import '../../../shared/widgets/section_header.dart';
import '../../../shared/widgets/stat_card.dart';
import '../../curriculum/application/curriculum_providers.dart';
import '../../curriculum/domain/curriculum_models.dart';
import '../../notes/application/notes_controller.dart';
import '../application/flashcards_controller.dart';
import '../domain/flashcard.dart';
import '../flashcard_strings.dart';

/// Flashcard home: stats, daily queue, decks, create and generate.
class FlashcardsScreen extends ConsumerWidget {
  const FlashcardsScreen({super.key, this.chapterId});

  final String? chapterId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(flashcardsProvider);
    final now = DateTime.now();
    final due = s.dueIn(null, now).length;
    final decks = chapterId == null ? s.decks : s.decks.where((d) => d.chapterId == chapterId).toList();

    return AppPageScaffold(
      title: context.tr(FcStrings.flashcards),
      actions: [
        PopupMenuButton<String>(
          key: const Key('fc.generate'),
          tooltip: context.tr(FcStrings.generate),
          icon: const Icon(Icons.auto_awesome),
          onSelected: (v) => _generate(context, ref, v),
          itemBuilder: (context) => [
            PopupMenuItem(value: 'chapter', child: ListTile(leading: const Icon(Icons.menu_book_outlined), title: Text(context.tr(FcStrings.fromChapter)))),
            PopupMenuItem(value: 'notes', child: ListTile(leading: const Icon(Icons.sticky_note_2_outlined), title: Text(context.tr(FcStrings.fromNotes)))),
            PopupMenuItem(value: 'mistakes', child: ListTile(leading: const Icon(Icons.replay), title: Text(context.tr(FcStrings.fromMistakes)))),
          ],
        ),
      ],
      floatingActionButton: FloatingActionButton.extended(
        key: const Key('fc.newDeck'),
        onPressed: () async {
          final name = await showTextInputDialog(context, title: FcStrings.newDeck, label: FcStrings.deckName);
          if (name == null) return;
          final d = await ref.read(flashcardsProvider.notifier).createDeck(name, chapterId: chapterId);
          if (context.mounted) await context.push('/flashcards/deck/${d.id}');
        },
        icon: const Icon(Icons.add),
        label: Text(context.tr(FcStrings.newDeck)),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          StatGrid(cards: [
            StatCard(label: context.tr(FcStrings.dueToday), value: context.n(due), icon: Icons.schedule, color: context.palette.warning),
            StatCard(label: context.tr(FcStrings.reviewedToday), value: context.n(s.reviewedOn(now)), icon: Icons.check_circle_outline, color: context.palette.success),
            StatCard(label: context.tr(FcStrings.learned), value: context.n(s.learned), icon: Icons.psychology_outlined, color: context.palette.xp),
            StatCard(label: context.tr(FcStrings.total), value: context.n(s.cards.length), icon: Icons.style_outlined),
          ]),
          const SizedBox(height: AppSpacing.md),
          FilledButton.icon(
            key: const Key('fc.daily'),
            onPressed: due == 0 ? null : () => context.push(AppRoutes.flashcardStudy('all')),
            icon: const Icon(Icons.play_arrow),
            label: Text(context.tr(due == 0 ? FcStrings.nothingDue : FcStrings.dailyQueue)),
          ),
          const SizedBox(height: AppSpacing.sm),
          InfoBanner(message: context.tr(FcStrings.srsInfo)),
          SectionHeader(title: context.tr(FcStrings.decks)),
          if (decks.isEmpty) EmptyState(icon: Icons.style_outlined, title: context.tr(FcStrings.empty), compact: true),
          for (final d in decks)
            Card(
              child: ListTile(
                key: Key('deck.${d.id}'),
                leading: Icon(d.source.icon, color: context.colors.primary),
                title: Text(d.title),
                subtitle: Text(
                  '${context.tr(FcStrings.cards.fill({'n': s.cardsIn(d.id).length}))} · '
                  '${context.tr(FcStrings.due.fill({'n': s.dueIn(d.id, now).length}))} · ${context.tr(d.source.label)}',
                ),
                trailing: IconButton.filledTonal(
                  tooltip: context.tr(FcStrings.study),
                  onPressed: s.cardsIn(d.id).isEmpty ? null : () => context.push(AppRoutes.flashcardStudy(d.id)),
                  icon: const Icon(Icons.play_arrow),
                ),
                onTap: () => context.push('/flashcards/deck/${d.id}'),
              ),
            ),
          const SizedBox(height: 88),
        ],
      ),
    );
  }

  Future<void> _generate(BuildContext context, WidgetRef ref, String from) async {
    final ctl = ref.read(flashcardsProvider.notifier);
    final lang = context.lang;
    Deck? deck;
    switch (from) {
      case 'chapter':
        final subjects = ref.read(mySubjectsProvider).value ?? const <Subject>[];
        final picked = await showModalBottomSheet<String>(
          context: context,
          isScrollControlled: true,
          showDragHandle: true,
          builder: (context) => DraggableScrollableSheet(
            expand: false,
            builder: (context, controller) => ListView(
              controller: controller,
              children: [
                for (final s in subjects)
                  for (final c in s.chapters)
                    ListTile(
                      leading: Icon(s.icon, color: s.color),
                      title: Text(context.tr(c.title)),
                      subtitle: Text(context.tr(s.name)),
                      onTap: () => Navigator.pop(context, c.id),
                    ),
              ],
            ),
          ),
        );
        if (picked != null) deck = await ctl.generateFromChapter(picked, lang);
        if (picked == null) return;
      case 'notes':
        final notes = ref.read(notesProvider);
        if (!context.mounted) return;
        final picked = await showModalBottomSheet<String>(
          context: context,
          showDragHandle: true,
          builder: (context) => ListView(
            shrinkWrap: true,
            children: [for (final n in notes) ListTile(leading: Icon(n.type.icon), title: Text(n.title), onTap: () => Navigator.pop(context, n.id))],
          ),
        );
        if (picked == null) return;
        deck = await ctl.generateFromNote(ref.read(notesProvider.notifier).byId(picked)!);
      case 'mistakes':
        deck = await ctl.generateFromMistakes(lang);
    }
    if (!context.mounted) return;
    if (deck == null) {
      context.showSnack(FcStrings.noCardsGenerated);
      return;
    }
    context.showSnack(FcStrings.deckCreated.fill({'n': ref.read(flashcardsProvider).cardsIn(deck.id).length}));
    await context.push('/flashcards/deck/${deck.id}');
  }
}

enum _Filter { all, due, fresh, bookmarked, learned }

/// One deck: search, filter, card list with edit/delete/bookmark, add card, study modes.
class DeckScreen extends ConsumerStatefulWidget {
  const DeckScreen({super.key, required this.deckId});

  final String deckId;

  @override
  ConsumerState<DeckScreen> createState() => _DeckScreenState();
}

class _DeckScreenState extends ConsumerState<DeckScreen> {
  String _query = '';
  _Filter _filter = _Filter.all;

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(flashcardsProvider);
    final deck = s.decks.where((d) => d.id == widget.deckId).firstOrNull;
    if (deck == null) return Scaffold(appBar: AppBar(), body: EmptyState(title: context.tr(S.notFound)));
    final now = DateTime.now();
    final ctl = ref.read(flashcardsProvider.notifier);
    final cards = s.cardsIn(deck.id).where((c) {
      final ok = switch (_filter) {
        _Filter.all => true,
        _Filter.due => c.srs.isDue(now),
        _Filter.fresh => c.srs.isNew,
        _Filter.bookmarked => c.bookmarked,
        _Filter.learned => c.srs.isMature,
      };
      final q = _query.toLowerCase();
      return ok && (q.isEmpty || c.front.toLowerCase().contains(q) || c.back.toLowerCase().contains(q));
    }).toList();

    return AppPageScaffold(
      title: deck.title,
      showShortcuts: false,
      actions: [
        PopupMenuButton<String>(
          onSelected: (v) async {
            if (v == 'rename') {
              final name = await showTextInputDialog(context, title: S.rename, initial: deck.title);
              if (name != null) await ctl.renameDeck(deck.id, name);
            } else if (v == 'delete') {
              final ok = await showConfirmDialog(context, title: FcStrings.deleteDeck, destructive: true, confirmLabel: S.delete);
              if (ok) {
                await ctl.deleteDeck(deck.id);
                if (context.mounted) context.pop();
              }
            }
          },
          itemBuilder: (context) => [
            PopupMenuItem(value: 'rename', child: Text(context.tr(S.rename))),
            PopupMenuItem(value: 'delete', child: Text(context.tr(S.delete))),
          ],
        ),
      ],
      floatingActionButton: FloatingActionButton(
        key: const Key('deck.addCard'),
        tooltip: context.tr(FcStrings.addCard),
        onPressed: () => _editCard(context, deck.id),
        child: const Icon(Icons.add),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  key: const Key('deck.study'),
                  onPressed: s.cardsIn(deck.id).isEmpty ? null : () => context.push(AppRoutes.flashcardStudy(deck.id)),
                  icon: const Icon(Icons.school_outlined),
                  label: Text(context.tr(FcStrings.study)),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: s.cardsIn(deck.id).isEmpty ? null : () => context.push(AppRoutes.flashcardStudy(deck.id, mode: 'quick')),
                  icon: const Icon(Icons.flash_on_outlined),
                  label: Text(context.tr(FcStrings.quickReview)),
                ),
              ),
            ],
          ),
          if (deck.source == DeckSource.chapter || deck.source == DeckSource.conversation) ...[
            const SizedBox(height: AppSpacing.sm),
            Align(alignment: AlignmentDirectional.centerStart, child: DemoBadge(label: FcStrings.aiDeck)),
          ],
          const SizedBox(height: AppSpacing.md),
          DebouncedSearchField(hint: context.tr(FcStrings.searchCards), onChanged: (q) => setState(() => _query = q)),
          const SizedBox(height: AppSpacing.sm),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final f in _Filter.values)
                  Padding(
                    padding: const EdgeInsetsDirectional.only(end: AppSpacing.xs),
                    child: ChoiceChip(
                      label: Text(context.tr(switch (f) {
                        _Filter.all => FcStrings.filterAll,
                        _Filter.due => FcStrings.filterDue,
                        _Filter.fresh => FcStrings.filterNew,
                        _Filter.bookmarked => FcStrings.filterBookmarked,
                        _Filter.learned => FcStrings.filterLearned,
                      })),
                      selected: _filter == f,
                      onSelected: (_) => setState(() => _filter = f),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          if (cards.isEmpty) EmptyState(icon: Icons.style_outlined, title: context.tr(FcStrings.emptyDeck), compact: true),
          for (final c in cards)
            Card(
              child: ExpansionTile(
                key: Key('card.${c.id}'),
                title: InlineRich(c.front, style: context.text.bodyLarge!, maxLines: 2),
                subtitle: Text(
                  c.srs.due == null ? context.tr(FcStrings.filterNew) : context.tr(FcStrings.nextIn.fill({'t': _dueLabel(context, c.srs.due!, now)})),
                  style: context.text.bodySmall,
                ),
                childrenPadding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.md),
                expandedCrossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  RichContent(c.back),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      IconButton(
                        tooltip: context.tr(S.bookmark),
                        icon: Icon(c.bookmarked ? Icons.bookmark : Icons.bookmark_border),
                        onPressed: () => ctl.toggleBookmark(c.id),
                      ),
                      IconButton(tooltip: context.tr(S.edit), icon: const Icon(Icons.edit_outlined), onPressed: () => _editCard(context, deck.id, card: c)),
                      IconButton(
                        tooltip: context.tr(S.delete),
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () async {
                          final ok = await showConfirmDialog(context, title: FcStrings.deleteCard, destructive: true, confirmLabel: S.delete);
                          if (ok) await ctl.deleteCard(c.id);
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          const SizedBox(height: 88),
        ],
      ),
    );
  }

  Future<void> _editCard(BuildContext context, String deckId, {Flashcard? card}) async {
    final front = TextEditingController(text: card?.front ?? '');
    final back = TextEditingController(text: card?.back ?? '');
    final formKey = GlobalKey<FormState>();
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.tr(card == null ? FcStrings.addCard : FcStrings.editCard)),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                key: const Key('card.front'),
                controller: front,
                maxLines: 3,
                minLines: 1,
                decoration: InputDecoration(labelText: context.tr(FcStrings.front)),
                validator: (v) => (v ?? '').trim().isEmpty ? context.tr(S.required) : null,
              ),
              const SizedBox(height: AppSpacing.sm),
              TextFormField(
                key: const Key('card.back'),
                controller: back,
                maxLines: 4,
                minLines: 1,
                decoration: InputDecoration(labelText: context.tr(FcStrings.back)),
                validator: (v) => (v ?? '').trim().isEmpty ? context.tr(S.required) : null,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(context.tr(S.cancel))),
          FilledButton(
            key: const Key('card.save'),
            onPressed: () {
              if (formKey.currentState!.validate()) Navigator.pop(context, true);
            },
            child: Text(context.tr(S.save)),
          ),
        ],
      ),
    );
    if (ok != true) return;
    final ctl = ref.read(flashcardsProvider.notifier);
    if (card == null) {
      await ctl.addCard(deckId, front.text.trim(), back.text.trim());
    } else {
      await ctl.editCard(card.id, front: front.text.trim(), back: back.text.trim());
    }
  }
}

String _dueLabel(BuildContext context, DateTime due, DateTime now) {
  final diff = due.difference(now);
  if (diff.isNegative || diff.inMinutes < 1) return context.tr(S.today);
  if (diff.inHours < 1) return context.tr(FcStrings.minutes10);
  return context.tr(FcStrings.days.fill({'n': (diff.inHours / 24).ceil()}));
}
