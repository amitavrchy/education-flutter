import 'dart:async';

import 'package:flutter/services.dart';
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
import '../../../shared/widgets/rich_content.dart';
import '../../flashcards/application/flashcards_controller.dart';
import '../../flashcards/flashcard_strings.dart';
import '../application/notes_controller.dart';
import '../domain/note.dart';
import '../notes_strings.dart';

/// Markdown editor with formatting toolbar, live preview, autosave, folder, tags, favourite,
/// linked notes, version history and a printable layout.
class NoteEditorScreen extends ConsumerStatefulWidget {
  const NoteEditorScreen({super.key, required this.noteId});

  final String noteId;

  @override
  ConsumerState<NoteEditorScreen> createState() => _NoteEditorScreenState();
}

class _NoteEditorScreenState extends ConsumerState<NoteEditorScreen> {
  late final Note? _initial = ref.read(notesProvider.notifier).byId(widget.noteId);
  late final _title = TextEditingController(text: _initial?.title ?? '');
  late final _body = TextEditingController(text: _initial?.body ?? '');
  late bool _preview = (_initial?.body.isNotEmpty ?? false) && (_initial?.aiGenerated ?? false);
  Timer? _debounce;
  bool _dirty = false;

  NotesController get _ctl => ref.read(notesProvider.notifier);

  @override
  void dispose() {
    _debounce?.cancel();
    if (_dirty) _ctl.save(widget.noteId, title: _title.text, body: _body.text, snapshot: true);
    _title.dispose();
    _body.dispose();
    super.dispose();
  }

