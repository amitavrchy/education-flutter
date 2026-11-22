import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../navigation/portal_config.dart';

/// Bottom-navigation shell for a portal. Each tab keeps its own navigation stack
/// (StatefulShellRoute.indexedStack), so switching tabs preserves scroll and history.
class RoleShell extends StatelessWidget {
  const RoleShell({super.key, required this.config, required this.navigationShell});

  final PortalConfig config;
  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
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
