import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/tokens.dart';
import '../widgets/reduced_motion_lottie.dart';
import 'mascot_identity.dart';
import 'ripple_controller.dart';

enum MascotMood {
  idle('calm'),
  guiding('ready to guide'),
  thinking('thinking'),
  celebrating('celebrating'),
  concerned('concerned');

  const MascotMood(this.semanticDescription);
  final String semanticDescription;
}

/// Immutable drawing parameters for one Ripple expression and pose.
///
/// The original 17 values remain the mood contract. Render-v2 fields are
/// additive so gestures and narration act on the same silhouette.
@immutable
class MascotMoodSpec {
  const MascotMoodSpec({
    required this.bodyColor,
    required this.highlightColor,
    required this.tilt,
    required this.widthScale,
    required this.heightScale,
    required this.leftFinRaised,
    required this.rightFinRaised,
    required this.eyeOpenness,
    required this.pupilOffset,
    required this.smile,
    required this.mouthOpenness,
    required this.browConcern,
    required this.thinkingAccent,
    required this.sparkles,
    required this.sweatDrop,
    required this.bobAmount,
    required this.pulseAmount,
    this.outlineColor = AppColors.deepWater,
    this.bellyGlow = 0.12,
    this.irisScale = 1,
    this.eyeAimX = 0,
    this.eyeAimY = 0,
    this.lidCurve = 0,
    this.browTilt = 0,
    this.cheekOpacity = 0,
    this.mouthWidth = 1,
    this.mouthOpen = 0,
    this.viseme = 0,
    this.finCurl = 0,
    this.targetAngle = 0,
    this.squash = 0,
    this.stretch = 0,
    this.jumpPhase = 0,
    this.splashPhase = 0,
    this.entranceProgress = 1,
    this.gesturePhase = 0,
  });

  final Color bodyColor;
  final Color highlightColor;
  final double tilt;
  final double widthScale;
  final double heightScale;
  final double leftFinRaised;
  final double rightFinRaised;
  final double eyeOpenness;
  final double pupilOffset;
  final double smile;
  final double mouthOpenness;
  final double browConcern;
  final double thinkingAccent;
  final double sparkles;
  final double sweatDrop;
  final double bobAmount;
  final double pulseAmount;
  final Color outlineColor;
  final double bellyGlow;
  final double irisScale;
  final double eyeAimX;
  final double eyeAimY;
  final double lidCurve;
  final double browTilt;
  final double cheekOpacity;
  final double mouthWidth;
  final double mouthOpen;
  final double viseme;
  final double finCurl;
  final double targetAngle;
  final double squash;
  final double stretch;
  final double jumpPhase;
  final double splashPhase;
  final double entranceProgress;
  final double gesturePhase;

  static MascotMoodSpec forMood(MascotMood mood) => switch (mood) {
    MascotMood.idle => idle,
    MascotMood.guiding => guiding,
    MascotMood.thinking => thinking,
    MascotMood.celebrating => celebrating,
    MascotMood.concerned => concerned,
  };

  static const MascotMoodSpec idle = MascotMoodSpec(
    bodyColor: AppColors.water,
    highlightColor: AppColors.waterLight,
    tilt: 0,
    widthScale: 1,
    heightScale: 1,
    leftFinRaised: 0.1,
    rightFinRaised: 0.1,
    eyeOpenness: 1,
    pupilOffset: 0,
    smile: 0.55,
    mouthOpenness: 0,
    browConcern: 0,
    thinkingAccent: 0,
    sparkles: 0,
    sweatDrop: 0,
    bobAmount: 1,
    pulseAmount: 0.2,
    cheekOpacity: 0.45,
  );

  static const MascotMoodSpec guiding = MascotMoodSpec(
    bodyColor: AppColors.deepWater,
    highlightColor: AppColors.water,
    tilt: 0.08,
    widthScale: 1,
    heightScale: 1,
    leftFinRaised: 0.1,
    rightFinRaised: 1,
    eyeOpenness: 1,
    pupilOffset: 0.22,
    smile: 0.72,
    mouthOpenness: 0,
    browConcern: 0,
    thinkingAccent: 0,
    sparkles: 0,
    sweatDrop: 0,
    bobAmount: 0.45,
    pulseAmount: 0,
    cheekOpacity: 0.48,
  );

