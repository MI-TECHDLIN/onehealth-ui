import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:onehealth_ui/core/localization/app_locale.dart';

void main() {
  test('registry contains the approved 18 language codes', () {
    expect(AppLocaleRegistry.all, hasLength(18));
    expect(
      AppLocaleRegistry.supportedLocales.map((locale) => locale.languageCode),
      containsAll(<String>{
        'en',
        'el',
        'pt',
        'nl',
        'no',
        'fr',
        'it',
        'es',
        'de',
        'pl',
        'ro',
        'bg',
        'tr',
        'uk',
        'ar',
        'fi',
        'sv',
        'hr',
      }),
    );
  });

  test('unknown locales fall back to English', () {
    expect(
      AppLocaleRegistry.resolve(const Locale('ja')),
      AppLocaleRegistry.english,
    );
    expect(AppLocaleRegistry.fromLanguageCode(null), AppLocaleRegistry.english);
  });

  test('unreviewed locales are explicitly marked for translation', () {
    expect(
      AppLocaleRegistry.all
          .where(
            (definition) =>
                definition.translationStatus ==
                TranslationStatus.needsTranslation,
          )
          .length,
      17,
    );
  });
}
