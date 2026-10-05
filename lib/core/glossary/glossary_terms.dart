import 'dart:ui';

import '../../l10n/generated/app_localizations.dart';

/// Builds a case-insensitive, Unicode-aware "whole word" matcher for
/// [body] (itself a regex fragment, e.g. an alternation of inflected
/// forms). Plain `\b`/`\w` are ASCII-only in Dart's regex engine, which
/// would silently fail to find a boundary next to Greek, Cyrillic or
/// Arabic letters (none of them are in `\w`) and would also miss
/// Polish/Romanian diacritics -- so this uses `\p{L}`/`\p{N}` Unicode
/// property look-arounds instead, which work for every script this app
/// ships.
RegExp _wholeWord(String body) => RegExp(
  '(?<![\\p{L}\\p{N}_])(?:$body)(?![\\p{L}\\p{N}_])',
  caseSensitive: false,
  unicode: true,
);

/// One tap-to-explain glossary entry. [matchPatterns] holds a per-language
/// word-matching pattern, matched against the literal copy from
/// `assessment-content.json` -- the protocol's own translated text, a
/// different (and differently-covered) language set than the app's ARB
/// locales, see `localeStatus` in that file. [matchPatternFor] falls back
/// to the English pattern for any language with no dedicated entry below;
/// since that pattern is written in English, it simply never matches
/// non-English copy, which is the same graceful "no underline" degradation
/// this feature has always had for locales not yet wired up (e.g. Greek,
/// whose assessment questions have no Greek translation yet and fall back
/// to English text -- the English pattern is exactly right there too).
class GlossaryTerm {
  const GlossaryTerm({
    required this.id,
    required this.matchPatterns,
    required this.title,
    required this.explanation,
  });

  final String id;
  final Map<String, RegExp> matchPatterns;
  final String Function(AppLocalizations strings) title;
  final String Function(AppLocalizations strings) explanation;

  RegExp matchPatternFor(Locale locale) =>
      matchPatterns[locale.languageCode] ?? matchPatterns['en']!;
}

/// Per-locale inflected word forms for one concept, as they actually
/// appear in `assessment-content.json`'s own translated question/option
/// copy (for the seven locales that ship real protocol translations) or
/// as a deliberately-chosen consistent word (for the eleven locales this
/// round added to that file) -- see `AGENTS.md` for the full canonical
/// term table shared between this file and that translation pass. A
/// locale with no entry here falls back to the English pattern (see
/// [GlossaryTerm.matchPatternFor]).
typedef _FormsByLocale = Map<String, String>;

abstract final class GlossaryTerms {
  static const _FormsByLocale _channelForms = <String, String>{
    'fr': r'lits?',
    'it': r'canal[ei]',
    'nl': r'kanaa(?:l|len)',
    'no': r'kanal(?:er|ene)?',
    'pt': r'canais?',
    'es': r'canales?',
    'de': r'Gewässerbetts?',
    'pl': r'koryto|koryta|korycie|korytem',
    'ro': r'albie|albia|albiei',
    'bg': r'русло|руслото|руслата',
    'uk': r'русло|русла|руслі',
    'tr': r'kanal|kanalı|kanalın|kanala|kanalda',
    'ar': r'(?:ال)?مجرى',
    'fi': r'uoma|uoman|uomassa|uomaa',
    'sv': r'fåran?s?',
    'hr': r'korito|koritu|koritom',
  };

  static const _FormsByLocale _substrateForms = <String, String>{
    'fr': r'fonds?',
    'it': r'fond[oi]',
    'nl': r'bodems?',
    'no': r'bunn(?:en)?',
    'pt': r'fundos?',
    'es': r'fondos?',
    'de': r'Sohlen?',
    'pl': r'dno|dna|dnem',
    'ro': r'fundul(?: albiei)?|fund',
    'bg': r'дъно|дъното',
    'uk': r'дно|дна',
    'tr': r'taban|tabanı|tabanın|tabanda',
    'ar': r'(?:ال)?قاع',
    'fi': r'pohja|pohjan|pohjassa',
    'sv': r'botten|bottnen',
    'hr': r'dno|dnu|dnom',
  };

  static const _FormsByLocale _bankForms = <String, String>{
    'fr': r'berges?',
    'it': r'banco|banchi',
    'nl': r'oevers?',
    'no': r'kant(?:er|ene)?',
    'pt': r'margens?',
    'es': r'orillas?',
    'de': r'Ufer',
    'pl': r'brzeg|brzegu|brzegiem',
    'ro': r'malul|maluri|mal',
    'bg': r'бряг|брега',
    'uk': r'берег|берега|береги',
    'tr': r'kıyı(?:sı|nın)?',
    'ar': r'(?:ال)?ضفة|(?:ال)?ضفاف',
    'fi': r'ranta|rannan|rannalla',
    'sv': r'strand(?:en)?',
    'hr': r'obala|obali|obalom',
  };

