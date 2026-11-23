import 'dart:math';

import '../../../core/l10n/tr.dart';
import '../../../mock/seed/tutor_knowledge_seed.dart';
import '../../curriculum/data/curriculum_repository.dart';
import '../../question_bank/domain/question.dart';
import '../domain/tutor_models.dart';

/// Deterministic, scenario-based stand-in for the AI tutor + RAG service.
///
/// Retrieval scores seeded sample-textbook passages by keyword overlap and by how well they
/// match the active academic context; the answer is then shaped by the teaching mode.
/// Everything here is pure (no I/O), so it is unit-tested directly.
class MockTutorEngine {
  MockTutorEngine({required this.curriculum, required this.questions, this.scenarios = tutorScenarios});

  final CurriculumRepository curriculum;
  final List<Question> Function() questions;
  final List<TutorScenario> scenarios;

  static const _integrityWords = ['leak', 'ফাঁস', 'cheat', 'নকল', 'answer key', 'প্রশ্নপত্র আগে', 'copy in exam', 'পরীক্ষায় দেখে'];
  static const _offTopicWords = ['movie', 'সিনেমা', 'game', 'গেম', 'girlfriend', 'প্রেম', 'hack', 'হ্যাক', 'betting', 'জুয়া'];

  /// Scores every passage for [query] in [context]; best first, only relevant ones.
  List<(TutorScenario, double)> retrieve(String query, TutorContext context) {
    final q = query.toLowerCase();
    final out = <(TutorScenario, double)>[];
    for (final s in scenarios) {
      var score = 0.0;
      // Explicit keywords outweigh context; context alone is enough for generic questions.
      for (final k in s.keywords) {
        if (q.contains(k.toLowerCase())) score += 0.45;
      }
      score = min(score, 0.9);
      if (context.topicId != null && s.topicId == context.topicId) {
        score += 0.3;
      } else if (context.chapterId != null && s.chapterId == context.chapterId) {
        score += 0.2;
      } else if (context.subjectId != null && s.subjectId == context.subjectId) {
        score += 0.1;
      } else if (context.subjectId != null && score > 0) {
        score -= 0.05;
      }
      if (score >= 0.3) out.add((s, min(score, 1.0)));
    }
    out.sort((a, b) => b.$2.compareTo(a.$2));
    return out;
  }

