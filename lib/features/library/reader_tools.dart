import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/router/app_routes.dart';
import '../../core/l10n/common_strings.dart';
import '../../core/l10n/tr.dart';
import '../../core/theme/app_spacing.dart';
import '../../shared/widgets/feedback.dart';
import '../../shared/widgets/section_header.dart';
import '../book_avatar/data/book_catalog.dart';
import '../notes/application/notes_controller.dart';
import '../question_bank/data/question_repository.dart';
import 'library_controller.dart';

/// Strips rich-text markup and splits a page into sentences the student can pick.
List<String> pageSentences(String body) {
  final plain = body.replaceAll(RegExp(r'\$\$[^$]*\$\$'), ' ').replaceAll(RegExp(r'[*=`]'), '');
  return [
    for (final s in plain.split(RegExp(r'(?<=[।.!?])\s+|\n+')))
      if (s.trim().length >= 12) s.trim(),
  ];
}

/// Wraps each highlight in `==…==` so [RichContent] renders it highlighted.
String withHighlights(String body, List<Highlight> highlights) {
  var out = body;
  for (final h in highlights) {
    if (out.contains(h.text)) out = out.replaceFirst(h.text, '==${h.text}==');
  }
  return out;
}

/// Note on one page (LIB-18).
class PageNoteSheet extends ConsumerStatefulWidget {
  const PageNoteSheet({super.key, required this.bookId, required this.page});

  final String bookId;
  final int page;

  @override
  ConsumerState<PageNoteSheet> createState() => _PageNoteSheetState();
}

class _PageNoteSheetState extends ConsumerState<PageNoteSheet> {
  late final _c = TextEditingController(text: ref.read(libraryProvider.notifier).of(widget.bookId).notes[widget.page] ?? '');

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, MediaQuery.viewInsetsOf(context).bottom + AppSpacing.lg),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('${context.tr(LibraryStrings.pageNote)} · ${context.tr(LibraryStrings.page.fill({'n': widget.page}))}', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: AppSpacing.sm),
        TextField(key: const Key('reader.noteInput'), controller: _c, maxLines: 5, autofocus: true, decoration: InputDecoration(hintText: context.tr(LibraryStrings.noteHint))),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            if (_c.text.isNotEmpty)
              TextButton(
                onPressed: () async {
                  await ref.read(libraryProvider.notifier).setNote(widget.bookId, widget.page, '');
                  if (context.mounted) Navigator.pop(context);
                },
                child: Text(context.tr(S.delete)),
              ),
            const Spacer(),
            FilledButton(
              key: const Key('reader.noteSave'),
              onPressed: () async {
                await ref.read(libraryProvider.notifier).setNote(widget.bookId, widget.page, _c.text);
                if (context.mounted) {
                  Navigator.pop(context);
                  context.showSnack(LibraryStrings.noteSaved);
                }
              },
              child: Text(context.tr(S.save)),
            ),
          ],
        ),
      ],
    ),
  );
}

/// Pick a sentence to highlight (LIB-19) or explain with the AI tutor (LIB-20).
class PassageSheet extends ConsumerWidget {
  const PassageSheet({super.key, required this.book, required this.page});

