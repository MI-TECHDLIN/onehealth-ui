import 'package:flutter_test/flutter_test.dart';
import 'package:onehealth_ui/features/check/gps_proximity_rule.dart';

void main() {
  test('a reliable fix near the selected stream needs no confirmation', () {
    final result = GpsProximityRule.evaluate(
      siteLatitude: 41,
      siteLongitude: -8,
      observedLatitude: 41.0005,
      observedLongitude: -8,
      accuracyMeters: 12,
    );

    expect(result.distanceMeters, lessThan(100));
    expect(result.requiresConfirmation, isFalse);
  });

  test('a far fix asks for a right-stream confirmation', () {
    final result = GpsProximityRule.evaluate(
      siteLatitude: 41,
      siteLongitude: -8,
      observedLatitude: 41.01,
      observedLongitude: -8,
      accuracyMeters: 15,
    );

    expect(result.distanceMeters, greaterThan(1000));
    expect(result.requiresConfirmation, isTrue);
  });

  test('an imprecise fix asks rather than silently blocking', () {
    final result = GpsProximityRule.evaluate(
      siteLatitude: 41,
      siteLongitude: -8,
      observedLatitude: 41,
      observedLongitude: -8,
      accuracyMeters: 140,
    );

    expect(result.requiresConfirmation, isTrue);
  });
}
