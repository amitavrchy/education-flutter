import '../../../core/l10n/tr.dart';
import '../../../core/utils/bangla_number.dart';
import '../../../mock/seed/tutor_knowledge_seed.dart';
import '../domain/avatar_models.dart';
import 'book_catalog.dart';

/// Simulated "answer only from this book" engine (port of the web `book-avatar-engine.ts`).
/// The real service retrieves from the book's indexed chunks; this mock searches the
/// sample book's passages and pages and never invents content from outside the book.
class BookAvatarEngine {
  const BookAvatarEngine();

  static final _bangla = RegExp(r'[\u0980-\u09FF]');
  static final _latin = RegExp(r'[a-zA-Z]');
  static final _greeting = RegExp(r'(^|\s)(হ্যালো|হাই|আসসালামু|সালাম|নমস্কার|hello|hi|hey|salam)(\s|[!?।,.]|$)', caseSensitive: false);
  static final _whoAreYou = RegExp(r'(তুমি কে|আপনি কে|তোমার নাম|আপনার নাম|who are you|your name)', caseSensitive: false);
  static final _contents = RegExp(r'(কী কী অধ্যায়|কোন কোন অধ্যায়|অধ্যায়গুলো|সূচিপত্র|সূচি|what chapters|which chapters|table of contents|contents)', caseSensitive: false);
  static const _stop = {
    'কী', 'কি', 'কাকে', 'বলে', 'কর', 'করো', 'বলো', 'দাও', 'বুঝিয়ে', 'এর', 'ও', 'এবং', 'একটি', 'কেন', 'কীভাবে', 'হয়', 'আমাকে',
    'what', 'is', 'the', 'a', 'an', 'of', 'and', 'to', 'in', 'how', 'why', 'explain', 'define', 'me', 'please', 'does', 'do', 'are',
  };

  static bool isBangla(String s) => _bangla.hasMatch(s);

  static List<String> tokens(String s) => s
      .toLowerCase()
      .split(RegExp(r'[\s,.;:!?।()\[\]{}"/\\-]+'))
      .where((t) => t.length >= 2 && !_stop.contains(t))
      .toList();

