import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../app/router/app_routes.dart';
import '../../../core/l10n/common_strings.dart';
import '../../../core/l10n/tr.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/time_format.dart';
import '../../../shared/widgets/app_page_scaffold.dart';
import '../../../shared/widgets/badges.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/feedback.dart';
import '../../../shared/widgets/search_field.dart';
import '../../../shared/widgets/section_header.dart';
import '../../curriculum/data/curriculum_repository.dart';
import '../application/tutor_controller.dart';
import '../domain/tutor_models.dart';
import '../tutor_strings.dart';
import 'widgets/tutor_widgets.dart';

enum _Grouping { date, subject, chapter, folder }

/// Tutor tab: conversation history with search, grouping, pin/archive/folders, and quick
/// prompts. Deep links (`?subject=&chapter=&topic=&prompt=`) open a new chat in that context.
class AiTutorScreen extends ConsumerStatefulWidget {
  const AiTutorScreen({super.key});

  @override
  ConsumerState<AiTutorScreen> createState() => _AiTutorScreenState();
}

class _AiTutorScreenState extends ConsumerState<AiTutorScreen> {
  String _query = '';
  bool _showArchived = false;
  _Grouping _grouping = _Grouping.date;
  String? _handledLink;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final params = GoRouterState.of(context).uri.queryParameters;
    final key = params.toString();
    if (params.isNotEmpty && key != _handledLink) {
      _handledLink = key;
      WidgetsBinding.instance.addPostFrameCallback((_) => _openFromLink(params));
    }
  }

  Future<void> _openFromLink(Map<String, String> params) async {
    final ctl = ref.read(tutorProvider.notifier);
    final ctx = ctl.defaultContext().copyWith(
      subjectId: () => params['subject'],
      chapterId: () => params['chapter'],
      topicId: () => params['topic'],
    );
    final c = await ctl.create(context: ctx);
    if (!mounted) return;
    context.go(Uri(path: AppRoutes.tutorChat(c.id), queryParameters: {if (params['prompt'] != null) 'prompt': params['prompt']!}).toString());
  }

  Future<void> _newChat([String? prompt]) async {
    final c = await ref.read(tutorProvider.notifier).create();
    if (!mounted) return;
    await context.push(Uri(path: AppRoutes.tutorChat(c.id), queryParameters: {'prompt': ?prompt}).toString());
  }

  @override
  Widget build(BuildContext context) {
    final all = ref.watch(tutorProvider);
    final repo = ref.watch(curriculumRepositoryProvider);
    final visible = all.where((c) => c.archived == _showArchived && c.messages.isNotEmpty).where((c) {
      if (_query.isEmpty) return true;
      final q = _query.toLowerCase();
      return c.title.toLowerCase().contains(q) || c.messages.any((m) => m.text.toLowerCase().contains(q));
    }).toList();
    final pinned = visible.where((c) => c.pinned).toList();
    final rest = visible.where((c) => !c.pinned).toList();

    String groupOf(Conversation c) => switch (_grouping) {
      _Grouping.date => _dateBucket(context, c.updatedAt),
      _Grouping.subject => c.context.subjectId == null
          ? context.tr(TutorStrings.general)
          : context.tr(repo.cachedSubjects.where((s) => s.id == c.context.subjectId).firstOrNull?.name ?? TutorStrings.general),
      _Grouping.chapter => c.context.chapterId == null
          ? context.tr(TutorStrings.general)
          : context.tr(repo.findChapter(c.context.chapterId!)?.chapter.title ?? TutorStrings.general),
      _Grouping.folder => c.folder ?? context.tr(TutorStrings.noFolder),
    };
    final groups = <String, List<Conversation>>{};
    for (final c in rest) {
      groups.putIfAbsent(groupOf(c), () => []).add(c);
    }
    final bookmarks = ref.read(tutorProvider.notifier).bookmarkedAnswers;

    return AppPageScaffold(
      title: context.tr(TutorStrings.tutor),
      actions: [
        IconButton(
          tooltip: context.tr(TutorStrings.voiceTutorTooltip),
          icon: const Icon(Icons.mic_none),
          onPressed: () => context.push(AppRoutes.voiceTutor),
        ),
      ],
      floatingActionButton: FloatingActionButton.extended(
        key: const Key('tutor.new'),
        onPressed: _newChat,
        icon: const Icon(Icons.add_comment_outlined),
        label: Text(context.tr(TutorStrings.newChat)),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InfoBanner(message: context.tr(TutorStrings.transparency), tone: Tone.info, icon: Icons.auto_awesome),
          const SizedBox(height: AppSpacing.md),
          DebouncedSearchField(hint: context.tr(TutorStrings.searchChats), onChanged: (q) => setState(() => _query = q)),
          const SizedBox(height: AppSpacing.sm),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final g in _Grouping.values)
                  Padding(
                    padding: const EdgeInsetsDirectional.only(end: AppSpacing.xs),
                    child: ChoiceChip(
                      label: Text(context.tr(switch (g) {
                        _Grouping.date => TutorStrings.byDate,
                        _Grouping.subject => TutorStrings.bySubject,
                        _Grouping.chapter => TutorStrings.byChapter,
                        _Grouping.folder => TutorStrings.byFolder,
                      })),
                      selected: _grouping == g,
                      onSelected: (_) => setState(() => _grouping = g),
                    ),
                  ),
                FilterChip(
                  avatar: const Icon(Icons.archive_outlined, size: 16),
                  label: Text(context.tr(TutorStrings.archived)),
                  selected: _showArchived,
                  onSelected: (v) => setState(() => _showArchived = v),
                ),
              ],
            ),
          ),
          if (all.where((c) => c.messages.isNotEmpty).isEmpty) ...[
            EmptyState(icon: Icons.smart_toy_outlined, title: context.tr(TutorStrings.emptyTitle), message: context.tr(TutorStrings.emptyHint)),
          ] else if (visible.isEmpty)
            EmptyState(icon: Icons.search_off, title: context.tr(S.noResults), compact: true),
          if (_query.isEmpty && !_showArchived) ...[
            SectionHeader(title: context.tr(const Tr('এগুলো জিজ্ঞেস করে দেখো', 'Try asking'))),
            Wrap(
              spacing: AppSpacing.xs,
              runSpacing: AppSpacing.xs,
              children: [
                for (final s in TutorStrings.suggestions)
                  ActionChip(avatar: const Icon(Icons.auto_awesome, size: 16), label: Text(context.tr(s)), onPressed: () => _newChat(context.tr(s))),
              ],
            ),
          ],
          if (pinned.isNotEmpty) ...[
            SectionHeader(title: context.tr(TutorStrings.pinned)),
            for (final c in pinned) _ConversationTile(conversation: c),
          ],
          for (final e in groups.entries) ...[
            SectionHeader(title: e.key),
            for (final c in e.value) _ConversationTile(conversation: c),
          ],
          if (bookmarks.isNotEmpty && _query.isEmpty) ...[
            SectionHeader(title: context.tr(TutorStrings.bookmarkedAnswers)),
            for (final (c, m) in bookmarks.take(5))
              Card(
                child: ListTile(
                  leading: const Icon(Icons.bookmark),
                  title: Text(m.text.replaceAll(RegExp(r'[#*>$\\|`=]'), '').trim(), maxLines: 2, overflow: TextOverflow.ellipsis),
                  subtitle: Text(c.title, maxLines: 1, overflow: TextOverflow.ellipsis),
                  onTap: () => context.push(AppRoutes.tutorChat(c.id)),
                ),
              ),
          ],
          const SizedBox(height: 88),
        ],
      ),
    );
  }

  String _dateBucket(BuildContext context, DateTime t) {
    final now = DateTime.now();
    final days = DateTime(now.year, now.month, now.day).difference(DateTime(t.year, t.month, t.day)).inDays;
    if (days == 0) return context.tr(S.today);
    if (days == 1) return context.tr(S.yesterday);
    if (days < 7) return context.tr(const Tr('এই সপ্তাহে', 'This week'));
    return context.tr(const Tr('আগে', 'Earlier'));
  }
}

