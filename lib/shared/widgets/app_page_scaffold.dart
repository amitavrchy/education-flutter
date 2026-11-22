import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/router/app_routes.dart';
import '../../core/theme/app_spacing.dart';

/// Standard page: app bar with notification + settings shortcuts and padded scrolling body.
class AppPageScaffold extends StatelessWidget {
  const AppPageScaffold({
    super.key,
    required this.title,
    required this.body,
    this.showShortcuts = true,
    this.scrollable = true,
  });

  final String title;
  final Widget body;
  final bool showShortcuts;
  final bool scrollable;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: showShortcuts
            ? [
                IconButton(
                  tooltip: 'নোটিফিকেশন',
                  icon: const Icon(Icons.notifications_outlined),
                  onPressed: () => context.push(AppRoutes.notifications),
                ),
                IconButton(
                  tooltip: 'সেটিংস',
                  icon: const Icon(Icons.settings_outlined),
                  onPressed: () => context.push(AppRoutes.settings),
                ),
              ]
            : null,
      ),
      body: SafeArea(
        child: scrollable
            ? SingleChildScrollView(padding: AppSpacing.screen, child: body)
            : Padding(padding: AppSpacing.screen, child: body),
      ),
    );
  }
}
