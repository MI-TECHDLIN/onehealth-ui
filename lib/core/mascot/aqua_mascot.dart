import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/tokens.dart';
import 'mascot_identity.dart';

enum MascotMood {
  idle('calm'),
  guiding('ready to guide'),
  thinking('thinking'),
  celebrating('celebrating'),
  concerned('concerned');

  const MascotMood(this.semanticDescription);

  final String semanticDescription;
}

/// Immutable drawing parameters for one mascot expression and pose.
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
    pulseAmount: 0.4,
  );

  static const MascotMoodSpec guiding = MascotMoodSpec(
    bodyColor: AppColors.deepWater,
    highlightColor: AppColors.water,
    tilt: 0.08,
    widthScale: 0.98,
    heightScale: 1.02,
    leftFinRaised: 0.2,
    rightFinRaised: 1,
    eyeOpenness: 1,
    pupilOffset: 0.22,
    smile: 0.65,
    mouthOpenness: 0.15,
    browConcern: 0,
    thinkingAccent: 0,
    sparkles: 0,
    sweatDrop: 0,
    bobAmount: 0.45,
    pulseAmount: 0.15,
  );

  static const MascotMoodSpec thinking = MascotMoodSpec(
    bodyColor: AppColors.water,
    highlightColor: AppColors.waterLight,
    tilt: -0.05,
    widthScale: 1,
    heightScale: 0.98,
    leftFinRaised: 0.35,
    rightFinRaised: 0.55,
    eyeOpenness: 0.78,
    pupilOffset: 0.18,
    smile: 0.08,
    mouthOpenness: 0,
    browConcern: 0,
    thinkingAccent: 1,
    sparkles: 0,
    sweatDrop: 0,
    bobAmount: 0.25,
    pulseAmount: 1,
  );

  static const MascotMoodSpec celebrating = MascotMoodSpec(
    bodyColor: AppColors.water,
    highlightColor: AppColors.waterLight,
    tilt: 0,
    widthScale: 1.06,
    heightScale: 0.96,
    leftFinRaised: 1,
    rightFinRaised: 1,
    eyeOpenness: 0.08,
    pupilOffset: 0,
    smile: 1,
    mouthOpenness: 1,
    browConcern: 0,
    thinkingAccent: 0,
    sparkles: 1,
    sweatDrop: 0,
    bobAmount: 0.65,
    pulseAmount: 0.7,
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
  );

  static MascotMoodSpec lerp(
    MascotMoodSpec begin,
    MascotMoodSpec end,
    double t,
  ) {
    final unitT = t.clamp(0.0, 1.0);
    double value(double a, double b) => a + (b - a) * t;
    double unit(double a, double b) => a + (b - a) * unitT;

    return MascotMoodSpec(
      bodyColor: Color.lerp(begin.bodyColor, end.bodyColor, unitT)!,
      highlightColor: Color.lerp(
        begin.highlightColor,
        end.highlightColor,
        unitT,
      )!,
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
    );
  }
}

/// A lightweight, code-drawn water companion with smoothly morphing moods.
class AquaMascot extends StatefulWidget {
  const AquaMascot({super.key, required this.mood, this.size = 160});

  final MascotMood mood;
  final double size;

  @override
  State<AquaMascot> createState() => _AquaMascotState();
}

class _AquaMascotState extends State<AquaMascot> with TickerProviderStateMixin {
  late final AnimationController _morphController;
  late final AnimationController _ambientController;
  late MascotMoodSpec _fromSpec;
  late MascotMoodSpec _toSpec;
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
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    if (_reduceMotion == reduceMotion) return;

