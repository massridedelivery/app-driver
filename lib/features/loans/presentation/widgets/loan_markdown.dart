import 'package:flutter/material.dart';

/// A small Markdown renderer for the loan documents (`GET /loans/terms`
/// bodies). It covers what the documents use: `#`–`###` headings,
/// paragraphs, `-`/`*`/`•` bullets (nested by indent), `1.` numbered items,
/// `---` rules, `>` quotes (holding any of these, nested by `>>`), and
/// `**bold**` / `*italic*` inline. Text is never dropped:
/// anything else renders as a plain line. Line breaks inside a paragraph
/// are kept (legal text numbers its clauses line by line).

enum MdKind { h1, h2, h3, paragraph, bullet, numbered, rule, quote }

@immutable
class MdBlock {
  const MdBlock(
    this.kind,
    this.text, {
    this.level = 0,
    this.marker = '',
    this.children = const [],
  });

  final MdKind kind;
  final String text;

  /// Nesting depth of a list item (0 = top).
  final int level;

  /// `1.` for a numbered item.
  final String marker;

  /// What a [MdKind.quote] holds, parsed like the body.
  final List<MdBlock> children;

  @override
  String toString() =>
      kind == MdKind.quote ? '$kind$children' : '$kind($level,$marker): $text';
}

final _heading = RegExp(r'^(#{1,6})\s+(.*)$');
final _bullet = RegExp(r'^(\s*)[-*•+]\s+(.*)$');
final _numbered = RegExp(r'^(\s*)(\d+[.)])\s+(.*)$');
final _rule = RegExp(r'^\s*([-*_])(\s*\1){2,}\s*$');
final _quote = RegExp(r'^ {0,3}> ?(.*)$');

/// Splits [source] into blocks.
List<MdBlock> parseMarkdown(String source) {
  final out = <MdBlock>[];
  final para = <String>[];
  final quote = <String>[];
  void flush() {
    if (para.isNotEmpty) {
      out.add(MdBlock(MdKind.paragraph, para.join('\n')));
      para.clear();
    }
  }

  void flushQuote() {
    if (quote.isNotEmpty) {
      out.add(
        MdBlock(MdKind.quote, '', children: parseMarkdown(quote.join('\n'))),
      );
      quote.clear();
    }
  }

  for (final raw in source.replaceAll('\r\n', '\n').split('\n')) {
    final line = raw.trimRight();
    final q = _quote.firstMatch(line);
    if (q != null) {
      // Consecutive `>` lines are one quote; a bare `>` splits its
      // paragraphs.
      flush();
      quote.add(q.group(1)!);
      continue;
    }
    flushQuote();
    if (line.trim().isEmpty) {
      flush();
      continue;
    }
    if (_rule.hasMatch(line)) {
      flush();
      out.add(const MdBlock(MdKind.rule, ''));
      continue;
    }
    final h = _heading.firstMatch(line.trimLeft());
    if (h != null) {
      flush();
      final n = h.group(1)!.length;
      out.add(
        MdBlock(
          n == 1 ? MdKind.h1 : (n == 2 ? MdKind.h2 : MdKind.h3),
          h.group(2)!.trim(),
        ),
      );
      continue;
    }
    final b = _bullet.firstMatch(line);
    if (b != null) {
      flush();
      out.add(MdBlock(MdKind.bullet, b.group(2)!, level: _depth(b.group(1)!)));
      continue;
    }
    final n = _numbered.firstMatch(line);
    if (n != null) {
      flush();
      out.add(
        MdBlock(
          MdKind.numbered,
          n.group(3)!,
          level: _depth(n.group(1)!),
          marker: n.group(2)!,
        ),
      );
      continue;
    }
    para.add(line.trimLeft());
  }
  flush();
  flushQuote();
  return out;
}

int _depth(String indent) {
  final spaces = indent.replaceAll('\t', '    ').length;
  return (spaces / 2).floor().clamp(0, 4);
}

/// Inline `**bold**`, `__bold__`, `*italic*`, `_italic_`. Unmatched markers
/// stay as typed.
List<InlineSpan> parseInline(String text, TextStyle base) {
  final spans = <InlineSpan>[];
  final re = RegExp(
    r'\*\*(.+?)\*\*|__(.+?)__|(?<![\w*])\*(?!\s)(.+?)(?<!\s)\*(?!\*)|(?<![\w_])_(?!\s)(.+?)(?<!\s)_(?![\w_])',
  );
  var at = 0;
  for (final m in re.allMatches(text)) {
    if (m.start > at) spans.add(TextSpan(text: text.substring(at, m.start)));
    final bold = m.group(1) ?? m.group(2);
    if (bold != null) {
      spans.add(
        TextSpan(
          children: parseInline(bold, base),
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
      );
    } else {
      spans.add(
        TextSpan(
          text: m.group(3) ?? m.group(4),
          style: const TextStyle(fontStyle: FontStyle.italic),
        ),
      );
    }
    at = m.end;
  }
  if (at < text.length) spans.add(TextSpan(text: text.substring(at)));
  return spans;
}

/// Renders [source]. Selectable, scales with the system text size.
class LoanMarkdown extends StatelessWidget {
  const LoanMarkdown(this.source, {super.key, this.color});

  final String source;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final base = TextStyle(
      fontSize: 15,
      height: 1.55,
      color: color ?? Theme.of(context).colorScheme.onSurface,
    );
    final blocks = parseMarkdown(source);
    return SelectionArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [for (final b in blocks) _block(b, base)],
      ),
    );
  }

  Widget _rich(String text, TextStyle style) =>
      Text.rich(TextSpan(style: style, children: parseInline(text, style)));

  Widget _block(MdBlock b, TextStyle base) {
    switch (b.kind) {
      case MdKind.h1:
      case MdKind.h2:
      case MdKind.h3:
        final size = switch (b.kind) {
          MdKind.h1 => 20.0,
          MdKind.h2 => 17.0,
          _ => 15.5,
        };
        return Padding(
          padding: const EdgeInsets.only(top: 14, bottom: 6),
          child: Semantics(
            header: true,
            child: _rich(
              b.text,
              base.copyWith(
                fontSize: size,
                fontWeight: FontWeight.w700,
                height: 1.35,
              ),
            ),
          ),
        );
      case MdKind.paragraph:
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: _rich(b.text, base),
        );
      case MdKind.bullet:
      case MdKind.numbered:
        return Padding(
          padding: EdgeInsets.only(left: 4.0 + b.level * 18, bottom: 6),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: b.kind == MdKind.numbered ? 28 : 16,
                child: Text(
                  b.kind == MdKind.numbered
                      ? b.marker
                      : (b.level == 0 ? '•' : '◦'),
                  style: base,
                ),
              ),
              Expanded(child: _rich(b.text, base)),
            ],
          ),
        );
      case MdKind.rule:
        return const Padding(
          padding: EdgeInsets.symmetric(vertical: 10),
          child: Divider(height: 1),
        );
      case MdKind.quote:
        return _Quote(
          color: base.color!,
          children: [for (final c in b.children) _block(c, base)],
        );
    }
  }
}

/// A `>` quote: a tinted panel with a bar on the reading-start edge.
class _Quote extends StatelessWidget {
  const _Quote({required this.color, required this.children});

  final Color color;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.05),
          border: BorderDirectional(
            start: BorderSide(color: color.withValues(alpha: 0.35), width: 3),
          ),
        ),
        child: Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(12, 10, 10, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: children,
          ),
        ),
      ),
    );
  }
}
