import 'package:material_ui/material_ui.dart';

import '../../../shared/widgets/app_page_scaffold.dart';
import '../../../shared/widgets/empty_state.dart';

/// Chat UI comes next; the data layer (AiTutorRepository) is already wired to the backend.
class AiTutorScreen extends StatelessWidget {
  const AiTutorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const AppPageScaffold(
      title: 'AI টিউটর',
      scrollable: false,
      body: EmptyState(
        icon: Icons.smart_toy_outlined,
        title: 'AI টিউটর শীঘ্রই আসছে',
        message: 'পাঠ্যবই থেকে উত্তর ও ধাপে ধাপে ব্যাখ্যা — বাংলা ও ইংরেজিতে।',
      ),
    );
  }
}
