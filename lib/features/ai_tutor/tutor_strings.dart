import '../../core/config/env.dart';
import '../../core/l10n/tr.dart';

abstract final class TutorStrings {
  static const tutor = Tr('AI টিউটর', 'AI Tutor');
  static const newChat = Tr('নতুন কথোপকথন', 'New chat');
  static const voiceTutorTooltip = Tr('ভয়েস টিউটর', 'Voice tutor');
  static const searchChats = Tr('কথোপকথন খুঁজুন', 'Search conversations');
  static const pinned = Tr('পিন করা', 'Pinned');
  static const recent = Tr('সাম্প্রতিক', 'Recent');
  static const archived = Tr('আর্কাইভ', 'Archived');
  static const showArchived = Tr('আর্কাইভ দেখুন', 'Show archived');
  static const hideArchived = Tr('আর্কাইভ লুকান', 'Hide archived');
  static const groupBy = Tr('সাজান', 'Group by');
  static const byDate = Tr('তারিখ', 'Date');
  static const bySubject = Tr('বিষয়', 'Subject');
  static const byChapter = Tr('অধ্যায়', 'Chapter');
  static const byFolder = Tr('ফোল্ডার', 'Folder');
  static const noFolder = Tr('ফোল্ডার নেই', 'No folder');
  static const general = Tr('সাধারণ', 'General');
  static const emptyTitle = Tr('এখনো কোনো কথোপকথন নেই', 'No conversations yet');
  static const emptyHint = Tr('যেকোনো বিষয়ে প্রশ্ন করে শুরু করো।', 'Start by asking about any subject.');
  static const bookmarkedAnswers = Tr('সংরক্ষিত উত্তর', 'Saved answers');
  static Tr get transparency => Env.useMockApi
      ? const Tr(
          'সিমুলেটেড AI: উত্তরগুলো ডেমো জ্ঞানভাণ্ডার ও নমুনা পাঠ্যবই থেকে তৈরি। গুরুত্বপূর্ণ তথ্য বই ও শিক্ষকের সাথে মিলিয়ে নাও।',
          'Simulated AI: answers come from a demo knowledge base and sample textbooks. Check important facts with your book and teacher.',
        )
      : const Tr(
          'AI উত্তর পাঠ্যবইয়ের অংশ থেকে লেখা হয়, তবু ভুল হতে পারে। গুরুত্বপূর্ণ তথ্য বই ও শিক্ষকের সাথে মিলিয়ে নাও।',
          'AI answers are written from textbook passages but can still be wrong. Check important facts with your book and teacher.',
        );
  static const askHint = Tr('প্রশ্ন লেখো…', 'Ask a question…');
  static const send = Tr('পাঠাও', 'Send');
  static const stop = Tr('থামাও', 'Stop');
  static const thinking = Tr('উত্তর খুঁজছি…', 'Finding the answer…');
  static const context = Tr('পড়ার প্রসঙ্গ', 'Study context');
  static const contextHint = Tr('প্রসঙ্গ বদলালে উত্তর ও উৎসও বদলাবে।', 'Changing the context changes the answers and sources.');
  static const mode = Tr('শেখানোর ধরন', 'Teaching mode');
  static const language = Tr('উত্তরের ভাষা', 'Answer language');
  static const level = Tr('স্তর', 'Level');
  static const classYear = Tr('শ্রেণি', 'Class');
  static const curriculum = Tr('শিক্ষাক্রম', 'Curriculum');
  static const anySubject = Tr('যেকোনো বিষয়', 'Any subject');
  static const anyChapter = Tr('যেকোনো অধ্যায়', 'Any chapter');
  static const anyTopic = Tr('যেকোনো টপিক', 'Any topic');
  static const sources = Tr('উৎস', 'Sources');
  static const page = Tr('পৃষ্ঠা {n}', 'Page {n}');
  static const sourceViewer = Tr('উৎস দেখুন', 'Source viewer');
  static const sampleSourceNote = Tr(
    'নমুনা পাঠ্যবই — ডেমোর জন্য লেখা কৃত্রিম অংশ, আসল NCTB বই নয়।',
    'Sample textbook — synthetic passage written for the demo, not a real NCTB book.',
  );
  static const confidence = Tr('নিশ্চয়তা', 'Confidence');
  static const relatedQuestions = Tr('সম্পর্কিত প্রশ্ন', 'Related questions');
  static const helpful = Tr('সহায়ক', 'Helpful');
  static const notHelpful = Tr('সহায়ক নয়', 'Not helpful');
  static const thanksFeedback = Tr('মতামতের জন্য ধন্যবাদ!', 'Thanks for the feedback!');
  static const regenerate = Tr('আবার তৈরি করো', 'Regenerate');
  static const versionsLabel = Tr('আগের {n}টি সংস্করণ', '{n} earlier versions');
  static const correctionHistory = Tr('উত্তরের সংশোধন ইতিহাস', 'Answer correction history');
  static const teacherReview = Tr('শিক্ষককে দেখাও', 'Ask a teacher');
  static const teacherReviewSent = Tr('শিক্ষকের রিভিউ তালিকায় পাঠানো হয়েছে', 'Sent to the teacher review queue');
  static const teacherReviewPending = Tr('শিক্ষকের রিভিউ চলছে', 'Teacher review pending');
  static const simpler = Tr('আরও সহজ', 'Simpler');
  static const deeper = Tr('আরও বিস্তারিত', 'More detail');
  static const simplerPrompt = Tr('আগের উত্তরটা আরও সহজ করে বলো', 'Explain the previous answer more simply');
  static const deeperPrompt = Tr('আগের উত্তরটা আরও বিস্তারিত বলো', 'Explain the previous answer in more depth');
  static const editQuestion = Tr('প্রশ্ন সম্পাদনা', 'Edit question');
  static const edited = Tr('সম্পাদিত', 'edited');
  static const errorAnswer = Tr('উত্তর আনা যায়নি।', 'Couldn’t get an answer.');
  static const offlineAnswer = Tr('AI টিউটরের জন্য ইন্টারনেট দরকার। সংযোগ ফিরলে আবার চেষ্টা করো।', 'The AI tutor needs the internet. Try again when you are back online.');
  static const interrupted = Tr('উত্তর মাঝপথে থেমে গিয়েছিল।', 'The answer was interrupted.');
  static const reportReasons = [
    Tr('উত্তর ভুল', 'Incorrect answer'),
    Tr('উৎস ভুল বা নেই', 'Wrong or missing source'),
    Tr('বয়স-অনুপযোগী বা অনিরাপদ', 'Inappropriate or unsafe'),
    Tr('বোঝা যায় না', 'Hard to understand'),
  ];
  static const exportDone = Tr('কথোপকথন Markdown হিসেবে কপি হয়েছে', 'Conversation copied as Markdown');
  static const share = Tr('শেয়ার', 'Share');
  static const shareTitle = Tr('নিরাপদ শেয়ার', 'Share safely');
  static const shareIncludeName = Tr('আমার নাম যুক্ত করো', 'Include my name');
  static const shareIncludeSources = Tr('উৎস যুক্ত করো', 'Include sources');
  static const shareNote = Tr(
    'ডিফল্টভাবে তোমার নাম ও ব্যক্তিগত তথ্য লুকানো থাকে। লিংকটি সিমুলেটেড — ডেমোতে কোথাও আপলোড হয় না।',
    'Your name and personal details are hidden by default. The link is simulated — nothing is uploaded in the demo.',
  );
  static const linkCopied = Tr('শেয়ার লিংক কপি হয়েছে (সিমুলেটেড)', 'Share link copied (simulated)');
  static const export = Tr('এক্সপোর্ট (Markdown)', 'Export (Markdown)');
  static const toQuiz = Tr('কুইজ বানাও', 'Make a quiz');
  static const toNotes = Tr('নোটে রূপান্তর', 'Convert to notes');
  static const toFlashcards = Tr('ফ্ল্যাশকার্ড বানাও', 'Make flashcards');
  static const quizEmpty = Tr('এই কথোপকথন থেকে কুইজ বানানোর মতো প্রশ্ন পাওয়া যায়নি', 'No questions found to build a quiz from this chat');
  static const moveToFolder = Tr('ফোল্ডারে সরাও', 'Move to folder');
  static const folderName = Tr('ফোল্ডারের নাম', 'Folder name');
  static const deleteChat = Tr('কথোপকথন মুছবে?', 'Delete conversation?');
  static const integrityReminder = Tr(
    'বোর্ড উত্তর মোড পরীক্ষার প্রস্তুতির জন্য। পরীক্ষার হলে বা অ্যাসাইনমেন্টে হুবহু কপি করবে না।',
    'Board-answer mode is for exam preparation. Don’t copy it verbatim into exams or assignments.',
  );
  static const suggestions = [
    Tr('নিউটনের দ্বিতীয় সূত্র বুঝিয়ে দাও', "Explain Newton's second law"),
    Tr('সালোকসংশ্লেষণের দ্রুত রিভিশন', 'Quick revision of photosynthesis'),
    Tr('মোল কী? উদাহরণ দাও', 'What is a mole? Give an example'),
    Tr('Each of the boys have a book — ঠিক আছে?', 'Is “Each of the boys have a book” correct?'),
    Tr('জাবেদা দাখিলা কীভাবে দিই?', 'How do I write journal entries?'),
    Tr('১৩ কে বাইনারিতে রূপান্তর', 'Convert 13 to binary'),
  ];
}
