import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/l10n/tr.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/time_format.dart';
import '../../../shared/widgets/app_page_scaffold.dart';
import '../../../shared/widgets/badges.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/feedback.dart';
import '../../../shared/widgets/rich_content.dart';
import '../../../shared/widgets/section_header.dart';
import '../../../shared/widgets/stat_card.dart';
import '../../auth/application/auth_controller.dart';
import '../application/avatar_controller.dart';
import '../avatar_strings.dart';
import '../data/book_catalog.dart';
import '../data/remote_avatar.dart';
import '../domain/avatar_models.dart';
import 'teacher_avatar.dart';

// ═════════════════════════════════════════════════════════════════════════════
// Teacher: test avatars and fix reported answers (editing lives in the web admin).
// ═════════════════════════════════════════════════════════════════════════════

class TeacherAvatarsScreen extends ConsumerStatefulWidget {
  const TeacherAvatarsScreen({super.key});

  @override
  ConsumerState<TeacherAvatarsScreen> createState() => _TeacherAvatarsScreenState();
}

class _TeacherAvatarsScreenState extends ConsumerState<TeacherAvatarsScreen> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(avatarControllerProvider);
    final q = _query.trim().toLowerCase();
    final books = [for (final b in sampleBooks) if (q.isEmpty || b.title.matches(q) || (state.avatarForBook(b.id)?.name.matches(q) ?? false)) b];
    final open = state.reports.where((r) => r.status == ReportStatus.open).length;
    return DefaultTabController(
      length: 2,
      child: AppPageScaffold(
        title: context.tr(AvatarStrings.teacherTitle),
        scrollable: false,
        bottom: TabBar(
          tabAlignment: TabAlignment.fill,
          tabs: [
            Tab(text: context.tr(AvatarStrings.avatarsTab)),
            Tab(text: '${context.tr(AvatarStrings.reportsTab)}${open > 0 ? ' (${context.n(open)})' : ''}'),
          ],
        ),
        body: TabBarView(
          children: [
            ListView(
              children: [
                InfoBanner(message: context.tr(AvatarStrings.teacherHint)),
                const SizedBox(height: AppSpacing.md),
                TextField(
                  decoration: InputDecoration(prefixIcon: const Icon(Icons.search), hintText: context.tr(AvatarStrings.searchHint)),
                  onChanged: (v) => setState(() => _query = v),
                ),
                const SizedBox(height: AppSpacing.sm),
                for (final b in books) _TeacherAvatarTile(book: b),
              ],
            ),
            const AvatarReportsList(),
          ],
        ),
      ),
    );
  }
}

class _TeacherAvatarTile extends ConsumerWidget {
  const _TeacherAvatarTile({required this.book});

  final Book book;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(avatarControllerProvider);
    final a = ref.read(avatarControllerProvider.notifier).avatarFor(book);
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: ListTile(
        key: Key('teacher.avatar.${book.id}'),
        leading: TeacherAvatar(appearance: a.appearance, size: 44),
        title: Text(context.tr(a.name)),
        subtitle: Text(
          '${context.tr(book.subject.name)} · ${context.tr(AvatarStrings.questions)} ${context.n(a.stats.questions)}'
          '${a.stats.satisfaction == null ? '' : ' · ${context.pct(a.stats.satisfaction!)}'}',
        ),
        trailing: Pill(context.tr(a.status.label), tone: a.status == AvatarStatus.active ? Tone.success : Tone.neutral),
        onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => AvatarDetailScreen(bookId: book.id))),
      ),
    );
  }
}

/// Read-only avatar profile + test chat (nothing stored).
class AvatarDetailScreen extends ConsumerStatefulWidget {
  const AvatarDetailScreen({super.key, required this.bookId});

  final String bookId;

  @override
  ConsumerState<AvatarDetailScreen> createState() => _AvatarDetailScreenState();
}

