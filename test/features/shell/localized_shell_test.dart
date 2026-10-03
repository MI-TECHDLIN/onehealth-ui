import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onehealth_ui/core/settings/app_preferences.dart';
import 'package:onehealth_ui/core/settings/app_settings_controller.dart';
import 'package:onehealth_ui/main.dart';

void main() {
  testWidgets('Arabic locale uses RTL with per-string English fallback', (
    tester,
  ) async {
    final settings = AppSettingsController(
      preferences: MemoryAppPreferences(),
    );
    addTearDown(settings.dispose);
    await settings.setLocale(const Locale('ar'));

    await tester.pumpWidget(
      OneHealthApp(settings: settings, applyGoogleFonts: false),
    );
    await tester.pumpAndSettle();

    expect(find.text('Explore streams'), findsWidgets);
    expect(
      Directionality.of(tester.element(find.text('Explore streams').first)),
      TextDirection.rtl,
    );
  });
}