  static const MascotMoodSpec thinking = MascotMoodSpec(
    bodyColor: AppColors.water,
    highlightColor: AppColors.waterLight,
    tilt: -0.05,
    widthScale: 0.98,
    heightScale: 1.02,
    leftFinRaised: 0.3,
    rightFinRaised: 0.18,
    eyeOpenness: 0.78,
    pupilOffset: -0.18,
    smile: 0.12,
    mouthOpenness: 0,
    browConcern: 0,
    thinkingAccent: 1,
    sparkles: 0,
    sweatDrop: 0,
    bobAmount: 0.25,
    pulseAmount: 1,
    eyeAimY: -0.16,
    lidCurve: 0.2,
  );

  static const MascotMoodSpec celebrating = MascotMoodSpec(
    bodyColor: AppColors.water,
    highlightColor: AppColors.waterLight,
    tilt: 0,
    widthScale: 1.06,
    heightScale: 0.96,
    leftFinRaised: 1,
    rightFinRaised: 1,
    eyeOpenness: 0.18,
    pupilOffset: 0,
    smile: 1,
    mouthOpenness: 1,
    browConcern: 0,
    thinkingAccent: 0,
    sparkles: 1,
    sweatDrop: 0,
    bobAmount: 0.65,
    pulseAmount: 0.7,
    cheekOpacity: 0.68,
    mouthWidth: 1.08,
  );

  static const MascotMoodSpec concerned = MascotMoodSpec(
    bodyColor: AppColors.deepWater,
    highlightColor: AppColors.water,
    tilt: -0.04,
    widthScale: 0.97,
    heightScale: 1,
    leftFinRaised: 0.18,
    rightFinRaised: 0.32,
    eyeOpenness: 0.95,
    pupilOffset: -0.08,
    smile: -0.55,
    mouthOpenness: 0,
    browConcern: 1,
    thinkingAccent: 0,
    sparkles: 0,
    sweatDrop: 1,
    bobAmount: 0.12,
    pulseAmount: 0,
    browTilt: 1,
    lidCurve: 0.15,
  );

  static MascotMoodSpec lerp(
    MascotMoodSpec begin,
    MascotMoodSpec end,
    double t,
  ) {
    final unitT = t.clamp(0.0, 1.0).toDouble();
    double value(double a, double b) => a + (b - a) * t;
    double unit(double a, double b) => a + (b - a) * unitT;
    return MascotMoodSpec(
      bodyColor: Color.lerp(begin.bodyColor, end.bodyColor, unitT)!,
      highlightColor: Color.lerp(begin.highlightColor, end.highlightColor, unitT)!,
      outlineColor: Color.lerp(begin.outlineColor, end.outlineColor, unitT)!,
      tilt: value(begin.tilt, end.tilt),
      widthScale: value(begin.widthScale, end.widthScale),
      heightScale: value(begin.heightScale, end.heightScale),
      leftFinRaised: value(begin.leftFinRaised, end.leftFinRaised),
      rightFinRaised: value(begin.rightFinRaised, end.rightFinRaised),
      eyeOpenness: value(begin.eyeOpenness, end.eyeOpenness),
      pupilOffset: value(begin.pupilOffset, end.pupilOffset),
      smile: value(begin.smile, end.smile),
      mouthOpenness: value(begin.mouthOpenness, end.mouthOpenness),
      browConcern: unit(begin.browConcern, end.browConcern),
      thinkingAccent: unit(begin.thinkingAccent, end.thinkingAccent),
      sparkles: unit(begin.sparkles, end.sparkles),
      sweatDrop: unit(begin.sweatDrop, end.sweatDrop),
      bobAmount: value(begin.bobAmount, end.bobAmount),
      pulseAmount: value(begin.pulseAmount, end.pulseAmount),
      bellyGlow: unit(begin.bellyGlow, end.bellyGlow),
      irisScale: value(begin.irisScale, end.irisScale),
      eyeAimX: value(begin.eyeAimX, end.eyeAimX),
      eyeAimY: value(begin.eyeAimY, end.eyeAimY),
      lidCurve: unit(begin.lidCurve, end.lidCurve),
      browTilt: value(begin.browTilt, end.browTilt),
      cheekOpacity: unit(begin.cheekOpacity, end.cheekOpacity),
      mouthWidth: value(begin.mouthWidth, end.mouthWidth),
      mouthOpen: unit(begin.mouthOpen, end.mouthOpen),
      viseme: unit(begin.viseme, end.viseme),
      finCurl: value(begin.finCurl, end.finCurl),
      targetAngle: value(begin.targetAngle, end.targetAngle),
      squash: value(begin.squash, end.squash),
      stretch: value(begin.stretch, end.stretch),
      jumpPhase: unit(begin.jumpPhase, end.jumpPhase),
      splashPhase: unit(begin.splashPhase, end.splashPhase),
      entranceProgress: unit(begin.entranceProgress, end.entranceProgress),
      gesturePhase: unit(begin.gesturePhase, end.gesturePhase),
    );
  }
}

