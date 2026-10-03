import 'package:flutter_test/flutter_test.dart';
import 'package:onehealth_ui/core/haptics/app_haptics.dart';

void main() {
  test('semantic haptics produce one platform call', () async {
    final driver = _RecordingHapticDriver();
    final haptics = AppHaptics(driver: driver);

    await haptics.selection();
    await haptics.continueAction();
    await haptics.success();
    await haptics.warning();

    expect(driver.calls, <String>['light', 'medium', 'medium', 'vibrate']);
  });

  test('disabled haptics do not call the platform', () async {
    final driver = _RecordingHapticDriver();
    final haptics = AppHaptics(enabled: false, driver: driver);

    await haptics.capture();
    await haptics.warning();

    expect(driver.calls, isEmpty);
  });
}

class _RecordingHapticDriver implements HapticDriver {
  final List<String> calls = <String>[];

  @override
  Future<void> heavyImpact() async => calls.add('heavy');

  @override
  Future<void> lightImpact() async => calls.add('light');

  @override
  Future<void> mediumImpact() async => calls.add('medium');

  @override
  Future<void> vibrate() async => calls.add('vibrate');
}
