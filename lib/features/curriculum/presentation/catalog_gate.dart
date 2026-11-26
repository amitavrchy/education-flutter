import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/l10n/tr.dart';
import '../../../core/theme/app_spacing.dart';
import '../../auth/application/auth_controller.dart';
import '../application/catalog_sync.dart';

/// API mode: holds the signed-in app until the server curriculum and question bank are on the
/// device (first launch only; later launches use the cache and refresh in the background).
class CatalogGate extends ConsumerWidget {
  const CatalogGate({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authControllerProvider);
    final catalog = ref.watch(catalogSyncProvider);
    if (auth is! Authenticated || catalog.ready) return child;
    final error = catalog.error != null && !catalog.syncing;
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (error) const Icon(Icons.cloud_off, size: 48) else const CircularProgressIndicator(),
              const SizedBox(height: AppSpacing.lg),
              Text(
                context.tr(error
                    ? const Tr('কারিকুলাম ডাউনলোড করা যায়নি। ইন্টারনেট সংযোগ দেখে আবার চেষ্টা করুন।', "Couldn't download the curriculum. Check your connection and try again.")
                    : const Tr('কারিকুলাম ও প্রশ্নব্যাংক প্রস্তুত হচ্ছে…', 'Preparing the curriculum and question bank…')),
                textAlign: TextAlign.center,
              ),
              if (error) ...[
                const SizedBox(height: AppSpacing.md),
                FilledButton(key: const Key('catalog.retry'), onPressed: () => ref.read(catalogSyncProvider.notifier).sync(), child: Text(context.tr(const Tr('আবার চেষ্টা', 'Retry')))),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