  TutorReply answer({required String query, required TutorContext context, List<ChatMessage> history = const [], int variant = 0}) {
    final lang = context.language == TutorLanguage.en ? AppLanguage.en : AppLanguage.bn;
    final mixed = context.language == TutorLanguage.mixed;
    String t(Tr tr) => tr.of(lang);
    final lower = query.toLowerCase();

    if (_integrityWords.any(lower.contains)) {
      return TutorReply(
        text: t(const Tr(
          '### একাডেমিক সততা\nআমি পরীক্ষার প্রশ্ন ফাঁস বা নকলে সাহায্য করতে পারি না। তবে চলো একসাথে প্রস্তুতি নিই — কোন অধ্যায় তোমার কঠিন লাগছে? আমি সম্ভাব্য গুরুত্বপূর্ণ প্রশ্নের ধরন ও অনুশীলন সেট বানিয়ে দিতে পারি।',
          '### Academic integrity\nI can’t help with leaked papers or cheating. But let’s prepare properly together — which chapter feels hard? I can build practice sets around the question styles that matter.',
        )),
        grounding: Grounding.general,
        confidence: 1,
        warnings: const [AnswerWarning.integrity],
        followUps: [t(const Tr('গুরুত্বপূর্ণ অধ্যায়ের তালিকা দাও', 'List the important chapters')), t(const Tr('একটি মডেল টেস্ট দাও', 'Give me a model test'))],
      );
    }
    if (_offTopicWords.any(lower.contains)) {
      return TutorReply(
        text: t(const Tr(
          'আমি তোমার পড়াশোনার সহায়ক, তাই এই বিষয়ে সাহায্য করতে পারছি না। 🙂 পাঠ্য বিষয়ের যেকোনো প্রশ্ন করো — গণিত, বিজ্ঞান, ভাষা বা ব্যবসায় শিক্ষা।',
          'I’m your study assistant, so I can’t help with that. 🙂 Ask me anything from your syllabus — maths, science, languages or business studies.',
        )),
        grounding: Grounding.general,
        confidence: 1,
        warnings: const [AnswerWarning.offTopic],
      );
    }

    // Oral exam: grade the student's reply to the previous viva question.
    final lastAssistant = history.lastWhere((m) => m.role == ChatRole.assistant && m.status == MessageStatus.done, orElse: () => _none);
    if (context.mode == TeachingMode.oralExam && lastAssistant.mode == TeachingMode.oralExam && lastAssistant.sources.isNotEmpty) {
      final s = scenarios.where((x) => x.id == lastAssistant.sources.first.id).firstOrNull;
      if (s != null) return _gradeOral(s, query, lang, context);
    }

    if (context.mode == TeachingMode.englishCoach) return _englishCoach(query, lang);

    final hits = retrieve(query, context);
    if (hits.isEmpty) return _general(query, context, lang);

    final (best, score) = hits.first;
    final sources = [for (final (s, sc) in hits.take(2)) _sourceOf(s, sc)];
    final warnings = <AnswerWarning>[];
    final versionMismatch = best.curriculumVersionId != context.curriculumVersionId;
    if (versionMismatch || best.curriculumVersionId == 'nctb-2013') warnings.add(AnswerWarning.oldCurriculum);
    if (hits.length > 1 && hits[1].$1.curriculumVersionId != best.curriculumVersionId && hits[1].$1.subjectId == best.subjectId) {
      warnings.add(AnswerWarning.conflictingSources);
    }
    final confidence = min(0.95, 0.5 + score * 0.45) - (versionMismatch ? 0.1 : 0);
    if (confidence < 0.65) warnings.add(AnswerWarning.lowConfidence);
    final grounding = score >= 0.6 && !versionMismatch ? Grounding.verified : Grounding.partial;

    final related = _relatedQuestions(best);
    final text = _compose(best, context.mode, lang, variant, mixed: mixed);
    return TutorReply(
      text: text,
      grounding: grounding,
      confidence: confidence,
      sources: sources,
      warnings: warnings,
      relatedQuestionIds: related,
      followUps: [
        for (final f in best.followUps) t(f),
        t(variant.isEven
            ? const Tr('আরও সহজ করে বলো', 'Explain it more simply')
            : const Tr('আরও বিস্তারিত বলো', 'Go deeper')),
      ],
    );
  }

  static final _none = ChatMessage(id: '', role: ChatRole.assistant, text: '', createdAt: DateTime(2000));

  SourceRef _sourceOf(TutorScenario s, double score) {
    final ch = curriculum.findChapter(s.chapterId);
    final subject = ch?.subject.name ?? const Tr('পাঠ্যবই', 'Textbook');
    return SourceRef(
      id: s.id,
      bookId: s.bookId,
      bookTitle: Tr('${subject.bn} (নমুনা পাঠ্যবই)', '${subject.en} (sample textbook)'),
      chapterTitle: ch?.chapter.title ?? s.title,
      page: s.page,
      excerpt: s.excerpt,
      curriculumVersionId: s.curriculumVersionId,
      score: score,
    );
  }

  List<String> _relatedQuestions(TutorScenario s) {
    final all = questions();
    final sameTopic = all.where((q) => q.topicId == s.topicId).map((q) => q.id);
    final sameChapter = all.where((q) => q.chapterId == s.chapterId && q.topicId != s.topicId).map((q) => q.id);
    return [...sameTopic, ...sameChapter].take(3).toList();
  }

