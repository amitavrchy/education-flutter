import '../../core/l10n/tr.dart';
import '../../features/notifications/domain/app_notification.dart';

/// Sample inbox, timestamped relative to the first launch.
List<AppNotification> seedNotifications([DateTime? now]) {
  final t = now ?? DateTime.now();
  AppNotification n(String id, NotificationCategory c, Tr title, Tr body, Duration ago, {bool read = false, String? route}) =>
      AppNotification(id: id, category: c, title: title, body: body, createdAt: t.subtract(ago), read: read, route: route);
  return [
    n('n1', NotificationCategory.study, const Tr('আজকের পড়ার পরিকল্পনা', 'Today’s study plan'),
        const Tr('পদার্থবিজ্ঞান: গতি — ৩০ মিনিট রিভিশন বাকি।', 'Physics: Motion — 30 minutes of revision left.'),
        const Duration(minutes: 25), route: '/student/learn'),
    n('n2', NotificationCategory.exam, const Tr('মডেল টেস্ট প্রস্তুত', 'Model test ready'),
        const Tr('রসায়ন অধ্যায় ১–৩ এর উপর ২৫ নম্বরের মডেল টেস্ট।', 'A 25-mark model test on Chemistry chapters 1–3.'),
        const Duration(hours: 3), route: '/student/practice'),
    n('n3', NotificationCategory.achievement, const Tr('৬ দিনের স্ট্রিক!', '6-day streak!'),
        const Tr('টানা ৬ দিন পড়েছ। আজ পড়লে ৭ দিনের ব্যাজ পাবে।', 'You studied 6 days in a row. Study today for the 7-day badge.'),
        const Duration(hours: 20)),
    n('n4', NotificationCategory.ai, const Tr('দুর্বল টপিক শনাক্ত হয়েছে', 'Weak topic detected'),
        const Tr('বলবিদ্যার “নিউটনের দ্বিতীয় সূত্র” এ ভুল বেশি হচ্ছে। একটি অনুশীলন সেট তৈরি করা হয়েছে।',
            'Frequent mistakes in “Newton’s second law”. A practice set has been prepared.'),
        const Duration(days: 1, hours: 2), route: '/student/practice'),
    n('n5', NotificationCategory.system, const Tr('ডেমো মোডে স্বাগতম', 'Welcome to demo mode'),
        const Tr('সব ডেটা নমুনা এবং শুধু এই ডিভাইসে সংরক্ষিত।', 'All data is sample data stored only on this device.'),
        const Duration(days: 2), read: true),
  ];
}
