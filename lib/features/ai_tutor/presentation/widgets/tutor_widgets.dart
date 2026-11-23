import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../core/l10n/common_strings.dart';
import '../../../../core/l10n/tr.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/time_format.dart';
import '../../../../mock/seed/curriculum_seed.dart';
import '../../../../shared/widgets/badges.dart';
import '../../../../shared/widgets/feedback.dart';
import '../../../../shared/widgets/rich_content.dart';
import '../../../curriculum/data/curriculum_repository.dart';
import '../../../curriculum/domain/curriculum_models.dart';
import '../../../question_bank/data/question_repository.dart';
import '../../application/tutor_controller.dart';
import '../../domain/tutor_models.dart';
import '../../tutor_strings.dart';

/// One chat message. Assistant messages carry grounding, sources, warnings and actions.
class MessageBubble extends ConsumerWidget {
  const MessageBubble({
    super.key,
    required this.conversationId,
    required this.message,
    required this.onFollowUp,
    required this.isLast,
  });

  final String conversationId;
  final ChatMessage message;
  final ValueChanged<String> onFollowUp;
  final bool isLast;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final m = message;
    final ctl = ref.read(tutorProvider.notifier);
    if (m.isUser) {
      return Align(
        alignment: AlignmentDirectional.centerEnd,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * 0.82),
          child: GestureDetector(
            onLongPress: () async {
              final text = await showTextInputDialog(
                context,
                title: TutorStrings.editQuestion,
                initial: m.text,
                maxLines: 4,
              );
              if (text != null) await ctl.editUserMessage(conversationId, m.id, text);
            },
            child: Container(
              margin: const EdgeInsets.only(bottom: AppSpacing.sm),
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
              decoration: BoxDecoration(
                color: context.colors.primary,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(AppRadius.lg),
                  topRight: Radius.circular(AppRadius.lg),
                  bottomLeft: Radius.circular(AppRadius.lg),
                  bottomRight: Radius.circular(AppRadius.xs),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(m.text, style: context.text.bodyLarge?.copyWith(color: context.colors.onPrimary)),
                  const SizedBox(height: 2),
                  Text(
                    '${m.editedAt != null ? '${context.tr(TutorStrings.edited)} · ' : ''}${relativeTime(m.createdAt, context.lang)}',
                    style: context.text.labelSmall?.copyWith(color: context.colors.onPrimary.withValues(alpha: 0.75)),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    final streaming = m.status == MessageStatus.streaming;
    return Semantics(
      liveRegion: streaming,
      container: true,
      child: Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.md),
        child: Material(
          color: context.colors.surfaceContainerLow,
          shape: RoundedRectangleBorder(
            side: BorderSide(color: context.colors.outlineVariant),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(AppRadius.xs),
              topRight: Radius.circular(AppRadius.lg),
              bottomLeft: Radius.circular(AppRadius.lg),
              bottomRight: Radius.circular(AppRadius.lg),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 12,
                      backgroundColor: context.colors.primaryContainer,
                      child: Icon(Icons.smart_toy, size: 14, color: context.colors.primary),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    if (m.mode != null)
                      Flexible(
                        child: Text(
                          context.tr(m.mode!.label),
                          style: context.text.labelSmall,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    const Spacer(),
                    if (m.grounding != null) _GroundingPill(grounding: m.grounding!),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                if (m.status == MessageStatus.error)
                  _ErrorBody(message: m, onRetry: () => ctl.retry(conversationId, m.id))
                else if (m.text.isEmpty && streaming)
                  Row(
                    children: [
                      const SizedBox.square(dimension: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                      const SizedBox(width: AppSpacing.sm),
                      Text(context.tr(TutorStrings.thinking), style: context.text.bodyMedium),
                    ],
                  )
                else
                  RichContent(m.text, selectable: !streaming),
                if (!streaming && m.status == MessageStatus.done) ...[
                  for (final w in m.warnings) ...[
                    const SizedBox(height: AppSpacing.sm),
                    InfoBanner(
                      message: context.tr(w.label),
                      tone: w == AnswerWarning.integrity || w == AnswerWarning.offTopic ? Tone.info : Tone.warning,
                      action: w == AnswerWarning.lowConfidence || w == AnswerWarning.missingKnowledge
                          ? TextButton(
                              onPressed: m.teacherReview ? null : () => _teacherReview(context, ref),
                              child: Text(context.tr(TutorStrings.teacherReview)),
                            )
                          : null,
                    ),
                  ],
                  if (m.confidence != null) ...[
                    const SizedBox(height: AppSpacing.sm),
                    Row(
                      children: [
                        Text('${context.tr(TutorStrings.confidence)}: ', style: context.text.labelSmall),
                        SizedBox(
                          width: 80,
                          child: LinearProgressIndicator(
                            value: m.confidence,
                            minHeight: 5,
                            color: m.confidence! >= 0.75
                                ? context.palette.success
                                : (m.confidence! >= 0.6 ? context.palette.warning : context.palette.danger),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Text(context.pct(m.confidence! * 100), style: context.text.labelSmall),
                        const Spacer(),
                        const SimulatedBadge(),
                      ],
                    ),
                  ],
                  if (m.sources.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.sm),
                    Text(context.tr(TutorStrings.sources), style: context.text.labelMedium),
                    const SizedBox(height: AppSpacing.xs),
                    for (final s in m.sources) SourceCard(source: s),
                  ],
                  if (m.relatedQuestionIds.isNotEmpty) _RelatedQuestions(ids: m.relatedQuestionIds),
                  if (m.teacherReview) ...[
                    const SizedBox(height: AppSpacing.sm),
                    Pill(
                      context.tr(TutorStrings.teacherReviewPending),
                      tone: Tone.info,
                      icon: Icons.person_search_outlined,
                    ),
                  ],
                  if (m.versions.isNotEmpty)
                    Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: TextButton.icon(
                        onPressed: () => _showVersions(context, m),
                        icon: const Icon(Icons.history, size: 16),
                        label: Text(context.tr(TutorStrings.versionsLabel.fill({'n': m.versions.length}))),
                      ),
                    ),
                  _Actions(
                    conversationId: conversationId,
                    message: m,
                    onTeacherReview: () => _teacherReview(context, ref),
                    onFollowUp: onFollowUp,
                  ),
                  if (isLast && m.followUps.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.xs),
                    Wrap(
                      spacing: AppSpacing.xs,
                      runSpacing: AppSpacing.xs,
                      children: [
                        for (final f in m.followUps)
                          ActionChip(
                            avatar: const Icon(Icons.subdirectory_arrow_right, size: 16),
                            label: Text(f),
                            onPressed: () => onFollowUp(f),
                          ),
                      ],
                    ),
                  ],
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _teacherReview(BuildContext context, WidgetRef ref) async {
    await ref.read(tutorProvider.notifier).requestTeacherReview(conversationId, message.id);
    if (context.mounted) context.showSnack(TutorStrings.teacherReviewSent);
  }

  void _showVersions(BuildContext context, ChatMessage m) => showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) => DraggableScrollableSheet(
      expand: false,
      builder: (context, controller) => ListView(
        controller: controller,
        padding: AppSpacing.screen,
        children: [
          Text(context.tr(TutorStrings.correctionHistory), style: context.text.titleLarge),
          for (var i = 0; i < m.versions.length; i++) ...[
            const SizedBox(height: AppSpacing.md),
            Text('v${context.n(i + 1)}', style: context.text.labelLarge),
            Card(
              child: Padding(padding: const EdgeInsets.all(AppSpacing.md), child: RichContent(m.versions[i])),
            ),
          ],
        ],
      ),
    ),
  );
}

class _GroundingPill extends StatelessWidget {
  const _GroundingPill({required this.grounding});

  final Grounding grounding;

  @override
  Widget build(BuildContext context) => Pill(
    context.tr(grounding.label),
    icon: grounding.icon,
    tone: switch (grounding) {
      Grounding.verified => Tone.success,
      Grounding.partial => Tone.info,
      Grounding.general => Tone.neutral,
      Grounding.unavailable => Tone.warning,
    },
  );
}

class _ErrorBody extends StatelessWidget {
  const _ErrorBody({required this.message, required this.onRetry});

  final ChatMessage message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final text = switch (message.error) {
      'OFFLINE' || 'NETWORK_ERROR' => TutorStrings.offlineAnswer,
      'INTERRUPTED' => TutorStrings.interrupted,
      _ => TutorStrings.errorAnswer,
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (message.text.isNotEmpty) ...[RichContent(message.text), const SizedBox(height: AppSpacing.sm)],
        InfoBanner(
          message: context.tr(text),
          tone: Tone.danger,
          action: TextButton.icon(
            key: Key('retry.${message.id}'),
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: Text(context.tr(S.retry)),
          ),
        ),
      ],
    );
  }
}

class _Actions extends ConsumerWidget {
  const _Actions({
    required this.conversationId,
    required this.message,
    required this.onTeacherReview,
    required this.onFollowUp,
  });

  final String conversationId;
  final ChatMessage message;
  final VoidCallback onTeacherReview;
  final ValueChanged<String> onFollowUp;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final m = message;
    final ctl = ref.read(tutorProvider.notifier);
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        IconButton(
          tooltip: context.tr(S.copy),
          icon: const Icon(Icons.copy, size: 18),
          onPressed: () async {
            await Clipboard.setData(ClipboardData(text: plainTextOf(m.text)));
            if (context.mounted) context.showSnack(S.copied);
          },
        ),
        IconButton(
          key: Key('regen.${m.id}'),
          tooltip: context.tr(TutorStrings.regenerate),
          icon: const Icon(Icons.autorenew, size: 18),
          onPressed: () => ctl.regenerate(conversationId, m.id),
        ),
        IconButton(
          tooltip: context.tr(TutorStrings.helpful),
          isSelected: m.feedback == 1,
          icon: const Icon(Icons.thumb_up_outlined, size: 18),
          selectedIcon: Icon(Icons.thumb_up, size: 18, color: context.palette.success),
          onPressed: () async {
            await ctl.setFeedback(conversationId, m.id, m.feedback == 1 ? null : 1);
            if (context.mounted && m.feedback != 1) context.showSnack(TutorStrings.thanksFeedback);
          },
        ),
        IconButton(
          tooltip: context.tr(TutorStrings.notHelpful),
          isSelected: m.feedback == -1,
          icon: const Icon(Icons.thumb_down_outlined, size: 18),
          selectedIcon: Icon(Icons.thumb_down, size: 18, color: context.palette.danger),
          onPressed: () => ctl.setFeedback(conversationId, m.id, m.feedback == -1 ? null : -1),
        ),
        IconButton(
          key: Key('bookmark.${m.id}'),
          tooltip: context.tr(m.bookmarked ? S.removeBookmark : S.bookmark),
          isSelected: m.bookmarked,
          icon: const Icon(Icons.bookmark_border, size: 18),
          selectedIcon: const Icon(Icons.bookmark, size: 18),
          onPressed: () => ctl.toggleBookmark(conversationId, m.id),
        ),
        PopupMenuButton<String>(
          tooltip: context.tr(S.more),
          icon: const Icon(Icons.more_horiz, size: 18),
          onSelected: (v) async {
            switch (v) {
              case 'simpler':
                onFollowUp(context.tr(TutorStrings.simplerPrompt));
              case 'deeper':
                onFollowUp(context.tr(TutorStrings.deeperPrompt));
              case 'teacher':
                onTeacherReview();
              case 'report':
                final reason = await showReportDialog(context, reasons: TutorStrings.reportReasons);
                if (reason != null) {
                  await ctl.report(conversationId, m.id, reason);
                  if (context.mounted) context.showSnack(S.reportSent);
                }
            }
          },
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'simpler',
              child: ListTile(leading: const Icon(Icons.child_care), title: Text(context.tr(TutorStrings.simpler))),
            ),
            PopupMenuItem(
              value: 'deeper',
              child: ListTile(leading: const Icon(Icons.layers_outlined), title: Text(context.tr(TutorStrings.deeper))),
            ),
            PopupMenuItem(
              value: 'teacher',
              enabled: !m.teacherReview,
              child: ListTile(
                leading: const Icon(Icons.person_search_outlined),
                title: Text(context.tr(TutorStrings.teacherReview)),
              ),
            ),
            PopupMenuItem(
              value: 'report',
              child: ListTile(leading: const Icon(Icons.flag_outlined), title: Text(context.tr(S.report))),
            ),
          ],
        ),
      ],
    );
  }
}

class _RelatedQuestions extends ConsumerWidget {
  const _RelatedQuestions({required this.ids});

