import 'package:material_ui/material_ui.dart';

import '../../core/l10n/common_strings.dart';
import '../../core/l10n/tr.dart';
import '../../core/theme/app_spacing.dart';
import 'error_view.dart';

extension FeedbackContext on BuildContext {
  void showSnack(Tr message, {SnackBarAction? action}) {
    ScaffoldMessenger.of(this)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(tr(message)), action: action));
  }

  void showErrorSnack(Object error) => showSnack(errorMessageOf(error));
}

/// Confirmation dialog. Destructive actions get an error-coloured confirm button.
Future<bool> showConfirmDialog(
  BuildContext context, {
  required Tr title,
  Tr? message,
  Tr confirmLabel = S.confirm,
  bool destructive = false,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(context.tr(title)),
      content: message == null ? null : Text(context.tr(message)),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: Text(context.tr(S.cancel))),
        FilledButton(
          style: destructive
              ? FilledButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.error,
                  foregroundColor: Theme.of(context).colorScheme.onError,
                )
              : null,
          onPressed: () => Navigator.pop(context, true),
          child: Text(context.tr(confirmLabel)),
        ),
      ],
    ),
  );
  return result ?? false;
}

/// Single text input dialog (rename, new folder…). Returns null when cancelled.
Future<String?> showTextInputDialog(
  BuildContext context, {
  required Tr title,
  Tr? label,
  String initial = '',
  int maxLines = 1,
}) {
  final controller = TextEditingController(text: initial);
  final formKey = GlobalKey<FormState>();
  return showDialog<String>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(context.tr(title)),
      content: Form(
        key: formKey,
        child: TextFormField(
          controller: controller,
          autofocus: true,
          maxLines: maxLines,
          decoration: InputDecoration(labelText: label == null ? null : context.tr(label)),
          validator: (value) => (value ?? '').trim().isEmpty ? context.tr(S.required) : null,
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text(context.tr(S.cancel))),
        FilledButton(
          onPressed: () {
            if (formKey.currentState!.validate()) Navigator.pop(context, controller.text.trim());
          },
          child: Text(context.tr(S.save)),
        ),
      ],
    ),
  );
}

/// Report dialog with reasons, used for questions, AI answers, OCR and content.
Future<String?> showReportDialog(BuildContext context, {required List<Tr> reasons, Tr? title}) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    builder: (context) {
      var selected = 0;
      final details = TextEditingController();
      return StatefulBuilder(
        builder: (context, setState) => Padding(
          padding: EdgeInsets.fromLTRB(
            AppSpacing.lg,
            0,
            AppSpacing.lg,
            MediaQuery.viewInsetsOf(context).bottom + AppSpacing.lg,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(context.tr(title ?? S.report), style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: AppSpacing.sm),
              RadioGroup<int>(
                groupValue: selected,
                onChanged: (value) => setState(() => selected = value ?? 0),
                child: Column(
                  children: [
                    for (var i = 0; i < reasons.length; i++)
                      RadioListTile<int>(value: i, title: Text(context.tr(reasons[i]))),
                  ],
                ),
              ),
              TextField(
                controller: details,
                maxLines: 2,
                decoration: InputDecoration(
                  hintText: context.tr(const Tr('বিস্তারিত (ঐচ্ছিক)', 'Details (optional)')),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              FilledButton(
                onPressed: () => Navigator.pop(
                  context,
                  '${reasons[selected].en}${details.text.isEmpty ? '' : ': ${details.text}'}',
                ),
                child: Text(context.tr(S.submit)),
              ),
            ],
          ),
        ),
      );
    },
  );
}
