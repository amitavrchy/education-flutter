import 'package:material_ui/material_ui.dart';

import 'empty_state.dart';

/// Full-area error with an optional retry, for failed loads.
class ErrorView extends StatelessWidget {
  const ErrorView({super.key, required this.message, this.onRetry});

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return EmptyState(
      icon: Icons.error_outline,
      title: 'কিছু একটা ভুল হয়েছে',
      message: message,
      action: onRetry == null
          ? null
          : FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('আবার চেষ্টা করুন'),
            ),
    );
  }
}

class LoadingView extends StatelessWidget {
  const LoadingView({super.key});

  @override
  Widget build(BuildContext context) => const Center(child: CircularProgressIndicator());
}