class _AvatarDetailScreenState extends ConsumerState<AvatarDetailScreen> {
  final _input = TextEditingController();
  final List<(String, AvatarAnswer)> _chat = [];
  bool _busy = false;

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  Future<void> _ask(BookAvatar a, String q) async {
    if (q.trim().isEmpty || _busy) return;
    _input.clear();
    setState(() => _busy = true);
    try {
      final answer = await ref.read(avatarControllerProvider.notifier).preview(a, q.trim());
      if (mounted) setState(() => _chat.add((q.trim(), answer)));
    } on ApiException catch (e) {
      if (mounted) context.showErrorSnack(e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(avatarControllerProvider);
    final book = bookById(widget.bookId)!;
    final a = ref.read(avatarControllerProvider.notifier).avatarFor(book);
    final text = Theme.of(context).textTheme;
    final scope = a.scopeChapterIds.isEmpty
        ? context.tr(AvatarStrings.wholeBook)
        : [for (final id in a.scopeChapterIds) if (book.chapter(id) case final c?) context.tr(c.title)].join(', ');
    return AppPageScaffold(
      title: context.tr(a.name),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(child: TeacherAvatar(appearance: a.appearance, size: 160, semanticLabel: context.tr(a.name))),
          const SizedBox(height: AppSpacing.sm),
          Text('${context.tr(a.title)} · ${context.tr(book.title)}', textAlign: TextAlign.center, style: text.bodyMedium),
          const SizedBox(height: AppSpacing.md),
          StatGrid(
            cards: [
              StatCard(label: context.tr(AvatarStrings.sessions), value: context.n(a.stats.sessions), icon: Icons.co_present_outlined),
              StatCard(label: context.tr(AvatarStrings.questions), value: context.n(a.stats.questions), icon: Icons.forum_outlined),
              StatCard(label: context.tr(AvatarStrings.outOfScope), value: context.n(a.stats.outOfScope), icon: Icons.block_outlined),
              StatCard(label: context.tr(AvatarStrings.satisfaction), value: a.stats.satisfaction == null ? '—' : context.pct(a.stats.satisfaction!), icon: Icons.thumb_up_outlined),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Card(
            margin: EdgeInsets.zero,
            child: Column(
              children: [
                ListTile(dense: true, title: Text(context.tr(AvatarStrings.persona)), trailing: Text(context.tr(a.persona.style.label))),
                ListTile(dense: true, title: Text(context.tr(AvatarStrings.answerLength)), trailing: Text(context.tr(a.persona.answerLength.label))),
                ListTile(dense: true, title: Text(context.tr(AvatarStrings.scope)), subtitle: Text(scope)),
                ListTile(dense: true, title: Text(context.tr(AvatarStrings.strictScope)), trailing: Icon(a.strictBookScope ? Icons.check_circle : Icons.cancel_outlined)),
              ],
            ),
          ),
          SectionHeader(title: context.tr(AvatarStrings.testChat)),
          Text(context.tr(AvatarStrings.testNote), style: text.bodySmall),
          const SizedBox(height: AppSpacing.sm),
          for (final (q, ans) in _chat) ...[
            Align(alignment: Alignment.centerRight, child: Chip(label: Text(q))),
            Card(
              margin: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Pill(
                      context.tr(switch (ans.grounded) {
                        Grounding.book => AvatarStrings.fromBook,
                        Grounding.outOfScope => AvatarStrings.outsideBook,
                        Grounding.greeting => const Tr('পরিচিতি', 'Intro'),
                      }),
                      tone: ans.grounded == Grounding.outOfScope ? Tone.warning : Tone.success,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    RichContent(ans.text),
                  ],
                ),
              ),
            ),
          ],
          if (_busy) const LinearProgressIndicator(),
          Wrap(
            spacing: AppSpacing.xs,
            children: [
              for (final s in [
                ...book.scenarios.take(1).map((s) => context.isBangla ? '${s.title.bn} কী?' : 'What is ${s.title.en}?'),
                context.isBangla ? 'তুমি কে?' : 'Who are you?',
                context.isBangla ? 'ফ্রান্সের রাজধানী কোথায়?' : 'What is the capital of France?',
              ])
                ActionChip(label: Text(s), onPressed: () => _ask(a, s)),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: TextField(
                  key: const Key('avatar.test.input'),
                  controller: _input,
                  onSubmitted: (v) => _ask(a, v),
                  decoration: InputDecoration(hintText: context.tr(AvatarStrings.testHint)),
                ),
              ),
              IconButton.filled(onPressed: () => _ask(a, _input.text), icon: const Icon(Icons.send)),
            ],
          ),
        ],
      ),
    );
  }
}

/// Reported avatar answers: resolve (with the corrected answer) or dismiss.
class AvatarReportsList extends ConsumerStatefulWidget {
  const AvatarReportsList({super.key});

  @override
  ConsumerState<AvatarReportsList> createState() => _AvatarReportsListState();
}

class _AvatarReportsListState extends ConsumerState<AvatarReportsList> {
  final Map<String, TextEditingController> _notes = {};

