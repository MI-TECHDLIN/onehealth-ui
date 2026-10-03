import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onehealth_ui/core/motion/motion_preferences.dart';
import 'package:onehealth_ui/core/theme/tokens.dart';

void main() {
  testWidgets('platform reduce motion selects the 120 ms duration', (
    tester,
  ) async {
    late BuildContext context;
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(disableAnimations: true),
        child: Builder(
          builder: (builderContext) {
            context = builderContext;
            return const SizedBox();
          },
        ),
      ),
    );

    expect(MotionPreferences.reduceMotionOf(context), isTrue);
    expect(MotionPreferences.pageDurationOf(context), AppMotion.reduced);
  });
}
