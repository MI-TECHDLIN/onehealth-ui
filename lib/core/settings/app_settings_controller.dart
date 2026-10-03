import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import '../localization/app_locale.dart';
import '../mode/app_mode.dart';
import 'app_preferences.dart';

class AppSettingsController extends ChangeNotifier {
  AppSettingsController({required AppPreferences preferences})
    : _preferences = preferences;

  factory AppSettingsController.memory() => AppSettingsController(
    preferences: MemoryAppPreferences(),
  );

  static const String localePreferenceKey = 'settings.locale';
  static const String modePreferenceKey = 'settings.mode';

  final AppPreferences _preferences;

  Locale _locale = AppLocaleRegistry.english.locale;
  AppMode _mode = AppMode.demo;

  Locale get locale => _locale;
  AppMode get mode => _mode;

  Future<void> load() async {
    final values = await Future.wait<String?>(<Future<String?>>[
      _preferences.readString(localePreferenceKey),
      _preferences.readString(modePreferenceKey),
    ]);
    _locale = AppLocaleRegistry.fromLanguageCode(values[0]).locale;
    _mode = AppMode.fromStorage(values[1]);
    notifyListeners();
  }

  Future<void> setLocale(Locale locale) async {
    final supported = AppLocaleRegistry.resolve(locale).locale;
    if (_locale == supported) return;
    _locale = supported;
    notifyListeners();
    await _preferences.writeString(
      localePreferenceKey,
      supported.languageCode,
    );
  }

  Future<void> setMode(AppMode mode) async {
    if (_mode == mode) return;
    _mode = mode;
    notifyListeners();
    await _preferences.writeString(modePreferenceKey, mode.name);
  }
}

class AppSettingsScope extends InheritedNotifier<AppSettingsController> {
  const AppSettingsScope({
    required AppSettingsController controller,
    required super.child,
    super.key,
  }) : super(notifier: controller);

  static AppSettingsController of(BuildContext context) {
    final scope = context
        .dependOnInheritedWidgetOfExactType<AppSettingsScope>();
    assert(scope != null, 'No AppSettingsScope found in context.');
    return scope!.notifier!;
  }
}
