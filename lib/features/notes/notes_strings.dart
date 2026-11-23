import '../../core/l10n/tr.dart';

abstract final class NotesStrings {
  static const notes = Tr('নোটস', 'Notes');
  static const search = Tr('নোট খুঁজুন', 'Search notes');
  static const newNote = Tr('নতুন নোট', 'New note');
  static const generate = Tr('AI দিয়ে তৈরি', 'Generate with AI');
  static const favorites = Tr('প্রিয়', 'Favourites');
  static const allFolders = Tr('সব ফোল্ডার', 'All folders');
  static const noFolder = Tr('ফোল্ডার ছাড়া', 'No folder');
  static const empty = Tr('এখনো কোনো নোট নেই', 'No notes yet');
  static const emptyHint = Tr('নিজে লেখো বা অধ্যায় থেকে AI দিয়ে তৈরি করো।', 'Write one yourself or generate from a chapter.');
  static const untitled = Tr('শিরোনামহীন নোট', 'Untitled note');
  static const titleHint = Tr('শিরোনাম', 'Title');
  static const bodyHint = Tr('লেখা শুরু করো… (Markdown ও \$গণিত\$ চলবে)', 'Start writing… (Markdown and \$math\$ supported)');
  static const preview = Tr('প্রিভিউ', 'Preview');
  static const edit = Tr('সম্পাদনা', 'Edit');
  static const saved = Tr('স্বয়ংক্রিয়ভাবে সংরক্ষিত', 'Auto-saved');
  static const saving = Tr('সংরক্ষণ হচ্ছে…', 'Saving…');
  static const tags = Tr('ট্যাগ', 'Tags');
  static const tagsHint = Tr('কমা দিয়ে আলাদা করো', 'Separate with commas');
  static const folder = Tr('ফোল্ডার', 'Folder');
  static const linked = Tr('সংযুক্ত নোট', 'Linked notes');
  static const linkNote = Tr('নোট সংযুক্ত করো', 'Link a note');
  static const history = Tr('সংস্করণের ইতিহাস', 'Version history');
  static const noHistory = Tr('আগের কোনো সংস্করণ নেই', 'No earlier versions');
  static const restore = Tr('ফিরিয়ে আনো', 'Restore');
  static const restored = Tr('আগের সংস্করণ ফিরিয়ে আনা হয়েছে', 'Earlier version restored');
  static const exportPdf = Tr('PDF / প্রিন্ট', 'PDF / print');
  static const printNote = Tr(
    'প্রিন্ট-উপযোগী লেআউট। ডেমোতে আসল PDF ফাইল তৈরি হয় না — ডিভাইসের প্রিন্ট/স্ক্রিনশট ব্যবহার করো।',
    'Print-ready layout. The demo does not create a real PDF file — use your device’s print or screenshot.',
  );
  static const deleteConfirm = Tr('নোট মুছবে?', 'Delete note?');
  static const aiLabel = Tr('AI-তৈরি (সিমুলেটেড)', 'AI-generated (simulated)');
  static const generateTitle = Tr('AI নোট তৈরি', 'Generate notes');
  static const from = Tr('উৎস', 'Source');
  static const fromChapter = Tr('অধ্যায়', 'Chapter');
  static const fromTopic = Tr('টপিক', 'Topic');
  static const fromUpload = Tr('ফাইল আপলোড', 'Upload a file');
  static const noteType = Tr('নোটের ধরন', 'Note type');
  static const chooseChapter = Tr('অধ্যায় বেছে নাও', 'Choose a chapter');
  static const chooseTopic = Tr('টপিক বেছে নাও', 'Choose a topic');
  static const generating = Tr('নোট তৈরি হচ্ছে…', 'Generating notes…');
  static const generated = Tr('নোট তৈরি হয়েছে', 'Notes generated');
  static const uploadNote = Tr(
    'PDF, ছবি বা TXT (সর্বোচ্চ ১০ MB)। লেখা শনাক্তকরণ সিমুলেটেড।',
    'PDF, image or TXT (max 10 MB). Text recognition is simulated.',
  );
  static const tooLarge = Tr('ফাইলটি ১০ MB এর বেশি', 'The file is larger than 10 MB');
  static const unsupported = Tr('এই ধরনের ফাইল সমর্থিত নয়', 'This file type is not supported');
  static const pickFile = Tr('ফাইল বেছে নাও', 'Choose file');
  static const fromNote = Tr('এই নোট থেকে ফ্ল্যাশকার্ড', 'Flashcards from this note');
  static const updated = Tr('আপডেট {t}', 'Updated {t}');
}
