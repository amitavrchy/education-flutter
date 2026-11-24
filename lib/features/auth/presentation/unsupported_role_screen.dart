import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../shared/widgets/empty_state.dart';
import '../application/auth_controller.dart';

/// Institution and super-admin accounts are served by the web dashboard.
class UnsupportedRoleScreen extends ConsumerWidget {
  const UnsupportedRoleScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: SafeArea(
        child: EmptyState(
          icon: Icons.desktop_windows_outlined,
          title: 'এই অ্যাকাউন্টটি ওয়েব ড্যাশবোর্ডের জন্য',
          message: 'অ্যাডমিন অ্যাকাউন্ট ShikkhaAI ওয়েবসাইট থেকে ব্যবহার করুন।',
          action: OutlinedButton.icon(
            onPressed: () => ref.read(authControllerProvider.notifier).logout(),
            icon: const Icon(Icons.logout),
            label: const Text('লগআউট'),
          ),
        ),
      ),
    );
  }
}
