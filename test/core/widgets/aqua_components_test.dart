import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onehealth_ui/core/mascot/aqua_mascot.dart';
import 'package:onehealth_ui/core/widgets/aqua_components.dart';
import 'package:onehealth_ui/core/widgets/badge_crest.dart';
import 'package:onehealth_ui/core/widgets/friendly_error_banner.dart';
import 'package:onehealth_ui/core/widgets/reduced_motion_lottie.dart';

Widget _app(Widget child, {bool reduceMotion = false}) => MaterialApp(
  home: MediaQuery(
    data: MediaQueryData(disableAnimations: reduceMotion),
    child: Scaffold(body: Center(child: child)),
  ),
);

void main() {
  testWidgets('button variants invoke actions and expose disabled/loading states', (
    tester,
  ) async {
    var taps = 0;
    await tester.pumpWidget(
      _app(
        Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            AquaButton(label: 'Primary', onPressed: () => taps++),
            AquaButton(
              label: 'Secondary',
              variant: AquaButtonVariant.secondary,
              onPressed: () => taps++,
            ),
            AquaButton(
              label: 'Ghost',
              variant: AquaButtonVariant.ghost,
              onPressed: () => taps++,
            ),
            const AquaButton(label: 'Loading', loading: true, onPressed: null),
            const AquaButton(label: 'Disabled', onPressed: null),
          ],
        ),
      ),
    );

    await tester.tap(find.text('Primary'));
    await tester.tap(find.text('Secondary'));
    await tester.tap(find.text('Ghost'));
    expect(taps, 3);
    expect(find.byKey(const Key('aqua_button_loading')), findsOneWidget);
    final disabledInk = tester.widget<InkWell>(
      find.descendant(
        of: find.widgetWithText(AquaButton, 'Disabled'),
        matching: find.byType(InkWell),
      ),
    );
    expect(disabledInk.onTap, isNull);
  });

  testWidgets('button compresses its tactile base while pressed', (tester) async {
    await tester.pumpWidget(
      _app(AquaButton(label: 'Hold me', onPressed: () {})),
    );

    final gesture = await tester.startGesture(tester.getCenter(find.text('Hold me')));
    await tester.pump(const Duration(milliseconds: 120));
    final pressed = tester.widget<AnimatedContainer>(find.byType(AnimatedContainer));
    expect(pressed.transform?.getTranslation().y, closeTo(4, 0.01));

    await gesture.up();
    await tester.pump(const Duration(milliseconds: 120));
    final released = tester.widget<AnimatedContainer>(find.byType(AnimatedContainer));
    expect(released.transform?.getTranslation().y, closeTo(0, 0.01));
  });

  testWidgets('step progress and pager announce position', (tester) async {
    final handle = tester.ensureSemantics();
    addTearDown(handle.dispose);
    await tester.pumpWidget(
      _app(
        const Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            StepProgressBar(
              sectionLabel: 'Water and habitat',
              currentStep: 4,
              totalSteps: 9,
            ),
            OnboardingPager(page: 2, pageCount: 5),
          ],
        ),
      ),
    );

    expect(find.bySemanticsLabel('Water and habitat, step 4 of 9'), findsOneWidget);
    expect(find.bySemanticsLabel('Page 3 of 5'), findsOneWidget);
  });

  testWidgets('filter chip covers selected, default and disabled states', (
    tester,
  ) async {
    var selected = true;
    await tester.pumpWidget(
      _app(
        StatefulBuilder(
          builder: (context, setState) => Row(
            children: <Widget>[
              AquaFilterChip(
                label: 'Selected',
                selected: selected,
                onSelected: (value) => setState(() => selected = value),
              ),
              AquaFilterChip(label: 'Default', selected: false, onSelected: (_) {}),
              const AquaFilterChip(
                label: 'Disabled',
                selected: false,
                onSelected: null,
              ),
            ],
          ),
        ),
      ),
    );

    await tester.tap(find.text('Selected'));
    expect(selected, isFalse);
    expect(
      tester
          .widget<FilterChip>(find.widgetWithText(FilterChip, 'Disabled'))
          .onSelected,
      isNull,
    );
  });

  testWidgets('picture card supports selected, disabled and multi-select states', (
    tester,
  ) async {
    var selected = false;
    await tester.pumpWidget(
      _app(
        SizedBox(
          width: 600,
          child: Row(
            children: <Widget>[
              Expanded(
                child: PictureChoiceCard(
                  image: const Placeholder(),
                  label: 'Choice',
                  selected: selected,
                  onSelected: (value) => selected = value,
                ),
              ),
              Expanded(
                child: PictureChoiceCard(
                  image: const Placeholder(),
                  label: 'Selected many',
                  selected: true,
                  multiSelect: true,
                  onSelected: (_) {},
                ),
              ),
              const Expanded(
                child: PictureChoiceCard(
                  image: Placeholder(),
                  label: 'Disabled',
                  selected: false,
                  enabled: false,
                  onSelected: null,
                ),
              ),
            ],
          ),
        ),
      ),
    );

    await tester.tap(find.text('Choice'));
    expect(selected, isTrue);
    expect(find.text('Selected many'), findsOneWidget);
    expect(find.text('Disabled'), findsOneWidget);
  });

  testWidgets('not-sure action is first-class and invokes its callback', (
    tester,
  ) async {
    var tapped = false;
    await tester.pumpWidget(_app(NotSureButton(onPressed: () => tapped = true)));
    await tester.tap(find.text("I'm not sure"));
    expect(tapped, isTrue);
  });

  testWidgets('friendly banner supplies concerned Ripple by default', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(const FriendlyErrorBanner(message: 'Please try again.')),
    );

    final ripple = tester.widget<AquaMascot>(find.byType(AquaMascot));
    expect(ripple.mood, MascotMood.concerned);
  });

  testWidgets('loading state announces work and uses thinking Ripple', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(const RippleLoadingState(label: 'Finding streams')),
    );

    expect(find.byType(LinearProgressIndicator), findsOneWidget);
    expect(tester.widget<AquaMascot>(find.byType(AquaMascot)).mood, MascotMood.thinking);
  });

  testWidgets('celebration combines celebrating Ripple and bundled burst', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        const RippleCelebrationOverlay(
          title: 'Complete',
          message: 'A fresh record was added.',
        ),
        reduceMotion: true,
      ),
    );
    await tester.pump();

    expect(find.byType(ReducedMotionLottie), findsOneWidget);
    expect(tester.widget<AquaMascot>(find.byType(AquaMascot)).mood, MascotMood.celebrating);
  });

  testWidgets('celebration Lottie paints non-transparent pixels mid-animation', (
    tester,
  ) async {
    const repaintKey = Key('celebrationLottieBoundary');
    await tester.pumpWidget(
      _app(
        const RepaintBoundary(
          key: repaintKey,
          child: SizedBox.square(
            dimension: 220,
            child: ReducedMotionLottie(
              asset: 'assets/animations/celebration-burst.json',
              semanticLabel: 'Celebration burst',
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    final boundary = tester.renderObject<RenderRepaintBoundary>(
      find.byKey(repaintKey),
    );
    final image = await boundary.toImage(pixelRatio: 1);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
    expect(bytes, isNotNull);
    final pixelBytes = bytes!;
    var paintedPixels = 0;
    for (var offset = 3; offset < pixelBytes.lengthInBytes; offset += 4) {
      if (pixelBytes.getUint8(offset) != 0) paintedPixels++;
    }
    expect(paintedPixels, greaterThan(100));
  });

  testWidgets('badges render locked, unlocked, new and reveal states', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        const Wrap(
          children: <Widget>[
            BadgeCrest(
              name: 'Locked',
              criterion: 'Do a thing',
              icon: BadgeIcon.firstSignal,
              state: BadgeState.locked,
            ),
            BadgeCrest(
              name: 'Unlocked',
              criterion: 'Done',
              icon: BadgeIcon.habitatEye,
              state: BadgeState.unlocked,
            ),
            BadgeCrest(
              name: 'Fresh',
              criterion: 'Newly done',
              icon: BadgeIcon.clearView,
              state: BadgeState.newBadge,
            ),
            BadgeUnlockReveal(
              badge: BadgeCrest(
                name: 'Reveal',
                criterion: 'Done',
                icon: BadgeIcon.streamExplorer,
                state: BadgeState.unlocked,
              ),
            ),
          ],
        ),
        reduceMotion: true,
      ),
    );

    expect(find.textContaining('Locked ·'), findsOneWidget);
    expect(find.text('NEW'), findsOneWidget);
    expect(find.byType(ReducedMotionLottie), findsOneWidget);
  });
}
