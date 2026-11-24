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
import 'library_controller.dart';

enum _Filter { all, ssc, hsc, downloaded }

/// Browse the sample textbooks.
class LibraryScreen extends ConsumerStatefulWidget {
  const LibraryScreen({super.key});

  @override
  ConsumerState<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends ConsumerState<LibraryScreen> {
  String _q = '';
  _Filter _filter = _Filter.all;

  @override
  Widget build(BuildContext context) {
    final reading = ref.watch(libraryProvider);
    final q = _q.trim().toLowerCase();
    final books = [
      for (final b in sampleBooks)
        if ((q.isEmpty || b.title.matches(q)) &&
            switch (_filter) {
              _Filter.all => true,
              _Filter.ssc => b.level == EducationLevel.ssc,
              _Filter.hsc => b.level == EducationLevel.hsc,
              _Filter.downloaded => reading[b.id]?.downloaded ?? false,
            })
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
          TextField(decoration: InputDecoration(prefixIcon: const Icon(Icons.search), hintText: context.tr(LibraryStrings.search)), onChanged: (v) => setState(() => _q = v)),
          const SizedBox(height: AppSpacing.sm),
          ChoiceChipBar<_Filter>(
            options: _Filter.values,
            selected: _filter,
            labelOf: (f) => switch (f) {
              _Filter.all => context.tr(LibraryStrings.all),
              _Filter.ssc => 'SSC',
              _Filter.hsc => 'HSC',
              _Filter.downloaded => context.tr(LibraryStrings.downloaded),
            },
            onSelected: (f) => setState(() => _filter = f),
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
                subtitle: Text('${b.level.code} · ${context.tr(LibraryStrings.pages.fill({'n': b.pageCount}))}'),
                trailing: (reading[b.id]?.downloaded ?? false) ? const Icon(Icons.download_done) : const Icon(Icons.chevron_right),
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
                onPressed: () async {
                  final offline = ref.read(appSettingsProvider).simulateOffline;
                  if (!r.downloaded && offline) return context.showSnack(LibraryStrings.offlineNotDownloaded);
                  await lib.setDownloaded(bookId, !r.downloaded);
                },
                icon: Icon(r.downloaded ? Icons.delete_outline : Icons.download_outlined),
                label: Text(context.tr(r.downloaded ? LibraryStrings.removeDownload : LibraryStrings.download)),
              ),
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
            key: const Key('reader.bookmark'),
            tooltip: context.tr(LibraryStrings.bookmark),
            isSelected: marked,
            icon: const Icon(Icons.bookmark_border),
            selectedIcon: const Icon(Icons.bookmark),
            onPressed: () => ref.read(libraryProvider.notifier).toggleBookmark(widget.bookId, page.page),
          ),
          PopupMenuButton<String>(
            onSelected: (v) {
              if (v == 'jump') _jump();
              if (v == '+') setState(() => _scale = (_scale + 0.15).clamp(0.85, 1.6));
              if (v == '-') setState(() => _scale = (_scale - 0.15).clamp(0.85, 1.6));
              if (v == 'ask') context.push(AppRoutes.avatarClass(widget.bookId));
            },
            itemBuilder: (context) => [
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
                            RichContent(context.tr(p.body), selectable: true),
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
