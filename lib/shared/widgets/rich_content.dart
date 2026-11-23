import 'package:flutter/services.dart';
import 'package:flutter_math_fork/flutter_math.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';

/// Renders the educational content format used across the app (tutor answers, notes,
/// solutions, textbook pages): a Markdown subset plus LaTeX math.
///
/// Supported: `#`/`##`/`###` headings, paragraphs, `-`/`*` bullets, `1.` lists,
/// `> ` callouts, ``` code blocks, `| table |` rows, `$$display math$$`, inline `$math$`,
/// `**bold**`, `*italic*`, `` `code` `` and `==highlight==`.
class RichContent extends StatelessWidget {
  const RichContent(this.source, {super.key, this.baseStyle, this.selectable = false, this.highlight});

  final String source;
  final TextStyle? baseStyle;
  final bool selectable;

  /// Text to highlight (e.g. a cited passage in the source viewer).
  final String? highlight;

  @override
  Widget build(BuildContext context) {
    final blocks = parseRichBlocks(source);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < blocks.length; i++) ...[
          if (i > 0) SizedBox(height: blocks[i].kind == RichBlockKind.listItem && blocks[i - 1].kind == RichBlockKind.listItem ? AppSpacing.xs : AppSpacing.sm),
          _BlockView(block: blocks[i], baseStyle: baseStyle, highlight: highlight),
        ],
      ],
    );
  }
}

enum RichBlockKind { heading, paragraph, listItem, quote, code, math, table }

class RichBlock {
  RichBlock(this.kind, this.text, {this.level = 0, this.marker, this.rows = const []});

  final RichBlockKind kind;
  final String text;
  final int level;
  final String? marker;
  final List<List<String>> rows;
}

/// Parser exposed for tests.
List<RichBlock> parseRichBlocks(String source) {
  final lines = source.replaceAll('\r\n', '\n').split('\n');
  final blocks = <RichBlock>[];
  final paragraph = <String>[];

  void flushParagraph() {
    if (paragraph.isNotEmpty) {
      blocks.add(RichBlock(RichBlockKind.paragraph, paragraph.join(' ')));
      paragraph.clear();
    }
  }

  var i = 0;
  while (i < lines.length) {
    final raw = lines[i];
    final line = raw.trim();
    if (line.isEmpty) {
      flushParagraph();
      i++;
      continue;
    }
    if (line.startsWith('```')) {
      flushParagraph();
      final code = <String>[];
      i++;
      while (i < lines.length && !lines[i].trim().startsWith('```')) {
        code.add(lines[i]);
        i++;
      }
      blocks.add(RichBlock(RichBlockKind.code, code.join('\n')));
      i++;
      continue;
    }
    if (line.startsWith(r'$$')) {
      flushParagraph();
      var body = line.substring(2);
      if (body.endsWith(r'$$') && body.length >= 2) {
        body = body.substring(0, body.length - 2);
      } else {
        final parts = <String>[body];
        i++;
        while (i < lines.length && !lines[i].trim().endsWith(r'$$')) {
          parts.add(lines[i]);
          i++;
        }
        if (i < lines.length) parts.add(lines[i].trim().replaceAll(r'$$', ''));
        body = parts.join(' ');
      }
      blocks.add(RichBlock(RichBlockKind.math, body.trim()));
      i++;
      continue;
    }
    final heading = RegExp(r'^(#{1,3})\s+(.*)$').firstMatch(line);
    if (heading != null) {
      flushParagraph();
      blocks.add(RichBlock(RichBlockKind.heading, heading.group(2)!, level: heading.group(1)!.length));
      i++;
      continue;
    }
    if (line.startsWith('|')) {
      flushParagraph();
      final rows = <List<String>>[];
      while (i < lines.length && lines[i].trim().startsWith('|')) {
        final row = lines[i].trim();
        final cells = row.substring(1, row.endsWith('|') ? row.length - 1 : row.length).split('|').map((c) => c.trim()).toList();
        if (!cells.every((c) => RegExp(r'^:?-{2,}:?$').hasMatch(c))) rows.add(cells);
        i++;
      }
      blocks.add(RichBlock(RichBlockKind.table, '', rows: rows));
      continue;
    }
    final bullet = RegExp(r'^[-*•]\s+(.*)$').firstMatch(line);
    final numbered = RegExp(r'^(\d+|[কখগঘ]|[a-d])[.)]\s+(.*)$').firstMatch(line);
    if (bullet != null || numbered != null) {
      flushParagraph();
      final indent = raw.length - raw.trimLeft().length;
      blocks.add(
        RichBlock(
          RichBlockKind.listItem,
          bullet?.group(1) ?? numbered!.group(2)!,
          marker: bullet != null ? '•' : '${numbered!.group(1)}.',
          level: indent >= 2 ? 1 : 0,
        ),
      );
      i++;
      continue;
    }
    if (line.startsWith('>')) {
      flushParagraph();
      final quote = <String>[];
      while (i < lines.length && lines[i].trim().startsWith('>')) {
        quote.add(lines[i].trim().substring(1).trim());
        i++;
      }
      blocks.add(RichBlock(RichBlockKind.quote, quote.join(' ')));
      continue;
    }
    paragraph.add(line);
    i++;
  }
  flushParagraph();
  return blocks;
}

