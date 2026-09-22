import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onehealth_ui/core/mascot/aqua_mascot.dart';
import 'package:onehealth_ui/core/mascot/mascot_identity.dart';
import 'package:onehealth_ui/core/theme/app_theme.dart';
import 'package:onehealth_ui/core/theme/tokens.dart';
import 'package:onehealth_ui/debug/mascot_gallery_screen.dart';
import 'package:onehealth_ui/main.dart';

void main() {
  test('theme exposes the water palette in light and dark modes', () {
    expect(AppTheme.light.colorScheme.primary, AppColors.deepWater);
    expect(AppTheme.light.colorScheme.tertiary, AppColors.peach);
    expect(AppTheme.dark.brightness, Brightness.dark);
    expect(AppTheme.dark.colorScheme.surface, AppColors.night);
  });

  test('mood specifications interpolate instead of hard cutting', () {
    final midpoint = MascotMoodSpec.lerp(
      MascotMoodSpec.idle,
      MascotMoodSpec.celebrating,
      0.5,
    );

    expect(midpoint.widthScale, greaterThan(MascotMoodSpec.idle.widthScale));
    expect(
      midpoint.widthScale,
      lessThan(MascotMoodSpec.celebrating.widthScale),
    );
    expect(midpoint.sparkles, 0.5);
    expect(midpoint.eyeOpenness, closeTo(0.54, 0.001));
  });

  testWidgets('app shell uses the new theme and opens the debug gallery', (
    tester,
  ) async {
    await tester.pumpWidget(const OneHealthApp());

    expect(find.text('Meet ${MascotIdentity.displayName}'), findsOneWidget);
    expect(find.byType(AquaMascot), findsOneWidget);

    await tester.tap(find.text('Review all moods'));
    await tester.pump();
    await tester.pump(AppMotion.celebrationEntrance);

    expect(find.byType(MascotGalleryScreen), findsOneWidget);
    expect(find.text('Settled poses'), findsOneWidget);
    expect(find.byType(AquaMascot), findsNWidgets(6));
  });

  testWidgets('reduced motion holds the mascot at its settled pose', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MediaQuery(
        data: MediaQueryData(disableAnimations: true),
        child: MaterialApp(home: AquaMascot(mood: MascotMood.thinking)),
      ),
    );

    final paint = tester.widget<CustomPaint>(
      find.descendant(
        of: find.byType(AquaMascot),
        matching: find.byType(CustomPaint),
      ),
    );
    final painter = paint.painter! as AquaMascotPainter;
    expect(painter.ambientPhase, 0);
    expect(painter.spec.thinkingAccent, 1);
  });

  testWidgets('changing mood produces an in-between painted state', (
    tester,
  ) async {
    final mood = ValueNotifier<MascotMood>(MascotMood.idle);
    addTearDown(mood.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: ValueListenableBuilder<MascotMood>(
          valueListenable: mood,
          builder: (context, value, child) => AquaMascot(mood: value),
        ),
      ),
    );

    mood.value = MascotMood.celebrating;
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    final paint = tester.widget<CustomPaint>(
      find.descendant(
        of: find.byType(AquaMascot),
        matching: find.byType(CustomPaint),
      ),
    );
    final painter = paint.painter! as AquaMascotPainter;
    expect(painter.spec.sparkles, greaterThan(0));
    expect(painter.spec.sparkles, lessThan(1));
  });
}
