import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

class LinkifiedText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final TextStyle? linkStyle;
  final int? maxLines;
  final TextOverflow? overflow;
  final void Function(String)? onLinkTap;

  const LinkifiedText({
    super.key,
    required this.text,
    this.style,
    this.linkStyle,
    this.maxLines,
    this.overflow,
    this.onLinkTap,
  });

  @override
  Widget build(BuildContext context) {
    final RegExp urlRegex = RegExp(r'(https?:\/\/[^\s]+|www\.[^\s]+)', caseSensitive: false);
    final Iterable<RegExpMatch> matches = urlRegex.allMatches(text);

    if (matches.isEmpty) {
      return Text(text, style: style, maxLines: maxLines, overflow: overflow);
    }

    final List<TextSpan> spans = [];
    int currentIndex = 0;

    for (final match in matches) {
      if (match.start > currentIndex) {
        spans.add(TextSpan(text: text.substring(currentIndex, match.start)));
      }

      final String url = match.group(0)!;
      spans.add(
        TextSpan(
          text: url,
          style: linkStyle ?? style?.copyWith(color: Colors.blue, decoration: TextDecoration.underline),
          recognizer: TapGestureRecognizer()
            ..onTap = () {
              if (onLinkTap != null) {
                onLinkTap!(url);
              }
            },
        ),
      );

      currentIndex = match.end;
    }

    if (currentIndex < text.length) {
      spans.add(TextSpan(text: text.substring(currentIndex)));
    }

    return Text.rich(
      TextSpan(children: spans, style: style),
      maxLines: maxLines,
      overflow: overflow,
    );
  }
}
