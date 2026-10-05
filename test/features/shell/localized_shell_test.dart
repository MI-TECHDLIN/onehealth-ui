import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onehealth_ui/core/settings/app_preferences.dart';
import 'package:onehealth_ui/core/settings/app_settings_controller.dart';
import 'package:onehealth_ui/l10n/generated/app_localizations.dart';
import 'package:onehealth_ui/main.dart';

void main() {
  testWidgets('Arabic locale uses RTL with its translated home title', (
    tester,
  ) async {
    final settings = AppSettingsController(
      preferences: MemoryAppPreferences(),
    );
    addTearDown(settings.dispose);
    await settings.setLocale(const Locale('ar'));
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

    final homeTitle = AppLocalizations.of(
      tester.element(find.byType(Scaffold).first),
    ).homeTitle;

    expect(find.text(homeTitle), findsWidgets);
    expect(
      Directionality.of(tester.element(find.text(homeTitle).first)),
      TextDirection.rtl,
    );
  });
}
