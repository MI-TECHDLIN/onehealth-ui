import 'dart:ui';

import 'package:flutter/foundation.dart';

/// Reusable actions Ripple can perform independently of its emotional mood.
enum RippleGesture { none, wave, point, nod, jump, swimIn, talk }

/// Four stable mouth cues used by narration timing tracks.
enum RippleViseme { rest, open, wide, round }

@immutable
class RippleVisemeFrame {
  const RippleVisemeFrame({required this.open, required this.width});

  final double open;
  final double width;

  static const RippleVisemeFrame rest = RippleVisemeFrame(
    open: 0,
    width: 1,
  );
  static const RippleVisemeFrame open = RippleVisemeFrame(
    open: 1,
    width: 0.82,
  );
  static const RippleVisemeFrame wide = RippleVisemeFrame(
    open: 0.58,
    width: 1.28,
  );
  static const RippleVisemeFrame round = RippleVisemeFrame(
    open: 0.72,
    width: 0.68,
  );

  static RippleVisemeFrame forViseme(RippleViseme viseme) => switch (viseme) {
    RippleViseme.rest => rest,
    RippleViseme.open => open,
    RippleViseme.wide => wide,
    RippleViseme.round => round,
  };

  static RippleVisemeFrame lerp(
    RippleVisemeFrame begin,
    RippleVisemeFrame end,
    double t,
  ) {
    final progress = t.clamp(0.0, 1.0).toDouble();
    return RippleVisemeFrame(
      open: begin.open + (end.open - begin.open) * progress,
      width: begin.width + (end.width - begin.width) * progress,
    );
  }
}

/// The deterministic low-pass function used when narration changes visemes.
///
/// Timing sources can call [RippleController.setViseme] at word or phoneme
/// boundaries. Ripple eases toward each cue over 160 ms instead of snapping.
abstract final class RippleVisemeSmoother {
  static RippleVisemeFrame sample({
    required RippleVisemeFrame begin,
    required RippleVisemeFrame end,
    required Duration elapsed,
    Duration duration = const Duration(milliseconds: 160),
  }) {
    if (duration <= Duration.zero) return end;
    final linear = (elapsed.inMicroseconds / duration.inMicroseconds)
        .clamp(0.0, 1.0)
        .toDouble();
    final eased = 1 - (1 - linear) * (1 - linear) * (1 - linear);
    return RippleVisemeFrame.lerp(begin, end, eased);
  }
}

/// External timing and gesture API for `AquaMascot`.
///
/// Own this controller beside audio/playback state and pass it to Ripple. The
/// widget owns only visual animation clocks; narration remains the source of
/// truth for viseme changes.
class RippleController extends ChangeNotifier {
  RippleGesture _gesture = RippleGesture.none;
  RippleViseme _viseme = RippleViseme.rest;
  Offset _target = const Offset(1, 0);
  bool _loop = false;
  int _gestureGeneration = 0;

  RippleGesture get gesture => _gesture;
  RippleViseme get viseme => _viseme;
  Offset get target => _target;
  bool get loop => _loop;
  int get gestureGeneration => _gestureGeneration;

  /// Starts a gesture. [target] is a normalized direction from Ripple's
  /// centre and is used by the point gesture for eye aim and fin angle.
  void playGesture(
    RippleGesture gesture, {
    Offset target = const Offset(1, 0),
    bool loop = false,
  }) {
    _gesture = gesture;
    _target = target.distanceSquared == 0
        ? const Offset(1, 0)
        : target / target.distance;
    _loop = loop;
    _gestureGeneration += 1;
    notifyListeners();
  }

  void stopGesture() {
    if (_gesture == RippleGesture.none) return;
    _gesture = RippleGesture.none;
    _loop = false;
    _gestureGeneration += 1;
    notifyListeners();
  }

  /// Sets the next narration mouth cue. This is intentionally not a timer:
  /// audio/word timing can drive it exactly, while the mascot smooths it.
  void setViseme(RippleViseme viseme) {
    if (_viseme == viseme && _gesture == RippleGesture.talk) return;
    _viseme = viseme;
    _gesture = RippleGesture.talk;
    notifyListeners();
  }
}

extension RippleGestureTiming on RippleGesture {
  Duration get duration => switch (this) {
    RippleGesture.wave => const Duration(milliseconds: 700),
    RippleGesture.point => const Duration(milliseconds: 1600),
    RippleGesture.nod => const Duration(milliseconds: 1250),
    RippleGesture.jump => const Duration(milliseconds: 1450),
    RippleGesture.swimIn => const Duration(milliseconds: 2600),
    RippleGesture.talk => const Duration(milliseconds: 160),
    RippleGesture.none => Duration.zero,
  };
}
