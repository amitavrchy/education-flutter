import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../app/router/app_routes.dart';
import '../../../core/l10n/tr.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/app_page_scaffold.dart';
import '../../../shared/widgets/cards.dart';
import '../../../shared/widgets/section_header.dart';
import '../practice_strings.dart';

/// Practice tab: entry point to the question bank, exams, archives and results.
class PracticeHubScreen extends StatelessWidget {
  const PracticeHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const c = AppColors.categorical;
    Widget tile(Key key, IconData icon, Tr title, Tr subtitle, Color color, String route) => Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: NavTile(
        key: key,
        icon: icon,
        color: color,
        title: context.tr(title),
        subtitle: context.tr(subtitle),
        onTap: () => context.push(route),
      ),
    );
    return AppPageScaffold(
      title: context.tr(PracticeStrings.practice),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Card(
            color: context.colors.primaryContainer,
            child: InkWell(
              key: const Key('practice.daily'),
              onTap: () => context.push(AppRoutes.practiceSession(mode: 'daily')),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Row(
                  children: [
                    Icon(Icons.bolt, size: 36, color: context.colors.onPrimaryContainer),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(context.tr(PracticeStrings.dailyQuiz), style: context.text.titleMedium),
                          Text(context.tr(PracticeStrings.dailyQuizHint), style: context.text.bodySmall),
                        ],
                      ),
                    ),
                    const Icon(Icons.arrow_forward),
                  ],
                ),
              ),
            ),
          ),
          SectionHeader(title: context.tr(PracticeStrings.practiceSection)),
          tile(const Key('practice.bank'), Icons.help_outline, PracticeStrings.questionBank,
              PracticeStrings.questionBankHint, c[0], AppRoutes.questionBank()),
          tile(const Key('practice.mixed'), Icons.shuffle, PracticeStrings.mixedPractice,
              PracticeStrings.mixedPracticeHint, c[5], AppRoutes.practiceSession(mode: 'mixed')),
          tile(const Key('practice.bookmarks'), Icons.bookmark_border, PracticeStrings.bookmarks,
              PracticeStrings.bookmarksHint, c[6], AppRoutes.bookmarks),
          SectionHeader(title: context.tr(PracticeStrings.examSection)),
          tile(const Key('practice.exams'), Icons.assignment_outlined, PracticeStrings.examCenter,
              PracticeStrings.examCenterHint, c[3], AppRoutes.examCenter),
          tile(const Key('practice.results'), Icons.leaderboard_outlined, PracticeStrings.results,
              PracticeStrings.resultsHint, c[1], AppRoutes.examResults),
          SectionHeader(title: context.tr(PracticeStrings.archiveSection)),
          tile(const Key('practice.board'), Icons.history_edu_outlined, PracticeStrings.boardArchive,
              PracticeStrings.boardArchiveHint, c[2], AppRoutes.boardArchive),
          tile(const Key('practice.institution'), Icons.account_balance_outlined, PracticeStrings.institutionArchive,
              PracticeStrings.institutionArchiveHint, c[4], AppRoutes.institutionArchive),
          tile(const Key('practice.handwriting'), Icons.draw_outlined, PracticeStrings.handwriting,
              PracticeStrings.handwritingHint, c[7], AppRoutes.handwriting),
        ],
      ),
    );
  }
}
