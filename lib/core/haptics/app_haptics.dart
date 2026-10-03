import 'package:flutter/services.dart';

abstract interface class HapticDriver {
  Future<void> lightImpact();
  Future<void> mediumImpact();
  Future<void> heavyImpact();
  Future<void> vibrate();
}

class SystemHapticDriver implements HapticDriver {
  const SystemHapticDriver();

  @override
  Future<void> lightImpact() => HapticFeedback.lightImpact();

  @override
  Future<void> mediumImpact() => HapticFeedback.mediumImpact();

  @override
  Future<void> heavyImpact() => HapticFeedback.heavyImpact();

  @override
  Future<void> vibrate() => HapticFeedback.vibrate();
}

/// Semantic, one-shot haptics for meaningful user actions.
///
/// Flutter's platform channel honors device-level haptic settings. [enabled]
/// additionally supports an in-app preference without leaking platform APIs
/// into feature widgets.
class AppHaptics {
  AppHaptics({
    this.enabled = true,
    HapticDriver driver = const SystemHapticDriver(),
  }) : _driver = driver;

  final bool enabled;
  final HapticDriver _driver;

  Future<void> selection() => _run(_driver.lightImpact);
  Future<void> continueAction() => _run(_driver.mediumImpact);
  Future<void> capture() => _run(_driver.mediumImpact);
  Future<void> success() => _run(_driver.mediumImpact);
  Future<void> warning() => _run(_driver.vibrate);

  Future<void> _run(Future<void> Function() action) async {
    if (!enabled) return;
    await action();
  }
}