  void _changed() {
    setState(() => _dirty = true);
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 600), () async {
      await _ctl.save(widget.noteId, title: _title.text, body: _body.text);
      if (mounted) setState(() => _dirty = false);
    });
  }

  void _wrap(String before, [String after = '']) {
    final sel = _body.selection;
    final text = _body.text;
    final start = sel.isValid ? sel.start : text.length;
    final end = sel.isValid ? sel.end : text.length;
    final inner = text.substring(start, end);
    _body.value = TextEditingValue(
      text: text.replaceRange(start, end, '$before$inner$after'),
      selection: TextSelection.collapsed(offset: start + before.length + inner.length),
    );
    _changed();
  }

  void _linePrefix(String prefix) {
    final sel = _body.selection;
    final text = _body.text;
    final pos = sel.isValid ? sel.start : text.length;
    final lineStart = text.lastIndexOf('\n', pos == 0 ? 0 : pos - 1) + 1;
    _body.value = TextEditingValue(
      text: text.replaceRange(lineStart, lineStart, prefix),
      selection: TextSelection.collapsed(offset: pos + prefix.length),
    );
    _changed();
  }

  @override
  Widget build(BuildContext context) {
    final note = ref.watch(notesProvider.select((l) => l.where((n) => n.id == widget.noteId).firstOrNull));
    if (note == null) {
      return Scaffold(appBar: AppBar(), body: EmptyState(icon: Icons.search_off, title: context.tr(S.notFound)));
    }
    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr(_dirty ? NotesStrings.saving : NotesStrings.saved), style: context.text.labelLarge),
        actions: [
          IconButton(
            tooltip: context.tr(NotesStrings.favorites),
            icon: Icon(note.favorite ? Icons.star : Icons.star_outline, color: note.favorite ? context.palette.warning : null),
            onPressed: () => _ctl.toggleFavorite(note.id),
          ),
          IconButton(
            key: const Key('note.preview'),
            tooltip: context.tr(_preview ? NotesStrings.edit : NotesStrings.preview),
            icon: Icon(_preview ? Icons.edit_outlined : Icons.visibility_outlined),
            onPressed: () => setState(() => _preview = !_preview),
          ),
          PopupMenuButton<String>(
            onSelected: (v) => _menu(note, v),
            itemBuilder: (context) => [
              PopupMenuItem(value: 'folder', child: ListTile(leading: const Icon(Icons.folder_outlined), title: Text(context.tr(NotesStrings.folder)))),
              PopupMenuItem(value: 'tags', child: ListTile(leading: const Icon(Icons.sell_outlined), title: Text(context.tr(NotesStrings.tags)))),
              PopupMenuItem(value: 'link', child: ListTile(leading: const Icon(Icons.link), title: Text(context.tr(NotesStrings.linkNote)))),
              PopupMenuItem(value: 'history', child: ListTile(leading: const Icon(Icons.history), title: Text(context.tr(NotesStrings.history)))),
              PopupMenuItem(value: 'cards', child: ListTile(leading: const Icon(Icons.style_outlined), title: Text(context.tr(NotesStrings.fromNote)))),
              PopupMenuItem(value: 'copy', child: ListTile(leading: const Icon(Icons.copy), title: Text(context.tr(S.copy)))),
              PopupMenuItem(value: 'print', child: ListTile(leading: const Icon(Icons.picture_as_pdf_outlined), title: Text(context.tr(NotesStrings.exportPdf)))),
              PopupMenuItem(value: 'delete', child: ListTile(leading: const Icon(Icons.delete_outline), title: Text(context.tr(S.delete)))),
            ],
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: AppSpacing.maxContentWidth),
            child: Column(
              children: [
                Expanded(
                  child: ListView(
                    padding: AppSpacing.screen,
                    children: [
                      TextField(
                        key: const Key('note.title'),
                        controller: _title,
                        style: context.text.headlineSmall,
                        decoration: InputDecoration(hintText: context.tr(NotesStrings.titleHint), border: InputBorder.none, filled: false),
                        onChanged: (_) => _changed(),
                      ),
                      Wrap(
                        spacing: AppSpacing.xs,
                        runSpacing: AppSpacing.xs,
                        children: [
                          Pill(context.tr(note.type.label), icon: note.type.icon),
                          Pill(context.tr(note.source.label)),
                          if (note.folder != null) Pill(note.folder!, icon: Icons.folder_outlined),
                          for (final t in note.tags) Pill('#$t', tone: Tone.info),
                          if (note.aiGenerated) DemoBadge(label: NotesStrings.aiLabel),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.md),
                      if (_preview)
                        RichContent(_body.text.isEmpty ? '_${context.tr(NotesStrings.bodyHint)}_' : _body.text, selectable: true)
                      else
                        TextField(
                          key: const Key('note.body'),
                          controller: _body,
                          minLines: 14,
                          maxLines: null,
                          keyboardType: TextInputType.multiline,
                          decoration: InputDecoration(hintText: context.tr(NotesStrings.bodyHint)),
                          onChanged: (_) => _changed(),
                        ),
                      if (note.linkedIds.isNotEmpty) ...[
                        const SizedBox(height: AppSpacing.lg),
                        Text(context.tr(NotesStrings.linked), style: context.text.titleSmall),
                        for (final id in note.linkedIds)
                          if (ref.read(notesProvider.notifier).byId(id) case final other?)
                            ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: const Icon(Icons.link),
                              title: Text(other.title.isEmpty ? context.tr(NotesStrings.untitled) : other.title),
                              trailing: IconButton(icon: const Icon(Icons.link_off), onPressed: () => _ctl.unlink(note.id, id)),
                              onTap: () => context.pushReplacement(AppRoutes.note(id)),
                            ),
                      ],
                    ],
                  ),
                ),
                if (!_preview)
                  Material(
                    color: context.colors.surfaceContainer,
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          IconButton(tooltip: 'Heading', icon: const Icon(Icons.title), onPressed: () => _linePrefix('## ')),
                          IconButton(tooltip: 'Bold', icon: const Icon(Icons.format_bold), onPressed: () => _wrap('**', '**')),
                          IconButton(tooltip: 'Italic', icon: const Icon(Icons.format_italic), onPressed: () => _wrap('*', '*')),
                          IconButton(tooltip: 'Highlight', icon: const Icon(Icons.highlight), onPressed: () => _wrap('==', '==')),
                          IconButton(tooltip: 'Bullet list', icon: const Icon(Icons.format_list_bulleted), onPressed: () => _linePrefix('- ')),
                          IconButton(tooltip: 'Numbered list', icon: const Icon(Icons.format_list_numbered), onPressed: () => _linePrefix('1. ')),
                          IconButton(tooltip: 'Quote', icon: const Icon(Icons.format_quote), onPressed: () => _linePrefix('> ')),
                          IconButton(tooltip: 'Math', icon: const Icon(Icons.functions), onPressed: () => _wrap(r'$', r'$')),
                          IconButton(tooltip: 'Table', icon: const Icon(Icons.table_chart_outlined), onPressed: () => _wrap('\n| A | B |\n|---|---|\n| 1 | 2 |\n')),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _menu(Note note, String action) async {
    switch (action) {
      case 'folder':
        final name = await showTextInputDialog(context, title: NotesStrings.folder, initial: note.folder ?? '');
        if (name != null) await _ctl.setFolder(note.id, name.isEmpty ? null : name);
      case 'tags':
        final controller = TextEditingController(text: note.tags.join(', '));
        final value = await showDialog<String>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(context.tr(NotesStrings.tags)),
            content: TextField(controller: controller, autofocus: true, decoration: InputDecoration(helperText: context.tr(NotesStrings.tagsHint))),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: Text(context.tr(S.cancel))),
              FilledButton(onPressed: () => Navigator.pop(context, controller.text), child: Text(context.tr(S.save))),
            ],
          ),
        );
        if (value != null) await _ctl.setTags(note.id, value.split(','));
      case 'link':
        final others = ref.read(notesProvider).where((n) => n.id != note.id && !note.linkedIds.contains(n.id)).toList();
        final picked = await showModalBottomSheet<String>(
          context: context,
          showDragHandle: true,
          builder: (context) => ListView(
            shrinkWrap: true,
            children: [
              for (final n in others)
                ListTile(leading: Icon(n.type.icon), title: Text(n.title.isEmpty ? context.tr(NotesStrings.untitled) : n.title), onTap: () => Navigator.pop(context, n.id)),
            ],
          ),
        );
        if (picked != null) await _ctl.link(note.id, picked);
      case 'history':
        await _showHistory(note);
      case 'cards':
        await _ctl.save(note.id, title: _title.text, body: _body.text);
        final deck = await ref.read(flashcardsProvider.notifier).generateFromNote(_ctl.byId(note.id)!);
        if (!mounted) return;
        if (deck == null) {
          context.showSnack(FcStrings.noCardsGenerated);
        } else {
          await context.push('/flashcards/deck/${deck.id}');
        }
      case 'copy':
        await Clipboard.setData(ClipboardData(text: '# ${_title.text}\n\n${_body.text}'));
        if (mounted) context.showSnack(S.copied);
      case 'print':
        await Navigator.of(context).push(MaterialPageRoute<void>(
          fullscreenDialog: true,
          builder: (_) => _PrintableNote(title: _title.text, body: _body.text),
        ));
      case 'delete':
        final ok = await showConfirmDialog(context, title: NotesStrings.deleteConfirm, destructive: true, confirmLabel: S.delete);
        if (ok) {
          _dirty = false;
          await _ctl.delete(note.id);
          if (mounted) context.pop();
        }
    }
  }

  Future<void> _showHistory(Note note) => showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (context) => DraggableScrollableSheet(
      expand: false,
      builder: (context, controller) => ListView(
        controller: controller,
        padding: AppSpacing.screen,
        children: [
          Text(context.tr(NotesStrings.history), style: context.text.titleLarge),
          if (note.history.isEmpty) EmptyState(icon: Icons.history, title: context.tr(NotesStrings.noHistory), compact: true),
          for (final v in note.history)
            Card(
              child: ExpansionTile(
                title: Text(v.title.isEmpty ? context.tr(NotesStrings.untitled) : v.title),
                subtitle: Text(relativeTime(v.at, context.lang)),
                childrenPadding: const EdgeInsets.all(AppSpacing.md),
                children: [
                  RichContent(v.body),
                  Align(
                    alignment: AlignmentDirectional.centerEnd,
                    child: FilledButton.tonal(
                      onPressed: () async {
                        await _ctl.restore(note.id, v);
                        _title.text = v.title;
                        _body.text = v.body;
                        if (context.mounted) {
                          Navigator.pop(context);
                          context.showSnack(NotesStrings.restored);
                        }
                      },
                      child: Text(context.tr(NotesStrings.restore)),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    ),
  );
}

class _PrintableNote extends StatelessWidget {
  const _PrintableNote({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) => Theme(
    data: ThemeData(brightness: Brightness.light, colorSchemeSeed: Colors.grey, useMaterial3: true),
    child: Builder(
      builder: (context) => Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(title: Text(context.tr(NotesStrings.exportPdf))),
        body: ListView(
          padding: const EdgeInsets.all(AppSpacing.xl),
          children: [
            Text(context.tr(NotesStrings.printNote), style: Theme.of(context).textTheme.bodySmall),
            const Divider(height: AppSpacing.xl),
            Text(title, style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: AppSpacing.md),
            RichContent(body),
          ],
        ),
      ),
    ),
  );
}