  /// Speakable text: strips Markdown, links and LaTeX.
  static String toSpoken(String md, String lang) {
    String tex(String t) => t
        .replaceAllMapped(RegExp(r'\\(?:text|mathrm)\{([^}]*)\}'), (m) => m[1]!)
        .replaceAllMapped(RegExp(r'\\t?frac\{([^}]*)\}\{([^}]*)\}'), (m) => '${m[1]} / ${m[2]}')
        .replaceAll(r'\times', lang == 'bn' ? ' গুণ ' : ' times ')
        .replaceAll(RegExp(r'\\[a-zA-Z]+'), ' ')
        .replaceAll(RegExp(r'[{}^_]'), ' ');
    return md
        .replaceAllMapped(RegExp(r'\$\$([^$]+)\$\$'), (m) => ' ${lang == 'bn' ? 'সূত্র' : 'formula'}: ${tex(m[1]!)}. ')
        .replaceAllMapped(RegExp(r'\$([^$]+)\$'), (m) => tex(m[1]!))
        .replaceAllMapped(RegExp(r'\[([^\]]+)\]\([^)]*\)'), (m) => m[1]!)
        .replaceAll(RegExp(r'[*_#>`|=]'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  AvatarAnswer answer({required Book book, required BookAvatar avatar, required String query}) {
    final q = query.trim();
    final lang = isBangla(q) ? 'bn' : (_latin.hasMatch(q) ? 'en' : avatar.voice.language);
    String t(Tr tr) => tr.of(lang == 'en' ? AppLanguage.en : AppLanguage.bn);
    String n(int v) => lang == 'bn' ? toBanglaDigits(v) : '$v';
    final chapters = [
      for (final c in book.chapters)
        if (avatar.scopeChapterIds.isEmpty || avatar.scopeChapterIds.contains(c.id)) c,
    ];
    final inScope = {for (final c in chapters) c.id};
    final bookTitle = t(book.title);
    final name = t(avatar.name);

    AvatarAnswer done(String text, {List<AvatarCitation> citations = const [], Grounding grounded = Grounding.book, List<String> followUps = const []}) =>
        AvatarAnswer(text: text, spoken: toSpoken(text, lang), citations: citations, grounded: grounded, followUps: followUps);

    List<String> topicSuggestions([int count = 3]) => [
      for (final c in chapters)
        for (final tp in c.topics) lang == 'bn' ? '${tp.title.bn} কী?' : 'What is ${tp.title.en}?',
    ].take(count).toList();

    // 1. Greeting / who are you.
    if (_whoAreYou.hasMatch(q) || (_greeting.hasMatch(q) && tokens(q).length <= 3)) {
      return done(
        lang == 'bn'
            ? 'আমি $name, "$bookTitle" বইয়ের শিক্ষক। এই বইয়ের যেকোনো অধ্যায় থেকে প্রশ্ন করো — আমি বইয়ের পৃষ্ঠা দেখিয়ে বুঝিয়ে দেব।'
            : "I'm $name, the teacher for \"$bookTitle\". Ask me anything from this book and I'll explain it with the page numbers.",
        grounded: Grounding.greeting,
        followUps: topicSuggestions(),
      );
    }

    // 2. Table of contents.
    if (_contents.hasMatch(q)) {
      final lines = [for (final c in chapters) '- ${lang == 'bn' ? 'অধ্যায়' : 'Chapter'} ${n(c.number)}: ${t(c.title)}'];
      return done(
        '${lang == 'bn' ? 'এই বইয়ে যে অধ্যায়গুলো থেকে আমি উত্তর দিই:' : 'Chapters I can answer from in this book:'}\n${lines.join('\n')}',
        citations: [
          for (final p in book.pages.where((p) => inScope.contains(p.chapterId) && p.heading.bn == p.chapterTitle.bn).take(3))
            AvatarCitation(page: p.page, chapterTitle: t(p.chapterTitle), excerpt: t(p.body)),
        ],
        followUps: topicSuggestions(),
      );
    }

    // 3. A detailed passage printed in the book (definition, formula, example).
    final lower = q.toLowerCase();
    // Whole words for short keywords ("বল" must not match "বলে"); substrings for longer
    // ones so inflected forms still match ("ত্বরণের").
    final words = ' ${lower.split(RegExp(r'[\s,.;:!?।()\[\]{}"/\\-]+')).join(' ')} ';
    bool hasKeyword(String k) {
      final key = k.toLowerCase();
      return key.length >= 4 ? lower.contains(key) : words.contains(' $key ');
    }

    TutorScenario? best;
    var bestScore = 0;
    for (final s in book.scenarios) {
      if (!inScope.contains(s.chapterId)) continue;
      final score = s.keywords.where(hasKeyword).length;
      if (score > bestScore) {
        best = s;
        bestScore = score;
      }
    }
    if (best != null) {
      final s = best;
      final chapter = book.chapter(s.chapterId);
      final p = avatar.persona;
      final parts = <String>[];
      final opener = switch (p.style) {
        PersonaStyle.friendly => lang == 'bn' ? 'চলো সহজ করে বুঝি।' : "Let's make this simple.",
        PersonaStyle.formal => lang == 'bn' ? 'বইয়ে যেভাবে আছে:' : 'As the book puts it:',
        PersonaStyle.socratic => lang == 'bn' ? 'আগে একটু ভাবো — তারপর মিলিয়ে নাও।' : 'Think about it first — then check.',
      };
      parts.add('**${t(s.title)}**: ${t(s.definition)}');
      if (p.answerLength != AnswerLength.short) {
        parts.add(t(s.excerpt));
        if (s.formula != null) parts.add('\$\$${s.formula}\$\$');
      }
      if (p.answerLength == AnswerLength.detailed) {
        parts.addAll([for (final k in s.keyPoints) '- ${t(k)}']);
        parts.add('> ${t(s.mistake)}');
      }
      if (p.useExamples && p.answerLength != AnswerLength.short) parts.add('${lang == 'bn' ? 'উদাহরণ' : 'Example'}: ${t(s.example)}');
      if (p.style == PersonaStyle.socratic) parts.add('${lang == 'bn' ? 'তোমার জন্য প্রশ্ন' : 'Your turn'}: ${t(s.oralQ)}');
      parts.add('📖 ${lang == 'bn' ? 'সূত্র' : 'Source'}: "$bookTitle", ${lang == 'bn' ? 'পৃষ্ঠা' : 'page'} ${n(s.page)}');
      return done(
        '$opener\n\n${parts.join('\n\n')}',
        citations: [
          AvatarCitation(page: s.page, chapterTitle: chapter == null ? '' : t(chapter.title), heading: t(s.title), excerpt: t(s.excerpt)),
        ],
        followUps: [for (final f in s.followUps) t(f)],
      );
    }

    // 4. Search the book's pages.
    final qt = tokens(q);
    BookPage? hit;
    var hitScore = 0;
    for (final page in book.pages) {
      if (!inScope.contains(page.chapterId)) continue;
      final heading = t(page.heading).toLowerCase();
      final chapter = t(page.chapterTitle).toLowerCase();
      final body = t(page.body).toLowerCase();
      var score = 0;
      for (final token in qt) {
        if (heading.contains(token)) score += 4;
        if (chapter.contains(token)) score += 2;
        if (body.contains(token)) score += 1;
      }
      if (score > hitScore) {
        hit = page;
        hitScore = score;
      }
    }
    if (hit != null && hitScore >= 3) {
      final page = hit;
      return done(
        '**${t(page.heading)}** (${t(page.chapterTitle)})\n\n${t(page.body)}\n\n📖 ${lang == 'bn' ? 'সূত্র' : 'Source'}: "$bookTitle", ${lang == 'bn' ? 'পৃষ্ঠা' : 'page'} ${n(page.page)}',
        citations: [AvatarCitation(page: page.page, chapterTitle: t(page.chapterTitle), heading: t(page.heading), excerpt: t(page.body))],
        followUps: topicSuggestions(),
      );
    }

    // 5. Not in this book.
    final suggestions = topicSuggestions();
    final list = suggestions.map((s) => '- $s').join('\n');
    return done(
      lang == 'bn'
          ? 'দুঃখিত, এই প্রশ্নের উত্তর "$bookTitle" বইয়ে খুঁজে পাইনি। আমি শুধু এই বইয়ের বিষয়বস্তু থেকে উত্তর দিই${avatar.strictBookScope ? '' : ' (অন্য বিষয়ের জন্য AI টিউটর ব্যবহার করো)'}। বইয়ের কোনো টপিক নিয়ে প্রশ্ন করো — যেমন:\n$list'
          : "Sorry, I couldn't find that in \"$bookTitle\". I only answer from this book${avatar.strictBookScope ? '' : ' (use the AI tutor for other topics)'}. Try a topic from the book, for example:\n$list",
      grounded: Grounding.outOfScope,
      followUps: suggestions,
    );
  }
}
