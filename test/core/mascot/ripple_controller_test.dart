import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onehealth_ui/core/mascot/aqua_mascot.dart';
import 'package:onehealth_ui/core/mascot/ripple_controller.dart';
import 'package:onehealth_ui/core/theme/tokens.dart';

void main() {
  test('render-v2 parameters interpolate with the original mood values', () {
    final result = MascotMoodSpec.lerp(
      MascotMoodSpec.idle,
      MascotMoodSpec.concerned,
      0.5,
    );

    expect(result.cheekOpacity, closeTo(0.225, 0.001));
    expect(result.browTilt, closeTo(0.5, 0.001));
    expect(result.outlineColor, AppColors.deepWater);
    expect(result.entranceProgress, 1);
  });

  test('viseme smoothing low-passes a timing-source mouth change', () {
    final midpoint = RippleVisemeSmoother.sample(
      begin: RippleVisemeFrame.rest,
      end: RippleVisemeFrame.open,
      elapsed: const Duration(milliseconds: 80),
    );

    expect(midpoint.open, closeTo(0.875, 0.001));
    expect(midpoint.width, closeTo(0.8425, 0.001));
    expect(
      RippleVisemeSmoother.sample(
        begin: RippleVisemeFrame.rest,
        end: RippleVisemeFrame.open,
        elapsed: const Duration(milliseconds: 160),
      ).open,
      1,
    );
  });

  test('controller exposes aimable gesture and external viseme timing', () {
    final controller = RippleController();
    addTearDown(controller.dispose);

    controller.playGesture(
      RippleGesture.point,
      target: const Offset(4, -3),
    );
    expect(controller.gesture, RippleGesture.point);
    expect(controller.target.dx, closeTo(0.8, 0.001));
    expect(controller.target.dy, closeTo(-0.6, 0.001));

    controller.setViseme(RippleViseme.round);
    expect(controller.gesture, RippleGesture.talk);
    expect(controller.viseme, RippleViseme.round);
  });

  testWidgets('gesture commands reach the custom painter', (tester) async {
    final controller = RippleController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: AquaMascot(
          mood: MascotMood.guiding,
          controller: controller,
        ),
      ),
    );

    controller.playGesture(
      RippleGesture.point,
      target: const Offset(-1, -1),
    );
    await tester.pump();

    final paint = tester.widget<CustomPaint>(
      find.descendant(
        of: find.byType(AquaMascot),
        matching: find.byType(CustomPaint),
      ),
    );
    final painter = paint.painter! as AquaMascotPainter;
    expect(painter.gesture, RippleGesture.point);
    expect(painter.target.dx, lessThan(0));
  });
}
