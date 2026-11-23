import '../../../core/l10n/tr.dart';
import '../data/curriculum_repository.dart';

/// Builds a structured study summary for a topic from its syllabus metadata.
///
/// This stands in for AI-generated / editor-approved lesson content. It never reproduces
/// textbook text: it only restates the topic title and learning outcome as study guidance.
String lessonMarkdown(TopicRef ref, AppLanguage lang) {
  final bn = lang == AppLanguage.bn;
  final title = ref.topic.title.of(lang);
  final chapter = ref.chapter.title.of(lang);
  final outcomes = [for (final o in ref.topic.outcomes) o.text.of(lang)];
  final b = StringBuffer()
    ..writeln('## $title')
    ..writeln(bn
        ? 'এই টপিকটি **$chapter** অধ্যায়ের অংশ। নিচের ধাপগুলো অনুসরণ করে পড়ো, তারপর অনুশীলন করে নিজেকে যাচাই করো।'
        : 'This topic is part of **$chapter**. Work through the steps below, then check yourself with practice.')
    ..writeln()
    ..writeln(bn ? '### এই টপিক শেষে তুমি পারবে' : '### By the end you should be able to');
  for (final o in outcomes) {
    b.writeln('- $o');
  }
  b
    ..writeln()
    ..writeln(bn ? '### কীভাবে পড়বে' : '### How to study it')
    ..writeln(bn
        ? '1. পাঠ্যবইয়ে “$title” অংশটি একবার মনোযোগ দিয়ে পড়ো।'
        : '1. Read the “$title” section of your textbook once, carefully.')
    ..writeln(bn
        ? '2. মূল সংজ্ঞা ও সূত্রগুলো নিজের ভাষায় খাতায় লেখো।'
        : '2. Write the key definitions and formulas in your own words.')
    ..writeln(bn
        ? '3. অন্তত একটি উদাহরণ নিজে সমাধান করো, তারপর বইয়ের সমাধানের সাথে মেলাও।'
        : '3. Solve at least one example yourself, then compare with the textbook.')
    ..writeln(bn
        ? '4. ৫টি MCQ ও ১টি সৃজনশীল প্রশ্ন অনুশীলন করো।'
        : '4. Practise 5 MCQs and 1 creative question.')
    ..writeln()
    ..writeln(bn
        ? '> **টিপ:** বোর্ড পরীক্ষায় এই অংশ থেকে প্রায়ই প্রয়োগমূলক প্রশ্ন আসে — শুধু মুখস্থ না করে “কেন” বোঝার চেষ্টা করো।'
        : '> **Tip:** Board exams often ask application questions here — aim to understand *why*, not just memorise.');
  return b.toString();
}
