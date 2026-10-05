import 'package:flutter_test/flutter_test.dart';
import 'package:onehealth_ui/core/gamification/reminder_rules.dart';
import 'package:onehealth_ui/core/mode/app_mode.dart';
import 'package:onehealth_ui/core/notifications/reminder_coordinator.dart';
import 'package:onehealth_ui/core/notifications/reminder_notifier.dart';
import 'package:onehealth_ui/core/settings/app_preferences.dart';
import 'package:onehealth_ui/data/repositories/repository_models.dart';

class _FakeNotifier implements ReminderNotifier {
  bool permissionGranted = true;
  bool permissionRequested = false;
  final List<({String title, String body})> shown = <({String title, String body})>[];

  @override
  Future<bool> ensurePermission() async {
    permissionRequested = true;
    return permissionGranted;
  }

  @override
  Future<void> showReminder({required String title, required String body}) async {
    shown.add((title: title, body: body));
  }
}

({String title, String body}) _buildMessage(ReminderCandidate candidate) =>
    (title: 'title:${candidate.kind.name}', body: 'body:${candidate.siteName}');

void main() {
  test('never shows a reminder, and never asks permission, when none is due', () async {
    final notifier = _FakeNotifier();
    final coordinator = ReminderCoordinator(
      preferences: MemoryAppPreferences(),
      notifier: notifier,
      now: () => DateTime.utc(2026, 6, 15),
    );

    await coordinator.maybeNotify(
      mode: AppMode.demo,
      remindersEnabled: true,
      history: const <AssessmentRecord>[],
      siteNamesByCode: const <String, String>{},
      buildMessage: _buildMessage,
    );

    expect(notifier.permissionRequested, isFalse);
    expect(notifier.shown, isEmpty);
  });

  test('does nothing while the preference is off, even if something is due', () async {
    final notifier = _FakeNotifier();
    final coordinator = ReminderCoordinator(
      preferences: MemoryAppPreferences(),
      notifier: notifier,
      now: () => DateTime.utc(2026, 6, 15),
    );

    await coordinator.maybeNotify(
      mode: AppMode.demo,
      remindersEnabled: false,
      history: <AssessmentRecord>[
        AssessmentRecord(
          id: '1',
          siteCode: 'A',
          submittedAt: DateTime.utc(2026, 1, 1),
        ),
      ],
      siteNamesByCode: const <String, String>{'A': 'A stream'},
      buildMessage: _buildMessage,
    );

    expect(notifier.shown, isEmpty);
  });

  test('shows a due reminder, then throttles the next check for 7 days', () async {
    final notifier = _FakeNotifier();
    final preferences = MemoryAppPreferences();
    var now = DateTime.utc(2026, 6, 15);
    final coordinator = ReminderCoordinator(
      preferences: preferences,
      notifier: notifier,
      now: () => now,
    );
    final history = <AssessmentRecord>[
      AssessmentRecord(id: '1', siteCode: 'A', submittedAt: DateTime.utc(2026, 1, 1)),
    ];

    await coordinator.maybeNotify(
      mode: AppMode.demo,
      remindersEnabled: true,
      history: history,
      siteNamesByCode: const <String, String>{'A': 'Willow Bend Stream'},
      buildMessage: _buildMessage,
    );

    expect(notifier.shown, hasLength(1));
    expect(notifier.shown.single.body, 'body:Willow Bend Stream');

    // Two days later, the weekly cap this coordinator itself enforces
    // suppresses a second notification even though the site is still stale.
    now = now.add(const Duration(days: 2));
    await coordinator.maybeNotify(
      mode: AppMode.demo,
      remindersEnabled: true,
      history: history,
      siteNamesByCode: const <String, String>{'A': 'Willow Bend Stream'},
      buildMessage: _buildMessage,
    );

    expect(notifier.shown, hasLength(1));
  });

  test('never shows a reminder when permission is denied', () async {
    final notifier = _FakeNotifier()..permissionGranted = false;
    final coordinator = ReminderCoordinator(
      preferences: MemoryAppPreferences(),
      notifier: notifier,
      now: () => DateTime.utc(2026, 6, 15),
    );

    await coordinator.maybeNotify(
      mode: AppMode.demo,
      remindersEnabled: true,
      history: <AssessmentRecord>[
        AssessmentRecord(id: '1', siteCode: 'A', submittedAt: DateTime.utc(2026, 1, 1)),
      ],
      siteNamesByCode: const <String, String>{'A': 'A stream'},
      buildMessage: _buildMessage,
    );

    expect(notifier.permissionRequested, isTrue);
    expect(notifier.shown, isEmpty);
  });

  test('Demo and Live each keep their own throttle', () async {
    final notifier = _FakeNotifier();
    final preferences = MemoryAppPreferences();
    final now = DateTime.utc(2026, 6, 15);
    final coordinator = ReminderCoordinator(
      preferences: preferences,
      notifier: notifier,
      now: () => now,
    );
    final history = <AssessmentRecord>[
      AssessmentRecord(id: '1', siteCode: 'A', submittedAt: DateTime.utc(2026, 1, 1)),
    ];

    await coordinator.maybeNotify(
      mode: AppMode.demo,
      remindersEnabled: true,
      history: history,
      siteNamesByCode: const <String, String>{'A': 'A stream'},
      buildMessage: _buildMessage,
    );
    await coordinator.maybeNotify(
      mode: AppMode.live,
      remindersEnabled: true,
      history: history,
      siteNamesByCode: const <String, String>{'A': 'A stream'},
      buildMessage: _buildMessage,
    );

    expect(notifier.shown, hasLength(2));
  });
}
