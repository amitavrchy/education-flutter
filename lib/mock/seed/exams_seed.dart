import '../../core/l10n/tr.dart';
import '../../features/exams/application/exam_scoring.dart';
import '../../features/exams/domain/exam.dart';
import '../../features/question_bank/domain/question.dart';
import 'questions_seed.dart';

/// Exams available to the demo student, timed relative to first launch.
List<ExamTemplate> seedExamTemplates([DateTime? now]) {
  final t = now ?? DateTime.now();
  return [
    ExamTemplate(
      id: 'tpl-phy-model-1',
      type: ExamType.modelTest,
      title: const Tr('পদার্থবিজ্ঞান মডেল টেস্ট ১ (গতি ও বল)', 'Physics model test 1 (Motion & Force)'),
      description: const Tr('১০টি প্রশ্ন · ১৫ মিনিট · ভুলে ০.২৫ কাটা', '10 questions · 15 min · −0.25 per wrong answer'),
      config: const ExamConfig(subjectId: 'ssc-phy', chapterIds: ['ssc-phy-p1-c2', 'ssc-phy-p1-c3'], questionCount: 10, timeLimitMinutes: 15, negativeMarking: true),
      createdAt: t.subtract(const Duration(days: 3)),
    ),
    ExamTemplate(
      id: 'tpl-chem-model-1',
      type: ExamType.modelTest,
      title: const Tr('রসায়ন মডেল টেস্ট (অধ্যায় ৩–৭)', 'Chemistry model test (chapters 3–7)'),
      description: const Tr('MCQ ও সংক্ষিপ্ত প্রশ্ন · ২০ মিনিট', 'MCQ and short questions · 20 min'),
      config: const ExamConfig(subjectId: 'ssc-chem', questionCount: 8, timeLimitMinutes: 20),
      createdAt: t.subtract(const Duration(hours: 3)),
    ),
    ExamTemplate(
      id: 'tpl-daily',
      type: ExamType.dailyChallenge,
      title: const Tr('আজকের চ্যালেঞ্জ', 'Today’s challenge'),
      description: const Tr('৫টি প্রশ্ন · ৫ মিনিট · সব বিষয়', '5 questions · 5 min · all subjects'),
      config: const ExamConfig(types: {QuestionType.mcq}, questionCount: 5, timeLimitMinutes: 5),
      createdAt: t,
    ),
    ExamTemplate(
      id: 'tpl-teacher-gmath',
      type: ExamType.teacherAssigned,
      title: const Tr('গণিত: বীজগাণিতিক রাশি ও সমীকরণ', 'Maths: algebraic expressions & equations'),
      assignedBy: const Tr('নাসরিন সুলতানা (গণিত শিক্ষক)', 'Nasrin Sultana (maths teacher)'),
      description: const Tr('শিক্ষক নির্ধারিত · ৩ দিনের মধ্যে জমা দাও', 'Assigned by your teacher · due in 3 days'),
      config: const ExamConfig(subjectId: 'ssc-gmath', chapterIds: ['ssc-gmath-p1-c3', 'ssc-gmath-p1-c6'], questionCount: 4, timeLimitMinutes: 20, randomize: false),
      dueAt: t.add(const Duration(days: 3)),
      createdAt: t.subtract(const Duration(days: 1)),
    ),
    ExamTemplate(
      id: 'tpl-inst-bio',
      type: ExamType.institution,
      title: const Tr('অর্ধবার্ষিক প্রস্তুতি: জীববিজ্ঞান', 'Half-yearly prep: Biology'),
      assignedBy: const Tr('ঢাকা আইডিয়াল স্কুল (নমুনা প্রতিষ্ঠান)', 'Dhaka Ideal School (sample institution)'),
      description: const Tr('প্রতিষ্ঠানের নির্ধারিত সময়ে খুলবে', 'Opens at the time set by your institution'),
      config: const ExamConfig(subjectId: 'ssc-bio', questionCount: 5, timeLimitMinutes: 25, reviewPolicy: ReviewPolicy.afterSubmit),
      scheduledAt: t.subtract(const Duration(hours: 1)),
      createdAt: t.subtract(const Duration(days: 5)),
    ),
    ExamTemplate(
      id: 'tpl-board-sample',
      type: ExamType.boardPrevious,
      title: const Tr('বোর্ড-ধাঁচের নমুনা প্রশ্নপত্র (কৃত্রিম)', 'Board-style sample paper (synthetic)'),
      description: const Tr(
        'বাস্তব বোর্ড প্রশ্ন নয় — বোর্ডের ধাঁচে লেখা নমুনা প্রশ্ন দিয়ে সময় ধরে অনুশীলন।',
        'Not real board questions — timed practice with original questions written in board style.',
      ),
      config: const ExamConfig(questionCount: 8, timeLimitMinutes: 10),
      questionIds: [for (final q in seedQuestions()) if (q.source == QuestionSource.board) q.id],
      createdAt: t.subtract(const Duration(days: 7)),
    ),
    ExamTemplate(
      id: 'tpl-full-sci',
      type: ExamType.fullSyllabus,
      title: const Tr('পূর্ণ সিলেবাস: বিজ্ঞান বিভাগ', 'Full syllabus: Science group'),
      description: const Tr('২০টি প্রশ্ন · ৩০ মিনিট · ভুলে নম্বর কাটা', '20 questions · 30 min · negative marking'),
      config: const ExamConfig(questionCount: 20, timeLimitMinutes: 30, negativeMarking: true),
      createdAt: t.subtract(const Duration(days: 10)),
    ),
    ExamTemplate(
      id: 'tpl-oral-eng',
      type: ExamType.oral,
      title: const Tr('মৌখিক অনুশীলন: ইংরেজি ব্যাকরণ', 'Oral practice: English grammar'),
      description: const Tr('জোরে উত্তর বলো, তারপর লিখে মিলিয়ে নাও', 'Say the answer aloud, then write it to compare'),
      config: const ExamConfig(subjectId: 'ssc-eng2', types: {QuestionType.short, QuestionType.fillBlank}, questionCount: 4, timeLimitMinutes: 10, mode: ExamMode.practice, reviewPolicy: ReviewPolicy.immediate),
      createdAt: t.subtract(const Duration(days: 2)),
    ),
  ];
}

