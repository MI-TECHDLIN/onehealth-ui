import '../../l10n/generated/app_localizations.dart';

/// One tap-to-explain glossary entry. [matchPattern] is matched against the
/// literal English copy from `assessment-content.json` -- the protocol's
/// completed language (see `localeStatus` in that file) and the language
/// this feature ships narration for -- so the underline affordance is
/// English-only for now; other locales simply show no underline, the same
/// graceful degradation `AssessmentContentSource.localized` already applies
/// to untranslated question copy.
class GlossaryTerm {
  const GlossaryTerm({
    required this.id,
    required this.matchPattern,
    required this.title,
    required this.explanation,
  });

  final String id;
  final RegExp matchPattern;
  final String Function(AppLocalizations strings) title;
  final String Function(AppLocalizations strings) explanation;
}

/// The five example terms named in the round-4 build brief, each matched
/// against whatever word the protocol's own English copy actually uses
/// (the stream bottom is called "bottom" in the UI, never "substrate", so
/// that question underlines "bottom" while the glossary card still teaches
/// the term "substrate").
abstract final class GlossaryTerms {
  static final List<GlossaryTerm> all = <GlossaryTerm>[
    GlossaryTerm(
      id: 'channel',
      matchPattern: RegExp(r'\bchannel\b', caseSensitive: false),
      title: (strings) => strings.glossaryChannelTitle,
      explanation: (strings) => strings.glossaryChannelExplanation,
    ),
    GlossaryTerm(
      id: 'substrate',
      matchPattern: RegExp(r'\bbottom\b', caseSensitive: false),
      title: (strings) => strings.glossarySubstrateTitle,
      explanation: (strings) => strings.glossarySubstrateExplanation,
    ),
    GlossaryTerm(
      id: 'bank',
      matchPattern: RegExp(r'\bbanks?\b', caseSensitive: false),
      title: (strings) => strings.glossaryBankTitle,
      explanation: (strings) => strings.glossaryBankExplanation,
    ),
    GlossaryTerm(
      id: 'riparianZone',
      matchPattern: RegExp(r'\b(riparian|margins?)\b', caseSensitive: false),
      title: (strings) => strings.glossaryRiparianZoneTitle,
      explanation: (strings) => strings.glossaryRiparianZoneExplanation,
    ),
    GlossaryTerm(
      id: 'invasiveSpecies',
      matchPattern: RegExp(r'\binvasive\b', caseSensitive: false),
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
