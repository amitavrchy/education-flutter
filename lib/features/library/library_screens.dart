import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/router/app_routes.dart';
import '../../core/l10n/tr.dart';
import '../../core/settings/app_settings.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/time_format.dart';
import '../../shared/widgets/app_page_scaffold.dart';
import '../../shared/widgets/badges.dart';
import '../../shared/widgets/cards.dart';
import '../../shared/widgets/empty_state.dart';
import '../../shared/widgets/error_view.dart';
import '../../shared/widgets/feedback.dart';
import '../../shared/widgets/rich_content.dart';
import '../../shared/widgets/section_header.dart';
import '../book_avatar/data/book_catalog.dart';
import '../curriculum/domain/curriculum_models.dart';
import '../../mock/seed/curriculum_seed.dart';
import '../account/account_controller.dart';
import '../profile/application/student_profile_controller.dart';
import 'library_controller.dart';
import 'reader_tools.dart';

/// Edition a sample book follows. A few older-edition books show the version warning (LIB-27).
String bookEdition(Book b) => b.subject.id.contains('ict') || b.subject.id.contains('bgs') ? 'nctb-2013' : 'nctb-2025';

/// Academic year printed on the sample book (LIB-07).
int bookYear(Book b) => b.level == EducationLevel.ssc ? 2026 : 2025;

/// Content permission: older editions are read-online only (LIB-25).
bool downloadAllowed(Book b) => bookEdition(b) == 'nctb-2025';

/// Browse and filter the sample textbooks (LIB-01..07).
class LibraryScreen extends ConsumerStatefulWidget {
  const LibraryScreen({super.key});

