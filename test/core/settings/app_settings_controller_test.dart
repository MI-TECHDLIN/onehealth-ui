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

  test('onboarding defaults to not complete and read-aloud defaults to on', () {
    final controller = AppSettingsController.memory();
    addTearDown(controller.dispose);

    expect(controller.onboardingComplete, isFalse);
    expect(controller.readAloudEnabled, isTrue);
  });

  test('completeOnboarding persists and is idempotent', () async {
    final preferences = MemoryAppPreferences();
    final controller = AppSettingsController(preferences: preferences);
    addTearDown(controller.dispose);
    await controller.load();

    await controller.completeOnboarding();
    expect(controller.onboardingComplete, isTrue);
    expect(
      await preferences.readString(
        AppSettingsController.onboardingCompleteKey,
      ),
      'true',
    );

    // A second call must not throw or flip anything back.
    await controller.completeOnboarding();
    expect(controller.onboardingComplete, isTrue);
  });

  test('setReadAloudEnabled persists the remembered preference', () async {
    final preferences = MemoryAppPreferences();
    final controller = AppSettingsController(preferences: preferences);
    addTearDown(controller.dispose);
    await controller.load();

    await controller.setReadAloudEnabled(false);
    expect(controller.readAloudEnabled, isFalse);
    expect(
      await preferences.readString(AppSettingsController.readAloudEnabledKey),
      'false',
    );

    final reloaded = AppSettingsController(preferences: preferences);
    addTearDown(reloaded.dispose);
    await reloaded.load();
    expect(reloaded.readAloudEnabled, isFalse);
  });
}
