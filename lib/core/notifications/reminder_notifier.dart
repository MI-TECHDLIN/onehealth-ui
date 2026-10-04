import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// The platform seam for showing one gentle reminder notification. Kept
/// behind an interface so `ReminderCoordinator`'s due/throttle decisions can
/// be tested without a device or the real plugin -- see
/// `reminder_coordinator.dart` and `reminder_rules.dart`.
abstract interface class ReminderNotifier {
  /// Ensures the OS-level notification permission has been requested,
  /// returning whether reminders may be shown. Safe to call repeatedly.
  Future<bool> ensurePermission();

  Future<void> showReminder({required String title, required String body});
}

/// Shows reminders immediately via `show()` rather than scheduling them with
/// `zonedSchedule`: the right reminder (stale site vs. seasonal revisit)
/// depends on the citizen's evolving history, so it is recomputed by
/// `ReminderCoordinator` each time the app comes to the foreground rather
/// than pre-scheduled -- see AGENTS.md for why this means no `timezone`
/// package dependency or exact-alarm manifest entries are needed here.
class LocalReminderNotifier implements ReminderNotifier {
  LocalReminderNotifier() : _plugin = FlutterLocalNotificationsPlugin();

  final FlutterLocalNotificationsPlugin _plugin;
  bool _initialized = false;

  static const String _channelId = 'gentle_reminders';
  static const String _channelName = 'Gentle reminders';
  static const String _channelDescription =
      'Occasional nudges to revisit a stream, at most once a week. '
      'Turn off anytime in Settings.';

  Future<void> _ensureInitialized() async {
    if (_initialized) return;
    _initialized = true;
    await _plugin.initialize(
      const InitializationSettings(
        android: AndroidInitializationSettings('ic_notification'),
      ),
    );
  }

  @override
  Future<bool> ensurePermission() async {
    await _ensureInitialized();
    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (android == null) return true;
    final granted = await android.requestNotificationsPermission();
    return granted ?? false;
  }

  @override
  Future<void> showReminder({
    required String title,
    required String body,
  }) async {
    await _ensureInitialized();
    await _plugin.show(
      id: 0,
      title: title,
      body: body,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: _channelDescription,
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
        ),
      ),
    );
  }
}