class _ConversationTile extends ConsumerWidget {
  const _ConversationTile({required this.conversation});

  final Conversation conversation;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = conversation;
    final ctl = ref.read(tutorProvider.notifier);
    return Card(
      child: ListTile(
        key: Key('conv.${c.id}'),
        leading: Icon(c.context.mode.icon, color: context.colors.primary),
        title: Text(c.title.isEmpty ? context.tr(TutorStrings.newChat) : c.title, maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: Text(
          '${contextLabel(context, ref, c.context)} · ${relativeTime(c.updatedAt, context.lang)}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        onTap: () => context.push(AppRoutes.tutorChat(c.id)),
        trailing: PopupMenuButton<String>(
          onSelected: (v) => conversationAction(context, ref, c, v),
          itemBuilder: (context) => conversationMenu(context, c),
        ),
        onLongPress: () => ctl.togglePin(c.id),
      ),
    );
  }
}

List<PopupMenuEntry<String>> conversationMenu(BuildContext context, Conversation c) => [
  PopupMenuItem(value: 'rename', child: ListTile(leading: const Icon(Icons.edit_outlined), title: Text(context.tr(S.rename)))),
  PopupMenuItem(value: 'pin', child: ListTile(leading: Icon(c.pinned ? Icons.push_pin : Icons.push_pin_outlined), title: Text(context.tr(c.pinned ? S.unpin : S.pin)))),
  PopupMenuItem(value: 'folder', child: ListTile(leading: const Icon(Icons.folder_outlined), title: Text(context.tr(TutorStrings.moveToFolder)))),
  PopupMenuItem(value: 'archive', child: ListTile(leading: const Icon(Icons.archive_outlined), title: Text(context.tr(c.archived ? const Tr('আর্কাইভ থেকে সরাও', 'Unarchive') : S.archive)))),
  PopupMenuItem(value: 'delete', child: ListTile(leading: const Icon(Icons.delete_outline), title: Text(context.tr(S.delete)))),
];

Future<void> conversationAction(BuildContext context, WidgetRef ref, Conversation c, String action) async {
  final ctl = ref.read(tutorProvider.notifier);
  switch (action) {
    case 'rename':
      final name = await showTextInputDialog(context, title: S.rename, initial: c.title);
      if (name != null) await ctl.rename(c.id, name);
    case 'pin':
      await ctl.togglePin(c.id);
    case 'folder':
      final folders = {for (final x in ref.read(tutorProvider)) ?x.folder}.toList();
      if (!context.mounted) return;
      final picked = await showModalBottomSheet<String>(
        context: context,
        showDragHandle: true,
        builder: (context) => ListView(
          shrinkWrap: true,
          children: [
            ListTile(leading: const Icon(Icons.create_new_folder_outlined), title: Text(context.tr(const Tr('নতুন ফোল্ডার', 'New folder'))), onTap: () => Navigator.pop(context, '\u0000new')),
            ListTile(leading: const Icon(Icons.folder_off_outlined), title: Text(context.tr(TutorStrings.noFolder)), onTap: () => Navigator.pop(context, '')),
            for (final f in folders) ListTile(leading: const Icon(Icons.folder_outlined), title: Text(f), onTap: () => Navigator.pop(context, f)),
          ],
        ),
      );
      if (picked == null || !context.mounted) return;
      if (picked == '\u0000new') {
        final name = await showTextInputDialog(context, title: TutorStrings.moveToFolder, label: TutorStrings.folderName);
        if (name != null) await ctl.setFolder(c.id, name);
      } else {
        await ctl.setFolder(c.id, picked.isEmpty ? null : picked);
      }
    case 'archive':
      await ctl.toggleArchive(c.id);
    case 'delete':
      final ok = await showConfirmDialog(context, title: TutorStrings.deleteChat, message: S.cannotUndo, destructive: true, confirmLabel: S.delete);
      if (ok) {
        await ctl.delete(c.id);
        if (context.mounted && GoRouterState.of(context).uri.path.contains('/chat/')) context.pop();
      }
  }
}
