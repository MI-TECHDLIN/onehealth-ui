/// Weekly contribution rhythm: counts any complete check in a week, with a
/// single grace week so one missed week never breaks the run. Never a
/// daily-only streak -- see AGENTS.md and the design report's "Gamification
/// recommendation" section for why.
class WeeklyRhythm {
  const WeeklyRhythm({
    required this.thisWeekDone,
    required this.streakWeeks,
    required this.graceAvailable,
  });

  /// Whether at least one check landed in the current week.
  final bool thisWeekDone;

  /// The current run of active weeks, tolerating at most one missed week
  /// anywhere in the run (not per gap -- the grace is spent once).
  final int streakWeeks;

  /// Whether the one grace week has not yet been spent in this run.
  final bool graceAvailable;
}

/// A fixed Monday used only to turn a date into an absolute, year-independent
/// week index -- avoids ISO week-numbering edge cases at year boundaries.
final DateTime _epochMonday = DateTime.utc(2000, 1, 3);

int weekIndexOf(DateTime date) {
  final utc = date.toUtc();
  final midnight = DateTime.utc(utc.year, utc.month, utc.day);
  return midnight.difference(_epochMonday).inDays ~/ 7;
}

/// Computes the weekly rhythm from a citizen's own check timestamps.
///
/// Walks backward week by week from the most recent *completed* reference
/// week (the current week only counts once it has a check; an empty
/// in-progress current week is reported separately via [WeeklyRhythm.thisWeekDone]
/// rather than treated as a miss). One missed week anywhere in the walk is
/// tolerated (the grace week); a second missed week ends the run.
WeeklyRhythm computeWeeklyRhythm({
  required List<DateTime> checkDates,
  required DateTime now,
}) {
  final activeWeeks = checkDates.map(weekIndexOf).toSet();
  final currentWeek = weekIndexOf(now);
  final thisWeekDone = activeWeeks.contains(currentWeek);

  if (activeWeeks.isEmpty) {
    return const WeeklyRhythm(
      thisWeekDone: false,
      streakWeeks: 0,
      graceAvailable: true,
    );
  }

  final earliestWeek = activeWeeks.reduce((a, b) => a < b ? a : b);
  var streak = 0;
  var graceAvailable = true;
  var week = thisWeekDone ? currentWeek : currentWeek - 1;

  while (week >= earliestWeek) {
    if (activeWeeks.contains(week)) {
      streak += 1;
    } else if (graceAvailable) {
      graceAvailable = false;
    } else {
      break;
    }
    week -= 1;
  }

  return WeeklyRhythm(
    thisWeekDone: thisWeekDone,
    streakWeeks: streak,
    graceAvailable: graceAvailable,
  );
}