  @override
  ConsumerState<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends ConsumerState<LibraryScreen> {
  String _q = '';
  EducationLevel? _level;
  String? _subject;
  String? _edition;
  String? _language;
  int? _year;
  bool _downloadedOnly = false;

  int get _active => [_level, _subject, _edition, _language, _year].where((x) => x != null).length + (_downloadedOnly ? 1 : 0);

  Future<void> _filters() async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, set) {
          void update(VoidCallback f) {
            setState(f);
            set(() {});
          }

          Widget chips<T>(Tr title, List<T?> options, T? value, String Function(T?) label, void Function(T?) onPick) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(ctx.tr(title), style: Theme.of(ctx).textTheme.labelLarge),
              Wrap(
                spacing: AppSpacing.xs,
                children: [for (final o in options) ChoiceChip(label: Text(label(o)), selected: value == o, onSelected: (_) => update(() => onPick(o)))],
              ),
              const SizedBox(height: AppSpacing.sm),
            ],
          );
          final subjects = {for (final b in sampleBooks) if (_level == null || b.level == _level) b.subject};
          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                chips<EducationLevel>(LibraryStrings.classFilter, [null, ...EducationLevel.values], _level, (o) => o == null ? ctx.tr(LibraryStrings.all) : '${o.code} (${o.classes.map(ctx.n).join('–')})', (o) => _level = o),
                Text(ctx.tr(LibraryStrings.subjectFilter), style: Theme.of(ctx).textTheme.labelLarge),
                DropdownButton<String?>(
                  isExpanded: true,
                  value: subjects.any((x) => x.id == _subject) ? _subject : null,
                  items: [
                    DropdownMenuItem(child: Text(ctx.tr(LibraryStrings.all))),
                    for (final x in subjects) DropdownMenuItem(value: x.id, child: Text(ctx.tr(x.name))),
                  ],
                  onChanged: (v) => update(() => _subject = v),
                ),
                const SizedBox(height: AppSpacing.sm),
                chips<String>(LibraryStrings.curriculumFilter, [null, for (final v in curriculumVersions) v.id], _edition, (o) => o == null ? ctx.tr(LibraryStrings.all) : ctx.tr(curriculumVersions.firstWhere((v) => v.id == o).name), (o) => _edition = o),
                chips<String>(LibraryStrings.languageFilter, const [null, 'bn', 'en'], _language, (o) => switch (o) {
                  null => ctx.tr(LibraryStrings.all),
                  'en' => 'English',
                  _ => 'বাংলা',
                }, (o) => _language = o),
                chips<int>(LibraryStrings.yearFilter, const [null, 2026, 2025], _year, (o) => o == null ? ctx.tr(LibraryStrings.all) : ctx.n(o), (o) => _year = o),
                SwitchListTile(contentPadding: EdgeInsets.zero, title: Text(ctx.tr(LibraryStrings.downloaded)), value: _downloadedOnly, onChanged: (v) => update(() => _downloadedOnly = v)),
                TextButton(
                  onPressed: () => update(() {
                    _level = null;
                    _subject = null;
                    _edition = null;
                    _language = null;
                    _year = null;
                    _downloadedOnly = false;
                  }),
                  child: Text(ctx.tr(LibraryStrings.clearFilters)),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final reading = ref.watch(libraryProvider);
    final q = _q.trim().toLowerCase();
    final books = [
      for (final b in sampleBooks)
        if ((q.isEmpty || b.title.matches(q) || b.subject.name.matches(q)) &&
            (_level == null || b.level == _level) &&
            (_subject == null || b.subject.id == _subject) &&
            (_edition == null || bookEdition(b) == _edition) &&
            (_language == null || b.language == _language) &&
            (_year == null || bookYear(b) == _year) &&
            (!_downloadedOnly || (reading[b.id]?.downloaded ?? false)))
          b,
    ];
    final recent = [for (final r in reading.values) if (r.lastPage != null && r.updatedAt != null) r]..sort((a, b) => b.updatedAt!.compareTo(a.updatedAt!));
    return AppPageScaffold(
      title: context.tr(LibraryStrings.title),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(context.tr(LibraryStrings.hint), style: Theme.of(context).textTheme.bodyMedium),
          if (recent.isNotEmpty) ...[
            SectionHeader(title: context.tr(LibraryStrings.continueReading)),
            for (final r in recent.take(2))
              if (bookById(r.bookId) case final b?)
                Card(
                  margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: ListTile(
                    leading: IconTile(icon: b.icon, color: b.color),
                    title: Text(context.tr(b.title)),
                    subtitle: Text('${context.tr(LibraryStrings.page.fill({'n': r.lastPage!}))} · ${relativeTime(r.updatedAt!, context.lang)}'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.push(AppRoutes.bookReader(b.id, page: r.lastPage)),
                  ),
                ),
          ],
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(child: TextField(decoration: InputDecoration(prefixIcon: const Icon(Icons.search), hintText: context.tr(LibraryStrings.search)), onChanged: (v) => setState(() => _q = v))),
              const SizedBox(width: AppSpacing.sm),
              Badge(
                isLabelVisible: _active > 0,
                label: Text(context.n(_active)),
                child: IconButton.filledTonal(key: const Key('library.filters'), tooltip: context.tr(LibraryStrings.filters), onPressed: _filters, icon: const Icon(Icons.tune)),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          if (books.isEmpty) EmptyState(title: context.tr(LibraryStrings.noBooks), icon: Icons.menu_book_outlined),
          for (final b in books)
            Card(
              margin: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: ListTile(
                key: Key('library.book.${b.id}'),
                leading: IconTile(icon: b.icon, color: b.color),
                title: Text(context.tr(b.title)),
                subtitle: Text('${b.level.code} · ${context.n(bookYear(b))} · ${context.tr(LibraryStrings.pages.fill({'n': b.pageCount}))}${bookEdition(b) != 'nctb-2025' ? ' · ${context.tr(LibraryStrings.oldEdition)}' : ''}'),
                trailing: (reading[b.id]?.downloaded ?? false) ? Tooltip(message: context.tr(LibraryStrings.downloadedNote), child: const Icon(Icons.offline_pin_outlined)) : const Icon(Icons.chevron_right),
                onTap: () => context.push(AppRoutes.book(b.id)),
              ),
            ),
        ],
      ),
    );
  }
}

/// Book detail: cover, contents, download, ask the book's teacher.
class BookScreen extends ConsumerWidget {
  const BookScreen({super.key, required this.bookId});

