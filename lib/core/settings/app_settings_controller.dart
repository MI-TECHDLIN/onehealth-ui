import 'package:flutter/widgets.dart';

import '../localization/app_locale.dart';
import '../mode/app_mode.dart';
import '../profile/avatar_catalog.dart';
import 'app_preferences.dart';

class AppSettingsController extends ChangeNotifier {
  AppSettingsController({required AppPreferences preferences})
    : _preferences = preferences;

  factory AppSettingsController.memory() => AppSettingsController(
    preferences: MemoryAppPreferences(),
  );

  static const String localePreferenceKey = 'settings.locale';
  static const String modePreferenceKey = 'settings.mode';
  static const String avatarPreferenceKey = 'profile.avatar';
  static const String onboardingCompleteKey = 'settings.onboardingComplete';
  static const String readAloudEnabledKey = 'settings.onboardingReadAloudEnabled';

  final AppPreferences _preferences;

  Locale _locale = AppLocaleRegistry.english.locale;
  AppMode _mode = AppMode.demo;
  String? _avatarId;
  bool _onboardingComplete = false;
  bool _readAloudEnabled = true;

  Locale get locale => _locale;
  AppMode get mode => _mode;
  String? get avatarId => _avatarId;
  bool get hasCompletedAvatarSetup => _avatarId != null;

  /// Whether the five-screen onboarding story has been shown once.
  bool get onboardingComplete => _onboardingComplete;

  /// The user's remembered on/off preference for onboarding narration.
  bool get readAloudEnabled => _readAloudEnabled;

  Future<void> load() async {
    final values = await Future.wait<String?>(<Future<String?>>[
      _preferences.readString(localePreferenceKey),
      _preferences.readString(modePreferenceKey),
      _preferences.readString(avatarPreferenceKey),
      _preferences.readString(onboardingCompleteKey),
      _preferences.readString(readAloudEnabledKey),
    ]);
    _locale = AppLocaleRegistry.fromLanguageCode(values[0]).locale;
    _mode = AppMode.fromStorage(values[1]);
    _avatarId = AvatarCatalog.ids.contains(values[2]) ? values[2] : null;
    _onboardingComplete = values[3] == 'true';
    _readAloudEnabled = values[4] != 'false';
    notifyListeners();
  }

  /// Marks onboarding as seen so it is not shown again on launch.
  Future<void> completeOnboarding() async {
    if (_onboardingComplete) return;
    _onboardingComplete = true;
    notifyListeners();
    await _preferences.writeString(onboardingCompleteKey, 'true');
  }

  Future<void> setReadAloudEnabled(bool enabled) async {
    if (_readAloudEnabled == enabled) return;
    _readAloudEnabled = enabled;
    notifyListeners();
    await _preferences.writeString(
      readAloudEnabledKey,
      enabled ? 'true' : 'false',
    );
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

  Future<void> setAvatar(String avatarId) async {
    if (!AvatarCatalog.ids.contains(avatarId)) {
      throw ArgumentError.value(avatarId, 'avatarId', 'Unknown avatar');
    }
    if (_avatarId == avatarId) return;
    _avatarId = avatarId;
    notifyListeners();
    await _preferences.writeString(avatarPreferenceKey, avatarId);
  }

  Future<void> autoAssignAvatar() => setAvatar(AvatarCatalog.autoAssignedId);
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
