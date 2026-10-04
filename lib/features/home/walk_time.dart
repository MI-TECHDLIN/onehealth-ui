/// Rough walking-time estimate from a straight-line distance, at an average
/// walking pace of 5 km/h. Returns `null` when the distance isn't known
/// (no device location yet), rather than fabricating a number.
int? walkMinutesFor(double? distanceKm) {
  if (distanceKm == null) return null;
  final minutes = (distanceKm / 5.0 * 60).round();
  return minutes < 1 ? 1 : minutes;
}
