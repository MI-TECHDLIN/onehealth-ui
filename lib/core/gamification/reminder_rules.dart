import '../../data/repositories/repository_models.dart';
import 'season.dart';

enum ReminderKind { staleSite, seasonalRevisit }

/// One gentle reminder worth showing, naming the site it is about.
class ReminderCandidate {
  const ReminderCandidate({
    required this.kind,
    required this.siteCode,
    required this.siteName,
  });

  final ReminderKind kind;
  final String siteCode;
  final String siteName;
}

/// "a stream not checked in 30 days".
const Duration staleSiteThreshold = Duration(days: 30);

/// Minimum gap since a site's last check before a season change there is
/// worth mentioning -- long enough that it reads as a real seasonal gap,
/// not someone who happened to check the day before a season flipped.
const Duration seasonalRevisitMinimumGap = Duration(days: 21);

/// "at most one [reminder] a week".
const Duration reminderCooldown = Duration(days: 7);

/// Decides whether a gentle reminder is due right now, and which one.
///
/// Pure and deterministic given its inputs, so this is fully unit-testable
/// without a plugin, a clock, or a device. The weekly cap is enforced here
/// via [lastSentAt] rather than relied on at the OS scheduling layer.
ReminderCandidate? decideReminder({
  required List<AssessmentRecord> history,
  required Map<String, String> siteNamesByCode,
  required DateTime now,
  DateTime? lastSentAt,
}) {
  if (lastSentAt != null && now.difference(lastSentAt) < reminderCooldown) {
    return null;
  }
  if (history.isEmpty) return null;

  final lastCheckedBySite = <String, DateTime>{};
  for (final record in history) {
    final current = lastCheckedBySite[record.siteCode];
    if (current == null || record.submittedAt.isAfter(current)) {
      lastCheckedBySite[record.siteCode] = record.submittedAt;
    }
  }

  String nameFor(String code) => siteNamesByCode[code] ?? code;

  MapEntry<String, DateTime>? mostStale;
  for (final entry in lastCheckedBySite.entries) {
    if (now.difference(entry.value) < staleSiteThreshold) continue;
    if (mostStale == null || entry.value.isBefore(mostStale.value)) {
      mostStale = entry;
    }
  }
  if (mostStale != null) {
    return ReminderCandidate(
      kind: ReminderKind.staleSite,
      siteCode: mostStale.key,
      siteName: nameFor(mostStale.key),
    );
  }

  MapEntry<String, DateTime>? bestSeasonal;
  for (final entry in lastCheckedBySite.entries) {
    final gap = now.difference(entry.value);
    if (gap < seasonalRevisitMinimumGap) continue;
    if (seasonOf(entry.value) == seasonOf(now)) continue;
    if (bestSeasonal == null || entry.value.isBefore(bestSeasonal.value)) {
      bestSeasonal = entry;
    }
  }
  if (bestSeasonal != null) {
    return ReminderCandidate(
      kind: ReminderKind.seasonalRevisit,
      siteCode: bestSeasonal.key,
      siteName: nameFor(bestSeasonal.key),
    );
  }

  return null;
}
