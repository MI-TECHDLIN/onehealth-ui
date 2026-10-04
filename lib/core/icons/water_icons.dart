import 'package:flutter/material.dart';

/// The water-themed glyphs Phosphor doesn't cover, drawn by hand on the same
/// 24x24 grid and ~1.5 dp rounded stroke as the Phosphor set so they sit
/// together without clashing. See the approved preview at
/// `.lavish/type-icons-preview.html` (round 3 type/icon pick) for the source
/// design -- this file is the Flutter port of that artwork.
enum WaterIcon {
  /// Raised Check nav action (`app_shell.dart`).
  streamCheck,

  /// Brand / loading accents -- a drop that just landed, making ripples.
  rippleDrop,

  /// Quality-rating rows and result summaries -- a drop with a verified tick.
  waterQuality,

  /// Habitat / riverbank questions and field-guide illustrations.
  riparianBank,

  /// Field safety notices -- a water-themed stand-in for a generic shield.
  fieldSafety,

  /// Read-aloud listen control -- a speaker with a ripple-shaped sound wave.
  narrationWave,
}

/// Renders a [WaterIcon]. [filled] mirrors Phosphor's fill weight for a
/// selected/active state; the default (`false`) is the regular/idle weight.
class WaterIconWidget extends StatelessWidget {
  const WaterIconWidget(
    this.icon, {
    super.key,
    this.size,
    this.color,
    this.filled = false,
  });

  final WaterIcon icon;

  /// Falls back to the ambient [IconTheme] size, then 24, matching [Icon].
  final double? size;
  final Color? color;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final iconTheme = IconTheme.of(context);
    final resolved = color ?? iconTheme.color ?? Colors.black;
    final resolvedSize = size ?? iconTheme.size ?? 24;
    return SizedBox.square(
      dimension: resolvedSize,
      child: CustomPaint(
        painter: _WaterIconPainter(icon: icon, color: resolved, filled: filled),
      ),
    );
  }
}

class _WaterIconPainter extends CustomPainter {
  const _WaterIconPainter({
    required this.icon,
    required this.color,
    required this.filled,
  });

  final WaterIcon icon;
  final Color color;
  final bool filled;

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / 24;
    canvas.save();
    canvas.scale(scale);

    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final boldStroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.1
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final fill = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    final onFill = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    switch (icon) {
      case WaterIcon.streamCheck:
        canvas
          ..drawPath(_streamWave(), stroke)
          ..drawPath(_checkMark(8, 9, 11, 12, 17, 5), stroke);

      case WaterIcon.rippleDrop:
        final drop = _dropPath(cx: 12, top: 3.5, bottomY: 11.8, r: 4.3);
        if (filled) {
          canvas
            ..drawPath(drop, fill)
            ..drawOval(
              Rect.fromCenter(center: const Offset(12, 19.2), width: 14, height: 3.4),
              Paint()
                ..color = color.withValues(alpha: 0.55)
                ..style = PaintingStyle.fill,
            );
        } else {
          canvas
            ..drawPath(drop, stroke)
            ..drawOval(
              Rect.fromCenter(center: const Offset(12, 19.2), width: 14, height: 3.4),
              stroke,
            )
            ..drawOval(
              Rect.fromCenter(center: const Offset(12, 19.2), width: 8, height: 2),
              stroke,
            );
        }

      case WaterIcon.waterQuality:
        final drop = _dropPath(cx: 11, top: 3.8, bottomY: 11, r: 3.8);
        const checkCenter = Offset(17.3, 16.8);
        if (filled) {
          canvas
            ..drawPath(drop, fill)
            ..drawCircle(checkCenter, 4.6, fill)
            ..drawPath(_checkMark(15.6, 16.8, 16.9, 18.1, 19.7, 15.2), onFill);
        } else {
          canvas
            ..drawPath(drop, stroke)
            ..drawCircle(checkCenter, 4, stroke)
            ..drawPath(_checkMark(15.6, 16.8, 16.7, 17.9, 18.7, 15.4), stroke);
        }

      case WaterIcon.riparianBank:
        if (filled) {
          canvas
            ..drawPath(_riparianFill(), fill)
            ..drawCircle(const Offset(5, 5.5), 1.4, fill)
            ..drawCircle(const Offset(19, 5.5), 1.4, fill);
        } else {
          canvas
            ..drawPath(_riparianOutline(), stroke)
            ..drawLine(const Offset(4, 6.6), const Offset(5.3, 4.8), stroke)
            ..drawLine(const Offset(6.4, 8), const Offset(7.7, 6.2), stroke)
            ..drawLine(const Offset(20, 6.6), const Offset(18.7, 4.8), stroke)
            ..drawLine(const Offset(17.6, 8), const Offset(16.3, 6.2), stroke);
        }

      case WaterIcon.fieldSafety:
        final shield = _shieldPath();
        final drop = _dropPath(cx: 12, top: 8.5, bottomY: 13.1, r: 2.3);
        if (filled) {
          final innerDrop = Paint()
            ..color = Colors.white.withValues(alpha: 0.85)
            ..style = PaintingStyle.fill;
          canvas
            ..drawPath(shield, fill)
            ..drawPath(drop, innerDrop);
        } else {
          canvas
            ..drawPath(shield, stroke)
            ..drawPath(drop, stroke);
        }

      case WaterIcon.narrationWave:
        final speaker = _speakerPath();
        if (filled) {
          canvas
            ..drawPath(speaker, fill)
            ..drawPath(_waveArc(13.5, 9.2, 16.1, 12, 13.5, 14.8), boldStroke)
            ..drawPath(_waveArc(16.3, 6.8, 20.9, 12, 16.3, 17.2), boldStroke);
        } else {
          canvas
            ..drawPath(speaker, stroke)
            ..drawPath(_waveArc(13.5, 9.2, 16.1, 12, 13.5, 14.8), stroke)
            ..drawPath(_waveArc(16.3, 6.8, 20.9, 12, 16.3, 17.2), stroke);
        }
    }