  @override
  void dispose() {
    for (final c in _notes.values) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reports = [...ref.watch(avatarControllerProvider).reports]..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final me = ref.read(avatarReviewerNameProvider);
    if (reports.isEmpty) return EmptyState(title: context.tr(AvatarStrings.noReports), icon: Icons.flag_outlined);
    final text = Theme.of(context).textTheme;
    return ListView(
      children: [
        for (final r in reports)
          Card(
            key: Key('avatar.reportCard.${r.id}'),
            margin: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(child: Text(bookById(r.bookId) == null ? r.bookId : context.tr(bookById(r.bookId)!.title), style: text.labelLarge)),
                      Pill(
                        context.tr(switch (r.status) {
                          ReportStatus.open => AvatarStrings.open,
                          ReportStatus.resolved => AvatarStrings.resolved,
                          ReportStatus.dismissed => AvatarStrings.dismissed,
                        }),
                        tone: r.status == ReportStatus.open ? Tone.warning : Tone.neutral,
                      ),
                    ],
                  ),
                  Text(relativeTime(r.createdAt, context.lang), style: text.bodySmall),
                  const SizedBox(height: AppSpacing.xs),
                  Text('${context.tr(AvatarStrings.question)}: ${r.question}'),
                  Text('${context.tr(AvatarStrings.reason)}: ${r.reason}', style: text.bodySmall),
                  if (r.resolution != null) Text('✓ ${r.resolution}${r.resolvedBy == null ? '' : ' — ${r.resolvedBy}'}', style: text.bodySmall),
                  if (r.status == ReportStatus.open) ...[
                    const SizedBox(height: AppSpacing.sm),
                    TextField(
                      key: Key('avatar.resolution.${r.id}'),
                      controller: _notes.putIfAbsent(r.id, TextEditingController.new),
                      decoration: InputDecoration(hintText: context.tr(AvatarStrings.resolutionHint), isDense: true),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => ref.read(avatarControllerProvider.notifier).resolveReport(r.id, ReportStatus.dismissed, _notes[r.id]?.text.trim() ?? '', me),
                          child: Text(context.tr(AvatarStrings.dismiss)),
                        ),
                        FilledButton(
                          key: Key('avatar.resolve.${r.id}'),
                          onPressed: () {
                            final note = _notes[r.id]?.text.trim() ?? '';
                            if (note.isEmpty) return context.showSnack(AvatarStrings.resolutionHint);
                            ref.read(avatarControllerProvider.notifier).resolveReport(r.id, ReportStatus.resolved, note, me);
                          },
                          child: Text(context.tr(AvatarStrings.resolve)),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
      ],
    );
  }
}

/// Name recorded on resolved reports. Tests override it.
final avatarReviewerNameProvider = Provider<String>(
  (ref) => switch (ref.watch(authControllerProvider)) {
    Authenticated(:final user) => user.name,
    _ => 'শিক্ষক',
  },
);

// ═════════════════════════════════════════════════════════════════════════════
// Parent: counts only.
// ═════════════════════════════════════════════════════════════════════════════

class ParentAvatarActivityScreen extends ConsumerWidget {
  const ParentAvatarActivityScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(avatarControllerProvider);
    final local = ref.read(avatarControllerProvider.notifier).usageFor(demoStudentId);
    // API mode: the linked children's counts from the server.
    final rows = ref.watch(guardianAvatarUsageProvider).value;
    final usage = rows == null
        ? local
        : AvatarUsage(
            sessions: rows.fold(0, (n, r) => n + r.$2),
            questions: rows.fold(0, (n, r) => n + r.$3),
            minutes: rows.fold(0, (n, r) => n + r.$4),
            byBook: rows,
          );
    final text = Theme.of(context).textTheme;
    return AppPageScaffold(
      title: context.tr(AvatarStrings.parentTitle),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(context.tr(AvatarStrings.parentHint), style: text.bodyMedium),
          const SizedBox(height: AppSpacing.md),
          StatGrid(
            cards: [
              StatCard(label: context.tr(AvatarStrings.sessions), value: context.n(usage.sessions), icon: Icons.co_present_outlined),
              StatCard(label: context.tr(AvatarStrings.questions), value: context.n(usage.questions), icon: Icons.forum_outlined),
              StatCard(label: context.tr(AvatarStrings.minutes), value: context.n(usage.minutes), icon: Icons.timer_outlined),
            ],
          ),
          SectionHeader(title: context.tr(AvatarStrings.byBook)),
          Text(context.tr(AvatarStrings.countsOnly), style: text.bodySmall),
          const SizedBox(height: AppSpacing.sm),
          if (usage.byBook.isEmpty)
            EmptyState(title: context.tr(AvatarStrings.noUsage), icon: Icons.co_present_outlined, compact: true)
          else
            for (final (book, s, q, m, last) in usage.byBook)
              Card(
                margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: ListTile(
                  title: Text(context.tr(book.subject.name)),
                  subtitle: Text('${context.tr(AvatarStrings.usageRow.fill({'s': s, 'q': q, 'm': m}))} · ${relativeTime(last, context.lang)}'),
                ),
              ),
        ],
      ),
    );
  }
}
