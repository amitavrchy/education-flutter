import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../app/router/app_routes.dart';
import '../../../core/config/env.dart';
import '../../../core/l10n/common_strings.dart';
import '../../../core/l10n/tr.dart';
import '../../../core/settings/app_settings.dart';
import '../../../core/storage/local_store.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/app_page_scaffold.dart';
import '../../../shared/widgets/feedback.dart';
import '../../../shared/widgets/section_header.dart';
import '../../auth/application/auth_controller.dart';
import '../../auth/domain/app_user.dart';
import '../../parent/guardian_controller.dart';
import '../../profile/application/student_profile_controller.dart';
import '../learning_prefs.dart';
import '../settings_strings.dart';

/// Device settings: appearance, language, accessibility, demo tools, storage and account.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authControllerProvider);
    final settings = ref.watch(appSettingsProvider);
    final controller = ref.read(appSettingsProvider.notifier);
    final user = auth is Authenticated ? auth.user : null;
    final store = ref.watch(localStoreProvider);

    return AppPageScaffold(
      title: context.tr(S.settings),
      showShortcuts: false,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (user != null)
            Card(
              child: ListTile(
                leading: const ProfileAvatar(),
                title: Text(user.name),
                subtitle: Text('${user.role.labelBn} · ${user.email ?? user.phone ?? ''}'),
                trailing: user.role == UserRole.student ? const Icon(Icons.chevron_right) : null,
                onTap: user.role == UserRole.student ? () => context.push(AppRoutes.profile) : null,
              ),
            ),
          PreferenceLinks(student: user?.role == UserRole.student),
          if (user?.role == UserRole.student) const _StudentAccountCard(),
          SectionHeader(title: context.tr(SettingsStrings.appearance)),
          SegmentedButton<ThemeMode>(
            segments: [
              ButtonSegment(
                value: ThemeMode.light,
                label: Text(context.tr(SettingsStrings.light)),
                icon: const Icon(Icons.light_mode_outlined),
              ),
              ButtonSegment(
                value: ThemeMode.system,
                label: Text(context.tr(SettingsStrings.system)),
                icon: const Icon(Icons.brightness_auto_outlined),
              ),
              ButtonSegment(
                value: ThemeMode.dark,
                label: Text(context.tr(SettingsStrings.dark)),
                icon: const Icon(Icons.dark_mode_outlined),
              ),
            ],
            selected: {settings.themeMode},
            onSelectionChanged: (selection) => controller.setThemeMode(selection.first),
          ),
          SectionHeader(title: context.tr(SettingsStrings.language)),
          SegmentedButton<AppLanguage>(
            key: const Key('settings.language'),
            segments: [
              for (final lang in AppLanguage.values)
                ButtonSegment(value: lang, label: Text(lang.nativeName)),
            ],
            selected: {settings.language},
            onSelectionChanged: (selection) => controller.setLanguage(selection.first),
          ),
          SectionHeader(title: context.tr(SettingsStrings.accessibility)),
          Card(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, 0),
                  child: Row(
                    children: [
                      Expanded(child: Text(context.tr(SettingsStrings.textSize), style: context.text.bodyLarge)),
                      Text('${context.n((settings.textScale * 100).round())}%', style: context.text.labelLarge),
                    ],
                  ),
                ),
                Slider(
                  value: settings.textScale,
                  min: 0.85,
                  max: 1.4,
                  divisions: 11,
                  label: '${context.n((settings.textScale * 100).round())}%',
                  onChanged: (v) => controller.update((s) => s.copyWith(textScale: v)),
                ),
                SwitchListTile(
                  title: Text(context.tr(SettingsStrings.highContrast)),
                  subtitle: Text(context.tr(SettingsStrings.highContrastHint)),
                  value: settings.highContrast,
                  onChanged: (v) => controller.update((s) => s.copyWith(highContrast: v)),
                ),
                SwitchListTile(
                  title: Text(context.tr(SettingsStrings.reducedMotion)),
                  subtitle: Text(context.tr(SettingsStrings.reducedMotionHint)),
                  value: settings.reducedMotion,
                  onChanged: (v) => controller.update((s) => s.copyWith(reducedMotion: v)),
                ),
                SwitchListTile(
                  title: Text(context.tr(SettingsStrings.banglaDigits)),
                  subtitle: Text(context.tr(SettingsStrings.banglaDigitsHint)),
                  value: settings.banglaDigits,
                  onChanged: (v) => controller.update((s) => s.copyWith(banglaDigits: v)),
                ),
              ],
            ),
          ),
          SectionHeader(title: context.tr(SettingsStrings.motivation)),
          Card(
            child: SwitchListTile(
              title: Text(context.tr(SettingsStrings.hideCompetitive)),
              subtitle: Text(context.tr(SettingsStrings.hideCompetitiveHint)),
              value: settings.hideCompetitive,
              onChanged: (v) => controller.update((s) => s.copyWith(hideCompetitive: v)),
            ),
          ),
          SectionHeader(title: context.tr(SettingsStrings.demoTools)),
          Card(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, 0),
                  child: Text(
                    context.tr(SettingsStrings.demoToolsHint),
                    style: context.text.bodySmall?.copyWith(color: context.colors.onSurfaceVariant),
                  ),
                ),
                SwitchListTile(
                  key: const Key('settings.offline'),
                  secondary: const Icon(Icons.cloud_off_outlined),
                  title: Text(context.tr(SettingsStrings.simulateOffline)),
                  value: settings.simulateOffline,
                  onChanged: (v) => controller.update((s) => s.copyWith(simulateOffline: v)),
                ),
                SwitchListTile(
                  secondary: const Icon(Icons.bug_report_outlined),
                  title: Text(context.tr(SettingsStrings.simulateErrors)),
                  value: settings.simulateErrors,
                  onChanged: (v) => controller.update((s) => s.copyWith(simulateErrors: v)),
                ),
              ],
            ),
          ),
          SectionHeader(title: context.tr(SettingsStrings.storage)),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.storage_outlined),
                  title: Text(
                    context.tr(SettingsStrings.storageUsed.fill({'n': (store.approximateBytes / 1024).ceil()})),
                  ),
                ),
                ListTile(
                  leading: Icon(Icons.restart_alt, color: context.palette.danger),
                  title: Text(context.tr(SettingsStrings.resetDemo)),
                  onTap: () => _resetDemo(context, ref),
                ),
              ],
            ),
          ),
          SectionHeader(title: context.tr(SettingsStrings.about)),
          Card(
            child: ListTile(
              leading: const Icon(Icons.info_outline),
              title: Text(context.tr(SettingsStrings.version)),
              subtitle: Text('0.2.0 · ${Env.useMockApi ? context.tr(SettingsStrings.demoMode) : Env.apiBaseUrl}'),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          OutlinedButton.icon(
            key: const Key('settings.logout'),
            onPressed: () async {
              final ok = await showConfirmDialog(context, title: SettingsStrings.logoutConfirm, confirmLabel: S.logout);
              if (ok) await ref.read(authControllerProvider.notifier).logout();
            },
            icon: const Icon(Icons.logout),
            label: Text(context.tr(S.logout)),
          ),
          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }

  Future<void> _resetDemo(BuildContext context, WidgetRef ref) async {
    final ok = await showConfirmDialog(
      context,
      title: SettingsStrings.resetDemo,
      message: SettingsStrings.resetDemoMessage,
      destructive: true,
    );
    if (!ok) return;
    await ref.read(localStoreProvider).clearAll(keep: {AppSettingsController.collection, 'profile'});
    ref.read(dataEpochProvider.notifier).bump();
    if (context.mounted) context.showSnack(SettingsStrings.resetDone);
  }
}

