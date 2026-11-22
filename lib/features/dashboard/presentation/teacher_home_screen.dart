import 'package:material_ui/material_ui.dart';

import '../../../core/utils/bangla_number.dart';
import '../../../shared/widgets/app_page_scaffold.dart';
import '../../../shared/widgets/section_header.dart';
import '../../../shared/widgets/stat_card.dart';
import 'widgets/greeting_header.dart';

class TeacherHomeScreen extends StatelessWidget {
  const TeacherHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppPageScaffold(
      title: 'ড্যাশবোর্ড',
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const GreetingHeader(subtitle: 'আজকের ক্লাস ও মূল্যায়ন'),
          const SectionHeader(title: 'সংক্ষেপে', trailing: DemoDataBadge()),
          StatGrid(
            cards: [
              StatCard(label: 'ক্লাস', value: toBanglaDigits(4), icon: Icons.class_outlined),
              StatCard(label: 'শিক্ষার্থী', value: toBanglaDigits(186), icon: Icons.groups_outlined),
              StatCard(
                label: 'মূল্যায়ন বাকি',
                value: toBanglaDigits(23),
                icon: Icons.fact_check_outlined,
              ),
              StatCard(
                label: 'চলমান অ্যাসাইনমেন্ট',
                value: toBanglaDigits(3),
                icon: Icons.assignment_outlined,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
