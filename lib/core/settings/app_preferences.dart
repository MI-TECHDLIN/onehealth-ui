import 'package:shared_preferences/shared_preferences.dart';

abstract interface class AppPreferences {
  Future<String?> readString(String key);
  Future<void> writeString(String key, String value);
}

class SharedPreferencesAppPreferences implements AppPreferences {
  SharedPreferencesAppPreferences({SharedPreferencesAsync? preferences})
    : _preferences = preferences ?? SharedPreferencesAsync();

  final SharedPreferencesAsync _preferences;

  @override
  Future<String?> readString(String key) => _preferences.getString(key);

  @override
  Future<void> writeString(String key, String value) async {
    await _preferences.setString(key, value);
  }
}

class MemoryAppPreferences implements AppPreferences {
  MemoryAppPreferences([Map<String, String>? initialValues])
    : _values = Map<String, String>.of(initialValues ?? const {});

  final Map<String, String> _values;

  @override
  Future<String?> readString(String key) async => _values[key];

  @override
  Future<void> writeString(String key, String value) async {
    _values[key] = value;
  }
}
