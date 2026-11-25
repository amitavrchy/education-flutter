import 'package:material_ui/material_ui.dart';

import '../../features/ai_tutor/presentation/ai_tutor_screen.dart';
import '../../features/curriculum/presentation/learn_screen.dart';
import '../../features/practice/presentation/practice_hub_screen.dart';
import '../router/app_routes.dart';
import '../../features/auth/domain/app_user.dart';
import '../../features/dashboard/presentation/student_home_screen.dart';
import '../../features/more/presentation/more_menu_screen.dart';
import '../../features/parent/parent_screens.dart';
import '../../features/teacher/teacher_screens.dart';

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

/// An entry of the "more" menu.
class PortalMenuItem {
  const PortalMenuItem({required this.slug, required this.label, required this.icon, this.route, this.group});

  final String slug;
  final String label;
  final IconData icon;

  /// Full-screen route the item opens. Null → `/<role>/more/<slug>` (role views not yet built).
  final String? route;

  /// Heading the item is listed under in the "more" menu.
  final String? group;
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
      slug: 'learn',
      label: 'শিখি',
      icon: Icons.menu_book_outlined,
      selectedIcon: Icons.menu_book,
      builder: (_) => const LearnScreen(),
    ),
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
      builder: (_) => const PracticeHubScreen(),
    ),
    _moreTab,
  ],
  menuItems: [
    // Learning tools
    const PortalMenuItem(slug: 'analytics', label: 'অগ্রগতি ও দুর্বলতা', icon: Icons.insights_outlined, route: AppRoutes.analytics, group: 'শেখা'),
    const PortalMenuItem(slug: 'planner', label: 'স্টাডি প্ল্যানার', icon: Icons.calendar_month_outlined, route: AppRoutes.planner, group: 'শেখা'),
    PortalMenuItem(slug: 'notes', label: 'নোটস', icon: Icons.sticky_note_2_outlined, route: AppRoutes.notes(), group: 'শেখা'),
    PortalMenuItem(slug: 'flashcards', label: 'ফ্ল্যাশকার্ড', icon: Icons.style_outlined, route: AppRoutes.flashcards(), group: 'শেখা'),
    const PortalMenuItem(slug: 'library', label: 'পাঠ্যবই লাইব্রেরি', icon: Icons.local_library_outlined, route: AppRoutes.library, group: 'শেখা'),
    const PortalMenuItem(slug: 'audio', label: 'অডিও রিভিশন', icon: Icons.headphones_outlined, route: AppRoutes.audio, group: 'শেখা'),
    const PortalMenuItem(slug: 'labs', label: 'বিজ্ঞান ও গণিত ল্যাব', icon: Icons.science_outlined, route: AppRoutes.labs, group: 'শেখা'),
    const PortalMenuItem(slug: 'english', label: 'ইংরেজি কোচ', icon: Icons.translate, route: AppRoutes.english, group: 'শেখা'),
    // AI tools
    const PortalMenuItem(slug: 'avatar-tutor', label: 'বইয়ের শিক্ষক (অ্যাভাটার)', icon: Icons.co_present_outlined, route: AppRoutes.avatarTutor, group: 'AI টুলস'),
    const PortalMenuItem(slug: 'voice', label: 'ভয়েস টিউটর', icon: Icons.mic_none, route: AppRoutes.voiceTutor, group: 'AI টুলস'),
    const PortalMenuItem(slug: 'photo-solver', label: 'ফটো সলভার', icon: Icons.photo_camera_outlined, route: AppRoutes.photoSolver, group: 'AI টুলস'),
    const PortalMenuItem(slug: 'handwriting', label: 'হাতের লেখা মূল্যায়ন', icon: Icons.draw_outlined, route: AppRoutes.handwriting, group: 'AI টুলস'),
    // Archives
    const PortalMenuItem(slug: 'board', label: 'বোর্ড প্রশ্ন আর্কাইভ', icon: Icons.history_edu_outlined, route: AppRoutes.boardArchive, group: 'প্রশ্ন আর্কাইভ'),
    const PortalMenuItem(slug: 'institution-papers', label: 'স্কুল-কলেজের প্রশ্ন', icon: Icons.account_balance_outlined, route: AppRoutes.institutionArchive, group: 'প্রশ্ন আর্কাইভ'),
    const PortalMenuItem(slug: 'bookmarks', label: 'বুকমার্ক', icon: Icons.bookmark_border, route: AppRoutes.bookmarks, group: 'প্রশ্ন আর্কাইভ'),
    // Me
    const PortalMenuItem(slug: 'achievements', label: 'অর্জন ও XP', icon: Icons.emoji_events_outlined, route: AppRoutes.achievements, group: 'আমি'),
    const PortalMenuItem(slug: 'offline', label: 'অফলাইন ডাউনলোড', icon: Icons.download_for_offline_outlined, route: AppRoutes.offline, group: 'আমি'),
    const PortalMenuItem(slug: 'profile', label: 'প্রোফাইল', icon: Icons.person_outline, route: AppRoutes.profile, group: 'আমি'),
    const PortalMenuItem(slug: 'subscription', label: 'সাবস্ক্রিপশন', icon: Icons.workspace_premium_outlined, route: AppRoutes.subscription, group: 'আমি'),
    const PortalMenuItem(slug: 'privacy', label: 'গোপনীয়তা ও নিরাপত্তা', icon: Icons.shield_outlined, route: AppRoutes.privacy, group: 'আমি'),
    const PortalMenuItem(slug: 'support', label: 'সাহায্য ও মতামত', icon: Icons.support_agent, route: AppRoutes.support, group: 'আমি'),
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
      builder: (_) => const TeacherClassesScreen(),
    ),
    PortalTab(
      slug: 'evaluation',
      label: 'মূল্যায়ন',
      icon: Icons.fact_check_outlined,
      selectedIcon: Icons.fact_check,
      builder: (_) => const TeacherEvaluationScreen(),
    ),
    _moreTab,
  ],
  menuItems: const [
    PortalMenuItem(slug: 'assignments', label: 'অ্যাসাইনমেন্ট', icon: Icons.assignment_outlined, route: AppRoutes.teacherAssignments),
    PortalMenuItem(slug: 'exams', label: 'পরীক্ষা', icon: Icons.quiz_outlined, route: AppRoutes.teacherExams),
    PortalMenuItem(slug: 'question-generator', label: 'AI প্রশ্ন জেনারেটর', icon: Icons.auto_awesome_outlined, route: AppRoutes.questionGenerator),
    PortalMenuItem(slug: 'materials', label: 'শিক্ষা উপকরণ', icon: Icons.folder_outlined, route: AppRoutes.teacherMaterials),
    PortalMenuItem(slug: 'avatars', label: 'অ্যাভাটার শিক্ষক', icon: Icons.co_present_outlined, route: AppRoutes.teacherAvatars),
    PortalMenuItem(slug: 'analytics', label: 'অ্যানালিটিক্স', icon: Icons.insights_outlined, route: AppRoutes.teacherAnalytics),
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
      builder: (_) => const ParentChildrenScreen(),
    ),
    PortalTab(
      slug: 'progress',
      label: 'অগ্রগতি',
      icon: Icons.trending_up_outlined,
      selectedIcon: Icons.trending_up,
      builder: (_) => const ParentProgressScreen(),
    ),
    _moreTab,
  ],
  menuItems: const [
    PortalMenuItem(slug: 'calendar', label: 'স্টাডি ক্যালেন্ডার', icon: Icons.calendar_month_outlined, route: AppRoutes.parentCalendar, group: 'সন্তানের পড়াশোনা'),
    PortalMenuItem(slug: 'results', label: 'ফলাফল', icon: Icons.emoji_events_outlined, route: AppRoutes.parentResults, group: 'সন্তানের পড়াশোনা'),
    PortalMenuItem(slug: 'goals', label: 'শেখার লক্ষ্য', icon: Icons.flag_outlined, route: AppRoutes.parentGoals, group: 'সন্তানের পড়াশোনা'),
    PortalMenuItem(slug: 'feedback', label: 'শিক্ষকের মন্তব্য', icon: Icons.rate_review_outlined, route: AppRoutes.parentFeedback, group: 'সন্তানের পড়াশোনা'),
    PortalMenuItem(slug: 'reports', label: 'রিপোর্ট', icon: Icons.description_outlined, route: AppRoutes.parentReports, group: 'সন্তানের পড়াশোনা'),
    PortalMenuItem(slug: 'avatar-activity', label: 'অ্যাভাটার শিক্ষকের ব্যবহার', icon: Icons.co_present_outlined, route: AppRoutes.avatarActivity, group: 'সন্তানের পড়াশোনা'),
    PortalMenuItem(slug: 'privacy', label: 'গোপনীয়তা', icon: Icons.shield_outlined, route: AppRoutes.parentPrivacy, group: 'অ্যাকাউন্ট'),
    PortalMenuItem(slug: 'subscription', label: 'সাবস্ক্রিপশন', icon: Icons.workspace_premium_outlined, route: AppRoutes.subscription, group: 'অ্যাকাউন্ট'),
    PortalMenuItem(slug: 'support', label: 'সাহায্য ও মতামত', icon: Icons.support_agent, route: AppRoutes.support, group: 'অ্যাকাউন্ট'),
  ],
);

/// Portals available in the app (admins use the web dashboard).
final List<PortalConfig> mobilePortals = [studentPortal, teacherPortal, parentPortal];
