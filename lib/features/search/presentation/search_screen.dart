import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../app/router/app_routes.dart';
import '../../../core/l10n/tr.dart';
import '../../../core/storage/local_store.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../mock/seed/curriculum_seed.dart';
import '../../../shared/widgets/app_page_scaffold.dart';
import '../../../shared/widgets/cards.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/search_field.dart';
import '../../../shared/widgets/section_header.dart';
import '../../ai_tutor/application/tutor_controller.dart';
import '../../book_avatar/application/avatar_controller.dart';
import '../../book_avatar/data/book_catalog.dart';
import '../../flashcards/application/flashcards_controller.dart';
import '../../notes/application/notes_controller.dart';
import '../../question_bank/data/question_repository.dart';
import '../../archives/archive_data.dart';
import '../../exams/application/exam_controller.dart';
import '../../profile/application/student_profile_controller.dart';
import '../../study_tools/audio_and_offline.dart';
import '../../study_tools/labs.dart';

abstract final class SearchStrings {
  static const title = Tr('খুঁজুন', 'Search');
  static const hint = Tr('বিষয়, অধ্যায়, প্রশ্ন, বই, নোট…', 'Subjects, chapters, questions, books, notes…');
  static const recent = Tr('সাম্প্রতিক অনুসন্ধান', 'Recent searches');
  static const clear = Tr('মুছুন', 'Clear');
  static const popular = Tr('জনপ্রিয় টপিক', 'Popular topics');
  static const noResults = Tr('কিছু পাওয়া যায়নি', 'No results');
  static const noResultsHint = Tr('অন্য শব্দে খুঁজে দেখো, বা AI টিউটরকে জিজ্ঞেস করো।', 'Try other words, or ask the AI tutor.');
  static const askTutor = Tr('AI টিউটরকে জিজ্ঞেস করো', 'Ask the AI tutor');
  static const all = Tr('সব', 'All');
  static const suggestions = Tr('পরামর্শ', 'Suggestions');
}

enum SearchKind {
  subject(Tr('বিষয়', 'Subjects'), Icons.menu_book_outlined),
  chapter(Tr('অধ্যায় ও টপিক', 'Chapters & topics'), Icons.list_alt),
  question(Tr('প্রশ্ন', 'Questions'), Icons.quiz_outlined),
  book(Tr('বই ও শিক্ষক', 'Books & teachers'), Icons.local_library_outlined),
  note(Tr('নোট', 'Notes'), Icons.sticky_note_2_outlined),
  deck(Tr('ফ্ল্যাশকার্ড', 'Flashcards'), Icons.style_outlined),
  chat(Tr('কথোপকথন', 'Conversations'), Icons.forum_outlined),
  paper(Tr('বোর্ড ও প্রতিষ্ঠানের প্রশ্নপত্র', 'Board & school papers'), Icons.history_edu_outlined),
  exam(Tr('পরীক্ষা', 'Exams'), Icons.assignment_outlined),
  resource(Tr('রিসোর্স (অডিও ও ল্যাব)', 'Resources (audio & labs)'), Icons.folder_open_outlined);

  const SearchKind(this.label, this.icon);
  final Tr label;
  final IconData icon;
}

class SearchHit {
  const SearchHit(this.kind, this.title, this.subtitle, this.route);

  final SearchKind kind;
  final String title;
  final String subtitle;
  final String route;
}

