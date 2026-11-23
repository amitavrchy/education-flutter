import 'tr.dart';

/// Shared UI dictionary: actions, states and navigation used across features.
/// Feature-specific strings live next to each feature in `*_strings.dart`.
abstract final class S {
  // Actions
  static const save = Tr('সংরক্ষণ', 'Save');
  static const cancel = Tr('বাতিল', 'Cancel');
  static const delete = Tr('মুছুন', 'Delete');
  static const edit = Tr('সম্পাদনা', 'Edit');
  static const retry = Tr('আবার চেষ্টা করুন', 'Try again');
  static const confirm = Tr('নিশ্চিত করুন', 'Confirm');
  static const close = Tr('বন্ধ করুন', 'Close');
  static const next = Tr('পরবর্তী', 'Next');
  static const previous = Tr('পূর্ববর্তী', 'Previous');
  static const back = Tr('ফিরে যান', 'Back');
  static const done = Tr('সম্পন্ন', 'Done');
  static const submit = Tr('জমা দিন', 'Submit');
  static const search = Tr('খুঁজুন', 'Search');
  static const filter = Tr('ফিল্টার', 'Filter');
  static const clearFilters = Tr('ফিল্টার মুছুন', 'Clear filters');
  static const sort = Tr('সাজান', 'Sort');
  static const seeAll = Tr('সব দেখুন', 'See all');
  static const start = Tr('শুরু করুন', 'Start');
  static const resume = Tr('আবার শুরু', 'Resume');
  static const create = Tr('তৈরি করুন', 'Create');
  static const add = Tr('যোগ করুন', 'Add');
  static const share = Tr('শেয়ার', 'Share');
  static const copy = Tr('কপি', 'Copy');
  static const copied = Tr('কপি হয়েছে', 'Copied');
  static const bookmark = Tr('বুকমার্ক', 'Bookmark');
  static const bookmarked = Tr('বুকমার্ক করা হয়েছে', 'Bookmarked');
  static const removeBookmark = Tr('বুকমার্ক সরান', 'Remove bookmark');
  static const report = Tr('রিপোর্ট করুন', 'Report');
  static const reportSent = Tr('রিপোর্ট পাঠানো হয়েছে। ধন্যবাদ!', 'Report sent. Thank you!');
  static const saved = Tr('সংরক্ষিত হয়েছে', 'Saved');
  static const deleted = Tr('মুছে ফেলা হয়েছে', 'Deleted');
  static const undo = Tr('পূর্বাবস্থায় ফেরান', 'Undo');
  static const download = Tr('ডাউনলোড', 'Download');
  static const print = Tr('প্রিন্ট', 'Print');
  static const export = Tr('এক্সপোর্ট', 'Export');
  static const upload = Tr('আপলোড', 'Upload');
  static const yes = Tr('হ্যাঁ', 'Yes');
  static const no = Tr('না', 'No');
  static const all = Tr('সব', 'All');
  static const more = Tr('আরও', 'More');
  static const apply = Tr('প্রয়োগ করুন', 'Apply');
  static const askAi = Tr('AI-কে জিজ্ঞেস করুন', 'Ask AI');
  static const details = Tr('বিস্তারিত', 'Details');
  static const open = Tr('খুলুন', 'Open');
  static const rename = Tr('নাম পরিবর্তন', 'Rename');
  static const archive = Tr('আর্কাইভ', 'Archive');
  static const pin = Tr('পিন করুন', 'Pin');
  static const unpin = Tr('আনপিন', 'Unpin');
  static const markRead = Tr('পঠিত চিহ্নিত করুন', 'Mark as read');
  static const required = Tr('এই ঘরটি পূরণ করুন', 'This field is required');

  // States
  static const loading = Tr('লোড হচ্ছে…', 'Loading…');
  static const errorTitle = Tr('কিছু একটা ভুল হয়েছে', 'Something went wrong');
  static const offlineTitle = Tr('আপনি অফলাইনে আছেন', 'You are offline');
  static const offlineMessage = Tr(
    'এই অংশের জন্য ইন্টারনেট প্রয়োজন। ডাউনলোড করা কনটেন্ট অফলাইনেও ব্যবহার করা যাবে।',
    'This needs an internet connection. Downloaded content still works offline.',
  );
  static const offlineBanner = Tr('অফলাইন মোড — শুধু ডাউনলোড করা কনটেন্ট', 'Offline — downloaded content only');
  static const simulatedError = Tr('সার্ভারে সমস্যা হয়েছে (সিমুলেটেড)।', 'Server error (simulated).');
  static const notFound = Tr('খুঁজে পাওয়া যায়নি', 'Not found');
  static const permissionDenied = Tr('অনুমতি নেই', 'Access denied');
  static const permissionDeniedMessage = Tr(
    'আপনার ভূমিকায় এই অংশ দেখার অনুমতি নেই।',
    'Your role does not have access to this section.',
  );
  static const quotaExceeded = Tr('প্ল্যানের সীমা শেষ', 'Plan limit reached');
  static const emptyTitle = Tr('এখানে এখনো কিছু নেই', 'Nothing here yet');
  static const noResults = Tr('কোনো ফলাফল পাওয়া যায়নি', 'No results found');
  static const noResultsHint = Tr('অন্য শব্দ বা ফিল্টার দিয়ে চেষ্টা করুন।', 'Try different words or filters.');
  static const demoData = Tr('ডেমো ডেটা', 'Demo data');
  static const simulated = Tr('সিমুলেটেড', 'Simulated');
  static const syntheticSample = Tr('কৃত্রিম নমুনা', 'Synthetic sample');
  static const comingSoonForSyllabus = Tr(
    'এই সিলেবাস টপিকের জন্য এখনো তৈরি হয়নি',
    'Not yet available for this syllabus topic',
  );
  static const unsavedChanges = Tr('অসংরক্ষিত পরিবর্তন আছে', 'You have unsaved changes');
  static const discard = Tr('বাদ দিন', 'Discard');
  static const areYouSure = Tr('আপনি কি নিশ্চিত?', 'Are you sure?');
  static const cannotUndo = Tr('এটি পূর্বাবস্থায় ফেরানো যাবে না।', 'This cannot be undone.');

  // Navigation
  static const home = Tr('হোম', 'Home');
  static const learn = Tr('শিখি', 'Learn');
  static const tutor = Tr('AI টিউটর', 'AI Tutor');
  static const practice = Tr('অনুশীলন', 'Practice');
  static const notifications = Tr('নোটিফিকেশন', 'Notifications');
  static const settings = Tr('সেটিংস', 'Settings');
  static const profile = Tr('প্রোফাইল', 'Profile');
  static const logout = Tr('লগআউট', 'Log out');

  // Common nouns
  static const minutes = Tr('মিনিট', 'min');
  static const questions = Tr('প্রশ্ন', 'Questions');
  static const marks = Tr('নম্বর', 'Marks');
  static const subject = Tr('বিষয়', 'Subject');
  static const chapter = Tr('অধ্যায়', 'Chapter');
  static const topic = Tr('টপিক', 'Topic');
  static const paper = Tr('পত্র', 'Paper');
  static const difficulty = Tr('কাঠিন্য', 'Difficulty');
  static const today = Tr('আজ', 'Today');
  static const yesterday = Tr('গতকাল', 'Yesterday');
  static const easy = Tr('সহজ', 'Easy');
  static const medium = Tr('মাঝারি', 'Medium');
  static const hard = Tr('কঠিন', 'Hard');
}
