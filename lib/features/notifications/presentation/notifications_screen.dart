import 'package:material_ui/material_ui.dart';

import '../../../shared/widgets/app_page_scaffold.dart';
import '../../../shared/widgets/empty_state.dart';

/// Notification inbox. Push notifications (FCM) are planned; see README.
class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const AppPageScaffold(
      title: 'নোটিফিকেশন',
      showShortcuts: false,
      scrollable: false,
      body: EmptyState(icon: Icons.notifications_none, title: 'কোনো নোটিফিকেশন নেই'),
    );
  }
}
