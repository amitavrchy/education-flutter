import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../app/router/app_routes.dart';
import '../../../core/l10n/common_strings.dart';
import '../../../core/l10n/tr.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/badges.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/feedback.dart';
import '../../profile/application/student_profile_controller.dart';
import '../../question_bank/application/practice_controller.dart';
import '../application/tutor_controller.dart';
import '../domain/tutor_models.dart';
import '../tutor_strings.dart';
import 'ai_tutor_screen.dart';
import 'widgets/tutor_widgets.dart';

/// Hook for converting a conversation into another module's content (notes, flashcards).
/// Registered by those modules so the tutor does not depend on them.
typedef ConversationConverter = Future<String?> Function(WidgetRef ref, Conversation c);

final conversationToNoteProvider = Provider<ConversationConverter?>((ref) => null);
final conversationToFlashcardsProvider = Provider<ConversationConverter?>((ref) => null);

/// Chat with the simulated tutor: active context chips, mode switch, streaming answers,
/// message actions and conversation tools (export, share, quiz, notes, flashcards).
class TutorChatScreen extends ConsumerStatefulWidget {
  const TutorChatScreen({super.key, required this.conversationId, this.initialPrompt});

  final String conversationId;
  final String? initialPrompt;

  @override
  ConsumerState<TutorChatScreen> createState() => _TutorChatScreenState();
}

class _TutorChatScreenState extends ConsumerState<TutorChatScreen> {
  late final _input = TextEditingController(text: widget.initialPrompt ?? '');
  final _scroll = ScrollController();

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _send([String? text]) {
    final t = (text ?? _input.text).trim();
    if (t.isEmpty) return;
    _input.clear();
    ref.read(tutorProvider.notifier).send(widget.conversationId, t);
    _scrollToEnd();
  }