  final List<String> ids;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final all = {for (final q in ref.watch(questionRepositoryProvider).cached) q.id: q};
    final qs = [for (final id in ids) ?all[id]];
    if (qs.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(context.tr(TutorStrings.relatedQuestions), style: context.text.labelMedium),
          for (final q in qs)
            ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              leading: Icon(q.type.icon, size: 18),
              title: InlineRich(context.tr(q.stem), style: context.text.bodyMedium!, maxLines: 2),
              trailing: const Icon(Icons.chevron_right, size: 18),
              onTap: () => context.push(AppRoutes.question(q.id)),
            ),
        ],
      ),
    );
  }
}

/// Compact citation card; tap opens the source viewer.
class SourceCard extends StatelessWidget {
  const SourceCard({super.key, required this.source});

  final SourceRef source;

  @override
  Widget build(BuildContext context) {
    final s = source;
    final old = s.curriculumVersionId != 'nctb-2025';
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.xs),
      color: context.colors.surfaceContainerHigh,
      child: InkWell(
        key: Key('source.${s.id}'),
        onTap: () => showSourceViewer(context, s),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.sm),
          child: Row(
            children: [
              Icon(Icons.menu_book_outlined, color: context.colors.primary, size: 20),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.tr(s.bookTitle),
                      style: context.text.labelLarge,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      '${context.tr(s.chapterTitle)} · ${context.tr(TutorStrings.page.fill({'n': s.page}))}',
                      style: context.text.bodySmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (old) Pill(context.tr(const Tr('পুরনো সিলেবাস', 'Old syllabus')), tone: Tone.warning),
              const Icon(Icons.open_in_new, size: 16),
            ],
          ),
        ),
      ),
    );
  }
}

