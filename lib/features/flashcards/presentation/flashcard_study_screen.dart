import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/l10n/common_strings.dart';
import '../../../core/l10n/tr.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/rich_content.dart';
import '../application/flashcards_controller.dart';
import '../domain/flashcard.dart';
import '../flashcard_strings.dart';

/// Study mode (rated, updates the schedule) and quick review (flip through, no scheduling).
/// [deckId] `all` = today's queue across decks.
class FlashcardStudyScreen extends ConsumerStatefulWidget {
  const FlashcardStudyScreen({super.key, required this.deckId, this.quick = false});

  final String deckId;
  final bool quick;

  @override
  ConsumerState<FlashcardStudyScreen> createState() => _FlashcardStudyScreenState();
}

class _FlashcardStudyScreenState extends ConsumerState<FlashcardStudyScreen> {
  late final DateTime _started = DateTime.now();
  late final List<String> _queue = _buildQueue();
  int _index = 0;
  bool _flipped = false;
  int _reviewed = 0;
  bool _done = false;

  List<String> _buildQueue() {
    final s = ref.read(flashcardsProvider);
    final now = DateTime.now();
    final deck = widget.deckId == 'all' ? null : widget.deckId;
    if (widget.quick) return [for (final c in s.cardsIn(widget.deckId)) c.id];
    final due = s.dueIn(deck, now);
    // Study mode on a deck with nothing due still lets you practise every card.
    final list = due.isNotEmpty || deck == null ? due : s.cardsIn(deck);
    return [for (final c in list) c.id];
  }

  Future<void> _rate(Rating r) async {
    await ref.read(flashcardsProvider.notifier).review(_queue[_index], r);
    _reviewed++;
    _advance();
  }

  void _advance() {
    if (_index < _queue.length - 1) {
      setState(() {
        _index++;
        _flipped = false;
      });
    } else {
      _finish();
    }
  }

  Future<void> _finish() async {
    if (_reviewed > 0 || widget.quick) {
      final minutes = max(1, DateTime.now().difference(_started).inMinutes);
      await ref.read(flashcardsProvider.notifier).finishSession(reviewed: max(_reviewed, widget.quick ? _queue.length : 0), minutes: minutes);
    }
    if (mounted) setState(() => _done = true);
  }