  final String bookId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final book = bookById(bookId);
    if (book == null) return AppPageScaffold(title: context.tr(LibraryStrings.title), body: const ErrorView());
    final r = ref.watch(libraryProvider)[bookId] ?? BookReading(bookId: bookId);
    final text = Theme.of(context).textTheme;
    final lib = ref.read(libraryProvider.notifier);
    final myVersion = ref.watch(studentProfileProvider.select((p) => p.curriculumVersionId));
    final plan = ref.watch(accountProvider.select((a) => a.plan));
    final allowed = downloadAllowed(book);
    return AppPageScaffold(
      title: context.tr(book.subject.name),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            height: 140,
            decoration: BoxDecoration(color: book.color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(16)),
            child: Row(
              children: [
                const SizedBox(width: AppSpacing.lg),
                Icon(book.icon, size: 56, color: book.color),
                const SizedBox(width: AppSpacing.lg),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(context.tr(book.title), style: text.titleMedium),
                      const SizedBox(height: AppSpacing.xs),
                      Text('${book.level.code} · ${context.tr(LibraryStrings.pages.fill({'n': book.pageCount}))}', style: text.bodySmall),
                      if (r.downloaded) Padding(padding: const EdgeInsets.only(top: AppSpacing.xs), child: Pill(context.tr(LibraryStrings.downloadedNote), tone: Tone.success, icon: Icons.download_done)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (bookEdition(book) != myVersion) ...[
            const SizedBox(height: AppSpacing.sm),
            InfoBanner(key: const Key('book.versionWarning'), message: context.tr(LibraryStrings.versionWarning), tone: Tone.warning, icon: Icons.history_toggle_off),
          ],
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              FilledButton.icon(
                key: const Key('book.read'),
                onPressed: () => context.push(AppRoutes.bookReader(bookId, page: r.lastPage)),
                icon: const Icon(Icons.menu_book),
                label: Text(context.tr(r.lastPage == null ? LibraryStrings.read : LibraryStrings.continueReading)),
              ),
              OutlinedButton.icon(
                onPressed: () => context.push(AppRoutes.avatarClass(bookId)),
                icon: const Icon(Icons.co_present_outlined),
                label: Text(context.tr(LibraryStrings.askTeacher)),
              ),
              OutlinedButton.icon(
                key: const Key('book.download'),
                onPressed: !allowed && !r.downloaded
                    ? null
                    : () async {
                        final offline = ref.read(appSettingsProvider).simulateOffline;
                        if (!r.downloaded && offline) return context.showSnack(LibraryStrings.offlineNotDownloaded);
                        if (!r.downloaded && plan == PlanCode.free && lib.downloadedCount >= freeDownloadLimit) return context.showSnack(LibraryStrings.downloadLimit);
                        await lib.setDownloaded(bookId, !r.downloaded);
                      },
                icon: Icon(r.downloaded ? Icons.delete_outline : (allowed ? Icons.download_outlined : Icons.block)),
                label: Text(context.tr(r.downloaded ? LibraryStrings.removeDownload : (allowed ? LibraryStrings.download : LibraryStrings.readOnline))),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Icon(r.downloaded ? Icons.offline_pin : Icons.cloud_outlined, size: 18, color: r.downloaded ? Colors.green : null),
              const SizedBox(width: AppSpacing.xs),
              Expanded(child: Text(context.tr(r.downloaded ? LibraryStrings.availableOffline : (allowed ? LibraryStrings.onlineOnly : LibraryStrings.permissionNote)), style: text.bodySmall)),
            ],
          ),
          SectionHeader(title: context.tr(LibraryStrings.contents)),
          for (final c in book.chapters)
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text('${context.tr(LibraryStrings.chapter.fill({'n': c.number}))}: ${context.tr(c.title)}'),
              trailing: Text(context.n(book.firstPageOf(c.id) ?? 0), style: text.labelMedium),
              onTap: () => context.push(AppRoutes.bookReader(bookId, page: book.firstPageOf(c.id))),
            ),
          if (r.bookmarks.isNotEmpty) ...[
            SectionHeader(title: context.tr(LibraryStrings.bookmarks)),
            Wrap(
              spacing: AppSpacing.xs,
              children: [
                for (final p in r.bookmarks)
                  ActionChip(avatar: const Icon(Icons.bookmark, size: 16), label: Text(context.tr(LibraryStrings.page.fill({'n': p}))), onPressed: () => context.push(AppRoutes.bookReader(bookId, page: p))),
              ],
            ),
          ],
          if (r.notes.isNotEmpty || r.highlights.isNotEmpty) ...[
            SectionHeader(title: context.tr(LibraryStrings.myNotes)),
            for (final e in r.notes.entries)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.edit_note),
                title: Text(e.value, maxLines: 2, overflow: TextOverflow.ellipsis),
                subtitle: Text(context.tr(LibraryStrings.page.fill({'n': e.key}))),
                onTap: () => context.push(AppRoutes.bookReader(bookId, page: e.key)),
              ),
            for (final h in r.highlights)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.format_color_fill, color: Colors.amber),
                title: Text(h.text, maxLines: 2, overflow: TextOverflow.ellipsis),
                subtitle: Text(context.tr(LibraryStrings.page.fill({'n': h.page}))),
                onTap: () => context.push(AppRoutes.bookReader(bookId, page: h.page)),
              ),
          ],
          if (r.history.isNotEmpty) ...[
            SectionHeader(title: context.tr(LibraryStrings.history)),
            for (final (page, at) in r.history.take(5))
              ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.history),
                title: Text(context.tr(LibraryStrings.page.fill({'n': page}))),
                subtitle: Text(relativeTime(at, context.lang)),
                onTap: () => context.push(AppRoutes.bookReader(bookId, page: page)),
              ),
          ],
          const SizedBox(height: AppSpacing.md),
          InfoBanner(message: context.tr(LibraryStrings.sample)),
        ],
      ),
    );
  }
}

