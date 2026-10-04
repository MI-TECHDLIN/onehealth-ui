import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:onehealth_ui/core/notifications/reminder_notifier.dart';
import 'package:onehealth_ui/core/settings/app_preferences.dart';
import 'package:onehealth_ui/core/settings/app_settings_controller.dart';
import 'package:onehealth_ui/features/settings/settings_screen.dart';
import 'package:onehealth_ui/l10n/generated/app_localizations.dart';

class _FakeNotifier implements ReminderNotifier {
  bool permissionRequested = false;

  @override
  Future<bool> ensurePermission() async {
    permissionRequested = true;
    return true;
  }

  @override
  Future<void> showReminder({required String title, required String body}) async {}
}

Future<_FakeNotifier> _pumpSettings(WidgetTester tester, {bool remindersEnabled = true}) async {
  final preferences = MemoryAppPreferences(<String, String>{
    AppSettingsController.remindersEnabledKey: remindersEnabled ? 'true' : 'false',
  });
  final settings = AppSettingsController(preferences: preferences);
  addTearDown(settings.dispose);
  await settings.load();
  final notifier = _FakeNotifier();

  final router = GoRouter(
    initialLocation: '/settings',
    routes: <RouteBase>[
      GoRoute(
        path: '/settings',
        builder: (context, state) => SettingsScreen(reminderNotifier: notifier),
      ),
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const Scaffold(body: Text('onboarding-stub')),
      ),
    ],
  );
  addTearDown(router.dispose);

  await tester.pumpWidget(
    AppSettingsScope(
      controller: settings,
      child: MaterialApp.router(
        routerConfig: router,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
      ),
    ),
  );
  await tester.pumpAndSettle();
  return notifier;
}

void main() {
  testWidgets('turning gentle reminders on requests the notification permission', (
    tester,
  ) async {
    final notifier = await _pumpSettings(tester, remindersEnabled: false);

    await tester.tap(find.text('Gentle reminders'));
    await tester.pumpAndSettle();

    expect(notifier.permissionRequested, isTrue);
  });

  testWidgets('turning gentle reminders off never asks for permission', (tester) async {
    final notifier = await _pumpSettings(tester, remindersEnabled: true);

    await tester.tap(find.text('Gentle reminders'));
    await tester.pumpAndSettle();

    expect(notifier.permissionRequested, isFalse);
  });

  testWidgets('opens Credits with the Lucide badge-icon attribution', (tester) async {
    await _pumpSettings(tester);

    await tester.tap(find.text('Credits'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Badge icons adapted from Lucide'), findsOneWidget);
    expect(find.textContaining('ISC License'), findsOneWidget);
  });
}
