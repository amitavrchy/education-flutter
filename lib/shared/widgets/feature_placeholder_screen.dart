import 'package:material_ui/material_ui.dart';

import 'app_page_scaffold.dart';
import 'empty_state.dart';

/// Temporary body for routes whose feature UI is not built yet.
class FeaturePlaceholderScreen extends StatelessWidget {
  const FeaturePlaceholderScreen({super.key, required this.title, this.icon = defaultIcon});

  static const IconData defaultIcon = Icons.construction;

  final String title;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return AppPageScaffold(
      title: title,
      scrollable: false,
      body: EmptyState(
        icon: icon,
        title: 'এই অংশটি তৈরি হচ্ছে',
        message: 'এই ফিচারটি শীঘ্রই যুক্ত করা হবে।',
      ),
    );
  }
}
