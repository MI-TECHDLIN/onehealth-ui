import 'package:flutter/material.dart';

/// The visual primitives for OneAquaHealth.
///
/// Widgets should consume these tokens (or values derived from [ColorScheme])
/// instead of introducing one-off colors, spacing, or motion timing.
abstract final class AppColors {
  // Water-led brand palette, derived from the Citizen Science app artwork.
  static const Color navy = Color(0xFF123047);
  static const Color deepWater = Color(0xFF126B78);
  static const Color water = Color(0xFF2E9EB0);
  static const Color waterLight = Color(0xFFA9E0E4);
  static const Color waterMist = Color(0xFFE9F7F7);
  static const Color foam = Color(0xFFF8FCFB);
  static const Color white = Color(0xFFFFFFFF);

  static const Color peach = Color(0xFFF5B69B);
  static const Color peachLight = Color(0xFFFFE8DC);
  static const Color sage = Color(0xFF78A98A);
  static const Color sageLight = Color(0xFFDDEBDD);

  // Celebration accents, kept separate from the stream-quality semantics.
  static const Color sparkle = Color(0xFFFFE6AB);

  // Stream-quality semantics: good, moderate, and poor.
  static const Color success = Color(0xFF2E8B62);
  static const Color successContainer = Color(0xFFD8F2E2);
  static const Color warning = Color(0xFFB77900);
  static const Color warningContainer = Color(0xFFFFE6AB);
  static const Color error = Color(0xFFB84A4A);
  static const Color errorContainer = Color(0xFFFFDAD6);

  static const Color ink = Color(0xFF173242);
  static const Color inkMuted = Color(0xFF506773);
  static const Color outline = Color(0xFFB7C9CC);

  // Dark-mode surfaces retain a blue cast instead of becoming neutral grey.
  static const Color night = Color(0xFF071B29);
  static const Color nightSurface = Color(0xFF102A38);
  static const Color nightSurfaceHigh = Color(0xFF1B3A49);
  static const Color nightInk = Color(0xFFE2F4F3);
  static const Color nightInkMuted = Color(0xFFADC7C9);
  static const Color nightOutline = Color(0xFF476370);
}

abstract final class AppTypography {
  static const String? fontFamily = null;

  static const double displaySize = 40;
  static const double headlineSize = 28;
  static const double titleSize = 20;
  static const double bodySize = 16;
  static const double labelSize = 14;
  static const double captionSize = 12;

  static const double tightHeight = 1.15;
  static const double bodyHeight = 1.5;
}

abstract final class AppSpacing {
  static const double xxs = 4;
  static const double xs = 8;
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;
  static const double page = 24;
}

abstract final class AppRadii {
  static const double sm = 10;
  static const double md = 16;
  static const double lg = 24;
  static const double pill = 999;
}

abstract final class AppMotion {
  static const Duration quick = Duration(milliseconds: 200);
  static const Duration moodMorph = Duration(milliseconds: 360);
  static const Duration celebrationEntrance = Duration(milliseconds: 560);
  static const Duration ambientLoop = Duration(milliseconds: 2400);

  static const Curve quickCurve = Curves.easeOutCubic;
  static const Curve moodCurve = Curves.easeInOutCubic;
  static const Curve celebrationCurve = Curves.easeOutBack;
}
