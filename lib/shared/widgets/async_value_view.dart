import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import 'error_view.dart';
import 'skeleton.dart';

/// Renders loading (skeleton), error (offline / denied / generic with retry) and data.
///
/// Keeps showing previous data while refreshing so lists don't flash.
class AsyncValueView<T> extends StatelessWidget {
  const AsyncValueView({
    super.key,
    required this.value,
    required this.data,
    this.onRetry,
    this.loading,
    this.compactError = false,
  });

  final AsyncValue<T> value;
  final Widget Function(T data) data;
  final VoidCallback? onRetry;
  final Widget? loading;
  final bool compactError;

  @override
  Widget build(BuildContext context) {
    if (value.hasValue && !(value.hasError && !value.isLoading)) {
      return data(value.requireValue);
    }
    if (value.hasError && !value.isLoading) {
      return ErrorView(error: value.error, onRetry: onRetry, compact: compactError);
    }
    return loading ?? const SkeletonList();
  }
}
