import 'package:flutter/material.dart';

import '../theme/tokens.dart';

/// A small, original cut-paper-style illustration for one glossary term.
/// Deliberately simple geometry (per the design report's illustration
/// style) -- these are not the picture-choice option art, which gets its
/// own hand-authored SVGs under `assets/illustrations/assessment/`.
class GlossaryIllustration extends StatelessWidget {
  const GlossaryIllustration({super.key, required this.termId, this.size = 96});

  final String termId;
  final double size;

  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: size,
    child: CustomPaint(painter: _GlossaryIllustrationPainter(termId: termId)),
  );
}

class _GlossaryIllustrationPainter extends CustomPainter {
  const _GlossaryIllustrationPainter({required this.termId});

  final String termId;

  @override
  void paint(Canvas canvas, Size size) {
    final background = Paint()..color = AppColors.waterMist;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.width, size.height),
        Radius.circular(AppRadii.lg),
      ),
      background,
    );
    switch (termId) {
      case 'channel':
        _paintChannel(canvas, size);
      case 'substrate':
        _paintSubstrate(canvas, size);
      case 'bank':
        _paintBank(canvas, size);
      case 'riparianZone':
        _paintRiparianZone(canvas, size);
      case 'invasiveSpecies':
        _paintInvasiveSpecies(canvas, size);
    }
  }

  void _paintChannel(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final valley = Path()
      ..moveTo(0, h * 0.3)
      ..lineTo(w * 0.32, h * 0.72)
      ..lineTo(w * 0.68, h * 0.72)
      ..lineTo(w, h * 0.3)
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();
    canvas.drawPath(valley, Paint()..color = AppColors.sageLight);
    final water = Path()
      ..moveTo(w * 0.32, h * 0.72)
      ..lineTo(w * 0.4, h * 0.86)
      ..lineTo(w * 0.6, h * 0.86)
      ..lineTo(w * 0.68, h * 0.72)
      ..close();
    canvas.drawPath(water, Paint()..color = AppColors.water);
  }

  void _paintSubstrate(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    canvas.drawRect(
      Rect.fromLTWH(0, h * 0.68, w, h * 0.32),
      Paint()..color = AppColors.water.withValues(alpha: 0.35),
    );
    final pebbles = <(double, double, double)>[
      (0.22, 0.78, 0.09),
      (0.42, 0.72, 0.07),
      (0.6, 0.8, 0.1),
      (0.78, 0.74, 0.06),
    ];
    for (final (dx, dy, r) in pebbles) {
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(w * dx, h * dy),
          width: w * r * 2,
          height: w * r * 1.3,
        ),
        Paint()..color = AppColors.inkMuted,
      );
    }
  }

  void _paintBank(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final slope = Path()
      ..moveTo(0, h * 0.2)
      ..lineTo(w * 0.55, h * 0.2)
      ..lineTo(w * 0.2, h)
      ..lineTo(0, h)
      ..close();
    canvas.drawPath(slope, Paint()..color = AppColors.sage);
    canvas.drawRect(
      Rect.fromLTWH(w * 0.2, h * 0.78, w * 0.8, h * 0.22),
      Paint()..color = AppColors.water,
    );
  }

  void _paintRiparianZone(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    canvas.drawRect(
      Rect.fromLTWH(0, h * 0.74, w, h * 0.26),
      Paint()..color = AppColors.water,
    );
    canvas.drawRect(
      Rect.fromLTWH(0, h * 0.6, w, h * 0.2),
      Paint()..color = AppColors.sageLight,
    );
    final trunk = Paint()..color = const Color(0xFF8A6A4A);
    canvas.drawRect(Rect.fromLTWH(w * 0.42, h * 0.46, w * 0.08, h * 0.2), trunk);
    canvas.drawCircle(
      Offset(w * 0.46, h * 0.36),
      w * 0.2,
      Paint()..color = AppColors.sage,
    );
  }

  void _paintInvasiveSpecies(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final vine = Path()
      ..moveTo(w * 0.5, h * 0.9)
      ..cubicTo(w * 0.2, h * 0.7, w * 0.8, h * 0.55, w * 0.35, h * 0.3)
      ..cubicTo(w * 0.15, h * 0.15, w * 0.3, h * 0.05, w * 0.5, h * 0.1);
    canvas.drawPath(
      vine,
      Paint()
        ..color = AppColors.sage
        ..style = PaintingStyle.stroke
        ..strokeWidth = size.width * 0.045
        ..strokeCap = StrokeCap.round,
    );
    for (final t in const <double>[0.2, 0.45, 0.7]) {
      canvas.drawCircle(
        Offset(w * (0.3 + t * 0.4), h * (0.85 - t * 0.6)),
        w * 0.07,
        Paint()..color = AppColors.sageLight,
      );
    }
    canvas.drawCircle(
      Offset(w * 0.78, h * 0.26),
      w * 0.07,
      Paint()..color = AppColors.warning,
    );
  }

  @override
  bool shouldRepaint(covariant _GlossaryIllustrationPainter oldDelegate) =>
      oldDelegate.termId != termId;
}
