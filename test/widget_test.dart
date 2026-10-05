import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onehealth_ui/core/mascot/aqua_mascot.dart';
import 'package:onehealth_ui/core/settings/app_preferences.dart';
import 'package:onehealth_ui/core/settings/app_settings_controller.dart';
import 'package:onehealth_ui/core/theme/app_theme.dart';
import 'package:onehealth_ui/core/theme/tokens.dart';
import 'package:onehealth_ui/debug/mascot_gallery_screen.dart';
import 'package:onehealth_ui/main.dart';

void main() {
  test('theme exposes the water palette in light and dark modes', () {
    final light = AppTheme.lightFor(
      const Locale('en'),
      applyGoogleFonts: false,
    );
    final dark = AppTheme.darkFor(
      const Locale('en'),
      applyGoogleFonts: false,
    );
    expect(light.colorScheme.primary, AppColors.deepWater);
    expect(light.colorScheme.tertiary, AppColors.peach);
    expect(dark.brightness, Brightness.dark);
    expect(dark.colorScheme.surface, AppColors.night);
    expect(
      light.textTheme.bodyLarge?.fontFamily,
      AppTypography.fontFamily,
    );
    expect(
      AppTheme.lightFor(
        const Locale('ar'),
        applyGoogleFonts: false,
      ).textTheme.bodyLarge?.fontFamily,
      AppTypography.arabicFontFamily,
    );
  });

  test('field guide tokens expose touch, elevation, and motion primitives', () {
    expect(AppSpacing.minTouchTarget, 48);
    expect(AppRadii.xl, 32);
    expect(AppOpacity.disabled, 0.46);
    expect(AppStrokes.focus, 3);
    expect(AppElevation.high.single.blurRadius, 32);
    expect(AppElevation.raisedAction.single.offset, const Offset(0, 5));
    expect(AppSizes.bottomNavigationHeight, 74);
    expect(AppMotion.page, const Duration(milliseconds: 300));
    expect(AppMotion.reduced, const Duration(milliseconds: 120));
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

  test('overshooting progress moves the pose but keeps alpha in range', () {
    final overshoot = MascotMoodSpec.lerp(
      MascotMoodSpec.idle,
      MascotMoodSpec.celebrating,
      1.1,
    );

    expect(
      overshoot.widthScale,
      greaterThan(MascotMoodSpec.celebrating.widthScale),
    );
    expect(overshoot.sparkles, 1);
    expect(overshoot.bodyColor, MascotMoodSpec.celebrating.bodyColor);
  });

  testWidgets('app shell navigates and keeps the debug gallery reachable', (
    tester,
  ) async {
    final settings = AppSettingsController(
      preferences: MemoryAppPreferences(),
    );
    addTearDown(settings.dispose);
    await settings.completeOnboarding();
    await tester.pumpWidget(
      OneHealthApp(
        settings: settings,
        applyGoogleFonts: false,
        // Avoids standing up the native MapLibre view in a widget test.
        homeMapViewBuilder:
            ({
              required sites,
              required visitedCodes,
              required myLocationEnabled,
              required onSiteTapped,
              required onControllerReady,
            }) => const SizedBox.shrink(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Explore streams'), findsWidgets);
    expect(find.text('DEMO'), findsOneWidget);
    expect(find.text('Check'), findsOneWidget);

    await tester.tap(find.text('Streams'));
    await tester.pumpAndSettle();
    expect(find.text('My streams'), findsWidgets);

    await tester.tap(find.text('Check'));
    await tester.pumpAndSettle();
    expect(find.byType(AppBar), findsOneWidget);

    await tester.tap(find.text('DEMO'));
    await tester.pumpAndSettle();
    expect(find.text('Settings'), findsOneWidget);

    await tester.tap(find.text('Review Ripple moods'));
    await tester.pump();
    await tester.pump(AppMotion.page);

    expect(find.byType(MascotGalleryScreen), findsOneWidget);
    expect(find.text('Settled moods'), findsOneWidget);
    expect(find.byType(AquaMascot), findsAtLeastNWidgets(6));
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

  testWidgets('celebration entrance overshoots before settling', (
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

    MascotMoodSpec paintedSpec() {
      final paint = tester.widget<CustomPaint>(
        find.descendant(
          of: find.byType(AquaMascot),
          matching: find.byType(CustomPaint),
        ),
      );
      return (paint.painter! as AquaMascotPainter).spec;
    }

    mood.value = MascotMood.celebrating;
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 420));
    expect(
      paintedSpec().widthScale,
      greaterThan(MascotMoodSpec.celebrating.widthScale),
    );

    await tester.pump(AppMotion.celebrationEntrance);
    expect(
      paintedSpec().widthScale,
      closeTo(MascotMoodSpec.celebrating.widthScale, 0.0001),
    );
  });
}
