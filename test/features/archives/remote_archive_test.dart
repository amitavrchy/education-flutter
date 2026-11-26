import 'package:flutter_test/flutter_test.dart';
import 'package:shikkhaai_mobile/features/archives/archive_data.dart';
import 'package:shikkhaai_mobile/features/archives/remote_archive.dart';
import 'package:shikkhaai_mobile/features/question_bank/data/question_repository.dart';
import 'package:shikkhaai_mobile/mock/seed/curriculum_seed.dart';

import '../../helpers/fake_server.dart';
import '../../helpers/test_app.dart';

void main() {
  tearDown(ArchiveCatalog.clear);

  test('API mode: papers come from the server; saving and reporting use bookmarks and content reports', () async {
    final probe = testContainer();
    final bank = probe.read(questionRepositoryProvider).cached;
    final phy = [
      for (final q in bank)
        if (q.subjectId == 'ssc-phy') q.id,
    ];
    final server = FakeServer({
      '/board-papers': [
        {
          'id': 'bp-ssc-phy-dhaka-2023-mcq',
          'boardId': 'brd-dhaka',
          'year': 2023,
          'subjectId': 'ssc-phy',
          'examType': 'mcq',
          'questionIds': phy.take(3).toList(),
        },
        {
          'id': 'bp-ssc-phy-dhaka-2023-creative',
          'boardId': 'brd-dhaka',
          'year': 2023,
          'subjectId': 'ssc-phy',
          'examType': 'creative',
          'questionIds': [phy[3], 'q-unknown'],
        },
      ],
      '/institution-papers': [
        {
          'id': 'ip-1',
          'institutionId': 'inst-9',
          'title': 'বার্ষিক পরীক্ষা',
          'academicYear': '2025',
          'subjectId': 'ssc-phy',
          'category': 'selection_test',
          'visibility': 'private',
          'uploadedBy': {'role': 'teacher'},
          'moderation': 'approved',
          'license': 'granted',
          'questionIds': phy.take(2).toList(),
        },
        {
          'id': 'ip-2',
          'institutionId': 'inst-9',
          'title': 'pending',
          'subjectId': 'ssc-phy',
          'moderation': 'pending',
          'license': 'granted',
          'questionIds': phy.take(2).toList(),
        },
      ],
      '/institutions': [
        {
          'id': 'inst-9',
          'name': {'bn': 'নমুনা কলেজ', 'en': 'Sample College'},
          'district': 'Khulna',
          'type': 'college',
        },
      ],
      '/bookmarks/u-student-1': [
        {'id': 'bm-1', 'kind': 'board_paper', 'refId': 'bp-ssc-phy-dhaka-2023-mcq'},
        {'id': 'bm-2', 'kind': 'question', 'refId': 'q-1'},
      ],
    });
    final c = testContainer(overrides: [remoteArchiveProvider.overrideWithValue(RemoteArchive(server.client, 'u-student-1'))]);
    c.read(archiveProvider);
    await c.read(archiveProvider.notifier).refresh();

    final board = boardPaper(bank, subject: subjectById('ssc-phy')!, boardId: 'dhaka', year: 2023)!;
    expect(board.questionIds, [...phy.take(4)]); // both papers, unknown ids dropped
    expect(boardPaper(bank, subject: subjectById('ssc-phy')!, boardId: 'dhaka', year: 2019), isNull);
    expect(c.read(archiveProvider).saved, ['bp-dhaka-2023-ssc-phy']);

    final inst = institutionPapers(bank);
    expect(inst.map((p) => p.id), ['ip-1']); // pending papers hidden
    expect(inst.single.institution!.district.bn, 'খুলনা');
    expect(inst.single.category, PaperCategory.selection);
    expect(paperIsPrivate(inst.single), isTrue);
    expect(paperTeacherUploaded(inst.single), isTrue);
    expect(archiveInstitutions.single.college, isTrue);

    await c.read(archiveProvider.notifier).toggleSaved(board.id, paper: board);
    expect(server.calls, contains('DELETE /bookmarks/u-student-1/bm-1'));
    await c.read(archiveProvider.notifier).toggleSaved(inst.single.id, paper: inst.single);
    final saved = server.lastBody['/bookmarks/u-student-1']! as Map;
    expect(saved['kind'], 'institution_paper');
    expect(saved['refId'], 'ip-1');
    await c.read(archiveProvider.notifier).report(board.id, 'ভুল উত্তর', paper: board);
    final report = server.lastBody['/content-reports']! as Map;
    expect(report['kind'], 'board_paper');
    expect(report['refId'], 'bp-ssc-phy-dhaka-2023-mcq');
  });
}
