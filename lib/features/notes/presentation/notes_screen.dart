import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../app/router/app_routes.dart';
import '../../../core/l10n/common_strings.dart';
import '../../../core/l10n/tr.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/time_format.dart';
import '../../../shared/widgets/badges.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/feedback.dart';
import '../../../shared/widgets/search_field.dart';
import '../../curriculum/application/curriculum_providers.dart';
import '../../curriculum/domain/curriculum_models.dart';
import '../application/notes_controller.dart';
import '../domain/note.dart';
import '../notes_strings.dart';

/// Notes dashboard: search, folders, tags, favourites, subject filter, create and generate.
class NotesScreen extends ConsumerStatefulWidget {
  const NotesScreen({super.key, this.chapterId});

  final String? chapterId;

  @override
  ConsumerState<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends ConsumerState<NotesScreen> {
  String _query = '';
  String? _folder;
  String? _tag;
  bool _favorites = false;
  late String? _chapter = widget.chapterId;

  @override
  Widget build(BuildContext context) {
    final all = ref.watch(notesProvider);
    final folders = {for (final n in all) ?n.folder}.toList()..sort();
    final tags = {for (final n in all) ...n.tags}.toList()..sort();
    final notes = all.where((n) {
      if (_favorites && !n.favorite) return false;
      if (_folder != null && n.folder != _folder) return false;
      if (_tag != null && !n.tags.contains(_tag)) return false;
      if (_chapter != null && n.chapterId != _chapter) return false;
      if (_query.isNotEmpty) {
        final q = _query.toLowerCase();
        return n.title.toLowerCase().contains(q) || n.body.toLowerCase().contains(q) || n.tags.any((t) => t.contains(q));
      }
      return true;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr(NotesStrings.notes)),
        actions: [
          IconButton(
            key: const Key('notes.generate'),
            tooltip: context.tr(NotesStrings.generate),
            icon: const Icon(Icons.auto_awesome),
            onPressed: () => showGenerateNoteSheet(context, ref, chapterId: _chapter),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        key: const Key('notes.new'),
        onPressed: () async {
          final n = await ref.read(notesProvider.notifier).create(chapterId: _chapter, folder: _folder);
          if (context.mounted) await context.push(AppRoutes.note(n.id));
        },
        icon: const Icon(Icons.edit_note),
        label: Text(context.tr(NotesStrings.newNote)),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: AppSpacing.maxContentWidth),
          child: ListView(
            padding: AppSpacing.screen,
            children: [
              DebouncedSearchField(hint: context.tr(NotesStrings.search), onChanged: (q) => setState(() => _query = q)),
              const SizedBox(height: AppSpacing.sm),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    FilterChip(
                      avatar: const Icon(Icons.star_outline, size: 16),
                      label: Text(context.tr(NotesStrings.favorites)),
                      selected: _favorites,
                      onSelected: (v) => setState(() => _favorites = v),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    if (_chapter != null)
                      Padding(
                        padding: const EdgeInsetsDirectional.only(end: AppSpacing.xs),
                        child: InputChip(label: Text(context.tr(S.chapter)), selected: true, onDeleted: () => setState(() => _chapter = null)),
                      ),
                    for (final f in folders)
                      Padding(
                        padding: const EdgeInsetsDirectional.only(end: AppSpacing.xs),
                        child: ChoiceChip(
                          avatar: const Icon(Icons.folder_outlined, size: 16),
                          label: Text(f),
                          selected: _folder == f,
                          onSelected: (v) => setState(() => _folder = v ? f : null),
                        ),
                      ),
                    for (final t in tags)
                      Padding(
                        padding: const EdgeInsetsDirectional.only(end: AppSpacing.xs),
                        child: ChoiceChip(label: Text('#$t'), selected: _tag == t, onSelected: (v) => setState(() => _tag = v ? t : null)),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              if (all.isEmpty)
                EmptyState(icon: Icons.sticky_note_2_outlined, title: context.tr(NotesStrings.empty), message: context.tr(NotesStrings.emptyHint))
              else if (notes.isEmpty)
                EmptyState(icon: Icons.search_off, title: context.tr(S.noResults), message: context.tr(S.noResultsHint), compact: true)
              else
                for (final n in notes) _NoteCard(note: n),
              const SizedBox(height: 88),
            ],
          ),
        ),
      ),
    );
  }
}

class _NoteCard extends ConsumerWidget {
  const _NoteCard({required this.note});

  final Note note;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final n = note;
    final preview = n.body.replaceAll(RegExp(r'[#*>$\\|`=_-]'), ' ').replaceAll(RegExp(r'\s+'), ' ').trim();
    return Card(
      child: InkWell(
        key: Key('note.${n.id}'),
        onTap: () => context.push(AppRoutes.note(n.id)),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(n.type.icon, size: 20, color: context.colors.primary),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(n.title.isEmpty ? context.tr(NotesStrings.untitled) : n.title, style: context.text.titleSmall, maxLines: 1, overflow: TextOverflow.ellipsis),
                  ),
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    tooltip: context.tr(NotesStrings.favorites),
                    icon: Icon(n.favorite ? Icons.star : Icons.star_outline, color: n.favorite ? context.palette.warning : null),
                    onPressed: () => ref.read(notesProvider.notifier).toggleFavorite(n.id),
                  ),
                ],
              ),
              if (preview.isNotEmpty) Text(preview, maxLines: 2, overflow: TextOverflow.ellipsis, style: context.text.bodySmall),
              const SizedBox(height: AppSpacing.xs),
              Wrap(
                spacing: AppSpacing.xs,
                runSpacing: AppSpacing.xs,
                children: [
                  Pill(context.tr(n.type.label)),
                  if (n.folder != null) Pill(n.folder!, icon: Icons.folder_outlined),
                  for (final t in n.tags) Pill('#$t', tone: Tone.info),
                  if (n.aiGenerated) DemoBadge(label: NotesStrings.aiLabel),
                  Pill(context.tr(NotesStrings.updated.fill({'t': relativeTime(n.updatedAt, context.lang)}))),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Generate-notes sheet: chapter, topic or uploaded file → note type → opens the editor.
Future<void> showGenerateNoteSheet(BuildContext context, WidgetRef ref, {String? chapterId}) async {
  final id = await showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => _GenerateSheet(chapterId: chapterId),
  );
  if (id != null && context.mounted) {
    context.showSnack(NotesStrings.generated);
    await context.push(AppRoutes.note(id));
  }
}

enum _From { chapter, topic, upload }

class _GenerateSheet extends ConsumerStatefulWidget {
  const _GenerateSheet({this.chapterId});

  final String? chapterId;

  @override
  ConsumerState<_GenerateSheet> createState() => _GenerateSheetState();
}

class _GenerateSheetState extends ConsumerState<_GenerateSheet> {
  _From _from = _From.chapter;
  late String? _chapterId = widget.chapterId;
  String? _topicId;
  NoteType _type = NoteType.short;
  bool _busy = false;

  Future<void> _go() async {
    final ctl = ref.read(notesProvider.notifier);
    final lang = context.lang;
    setState(() => _busy = true);
    try {
      // Simulated generation time.
      await Future<void>.delayed(const Duration(milliseconds: 600));
      Note? n;
      switch (_from) {
        case _From.chapter:
          if (_chapterId != null) n = await ctl.generateFromChapter(_chapterId!, _type, lang);
        case _From.topic:
          if (_topicId != null) n = await ctl.generateFromTopic(_topicId!, _type, lang);
        case _From.upload:
          final result = await FilePicker.pickFiles(type: FileType.custom, allowedExtensions: const ['pdf', 'png', 'jpg', 'jpeg', 'txt']);
          final file = result.firstOrNull;
          if (file == null) break;
          if (!const ['pdf', 'png', 'jpg', 'jpeg', 'txt'].contains(file.extension?.toLowerCase())) {
            if (mounted) context.showSnack(NotesStrings.unsupported);
            break;
          }
          final size = file.lengthSync() ?? await file.length() ?? 0;
          if (size > 10 * 1024 * 1024) {
            if (mounted) context.showSnack(NotesStrings.tooLarge);
            break;
          }
          n = await ctl.generateFromUpload(file.name, size, lang);
      }
      if (mounted && n != null) Navigator.pop(context, n.id);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final subjects = ref.watch(mySubjectsProvider).value ?? const <Subject>[];
    final chapters = [for (final s in subjects) for (final c in s.chapters) (s, c)];
    final selected = chapters.where((e) => e.$2.id == _chapterId).firstOrNull;
    final ready = switch (_from) { _From.chapter => _chapterId != null, _From.topic => _topicId != null, _From.upload => true };
    return Padding(
      padding: EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.lg + MediaQuery.viewInsetsOf(context).bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(context.tr(NotesStrings.generateTitle), style: context.text.titleLarge),
          const SizedBox(height: AppSpacing.md),
          SegmentedButton<_From>(
            segments: [
              ButtonSegment(value: _From.chapter, label: Text(context.tr(NotesStrings.fromChapter))),
              ButtonSegment(value: _From.topic, label: Text(context.tr(NotesStrings.fromTopic))),
              ButtonSegment(value: _From.upload, label: Text(context.tr(NotesStrings.fromUpload))),
            ],
            selected: {_from},
            onSelectionChanged: (v) => setState(() => _from = v.first),
          ),
          const SizedBox(height: AppSpacing.md),
          if (_from != _From.upload)
            DropdownButtonFormField<String>(
              key: const Key('gen.chapter'),
              initialValue: _chapterId,
              isExpanded: true,
              decoration: InputDecoration(labelText: context.tr(NotesStrings.chooseChapter)),
              items: [
                for (final (s, c) in chapters)
                  DropdownMenuItem(value: c.id, child: Text('${context.tr(s.name)} · ${context.tr(c.title)}', overflow: TextOverflow.ellipsis)),
              ],
              onChanged: (v) => setState(() {
                _chapterId = v;
                _topicId = null;
              }),
            ),
          if (_from == _From.topic && selected != null) ...[
            const SizedBox(height: AppSpacing.sm),
            DropdownButtonFormField<String>(
              initialValue: _topicId,
              isExpanded: true,
              decoration: InputDecoration(labelText: context.tr(NotesStrings.chooseTopic)),
              items: [for (final t in selected.$2.topics) DropdownMenuItem(value: t.id, child: Text(context.tr(t.title)))],
              onChanged: (v) => setState(() => _topicId = v),
            ),
          ],
          if (_from == _From.upload) InfoBanner(message: context.tr(NotesStrings.uploadNote), tone: Tone.warning),
          if (_from != _From.upload) ...[
            const SizedBox(height: AppSpacing.md),
            Text(context.tr(NotesStrings.noteType), style: context.text.titleSmall),
            const SizedBox(height: AppSpacing.xs),
            Wrap(
              spacing: AppSpacing.xs,
              runSpacing: AppSpacing.xs,
              children: [
                for (final t in NoteType.values.where((t) => t != NoteType.freeform))
                  ChoiceChip(avatar: Icon(t.icon, size: 16), label: Text(context.tr(t.label)), selected: _type == t, onSelected: (_) => setState(() => _type = t)),
              ],
            ),
          ],
          const SizedBox(height: AppSpacing.lg),
          FilledButton.icon(
            key: const Key('gen.go'),
            onPressed: ready && !_busy ? _go : null,
            icon: _busy ? const SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.auto_awesome),
            label: Text(context.tr(_busy ? NotesStrings.generating : (_from == _From.upload ? NotesStrings.pickFile : NotesStrings.generate))),
          ),
        ],
      ),
    );
  }
}
