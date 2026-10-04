import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../theme/tokens.dart';
import 'reduced_motion_lottie.dart';

enum BadgeState { locked, unlocked, newBadge }

enum BadgeDiscipline { water, habitat, community }

enum BadgeIcon { firstSignal, habitatEye, clearView, streamExplorer, biodiversity }

/// A single release-one evidence badge in the hex-drop crest family.
class BadgeCrest extends StatefulWidget {
  const BadgeCrest({
    super.key,
    required this.name,
    required this.criterion,
    required this.icon,
    required this.state,
    this.discipline = BadgeDiscipline.water,
    this.onTap,
  });

  final String name;
  final String criterion;
  final BadgeIcon icon;
  final BadgeState state;
  final BadgeDiscipline discipline;
  final VoidCallback? onTap;

  @override
  State<BadgeCrest> createState() => _BadgeCrestState();
}

class _BadgeCrestState extends State<BadgeCrest>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncAnimation();
  }

  @override
  void didUpdateWidget(covariant BadgeCrest oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.state != widget.state) _syncAnimation();
  }

  void _syncAnimation() {
    final reduceMotion = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    if (widget.state == BadgeState.newBadge && !reduceMotion) {
      _controller.repeat(reverse: true);
    } else {
      _controller
        ..stop()
        ..value = 0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final locked = widget.state == BadgeState.locked;
    final stateLabel = switch (widget.state) {
      BadgeState.locked => 'Locked',
      BadgeState.unlocked => 'Unlocked',
      BadgeState.newBadge => 'Newly unlocked',
    };
    return Semantics(
      button: widget.onTap != null,
      enabled: widget.onTap != null,
      label: '${widget.name}. $stateLabel. ${widget.criterion}',
      child: ExcludeSemantics(
        child: GestureDetector(
          onTap: widget.onTap,
          behavior: HitTestBehavior.opaque,
          child: SizedBox(
            width: 116,
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                final bob = math.sin(_controller.value * math.pi) * -4;
                final turn = math.sin(_controller.value * math.pi) * 0.025;
                return Transform.translate(
                  offset: Offset(0, bob),
                  child: Transform.rotate(angle: turn, child: child),
                );
              },
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Stack(
                    clipBehavior: Clip.none,
                    children: <Widget>[
                      Opacity(
                        opacity: locked ? AppOpacity.disabled : 1,
                        child: ColorFiltered(
                          colorFilter: locked
                              ? const ColorFilter.matrix(<double>[
                                  0.2126, 0.7152, 0.0722, 0, 0,
                                  0.2126, 0.7152, 0.0722, 0, 0,
                                  0.2126, 0.7152, 0.0722, 0, 0,
                                  0, 0, 0, 1, 0,
                                ])
                              : const ColorFilter.mode(
                                  Colors.transparent,
                                  BlendMode.dst,
                                ),
                          child: CustomPaint(
                            painter: _BadgeCrestPainter(
                              discipline: widget.discipline,
                              icon: widget.icon,
                              locked: locked,
                            ),
                            size: const Size(92, 102),
                          ),
                        ),
                      ),
                      if (locked)
                        const Positioned(
                          right: 4,
                          bottom: 10,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: AppColors.navy,
                              shape: BoxShape.circle,
                            ),
                            child: Padding(
                              padding: EdgeInsets.all(5),
                              child: Icon(
                                PhosphorIconsFill.lockSimple,
                                size: 14,
                                color: AppColors.white,
                              ),
                            ),
                          ),
                        ),
                      if (widget.state == BadgeState.newBadge)
                        const PositionedDirectional(
                          end: -4,
                          top: 2,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: AppColors.sparkle,
                              borderRadius: BorderRadius.all(
                                Radius.circular(AppRadii.pill),
                              ),
                              border: Border.fromBorderSide(
                                BorderSide(color: AppColors.white, width: 2),
                              ),
                            ),
                            child: Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 3,
                              ),
                              child: Text(
                                'NEW',
                                style: TextStyle(
                                  color: AppColors.navy,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  Text(
                    widget.name,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                  const SizedBox(height: AppSpacing.xxs),
                  Text(
                    locked ? 'Locked · ${widget.criterion}' : widget.criterion,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// One-shot badge reveal; reduced motion displays the completed crest frame.
class BadgeUnlockReveal extends StatelessWidget {
  const BadgeUnlockReveal({
    super.key,
    required this.badge,
    this.replayKey = 0,
  });

  final BadgeCrest badge;
  final Object replayKey;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: 180,
      child: Stack(
        alignment: Alignment.center,
        children: <Widget>[
          Positioned.fill(
            child: ReducedMotionLottie(
              asset: 'assets/animations/badge-unlock.json',
              semanticLabel: 'Badge unlocked',
              replayKey: replayKey,
            ),
          ),
          badge,
        ],
      ),
    );
  }
}

class _BadgeCrestPainter extends CustomPainter {
  const _BadgeCrestPainter({
    required this.discipline,
    required this.icon,
    required this.locked,
  });

  final BadgeDiscipline discipline;
  final BadgeIcon icon;
  final bool locked;

  @override
  void paint(Canvas canvas, Size size) {
    final outer = _hexDrop(Rect.fromLTWH(4, 2, size.width - 8, size.height - 12));
    final colors = switch (discipline) {
      BadgeDiscipline.water => const <Color>[AppColors.waterLight, AppColors.water],
      BadgeDiscipline.habitat => const <Color>[AppColors.sageLight, AppColors.sage],
      BadgeDiscipline.community => const <Color>[AppColors.peachLight, AppColors.peach],
    };
    canvas.drawShadow(outer, AppColors.navy.withValues(alpha: 0.2), 7, true);
    canvas.drawPath(
      outer,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: colors,
        ).createShader(Offset.zero & size),
    );
    final inner = _hexDrop(Rect.fromLTWH(14, 12, size.width - 28, size.height - 32));
    canvas.drawPath(
      inner,
      Paint()..color = locked ? AppColors.outline : AppColors.foam,
    );
    _drawIcon(canvas, Offset(size.width / 2, size.height * 0.48));
  }

  Path _hexDrop(Rect rect) => Path()
    ..moveTo(rect.center.dx, rect.top)
    ..lineTo(rect.right, rect.top + rect.height * 0.22)
    ..lineTo(rect.right, rect.top + rect.height * 0.7)
    ..lineTo(rect.center.dx, rect.bottom)
    ..lineTo(rect.left, rect.top + rect.height * 0.7)
    ..lineTo(rect.left, rect.top + rect.height * 0.22)
    ..close();

  void _drawIcon(Canvas canvas, Offset center) {
    final paint = Paint()
      ..color = AppColors.navy
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.3
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    switch (icon) {
      case BadgeIcon.firstSignal:
        canvas.drawPath(
          Path()
            ..moveTo(center.dx, center.dy - 18)
            ..cubicTo(
              center.dx - 3,
              center.dy - 8,
              center.dx - 14,
              center.dy,
              center.dx - 14,
              center.dy + 8,
            )
            ..arcToPoint(
              Offset(center.dx + 14, center.dy + 8),
              radius: const Radius.circular(14),
              clockwise: false,
            )
            ..cubicTo(
              center.dx + 14,
              center.dy,
              center.dx + 3,
              center.dy - 8,
              center.dx,
              center.dy - 18,
            ),
          paint,
        );
      case BadgeIcon.habitatEye:
        canvas.drawPath(
          Path()
            ..moveTo(center.dx - 18, center.dy + 11)
            ..quadraticBezierTo(center.dx - 12, center.dy - 16, center.dx + 16, center.dy - 14)
            ..quadraticBezierTo(center.dx + 14, center.dy + 13, center.dx - 18, center.dy + 11)
            ..moveTo(center.dx - 13, center.dy + 8)
            ..lineTo(center.dx + 11, center.dy - 9),
          paint,
        );
      case BadgeIcon.clearView:
        canvas
          ..drawRRect(
            RRect.fromRectAndRadius(
              Rect.fromCenter(center: center, width: 36, height: 27),
              const Radius.circular(5),
            ),
            paint,
          )
          ..drawCircle(center, 7, paint)
          ..drawLine(
            Offset(center.dx - 10, center.dy - 14),
            Offset(center.dx - 5, center.dy - 19),
            paint,
          )
          ..drawLine(
            Offset(center.dx - 5, center.dy - 19),
            Offset(center.dx + 3, center.dy - 19),
            paint,
          );
      case BadgeIcon.streamExplorer:
        canvas.drawPath(
          Path()
            ..moveTo(center.dx - 18, center.dy - 12)
            ..cubicTo(
              center.dx - 4,
              center.dy - 20,
              center.dx - 5,
              center.dy,
              center.dx + 17,
              center.dy - 8,
            )
            ..moveTo(center.dx - 17, center.dy + 2)
            ..cubicTo(
              center.dx - 3,
              center.dy - 6,
              center.dx - 3,
              center.dy + 14,
              center.dx + 18,
              center.dy + 5,
            )
            ..moveTo(center.dx - 15, center.dy + 15)
            ..cubicTo(
              center.dx - 3,
              center.dy + 8,
              center.dx + 4,
              center.dy + 21,
              center.dx + 15,
              center.dy + 14,
            ),
          paint,
        );
      case BadgeIcon.biodiversity:
        canvas
          ..drawCircle(Offset(center.dx - 10, center.dy - 7), 5, paint)
          ..drawCircle(Offset(center.dx + 10, center.dy - 7), 5, paint)
          ..drawCircle(Offset(center.dx - 14, center.dy + 7), 4, paint)
          ..drawCircle(Offset(center.dx + 14, center.dy + 7), 4, paint);
        canvas.drawPath(
          Path()
            ..moveTo(center.dx, center.dy - 2)
            ..cubicTo(
              center.dx - 13,
              center.dy + 5,
              center.dx - 12,
              center.dy + 18,
              center.dx,
              center.dy + 18,
            )
            ..cubicTo(
              center.dx + 12,
              center.dy + 18,
              center.dx + 13,
              center.dy + 5,
              center.dx,
              center.dy - 2,
            ),
          paint,
        );
    }
  }

  @override
  bool shouldRepaint(covariant _BadgeCrestPainter oldDelegate) =>
      oldDelegate.discipline != discipline ||
      oldDelegate.icon != icon ||
      oldDelegate.locked != locked;
}
