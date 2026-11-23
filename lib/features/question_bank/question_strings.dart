import '../../core/l10n/tr.dart';

abstract final class QStrings {
  static const bank = Tr('প্রশ্ন ব্যাংক', 'Question bank');
  static const searchHint = Tr('প্রশ্ন খুঁজুন', 'Search questions');
  static const filters = Tr('ফিল্টার', 'Filters');
  static const type = Tr('প্রশ্নের ধরন', 'Question type');
  static const source = Tr('উৎস', 'Source');
  static const year = Tr('সাল', 'Year');
  static const board = Tr('বোর্ড', 'Board');
  static const marks = Tr('নম্বর', 'Marks');
  static const verifiedOnly = Tr('শুধু যাচাইকৃত', 'Verified only');
  static const highRelevance = Tr('বোর্ডে গুরুত্বপূর্ণ', 'High exam relevance');
  static const any = Tr('যেকোনো', 'Any');
  static const results = Tr('{n}টি প্রশ্ন', '{n} questions');
  static const loadMore = Tr('আরও দেখুন', 'Load more');
  static const showAnswer = Tr('উত্তর দেখুন', 'Show answer');
  static const hideAnswer = Tr('উত্তর লুকান', 'Hide answer');
  static const answer = Tr('উত্তর', 'Answer');
  static const explanation = Tr('ব্যাখ্যা', 'Explanation');
  static const steps = Tr('ধাপে ধাপে সমাধান', 'Step-by-step solution');
  static const altMethod = Tr('বিকল্প পদ্ধতি', 'Alternative method');
  static const rubric = Tr('নম্বর বণ্টন (রুব্রিক)', 'Marking rubric');
  static const stimulus = Tr('উদ্দীপক', 'Stimulus');
  static const matchHint = Tr('বাম পাশের সাথে ডান পাশ মেলাও', 'Match the left column to the right');
  static const iGotIt = Tr('আমি সঠিক পেরেছি', 'I got it right');
  static const iMissed = Tr('ভুল হয়েছে', 'I got it wrong');
  static const markedCorrect = Tr('সঠিক হিসেবে রেকর্ড হয়েছে', 'Recorded as correct');
  static const markedWrong = Tr('ভুল হিসেবে রেকর্ড হয়েছে — রিভিশন তালিকায় যোগ হলো', 'Recorded as wrong — added to your revision list');
  static const addToSet = Tr('অনুশীলন সেটে যোগ করুন', 'Add to practice set');
  static const newSet = Tr('নতুন সেট', 'New set');
  static const setName = Tr('সেটের নাম', 'Set name');
  static const addedToSet = Tr('সেটে যোগ হয়েছে', 'Added to set');
  static const saveToNotes = Tr('নোটে সংরক্ষণ', 'Save to notes');
  static const printView = Tr('প্রিন্ট ভিউ', 'Print view');
  static const printNote = Tr(
    'প্রিন্ট-উপযোগী লেআউট। ডেমোতে প্রিন্টার সংযোগ নেই — স্ক্রিনশট বা PDF হিসেবে সংরক্ষণ করুন।',
    'Print-friendly layout. No printer connection in the demo — save as a screenshot or PDF.',
  );
  static const related = Tr('সম্পর্কিত প্রশ্ন', 'Related questions');
  static const verified = Tr('যাচাইকৃত', 'Verified');
  static const unverified = Tr('যাচাই বাকি', 'Pending review');
  static const boardStyle = Tr('বোর্ড-ধাঁচের নমুনা', 'Board-style sample');
  static const frequency = Tr('{n} বার এসেছে (নমুনা)', 'Appeared {n}× (sample)');
  static const attemptedTimes = Tr('{n} বার চেষ্টা করেছ', 'Attempted {n}×');
  static const citation = Tr('সূত্র: {book}, পৃষ্ঠা {page}', 'Source: {book}, page {page}');
  static const reportReasons = [
    Tr('উত্তর ভুল', 'Wrong answer'),
    Tr('প্রশ্নে ভুল/টাইপো', 'Error or typo in question'),
    Tr('সিলেবাসের বাইরে', 'Outside the syllabus'),
    Tr('অন্য কারণ', 'Other'),
  ];
  static const coverage = Tr('টপিক কভারেজ', 'Topic coverage');
  static const coverageValue = Tr('{done}/{total} টপিক অনুশীলন করেছ', 'Practised {done}/{total} topics');
  static const emptyBank = Tr('এই ফিল্টারে কোনো প্রশ্ন নেই', 'No questions match these filters');
  static const practiceThese = Tr('এগুলো অনুশীলন করুন', 'Practise these');

  // Practice session
  static const session = Tr('অনুশীলন', 'Practice');
  static const questionNofM = Tr('প্রশ্ন {n}/{m}', 'Question {n}/{m}');
  static const check = Tr('যাচাই করুন', 'Check');
  static const correct = Tr('সঠিক!', 'Correct!');
  static const incorrect = Tr('ভুল', 'Incorrect');
  static const typeAnswer = Tr('উত্তর লেখো', 'Type your answer');
  static const finish = Tr('শেষ করুন', 'Finish');
  static const sessionDone = Tr('অনুশীলন শেষ!', 'Practice complete!');
  static const scoreLine = Tr('{c}/{t} সঠিক', '{c}/{t} correct');
  static const xpEarned = Tr('+{n} XP অর্জিত', '+{n} XP earned');
  static const masteryUpdated = Tr('তোমার টপিক দক্ষতা আপডেট হয়েছে', 'Your topic mastery has been updated');
  static const reviewWrong = Tr('ভুলগুলো আবার করো', 'Retry the wrong ones');
  static const noQuestions = Tr('এখানে এখনো প্রশ্ন নেই', 'No questions here yet');
  static const noQuestionsHint = Tr(
    'এই অংশের প্রশ্ন শিক্ষকরা যাচাই করছেন। মিশ্র অনুশীলন বা অন্য অধ্যায় চেষ্টা করো।',
    'Teachers are still reviewing questions for this section. Try mixed practice or another chapter.',
  );
  static const exitSession = Tr('অনুশীলন ছেড়ে যাবে?', 'Leave practice?');
  static const exitSessionBody = Tr('এ পর্যন্ত দেওয়া উত্তরগুলো রেকর্ড থাকবে।', 'Answers so far are already recorded.');
  static const leave = Tr('ছেড়ে যান', 'Leave');

  // Bookmarks screen
  static const bookmarks = Tr('বুকমার্ক', 'Bookmarks');
  static const wrong = Tr('ভুল উত্তর', 'Wrong answers');
  static const sets = Tr('অনুশীলন সেট', 'Practice sets');
  static const history = Tr('ইতিহাস', 'History');
  static const noBookmarks = Tr('কোনো বুকমার্ক নেই', 'No bookmarks yet');
  static const noBookmarksHint = Tr('প্রশ্নের পাশে 🔖 চাপলে এখানে জমা হবে।', 'Tap the bookmark icon on any question to save it here.');
  static const noWrong = Tr('কোনো ভুল উত্তর নেই — দারুণ!', 'No wrong answers — great!');
  static const noSets = Tr('কোনো সেট নেই', 'No practice sets yet');
  static const noHistory = Tr('এখনো কোনো অনুশীলন হয়নি', 'No practice yet');
  static const reattemptAll = Tr('সবগুলো আবার চেষ্টা করো', 'Reattempt all');
  static const deleteSet = Tr('সেট মুছবেন?', 'Delete set?');
  static const setQuestions = Tr('{n}টি প্রশ্ন', '{n} questions');
}
