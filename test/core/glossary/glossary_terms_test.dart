import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:onehealth_ui/core/glossary/glossary_terms.dart';

void main() {
  test('English matching is unchanged from the original single-pattern behaviour', () {
    final bank = GlossaryTerms.byId('bank')!;
    expect(
      bank.matchPatternFor(const Locale('en')).hasMatch('The banks of the channel are...'),
      isTrue,
    );
    expect(
      bank.matchPatternFor(const Locale('en')).hasMatch('No match here'),
      isFalse,
    );
  });

  test('French matches its own words for bank and riparian margin distinctly', () {
    final bank = GlossaryTerms.byId('bank')!;
    final riparian = GlossaryTerms.byId('riparianZone')!;
    const fr = Locale('fr');
    expect(bank.matchPatternFor(fr).hasMatch('Les berges sont...'), isTrue);
    expect(riparian.matchPatternFor(fr).hasMatch('Dans les marges / la zone riveraine'), isTrue);
  });

  test('German whole-word matching does not over-match a longer compound', () {
    final bank = GlossaryTerms.byId('bank')!;
    const de = Locale('de');
    expect(bank.matchPatternFor(de).hasMatch('Das Ufer ist steil.'), isTrue);
    // "Uferzone" must stay reserved for the riparian-zone term, not "bank".
    expect(bank.matchPatternFor(de).hasMatch('Die Uferzone ist breit.'), isFalse);
  });

  test('Arabic matching tolerates the attached definite article prefix', () {
    final channel = GlossaryTerms.byId('channel')!;
    const ar = Locale('ar');
    expect(channel.matchPatternFor(ar).hasMatch('شكل مجرى المياه'), isTrue);
    expect(channel.matchPatternFor(ar).hasMatch('عرض المجرى كبير'), isTrue);
  });

  test('Polish inflected case forms all match the same stem', () {
    final substrate = GlossaryTerms.byId('substrate')!;
    const pl = Locale('pl');
    expect(substrate.matchPatternFor(pl).hasMatch('Dno kanału jest naturalne.'), isTrue);
    expect(substrate.matchPatternFor(pl).hasMatch('Patrzysz na dnem potoku.'), isTrue);
  });

  test('a locale with no dedicated pattern gracefully falls back to English '
      '(no false underline on untranslated fallback text)', () {
    final bank = GlossaryTerms.byId('bank')!;
    // Greek's assessment protocol has no Greek translation yet and shows
    // English fallback text; the English pattern must still catch it.
    const el = Locale('el');
    expect(bank.matchPatternFor(el).hasMatch('The banks of the channel are...'), isTrue);
  });
}