  @override
  Widget build(BuildContext context) {
    final cards = {for (final c in ref.watch(flashcardsProvider).cards) c.id: c};
    if (_queue.isEmpty) {
      return Scaffold(appBar: AppBar(), body: EmptyState(icon: Icons.celebration_outlined, title: context.tr(FcStrings.nothingDue)));
    }
    if (_done) {
      final n = widget.quick ? _queue.length : _reviewed;
      return Scaffold(
        appBar: AppBar(automaticallyImplyLeading: false, title: Text(context.tr(FcStrings.sessionDone))),
        body: EmptyState(
          icon: Icons.emoji_events_outlined,
          iconColor: context.palette.xp,
          title: context.tr(FcStrings.sessionDone),
          message: context.tr(FcStrings.sessionSummary.fill({'n': n, 'xp': n * 2})),
          action: FilledButton(key: const Key('study.done'), onPressed: () => context.pop(), child: Text(context.tr(S.done))),
        ),
      );
    }
    final card = cards[_queue[_index]];
    if (card == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _advance());
      return const Scaffold(body: SizedBox.shrink());
    }
    final now = DateTime.now();
    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr(FcStrings.cardNofM.fill({'n': _index + 1, 'm': _queue.length}))),
        bottom: PreferredSize(preferredSize: const Size.fromHeight(4), child: LinearProgressIndicator(value: (_index + 1) / _queue.length)),
        actions: [
          IconButton(
            tooltip: context.tr(S.bookmark),
            icon: Icon(card.bookmarked ? Icons.bookmark : Icons.bookmark_border),
            onPressed: () => ref.read(flashcardsProvider.notifier).toggleBookmark(card.id),
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: Padding(
              padding: AppSpacing.screen,
              child: Column(
                children: [
                  if (widget.quick) Text(context.tr(FcStrings.quickNote), style: context.text.bodySmall),
                  const SizedBox(height: AppSpacing.sm),
                  Expanded(
                    child: GestureDetector(
                      key: const Key('study.card'),
                      onTap: () => setState(() => _flipped = !_flipped),
                      child: _FlipCard(front: card.front, back: card.back, flipped: _flipped),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  if (widget.quick)
                    Row(
                      children: [
                        IconButton.outlined(
                          tooltip: context.tr(S.previous),
                          onPressed: _index == 0 ? null : () => setState(() {
                            _index--;
                            _flipped = false;
                          }),
                          icon: const Icon(Icons.chevron_left),
                        ),
                        const Spacer(),
                        FilledButton.tonal(onPressed: () => setState(() => _flipped = !_flipped), child: Text(context.tr(FcStrings.tapToFlip))),
                        const Spacer(),
                        IconButton.outlined(key: const Key('study.next'), tooltip: context.tr(S.next), onPressed: _advance, icon: const Icon(Icons.chevron_right)),
                      ],
                    )
                  else if (!_flipped)
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(key: const Key('study.flip'), onPressed: () => setState(() => _flipped = true), child: Text(context.tr(FcStrings.showAnswer))),
                    )
                  else
                    Column(
                      children: [
                        Row(
                          children: [
                            for (final r in Rating.values)
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 2),
                                  child: _RateButton(rating: r, preview: card.srs.review(r, now).due!, now: now, onTap: () => _rate(r)),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Row(
                          children: [
                            TextButton.icon(onPressed: () => _rate(Rating.again), icon: const Icon(Icons.close), label: Text(context.tr(FcStrings.unknown))),
                            const Spacer(),
                            TextButton.icon(onPressed: () => _rate(Rating.easy), icon: const Icon(Icons.check), label: Text(context.tr(FcStrings.known))),
                          ],
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RateButton extends StatelessWidget {
  const _RateButton({required this.rating, required this.preview, required this.now, required this.onTap});

  final Rating rating;
  final DateTime preview;
  final DateTime now;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = switch (rating) {
      Rating.again => context.palette.danger,
      Rating.hard => context.palette.warning,
      Rating.good => context.palette.info,
      Rating.easy => context.palette.success,
    };
    final diff = preview.difference(now);
    final when = diff.inHours < 1 ? context.tr(FcStrings.minutes10) : context.tr(FcStrings.days.fill({'n': (diff.inHours / 24).round()}));
    return OutlinedButton(
      key: Key('rate.${rating.name}'),
      style: OutlinedButton.styleFrom(foregroundColor: color, side: BorderSide(color: color), padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm)),
      onPressed: onTap,
      child: Column(mainAxisSize: MainAxisSize.min, children: [Text(context.tr(rating.label)), Text(when, style: context.text.labelSmall?.copyWith(color: color))]),
    );
  }
}

/// 3D flip (instant when reduced motion is on).
class _FlipCard extends StatelessWidget {
  const _FlipCard({required this.front, required this.back, required this.flipped});

  final String front;
  final String back;
  final bool flipped;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(end: flipped ? 1 : 0),
      duration: context.reduceMotion ? Duration.zero : const Duration(milliseconds: 380),
      curve: Curves.easeInOut,
      builder: (context, t, _) {
        final showBack = t >= 0.5;
        final angle = t * pi;
        return Semantics(
          label: context.tr(FcStrings.tapToFlip),
          child: Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.0012)
              ..rotateY(angle),
            child: Transform(
              alignment: Alignment.center,
              transform: Matrix4.identity()..rotateY(showBack ? pi : 0),
              child: Card(
                color: showBack ? context.colors.primaryContainer : context.colors.surfaceContainerLow,
                child: SizedBox.expand(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.xl),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          context.tr(showBack ? FcStrings.back : FcStrings.front),
                          style: context.text.labelMedium?.copyWith(color: context.colors.onSurfaceVariant),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Flexible(
                          child: SingleChildScrollView(
                            child: RichContent(showBack ? back : front, baseStyle: context.text.titleLarge),
                          ),
                        ),
                        if (!showBack) ...[
                          const SizedBox(height: AppSpacing.lg),
                          Icon(Icons.touch_app_outlined, color: context.colors.onSurfaceVariant),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
