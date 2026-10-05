import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onehealth_ui/core/localization/app_locale.dart';
import 'package:onehealth_ui/core/settings/app_preferences.dart';
import 'package:onehealth_ui/core/settings/app_settings_controller.dart';
import 'package:onehealth_ui/main.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

/// Round-7 translation safety net: every one of the 18 approved locales
/// must render the shell's key destinations without a dangling English
/// fallback crashing a lookup, and -- the point of this file -- without
/// tripping a `RenderFlex overflowed` or other layout exception now that
/// German/Finnish/Greek/Polish-length real text replaces the old English
/// placeholder copy in every ARB file. `flutter_test` fails a test the
/// moment the framework records such an exception, so simply pumping each
/// screen is the check; see `docs/manual-qa.md` for the 200% text-scale and
/// Arabic RTL spot checks this automated pass does not attempt.
void main() {
  for (final definition in AppLocaleRegistry.all) {
    testWidgets(
      '${definition.englishName} (${definition.locale.languageCode}) '
      'renders Home, Streams, Impact, You and Settings without overflow',
      (tester) async {
        final settings = AppSettingsController(
          preferences: MemoryAppPreferences(),
        );
        addTearDown(settings.dispose);
        await settings.setLocale(definition.locale);
        await settings.completeOnboarding();

        await tester.pumpWidget(
          OneHealthApp(
            settings: settings,
            applyGoogleFonts: false,
            // Avoids standing up the native MapLibre view in a widget test.
            homeMapViewBuilder:
                ({
                  required sites,
                  required visitedCodes,
                  required myLocationEnabled,
                  required onSiteTapped,
                  required onControllerReady,
                }) => const SizedBox.shrink(),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: 'Home');

        await tester.tap(find.byIcon(PhosphorIconsRegular.drop));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: 'Streams');

        await tester.tap(find.byIcon(PhosphorIconsRegular.chartLineUp));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: 'Impact');

        await tester.tap(find.byIcon(PhosphorIconsRegular.user));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: 'Profile/You');

        expect(find.text('DEMO'), findsNothing);
        await tester.tap(find.byKey(const Key('shellSettingsButton')));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: 'Settings sheet');
      },
    );
  }
}
