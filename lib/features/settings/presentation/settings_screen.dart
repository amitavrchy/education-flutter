import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/config/env.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/theme_mode_controller.dart';
import '../../../shared/widgets/app_page_scaffold.dart';
import '../../../shared/widgets/section_header.dart';
import '../../auth/application/auth_controller.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authControllerProvider);
    final themeMode = ref.watch(themeModeProvider);
    final user = auth is Authenticated ? auth.user : null;

    return AppPageScaffold(
      title: 'সেটিংস',
      showShortcuts: false,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (user != null)
            Card(
              child: ListTile(
                leading: const CircleAvatar(child: Icon(Icons.person_outline)),
                title: Text(user.name),
                subtitle: Text('${user.role.labelBn} · ${user.email ?? user.phone ?? ''}'),
              ),
            ),
          const SectionHeader(title: 'থিম'),
          SegmentedButton<ThemeMode>(
            segments: const [
              ButtonSegment(value: ThemeMode.light, label: Text('লাইট'), icon: Icon(Icons.light_mode_outlined)),
              ButtonSegment(value: ThemeMode.system, label: Text('সিস্টেম'), icon: Icon(Icons.brightness_auto_outlined)),
              ButtonSegment(value: ThemeMode.dark, label: Text('ডার্ক'), icon: Icon(Icons.dark_mode_outlined)),
            ],
            selected: {themeMode},
            onSelectionChanged: (selection) =>
                ref.read(themeModeProvider.notifier).set(selection.first),
          ),
          const SectionHeader(title: 'অ্যাপ'),
          Card(
            child: ListTile(
              leading: const Icon(Icons.info_outline),
              title: const Text('সংস্করণ'),
              subtitle: Text('0.1.0 · ${Env.useMockApi ? 'ডেমো মোড' : Env.apiBaseUrl}'),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          OutlinedButton.icon(
            onPressed: () => ref.read(authControllerProvider.notifier).logout(),
            icon: const Icon(Icons.logout),
            label: const Text('লগআউট'),
          ),
        ],
      ),
    );
  }
}
