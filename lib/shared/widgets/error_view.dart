import 'package:material_ui/material_ui.dart';

import '../../core/l10n/common_strings.dart';
import '../../core/l10n/tr.dart';
import '../../core/network/api_exception.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import 'empty_state.dart';

/// Maps any error to a user-facing localized message.
Tr errorMessageOf(Object error) {
  if (error is ApiException) {
    return switch (error.code) {
      'OFFLINE' || 'NETWORK_ERROR' => S.offlineMessage,
      'SIMULATED_ERROR' => S.simulatedError,
      'NOT_FOUND' => S.notFound,
      'FORBIDDEN' => S.permissionDeniedMessage,
      'QUOTA_EXCEEDED' => Tr(error.message, 'You have reached your plan limit.'),
      _ => Tr(error.message, error.message),
    };
  }
  return const Tr('অপ্রত্যাশিত একটি সমস্যা হয়েছে।', 'An unexpected error occurred.');
}

/// Picks the right state view for an error: offline, permission denied or generic.
class ErrorView extends StatelessWidget {
  const ErrorView({super.key, this.error, this.message, this.onRetry, this.compact = false});

  final Object? error;
  final String? message;
  final VoidCallback? onRetry;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final err = error;
    if (err is ApiException && err.isNetworkError) {
      return OfflineView(onRetry: onRetry, compact: compact);
    }
    if (err is ApiException && err.isForbidden) return PermissionDeniedView(compact: compact);
    return EmptyState(
      compact: compact,
      icon: Icons.error_outline,
      iconColor: context.palette.danger,
      title: context.tr(S.errorTitle),
      message: message ?? (err == null ? null : context.tr(errorMessageOf(err))),
      action: onRetry == null
          ? null
          : FilledButton.tonalIcon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: Text(context.tr(S.retry)),
            ),
    );
  }
}

class OfflineView extends StatelessWidget {
  const OfflineView({super.key, this.onRetry, this.compact = false});

  final VoidCallback? onRetry;
  final bool compact;

  @override
  Widget build(BuildContext context) => EmptyState(
    compact: compact,
    icon: Icons.cloud_off_outlined,
    iconColor: context.palette.warning,
    title: context.tr(S.offlineTitle),
    message: context.tr(S.offlineMessage),
    action: onRetry == null
        ? null
        : OutlinedButton.icon(onPressed: onRetry, icon: const Icon(Icons.refresh), label: Text(context.tr(S.retry))),
  );
}

class PermissionDeniedView extends StatelessWidget {
  const PermissionDeniedView({super.key, this.compact = false, this.message});

  final bool compact;
  final String? message;

  @override
  Widget build(BuildContext context) => EmptyState(
    compact: compact,
    icon: Icons.lock_outline,
    iconColor: context.palette.danger,
    title: context.tr(S.permissionDenied),
    message: message ?? context.tr(S.permissionDeniedMessage),
  );
}

class LoadingView extends StatelessWidget {
  const LoadingView({super.key, this.label});

  final String? label;

  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const CircularProgressIndicator(),
        if (label != null) ...[
          const SizedBox(height: AppSpacing.md),
          Text(label!, style: context.text.bodyMedium),
        ],
      ],
    ),
  );
}