/// Three earlier, already-scored attempts so history and trends have data on first launch.
List<ExamAttempt> seedExamAttempts([DateTime? now]) {
  final t = now ?? DateTime.now();
  final all = {for (final q in seedQuestions()) q.id: q};
  ExamAttempt past(String id, String title, String titleEn, List<String> ids, int daysAgo, int rightEvery, {String? feedbackBn, String? feedbackEn}) {
    final answers = <String, ExamAnswer>{};
    for (var i = 0; i < ids.length; i++) {
      final q = all[ids[i]]!;
      if (q.correctIndex != null) {
        final right = i % rightEvery != 0;
        answers[q.id] = ExamAnswer(choice: right ? q.correctIndex : (q.correctIndex! + 1) % q.options.length);
      }
    }
    final started = t.subtract(Duration(days: daysAgo, hours: 2));
    final attempt = ExamAttempt(
      id: id,
      type: ExamType.chapter,
      title: Tr(title, titleEn),
      config: ExamConfig(questionCount: ids.length, timeLimitMinutes: 10),
      questionIds: ids,
      startedAt: started,
      answers: answers,
      status: AttemptStatus.submitted,
      submittedAt: started.add(const Duration(minutes: 9)),
    );
    final r = scoreAttempt(attempt, all, timeSpentSeconds: 9 * 60);
    return attempt.copyWith(
      result: ExamResult(
        scores: r.scores,
        timeSpentSeconds: r.timeSpentSeconds,
        teacherFeedback: feedbackBn == null ? null : Tr(feedbackBn, feedbackEn!),
      ),
    );
  }

  return [
    past('att-seed-1', 'পদার্থবিজ্ঞান: গতি', 'Physics: Motion', ['q-phy-m1', 'q-phy-m2', 'q-phy-m3', 'q-phy-f1', 'q-phy-f2'], 12, 3),
    past('att-seed-2', 'রসায়ন: পরমাণু ও বন্ধন', 'Chemistry: atoms & bonds', ['q-chem-a1', 'q-chem-a2', 'q-chem-b1', 'q-chem-r1', 'q-chem-p1'], 7, 4,
        feedbackBn: 'বন্ধনের ধারণা ভালো। জারণ-বিজারণে আরেকটু অনুশীলন দরকার।', feedbackEn: 'Good grasp of bonding. Practise oxidation and reduction a bit more.'),
    past('att-seed-3', 'মিশ্র: গণিত ও জীববিজ্ঞান', 'Mixed: maths & biology', ['q-gm-a1', 'q-gm-t1', 'q-hm-s1', 'q-bio-c1', 'q-bio-c2', 'q-bio-d1'], 3, 5),
  ];
}
