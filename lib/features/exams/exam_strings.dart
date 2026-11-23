import '../../core/l10n/tr.dart';

abstract final class ExamStrings {
  static const center = Tr('পরীক্ষা কেন্দ্র', 'Exam centre');
  static const inProgress = Tr('চলমান পরীক্ষা', 'In progress');
  static const resume = Tr('আবার শুরু করো', 'Resume');
  static const discard = Tr('বাতিল করো', 'Discard');
  static const discardConfirm = Tr('এই চেষ্টা বাতিল করবে?', 'Discard this attempt?');
  static const available = Tr('তোমার জন্য পরীক্ষা', 'Exams for you');
  static const createCustom = Tr('নিজের পরীক্ষা তৈরি করো', 'Create your own exam');
  static const createCustomHint = Tr('বিষয়, অধ্যায়, সময় ও নম্বর নিজে ঠিক করো', 'Choose subject, chapters, time and marks');
  static const adaptive = Tr('অ্যাডাপটিভ পরীক্ষা', 'Adaptive exam');
  static const adaptiveHint = Tr('তোমার দুর্বল টপিক থেকে প্রশ্ন বেছে নেয়', 'Picks questions from your weakest topics');
  static const recent = Tr('সাম্প্রতিক ফলাফল', 'Recent results');
  static const due = Tr('জমার শেষ: {d}', 'Due {d}');
  static const opensAt = Tr('শুরু: {d}', 'Opens {d}');
  static const notOpenYet = Tr('এখনো খোলেনি', 'Not open yet');
  static const completed = Tr('সম্পন্ন', 'Completed');
  static const minutes = Tr('{n} মিনিট', '{n} min');
  static const questions = Tr('{n}টি প্রশ্ন', '{n} questions');

  // Setup
  static const setup = Tr('পরীক্ষা সেটআপ', 'Exam setup');
  static const subject = Tr('বিষয়', 'Subject');
  static const chooseSubject = Tr('বিষয় বেছে নাও', 'Choose a subject');
  static const chapters = Tr('অধ্যায় (না বাছলে সব)', 'Chapters (none = all)');
  static const types = Tr('প্রশ্নের ধরন (না বাছলে সব)', 'Question types (none = all)');
  static const count = Tr('প্রশ্ন সংখ্যা', 'Number of questions');
  static const timeLimit = Tr('সময়সীমা', 'Time limit');
  static const negative = Tr('ভুল উত্তরে নম্বর কাটা (−০.২৫)', 'Negative marking (−0.25)');
  static const mode = Tr('মোড', 'Mode');
  static const randomize = Tr('প্রশ্ন এলোমেলো করো', 'Randomise questions');
  static const reviewPolicy = Tr('উত্তর দেখানোর নিয়ম', 'Review policy');
  static const availableCount = Tr('এই শর্তে {n}টি প্রশ্ন আছে', '{n} questions match');
  static const notEnough = Tr('যথেষ্ট প্রশ্ন নেই — শর্ত শিথিল করো', 'Not enough questions — loosen the filters');
  static const totalMarks = Tr('মোট নম্বর: {n}', 'Total marks: {n}');
  static const startExam = Tr('পরীক্ষা শুরু করো', 'Start exam');