  void _scrollToEnd() => WidgetsBinding.instance.addPostFrameCallback((_) {
    if (_scroll.hasClients) {
      _scroll.animateTo(_scroll.position.maxScrollExtent + 200, duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
    }
  });

  @override
  Widget build(BuildContext context) {
    final c = ref.watch(tutorProvider.select((list) => list.where((x) => x.id == widget.conversationId).firstOrNull));
    if (c == null) {
      return Scaffold(appBar: AppBar(), body: EmptyState(icon: Icons.search_off, title: context.tr(S.notFound)));
    }
    ref.listen(tutorProvider.select((list) => list.where((x) => x.id == widget.conversationId).firstOrNull?.messages.lastOrNull?.text.length), (_, _) => _scrollToEnd());
    final ctl = ref.read(tutorProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: Text(c.title.isEmpty ? context.tr(TutorStrings.newChat) : c.title, maxLines: 1, overflow: TextOverflow.ellipsis),
        actions: [
          IconButton(
            tooltip: context.tr(TutorStrings.voiceTutorTooltip),
            icon: const Icon(Icons.mic_none),
            onPressed: () => context.push(AppRoutes.voiceTutor),
          ),
          PopupMenuButton<String>(
            key: const Key('chat.menu'),
            onSelected: (v) => _menu(c, v),
            itemBuilder: (context) => [
              PopupMenuItem(value: 'quiz', child: ListTile(leading: const Icon(Icons.quiz_outlined), title: Text(context.tr(TutorStrings.toQuiz)))),
              PopupMenuItem(value: 'notes', child: ListTile(leading: const Icon(Icons.sticky_note_2_outlined), title: Text(context.tr(TutorStrings.toNotes)))),
              PopupMenuItem(value: 'cards', child: ListTile(leading: const Icon(Icons.style_outlined), title: Text(context.tr(TutorStrings.toFlashcards)))),
              PopupMenuItem(value: 'export', child: ListTile(leading: const Icon(Icons.download_outlined), title: Text(context.tr(TutorStrings.export)))),
              PopupMenuItem(value: 'share', child: ListTile(leading: const Icon(Icons.share_outlined), title: Text(context.tr(TutorStrings.share)))),
              const PopupMenuDivider(),
              ...conversationMenu(context, c),
            ],
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(44),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(AppSpacing.md, 0, AppSpacing.md, AppSpacing.sm),
            child: Row(
              children: [
                ActionChip(
                  key: const Key('chat.context'),
                  avatar: const Icon(Icons.school_outlined, size: 16),
                  label: Text(contextLabel(context, ref, c.context)),
                  onPressed: () => _editContext(c),
                ),
                const SizedBox(width: AppSpacing.xs),
                ActionChip(
                  key: const Key('chat.mode'),
                  avatar: Icon(c.context.mode.icon, size: 16),
                  label: Text(context.tr(c.context.mode.label)),
                  onPressed: () => _editContext(c),
                ),
                const SizedBox(width: AppSpacing.xs),
                Chip(avatar: const Icon(Icons.translate, size: 16), label: Text(context.tr(c.context.language.label))),
              ],
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: AppSpacing.maxContentWidth),
                  child: ListView(
                    controller: _scroll,
                    padding: AppSpacing.screen,
                    children: [
                      InfoBanner(message: context.tr(TutorStrings.transparency), tone: Tone.info, icon: Icons.auto_awesome),
                      if (c.context.mode == TeachingMode.boardAnswer) ...[
                        const SizedBox(height: AppSpacing.sm),
                        InfoBanner(message: context.tr(TutorStrings.integrityReminder), tone: Tone.warning, icon: Icons.gavel_outlined),
                      ],
                      const SizedBox(height: AppSpacing.md),
                      if (c.messages.isEmpty)
                        Wrap(
                          spacing: AppSpacing.xs,
                          runSpacing: AppSpacing.xs,
                          children: [
                            for (final s in TutorStrings.suggestions)
                              ActionChip(label: Text(context.tr(s)), onPressed: () => _send(context.tr(s))),
                          ],
                        ),
                      for (var i = 0; i < c.messages.length; i++)
                        MessageBubble(
                          key: ValueKey(c.messages[i].id),
                          conversationId: c.id,
                          message: c.messages[i],
                          isLast: i == c.messages.length - 1,
                          onFollowUp: _send,
                        ),
                    ],
                  ),
                ),
              ),
            ),
            _Composer(
              controller: _input,
              streaming: c.isStreaming,
              onSend: _send,
              onStop: () => ctl.stop(c.id),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _editContext(Conversation c) async {
    final next = await showContextSheet(context, ref, c.context);
    if (next != null) await ref.read(tutorProvider.notifier).setContext(c.id, next);
  }

  Future<void> _menu(Conversation c, String action) async {
    switch (action) {
      case 'quiz':
        final ids = <String>{for (final m in c.messages) ...m.relatedQuestionIds}.toList();
        if (ids.isEmpty) {
          context.showSnack(TutorStrings.quizEmpty);
          return;
        }
        final set = await ref.read(practiceProvider.notifier).createSet('Quiz: ${c.title}', questionIds: ids);
        if (mounted) await context.push(Uri(path: '/practice-session', queryParameters: {'mode': 'set', 'set': set.id}).toString());
      case 'notes':
        final convert = ref.read(conversationToNoteProvider);
        final route = convert == null ? null : await convert(ref, c);
        if (route != null && mounted) await context.push(route);
      case 'cards':
        final convert = ref.read(conversationToFlashcardsProvider);
        final route = convert == null ? null : await convert(ref, c);
        if (route != null && mounted) await context.push(route);
      case 'export':
        await Clipboard.setData(ClipboardData(text: conversationMarkdown(c)));
        if (mounted) context.showSnack(TutorStrings.exportDone);
      case 'share':
        await _share(c);
      default:
        await conversationAction(context, ref, c, action);
    }
  }

  Future<void> _share(Conversation c) async {
    var includeName = false;
    var includeSources = true;
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(context.tr(TutorStrings.shareTitle)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(context.tr(TutorStrings.shareIncludeName)),
                value: includeName,
                onChanged: (v) => setState(() => includeName = v),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(context.tr(TutorStrings.shareIncludeSources)),
                value: includeSources,
                onChanged: (v) => setState(() => includeSources = v),
              ),
              Text(context.tr(TutorStrings.shareNote), style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: Text(context.tr(S.cancel))),
            FilledButton(onPressed: () => Navigator.pop(context, true), child: Text(context.tr(S.copy))),
          ],
        ),
      ),
    );
    if (ok != true) return;
    final name = ref.read(studentProfileProvider).name;
    final link = 'https://edumentor.example/share/${c.id.hashCode.toRadixString(36)}'
        '?n=${includeName && name.isNotEmpty ? 1 : 0}&s=${includeSources ? 1 : 0}';
    await Clipboard.setData(ClipboardData(text: link));
    if (mounted) context.showSnack(TutorStrings.linkCopied);
  }
}

class _Composer extends StatelessWidget {
  const _Composer({required this.controller, required this.streaming, required this.onSend, required this.onStop});

  final TextEditingController controller;
  final bool streaming;
  final ValueChanged<String?> onSend;
  final VoidCallback onStop;

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 3,
      color: context.colors.surfaceContainerLow,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.sm, AppSpacing.sm, AppSpacing.sm),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: TextField(
                key: const Key('chat.input'),
                controller: controller,
                minLines: 1,
                maxLines: 5,
                textInputAction: TextInputAction.send,
                onSubmitted: streaming ? null : (_) => onSend(null),
                decoration: InputDecoration(hintText: context.tr(TutorStrings.askHint)),
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            streaming
                ? IconButton.filledTonal(key: const Key('chat.stop'), tooltip: context.tr(TutorStrings.stop), onPressed: onStop, icon: const Icon(Icons.stop))
                : IconButton.filled(key: const Key('chat.send'), tooltip: context.tr(TutorStrings.send), onPressed: () => onSend(null), icon: const Icon(Icons.send)),
          ],
        ),
      ),
    );
  }
}
