import '../../core/l10n/tr.dart';

abstract final class AvatarStrings {
  static const galleryTitle = Tr('বইয়ের শিক্ষক', 'Book teachers');
  static const galleryHeadline = Tr('বইয়ের শিক্ষক — লাইভ অ্যাভাটার', 'Book teachers — live avatars');
  static const galleryHint = Tr(
    'প্রতিটি বইয়ের নিজস্ব শিক্ষক। লিখে বা কথা বলে প্রশ্ন করো — উত্তর আসবে শুধু ওই বই থেকে, পৃষ্ঠা নম্বরসহ।',
    'Every book has its own teacher. Ask by typing or speaking — answers come only from that book, with page numbers.',
  );
  static const recentClasses = Tr('সাম্প্রতিক ক্লাস', 'Recent classes');
  static const searchHint = Tr('বই বা শিক্ষক খুঁজুন', 'Search books or teachers');
  static const all = Tr('সব', 'All');
  static const ask = Tr('প্রশ্ন করো', 'Ask');
  static const noBooks = Tr('কোনো বই পাওয়া যায়নি', 'No books found');
  static const onlyThisBook = Tr('শুধু এই বই থেকে উত্তর', 'Answers from this book only');
  static const startClass = Tr('ক্লাস শুরু করো', 'Start class');
  static const history = Tr('আগের ক্লাস', 'Past classes');
  static const noHistory = Tr('এই বইয়ের কোনো আগের ক্লাস নেই।', 'No past classes for this book.');
  static const newClass = Tr('নতুন ক্লাস', 'New class');
  static const askHint = Tr('এই বই থেকে প্রশ্ন লেখো…', 'Ask something from this book…');
  static const send = Tr('পাঠাও', 'Send');
  static const idle = Tr('প্রশ্ন করো — লিখে বা কথা বলে', 'Ask — by typing or speaking');
  static const listening = Tr('শুনছি…', 'Listening…');
  static const thinking = Tr('বইয়ে খুঁজছি…', 'Looking in the book…');
  static const speaking = Tr('বলছি…', 'Speaking…');
  static const askByVoice = Tr('কথা বলে প্রশ্ন করো', 'Ask by voice');
  static const stopListening = Tr('শোনা বন্ধ', 'Stop listening');
  static const stopSpeaking = Tr('থামাও', 'Stop');
  static const mute = Tr('শব্দ বন্ধ', 'Mute');
  static const unmute = Tr('শব্দ চালু', 'Unmute');
  static const speed = Tr('গতি', 'Speed');
  static const handsFree = Tr('হ্যান্ডস-ফ্রি: উত্তর শেষে আবার শুনবে', 'Hands-free: listens again after each answer');
  static const noVoice = Tr(
    'এই ডিভাইসে এই ভাষার কণ্ঠ নেই — অ্যাভাটার ঠোঁট নাড়বে, ক্যাপশন পড়ো।',
    'No voice for this language on this device — the avatar lip-syncs; read the captions.',
  );
  static const micUnavailable = Tr(
    'এই ডিভাইসে কণ্ঠ শনাক্তকরণ নেই বা মাইক্রোফোনের অনুমতি দেওয়া হয়নি। নমুনা প্রশ্ন বেছে নাও বা লিখে প্রশ্ন করো।',
    'Speech recognition is unavailable or the microphone permission was denied. Pick a sample question or type instead.',
  );
  static const sampleVoiceQuestions = Tr('নমুনা কণ্ঠ প্রশ্ন (ডেমো)', 'Sample voice questions (demo)');
  static const offline = Tr(
    'অফলাইন — অ্যাভাটার শিক্ষকের জন্য ইন্টারনেট লাগে। ডাউনলোড করা বই পড়তে পারো।',
    'Offline — the avatar teacher needs internet. You can still read downloaded books.',
  );
  static const fromBook = Tr('বই থেকে', 'From the book');
  static const outsideBook = Tr('বইয়ের বাইরে', 'Outside the book');
  static const page = Tr('পৃষ্ঠা {n}', 'Page {n}');
  static const replay = Tr('আবার শোনো', 'Replay');
  static const helpful = Tr('সহায়ক', 'Helpful');
  static const notHelpful = Tr('সহায়ক নয়', 'Not helpful');
  static const report = Tr('ভুল উত্তর রিপোর্ট', 'Report answer');
  static const reportReason = Tr('কী ভুল মনে হলো?', 'What seems wrong?');
  static const reportSent = Tr('রিপোর্ট পাঠানো হয়েছে — শিক্ষক দেখবেন', 'Report sent — a teacher will review it');
  static const thanks = Tr('মতামতের জন্য ধন্যবাদ', 'Thanks for the feedback');
  static const cancel = Tr('বাতিল', 'Cancel');
  static const submit = Tr('পাঠাও', 'Submit');
  static const sourceSheet = Tr('বইয়ের পৃষ্ঠা', 'Book page');
  static const openInBook = Tr('বইয়ে এই পৃষ্ঠা খুলুন', 'Open this page in the book');
  static const sampleBookNote = Tr(
    'নমুনা পাঠ্যবই — ডেমোর জন্য লেখা কৃত্রিম অংশ, আসল NCTB বই নয়।',
    'Sample textbook — synthetic text written for the demo, not a real NCTB book.',
  );
  static const askTeacherOfBook = Tr('এই বইয়ের শিক্ষককে জিজ্ঞেস করো', "Ask this book's teacher");

