import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// The small markdown subset the assistant writes: headings, bullets, numbered steps and **bold**.
/// Tolerates half-written markup while the answer is still streaming.
class AiMarkdown extends StatelessWidget {
  const AiMarkdown({super.key, required this.text, this.trailing});

  final String text;

  /// Shown after the last word (the blinking cursor while streaming).
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final body = theme.textTheme.bodyLarge?.copyWith(height: 1.75, fontSize: 15.5, color: AppColors.onSurface);
    final blocks = _parse(text);
    final children = <Widget>[];

    for (var i = 0; i < blocks.length; i++) {
      final b = blocks[i];
      final isLast = i == blocks.length - 1;
      final tail = isLast && trailing != null ? WidgetSpan(child: trailing!) : null;
      switch (b.kind) {
        case _Kind.gap:
          children.add(const SizedBox(height: 6));
        case _Kind.heading:
          children.add(Padding(
            padding: const EdgeInsets.only(top: 6, bottom: 4),
            child: Text.rich(
              TextSpan(children: [..._inline(b.text, body), if (tail != null) tail]),
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800, color: AppColors.onSurface),
            ),
          ));
        case _Kind.bullet:
        case _Kind.numbered:
          children.add(Padding(
            padding: EdgeInsetsDirectional.only(start: 4.0 + b.indent * 14, bottom: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (b.kind == _Kind.bullet)
                  Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                    ),
                  )
                else
                  Container(
                    margin: const EdgeInsets.only(top: 3),
                    width: 22,
                    height: 22,
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(color: AppColors.primaryContainer, shape: BoxShape.circle),
                    child: Text(
                      b.number,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: AppColors.onPrimaryContainer,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                const SizedBox(width: 10),
                Expanded(child: Text.rich(TextSpan(children: [..._inline(b.text, body), if (tail != null) tail]), style: body)),
              ],
            ),
          ));
        case _Kind.paragraph:
          children.add(Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text.rich(TextSpan(children: [..._inline(b.text, body), if (tail != null) tail]), style: body),
          ));
      }
    }
    if (blocks.isEmpty && trailing != null) children.add(trailing!);

    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: children);
  }
}

enum _Kind { heading, bullet, numbered, paragraph, gap }

class _Block {
  const _Block(this.kind, this.text, {this.number = '', this.indent = 0});

  final _Kind kind;
  final String text;
  final String number;
  final int indent;
}

final _heading = RegExp(r'^\s*#{1,6}\s+(.*)$');
final _bullet = RegExp(r'^(\s*)[-*•]\s+(.*)$');
final _numbered = RegExp(r'^(\s*)(\d{1,2})[.)]\s+(.*)$');

List<_Block> _parse(String text) {
  final blocks = <_Block>[];
  for (final raw in text.replaceAll('\r', '').split('\n')) {
    final line = raw.trimRight();
    if (line.trim().isEmpty) {
      if (blocks.isNotEmpty && blocks.last.kind != _Kind.gap) blocks.add(const _Block(_Kind.gap, ''));
      continue;
    }
    final h = _heading.firstMatch(line);
    if (h != null) {
      blocks.add(_Block(_Kind.heading, h.group(1)!));
      continue;
    }
    final n = _numbered.firstMatch(line);
    if (n != null) {
      blocks.add(_Block(_Kind.numbered, n.group(3)!, number: n.group(2)!, indent: n.group(1)!.length ~/ 2));
      continue;
    }
    final b = _bullet.firstMatch(line);
    if (b != null) {
      blocks.add(_Block(_Kind.bullet, b.group(2)!, indent: b.group(1)!.length ~/ 2));
      continue;
    }
    blocks.add(_Block(_Kind.paragraph, line.trim()));
  }
  while (blocks.isNotEmpty && blocks.last.kind == _Kind.gap) {
    blocks.removeLast();
  }
  return blocks;
}

/// `**bold**` → bold span; stray markers (half-streamed or single `*`) are dropped.
List<InlineSpan> _inline(String text, TextStyle? base) {
  final spans = <InlineSpan>[];
  final parts = text.replaceAll(RegExp(r'\[\d+\]'), '').split('**');
  for (var i = 0; i < parts.length; i++) {
    final part = parts[i].replaceAll(RegExp(r'(?<!\w)[*_](?!\s)|(?<!\s)[*_](?!\w)'), '');
    if (part.isEmpty) continue;
    final bold = i.isOdd && i < parts.length - 1;
    spans.add(TextSpan(
      text: part,
      style: bold ? const TextStyle(fontWeight: FontWeight.w800, color: AppColors.onSurface) : null,
    ));
  }
  return spans;
}
