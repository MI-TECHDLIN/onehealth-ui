import 'dart:convert';

import 'package:flutter/services.dart';

class AssessmentContentSource {
  AssessmentContentSource({AssetBundle? bundle}) : _bundle = bundle ?? rootBundle;

  static const String assetPath = 'assets/data/assessment-content.json';

  final AssetBundle _bundle;
  Future<Map<String, dynamic>>? _cached;

  Future<Map<String, dynamic>> load() => _cached ??= _load();

  Future<Map<String, dynamic>> _load() async {
    final decoded = jsonDecode(await _bundle.loadString(assetPath));
    if (decoded is! Map) {
      throw const FormatException('Assessment content must be a JSON object.');
    }
    return Map<String, dynamic>.from(decoded);
  }

  Future<Map<String, dynamic>> localized(String languageCode) async {
    final source = await load();
    final locales = source['contentByLocale'];
    if (locales is! Map) return <String, dynamic>{};
    final english = _stringMap(locales['en']);
    final requested = _stringMap(locales[languageCode]);
    return _merge(english, requested);
  }

  Map<String, dynamic> _merge(
    Map<String, dynamic> fallback,
    Map<String, dynamic> translated,
  ) {
    final result = <String, dynamic>{...fallback};
    for (final entry in translated.entries) {
      final fallbackValue = result[entry.key];
      if (fallbackValue is Map && entry.value is Map) {
        result[entry.key] = _merge(
          Map<String, dynamic>.from(fallbackValue),
          Map<String, dynamic>.from(entry.value as Map),
        );
      } else {
        result[entry.key] = entry.value;
      }
    }
    return result;
  }

  Map<String, dynamic> _stringMap(Object? value) => value is Map
      ? Map<String, dynamic>.from(value)
      : <String, dynamic>{};
}
