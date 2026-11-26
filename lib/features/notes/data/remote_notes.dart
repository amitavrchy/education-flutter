import '../domain/note.dart';

/// Web notes keep Tiptap HTML; the app keeps Markdown. These converters cover what both
/// editors produce: headings, paragraphs, bullet lists, bold, italic and line breaks.
String htmlToMarkdown(String html) {
  var s = html
      .replaceAllMapped(RegExp(r'<h([1-3])[^>]*>', caseSensitive: false), (m) => '\n${'#' * int.parse(m[1]!)} ')
      .replaceAll(RegExp(r'</h[1-6]>', caseSensitive: false), '\n')
      .replaceAll(RegExp(r'<li[^>]*>', caseSensitive: false), '\n- ')
      .replaceAll(RegExp(r'</li>|</?ul[^>]*>|</?ol[^>]*>', caseSensitive: false), '')
      .replaceAll(RegExp(r'</?(strong|b)>', caseSensitive: false), '**')
      .replaceAll(RegExp(r'</?(em|i)>', caseSensitive: false), '*')
      .replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n')
      .replaceAll(RegExp(r'</p>', caseSensitive: false), '\n\n')
      .replaceAll(RegExp(r'<[^>]+>'), '')
      .replaceAll('&nbsp;', ' ')
      .replaceAll('&lt;', '<')
      .replaceAll('&gt;', '>')
      .replaceAll('&quot;', '"')
      .replaceAll('&#39;', "'")
      .replaceAll('&amp;', '&');
  s = s.replaceAll(RegExp(r'\n{3,}'), '\n\n');
  return s.trim();
}

String _escape(String s) => s.replaceAll('&', '&amp;').replaceAll('<', '&lt;').replaceAll('>', '&gt;');

String _inline(String s) =>
    _escape(s)
        .replaceAllMapped(RegExp(r'\*\*(.+?)\*\*'), (m) => '<strong>${m[1]}</strong>')
        .replaceAllMapped(RegExp(r'(?<!\*)\*(?!\*)(.+?)(?<!\*)\*(?!\*)'), (m) => '<em>${m[1]}</em>');

String markdownToHtml(String md) {
  final out = StringBuffer();
  var inList = false;
  for (final raw in md.split('\n')) {
    final line = raw.trimRight();
    final bullet = RegExp(r'^\s*[-*]\s+(.*)$').firstMatch(line);
    if (bullet != null) {
      if (!inList) out.write('<ul>');
      inList = true;
      out.write('<li>${_inline(bullet[1]!)}</li>');
      continue;
    }
    if (inList) {
      out.write('</ul>');
      inList = false;
    }
    final heading = RegExp(r'^(#{1,3})\s+(.*)$').firstMatch(line);
    if (heading != null) {
      out.write('<h${heading[1]!.length}>${_inline(heading[2]!)}</h${heading[1]!.length}>');
    } else if (line.trim().isNotEmpty) {
      out.write('<p>${_inline(line)}</p>');
    }
  }
  if (inList) out.write('</ul>');
  return out.toString();
}

/// Maps notes between the app and the backend's (web) records.
abstract final class NoteMapper {
  static NoteType typeOf(String? kind) => switch (kind) {
    'short' => NoteType.short,
    'detailed' => NoteType.detailed,
    'revision' => NoteType.revision,
    'formula' => NoteType.formulaSheet,
    'definition' => NoteType.definitionSheet,
    'takeaways' => NoteType.keyTakeaways,
    'important_questions' => NoteType.importantQuestions,
    _ => NoteType.freeform,
  };

  static String kindOf(NoteType t) => switch (t) {
    NoteType.short => 'short',
    NoteType.detailed => 'detailed',
    NoteType.revision => 'revision',
    NoteType.formulaSheet => 'formula',
    NoteType.definitionSheet => 'definition',
    NoteType.keyTakeaways => 'takeaways',
    NoteType.importantQuestions => 'important_questions',
    NoteType.freeform => 'custom',
  };

  static NoteSource sourceOf(String? s) => NoteSource.values.where((v) => v.name == s).firstOrNull ?? NoteSource.manual;

  static DateTime _date(Object? v) => (v == null ? null : DateTime.tryParse(v as String)) ?? DateTime.now();

  static Note fromApi(Map<String, dynamic> j) {
    final source = (j['source'] as Map?)?.cast<String, dynamic>() ?? const {};
    return Note(
      id: j['id'] as String,
      title: j['title'] as String? ?? '',
      body: htmlToMarkdown(j['content'] as String? ?? ''),
      createdAt: _date(j['createdAt']),
      updatedAt: _date(j['updatedAt'] ?? j['createdAt']),
      type: typeOf(j['kind'] as String?),
      source: sourceOf(source['type'] as String?),
      folder: j['folderId'] as String?,
      tags: [for (final t in j['tags'] as List? ?? const []) t as String],
      favorite: j['favorite'] as bool? ?? false,
      subjectId: j['subjectId'] as String?,
      chapterId: j['chapterId'] as String? ?? (source['type'] == 'chapter' ? source['refId'] as String? : null),
      linkedIds: [for (final t in j['linkedNoteIds'] as List? ?? const []) t as String],
      history: [
        for (final v in j['versions'] as List? ?? const [])
          NoteVersion(at: _date((v as Map)['at']), title: v['title'] as String? ?? '', body: htmlToMarkdown(v['content'] as String? ?? '')),
      ],
      aiGenerated: j['aiGenerated'] as bool? ?? false,
    );
  }

  static Map<String, dynamic> fields(Note n) => {
    'title': n.title,
    'content': markdownToHtml(n.body),
    'kind': kindOf(n.type),
    'folderId': n.folder,
    'tags': n.tags,
    'favorite': n.favorite,
    'linkedNoteIds': n.linkedIds,
    'subjectId': n.subjectId,
    'chapterId': n.chapterId,
    'aiGenerated': n.aiGenerated,
    'versions': [
      for (final v in n.history) {'at': v.at.toUtc().toIso8601String(), 'title': v.title, 'content': markdownToHtml(v.body)},
    ],
    'createdAt': n.createdAt.toUtc().toIso8601String(),
    'updatedAt': n.updatedAt.toUtc().toIso8601String(),
  };

  /// Filled only for notes created in the app.
  static Map<String, dynamic> defaults(Note n) => {
    'offline': true,
    'source': {'type': n.source.name, 'refId': ?n.chapterId},
  };
}
