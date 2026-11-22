import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../app/navigation/portal_config.dart';
import '../../../app/router/app_routes.dart';
import '../../../shared/widgets/app_page_scaffold.dart';

/// Lists every feature of a portal that doesn't fit in the bottom navigation.
class MoreMenuScreen extends StatelessWidget {
  const MoreMenuScreen({super.key, required this.config});

  final PortalConfig config;

  @override
  Widget build(BuildContext context) {
    return AppPageScaffold(
      title: 'আরও',
      body: Card(
        child: Column(
          children: [
            for (final item in config.menuItems)
              ListTile(
                leading: Icon(item.icon),
                title: Text(item.label),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.go('${config.morePath}/${item.slug}'),
              ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.settings_outlined),
              title: const Text('সেটিংস'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push(AppRoutes.settings),
            ),
          ],
        ),
      ),
    );
  }
}
