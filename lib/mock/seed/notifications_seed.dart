import '../../core/l10n/tr.dart';
import '../../features/notifications/domain/app_notification.dart';

/// Sample inbox, timestamped relative to the first launch. Covers every notification type
/// (web §43) and every mobile role.
List<AppNotification> seedNotifications([DateTime? now]) {
  final t = now ?? DateTime.now();
  AppNotification n(
    String id,
    NotificationCategory c,
    Tr title,
    Tr body,
    Duration ago, {
    bool read = false,
    String? route,
    String? audience = 'student',
    NotificationPriority priority = NotificationPriority.normal,
  }) => AppNotification(id: id, category: c, title: title, body: body, createdAt: t.subtract(ago), read: read, route: route, audience: audience, priority: priority);
  return [
    // Student
    n('n1', NotificationCategory.study, const Tr('আজকের পড়ার পরিকল্পনা', 'Today’s study plan'),
        const Tr('পদার্থবিজ্ঞান: গতি — ৩০ মিনিট রিভিশন বাকি।', 'Physics: Motion — 30 minutes of revision left.'),
        const Duration(minutes: 25), route: '/planner'),
    n('n2', NotificationCategory.exam, const Tr('মডেল টেস্ট প্রস্তুত', 'Model test ready'),
        const Tr('রসায়ন অধ্যায় ১–৩ এর উপর ২৫ নম্বরের মডেল টেস্ট।', 'A 25-mark model test on Chemistry chapters 1–3.'),
        const Duration(hours: 3), route: '/student/practice/exams', priority: NotificationPriority.high),
    n('n3', NotificationCategory.achievement, const Tr('৬ দিনের স্ট্রিক!', '6-day streak!'),
        const Tr('টানা ৬ দিন পড়েছ। আজ পড়লে ৭ দিনের ব্যাজ পাবে।', 'You studied 6 days in a row. Study today for the 7-day badge.'),
        const Duration(hours: 20), route: '/achievements'),
    n('n4', NotificationCategory.ai, const Tr('দুর্বল টপিক শনাক্ত হয়েছে', 'Weak topic detected'),
        const Tr('বলবিদ্যার “নিউটনের দ্বিতীয় সূত্র” এ ভুল বেশি হচ্ছে। একটি অনুশীলন সেট তৈরি করা হয়েছে।',
            'Frequent mistakes in “Newton’s second law”. A practice set has been prepared.'),
        const Duration(days: 1, hours: 2), route: '/student/practice'),
    n('n6', NotificationCategory.assignment, const Tr('নতুন অ্যাসাইনমেন্ট', 'New assignment'),
        const Tr('নাসরিন সুলতানা “বলের সমস্যা — অনুশীলন” দিয়েছেন। জমা ২ দিনের মধ্যে।', 'Nasrin Sultana set “Force problems — practice”. Due in 2 days.'),
        const Duration(hours: 6), route: '/student/practice/exams'),
    n('n7', NotificationCategory.feedback, const Tr('শিক্ষকের মতামত', 'Teacher feedback'),
        const Tr('তোমার “নিউটনের সূত্র” উত্তরে একক লেখা বাদ পড়েছে — বাকিটা ভালো হয়েছে।', 'Units were missing in your “Newton’s laws” answer — the rest is good.'),
        const Duration(days: 1, hours: 8), route: '/handwriting', read: true),
    n('n8', NotificationCategory.announcement, const Tr('বোর্ড বিজ্ঞপ্তি (নমুনা)', 'Board notice (sample)'),
        const Tr('এসএসসি ২০২৭ এর ফরম পূরণ শুরু হবে আগামী মাসে। এটি নমুনা ঘোষণা।', 'SSC 2027 form fill-up starts next month. This is a sample notice.'),
        const Duration(days: 2, hours: 4)),
    n('n9', NotificationCategory.billing, const Tr('ফ্রি প্ল্যান ব্যবহার করছ', 'You are on the Free plan'),
        const Tr('প্রো প্ল্যানে ৭ দিনের ফ্রি ট্রায়াল নিতে পারো।', 'Try Pro free for 7 days.'),
        const Duration(days: 3), route: '/subscription', read: true, priority: NotificationPriority.low),
    n('n10', NotificationCategory.announcement, const Tr('কনটেন্ট সংশোধন', 'Content correction'),
        const Tr('রসায়ন প্রশ্ন #১২ এর উত্তর সংশোধন করা হয়েছে।', 'The answer to Chemistry question #12 was corrected.'),
        const Duration(days: 4), route: '/student/practice/bank', read: true),
    n('n5', NotificationCategory.system, const Tr('ডেমো মোডে স্বাগতম', 'Welcome to demo mode'),
        const Tr('সব ডেটা নমুনা এবং শুধু এই ডিভাইসে সংরক্ষিত।', 'All data is sample data stored only on this device.'),
        const Duration(days: 5), read: true, audience: null),
    // Parent
    n('p1', NotificationCategory.study, const Tr('সাপ্তাহিক রিপোর্ট প্রস্তুত', 'Weekly report ready'),
        const Tr('রাফির এই সপ্তাহের পড়াশোনার রিপোর্ট দেখুন।', 'See Rafi’s learning report for this week.'),
        const Duration(hours: 2), audience: 'parent', route: '/parent-reports'),
    n('p2', NotificationCategory.feedback, const Tr('শিক্ষকের মন্তব্য', 'Teacher comment'),
        const Tr('নাসরিন সুলতানা রাফির পদার্থবিজ্ঞান নিয়ে মন্তব্য করেছেন।', 'Nasrin Sultana commented on Rafi’s physics.'),
        const Duration(hours: 9), audience: 'parent', route: '/parent-feedback'),
    n('p3', NotificationCategory.exam, const Tr('পরীক্ষার ফল', 'Exam result'),
        const Tr('রাফি মডেল টেস্টে ৭৮% পেয়েছে।', 'Rafi scored 78% in a model test.'),
        const Duration(days: 1), audience: 'parent', route: '/parent-results', read: true),
    // Teacher
    n('t1', NotificationCategory.assignment, const Tr('নতুন জমা', 'New submissions'),
        const Tr('“নিউটনের সূত্র — সৃজনশীল প্রশ্ন” এ ৪টি খাতা মূল্যায়নের অপেক্ষায়।', '4 scripts for “Newton’s laws — creative question” are waiting.'),
        const Duration(hours: 1), audience: 'teacher', route: '/teacher/evaluation', priority: NotificationPriority.high),
    n('t2', NotificationCategory.ai, const Tr('রিভিউ কিউ', 'Review queue'),
        const Tr('৩টি প্রশ্ন আপনার পর্যালোচনার অপেক্ষায়।', '3 questions are waiting for your review.'),
        const Duration(hours: 5), audience: 'teacher', route: '/teacher-review'),
    n('t3', NotificationCategory.feedback, const Tr('অ্যাভাটার রিপোর্ট', 'Avatar report'),
        const Tr('একজন শিক্ষার্থী অ্যাভাটার শিক্ষকের একটি উত্তর ভুল বলে রিপোর্ট করেছে।', 'A student reported an avatar answer as wrong.'),
        const Duration(days: 1, hours: 3), audience: 'teacher', route: '/teacher-avatars', read: true),
  ];
}
