import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/utils/bangla_number.dart';
import '../../../shared/widgets/app_page_scaffold.dart';
import '../../../shared/widgets/section_header.dart';
import '../../../shared/widgets/stat_card.dart';
import 'widgets/greeting_header.dart';

class StudentHomeScreen extends StatelessWidget {
  const StudentHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppPageScaffold(
      title: 'ড্যাশবোর্ড',
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const GreetingHeader(subtitle: 'আজ কী শিখতে চাও?'),
          const SectionHeader(title: 'এই সপ্তাহ', trailing: DemoDataBadge()),
          StatGrid(
            cards: [
              StatCard(label: 'পড়ার সময় (মিনিট)', value: toBanglaDigits(405), icon: Icons.timer_outlined),
              StatCard(label: 'অনুশীলিত প্রশ্ন', value: toBanglaDigits(204), icon: Icons.quiz_outlined),
              StatCard(label: 'গড় নম্বর', value: '${toBanglaDigits(78)}%', icon: Icons.grade_outlined),
              StatCard(
                label: 'টানা পড়ার দিন',
                value: toBanglaDigits(6),
                icon: Icons.local_fire_department_outlined,
              ),
            ],
          ),
          const SectionHeader(title: 'দ্রুত শুরু করো'),
          _QuickAction(
            icon: Icons.smart_toy_outlined,
            title: 'AI টিউটরকে প্রশ্ন করো',
            onTap: () => context.go('/student/ai-tutor'),
          ),
          _QuickAction(
            icon: Icons.co_present_outlined,
            title: 'বইয়ের শিক্ষককে প্রশ্ন করো (অ্যাভাটার)',
            onTap: () => context.push('/avatar-tutor'),
          ),
          _QuickAction(
            icon: Icons.photo_camera_outlined,
            title: 'ছবি তুলে সমাধান',
            onTap: () => context.go('/student/more/photo-solver'),
          ),
          _QuickAction(
            icon: Icons.quiz_outlined,
            title: 'মডেল টেস্ট দাও',
            onTap: () => context.go('/student/practice'),
          ),
        ],
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({required this.icon, required this.title, required this.onTap});

  final IconData icon;
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(icon),
        title: Text(title),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
