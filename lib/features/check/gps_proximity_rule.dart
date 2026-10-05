import 'dart:math' as math;

/// Result of comparing a device fix with the stream selected for the check.
class GpsProximityResult {
  const GpsProximityResult({
    required this.distanceMeters,
    required this.accuracyMeters,
    required this.requiresConfirmation,
  });

  final double distanceMeters;
  final double accuracyMeters;
  final bool requiresConfirmation;
}

abstract final class GpsProximityRule {
  static const double reliableAccuracyMeters = 100;
  static const double farFromSiteMeters = 300;

  static GpsProximityResult evaluate({
    required double siteLatitude,
    required double siteLongitude,
    required double observedLatitude,
    required double observedLongitude,
    required double accuracyMeters,
  }) {
    final distance = distanceMeters(
      siteLatitude,
      siteLongitude,
      observedLatitude,
      observedLongitude,
    );
    final poorFix = accuracyMeters > reliableAccuracyMeters;
    final clearlyFar = distance >
        math.max(farFromSiteMeters, accuracyMeters * 2).toDouble();
    return GpsProximityResult(
      distanceMeters: distance,
      accuracyMeters: accuracyMeters,
      // An imprecise fix also needs a human confirmation. It never silently
      // blocks a valid field submission.
      requiresConfirmation: poorFix || clearlyFar,
    );
  }

  static double distanceMeters(
    double latitudeA,
    double longitudeA,
    double latitudeB,
    double longitudeB,
  ) {
    const earthRadiusMeters = 6371000.0;
    double radians(double degrees) => degrees * math.pi / 180;
    final deltaLatitude = radians(latitudeB - latitudeA);
    final deltaLongitude = radians(longitudeB - longitudeA);
    final a = math.sin(deltaLatitude / 2) * math.sin(deltaLatitude / 2) +
        math.cos(radians(latitudeA)) *
            math.cos(radians(latitudeB)) *
            math.sin(deltaLongitude / 2) *
            math.sin(deltaLongitude / 2);
    return earthRadiusMeters * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
  }
}