class _BlockView extends StatelessWidget {
  const _BlockView({required this.block, this.baseStyle, this.highlight});

  final RichBlock block;
  final TextStyle? baseStyle;
  final String? highlight;

  @override
  Widget build(BuildContext context) {
    final base = baseStyle ?? context.text.bodyLarge!;
    switch (block.kind) {
      case RichBlockKind.heading:
        final style = switch (block.level) {
          1 => context.text.titleLarge,
          2 => context.text.titleMedium,
          _ => context.text.titleSmall,
        };
        return Padding(
          padding: EdgeInsets.only(top: block.level == 1 ? AppSpacing.sm : AppSpacing.xs),
          child: Semantics(header: true, child: InlineRich(block.text, style: style!, highlight: highlight)),
        );
      case RichBlockKind.paragraph:
        return InlineRich(block.text, style: base, highlight: highlight);
      case RichBlockKind.listItem:
        return Padding(
          padding: EdgeInsetsDirectional.only(start: block.level * AppSpacing.lg),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 24,
                child: Text(block.marker ?? '•', style: base.copyWith(color: context.colors.primary, fontWeight: FontWeight.w700)),
              ),
              Expanded(child: InlineRich(block.text, style: base, highlight: highlight)),
            ],
          ),
        );
      case RichBlockKind.quote:
        return Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: context.palette.infoContainer.withValues(alpha: 0.6),
            borderRadius: AppRadius.field,
            border: BorderDirectional(start: BorderSide(color: context.palette.info, width: 4)),
          ),
          child: InlineRich(block.text, style: base, highlight: highlight),
        );
      case RichBlockKind.code:
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: context.colors.surfaceContainerHighest,
            borderRadius: AppRadius.field,
          ),
          child: Stack(
            children: [
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Text(block.text, style: const TextStyle(fontFamily: 'monospace', fontSize: 13, height: 1.5)),
              ),
              PositionedDirectional(
                top: -8,
                end: -8,
                child: IconButton(
                  tooltip: 'Copy',
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(Icons.copy, size: 16),
                  onPressed: () => Clipboard.setData(ClipboardData(text: block.text)),
                ),
              ),
            ],
          ),
        );
      case RichBlockKind.math:
        return Container(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm, horizontal: AppSpacing.md),
          decoration: BoxDecoration(
            color: context.colors.surfaceContainer,
            borderRadius: AppRadius.field,
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Semantics(
              label: block.text,
              child: Math.tex(
                block.text,
                textStyle: base.copyWith(fontSize: (base.fontSize ?? 16) + 2),
                onErrorFallback: (_) => Text(block.text, style: base),
              ),
            ),
          ),
        );
      case RichBlockKind.table:
        if (block.rows.isEmpty) return const SizedBox.shrink();
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Table(
            defaultColumnWidth: const IntrinsicColumnWidth(),
            border: TableBorder.all(color: context.colors.outlineVariant, borderRadius: AppRadius.chip),
            children: [
              for (var r = 0; r < block.rows.length; r++)
                TableRow(
                  decoration: r == 0 ? BoxDecoration(color: context.colors.surfaceContainerHigh) : null,
                  children: [
                    for (final cell in block.rows[r])
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                        child: InlineRich(
                          cell,
                          style: (r == 0 ? context.text.labelLarge : context.text.bodyMedium)!,
                        ),
                      ),
                  ],
                ),
            ],
          ),
        );
    }
  }
}

