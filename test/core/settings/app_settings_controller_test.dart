import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:onehealth_ui/core/mode/app_mode.dart';
import 'package:onehealth_ui/core/settings/app_preferences.dart';
import 'package:onehealth_ui/core/settings/app_settings_controller.dart';

void main() {
  test('defaults to English Demo mode', () {
    final controller = AppSettingsController.memory();
    addTearDown(controller.dispose);

    expect(controller.locale, const Locale('en'));
    expect(controller.mode, AppMode.demo);
  });

  test('loads and persists locale and mode', () async {
    final preferences = MemoryAppPreferences(<String, String>{
      AppSettingsController.localePreferenceKey: 'ar',
      AppSettingsController.modePreferenceKey: 'live',
    });
    final controller = AppSettingsController(preferences: preferences);
    addTearDown(controller.dispose);

    await controller.load();
    expect(controller.locale, const Locale('ar'));
    expect(controller.mode, AppMode.live);

    await controller.setLocale(const Locale('de'));
    await controller.setMode(AppMode.demo);

    expect(
      await preferences.readString(
        AppSettingsController.localePreferenceKey,
      ),
      'de',
    );
    expect(
      await preferences.readString(AppSettingsController.modePreferenceKey),
      'demo',
    );
  });

  test('mode-owned storage namespaces cannot collide', () {
    expect(AppMode.demo.storageNamespace, isNot(AppMode.live.storageNamespace));
  });
}