  static const _FormsByLocale _riparianZoneForms = <String, String>{
    'fr': r'marges?',
    'it': r'margine|margini|marginali',
    'nl': r'marges?',
    'no': r'kantsonene|randsonene|kantsone|randsone',
    'pt': r'margens?',
    'es': r'zona ribereña|zonas ribereñas|margen|márgenes',
    'de': r'Uferzonen?',
    'pl': r'strefa przybrzeżna|strefie przybrzeżnej|strefę przybrzeżną',
    'ro': r'zonă riverană|zona riverană|zone riverane',
    'bg': r'крайречна зона|крайречната зона',
    'uk': r'прибережна зона|прибережної зони|прибережну зону',
    'tr': r'kıyı şeridi(?:nde|ni)?',
    'ar': r'الهامش النهري',
    'fi': r'rantavyöhyke|rantavyöhykkeellä|rantavyöhykkeen',
    'sv': r'strandzon(?:en)?',
    'hr': r'priobalni pojas|priobalnom pojasu',
  };

  static const _FormsByLocale _invasiveSpeciesForms = <String, String>{
    'fr': r'envahissantes?|invasives?',
    'it': r'invasiv[ae]',
    'nl': r'invasieve',
    'no': r'invasiv[et]?',
    'pt': r'invasor[a]?s?',
    'es': r'invasor[a]?s?',
    'de': r'invasive[nrs]?',
    'pl': r'inwazyjny|inwazyjna|inwazyjne|inwazyjnego',
    'ro': r'invazivă|invaziva|invazive',
    'bg': r'инвазивен|инвазивния|инвазивни',
    'uk': r'інвазивний|інвазивні|інвазивного',
    'tr': r'istilacı',
    'ar': r'دخيل',
    'fi': r'vieraslaji|vieraslajit|vieraslajien',
    'sv': r'invasiv[at]?',
    'hr': r'invazivna|invazivne|invazivni',
  };

  static Map<String, RegExp> _patternsFor(
    String english,
    _FormsByLocale forms,
  ) => <String, RegExp>{
    'en': _wholeWord(english),
    for (final entry in forms.entries) entry.key: _wholeWord(entry.value),
  };

  /// The five example terms named in the round-4 build brief, each matched
  /// against whatever word the protocol's own copy actually uses in each
  /// language (the stream bottom is called "bottom" in the English UI,
  /// never "substrate", so that question underlines "bottom" while the
  /// glossary card still teaches the term "substrate" -- and likewise for
  /// every other locale's own word for the same concept).
  static final List<GlossaryTerm> all = <GlossaryTerm>[
    GlossaryTerm(
      id: 'channel',
      matchPatterns: _patternsFor('channel', _channelForms),
      title: (strings) => strings.glossaryChannelTitle,
      explanation: (strings) => strings.glossaryChannelExplanation,
    ),
    GlossaryTerm(
      id: 'substrate',
      matchPatterns: _patternsFor('bottom', _substrateForms),
      title: (strings) => strings.glossarySubstrateTitle,
      explanation: (strings) => strings.glossarySubstrateExplanation,
    ),
    GlossaryTerm(
      id: 'bank',
      matchPatterns: _patternsFor('banks?', _bankForms),
      title: (strings) => strings.glossaryBankTitle,
      explanation: (strings) => strings.glossaryBankExplanation,
    ),
    GlossaryTerm(
      id: 'riparianZone',
      matchPatterns: _patternsFor('riparian|margins?', _riparianZoneForms),
      title: (strings) => strings.glossaryRiparianZoneTitle,
      explanation: (strings) => strings.glossaryRiparianZoneExplanation,
    ),
    GlossaryTerm(
      id: 'invasiveSpecies',
      matchPatterns: _patternsFor('invasive', _invasiveSpeciesForms),
      title: (strings) => strings.glossaryInvasiveSpeciesTitle,
      explanation: (strings) => strings.glossaryInvasiveSpeciesExplanation,
    ),
  ];

  static GlossaryTerm? byId(String id) {
    for (final term in all) {
      if (term.id == id) return term;
    }
    return null;
  }

  static List<GlossaryTerm> byIds(List<String> ids) =>
      ids.map(byId).whereType<GlossaryTerm>().toList(growable: false);
}