/// Bottom sheet showing the cited passage with the matched sentence highlighted.
void showSourceViewer(BuildContext context, SourceRef s) {
  final version = curriculumVersions.where((v) => v.id == s.curriculumVersionId).firstOrNull;
  showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (context) {
      final excerpt = context.tr(s.excerpt);
      final firstSentence = excerpt.split(RegExp(r'(?<=[।.])\s')).first;
      return Padding(
        padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(context.tr(TutorStrings.sourceViewer), style: context.text.titleLarge),
            const SizedBox(height: AppSpacing.sm),
            Text(context.tr(s.bookTitle), style: context.text.titleSmall),
            Text('${context.tr(s.chapterTitle)} · ${context.tr(TutorStrings.page.fill({'n': s.page}))}'),
            if (version != null) Text(context.tr(version.name), style: context.text.bodySmall),
            const SizedBox(height: AppSpacing.md),
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(color: context.colors.surfaceContainerHigh, borderRadius: AppRadius.field),
              child: RichContent(excerpt, highlight: firstSentence, selectable: true),
            ),
            const SizedBox(height: AppSpacing.md),
            InfoBanner(
              message: context.tr(TutorStrings.sampleSourceNote),
              tone: Tone.warning,
              icon: Icons.science_outlined,
            ),
            if (version?.note != null) ...[
              const SizedBox(height: AppSpacing.sm),
              InfoBanner(message: context.tr(version!.note!), tone: Tone.warning),
            ],
            const SizedBox(height: AppSpacing.md),
            OutlinedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                context.push(AppRoutes.book(s.bookId));
              },
              icon: const Icon(Icons.local_library_outlined),
              label: Text(context.tr(const Tr('বইয়ে খুলুন', 'Open in library'))),
            ),
          ],
        ),
      );
    },
  );
}

