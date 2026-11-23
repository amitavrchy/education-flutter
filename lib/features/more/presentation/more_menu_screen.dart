import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../app/navigation/portal_config.dart';
import '../../../app/router/app_routes.dart';
import '../../../core/l10n/common_strings.dart';
import '../../../core/l10n/tr.dart';
import '../../../shared/widgets/app_page_scaffold.dart';
import '../../../shared/widgets/section_header.dart';

/// Lists every feature of a portal that doesn't fit in the bottom navigation, grouped.
class MoreMenuScreen extends StatelessWidget {
  const MoreMenuScreen({super.key, required this.config});

  final PortalConfig config;

  @override
  Widget build(BuildContext context) {
    final groups = <String?, List<PortalMenuItem>>{};
    for (final item in config.menuItems) {
      groups.putIfAbsent(item.group, () => []).add(item);
    }
    return AppPageScaffold(
      title: context.tr(S.more),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final entry in groups.entries) ...[
            if (entry.key != null) SectionHeader(title: entry.key!),
            Card(
              child: Column(
                children: [
                  for (final item in entry.value)
                    ListTile(
                      key: Key('more.${item.slug}'),
                      leading: Icon(item.icon),
                      title: Text(item.label),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => item.route != null
                          ? context.push(item.route!)
                          : context.go('${config.morePath}/${item.slug}'),
                    ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 16),
          Card(
            child: ListTile(
              key: const Key('more.settings'),
              leading: const Icon(Icons.settings_outlined),
              title: Text(context.tr(S.settings)),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push(AppRoutes.settings),
            ),
          ),
        ],
      ),
    );
  }
}
