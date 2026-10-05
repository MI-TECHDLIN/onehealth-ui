import '../../data/repositories/repository_models.dart';
import '../gamification/reminder_rules.dart';
import '../mode/app_mode.dart';
import '../settings/app_preferences.dart';
import 'reminder_notifier.dart';

/// Ties the pure reminder decision (`reminder_rules.dart`) to persistence
/// (the weekly throttle) and the platform notifier. The decision itself
/// stays pure and injectable here so tests can cover the throttle/permission
/// flow with a fake [ReminderNotifier] and [AppPreferences], never the real
/// plugin -- see AGENTS.md.
class ReminderCoordinator {
  ReminderCoordinator({
    required AppPreferences preferences,
    required ReminderNotifier notifier,
    DateTime Function()? now,
  }) : _preferences = preferences,
       _notifier = notifier,
       _now = now ?? DateTime.now;

  final AppPreferences _preferences;
  final ReminderNotifier _notifier;
  final DateTime Function() _now;

  /// Checks whether a gentle reminder is due and, if so, requests the OS
  /// permission (if not already resolved) and shows it. No-ops quietly if
  /// reminders are turned off, nothing is due yet, or permission is denied.
  /// Intended to be called once per app foreground, not on a timer.
  Future<void> maybeNotify({
    required AppMode mode,
    required bool remindersEnabled,
    required List<AssessmentRecord> history,
    required Map<String, String> siteNamesByCode,
    required ({String title, String body}) Function(ReminderCandidate candidate)
    buildMessage,
  }) async {
    if (!remindersEnabled) return;
    final now = _now().toUtc();
    final key = _lastSentKey(mode);
    final lastSentRaw = await _preferences.readString(key);
    final lastSentAt = lastSentRaw == null
        ? null
        : DateTime.tryParse(lastSentRaw);

    final candidate = decideReminder(
      history: history,
      siteNamesByCode: siteNamesByCode,
      now: now,
      lastSentAt: lastSentAt,
    );
    if (candidate == null) return;

    final granted = await _notifier.ensurePermission();
    if (!granted) return;

    final message = buildMessage(candidate);
    await _notifier.showReminder(title: message.title, body: message.body);
    await _preferences.writeString(key, now.toIso8601String());
  }

  String _lastSentKey(AppMode mode) =>
      '${mode.storageNamespace}.reminders.lastSentAt';
}
