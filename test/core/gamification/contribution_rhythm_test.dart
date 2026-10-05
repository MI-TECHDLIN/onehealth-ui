import 'package:flutter_test/flutter_test.dart';
import 'package:onehealth_ui/core/gamification/contribution_rhythm.dart';

final DateTime _now = DateTime.utc(2026, 3, 11);

DateTime _weeksAgo(int weeks) => _now.subtract(Duration(days: 7 * weeks));

void main() {
  test('empty history has no streak and an unused grace week', () {
    final rhythm = computeWeeklyRhythm(checkDates: const <DateTime>[], now: _now);

    expect(rhythm.thisWeekDone, isFalse);
    expect(rhythm.streakWeeks, 0);
    expect(rhythm.graceAvailable, isTrue);
  });

  test('a check in every week counts the full run and marks this week done', () {
    final rhythm = computeWeeklyRhythm(
      checkDates: <DateTime>[_weeksAgo(0), _weeksAgo(1), _weeksAgo(2)],
      now: _now,
    );

    expect(rhythm.thisWeekDone, isTrue);
    expect(rhythm.streakWeeks, 3);
    expect(rhythm.graceAvailable, isTrue);
  });

  test('a single missed week is forgiven by the grace week and keeps the run going', () {
    // Weeks 0, 1 and 3 have checks; week 2 is missed.
    final rhythm = computeWeeklyRhythm(
      checkDates: <DateTime>[_weeksAgo(0), _weeksAgo(1), _weeksAgo(3)],
      now: _now,
    );

    expect(rhythm.thisWeekDone, isTrue);
    expect(rhythm.streakWeeks, 3);
    expect(rhythm.graceAvailable, isFalse);
  });

  test('a second missed week breaks the run once the grace week is spent', () {
    // Week 0 has a check; weeks 1 and 2 are both missed.
    final rhythm = computeWeeklyRhythm(
      checkDates: <DateTime>[_weeksAgo(0), _weeksAgo(3)],
      now: _now,
    );

    expect(rhythm.streakWeeks, 1);
    expect(rhythm.graceAvailable, isFalse);
  });

  test('an in-progress current week with no check yet is not treated as a miss', () {
    final rhythm = computeWeeklyRhythm(
      checkDates: <DateTime>[_weeksAgo(1), _weeksAgo(2)],
      now: _now,
    );

    expect(rhythm.thisWeekDone, isFalse);
    expect(rhythm.streakWeeks, 2);
    expect(rhythm.graceAvailable, isTrue);
  });

  test('weekIndexOf is stable across a week and changes at the boundary', () {
    final monday = DateTime.utc(2026, 3, 9);
    final sunday = monday.add(const Duration(days: 6));
    final nextMonday = monday.add(const Duration(days: 7));

    expect(weekIndexOf(monday), weekIndexOf(sunday));
    expect(weekIndexOf(nextMonday), weekIndexOf(monday) + 1);
  });
}