  String _compose(TutorScenario s, TeachingMode mode, AppLanguage lang, int variant, {bool mixed = false}) {
    String t(Tr tr) => tr.of(lang);
    final bn = lang == AppLanguage.bn;
    final title = mixed ? '${s.title.bn} (${s.title.en})' : t(s.title);
    final formula = s.formula == null ? '' : '\$\$${s.formula}\$\$\n';
    final symbols = s.symbols.isEmpty
        ? ''
        : '${[for (final (sym, meaning) in s.symbols) '- \$$sym\$ = ${t(meaning)}'].join('\n')}\n';
    final points = [for (final p in s.keyPoints) '- ${t(p)}'].join('\n');
    final openers = bn
        ? ['চলো সহজ করে দেখি।', 'খুব ভালো প্রশ্ন!', 'এটা বুঝলে অনেক অঙ্ক সহজ হয়ে যাবে।']
        : ['Let’s make this simple.', 'Great question!', 'Once this clicks, lots of problems get easier.'];
    final opener = openers[variant % openers.length];
    final b = StringBuffer();

    switch (mode) {
      case TeachingMode.simple:
        b.writeln('### $title');
        b.writeln(opener);
        b.writeln();
        if (variant.isOdd) b.writeln('> ${t(s.analogy)}\n');
        b.writeln(t(s.definition));
        if (formula.isNotEmpty) b.write('\n$formula');
        b.writeln('\n**${bn ? 'উদাহরণ' : 'Example'}:** ${t(s.example)}');
        if (variant.isEven) b.writeln('\n> ${t(s.analogy)}');
      case TeachingMode.socratic:
        b.writeln('### $title — ${bn ? 'চলো ভেবে দেখি' : 'let’s think it through'}');
        b.writeln(bn ? 'আমি সরাসরি উত্তর বলব না — প্রশ্নের মাধ্যমে তুমি নিজেই পৌঁছাবে।' : 'I won’t just tell you — you’ll get there through questions.');
        b.writeln();
        b.writeln('1. ${bn ? 'নিচের লাইনটি পড়ো এবং মূল শব্দটি চিহ্নিত করো' : 'Read this line and spot the key idea'}: *${t(s.definition)}*');
        b.writeln('2. ${t(s.analogy)} — ${bn ? 'এখানে কী বদলাচ্ছে?' : 'what is changing here?'}');
        b.writeln('3. ${bn ? 'এবার তুমি বলো' : 'Now you tell me'}: **${t(s.oralQ)}**');
        b.writeln('\n${bn ? '💡 ইঙ্গিত লাগলে “ইঙ্গিত দাও” লেখো।' : '💡 Type “hint” if you need a nudge.'}');
      case TeachingMode.boardAnswer:
        b.writeln('### ${bn ? 'বোর্ড পরীক্ষার উপযোগী উত্তর' : 'Board-exam style answer'}: $title');
        b.writeln('**${bn ? 'ক) জ্ঞানমূলক' : 'a) Knowledge'}:** ${t(s.definition)}');
        b.writeln();
        b.writeln('**${bn ? 'খ) অনুধাবনমূলক' : 'b) Comprehension'}:** ${t(s.keyPoints.first)} ${t(s.analogy)}');
        b.writeln();
        b.writeln('**${bn ? 'গ) প্রয়োগমূলক' : 'c) Application'}:** ${t(s.example)}');
        b.writeln();
        b.writeln('**${bn ? 'ঘ) উচ্চতর দক্ষতা' : 'd) Higher-order'}:** ${t(s.mistake)} ${bn ? 'তাই সঠিক নিয়ম প্রয়োগ করে সিদ্ধান্তে পৌঁছাতে হবে।' : 'So apply the correct rule to reach the conclusion.'}');
        b.writeln('\n> ${bn ? 'খাতায় মূল শব্দ আন্ডারলাইন করো এবং একক লিখতে ভুলো না।' : 'Underline key terms in your script and always write units.'}');
      case TeachingMode.quickRevision:
        b.writeln('### ⚡ $title');
        b.writeln(points);
        if (formula.isNotEmpty) b.write('\n$formula');
        b.writeln('\n**${bn ? 'সাবধান' : 'Watch out'}:** ${t(s.mistake)}');
      case TeachingMode.stepByStep:
        b.writeln('### ${bn ? 'ধাপে ধাপে' : 'Step by step'}: $title');
        b.writeln('1. ${bn ? 'ধারণা' : 'Idea'}: ${t(s.definition)}');
        if (s.formula != null) b.writeln('2. ${bn ? 'সূত্র লেখো' : 'Write the formula'}: \$${s.formula}\$');
        b.writeln('${s.formula != null ? 3 : 2}. ${bn ? 'মান বসাও ও হিসাব করো' : 'Substitute and calculate'}: ${t(s.example)}');
        b.writeln('${s.formula != null ? 4 : 3}. ${bn ? 'যাচাই করো' : 'Check'}: ${t(s.mistake)}');
        b.writeln('\n**${bn ? 'এবার নিজে করো' : 'Your turn'}:** ${t(s.practiceQ)}');
      case TeachingMode.deepConcept:
        b.writeln('### $title — ${bn ? 'গভীরে' : 'in depth'}');
        b.writeln('**${bn ? 'পাঠ্যবই যা বলে' : 'What the book says'}:** ${t(s.excerpt)}');
        b.writeln();
        b.writeln('**${bn ? 'কেন এমন হয়' : 'Why it works'}:** ${t(s.definition)} ${t(s.analogy)}');
        if (formula.isNotEmpty) b.write('\n$formula$symbols');
        b.writeln('\n**${bn ? 'মূল বিষয়' : 'Key ideas'}:**\n$points');
        b.writeln('\n**${bn ? 'অন্য অধ্যায়ের সাথে সংযোগ' : 'Connections'}:** ${[for (final f in s.followUps.take(2)) t(f)].join(' · ')}');
      case TeachingMode.practice:
        b.writeln('### 📝 ${bn ? 'অনুশীলন প্রশ্ন' : 'Practice question'}: $title');
        b.writeln(t(s.practiceQ));
        b.writeln('\n> ${bn ? 'উত্তর লিখে পাঠাও, আমি মিলিয়ে দেখব। উত্তর দেখতে চাইলে নিচে দেখো।' : 'Send me your answer and I’ll check it. Peek below only if stuck.'}');
        b.writeln('\n**${bn ? 'উত্তর' : 'Answer'}:** ==${t(s.practiceA)}==');
      case TeachingMode.oralExam:
        b.writeln('### 🎤 ${bn ? 'মৌখিক পরীক্ষা' : 'Oral exam'}: $title');
        b.writeln(bn ? 'আমি পরীক্ষক — উত্তর ছোট ও স্পষ্ট বলো (বা লেখো)।' : 'I’m the examiner — answer briefly and clearly (speak or type).');
        b.writeln('\n**${bn ? 'প্রশ্ন' : 'Question'}:** ${t(s.oralQ)}');
      case TeachingMode.formula:
        b.writeln('### ${bn ? 'সূত্র' : 'Formula'}: $title');
        if (formula.isNotEmpty) {
          b.write(formula);
          b.write(symbols);
        } else {
          b.writeln(bn ? 'এই টপিকে নির্দিষ্ট সূত্র নেই; মূল নিয়মগুলো:' : 'There is no single formula here; the key rules are:');
          b.writeln(points);
        }
        b.writeln('\n**${bn ? 'কখন ব্যবহার করবে' : 'When to use it'}:** ${t(s.keyPoints.first)}');
        b.writeln('\n**${bn ? 'উদাহরণ' : 'Example'}:** ${t(s.example)}');
      case TeachingMode.englishCoach:
        b.writeln(t(s.definition));
    }
    return b.toString().trim();
  }

  TutorReply _gradeOral(TutorScenario s, String reply, AppLanguage lang, TutorContext context) {
    final bn = lang == AppLanguage.bn;
    final words = RegExp(r'[\p{L}\p{N}]{2,}', unicode: true);
    final key = {for (final m in words.allMatches('${s.practiceA.bn} ${s.practiceA.en} ${s.definition.bn} ${s.definition.en}'.toLowerCase())) m[0]!};
    final said = {for (final m in words.allMatches(reply.toLowerCase())) m[0]!};
    final hit = key.intersection(said).length;
    final score = min(5, (hit * 5 / max(4, key.length / 3)).round());
    final next = s.followUps.first.of(lang);
    final text = StringBuffer()
      ..writeln('### ${bn ? 'মূল্যায়ন' : 'Feedback'}: ${'★' * score}${'☆' * (5 - score)} (${bn ? 'সিমুলেটেড' : 'simulated'})')
      ..writeln(score >= 3
          ? (bn ? 'ভালো! মূল ধারণা ঠিক আছে।' : 'Good! You have the core idea.')
          : (bn ? 'কাছাকাছি, কিন্তু মূল শব্দগুলো আসেনি।' : 'Close, but the key terms are missing.'))
      ..writeln('\n**${bn ? 'আদর্শ উত্তর' : 'Model answer'}:** ${s.practiceA.of(lang)}')
      ..writeln('\n**${bn ? 'পরের প্রশ্ন' : 'Next question'}:** $next');
    return TutorReply(
      text: text.toString().trim(),
      grounding: Grounding.verified,
      confidence: 0.8,
      sources: [_sourceOf(s, 0.8)],
      followUps: [for (final f in s.followUps.skip(1)) f.of(lang)],
      warnings: context.curriculumVersionId != s.curriculumVersionId ? const [AnswerWarning.oldCurriculum] : const [],
    );
  }

  static final _englishRules = <(RegExp, String, Tr)>[
    (RegExp(r'\b(each|every|either|neither) of (\w+ )*?(\w+) have\b', caseSensitive: false), r'$1 of $2$3 has',
        const Tr('each/every/either/neither এর পরে singular verb (has)।', 'each/every/either/neither take a singular verb (has).')),
    (RegExp(r'\b(he|she|it) (go|do|have|play|read|write)\b', caseSensitive: false), r'$1 $2s',
        const Tr('Third person singular-এ present tense verb-এ s/es যোগ হয়।', 'Third-person singular present verbs take -s/-es.')),
    (RegExp(r'\bdid not (\w+?)ed\b', caseSensitive: false), r'did not $1',
        const Tr('did/did not এর পরে verb-এর base form বসে।', 'After did/did not, use the base form of the verb.')),
    (RegExp(r'\bmore better\b', caseSensitive: false), 'better',
        const Tr('“more better” দ্বিগুণ তুলনা — শুধু “better” লেখো।', '“more better” is a double comparative — use “better”.')),
    (RegExp(r'\bi\b'), 'I', const Tr('“I” সবসময় বড় হাতের।', '“I” is always capitalised.')),
    (RegExp(r'\bdiscuss about\b', caseSensitive: false), 'discuss',
        const Tr('“discuss” এর পরে “about” বসে না।', '“discuss” does not take “about”.')),
  ];

  TutorReply _englishCoach(String input, AppLanguage lang) {
    final bn = lang == AppLanguage.bn;
    var fixed = input.trim();
    final notes = <String>[];
    for (final (re, rep, why) in _englishRules) {
      if (re.hasMatch(fixed)) {
        fixed = fixed.replaceAllMapped(re, (m) {
          var out = rep;
          for (var i = 1; i <= m.groupCount; i++) {
            out = out.replaceAll('\$$i', m[i] ?? '');
          }
          return out;
        });
        notes.add(why.of(lang));
      }
    }
    if (fixed.isNotEmpty && fixed[0] != fixed[0].toUpperCase()) {
      fixed = fixed[0].toUpperCase() + fixed.substring(1);
      notes.add(bn ? 'বাক্যের শুরু বড় হাতের অক্ষরে।' : 'Start the sentence with a capital letter.');
    }
    if (fixed.isNotEmpty && !RegExp(r'[.!?]$').hasMatch(fixed)) {
      fixed = '$fixed.';
      notes.add(bn ? 'বাক্যের শেষে যতিচিহ্ন দাও।' : 'End the sentence with punctuation.');
    }
    final b = StringBuffer()..writeln('### ${bn ? 'ইংরেজি কোচ' : 'English coach'}');
    if (notes.isEmpty) {
      b
        ..writeln(bn ? '✅ বাক্যটি ব্যাকরণগতভাবে ঠিক আছে!' : '✅ That sentence is grammatically correct!')
        ..writeln('\n**${bn ? 'আরও সুন্দর করতে' : 'To sound richer'}:** ${bn ? 'একটি বিশেষণ বা linking word (however, moreover) যোগ করে দেখো।' : 'try adding an adjective or a linking word (however, moreover).'}');
    } else {
      b
        ..writeln('**${bn ? 'সংশোধিত' : 'Corrected'}:** $fixed')
        ..writeln('\n**${bn ? 'কেন' : 'Why'}:**')
        ..writeln([for (final n in notes) '- $n'].join('\n'));
    }
    b.writeln('\n${bn ? '🎙️ এবার বাক্যটি জোরে তিনবার বলো।' : '🎙️ Now say the sentence aloud three times.'}');
    return TutorReply(
      text: b.toString().trim(),
      grounding: Grounding.general,
      confidence: notes.isEmpty ? 0.75 : 0.85,
      followUps: [
        bn ? 'আরেকটি বাক্য যাচাই করো' : 'Check another sentence',
        bn ? 'Subject-verb agreement শেখাও' : 'Teach subject-verb agreement',
      ],
    );
  }

  TutorReply _general(String query, TutorContext context, AppLanguage lang) {
    final bn = lang == AppLanguage.bn;
    final topic = context.topicId == null ? null : curriculum.findTopic(context.topicId!);
    final chapter = context.chapterId == null ? null : curriculum.findChapter(context.chapterId!);
    final subjectKnown = context.subjectId != null && scenarios.any((s) => s.subjectId == context.subjectId);
    final b = StringBuffer();
    b.writeln('### ${bn ? 'সাধারণ ব্যাখ্যা' : 'General explanation'}');
    b.writeln(bn
        ? 'নমুনা জ্ঞানভাণ্ডারে এই প্রশ্নের জন্য যাচাইকৃত পাঠ্যবইয়ের অংশ পাইনি, তাই নিচের উত্তরটি সাধারণ পড়ার নির্দেশনা — বই বা শিক্ষকের সাথে মিলিয়ে নাও।'
        : 'I couldn’t find a verified textbook passage for this in the sample knowledge base, so here is general study guidance — check it against your book or teacher.');
    if (topic != null) {
      b.writeln('\n**${topic.topic.title.of(lang)}** — ${bn ? 'শিখনফল' : 'learning outcomes'}:');
      for (final o in topic.topic.outcomes) {
        b.writeln('- ${o.text.of(lang)}');
      }
    } else if (chapter != null) {
      b.writeln('\n**${chapter.chapter.title.of(lang)}** — ${chapter.chapter.description.of(lang)}');
    }
    b.writeln('\n${bn ? '**কীভাবে এগোবে:** মূল সংজ্ঞা লেখো → একটি উদাহরণ সমাধান করো → ৩টি MCQ অনুশীলন করো।' : '**How to proceed:** write the key definition → solve one example → practise 3 MCQs.'}');
    return TutorReply(
      text: b.toString().trim(),
      grounding: subjectKnown || context.subjectId == null ? Grounding.general : Grounding.unavailable,
      confidence: 0.4,
      warnings: [AnswerWarning.lowConfidence, if (!subjectKnown) AnswerWarning.missingKnowledge],
      followUps: [
        bn ? 'শিক্ষকের কাছে পাঠাও' : 'Send to a teacher',
        bn ? 'নিউটনের দ্বিতীয় সূত্র বুঝিয়ে দাও' : "Explain Newton's second law",
      ],
    );
  }
}