/// Global search across the app's content, grouped by kind, with recent searches.
class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  static const _recentKey = 'recent';
  static const _collection = 'search';
  String _q = '';
  SearchKind? _kind;

  List<String> get _recent => ((ref.read(localStoreProvider).get(_collection, _recentKey)?['items'] as List?) ?? const []).cast<String>();

  Future<void> _remember(String q) async {
    final t = q.trim();
    if (t.length < 2) return;
    final items = [t, ..._recent.where((x) => x != t)].take(8).toList();
    await ref.read(localStoreProvider).put(_collection, _recentKey, {'items': items});
    if (mounted) setState(() {});
  }

  List<SearchHit> _search(String raw, AppLanguage lang) {
    final q = raw.trim().toLowerCase();
    if (q.length < 2) return const [];
    bool m(String s) => s.toLowerCase().contains(q);
    bool mt(Tr t) => m(t.bn) || m(t.en);
    final hits = <SearchHit>[];
    for (final s in seedSubjects) {
      if (mt(s.name)) hits.add(SearchHit(SearchKind.subject, s.name.of(lang), s.level.code, AppRoutes.subject(s.id)));
      for (final c in s.chapters) {
        if (mt(c.title)) hits.add(SearchHit(SearchKind.chapter, c.title.of(lang), s.name.of(lang), AppRoutes.chapter(c.id)));
        for (final t in c.topics) {
          if (mt(t.title)) hits.add(SearchHit(SearchKind.chapter, t.title.of(lang), '${s.name.of(lang)} · ${c.title.of(lang)}', AppRoutes.topic(t.id)));
        }
      }
    }
    for (final qn in ref.read(questionRepositoryProvider).cached) {
      if (mt(qn.stem)) {
        final stem = qn.stem.of(lang).replaceAll(RegExp(r'[$*#]'), '');
        hits.add(SearchHit(SearchKind.question, stem.length > 90 ? '${stem.substring(0, 90)}…' : stem, qn.type.label.of(lang), AppRoutes.question(qn.id)));
      }
    }
    final avatars = ref.read(avatarControllerProvider);
    for (final b in sampleBooks) {
      final a = avatars.avatarForBook(b.id);
      if (mt(b.title)) hits.add(SearchHit(SearchKind.book, b.title.of(lang), b.level.code, AppRoutes.book(b.id)));
      if (a != null && mt(a.name)) hits.add(SearchHit(SearchKind.book, a.name.of(lang), a.title.of(lang), AppRoutes.avatarClass(b.id)));
    }
    for (final n in ref.read(notesProvider)) {
      if (m(n.title) || m(n.body)) hits.add(SearchHit(SearchKind.note, n.title, n.type.label.of(lang), AppRoutes.note(n.id)));
    }
    for (final d in ref.read(flashcardsProvider).decks) {
      if (m(d.title)) hits.add(SearchHit(SearchKind.deck, d.title, '', '/flashcards/deck/${d.id}'));
    }
    for (final c in ref.read(tutorProvider)) {
      if (m(c.title) || c.messages.any((x) => m(x.text))) hits.add(SearchHit(SearchKind.chat, c.title, '', AppRoutes.tutorChat(c.id)));
    }
    final bank = ref.read(questionRepositoryProvider).cached;
    final level = ref.read(studentProfileProvider).level;
    for (final s in seedSubjects.where((s) => s.level == level)) {
      if (!mt(s.name)) continue;
      for (final b in educationBoards.take(3)) {
        if (boardPaper(bank, subject: s, boardId: b.id, year: archiveYears.first) case final p?) hits.add(SearchHit(SearchKind.paper, p.title.of(lang), lang == AppLanguage.bn ? 'বোর্ড-ধাঁচের নমুনা' : 'Board-style sample', AppRoutes.boardPaper(p.id)));
      }
    }
    for (final p in institutionPapers(bank)) {
      if (mt(p.title) || mt(p.institution!.name)) hits.add(SearchHit(SearchKind.paper, p.title.of(lang), p.institution!.name.of(lang), AppRoutes.institutionPaper(p.id)));
    }
    final exams = ref.read(examProvider);
    for (final t in exams.templates) {
      if (mt(t.title) || mt(t.type.label)) hits.add(SearchHit(SearchKind.exam, t.title.of(lang), t.type.label.of(lang), AppRoutes.examCenter));
    }
    for (final a in exams.finished) {
      if (mt(a.title)) hits.add(SearchHit(SearchKind.exam, a.title.of(lang), '${(a.result!.percent * 100).round()}%', AppRoutes.examResult(a.id)));
    }
    for (final l in ref.read(audioLessonsProvider)) {
      if (mt(l.title)) hits.add(SearchHit(SearchKind.resource, l.title.of(lang), lang == AppLanguage.bn ? 'অডিও লেসন' : 'Audio lesson', AppRoutes.audio));
    }
    for (final lab in labCatalog.where((l) => l.available)) {
      if (mt(lab.title)) hits.add(SearchHit(SearchKind.resource, lab.title.of(lang), lang == AppLanguage.bn ? 'ল্যাব' : 'Lab', AppRoutes.labs));
    }
    return hits;
  }

  /// Title completions from the strongest hits (SRCH-06).
  List<String> _suggestions(List<SearchHit> hits) {
    final q = _q.trim().toLowerCase();
    return {
      for (final h in hits.where((h) => h.kind == SearchKind.subject || h.kind == SearchKind.chapter))
        if (h.title.toLowerCase() != q) h.title,
    }.take(4).toList();
  }

  @override
  Widget build(BuildContext context) {
    final all = _search(_q, context.lang);
    final hits = _kind == null ? all : [for (final h in all) if (h.kind == _kind) h];
    final kinds = [for (final k in SearchKind.values) if (all.any((h) => h.kind == k)) k];
    final recent = _recent;
    return AppPageScaffold(
      title: context.tr(SearchStrings.title),
      showShortcuts: false,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DebouncedSearchField(
            key: const Key('search.field'),
            autofocus: true,
            hint: context.tr(SearchStrings.hint),
            initial: _q,
            onChanged: (v) => setState(() {
              _q = v;
              _kind = null;
            }),
            onSubmitted: _remember,
          ),
          const SizedBox(height: AppSpacing.md),
          if (_q.trim().length < 2) ...[
            if (recent.isNotEmpty)
              SectionHeader(
                title: context.tr(SearchStrings.recent),
                actionLabel: context.tr(SearchStrings.clear),
                onAction: () async {
                  await ref.read(localStoreProvider).delete(_collection, _recentKey);
                  setState(() {});
                },
              ),
            Wrap(
              spacing: AppSpacing.xs,
              children: [
                for (final r in recent)
                  InputChip(
                    key: Key('recent.$r'),
                    label: Text(r),
                    onPressed: () => setState(() => _q = r),
                    onDeleted: () async {
                      final items = [for (final x in _recent) if (x != r) x];
                      await ref.read(localStoreProvider).put(_collection, _recentKey, {'items': items});
                      setState(() {});
                    },
                  ),
              ],
            ),
            SectionHeader(title: context.tr(SearchStrings.popular)),
            Wrap(
              spacing: AppSpacing.xs,
              runSpacing: AppSpacing.xs,
              children: [
                for (final t in context.isBangla ? const ['ত্বরণ', 'নিউটন', 'মোল', 'সালোকসংশ্লেষণ', 'বীজগণিত', 'Tense'] : const ['acceleration', 'Newton', 'mole', 'photosynthesis', 'algebra', 'tense'])
                  ActionChip(label: Text(t), onPressed: () => setState(() => _q = t)),
              ],
            ),
          ] else if (all.isEmpty)
            EmptyState(
              title: context.tr(SearchStrings.noResults),
              message: context.tr(SearchStrings.noResultsHint),
              icon: Icons.search_off,
              action: FilledButton(onPressed: () => context.go(AppRoutes.tutor(prompt: _q)), child: Text(context.tr(SearchStrings.askTutor))),
            )
          else ...[
            if (_suggestions(all).isNotEmpty) ...[
              Text(context.tr(SearchStrings.suggestions), style: Theme.of(context).textTheme.labelMedium),
              Wrap(
                spacing: AppSpacing.xs,
                children: [for (final sg in _suggestions(all)) ActionChip(key: Key('suggest.$sg'), avatar: const Icon(Icons.north_west, size: 14), label: Text(sg), onPressed: () => setState(() => _q = sg))],
              ),
              const SizedBox(height: AppSpacing.sm),
            ],
            ChoiceChipBar<SearchKind?>(
              options: [null, ...kinds],
              selected: _kind,
              labelOf: (k) => k == null
                  ? '${context.tr(SearchStrings.all)} (${context.n(all.length)})'
                  : '${context.tr(k.label)} (${context.n(all.where((h) => h.kind == k).length)})',
              onSelected: (k) => setState(() => _kind = k),
            ),
            const SizedBox(height: AppSpacing.sm),
            for (final k in SearchKind.values)
              if (hits.any((h) => h.kind == k)) ...[
                SectionHeader(title: context.tr(k.label)),
                for (final h in hits.where((h) => h.kind == k).take(_kind == null ? 4 : 50))
                  Card(
                    margin: const EdgeInsets.only(bottom: AppSpacing.xs),
                    child: ListTile(
                      dense: true,
                      leading: Icon(k.icon),
                      title: Text(h.title, maxLines: 2, overflow: TextOverflow.ellipsis),
                      subtitle: h.subtitle.isEmpty ? null : Text(h.subtitle, maxLines: 1, overflow: TextOverflow.ellipsis),
                      onTap: () {
                        _remember(_q);
                        context.push(h.route);
                      },
                    ),
                  ),
              ],
          ],
        ],
      ),
    );
  }
}
