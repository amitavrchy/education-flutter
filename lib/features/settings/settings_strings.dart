import '../../core/l10n/tr.dart';

abstract final class SettingsStrings {
  static const appearance = Tr('চেহারা', 'Appearance');
  static const light = Tr('লাইট', 'Light');
  static const dark = Tr('ডার্ক', 'Dark');
  static const system = Tr('সিস্টেম', 'System');
  static const language = Tr('ভাষা', 'Language');
  static const accessibility = Tr('অ্যাক্সেসিবিলিটি', 'Accessibility');
  static const textSize = Tr('লেখার আকার', 'Text size');
  static const highContrast = Tr('উচ্চ কনট্রাস্ট', 'High contrast');
  static const highContrastHint = Tr('লেখা ও বোতাম আরও স্পষ্ট দেখায়', 'Makes text and controls easier to see');
  static const reducedMotion = Tr('কম অ্যানিমেশন', 'Reduce motion');
  static const reducedMotionHint = Tr('অ্যানিমেশন ও ট্রানজিশন বন্ধ রাখে', 'Turns off animations and transitions');
  static const banglaDigits = Tr('বাংলা সংখ্যা', 'Bangla numerals');
  static const banglaDigitsHint = Tr('বাংলা ইন্টারফেসে ১২৩ দেখাবে', 'Show ১২৩ in the Bangla interface');
  static const motivation = Tr('প্রেরণা', 'Motivation');
  static const hideCompetitive = Tr('লিডারবোর্ড লুকান', 'Hide leaderboards');
  static const hideCompetitiveHint = Tr(
    'র‍্যাংকিং ও বন্ধুদের চ্যালেঞ্জ দেখাবে না',
    'Hides rankings and friend challenges',
  );
  static const account = Tr('অ্যাকাউন্ট', 'Account');
  static const profile = Tr('প্রোফাইল ও একাডেমিক তথ্য', 'Profile & academic details');
  static const notificationPrefs = Tr('নোটিফিকেশন পছন্দ', 'Notification preferences');
  static const privacy = Tr('গোপনীয়তা ও নিরাপত্তা', 'Privacy & safety');
  static const subscription = Tr('সাবস্ক্রিপশন', 'Subscription');
  static const help = Tr('সাহায্য ও মতামত', 'Help & feedback');
  static const demoTools = Tr('ডেমো টুলস', 'Demo tools');
  static const demoToolsHint = Tr(
    'শুধু পরীক্ষার জন্য: অফলাইন ও সার্ভার-ত্রুটি অবস্থা দেখতে চালু করুন।',
    'Testing only: turn on to see offline and server-error states.',
  );
  static const simulateOffline = Tr('অফলাইন সিমুলেট করুন', 'Simulate offline');
  static const simulateErrors = Tr('সার্ভার ত্রুটি সিমুলেট করুন', 'Simulate server errors');
  static const storage = Tr('স্টোরেজ', 'Storage');
  static const storageUsed = Tr('এই ডিভাইসে {n} KB ব্যবহৃত', '{n} KB used on this device');
  static const resetDemo = Tr('ডেমো ডেটা রিসেট করুন', 'Reset demo data');
  static const resetDemoMessage = Tr(
    'নোট, ফ্ল্যাশকার্ড, পরীক্ষার ফলাফল, কথোপকথন ও অগ্রগতি শুরুর নমুনা অবস্থায় ফিরে যাবে। প্রোফাইল ও সেটিংস থাকবে।',
    'Notes, flashcards, exam results, conversations and progress return to the starting sample. Profile and settings are kept.',
  );
  static const resetDone = Tr('ডেমো ডেটা রিসেট হয়েছে', 'Demo data reset');
  static const about = Tr('অ্যাপ সম্পর্কে', 'About');
  static const version = Tr('সংস্করণ', 'Version');
  static const demoMode = Tr('ডেমো মোড — সব ডেটা নমুনা', 'Demo mode — all data is sample data');
  static const logoutConfirm = Tr('লগআউট করবেন?', 'Log out?');
}
