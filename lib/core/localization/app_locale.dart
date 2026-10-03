import 'dart:ui';

enum TranslationStatus { reviewed, needsTranslation }

class AppLocaleDefinition {
  const AppLocaleDefinition({
    required this.locale,
    required this.englishName,
    required this.endonym,
    required this.translationStatus,
  });

  final Locale locale;
  final String englishName;
  final String endonym;
  final TranslationStatus translationStatus;
}

/// The complete locale set approved by the Ripple Field Guide.
///
/// English is the source locale. Until a domain reviewer signs off another
/// locale, gen-l10n falls back to the English template for each missing string.
abstract final class AppLocaleRegistry {
  static const AppLocaleDefinition english = AppLocaleDefinition(
    locale: Locale('en'),
    englishName: 'English',
    endonym: 'English',
    translationStatus: TranslationStatus.reviewed,
  );

  static const List<AppLocaleDefinition> all = <AppLocaleDefinition>[
    english,
    AppLocaleDefinition(
      locale: Locale('el'),
      englishName: 'Greek',
      endonym: 'Ελληνικά',
      translationStatus: TranslationStatus.needsTranslation,
    ),
    AppLocaleDefinition(
      locale: Locale('pt'),
      englishName: 'Portuguese',
      endonym: 'Português',
      translationStatus: TranslationStatus.needsTranslation,
    ),
    AppLocaleDefinition(
      locale: Locale('nl'),
      englishName: 'Dutch',
      endonym: 'Nederlands',
      translationStatus: TranslationStatus.needsTranslation,
    ),
    AppLocaleDefinition(
      locale: Locale('no'),
      englishName: 'Norwegian',
      endonym: 'Norsk',
      translationStatus: TranslationStatus.needsTranslation,
    ),
    AppLocaleDefinition(
      locale: Locale('fr'),
      englishName: 'French',
      endonym: 'Français',
      translationStatus: TranslationStatus.needsTranslation,
    ),
    AppLocaleDefinition(
      locale: Locale('it'),
      englishName: 'Italian',
      endonym: 'Italiano',
      translationStatus: TranslationStatus.needsTranslation,
    ),
    AppLocaleDefinition(
      locale: Locale('es'),
      englishName: 'Spanish',
      endonym: 'Español',
      translationStatus: TranslationStatus.needsTranslation,
    ),
    AppLocaleDefinition(
      locale: Locale('de'),
      englishName: 'German',
      endonym: 'Deutsch',
      translationStatus: TranslationStatus.needsTranslation,
    ),
    AppLocaleDefinition(
      locale: Locale('pl'),
      englishName: 'Polish',
      endonym: 'Polski',
      translationStatus: TranslationStatus.needsTranslation,
    ),
    AppLocaleDefinition(
      locale: Locale('ro'),
      englishName: 'Romanian',
      endonym: 'Română',
      translationStatus: TranslationStatus.needsTranslation,
    ),
    AppLocaleDefinition(
      locale: Locale('bg'),
      englishName: 'Bulgarian',
      endonym: 'Български',
      translationStatus: TranslationStatus.needsTranslation,
    ),
    AppLocaleDefinition(
      locale: Locale('tr'),
      englishName: 'Turkish',
      endonym: 'Türkçe',
      translationStatus: TranslationStatus.needsTranslation,
    ),
    AppLocaleDefinition(
      locale: Locale('uk'),
      englishName: 'Ukrainian',
      endonym: 'Українська',
      translationStatus: TranslationStatus.needsTranslation,
    ),
    AppLocaleDefinition(
      locale: Locale('ar'),
      englishName: 'Arabic',
      endonym: 'العربية',
      translationStatus: TranslationStatus.needsTranslation,
    ),
    AppLocaleDefinition(
      locale: Locale('fi'),
      englishName: 'Finnish',
      endonym: 'Suomi',
      translationStatus: TranslationStatus.needsTranslation,
    ),
    AppLocaleDefinition(
      locale: Locale('sv'),
      englishName: 'Swedish',
      endonym: 'Svenska',
      translationStatus: TranslationStatus.needsTranslation,
    ),
    AppLocaleDefinition(
      locale: Locale('hr'),
      englishName: 'Croatian',
      endonym: 'Hrvatski',
      translationStatus: TranslationStatus.needsTranslation,
    ),
  ];

  static List<Locale> get supportedLocales =>
      all.map((definition) => definition.locale).toList(growable: false);

  static AppLocaleDefinition resolve(Locale? locale) {
    if (locale == null) return english;
    return all.firstWhere(
      (definition) =>
          definition.locale.languageCode == locale.languageCode,
      orElse: () => english,
    );
  }

  static AppLocaleDefinition fromLanguageCode(String? languageCode) {
    if (languageCode == null) return english;
    return resolve(Locale(languageCode));
  }
}
