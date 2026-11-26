import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../app/router/app_routes.dart';
import '../../../core/l10n/tr.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/time_format.dart';
import '../../../shared/widgets/app_page_scaffold.dart';
import '../../../shared/widgets/badges.dart';
import '../../../shared/widgets/cards.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/section_header.dart';
import '../../curriculum/domain/curriculum_models.dart';
import '../application/avatar_controller.dart';
import '../avatar_strings.dart';
import '../data/book_catalog.dart';
import 'teacher_avatar.dart';

/// Student: every book's teacher avatar, plus recent classes.
class AvatarGalleryScreen extends ConsumerStatefulWidget {
  const AvatarGalleryScreen({super.key});

  @override
  ConsumerState<AvatarGalleryScreen> createState() => _AvatarGalleryScreenState();
}

class _AvatarGalleryScreenState extends ConsumerState<AvatarGalleryScreen> {
  String _query = '';
  EducationLevel? _level;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(avatarControllerProvider);
    final me = ref.read(avatarControllerProvider.notifier).currentUserId;
    final recent = state.sessionsOf(me).take(4).toList();
    final q = _query.trim().toLowerCase();
    final list = [
      for (final (book, avatar) in state.available)
        if ((_level == null || book.level == _level) && (q.isEmpty || book.title.matches(q) || avatar.name.matches(q) || book.subject.name.matches(q)))
          (book, avatar),
    ];
    return AppPageScaffold(
      title: context.tr(AvatarStrings.galleryTitle),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(context.tr(AvatarStrings.galleryHeadline), style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: AppSpacing.xs),
          Text(
            context.tr(AvatarStrings.galleryHint),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
          ),
          if (recent.isNotEmpty) ...[
            SectionHeader(title: context.tr(AvatarStrings.recentClasses)),
            SizedBox(
              height: 64,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: recent.length,
                separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.sm),
                itemBuilder: (context, i) {
                  final s = recent[i];
                  final book = bookById(s.bookId);
                  return SizedBox(
                    width: 200,
                    child: TapCard(
                      onTap: () => context.push(AppRoutes.avatarClass(s.bookId, sessionId: s.id)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(s.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.labelLarge),
                          Text(
                            '${book == null ? '' : context.tr(book.subject.name)} · ${relativeTime(s.lastAt, context.lang)}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.lg),
          TextField(
            key: const Key('avatar.search'),
            decoration: InputDecoration(prefixIcon: const Icon(Icons.search), hintText: context.tr(AvatarStrings.searchHint)),
            onChanged: (v) => setState(() => _query = v),
          ),
          const SizedBox(height: AppSpacing.sm),
          ChoiceChipBar<EducationLevel?>(
            options: const [null, EducationLevel.ssc, EducationLevel.hsc],
            selected: _level,
            labelOf: (l) => l == null ? context.tr(AvatarStrings.all) : l.code,
            onSelected: (l) => setState(() => _level = l),
          ),
          const SizedBox(height: AppSpacing.md),
          if (list.isEmpty)
            EmptyState(title: context.tr(AvatarStrings.noBooks), icon: Icons.menu_book_outlined)
          else
            LayoutBuilder(
              builder: (context, box) {
                final columns = box.maxWidth > 700 ? 4 : (box.maxWidth > 420 ? 3 : 2);
                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: list.length,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: columns,
                    mainAxisSpacing: AppSpacing.md,
                    crossAxisSpacing: AppSpacing.md,
                    childAspectRatio: 0.62,
                  ),
                  itemBuilder: (context, i) => _AvatarCard(book: list[i].$1),
                );
              },
            ),
        ],
      ),
    );
  }
}

class _AvatarCard extends ConsumerWidget {
  const _AvatarCard({required this.book});

  final Book book;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final avatar = ref.read(avatarControllerProvider.notifier).avatarFor(book);
    final text = Theme.of(context).textTheme;
    return Card(
      clipBehavior: Clip.antiAlias,
      margin: EdgeInsets.zero,
      child: InkWell(
        key: Key('avatar.card.${book.id}'),
        onTap: () => context.push(AppRoutes.avatarClass(book.id)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: ColoredBox(
                color: Color(avatar.appearance.background),
                child: Center(child: TeacherAvatar(appearance: avatar.appearance, size: 110)),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.sm),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(context.tr(avatar.name), maxLines: 1, overflow: TextOverflow.ellipsis, style: text.titleSmall),
                      ),
                      Pill(book.level.code),
                    ],
                  ),
                  Text(context.tr(book.subject.name), maxLines: 1, overflow: TextOverflow.ellipsis, style: text.bodySmall),
                  const SizedBox(height: AppSpacing.xs),
                  Row(
                    children: [
                      Icon(Icons.forum_outlined, size: 16, color: Theme.of(context).colorScheme.primary),
                      const SizedBox(width: AppSpacing.xs),
                      Text(context.tr(AvatarStrings.ask), style: text.labelMedium?.copyWith(color: Theme.of(context).colorScheme.primary)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