/// Page-by-page reader with page jump, text size and bookmarks.
class BookReaderScreen extends ConsumerStatefulWidget {
  const BookReaderScreen({super.key, required this.bookId, this.page});

  final String bookId;
  final int? page;

  @override
  ConsumerState<BookReaderScreen> createState() => _BookReaderScreenState();
}

class _BookReaderScreenState extends ConsumerState<BookReaderScreen> {
  late final Book _book = bookById(widget.bookId)!;
  late final PageController _pages = PageController(initialPage: widget.page == null ? 0 : _book.indexOfPage(widget.page!));
  late int _index = _pages.initialPage;
  double _scale = 1;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _remember());
  }

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  void _remember() => ref.read(libraryProvider.notifier).openedPage(widget.bookId, _book.pages[_index].page);

  Future<void> _jump() async {
    final ctrl = TextEditingController();
    final n = await showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.tr(LibraryStrings.goToPage)),
        content: TextField(key: const Key('reader.pageInput'), controller: ctrl, keyboardType: TextInputType.number, autofocus: true),
        actions: [FilledButton(onPressed: () => Navigator.pop(context, int.tryParse(ctrl.text.trim())), child: Text(context.tr(LibraryStrings.go)))],
      ),
    );
    ctrl.dispose();
    if (n != null) _pages.jumpToPage(_book.indexOfPage(n));
  }

  @override
  Widget build(BuildContext context) {
    final r = ref.watch(libraryProvider)[widget.bookId] ?? BookReading(bookId: widget.bookId);
    final offline = ref.watch(appSettingsProvider.select((s) => s.simulateOffline));
    final page = _book.pages[_index];
    final marked = r.bookmarks.contains(page.page);
    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr(_book.subject.name)),
        actions: [
          IconButton(
            key: const Key('reader.note'),
            tooltip: context.tr(LibraryStrings.pageNote),
            isSelected: r.notes.containsKey(page.page),
            icon: const Icon(Icons.edit_note_outlined),
            selectedIcon: const Icon(Icons.edit_note),
            onPressed: () => showModalBottomSheet<void>(context: context, isScrollControlled: true, showDragHandle: true, builder: (_) => PageNoteSheet(bookId: widget.bookId, page: page.page)),
          ),
          IconButton(
            key: const Key('reader.bookmark'),
            tooltip: context.tr(LibraryStrings.bookmark),
            isSelected: marked,
            icon: const Icon(Icons.bookmark_border),
            selectedIcon: const Icon(Icons.bookmark),
            onPressed: () => ref.read(libraryProvider.notifier).toggleBookmark(widget.bookId, page.page),
          ),
          PopupMenuButton<String>(
            key: const Key('reader.menu'),
            onSelected: (v) {
              if (v == 'jump') _jump();
              if (v == '+') setState(() => _scale = (_scale + 0.15).clamp(0.85, 1.6));
              if (v == '-') setState(() => _scale = (_scale - 0.15).clamp(0.85, 1.6));
              if (v == 'ask') context.push(AppRoutes.avatarClass(widget.bookId));
              if (v == 'passage') showModalBottomSheet<void>(context: context, isScrollControlled: true, showDragHandle: true, builder: (_) => PassageSheet(book: _book, page: page));
              if (v == 'related') showModalBottomSheet<void>(context: context, isScrollControlled: true, showDragHandle: true, builder: (_) => RelatedSheet(book: _book, page: page));
              if (v == 'aiPage') {
                context.go(AppRoutes.tutor(
                  subjectId: _book.subject.id,
                  chapterId: page.chapterId,
                  prompt: context.isBangla ? '"${page.heading.bn}" (পৃষ্ঠা ${page.page}) অংশটি বুঝিয়ে দাও' : 'Explain "${page.heading.en}" (page ${page.page})',
                ));
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(value: 'passage', child: Text('${context.tr(LibraryStrings.highlight)} / ${context.tr(LibraryStrings.explain)}')),
              PopupMenuItem(value: 'aiPage', child: Text(context.tr(LibraryStrings.askPage))),
              PopupMenuItem(value: 'related', child: Text(context.tr(LibraryStrings.related))),
              PopupMenuItem(value: 'jump', child: Text(context.tr(LibraryStrings.goToPage))),
              PopupMenuItem(value: '+', child: Text('${context.tr(LibraryStrings.textSize)} +')),
              PopupMenuItem(value: '-', child: Text('${context.tr(LibraryStrings.textSize)} −')),
              PopupMenuItem(value: 'ask', child: Text(context.tr(LibraryStrings.askTeacher))),
            ],
          ),
        ],
      ),
      body: offline && !r.downloaded
          ? OfflineView(onRetry: () => setState(() {}))
          : Column(
              children: [
                Expanded(
                  child: PageView.builder(
                    controller: _pages,
                    itemCount: _book.pages.length,
                    onPageChanged: (i) {
                      setState(() => _index = i);
                      _remember();
                    },
                    itemBuilder: (context, i) {
                      final p = _book.pages[i];
                      final text = Theme.of(context).textTheme;
                      return MediaQuery(
                        data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(MediaQuery.textScalerOf(context).scale(1) * _scale)),
                        child: ListView(
                          padding: AppSpacing.screen,
                          children: [
                            Text(context.tr(p.chapterTitle), style: text.labelMedium?.copyWith(color: Theme.of(context).colorScheme.primary)),
                            const SizedBox(height: AppSpacing.xs),
                            Text(context.tr(p.heading), style: text.titleLarge),
                            const SizedBox(height: AppSpacing.md),
                            RichContent(withHighlights(context.tr(p.body), r.highlightsOn(p.page)), selectable: true),
                            if (r.notes[p.page] case final note?) ...[
                              const SizedBox(height: AppSpacing.lg),
                              Card(
                                key: const Key('reader.noteCard'),
                                color: Colors.amber.withValues(alpha: 0.15),
                                margin: EdgeInsets.zero,
                                child: ListTile(leading: const Icon(Icons.edit_note), title: Text(note), subtitle: Text(context.tr(LibraryStrings.pageNote))),
                              ),
                            ],
                          ],
                        ),
                      );
                    },
                  ),
                ),
                SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                    child: Row(
                      children: [
                        IconButton(onPressed: _index == 0 ? null : () => _pages.previousPage(duration: const Duration(milliseconds: 200), curve: Curves.easeOut), icon: const Icon(Icons.chevron_left)),
                        Expanded(
                          child: TextButton(
                            key: const Key('reader.pageLabel'),
                            onPressed: _jump,
                            child: Text(context.tr(LibraryStrings.pageOf.fill({'n': page.page, 't': _book.pageCount}))),
                          ),
                        ),
                        IconButton(
                          key: const Key('reader.next'),
                          onPressed: _index >= _book.pages.length - 1 ? null : () => _pages.nextPage(duration: const Duration(milliseconds: 200), curve: Curves.easeOut),
                          icon: const Icon(Icons.chevron_right),
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