  // Taking
  static const instructions = Tr('নির্দেশনা', 'Instructions');
  static const instructionLines = [
    Tr('সময় শেষ হলে পরীক্ষা নিজে থেকেই জমা হয়ে যাবে।', 'The exam submits itself when time runs out.'),
    Tr('প্রতিটি উত্তর সাথে সাথে সংরক্ষিত হয় — অ্যাপ বন্ধ হলেও পরে আবার শুরু করা যাবে।', 'Every answer is saved instantly — you can resume if the app closes.'),
    Tr('অনিশ্চিত প্রশ্ন “রিভিউ” চিহ্নিত করে পরে ফিরে এসো।', 'Mark unsure questions for review and come back later.'),
    Tr('লিখিত উত্তরের নম্বর AI-এর আনুমানিক মূল্যায়ন (সিমুলেটেড) — চূড়ান্ত নয়।', 'Marks for written answers are a simulated AI estimate — not final.'),
  ];
  static const begin = Tr('শুরু করো', 'Begin');
  static const timeLeft = Tr('বাকি সময়', 'Time left');
  static const palette = Tr('প্রশ্ন তালিকা', 'Question palette');
  static const markReview = Tr('রিভিউর জন্য চিহ্নিত', 'Mark for review');
  static const answered = Tr('উত্তর দেওয়া', 'Answered');
  static const notAnswered = Tr('উত্তর বাকি', 'Not answered');
  static const writeAnswer = Tr('তোমার উত্তর লেখো', 'Write your answer');
  static const uploadHandwritten = Tr('হাতে লেখা উত্তরের ছবি', 'Photo of handwritten answer');
  static const imagesAttached = Tr('{n}টি ছবি যুক্ত', '{n} photos attached');
  static const submit = Tr('জমা দাও', 'Submit');
  static const submitConfirm = Tr('পরীক্ষা জমা দেবে?', 'Submit the exam?');
  static const submitSummary = Tr(
    '{a}টি উত্তর দেওয়া, {u}টি বাকি, {r}টি রিভিউ চিহ্নিত। জমা দেওয়ার পর পরিবর্তন করা যাবে না।',
    '{a} answered, {u} unanswered, {r} marked for review. You cannot change answers after submitting.',
  );
  static const timeUp = Tr('সময় শেষ! পরীক্ষা জমা হয়েছে।', 'Time is up! Your exam has been submitted.');
  static const leaveExam = Tr('পরীক্ষা থেকে বের হবে?', 'Leave the exam?');
  static const leaveExamBody = Tr(
    'উত্তরগুলো সংরক্ষিত আছে। পরীক্ষা কেন্দ্র থেকে আবার শুরু করতে পারবে, তবে সময় চলতে থাকবে না।',
    'Your answers are saved. Resume from the exam centre; the timer pauses while you are away.',
  );
  static const leave = Tr('বের হও', 'Leave');
  static const recovered = Tr('আগের সেশন ফিরিয়ে আনা হয়েছে', 'Previous session recovered');

  // Results
  static const result = Tr('ফলাফল', 'Result');
  static const results = Tr('ফলাফল ইতিহাস', 'Result history');
  static const score = Tr('প্রাপ্ত নম্বর', 'Score');
  static const correct = Tr('সঠিক', 'Correct');
  static const incorrect = Tr('ভুল', 'Incorrect');
  static const unanswered = Tr('উত্তর দেওয়া হয়নি', 'Unanswered');
  static const estimated = Tr('আনুমানিক (AI)', 'Estimated (AI)');
  static const timeSpent = Tr('সময় লেগেছে', 'Time spent');
  static const accuracy = Tr('নির্ভুলতা', 'Accuracy');
  static const grade = Tr('গ্রেড', 'Grade');
  static const estimateNote = Tr(
    'লিখিত উত্তরের নম্বর AI-এর আনুমানিক মূল্যায়ন (সিমুলেটেড, চূড়ান্ত নয়)। শিক্ষকের মূল্যায়নই চূড়ান্ত।',
    'Written-answer marks are a simulated AI estimate (not authoritative). Your teacher’s marks are final.',
  );
  static const byTopic = Tr('টপিকভিত্তিক বিশ্লেষণ', 'Topic-wise analysis');
  static const byDifficulty = Tr('কাঠিন্যভিত্তিক বিশ্লেষণ', 'Difficulty analysis');
  static const questionWise = Tr('প্রশ্নভিত্তিক বিশ্লেষণ', 'Question-wise analysis');
  static const weakAreas = Tr('দুর্বল জায়গা ও পরামর্শ', 'Weak areas & recommendations');
  static const noWeak = Tr('কোনো দুর্বল টপিক পাওয়া যায়নি — চমৎকার!', 'No weak topics found — excellent!');
  static const reviseTopic = Tr('পড়ো', 'Revise');
  static const practiceTopic = Tr('অনুশীলন', 'Practise');
  static const retake = Tr('আবার দাও', 'Retake');
  static const printResult = Tr('প্রিন্টযোগ্য ফলাফল', 'Printable result');
  static const teacherFeedback = Tr('শিক্ষকের মন্তব্য', 'Teacher feedback');
  static const yourAnswer = Tr('তোমার উত্তর: {a}', 'Your answer: {a}');
  static const noAnswer = Tr('উত্তর দেওয়া হয়নি', 'Not answered');
  static const answersHidden = Tr('এই পরীক্ষায় উত্তর দেখানো বন্ধ রাখা হয়েছে।', 'Answers are hidden for this exam.');
  static const noResults = Tr('এখনো কোনো পরীক্ষা দাওনি', 'No exams taken yet');
  static const noResultsHint = Tr('পরীক্ষা কেন্দ্র থেকে একটি মডেল টেস্ট দিয়ে শুরু করো।', 'Start with a model test from the exam centre.');
  static const trend = Tr('নম্বরের ধারা', 'Score trend');
  static const expired = Tr('সময় শেষে জমা', 'Auto-submitted');
}
