import 'package:flutter_test/flutter_test.dart';
import 'package:onehealth_ui/core/gamification/reminder_rules.dart';
import 'package:onehealth_ui/data/repositories/repository_models.dart';

final DateTime _now = DateTime.utc(2026, 6, 15);

AssessmentRecord _record(String siteCode, DateTime submittedAt) =>
    AssessmentRecord(id: siteCode, siteCode: siteCode, submittedAt: submittedAt);

void main() {
  test('no reminder with no history', () {
    expect(
      decideReminder(
        history: const <AssessmentRecord>[],
        siteNamesByCode: const <String, String>{},
        now: _now,
      ),
      isNull,
    );
  });

  test('no reminder when every site was checked recently', () {
    final candidate = decideReminder(
      history: <AssessmentRecord>[
        _record('A', _now.subtract(const Duration(days: 5))),
      ],
      siteNamesByCode: const <String, String>{'A': 'Willow Bend Stream'},
      now: _now,
    );

    expect(candidate, isNull);
  });

  test('a site unchecked for 30+ days triggers a stale-site reminder', () {
    final candidate = decideReminder(
      history: <AssessmentRecord>[
        _record('A', _now.subtract(const Duration(days: 31))),
      ],
      siteNamesByCode: const <String, String>{'A': 'Willow Bend Stream'},
      now: _now,
    );

    expect(candidate, isNotNull);
    expect(candidate!.kind, ReminderKind.staleSite);
    expect(candidate.siteCode, 'A');
    expect(candidate.siteName, 'Willow Bend Stream');
  });

  test('the most overdue site wins when more than one is stale', () {
    final candidate = decideReminder(
      history: <AssessmentRecord>[
        _record('A', _now.subtract(const Duration(days: 31))),
        _record('B', _now.subtract(const Duration(days: 90))),
      ],
      siteNamesByCode: const <String, String>{'A': 'A stream', 'B': 'B stream'},
      now: _now,
    );

    expect(candidate!.siteCode, 'B');
  });

  test('a season change since the last check triggers a seasonal revisit reminder', () {
    // Checked in winter; now is deep into spring/summer -- not stale (under
    // 30 days is impossible across a season, so use a realistic gap).
    final candidate = decideReminder(
      history: <AssessmentRecord>[
        _record('A', DateTime.utc(2026, 5, 28)), // spring, 18 days before `now`
      ],
      siteNamesByCode: const <String, String>{'A': 'Willow Bend Stream'},
      now: DateTime.utc(2026, 6, 20), // summer, 23 days after the check
    );

    expect(candidate, isNotNull);
    expect(candidate!.kind, ReminderKind.seasonalRevisit);
  });

  test('a season change under the minimum gap is not worth mentioning yet', () {
    final candidate = decideReminder(
      history: <AssessmentRecord>[
        _record('A', DateTime.utc(2026, 5, 30)),
      ],
      siteNamesByCode: const <String, String>{'A': 'Willow Bend Stream'},
      now: DateTime.utc(2026, 6, 2), // summer, but only 3 days later
    );

    expect(candidate, isNull);
  });

  test('a stale site always wins over a seasonal-only revisit', () {
    final candidate = decideReminder(
      history: <AssessmentRecord>[
        // 26 days ago, a different season, but under the 30-day stale
        // threshold: seasonal-only.
        _record('A', DateTime.utc(2026, 5, 20)),
        // 40 days ago: stale regardless of season.
        _record('B', _now.subtract(const Duration(days: 40))),
      ],
      siteNamesByCode: const <String, String>{'A': 'A stream', 'B': 'B stream'},
      now: _now,
    );

    expect(candidate!.kind, ReminderKind.staleSite);
    expect(candidate.siteCode, 'B');
  });

  test('the weekly cap suppresses a reminder sent less than 7 days ago', () {
    final candidate = decideReminder(
      history: <AssessmentRecord>[
        _record('A', _now.subtract(const Duration(days: 60))),
      ],
      siteNamesByCode: const <String, String>{'A': 'Willow Bend Stream'},
      now: _now,
      lastSentAt: _now.subtract(const Duration(days: 2)),
    );

    expect(candidate, isNull);
  });

  test('the weekly cap clears after 7 days', () {
    final candidate = decideReminder(
      history: <AssessmentRecord>[
        _record('A', _now.subtract(const Duration(days: 60))),
      ],
      siteNamesByCode: const <String, String>{'A': 'Willow Bend Stream'},
      now: _now,
      lastSentAt: _now.subtract(const Duration(days: 8)),
    );

    expect(candidate, isNotNull);
  });

  test('an unnamed site falls back to its code', () {
    final candidate = decideReminder(
      history: <AssessmentRecord>[
        _record('UNKNOWN-01', _now.subtract(const Duration(days: 45))),
      ],
      siteNamesByCode: const <String, String>{},
      now: _now,
    );

    expect(candidate!.siteName, 'UNKNOWN-01');
  });
}