  // Teacher
  static const teacherTitle = Tr('অ্যাভাটার শিক্ষক', 'Avatar teachers');
  static const teacherHint = Tr(
    'শিক্ষার্থীরা যে অ্যাভাটারের সাথে কথা বলে সেগুলো পরীক্ষা করুন এবং রিপোর্ট করা উত্তর সংশোধন করুন। চেহারা ও কণ্ঠ বদলানো যায় ওয়েবের অ্যাডমিন প্যানেল থেকে।',
    'Test the avatars students talk to and fix reported answers. Appearance and voice are edited in the web admin panel.',
  );
  static const avatarsTab = Tr('অ্যাভাটার', 'Avatars');
  static const reportsTab = Tr('রিপোর্ট', 'Reports');
  static const testChat = Tr('পরীক্ষা চ্যাট', 'Test chat');
  static const testHint = Tr('পরীক্ষামূলক প্রশ্ন…', 'Test question…');
  static const testNote = Tr(
    'এখানে প্রশ্ন করে দেখুন অ্যাভাটার কীভাবে উত্তর দেয় — কিছুই সংরক্ষিত হয় না।',
    'Try questions to see how the avatar answers — nothing is saved.',
  );
  static const sessions = Tr('ক্লাস', 'Classes');
  static const questions = Tr('প্রশ্ন', 'Questions');
  static const outOfScope = Tr('বাইরের', 'Out of scope');
  static const satisfaction = Tr('সন্তুষ্টি', 'Satisfaction');
  static const persona = Tr('শেখানোর ধরন', 'Teaching style');
  static const answerLength = Tr('উত্তরের দৈর্ঘ্য', 'Answer length');
  static const scope = Tr('উত্তরের পরিধি', 'Answer scope');
  static const wholeBook = Tr('পুরো বই', 'Whole book');
  static const strictScope = Tr('শুধু বই থেকে উত্তর (কড়া নিয়ম)', 'Book-only answers (strict)');
  static const open = Tr('খোলা', 'Open');
  static const resolved = Tr('সমাধান হয়েছে', 'Resolved');
  static const dismissed = Tr('বাতিল', 'Dismissed');
  static const resolve = Tr('সমাধান', 'Resolve');
  static const dismiss = Tr('বাতিল করুন', 'Dismiss');
  static const resolutionHint = Tr('সমাধানের নোট / সঠিক উত্তর', 'Resolution note / correct answer');
  static const noReports = Tr('কোনো রিপোর্ট নেই', 'No reports');
  static const question = Tr('প্রশ্ন', 'Question');
  static const reason = Tr('কারণ', 'Reason');

  // Parent
  static const parentTitle = Tr('অ্যাভাটার শিক্ষকের ব্যবহার', 'Avatar teacher usage');
  static const parentHint = Tr(
    'সন্তান কোন বইয়ের শিক্ষকের সাথে কতক্ষণ পড়েছে। গোপনীয়তার জন্য প্রশ্ন ও উত্তরের লেখা দেখানো হয় না।',
    'Which book teachers your child studied with and for how long. Questions and answers are not shown, for privacy.',
  );
  static const minutes = Tr('মিনিট', 'Minutes');
  static const byBook = Tr('বই অনুযায়ী', 'By book');
  static const countsOnly = Tr('শুধু সংখ্যা — কথোপকথন শিক্ষার্থীর কাছে প্রাইভেট।', 'Counts only — conversations stay private to the student.');
  static const noUsage = Tr('এখনো কোনো অ্যাভাটার ক্লাস হয়নি।', 'No avatar classes yet.');
  static const usageRow = Tr('{s} ক্লাস · {q} প্রশ্ন · {m} মিনিট', '{s} classes · {q} questions · {m} min');
}