/// Ripple, a code-drawn water companion with smoothly morphing moods.
class AquaMascot extends StatefulWidget {
  const AquaMascot({
    super.key,
    required this.mood,
    this.size = 160,
    this.controller,
    this.pauseAnimations = false,
  });

  final MascotMood mood;
  final double size;
  final RippleController? controller;
  final bool pauseAnimations;

  @override
  State<AquaMascot> createState() => _AquaMascotState();
}

class _AquaMascotState extends State<AquaMascot> with TickerProviderStateMixin {
  late final AnimationController _morphController;
  late final AnimationController _ambientController;
  late final AnimationController _gestureController;
  late final AnimationController _visemeController;
  late MascotMoodSpec _fromSpec;
  late MascotMoodSpec _toSpec;
  RippleVisemeFrame _fromViseme = RippleVisemeFrame.rest;
  RippleVisemeFrame _toViseme = RippleVisemeFrame.rest;
  RippleGesture _gesture = RippleGesture.none;
  Offset _target = const Offset(1, 0);
  int _gestureGeneration = -1;
  Curve _morphCurve = AppMotion.moodCurve;
  bool? _reduceMotion;

  @override
  void initState() {
    super.initState();
    _fromSpec = MascotMoodSpec.forMood(widget.mood);
    _toSpec = _fromSpec;
    _morphController = AnimationController(
      vsync: this,
      duration: AppMotion.moodMorph,
      value: 1,
    );
    _ambientController = AnimationController(
      vsync: this,
      duration: AppMotion.ambientLoop,
    );
    _gestureController = AnimationController(vsync: this);
    _visemeController = AnimationController(
      vsync: this,
      duration: AppMotion.visemeSmoothing,
      value: 1,
    );
    widget.controller?.addListener(_handleRippleCommand);
    _handleRippleCommand();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduceMotion = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    if (_reduceMotion == reduceMotion) return;
    _reduceMotion = reduceMotion;
    _syncMotionPreference();
  }

