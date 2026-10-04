import 'package:flutter/material.dart';

import 'glossary_sheet.dart';
import 'glossary_terms.dart';

/// Renders [text] with any matching glossary terms underlined and
/// tappable, opening [showGlossarySheet] on tap. Pass the question's own
/// [termIds] (see `AssessmentQuestion.glossaryTermIds`) to scope matching to
/// the terms actually relevant to that question, rather than scanning the
/// full registry against every screen's text.
class GlossaryTermText extends StatelessWidget {
  const GlossaryTermText({
    super.key,
    required this.text,
    required this.termIds,
    required this.readAloudEnabled,
    this.style,
    this.textAlign,
  });

  final String text;
  final List<String> termIds;
  final bool readAloudEnabled;
  final TextStyle? style;
  final TextAlign? textAlign;

  @override
  Widget build(BuildContext context) {
    final terms = GlossaryTerms.byIds(termIds);
    if (terms.isEmpty) {
      return Text(text, style: style, textAlign: textAlign);
    }

    final baseStyle = style ?? DefaultTextStyle.of(context).style;
    final matches = <(int, int, GlossaryTerm)>[];
    for (final term in terms) {
      for (final match in term.matchPattern.allMatches(text)) {
        matches.add((match.start, match.end, term));
      }
    }
    matches.sort((a, b) => a.$1.compareTo(b.$1));

    final spans = <InlineSpan>[];
    var cursor = 0;
    for (final (start, end, term) in matches) {
      if (start < cursor) continue; // overlapping match; keep the first
      if (start > cursor) {
        spans.add(TextSpan(text: text.substring(cursor, start)));
      }
      spans.add(
        WidgetSpan(
          alignment: PlaceholderAlignment.baseline,
          baseline: TextBaseline.alphabetic,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => showGlossarySheet(
              context,
              term: term,
              readAloudEnabled: readAloudEnabled,
            ),
            child: Text(
              text.substring(start, end),
              style: baseStyle.copyWith(
                decoration: TextDecoration.underline,
                decorationStyle: TextDecorationStyle.dotted,
                decorationThickness: 2,
              ),
            ),
          ),
        ),
      );
      cursor = end;
    }
    if (cursor < text.length) {
      spans.add(TextSpan(text: text.substring(cursor)));
    }

    return Text.rich(
      TextSpan(style: baseStyle, children: spans),
      textAlign: textAlign,
    );
  }
}
