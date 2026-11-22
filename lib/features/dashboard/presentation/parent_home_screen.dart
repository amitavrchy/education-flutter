import 'package:material_ui/material_ui.dart';

import '../../../core/utils/bangla_number.dart';
import '../../../shared/widgets/app_page_scaffold.dart';
import '../../../shared/widgets/section_header.dart';
import '../../../shared/widgets/stat_card.dart';
import 'widgets/greeting_header.dart';

class ParentHomeScreen extends StatelessWidget {
  const ParentHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppPageScaffold(
      title: 'ড্যাশবোর্ড',
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const GreetingHeader(subtitle: 'আপনার সন্তানের পড়াশোনার খবর'),
          const SectionHeader(title: 'এই সপ্তাহ', trailing: DemoDataBadge()),
          StatGrid(
            cards: [
              StatCard(
                label: 'পড়ার সময় (মিনিট)',
                value: toBanglaDigits(312),
                icon: Icons.timer_outlined,
              ),
              StatCard(
                label: 'পরীক্ষা সম্পন্ন',
                value: toBanglaDigits(2),
                icon: Icons.task_alt_outlined,
              ),
              StatCard(
                label: 'গড় নম্বর',
                value: '${toBanglaDigits(81)}%',
                icon: Icons.grade_outlined,
              ),
              StatCard(
                label: 'নতুন নোটিশ',
                value: toBanglaDigits(1),
                icon: Icons.campaign_outlined,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