  @override
  void didUpdateWidget(covariant AquaMascot oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller?.removeListener(_handleRippleCommand);
      widget.controller?.addListener(_handleRippleCommand);
      _handleRippleCommand();
    }
    if (oldWidget.pauseAnimations != widget.pauseAnimations) {
      _syncMotionPreference();
    }
    if (oldWidget.mood == widget.mood) return;
    _fromSpec = _displayedSpec;
    _toSpec = MascotMoodSpec.forMood(widget.mood);
    _morphCurve = widget.mood == MascotMood.celebrating
        ? AppMotion.celebrationCurve
        : AppMotion.moodCurve;
    _morphController.duration = widget.mood == MascotMood.celebrating
        ? AppMotion.celebrationEntrance
        : AppMotion.moodMorph;
    if (_reduceMotion ?? false) {
      _fromSpec = _toSpec;
      _morphController.value = 1;
    } else {
      _morphController.forward(from: 0);
    }
  }

  MascotMoodSpec get _displayedSpec => MascotMoodSpec.lerp(
    _fromSpec,
    _toSpec,
    _morphCurve.transform(_morphController.value),
  );

  RippleVisemeFrame get _displayedViseme => RippleVisemeSmoother.sample(
    begin: _fromViseme,
    end: _toViseme,
    elapsed: AppMotion.visemeSmoothing * _visemeController.value,
    duration: AppMotion.visemeSmoothing,
  );

  void _syncMotionPreference() {
    final pause = (_reduceMotion ?? false) || widget.pauseAnimations;
    if (pause) {
      _ambientController
        ..stop()
        ..value = 0;
      _gestureController.stop();
      if (_reduceMotion ?? false) {
        _morphController.value = 1;
        _gestureController.value = 1;
        _visemeController.value = 1;
      }
    } else {
      _ambientController.repeat();
      _startGestureAnimation();
    }
  }

  void _handleRippleCommand() {
    final controller = widget.controller;
    if (controller == null) return;
    final gestureChanged = _gesture != controller.gesture;
    final nextViseme = RippleVisemeFrame.forViseme(controller.viseme);
    if (nextViseme != _toViseme) {
      _fromViseme = _displayedViseme;
      _toViseme = nextViseme;
      if (_reduceMotion ?? false) {
        _visemeController.value = 1;
      } else {
        _visemeController.forward(from: 0);
      }
    }
    _gesture = controller.gesture;
    _target = controller.target;
    if (_gestureGeneration != controller.gestureGeneration) {
      _gestureGeneration = controller.gestureGeneration;
      _startGestureAnimation();
    }
    if (gestureChanged && mounted) setState(() {});
  }

  void _startGestureAnimation() {
    final controller = widget.controller;
    if (controller == null ||
        _gesture == RippleGesture.none ||
        _gesture == RippleGesture.talk ||
        widget.pauseAnimations) {
      _gestureController
        ..stop()
        ..value = _gesture == RippleGesture.none ? 0 : 1;
      return;
    }
    _gestureController.duration = _gesture.duration;
    if (_reduceMotion ?? false) {
      _gestureController.value = 1;
    } else if (controller.loop) {
      _gestureController.repeat();
    } else {
      _gestureController.forward(from: 0);
    }
  }

  @override
  void dispose() {
    widget.controller?.removeListener(_handleRippleCommand);
    _morphController.dispose();
    _ambientController.dispose();
    _gestureController.dispose();
    _visemeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final label = _gesture == RippleGesture.none
        ? '${MascotIdentity.displayName} is ${widget.mood.semanticDescription}'
        : '${MascotIdentity.displayName} is ${_gesture.semanticDescription}';
    return Semantics(
      image: true,
      label: label,
      child: RepaintBoundary(
        child: SizedBox(
          width: widget.size,
          height: widget.size * 1.16,
          child: Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: <Widget>[
              if (_gesture == RippleGesture.jump)
                Positioned(
                  left: -widget.size * 0.18,
                  right: -widget.size * 0.18,
                  bottom: -widget.size * 0.12,
                  height: widget.size * 0.72,
                  child: IgnorePointer(
                    child: ReducedMotionLottie(
                      asset: 'assets/animations/celebration-burst.json',
                      semanticLabel: 'Water splash',
                      replayKey: _gestureGeneration,
                    ),
                  ),
                ),
              Positioned.fill(
                child: AnimatedBuilder(
                  animation: Listenable.merge(<Listenable>[
                    _morphController,
                    _ambientController,
                    _gestureController,
                    _visemeController,
                  ]),
                  builder: (context, child) => CustomPaint(
                    painter: AquaMascotPainter(
                      spec: _displayedSpec,
                      ambientPhase: (_reduceMotion ?? false)
                          ? 0
                          : _ambientController.value,
                      gesture: _gesture,
                      gesturePhase: (_reduceMotion ?? false)
                          ? 1
                          : _gestureController.value,
                      target: _target,
                      viseme: _displayedViseme,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

extension on RippleGesture {
  String get semanticDescription => switch (this) {
    RippleGesture.none => 'still',
    RippleGesture.wave => 'waving hello',
    RippleGesture.point => 'pointing',
    RippleGesture.nod => 'nodding',
    RippleGesture.jump => 'jumping with joy',
    RippleGesture.swimIn => 'swimming in',
    RippleGesture.talk => 'talking',
  };
}

@visibleForTesting
class AquaMascotPainter extends CustomPainter {
  const AquaMascotPainter({
    required this.spec,
    required this.ambientPhase,
    this.gesture = RippleGesture.none,
    this.gesturePhase = 0,
    this.target = const Offset(1, 0),
    this.viseme = RippleVisemeFrame.rest,
  });

  final MascotMoodSpec spec;
  final double ambientPhase;
  final RippleGesture gesture;
  final double gesturePhase;
  final Offset target;
  final RippleVisemeFrame viseme;
  static const double _designWidth = 200;
  static const double _designHeight = 232;

  @override
  void paint(Canvas canvas, Size size) {
    final scale = math.min(size.width / _designWidth, size.height / _designHeight);
    canvas
      ..save()
      ..translate(
        (size.width - _designWidth * scale) / 2,
        (size.height - _designHeight * scale) / 2,
      )
      ..scale(scale);
    final wave = math.sin(ambientPhase * math.pi * 2);
    final pose = _gesturePose(gesturePhase);
    final bob = wave * 3 * spec.bobAmount + pose.translate.dy;
    final pulse = 1 + wave * 0.018 * spec.pulseAmount;
    _drawGroundShadow(canvas, bob, pose.opacity);
    canvas
      ..saveLayer(
        const Rect.fromLTWH(-60, -60, 320, 340),
        Paint()..color = AppColors.white.withValues(alpha: pose.opacity),
      )
      ..translate(pose.translate.dx, 0)
      ..translate(100, 116 + bob)
      ..rotate(spec.tilt + pose.rotation)
      ..scale(
        spec.widthScale * pulse * pose.scaleX,
        spec.heightScale / pulse * pose.scaleY,
      )
      ..translate(-100, -116);
    final fins = _gestureFins();
    _drawFin(
      canvas,
      isLeft: true,
      raised: spec.leftFinRaised + fins.$1,
      targetAngle: fins.$3,
    );
    _drawFin(
      canvas,
      isLeft: false,
      raised: spec.rightFinRaised + fins.$2,
      targetAngle: fins.$4,
    );
    _drawBody(canvas);
    _drawFace(canvas);
    _drawSweatDrop(canvas);
    _drawThinkingAccent(canvas);
    _drawSparkles(canvas, wave);
    canvas.restore();
    canvas.restore();
  }

  _RipplePose _gesturePose(double phase) {
    switch (gesture) {
      case RippleGesture.nod:
        final pulse = math.sin(phase * math.pi * 2);
        return _RipplePose(
          translate: Offset(0, math.max(0.0, pulse) * 4),
          rotation: pulse * 0.08,
          scaleX: 1 + math.max(0.0, pulse) * 0.025,
          scaleY: 1 - math.max(0.0, pulse) * 0.035,
        );
      case RippleGesture.jump:
        final lift = math.sin(phase * math.pi);
        final landing = math.exp(-math.pow((phase - 0.84) * 13, 2)) * 0.08;
        final launch = math.exp(-math.pow((phase - 0.12) * 11, 2)) * 0.08;
        return _RipplePose(
          translate: Offset(0, -28 * math.max(0.0, lift)),
          scaleX: 1 + launch + landing - lift * 0.035,
          scaleY: 1 - launch - landing + lift * 0.06,
        );
      case RippleGesture.swimIn:
        final t = Curves.easeOutCubic.transform(
          phase.clamp(0.0, 1.0).toDouble(),
        );
        return _RipplePose(
          translate: Offset(-92 * (1 - t), 24 * (1 - t)),
          rotation: -0.28 * (1 - t) + math.sin(t * math.pi) * 0.04,
          scaleX: 0.78 + 0.22 * t,
          scaleY: 0.78 + 0.22 * t,
          opacity: t,
        );
      case RippleGesture.none:
      case RippleGesture.wave:
      case RippleGesture.point:
      case RippleGesture.talk:
        return const _RipplePose();
    }
  }

  (double, double, double?, double?) _gestureFins() {
    final oscillation = (math.sin(gesturePhase * math.pi * 4) + 1) / 2;
    switch (gesture) {
      case RippleGesture.wave:
        return (0, 0.18 + oscillation * 0.72, null, null);
      case RippleGesture.point:
        final angle = math.atan2(target.dy, target.dx);
        return target.dx < 0
            ? (0.72, 0, angle, null)
            : (0, 0.72, null, angle);
      case RippleGesture.swimIn:
        return (oscillation * 0.28, (1 - oscillation) * 0.28, null, null);
      case RippleGesture.none:
      case RippleGesture.nod:
      case RippleGesture.jump:
      case RippleGesture.talk:
        return (0, 0, null, null);
    }
  }

  void _drawGroundShadow(Canvas canvas, double bob, double opacity) {
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(100, 218 - bob * 0.12),
        width: math.max(56.0, 96 - bob.abs() * 1.5),
        height: 14,
      ),
      Paint()
        ..color = AppColors.navy.withValues(alpha: 0.13 * opacity)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );
  }

  Path get _bodyPath => Path()
    ..moveTo(100, 16)
    ..cubicTo(91, 43, 42, 74, 42, 132)
    ..cubicTo(42, 178, 67, 207, 100, 207)
    ..cubicTo(137, 207, 158, 178, 158, 132)
    ..cubicTo(158, 75, 111, 43, 100, 16)
    ..close();

  void _drawBody(Canvas canvas) {
    final body = _bodyPath;
    canvas.drawPath(
      body.shift(const Offset(0, 4)),
      Paint()
        ..color = AppColors.navy.withValues(alpha: 0.2)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
    );
    canvas.drawPath(
      body,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            AppColors.foam,
            spec.highlightColor,
            spec.bodyColor,
            AppColors.deepWater,
          ],
          stops: const <double>[0, 0.28, 0.78, 1],
        ).createShader(const Rect.fromLTWH(38, 14, 124, 196)),
    );
    canvas.drawPath(
      body,
      Paint()
        ..color = spec.outlineColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4
        ..strokeJoin = StrokeJoin.round,
    );
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(105, 166), width: 72, height: 56),
      Paint()..color = AppColors.foam.withValues(alpha: spec.bellyGlow),
    );
    canvas.drawPath(
      Path()
        ..moveTo(77, 53)
        ..cubicTo(60, 75, 54, 101, 55, 122),
      Paint()
        ..color = AppColors.white.withValues(alpha: 0.55)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 8
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawPath(
      Path()
        ..moveTo(69, 87)
        ..cubicTo(76, 75, 82, 70, 87, 66),
      Paint()
        ..color = AppColors.white.withValues(alpha: 0.24)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round,
    );
  }

  void _drawFin(
    Canvas canvas, {
    required bool isLeft,
    required double raised,
    required double? targetAngle,
  }) {
    final direction = isLeft ? -1.0 : 1.0;
    final pivot = Offset(isLeft ? 49 : 151, 137);
    final clampedRaised = raised.clamp(0.0, 1.35).toDouble();
    final baseAngle = direction * (0.12 - clampedRaised * 1.22);
    final angle = targetAngle == null
        ? baseAngle
        : targetAngle + (isLeft ? math.pi : 0);
    canvas
      ..save()
      ..translate(pivot.dx, pivot.dy)
      ..rotate(angle);
    final curl = spec.finCurl * 7;
    final fin = Path()
      ..moveTo(0, 0)
      ..cubicTo(
        direction * 15,
        -18 - curl,
        direction * 40,
        -18 + curl,
        direction * 48,
        2,
      )
      ..cubicTo(direction * 30, 17, direction * 12, 16, 0, 0)
      ..close();
    final bounds = Rect.fromLTWH(isLeft ? -50 : 0, -22, 50, 42);
    canvas.drawPath(
      fin,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[AppColors.sageLight, AppColors.sage],
        ).createShader(bounds),
    );
    canvas.drawPath(
      fin,
      Paint()
        ..color = AppColors.deepWater
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeJoin = StrokeJoin.round,
    );
    canvas.drawPath(
      Path()
        ..moveTo(direction * 8, 1)
        ..quadraticBezierTo(direction * 25, -2, direction * 39, 1),
      Paint()
        ..color = AppColors.foam.withValues(alpha: 0.72)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round,
    );
    canvas.restore();
  }

  void _drawFace(Canvas canvas) {
    var aimX = spec.eyeAimX + spec.pupilOffset;
    var aimY = spec.eyeAimY;
    if (gesture == RippleGesture.wave) aimX += 0.18;
    if (gesture == RippleGesture.point) {
      aimX += target.dx * 0.42;
      aimY += target.dy * 0.35;
    }
    final eyeHeight = 15 * math.max(0.08, spec.eyeOpenness).toDouble();
    for (final x in <double>[78, 122]) {
      if (spec.eyeOpenness < 0.25) {
        final eye = Path()
          ..moveTo(x - 8, 124)
          ..quadraticBezierTo(x, 130 - spec.lidCurve * 3, x + 8, 124);
        canvas.drawPath(
          eye,
          Paint()
            ..color = AppColors.navy
            ..style = PaintingStyle.stroke
            ..strokeWidth = 3
            ..strokeCap = StrokeCap.round,
        );
        continue;
      }
      final eyeRect = Rect.fromCenter(
        center: Offset(x, 124),
        width: 17,
        height: eyeHeight,
      );
      canvas.drawOval(eyeRect, Paint()..color = AppColors.foam);
      canvas.drawOval(
        eyeRect,
        Paint()
          ..color = AppColors.navy
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5,
      );
      final irisCenter = Offset(x + aimX * 6, 126 + aimY * 6);
      canvas.drawOval(
        Rect.fromCenter(
          center: irisCenter,
          width: 8.4 * spec.irisScale,
          height: math.max(2.8, eyeHeight * 0.64) * spec.irisScale,
        ),
        Paint()..color = AppColors.navy,
      );
      canvas.drawCircle(
        irisCenter.translate(-2.1, -2.6),
        1.65,
        Paint()..color = AppColors.white,
      );
    }
    if (spec.browConcern > 0 || spec.browTilt != 0) {
      final opacity = math
          .max(spec.browConcern, spec.browTilt.abs())
          .clamp(0.0, 1.0)
          .toDouble();
      final drop = (5 * math.max(spec.browConcern, spec.browTilt)).toDouble();
      final browPaint = Paint()
        ..color = AppColors.navy.withValues(alpha: opacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.5
        ..strokeCap = StrokeCap.round;
      canvas
        ..drawLine(Offset(67, 106 + drop), const Offset(85, 101), browPaint)
        ..drawLine(const Offset(115, 101), Offset(133, 106 + drop), browPaint);
    }
    final cheekOpacity = math.max(
      spec.cheekOpacity,
      spec.smile > 0.2 ? 0.34 + spec.smile * 0.11 : 0.0,
    );
    if (cheekOpacity > 0) {
      final cheekPaint = Paint()
        ..color = AppColors.peach.withValues(
          alpha: cheekOpacity.clamp(0.0, 0.72).toDouble(),
        );
      canvas
        ..drawOval(
          Rect.fromCenter(center: const Offset(67, 147), width: 16, height: 8),
          cheekPaint,
        )
        ..drawOval(
          Rect.fromCenter(center: const Offset(133, 147), width: 16, height: 8),
          cheekPaint,
        );
    }
    _drawMouth(canvas);
  }

  void _drawMouth(Canvas canvas) {
    final talkOpen = gesture == RippleGesture.talk ? viseme.open : 0.0;
    final openness = math.max(
      math.max(spec.mouthOpenness, spec.mouthOpen),
      talkOpen,
    );
    final widthScale = spec.mouthWidth *
        (gesture == RippleGesture.talk ? viseme.width : 1);
    final openBlend = ((openness - 0.08) / 0.42)
        .clamp(0.0, 1.0)
        .toDouble();
    if (openBlend < 1) {
      final mouth = Path()
        ..moveTo(100 - 16 * widthScale, 153)
        ..quadraticBezierTo(
          100,
          153 + spec.smile * 14,
          100 + 16 * widthScale,
          153,
        );
      canvas.drawPath(
        mouth,
        Paint()
          ..color = AppColors.navy.withValues(alpha: 1 - openBlend)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 4.5
          ..strokeCap = StrokeCap.round,
      );
    }
    if (openBlend <= 0) return;
    final height = 9 + 24 * openness;
    final mouth = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: const Offset(100, 158),
        width: 42 * widthScale,
        height: height,
      ),
      Radius.circular(math.min(17.0, height / 2)),
    );
    canvas.drawRRect(
      mouth,
      Paint()..color = AppColors.navy.withValues(alpha: openBlend),
    );
    canvas
      ..save()
      ..clipRRect(mouth)
      ..drawArc(
        Rect.fromCenter(
          center: Offset(100, 162 + height * 0.18),
          width: 27 * widthScale,
          height: 11,
        ),
        0,
        math.pi,
        true,
        Paint()..color = AppColors.peach.withValues(alpha: openBlend),
      )
      ..restore();
  }

  void _drawSweatDrop(Canvas canvas) {
    if (spec.sweatDrop <= 0) return;
    final drop = Path()
      ..moveTo(146, 98)
      ..quadraticBezierTo(164, 120, 146, 117)
      ..quadraticBezierTo(128, 113, 146, 98)
      ..close();
    canvas.drawPath(
      drop,
      Paint()..color = AppColors.waterLight.withValues(alpha: spec.sweatDrop),
    );
    canvas.drawPath(
      drop,
      Paint()
        ..color = AppColors.deepWater.withValues(alpha: spec.sweatDrop)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  void _drawThinkingAccent(Canvas canvas) {
    if (spec.thinkingAccent <= 0) return;
    final angle = ambientPhase * math.pi * 2;
    final paint = Paint()
      ..color = AppColors.peach.withValues(alpha: spec.thinkingAccent);
    for (var index = 0; index < 3; index++) {
      final itemAngle = angle + index * math.pi * 2 / 3;
      canvas.drawCircle(
        Offset(100 + math.cos(itemAngle) * 78, 72 + math.sin(itemAngle) * 20),
        4 + index * 1.5,
        paint,
      );
    }
  }

  void _drawSparkles(Canvas canvas, double wave) {
    if (spec.sparkles <= 0) return;
    final scale = spec.sparkles * (1 + wave * 0.12);
    final paint = Paint()
      ..color = AppColors.sparkle.withValues(alpha: spec.sparkles);
    for (final center in const <Offset>[
      Offset(25, 60),
      Offset(174, 48),
      Offset(184, 125),
      Offset(18, 132),
    ]) {
      final sparkle = Path()
        ..moveTo(center.dx, center.dy - 9 * scale)
        ..lineTo(center.dx + 3 * scale, center.dy - 3 * scale)
        ..lineTo(center.dx + 9 * scale, center.dy)
        ..lineTo(center.dx + 3 * scale, center.dy + 3 * scale)
        ..lineTo(center.dx, center.dy + 9 * scale)
        ..lineTo(center.dx - 3 * scale, center.dy + 3 * scale)
        ..lineTo(center.dx - 9 * scale, center.dy)
        ..lineTo(center.dx - 3 * scale, center.dy - 3 * scale)
        ..close();
      canvas.drawPath(sparkle, paint);
    }
  }

  @override
  bool shouldRepaint(covariant AquaMascotPainter oldDelegate) =>
      oldDelegate.spec != spec ||
      oldDelegate.ambientPhase != ambientPhase ||
      oldDelegate.gesture != gesture ||
      oldDelegate.gesturePhase != gesturePhase ||
      oldDelegate.target != target ||
      oldDelegate.viseme != viseme;
}

@immutable
class _RipplePose {
  const _RipplePose({
    this.translate = Offset.zero,
    this.rotation = 0,
    this.scaleX = 1,
    this.scaleY = 1,
    this.opacity = 1,
  });
  final Offset translate;
  final double rotation;
  final double scaleX;
  final double scaleY;
  final double opacity;
}
