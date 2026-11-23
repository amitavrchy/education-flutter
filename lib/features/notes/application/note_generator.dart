import '../../../core/l10n/tr.dart';
import '../../../mock/seed/tutor_knowledge_seed.dart';
import '../../ai_tutor/domain/tutor_models.dart';
import '../../curriculum/data/curriculum_repository.dart';
import '../../question_bank/domain/question.dart';
import '../domain/note.dart';

/// Simulated "AI notes" generator. Builds structured notes from syllabus metadata, the
/// sample knowledge base and the question bank — never from real textbook text.
class NoteGenerator {
  NoteGenerator({required this.curriculum, required this.questions, this.knowledge = tutorScenarios});

  final CurriculumRepository curriculum;
  final List<Question> questions;
  final List<TutorScenario> knowledge;

  String _label(AppLanguage lang) => lang == AppLanguage.bn
      ? '> 🤖 AI-তৈরি নোট (সিমুলেটেড) — নমুনা জ্ঞানভাণ্ডার থেকে; বইয়ের সাথে মিলিয়ে নাও।'
      : '> 🤖 AI-generated notes (simulated) — from the sample knowledge base; verify with your book.';

  ({String title, String body}) fromTopics({
    required String scopeTitle,
    required List<TopicRef> topics,
    required NoteType type,
    required AppLanguage lang,
  }) {
    final bn = lang == AppLanguage.bn;
    String t(Tr x) => x.of(lang);
    final topicIds = {for (final r in topics) r.topic.id};
    final chapterIds = {for (final r in topics) r.chapter.id};
    final k = knowledge.where((s) => topicIds.contains(s.topicId) || chapterIds.contains(s.chapterId)).toList();
    final qs = questions.where((q) => topicIds.contains(q.topicId)).toList()..sort((a, b) => b.frequency.compareTo(a.frequency));
    final b = StringBuffer('${_label(lang)}\n\n');

    switch (type) {
      case NoteType.formulaSheet:
        b.writeln('## ${bn ? 'সূত্র তালিকা' : 'Formula sheet'}');
        final withFormula = k.where((s) => s.formula != null);
        if (withFormula.isEmpty) b.writeln(bn ? '_এই অংশে সংরক্ষিত কোনো সূত্র নেই।_' : '_No stored formulas for this part._');
        for (final s in withFormula) {
          b.writeln('### ${t(s.title)}\n\$\$${s.formula}\$\$');
          for (final (sym, meaning) in s.symbols) {
            b.writeln('- \$$sym\$ — ${t(meaning)}');
          }
        }
      case NoteType.definitionSheet:
        b.writeln('## ${bn ? 'সংজ্ঞা' : 'Definitions'}');
        for (final s in k) {
          b.writeln('- **${t(s.title)}:** ${t(s.definition)}');
        }
        for (final q in qs.where((q) => q.type == QuestionType.definition)) {
          b.writeln('- **${t(q.stem)}** ${t(q.answer)}');
        }
        if (k.isEmpty) {
          for (final r in topics) {
            b.writeln('- **${t(r.topic.title)}:** ${t(r.topic.outcomes.first.text)}');
          }
        }
      case NoteType.importantQuestions:
        b.writeln('## ${bn ? 'গুরুত্বপূর্ণ প্রশ্ন' : 'Important questions'}');
        if (qs.isEmpty) b.writeln(bn ? '_এই অংশের প্রশ্ন এখনো যুক্ত হয়নি।_' : '_No questions added for this part yet._');
        for (final q in qs.take(8)) {
          b.writeln('1. ${t(q.stem)}  \n   **${bn ? 'উত্তর' : 'Answer'}:** ${t(q.answer).replaceAll('\n', ' ')}');
        }
      case NoteType.keyTakeaways:
        b.writeln('## ${bn ? 'মূল শিক্ষা' : 'Key takeaways'}');
        for (final s in k) {
          for (final p in s.keyPoints) {
            b.writeln('- ${t(p)}');
          }
        }
        for (final r in topics) {
          for (final o in r.topic.outcomes) {
            b.writeln('- ${t(o.text)}');
          }
        }
      case NoteType.revision:
        b.writeln('## ⚡ ${bn ? 'রিভিশন' : 'Revision'}: $scopeTitle');
        for (final r in topics) {
          b.writeln('### ${t(r.topic.title)}');
          final s = k.where((x) => x.topicId == r.topic.id).firstOrNull;
          if (s != null) {
            b.writeln('- ${t(s.definition)}');
            if (s.formula != null) b.writeln('- \$${s.formula}\$');
            b.writeln('- ⚠️ ${t(s.mistake)}');
          } else {
            b.writeln('- ${t(r.topic.outcomes.first.text)}');
          }
        }
      case NoteType.short:
        b.writeln('## $scopeTitle');
        for (final r in topics) {
          final s = k.where((x) => x.topicId == r.topic.id).firstOrNull;
          b.writeln('- **${t(r.topic.title)}** — ${s == null ? t(r.topic.outcomes.first.text) : t(s.definition)}');
        }
      case NoteType.detailed:
      case NoteType.freeform:
        b.writeln('# $scopeTitle');
        for (final r in topics) {
          b.writeln('\n## ${t(r.topic.title)}');
          final s = k.where((x) => x.topicId == r.topic.id).firstOrNull;
          if (s == null) {
            b.writeln('${bn ? 'শিখনফল' : 'Outcome'}: ${t(r.topic.outcomes.first.text)}');
            continue;
          }
          b.writeln(t(s.definition));
          if (s.formula != null) b.writeln('\n\$\$${s.formula}\$\$');
          b.writeln('\n**${bn ? 'উদাহরণ' : 'Example'}:** ${t(s.example)}');
          b.writeln('\n> ${t(s.analogy)}');
          b.writeln('\n**${bn ? 'সাধারণ ভুল' : 'Common mistake'}:** ${t(s.mistake)}');
        }
    }
    return (title: '$scopeTitle — ${t(type.label)}', body: b.toString().trim());
  }