    canvas.restore();
  }

  /// A gentle stream S-curve used as the base of [WaterIcon.streamCheck].
  Path _streamWave() => Path()
    ..moveTo(3, 16)
    ..cubicTo(6, 12, 9, 12, 12, 16)
    ..cubicTo(15, 20, 18, 20, 21, 16);

  Path _checkMark(
    double x1,
    double y1,
    double x2,
    double y2,
    double x3,
    double y3,
  ) => Path()
    ..moveTo(x1, y1)
    ..lineTo(x2, y2)
    ..lineTo(x3, y3);

  /// A symmetric water-drop silhouette, open at [top] and rounded at
  /// [bottomY] with radius [r], centered on [cx].
  Path _dropPath({
    required double cx,
    required double top,
    required double bottomY,
    required double r,
  }) => Path()
    ..moveTo(cx, top)
    ..cubicTo(cx - r * 0.56, top + (bottomY - top) * 0.8, cx - r, bottomY - r * 0.35, cx - r, bottomY)
    ..arcToPoint(Offset(cx + r, bottomY), radius: Radius.circular(r), clockwise: false)
    ..cubicTo(cx + r, bottomY - r * 0.35, cx + r * 0.56, top + (bottomY - top) * 0.8, cx, top)
    ..close();

  Path _riparianOutline() => Path()
    ..moveTo(2, 8.5)
    ..lineTo(9.5, 17)
    ..moveTo(22, 8.5)
    ..lineTo(14.5, 17)
    ..moveTo(9.5, 17)
    ..cubicTo(9.5, 15.6, 10.6, 14.6, 12, 14.6)
    ..cubicTo(13.4, 14.6, 14.5, 15.6, 14.5, 17);

  Path _riparianFill() => Path()
    ..moveTo(2, 7.5)
    ..lineTo(10.3, 18)
    ..lineTo(13.7, 18)
    ..lineTo(22, 7.5)
    ..lineTo(20.5, 6.2)
    ..lineTo(13, 15.6)
    ..lineTo(11, 15.6)
    ..lineTo(3.5, 6.2)
    ..close();

  Path _shieldPath() => Path()
    ..moveTo(12, 3)
    ..lineTo(18.5, 5.4)
    ..lineTo(18.5, 11.2)
    ..cubicTo(18.5, 15.6, 15.7, 18.8, 12, 19.8)
    ..cubicTo(8.3, 18.8, 5.5, 15.6, 5.5, 11.2)
    ..lineTo(5.5, 5.4)
    ..close();

  Path _speakerPath() => Path()
    ..moveTo(3, 9.5)
    ..lineTo(6, 9.5)
    ..lineTo(10, 5.7)
    ..lineTo(10, 18.3)
    ..lineTo(6, 14.5)
    ..lineTo(3, 14.5)
    ..close();

  Path _waveArc(
    double x1,
    double y1,
    double cx,
    double cy,
    double x2,
    double y2,
  ) => Path()
    ..moveTo(x1, y1)
    ..quadraticBezierTo(cx, cy, x2, y2);

  @override
  bool shouldRepaint(covariant _WaterIconPainter oldDelegate) =>
      oldDelegate.icon != icon ||
      oldDelegate.color != color ||
      oldDelegate.filled != filled;
}
