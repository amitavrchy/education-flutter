import '../../core/config/env.dart';
import '../../core/l10n/tr.dart';

abstract final class FcStrings {
  static const flashcards = Tr('ফ্ল্যাশকার্ড', 'Flashcards');
  static const dueToday = Tr('আজ রিভিশন', 'Due today');
  static const learned = Tr('শেখা হয়েছে', 'Learned');
  static const total = Tr('মোট কার্ড', 'Total cards');
  static const reviewedToday = Tr('আজ রিভিউ', 'Reviewed today');
  static const dailyQueue = Tr('আজকের রিভিশন শুরু করো', 'Start today’s review');
  static const nothingDue = Tr('আজ রিভিশনের কিছু বাকি নেই 🎉', 'Nothing due today 🎉');
  static const decks = Tr('ডেক', 'Decks');
  static const newDeck = Tr('নতুন ডেক', 'New deck');
  static const deckName = Tr('ডেকের নাম', 'Deck name');
  static const generate = Tr('AI দিয়ে তৈরি', 'Generate');
  static const fromChapter = Tr('অধ্যায় থেকে', 'From a chapter');
  static const fromMistakes = Tr('ভুল উত্তর থেকে', 'From wrong answers');
  static const fromNotes = Tr('নোট থেকে', 'From notes');
  static const noCardsGenerated = Tr('কার্ড বানানোর মতো কনটেন্ট পাওয়া যায়নি', 'Not enough content to make cards');
  static const deckCreated = Tr('{n}টি কার্ডসহ ডেক তৈরি হয়েছে', 'Deck created with {n} cards');
  static const cards = Tr('{n}টি কার্ড', '{n} cards');
  static const due = Tr('{n}টি বাকি', '{n} due');
  static const study = Tr('স্টাডি', 'Study');
  static const quickReview = Tr('দ্রুত রিভিউ', 'Quick review');
  static const addCard = Tr('কার্ড যোগ করো', 'Add card');
  static const editCard = Tr('কার্ড সম্পাদনা', 'Edit card');
  static const front = Tr('সামনে (প্রশ্ন)', 'Front (prompt)');
  static const back = Tr('পেছনে (উত্তর)', 'Back (answer)');
  static const deleteDeck = Tr('ডেক মুছবে?', 'Delete deck?');
  static const deleteCard = Tr('কার্ড মুছবে?', 'Delete card?');
  static const searchCards = Tr('কার্ড খুঁজুন', 'Search cards');
  static const filterAll = Tr('সব', 'All');
  static const filterDue = Tr('বাকি', 'Due');
  static const filterNew = Tr('নতুন', 'New');
  static const filterBookmarked = Tr('বুকমার্ক', 'Bookmarked');
  static const filterLearned = Tr('শেখা', 'Learned');
  static const tapToFlip = Tr('উল্টাতে ট্যাপ করো', 'Tap to flip');
  static const showAnswer = Tr('উত্তর দেখো', 'Show answer');
  static const known = Tr('জানি', 'I know it');
  static const unknown = Tr('জানি না', 'Don’t know');
  static const nextIn = Tr('পরের রিভিউ: {t}', 'Next review: {t}');
  static const sessionDone = Tr('সেশন শেষ!', 'Session complete!');
  static const sessionSummary = Tr('{n}টি কার্ড রিভিউ করেছ · +{xp} XP', 'Reviewed {n} cards · +{xp} XP');
  static const cardNofM = Tr('কার্ড {n}/{m}', 'Card {n}/{m}');
  static const quickNote = Tr('দ্রুত রিভিউ সময়সূচি বদলায় না', 'Quick review does not change the schedule');
  static const emptyDeck = Tr('এই ডেকে কোনো কার্ড নেই', 'No cards in this deck');
  static const empty = Tr('এখনো কোনো ডেক নেই', 'No decks yet');
  static const srsInfo = Tr(
    'সরলীকৃত স্পেসড রিপিটিশন: “আবার” দিলে ১০ মিনিট পরে, “ভালো” দিলে ১ → ৩ → ক্রমশ বেশি দিন পরে আবার আসবে।',
    'Simplified spaced repetition: “Again” brings a card back in 10 minutes; “Good” spaces it 1 → 3 → more days.',
  );
  static Tr get aiDeck => Env.useMockApi ? const Tr('AI-তৈরি (সিমুলেটেড)', 'AI-generated (simulated)') : const Tr('AI-তৈরি', 'AI-generated');
  static const days = Tr('{n} দিন', '{n} days');
  static const minutes10 = Tr('১০ মিনিট', '10 min');
}