/// Academic profile, goals, connected guardian, institution and help (SET-02, 09, 10, 15, 16, 19–21).
class _StudentAccountCard extends ConsumerWidget {
  const _StudentAccountCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = ref.watch(studentProfileProvider);
    final guardians = [for (final l in ref.watch(guardianProvider).links) if (l.self && l.active) l];
    return Card(
      child: Column(
        children: [
          ListTile(
            key: const Key('settings.goals'),
            leading: const Icon(Icons.flag_outlined),
            title: Text(context.tr(const Tr('লক্ষ্য ও পরীক্ষা', 'Goals & exam target'))),
            subtitle: Text('GPA ${context.n(p.targetGpa.toStringAsFixed(2))} · ${context.n(p.dailyMinutes)} min/day · ${p.level.code} ${context.n(p.examYear)}'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push(AppRoutes.profile),
          ),
          ListTile(
            key: const Key('settings.institution'),
            leading: const Icon(Icons.account_balance_outlined),
            title: Text(context.tr(const Tr('প্রতিষ্ঠান', 'Institution'))),
            subtitle: Text(p.institution.isEmpty ? '—' : p.institution),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push(AppRoutes.profile),
          ),
          ListTile(
            key: const Key('settings.guardian'),
            leading: const Icon(Icons.family_restroom_outlined),
            title: Text(context.tr(const Tr('যুক্ত অভিভাবক', 'Connected guardian'))),
            subtitle: Text(guardians.isEmpty ? context.tr(const Tr('কেউ যুক্ত নেই — গোপনীয়তা থেকে কোড শেয়ার করো', 'None — share your code from Privacy')) : guardians.map((g) => g.relation).join(', ')),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push(AppRoutes.privacy),
          ),
          ListTile(
            leading: const Icon(Icons.download_for_offline_outlined),
            title: Text(context.tr(const Tr('অফলাইন ডাউনলোড', 'Offline downloads'))),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push(AppRoutes.offline),
          ),
          ListTile(
            key: const Key('settings.help'),
            leading: const Icon(Icons.support_agent),
            title: Text(context.tr(const Tr('সাহায্য, মতামত ও সমস্যা রিপোর্ট', 'Help, feedback & report a problem'))),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push(AppRoutes.support),
          ),
        ],
      ),
    );
  }
}
