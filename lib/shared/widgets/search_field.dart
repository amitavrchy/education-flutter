import 'dart:async';

import 'package:material_ui/material_ui.dart';

import '../../core/l10n/common_strings.dart';
import '../../core/l10n/tr.dart';

/// Search box that reports changes after a short pause (debounced) to keep lists smooth.
class DebouncedSearchField extends StatefulWidget {
  const DebouncedSearchField({
    super.key,
    required this.onChanged,
    this.hint,
    this.initial = '',
    this.delay = const Duration(milliseconds: 300),
    this.autofocus = false,
    this.onSubmitted,
  });

  final ValueChanged<String> onChanged;
  final ValueChanged<String>? onSubmitted;
  final String? hint;
  final String initial;
  final Duration delay;
  final bool autofocus;

  @override
  State<DebouncedSearchField> createState() => _DebouncedSearchFieldState();
}

class _DebouncedSearchFieldState extends State<DebouncedSearchField> {
  late final TextEditingController _controller = TextEditingController(text: widget.initial);
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _changed(String value) {
    setState(() {});
    _timer?.cancel();
    _timer = Timer(widget.delay, () => widget.onChanged(value.trim()));
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      autofocus: widget.autofocus,
      textInputAction: TextInputAction.search,
      onChanged: _changed,
      onSubmitted: (value) {
        _timer?.cancel();
        widget.onChanged(value.trim());
        widget.onSubmitted?.call(value.trim());
      },
      decoration: InputDecoration(
        hintText: widget.hint ?? context.tr(S.search),
        prefixIcon: const Icon(Icons.search),
        suffixIcon: _controller.text.isEmpty
            ? null
            : IconButton(
                tooltip: context.tr(S.close),
                icon: const Icon(Icons.close),
                onPressed: () {
                  _controller.clear();
                  _changed('');
                },
              ),
      ),
    );
  }
}
