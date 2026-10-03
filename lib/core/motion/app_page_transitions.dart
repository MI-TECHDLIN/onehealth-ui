import 'package:animations/animations.dart';
import 'package:flutter/material.dart';

import '../theme/tokens.dart';
import 'motion_preferences.dart';

/// Horizontal shared-axis navigation, with a short dissolve for reduce motion.
class AppPageTransitionsBuilder extends PageTransitionsBuilder {
  const AppPageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    if (MotionPreferences.reduceMotionOf(context)) {
      return FadeTransition(
        opacity: CurvedAnimation(
          parent: animation,
          curve: AppMotion.pageCurve,
        ),
        child: child,
      );
    }

    return SharedAxisTransition(
      animation: animation,
      secondaryAnimation: secondaryAnimation,
      transitionType: SharedAxisTransitionType.horizontal,
      fillColor: Colors.transparent,
      child: child,
    );
  }
}

class AppRouteTransition extends StatelessWidget {
  const AppRouteTransition({
    required this.animation,
    required this.secondaryAnimation,
    required this.child,
    super.key,
  });

  final Animation<double> animation;
  final Animation<double> secondaryAnimation;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (MotionPreferences.reduceMotionOf(context)) {
      return FadeTransition(
        opacity: CurvedAnimation(
          parent: animation,
          curve: AppMotion.pageCurve,
        ),
        child: child,
      );
    }

    return SharedAxisTransition(
      animation: animation,
      secondaryAnimation: secondaryAnimation,
      transitionType: SharedAxisTransitionType.horizontal,
      fillColor: Theme.of(context).colorScheme.surface,
      child: child,
    );
  }
}