  ({String title, String body}) fromQuestion(Question q, AppLanguage lang) {
    final bn = lang == AppLanguage.bn;
    final b = StringBuffer('${_label(lang)}\n\n')
      ..writeln('## ${bn ? 'প্রশ্ন' : 'Question'}')
      ..writeln(q.stem.of(lang));
    if (q.stimulus != null) b.writeln('\n> ${q.stimulus!.of(lang)}');
    b
      ..writeln('\n## ${bn ? 'উত্তর' : 'Answer'}')
      ..writeln(q.answer.of(lang));
    if (q.steps.isNotEmpty) {
      b.writeln('\n## ${bn ? 'ধাপ' : 'Steps'}');
      for (final s in q.steps) {
        b.writeln('1. ${s.of(lang)}');
      }
    }
    if (q.explanation != null) b.writeln('\n**${bn ? 'ব্যাখ্যা' : 'Explanation'}:** ${q.explanation!.of(lang)}');
    final stem = q.stem.of(lang).replaceAll(RegExp(r'[\$\\{}]'), '');
    return (title: stem.length > 50 ? '${stem.substring(0, 50)}…' : stem, body: b.toString().trim());
  }

  ({String title, String body}) fromConversation(Conversation c, AppLanguage lang) {
    final bn = lang == AppLanguage.bn;
    final b = StringBuffer('${_label(lang)}\n\n');
    for (final m in c.messages) {
      if (m.isUser) {
        b.writeln('## ❓ ${m.text}');
      } else if (m.status == MessageStatus.done) {
        b.writeln(m.text.replaceAll(RegExp(r'^### ', multiLine: true), '#### '));
        if (m.sources.isNotEmpty) {
          b.writeln('\n_${bn ? 'উৎস' : 'Source'}: ${m.sources.first.bookTitle.of(lang)}, ${bn ? 'পৃষ্ঠা' : 'p.'} ${m.sources.first.page}_\n');
        }
      }
    }
    return (title: c.title.isEmpty ? (bn ? 'AI কথোপকথনের নোট' : 'Notes from AI chat') : c.title, body: b.toString().trim());
  }

  /// Simulated OCR/summary of an uploaded file: we never read real content in the demo.
  ({String title, String body}) fromUpload(String fileName, int bytes, AppLanguage lang) {
    final bn = lang == AppLanguage.bn;
    return (
      title: fileName,
      body: '${_label(lang)}\n\n## ${bn ? 'আপলোড করা ফাইল' : 'Uploaded file'}: $fileName\n'
          '- ${bn ? 'আকার' : 'Size'}: ${(bytes / 1024).toStringAsFixed(1)} KB\n'
          '- ${bn ? 'লেখা শনাক্তকরণ (OCR) সিমুলেটেড — আসল বিষয়বস্তু পড়া হয়নি।' : 'Text recognition (OCR) is simulated — the real content was not read.'}\n\n'
          '## ${bn ? 'তোমার সারাংশ লেখো' : 'Write your summary'}\n- \n- \n',
    );
  }
}