/// Context picker: level, class, subject, paper, chapter, topic, curriculum, language, mode.
Future<TutorContext?> showContextSheet(BuildContext context, WidgetRef ref, TutorContext initial) {
  return showModalBottomSheet<TutorContext>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => _ContextSheet(initial: initial),
  );
}

class _ContextSheet extends ConsumerStatefulWidget {
  const _ContextSheet({required this.initial});

  final TutorContext initial;

  @override
  ConsumerState<_ContextSheet> createState() => _ContextSheetState();
}

class _ContextSheetState extends ConsumerState<_ContextSheet> {
  late TutorContext c = widget.initial;

  @override
  Widget build(BuildContext context) {
    final repo = ref.read(curriculumRepositoryProvider);
    final subjects = repo.cachedSubjects.where((s) => s.level == c.level).toList();
    final subject = subjects.where((s) => s.id == c.subjectId).firstOrNull;
    final chapters =
        subject?.chapters.where((ch) => c.paper == null || ch.paper == c.paper).toList() ?? const <Chapter>[];
    final chapter = chapters.where((ch) => ch.id == c.chapterId).firstOrNull;
    Widget label(Tr t) => Padding(
      padding: const EdgeInsets.only(top: AppSpacing.md, bottom: AppSpacing.xs),
      child: Text(context.tr(t), style: context.text.titleSmall),
    );
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.85,
      maxChildSize: 0.95,
      builder: (context, controller) => Column(
        children: [
          Expanded(
            child: ListView(
              controller: controller,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              children: [
                Text(context.tr(TutorStrings.context), style: context.text.titleLarge),
                Text(context.tr(TutorStrings.contextHint), style: context.text.bodySmall),
                label(TutorStrings.mode),
                Wrap(
                  spacing: AppSpacing.xs,
                  runSpacing: AppSpacing.xs,
                  children: [
                    for (final m in TeachingMode.values)
                      ChoiceChip(
                        key: Key('mode.${m.name}'),
                        avatar: Icon(m.icon, size: 16),
                        label: Text(context.tr(m.label)),
                        selected: c.mode == m,
                        onSelected: (_) => setState(() => c = c.copyWith(mode: m)),
                      ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.xs),
                  child: Text(
                    context.tr(c.mode.hint),
                    style: context.text.bodySmall?.copyWith(color: context.colors.onSurfaceVariant),
                  ),
                ),
                label(TutorStrings.language),
                SegmentedButton<TutorLanguage>(
                  segments: [
                    for (final l in TutorLanguage.values)
                      ButtonSegment(value: l, label: Text(context.tr(l.label), maxLines: 1)),
                  ],
                  selected: {c.language},
                  onSelectionChanged: (v) => setState(() => c = c.copyWith(language: v.first)),
                ),
                label(TutorStrings.level),
                Row(
                  children: [
                    for (final l in EducationLevel.values)
                      Padding(
                        padding: const EdgeInsetsDirectional.only(end: AppSpacing.xs),
                        child: ChoiceChip(
                          label: Text(context.tr(l.label)),
                          selected: c.level == l,
                          onSelected: (_) => setState(
                            () => c = c.copyWith(
                              level: l,
                              classYear: l.classes.last,
                              subjectId: () => null,
                              chapterId: () => null,
                              topicId: () => null,
                              paper: () => null,
                            ),
                          ),
                        ),
                      ),
                    const SizedBox(width: AppSpacing.md),
                    for (final y in c.level.classes)
                      Padding(
                        padding: const EdgeInsetsDirectional.only(end: AppSpacing.xs),
                        child: ChoiceChip(
                          label: Text('${context.tr(TutorStrings.classYear)} ${context.n(y)}'),
                          selected: c.classYear == y,
                          onSelected: (_) => setState(() => c = c.copyWith(classYear: y)),
                        ),
                      ),
                  ],
                ),
                label(S.subject),
                DropdownButtonFormField<String?>(
                  key: ValueKey('subject-${c.level.name}'),
                  initialValue: c.subjectId,
                  isExpanded: true,
                  items: [
                    DropdownMenuItem<String?>(child: Text(context.tr(TutorStrings.anySubject))),
                    for (final s in subjects) DropdownMenuItem(value: s.id, child: Text(context.tr(s.name))),
                  ],
                  onChanged: (v) => setState(
                    () => c = c.copyWith(
                      subjectId: () => v,
                      chapterId: () => null,
                      topicId: () => null,
                      paper: () => null,
                    ),
                  ),
                ),
                if (subject != null && subject.papers > 1) ...[
                  label(S.paper),
                  SegmentedButton<int?>(
                    segments: [
                      ButtonSegment(value: null, label: Text(context.tr(S.all))),
                      for (var p = 1; p <= subject.papers; p++) ButtonSegment(value: p, label: Text(context.n(p))),
                    ],
                    selected: {c.paper},
                    onSelectionChanged: (v) => setState(
                      () => c = c.copyWith(paper: () => v.first, chapterId: () => null, topicId: () => null),
                    ),
                  ),
                ],
                if (subject != null) ...[
                  label(S.chapter),
                  DropdownButtonFormField<String?>(
                    key: ValueKey('chapter-${c.subjectId}-${c.paper}'),
                    initialValue: c.chapterId,
                    isExpanded: true,
                    items: [
                      DropdownMenuItem<String?>(child: Text(context.tr(TutorStrings.anyChapter))),
                      for (final ch in chapters)
                        DropdownMenuItem(
                          value: ch.id,
                          child: Text(
                            '${context.n(ch.number)}. ${context.tr(ch.title)}',
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                    onChanged: (v) => setState(() => c = c.copyWith(chapterId: () => v, topicId: () => null)),
                  ),
                ],
                if (chapter != null) ...[
                  label(S.topic),
                  DropdownButtonFormField<String?>(
                    key: ValueKey('topic-${c.chapterId}'),
                    initialValue: c.topicId,
                    isExpanded: true,
                    items: [
                      DropdownMenuItem<String?>(child: Text(context.tr(TutorStrings.anyTopic))),
                      for (final t in chapter.topics)
                        DropdownMenuItem(
                          value: t.id,
                          child: Text(context.tr(t.title), overflow: TextOverflow.ellipsis),
                        ),
                    ],
                    onChanged: (v) => setState(() => c = c.copyWith(topicId: () => v)),
                  ),
                ],
                label(TutorStrings.curriculum),
                RadioGroup<String>(
                  groupValue: c.curriculumVersionId,
                  onChanged: (id) => setState(() => c = c.copyWith(curriculumVersionId: id)),
                  child: Column(
                    children: [
                      for (final v in curriculumVersions)
                        RadioListTile<String>(
                          contentPadding: EdgeInsets.zero,
                          value: v.id,
                          title: Text(context.tr(v.name)),
                          subtitle: v.note == null ? null : Text(context.tr(v.note!)),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  key: const Key('context.apply'),
                  onPressed: () => Navigator.pop(context, c),
                  child: Text(context.tr(S.apply)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// One-line summary of a context for chips and list subtitles.
String contextLabel(BuildContext context, WidgetRef ref, TutorContext c) {
  final repo = ref.read(curriculumRepositoryProvider);
  final parts = <String>[context.tr(c.level.label)];
  final subject = repo.cachedSubjects.where((s) => s.id == c.subjectId).firstOrNull;
  if (subject != null) parts.add(context.tr(subject.name));
  if (c.chapterId != null) {
    final ch = repo.findChapter(c.chapterId!);
    if (ch != null) parts.add('${context.tr(S.chapter)} ${context.n(ch.chapter.number)}');
  }
  if (c.topicId != null) {
    final t = repo.findTopic(c.topicId!);
    if (t != null) parts.add(context.tr(t.topic.title));
  }
  return parts.join(' · ');
}
