import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/l10n/tr.dart';
import '../../features/notifications/application/notifications_controller.dart';
import '../../features/notifications/domain/app_notification.dart';
import '../navigation/portal_config.dart';
import '../router/app_routes.dart';

/// Bottom-navigation shell for a portal. Each tab keeps its own navigation stack
/// (StatefulShellRoute.indexedStack), so switching tabs preserves scroll and history.
///
/// Also shows an in-app banner when an urgent notification for this role arrives.
class RoleShell extends ConsumerWidget {
  const RoleShell({super.key, required this.config, required this.navigationShell});

  final PortalConfig config;
  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen<List<AppNotification>>(visibleNotificationsProvider, (prev, next) {
      final before = {for (final n in prev ?? const <AppNotification>[]) n.id};
      final fresh = next.where((n) => !before.contains(n.id) && !n.read && n.priority == NotificationPriority.high).firstOrNull;
      if (prev == null || fresh == null) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            content: Row(
              children: [
                Icon(fresh.category.icon, color: Theme.of(context).colorScheme.onInverseSurface),
                const SizedBox(width: 12),
                Expanded(child: Text(context.tr(fresh.title))),
              ],
            ),
            action: SnackBarAction(label: context.tr(const Tr('দেখো', 'View')), onPressed: () => context.push(AppRoutes.notifications)),
          ),
        );
    });
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: (index) => navigationShell.goBranch(
          index,
          // Tapping the active tab again returns to its first screen.
          initialLocation: index == navigationShell.currentIndex,
        ),
        destinations: [
          for (final tab in config.tabs)
            NavigationDestination(
              icon: Icon(tab.icon),
              selectedIcon: Icon(tab.selectedIcon),
              label: tab.label,
            ),
        ],
      ),
    );
  }
}
