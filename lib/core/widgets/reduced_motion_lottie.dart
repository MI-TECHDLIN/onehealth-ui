import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

/// Plays a bundled one-shot animation and shows its meaningful final frame
/// when the system requests reduced motion.
class ReducedMotionLottie extends StatefulWidget {
  const ReducedMotionLottie({
    super.key,
    required this.asset,
    required this.semanticLabel,
    this.fit = BoxFit.contain,
    this.repeat = false,
    this.replayKey = 0,
  });

  final String asset;
  final String semanticLabel;
  final BoxFit fit;
  final bool repeat;
  final Object replayKey;

  @override
  State<ReducedMotionLottie> createState() => _ReducedMotionLottieState();
}

class _ReducedMotionLottieState extends State<ReducedMotionLottie>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  Duration? _compositionDuration;

  bool get _reduceMotion =>
      MediaQuery.maybeOf(context)?.disableAnimations ?? false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _updatePlayback();
  }

  @override
  void didUpdateWidget(covariant ReducedMotionLottie oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.replayKey != widget.replayKey ||
        oldWidget.repeat != widget.repeat) {
      _updatePlayback(restart: true);
    }
  }

  void _updatePlayback({bool restart = false}) {
    if (_compositionDuration == null) return;
    _controller.duration = _compositionDuration;
    if (_reduceMotion) {
      _controller
        ..stop()
        ..value = 1;
    } else if (widget.repeat) {
      _controller.repeat();
    } else if (restart || !_controller.isAnimating) {
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      image: true,
      label: widget.semanticLabel,
      child: ExcludeSemantics(
        child: Lottie.asset(
          widget.asset,
          controller: _controller,
          animate: false,
          repeat: false,
          fit: widget.fit,
          onLoaded: (composition) {
            _compositionDuration = composition.duration;
            _updatePlayback(restart: true);
          },
        ),
      ),
    );
  }
}
