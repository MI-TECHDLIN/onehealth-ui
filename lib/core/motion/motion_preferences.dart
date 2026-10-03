import 'package:flutter/widgets.dart';

import '../theme/tokens.dart';

/// Resolves motion behavior from the current platform accessibility setting.
abstract final class MotionPreferences {
  static bool reduceMotionOf(BuildContext context) {
    final mediaQuery = MediaQuery.maybeOf(context);
    final accessibility = WidgetsBinding
        .instance
        .platformDispatcher
        .accessibilityFeatures;
    return (mediaQuery?.disableAnimations ?? false) ||
        accessibility.disableAnimations ||
        accessibility.reduceMotion;
  }

  static Duration pageDurationOf(BuildContext context) =>
      reduceMotionOf(context) ? AppMotion.reduced : AppMotion.page;
}