  final Book book;
  final BookPage page;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sentences = pageSentences(context.tr(page.body));
    final marked = {for (final h in ref.watch(libraryProvider)[book.id]?.highlightsOn(page.page) ?? const <Highlight>[]) h.text};
    final lib = ref.read(libraryProvider.notifier);
    return SizedBox(
      height: MediaQuery.sizeOf(context).height * 0.7,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.lg),
        children: [
          Text(context.tr(LibraryStrings.selectPassage), style: Theme.of(context).textTheme.titleMedium),
          Text(context.tr(LibraryStrings.selectHint), style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: AppSpacing.sm),
          for (final (i, s) in sentences.indexed)
            Card(
              color: marked.contains(s) ? Colors.amber.withValues(alpha: 0.25) : null,
              margin: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.sm),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(s),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton.icon(
                          key: Key('passage.hl.$i'),
                          onPressed: () async {
                            if (marked.contains(s)) {
                              await lib.removeHighlight(book.id, Highlight(page.page, s, DateTime.now()));
                            } else {
                              await lib.addHighlight(book.id, page.page, s);
                              if (context.mounted) context.showSnack(LibraryStrings.highlighted);
                            }
                          },
                          icon: Icon(marked.contains(s) ? Icons.format_color_reset : Icons.format_color_fill),
                          label: Text(context.tr(marked.contains(s) ? S.delete : LibraryStrings.highlight)),
                        ),
                        TextButton.icon(
                          key: Key('passage.ai.$i'),
                          onPressed: () {
                            Navigator.pop(context);
                            context.go(AppRoutes.tutor(
                              subjectId: book.subject.id,
                              chapterId: page.chapterId,
                              prompt: context.isBangla ? 'এই অংশটি সহজ করে ব্যাখ্যা করো: "$s"' : 'Explain this passage simply: "$s"',
                            ));
                          },
                          icon: const Icon(Icons.auto_awesome_outlined),
                          label: Text(context.tr(LibraryStrings.explain)),
                        ),
                      ],
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

/// Related questions (LIB-22), related notes (LIB-23) and chapter resources (LIB-24).
class RelatedSheet extends ConsumerWidget {
  const RelatedSheet({super.key, required this.book, required this.page});

  final Book book;
  final BookPage page;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final questions = [for (final q in ref.watch(questionRepositoryProvider).cached) if (q.chapterId == page.chapterId) q].take(5).toList();
    final notes = [for (final n in ref.watch(notesProvider)) if (n.chapterId == page.chapterId) n];
    final chapter = book.chapter(page.chapterId);
    void go(String route, {bool tab = false}) {
      Navigator.pop(context);
      tab ? context.go(route) : context.push(route);
    }

    final none = Text(context.tr(LibraryStrings.noRelated), style: Theme.of(context).textTheme.bodySmall);
    return SizedBox(
      height: MediaQuery.sizeOf(context).height * 0.75,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.lg),
        children: [
          Text(context.tr(page.chapterTitle), style: Theme.of(context).textTheme.titleMedium),
          SectionHeader(title: context.tr(LibraryStrings.relatedQuestions)),
          if (questions.isEmpty) none,
          for (final q in questions)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(q.type.icon),
              title: Text(context.tr(q.stem), maxLines: 2, overflow: TextOverflow.ellipsis),
              subtitle: Text(context.tr(q.type.label)),
              onTap: () => go(AppRoutes.question(q.id), tab: true),
            ),
          SectionHeader(title: context.tr(LibraryStrings.relatedNotes)),
          if (notes.isEmpty) none,
          for (final n in notes.take(5)) ListTile(contentPadding: EdgeInsets.zero, leading: const Icon(Icons.sticky_note_2_outlined), title: Text(n.title), onTap: () => go(AppRoutes.note(n.id))),
          SectionHeader(title: context.tr(LibraryStrings.resources)),
          ListTile(contentPadding: EdgeInsets.zero, leading: const Icon(Icons.menu_book_outlined), title: Text(context.tr(LibraryStrings.lesson)), onTap: () => go(AppRoutes.chapter(page.chapterId), tab: true)),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.quiz_outlined),
            title: Text(context.tr(LibraryStrings.practiseChapter)),
            onTap: () => go(AppRoutes.practiceSession(subjectId: book.subject.id, chapterId: page.chapterId)),
          ),
          ListTile(contentPadding: EdgeInsets.zero, leading: const Icon(Icons.style_outlined), title: Text(context.tr(LibraryStrings.flashcards)), onTap: () => go(AppRoutes.flashcards(chapterId: page.chapterId))),
          ListTile(contentPadding: EdgeInsets.zero, leading: const Icon(Icons.headphones_outlined), title: Text(context.tr(LibraryStrings.audio)), onTap: () => go(AppRoutes.audio)),
          if (chapter?.hasLab ?? false) ListTile(contentPadding: EdgeInsets.zero, leading: const Icon(Icons.science_outlined), title: Text(context.tr(LibraryStrings.lab)), onTap: () => go(AppRoutes.labs)),
        ],
      ),
    );
  }
}
