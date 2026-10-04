import 'package:flutter/material.dart';

/// Bundled "water-first" MapLibre style JSON, derived from OpenFreeMap's
/// Liberty style. Tiles, sprite and glyphs still stream from OpenFreeMap over
/// the network (no API key); only the style document itself is bundled.
abstract final class MapStyleAssets {
  static const String light = 'assets/map/oneaquahealth-water-light.json';
  static const String dark = 'assets/map/oneaquahealth-water-dark.json';

  static String forBrightness(Brightness brightness) =>
      brightness == Brightness.dark ? dark : light;
}