    _reduceMotion = reduceMotion;
    if (reduceMotion) {
      _morphController.value = 1;
      _ambientController.stop();
      _ambientController.value = 0;
    } else {
      _ambientController.repeat();
    }
  }

  @override
  void didUpdateWidget(covariant AquaMascot oldWidget) {
    super.didUpdateWidget(oldWidget);
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

  MascotMoodSpec get _displayedSpec {
    final progress = _morphCurve.transform(_morphController.value);
    return MascotMoodSpec.lerp(_fromSpec, _toSpec, progress);
  }

  @override
  void dispose() {
    _morphController.dispose();
    _ambientController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      image: true,
      label:
          '${MascotIdentity.displayName} is ${widget.mood.semanticDescription}',
      child: RepaintBoundary(
        child: SizedBox(
          width: widget.size,
          height: widget.size * 1.16,
          child: AnimatedBuilder(
            animation: Listenable.merge(<Listenable>[
              _morphController,
              _ambientController,
            ]),
            builder: (context, child) => CustomPaint(
              painter: AquaMascotPainter(
                spec: _displayedSpec,
                ambientPhase: (_reduceMotion ?? false)
                    ? 0
                    : _ambientController.value,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

@visibleForTesting
class AquaMascotPainter extends CustomPainter {
  const AquaMascotPainter({required this.spec, required this.ambientPhase});

  final MascotMoodSpec spec;
  final double ambientPhase;

  static const double _designWidth = 200;
  static const double _designHeight = 232;

  @override
  void paint(Canvas canvas, Size size) {
    final scale = math.min(
      size.width / _designWidth,
      size.height / _designHeight,
    );
    canvas
      ..save()
      ..translate(
        (size.width - _designWidth * scale) / 2,
        (size.height - _designHeight * scale) / 2,
      )
      ..scale(scale);

    final wave = math.sin(ambientPhase * math.pi * 2);
    final bob = wave * 3 * spec.bobAmount;
    final pulse = 1 + wave * 0.018 * spec.pulseAmount;

    _drawGroundShadow(canvas, bob);

    canvas
      ..save()
      ..translate(100, 116 + bob)
      ..rotate(spec.tilt)
      ..scale(spec.widthScale * pulse, spec.heightScale / pulse)
      ..translate(-100, -116);

    _drawFin(canvas, isLeft: true, raised: spec.leftFinRaised);
    _drawFin(canvas, isLeft: false, raised: spec.rightFinRaised);
    _drawBody(canvas);
    _drawFace(canvas);
    _drawSweatDrop(canvas);
    canvas.restore();

    _drawThinkingAccent(canvas);
    _drawSparkles(canvas, wave);
    canvas.restore();
  }

  void _drawGroundShadow(Canvas canvas, double bob) {
    final paint = Paint()
      ..color = AppColors.navy.withValues(alpha: 0.12)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(100, 218 - bob * 0.25),
        width: 92 - bob.abs() * 2,
        height: 13,
      ),
      paint,
    );
  }

  void _drawBody(Canvas canvas) {
    final body = Path()
      ..moveTo(100, 16)
      ..cubicTo(91, 43, 42, 74, 42, 132)
      ..cubicTo(42, 178, 67, 207, 100, 207)
      ..cubicTo(137, 207, 158, 178, 158, 132)
      ..cubicTo(158, 75, 111, 43, 100, 16)
      ..close();

    final bodyPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: <Color>[spec.highlightColor, spec.bodyColor],
        stops: const <double>[0, 0.72],
      ).createShader(const Rect.fromLTWH(38, 14, 124, 196));
    canvas.drawPath(body, bodyPaint);

    final sheen = Paint()
      ..color = AppColors.white.withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 7
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(
      Path()
        ..moveTo(78, 55)
        ..cubicTo(59, 78, 54, 104, 55, 125),
      sheen,
    );
  }

  void _drawFin(Canvas canvas, {required bool isLeft, required double raised}) {
    final direction = isLeft ? -1.0 : 1.0;
    final pivot = Offset(isLeft ? 49 : 151, 137);
    final angle = direction * (0.12 - raised * 1.22);

    canvas
      ..save()
      ..translate(pivot.dx, pivot.dy)
      ..rotate(angle);

    final fin = Path()
      ..moveTo(0, 0)
      ..cubicTo(direction * 15, -18, direction * 40, -18, direction * 48, 2)
      ..cubicTo(direction * 30, 17, direction * 12, 16, 0, 0)
      ..close();
    canvas.drawPath(fin, Paint()..color = AppColors.sage);
    canvas.drawPath(
      Path()
        ..moveTo(direction * 8, 1)
        ..quadraticBezierTo(direction * 25, -2, direction * 39, 1),
      Paint()
        ..color = AppColors.sageLight.withValues(alpha: 0.7)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round,
    );
    canvas.restore();
  }

  void _drawFace(Canvas canvas) {
    final facePaint = Paint()..color = AppColors.navy;
    final eyeHeight = 13 * math.max(0.1, spec.eyeOpenness).toDouble();
    for (final x in <double>[79, 121]) {
      canvas.drawOval(
        Rect.fromCenter(center: Offset(x, 125), width: 11, height: eyeHeight),
        facePaint,
      );
      if (spec.eyeOpenness > 0.35) {
        canvas.drawCircle(
          Offset(x + spec.pupilOffset * 5, 122),
          2.2,
          Paint()..color = AppColors.white.withValues(alpha: 0.82),
        );
      }
    }

    if (spec.browConcern > 0) {
      final browPaint = Paint()
        ..color = AppColors.navy.withValues(alpha: spec.browConcern)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round;
      canvas
        ..drawLine(const Offset(69, 108), const Offset(86, 104), browPaint)
        ..drawLine(const Offset(114, 104), const Offset(131, 108), browPaint);
    }

    final open = ((spec.mouthOpenness - 0.28) / 0.3).clamp(0.0, 1.0);
    if (open < 1) {
      final mouthPaint = Paint()
        ..color = AppColors.navy.withValues(alpha: 1 - open)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4
        ..strokeCap = StrokeCap.round;
      final mouth = Path()
        ..moveTo(85, 153)
        ..quadraticBezierTo(100, 153 + spec.smile * 14, 115, 153);
      canvas.drawPath(mouth, mouthPaint);
    }
    if (open <= 0) return;

    final height = (8 + 23 * spec.mouthOpenness) * open;
    final mouth = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: const Offset(100, 158),
        width: 39,
        height: height,
      ),
      const Radius.circular(AppRadii.md),
    );
    canvas.drawRRect(
      mouth,
      Paint()..color = AppColors.navy.withValues(alpha: open),
    );
    canvas.save();
    canvas.clipRRect(mouth);
    canvas.drawArc(
      Rect.fromCenter(
        center: Offset(100, 162 + height * 0.18),
        width: 26,
        height: 10,
      ),
      0,
      math.pi,
      true,
      Paint()..color = AppColors.peach.withValues(alpha: open),
    );
    canvas.restore();
  }

  void _drawSweatDrop(Canvas canvas) {
    if (spec.sweatDrop <= 0) return;
    final paint = Paint()
      ..color = AppColors.waterLight.withValues(alpha: spec.sweatDrop);
    final drop = Path()
      ..moveTo(145, 101)
      ..quadraticBezierTo(154, 112, 145, 119)
      ..quadraticBezierTo(136, 112, 145, 101)
      ..close();
    canvas.drawPath(drop, paint);
  }

  void _drawThinkingAccent(Canvas canvas) {
    if (spec.thinkingAccent <= 0) return;
    final angle = ambientPhase * math.pi * 2;
    final orbitPaint = Paint()
      ..color = AppColors.peach.withValues(alpha: spec.thinkingAccent);
    for (var index = 0; index < 3; index++) {
      final itemAngle = angle + index * math.pi * 2 / 3;
      final radius = 4.0 + index * 1.5;
      canvas.drawCircle(
        Offset(100 + math.cos(itemAngle) * 78, 72 + math.sin(itemAngle) * 20),
        radius,
        orbitPaint,
      );
    }
  }

  void _drawSparkles(Canvas canvas, double wave) {
    if (spec.sparkles <= 0) return;
    final scale = spec.sparkles * (1 + wave * 0.12);
    final paint = Paint()
      ..color = AppColors.sparkle.withValues(alpha: spec.sparkles)
      ..style = PaintingStyle.fill;
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
      oldDelegate.spec != spec || oldDelegate.ambientPhase != ambientPhase;
}
