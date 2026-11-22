import 'package:material_ui/material_ui.dart';

import '../../features/ai_tutor/presentation/ai_tutor_screen.dart';
import '../../features/auth/domain/app_user.dart';
import '../../features/dashboard/presentation/parent_home_screen.dart';
import '../../features/dashboard/presentation/student_home_screen.dart';
import '../../features/dashboard/presentation/teacher_home_screen.dart';
import '../../features/more/presentation/more_menu_screen.dart';
import '../../shared/widgets/feature_placeholder_screen.dart';

/// One bottom-navigation tab of a portal.
class PortalTab {
  const PortalTab({
    required this.slug,
    required this.label,
    required this.icon,
    required this.selectedIcon,
    required this.builder,
  });

  final String slug;
  final String label;
  final IconData icon;
  final IconData selectedIcon;
  final Widget Function(PortalConfig config) builder;
}

/// An entry of the "more" menu, opened at /<role>/more/<slug>.
class PortalMenuItem {
  const PortalMenuItem({required this.slug, required this.label, required this.icon});

  final String slug;
  final String label;
  final IconData icon;
}

/// Single source of truth for a role's navigation: tabs, routes and the "more" menu.
/// Mirrors the web portals, trimmed to what makes sense on a phone.
class PortalConfig {
  const PortalConfig({
    required this.role,
    required this.title,
    required this.tabs,
    required this.menuItems,
  });

  final UserRole role;
  final String title;
  final List<PortalTab> tabs;
  final List<PortalMenuItem> menuItems;

  String get basePath => '/${role.pathSegment}';
  String tabPath(PortalTab tab) => '$basePath/${tab.slug}';
  String get morePath => '$basePath/more';

  PortalMenuItem? menuItem(String slug) {
    for (final item in menuItems) {
      if (item.slug == slug) return item;
    }
    return null;
  }
}

Widget _placeholder(String title, IconData icon) =>
    FeaturePlaceholderScreen(title: title, icon: icon);

PortalTab _homeTab(Widget Function(PortalConfig config) builder) => PortalTab(
  slug: 'home',
  label: 'হোম',
  icon: Icons.home_outlined,
  selectedIcon: Icons.home,
  builder: builder,
);

final PortalTab _moreTab = PortalTab(
  slug: 'more',
  label: 'আরও',
  icon: Icons.menu,
  selectedIcon: Icons.menu_open,
  builder: (config) => MoreMenuScreen(config: config),
);

final PortalConfig studentPortal = PortalConfig(
  role: UserRole.student,
  title: 'শিক্ষার্থী',
  tabs: [
    _homeTab((_) => const StudentHomeScreen()),
    PortalTab(
      slug: 'ai-tutor',
      label: 'AI টিউটর',
      icon: Icons.smart_toy_outlined,
      selectedIcon: Icons.smart_toy,
      builder: (_) => const AiTutorScreen(),
    ),
    PortalTab(
      slug: 'practice',
      label: 'অনুশীলন',
      icon: Icons.quiz_outlined,
      selectedIcon: Icons.quiz,
      builder: (_) => _placeholder('অনুশীলন ও পরীক্ষা', Icons.quiz_outlined),
    ),
    PortalTab(
      slug: 'progress',
      label: 'অগ্রগতি',
      icon: Icons.insights_outlined,
      selectedIcon: Icons.insights,
      builder: (_) => _placeholder('ফলাফল ও অ্যানালিটিক্স', Icons.insights_outlined),
    ),
    _moreTab,
  ],
  menuItems: const [
    PortalMenuItem(slug: 'library', label: 'লাইব্রেরি', icon: Icons.menu_book_outlined),
    PortalMenuItem(slug: 'questions', label: 'প্রশ্ন ব্যাংক', icon: Icons.help_outline),
    PortalMenuItem(slug: 'photo-solver', label: 'ফটো সলভার', icon: Icons.photo_camera_outlined),
    PortalMenuItem(slug: 'notes', label: 'নোটস', icon: Icons.sticky_note_2_outlined),
    PortalMenuItem(slug: 'study-planner', label: 'স্টাডি প্ল্যানার', icon: Icons.calendar_month_outlined),
    PortalMenuItem(slug: 'videos', label: 'ভিডিও ক্লাস', icon: Icons.ondemand_video_outlined),
    PortalMenuItem(slug: 'practical-lab', label: 'প্র্যাকটিক্যাল ল্যাব', icon: Icons.science_outlined),
    PortalMenuItem(slug: 'scholarships', label: 'স্কলারশিপ', icon: Icons.emoji_events_outlined),
    PortalMenuItem(slug: 'career', label: 'ক্যারিয়ার', icon: Icons.work_outline),
    PortalMenuItem(slug: 'notices', label: 'নোটিশ', icon: Icons.campaign_outlined),
  ],
);

final PortalConfig teacherPortal = PortalConfig(
  role: UserRole.teacher,
  title: 'শিক্ষক',
  tabs: [
    _homeTab((_) => const TeacherHomeScreen()),
    PortalTab(
      slug: 'classes',
      label: 'ক্লাস',
      icon: Icons.class_outlined,
      selectedIcon: Icons.class_,
      builder: (_) => _placeholder('ক্লাস ও শিক্ষার্থী', Icons.class_outlined),
    ),
    PortalTab(
      slug: 'evaluation',
      label: 'মূল্যায়ন',
      icon: Icons.fact_check_outlined,
      selectedIcon: Icons.fact_check,
      builder: (_) => _placeholder('উত্তর মূল্যায়ন', Icons.fact_check_outlined),
    ),
    _moreTab,
  ],
  menuItems: const [
    PortalMenuItem(slug: 'assignments', label: 'অ্যাসাইনমেন্ট', icon: Icons.assignment_outlined),
    PortalMenuItem(slug: 'exams', label: 'পরীক্ষা', icon: Icons.quiz_outlined),
    PortalMenuItem(slug: 'question-generator', label: 'AI প্রশ্ন জেনারেটর', icon: Icons.auto_awesome_outlined),
    PortalMenuItem(slug: 'materials', label: 'শিক্ষা উপকরণ', icon: Icons.folder_outlined),
    PortalMenuItem(slug: 'analytics', label: 'অ্যানালিটিক্স', icon: Icons.insights_outlined),
  ],
);

final PortalConfig parentPortal = PortalConfig(
  role: UserRole.parent,
  title: 'অভিভাবক',
  tabs: [
    _homeTab((_) => const ParentHomeScreen()),
    PortalTab(
      slug: 'children',
      label: 'সন্তান',
      icon: Icons.family_restroom_outlined,
      selectedIcon: Icons.family_restroom,
      builder: (_) => _placeholder('আমার সন্তান', Icons.family_restroom_outlined),
    ),
    PortalTab(
      slug: 'progress',
      label: 'অগ্রগতি',
      icon: Icons.trending_up_outlined,
      selectedIcon: Icons.trending_up,
      builder: (_) => _placeholder('অগ্রগতি ও ফলাফল', Icons.trending_up_outlined),
    ),
    _moreTab,
  ],
  menuItems: const [
    PortalMenuItem(slug: 'reports', label: 'রিপোর্ট', icon: Icons.description_outlined),
    PortalMenuItem(slug: 'results', label: 'ফলাফল', icon: Icons.emoji_events_outlined),
  ],
);

/// Portals available in the app (institution and super-admin use the web dashboard).
final List<PortalConfig> mobilePortals = [studentPortal, teacherPortal, parentPortal];