/// Inline formatting: **bold**, *italic*, `code`, $math$, ==highlight==.
class InlineRich extends StatelessWidget {
  const InlineRich(this.text, {super.key, required this.style, this.highlight, this.maxLines});

  final String text;
  final TextStyle style;
  final String? highlight;
  final int? maxLines;

  static final _token = RegExp(r'(\*\*[^*]+\*\*|\$[^$]+\$|`[^`]+`|==[^=]+==|\*[^*\s][^*]*\*)');

  @override
  Widget build(BuildContext context) {
    final spans = <InlineSpan>[];
    final markColor = context.palette.warningContainer;
    void addPlain(String value) {
      final h = highlight;
      if (h == null || h.isEmpty || !value.contains(h)) {
        spans.add(TextSpan(text: value));
        return;
      }
      final parts = value.split(h);
      for (var i = 0; i < parts.length; i++) {
        spans.add(TextSpan(text: parts[i]));
        if (i < parts.length - 1) {
          spans.add(TextSpan(text: h, style: TextStyle(backgroundColor: markColor, fontWeight: FontWeight.w600)));
        }
      }
    }

    var last = 0;
    for (final match in _token.allMatches(text)) {
      if (match.start > last) addPlain(text.substring(last, match.start));
      final token = match.group(0)!;
      if (token.startsWith('**')) {
        spans.add(TextSpan(text: token.substring(2, token.length - 2), style: const TextStyle(fontWeight: FontWeight.w700)));
      } else if (token.startsWith(r'$')) {
        final tex = token.substring(1, token.length - 1);
        spans.add(
          WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            child: Math.tex(tex, mathStyle: MathStyle.text, textStyle: style, onErrorFallback: (_) => Text(tex, style: style)),
          ),
        );
      } else if (token.startsWith('`')) {
        spans.add(
          TextSpan(
            text: token.substring(1, token.length - 1),
            style: TextStyle(fontFamily: 'monospace', backgroundColor: context.colors.surfaceContainerHighest),
          ),
        );
      } else if (token.startsWith('==')) {
        spans.add(TextSpan(text: token.substring(2, token.length - 2), style: TextStyle(backgroundColor: markColor)));
      } else {
        spans.add(TextSpan(text: token.substring(1, token.length - 1), style: const TextStyle(fontStyle: FontStyle.italic)));
      }
      last = match.end;
    }
    if (last < text.length) addPlain(text.substring(last));
    return Text.rich(TextSpan(style: style, children: spans), maxLines: maxLines, overflow: maxLines == null ? null : TextOverflow.ellipsis);
  }
}

/// Strips formatting for previews, search and clipboard.
String plainTextOf(String source) => source
    .replaceAll(RegExp(r'^#{1,3}\s+', multiLine: true), '')
    .replaceAll(RegExp(r'\*\*|==|`|\$\$'), '')
    .replaceAll(RegExp(r'^\s*[-*>]\s+', multiLine: true), '')
    .trim();
