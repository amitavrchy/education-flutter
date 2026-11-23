import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/router/app_routes.dart';
import '../../core/l10n/common_strings.dart';
import '../../core/l10n/tr.dart';
import '../../core/settings/app_settings.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../features/notifications/application/notifications_controller.dart';

/// Standard page: context-aware app bar (search, notifications, settings shortcuts),
/// offline banner, safe area and width-constrained body for tablets.
class AppPageScaffold extends ConsumerWidget {
  const AppPageScaffold({
    super.key,
    required this.title,
    required this.body,
    this.showShortcuts = true,
    this.scrollable = true,
    this.actions,
    this.floatingActionButton,
    this.bottom,
    this.bottomBar,
    this.padding = AppSpacing.screen,
    this.leading,
  });

  final String title;
  final Widget body;
  final bool showShortcuts;
  final bool scrollable;
  final List<Widget>? actions;
  final Widget? floatingActionButton;
  final PreferredSizeWidget? bottom;
  final Widget? bottomBar;
  final EdgeInsets padding;
  final Widget? leading;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final offline = ref.watch(appSettingsProvider.select((s) => s.simulateOffline));
    final unread = showShortcuts ? ref.watch(unreadNotificationCountProvider) : 0;
    Widget content = scrollable
        ? SingleChildScrollView(padding: padding, child: body)
        : Padding(padding: padding, child: body);
    content = Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: AppSpacing.maxContentWidth),
        child: content,
      ),
    );
    return Scaffold(
      appBar: AppBar(
        leading: leading,
        title: Text(title),
        bottom: bottom,
        actions: [
          ...?actions,
          if (showShortcuts) ...[
            IconButton(
              tooltip: context.tr(S.search),
              icon: const Icon(Icons.search),
              onPressed: () => context.push(AppRoutes.search),
            ),
            IconButton(
              tooltip: context.tr(S.notifications),
              icon: Badge(
                isLabelVisible: unread > 0,
                label: Text(context.n(unread)),
                child: const Icon(Icons.notifications_outlined),
              ),
              onPressed: () => context.push(AppRoutes.notifications),
            ),
          ],
        ],
      ),
      floatingActionButton: floatingActionButton,
      bottomNavigationBar: bottomBar,
      body: SafeArea(
        child: Column(
          children: [
            if (offline) const OfflineBanner(),
            Expanded(child: content),
          ],
        ),
      ),
    );
  }
}

class OfflineBanner extends StatelessWidget {
  const OfflineBanner({super.key});

  @override
  Widget build(BuildContext context) => Semantics(
    liveRegion: true,
    child: Container(
      width: double.infinity,
      color: context.palette.warningContainer,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.xs + 2),
      child: Row(
        children: [
          Icon(Icons.cloud_off, size: 16, color: context.palette.warning),
          const SizedBox(width: AppSpacing.sm),
          Expanded(child: Text(context.tr(S.offlineBanner), style: context.text.labelMedium)),
        ],
      ),
    ),
  );
}
