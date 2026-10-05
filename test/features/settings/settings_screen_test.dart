import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:onehealth_ui/core/haptics/app_haptics.dart';
import 'package:onehealth_ui/core/mode/app_mode.dart';
import 'package:onehealth_ui/core/notifications/reminder_notifier.dart';
import 'package:onehealth_ui/core/settings/app_preferences.dart';
import 'package:onehealth_ui/core/settings/app_settings_controller.dart';
import 'package:onehealth_ui/data/repositories/assessment_repository.dart';
import 'package:onehealth_ui/data/repositories/repository_bundle.dart';
import 'package:onehealth_ui/data/repositories/repository_models.dart';
import 'package:onehealth_ui/data/repositories/repository_scope.dart';
import 'package:onehealth_ui/features/settings/settings_screen.dart';
import 'package:onehealth_ui/l10n/generated/app_localizations.dart';

class _RecordingHapticDriver implements HapticDriver {
  final List<String> calls = <String>[];

  @override
  Future<void> heavyImpact() async => calls.add('heavy');

  @override
  Future<void> lightImpact() async => calls.add('light');

  @override
  Future<void> mediumImpact() async => calls.add('medium');

  @override
  Future<void> vibrate() async => calls.add('vibrate');
}

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

class _DemoSettingsHarness {
  const _DemoSettingsHarness({
    required this.settings,
    required this.repositoryPreferences,
    required this.hapticDriver,
  });

  final AppSettingsController settings;
  final AppPreferences repositoryPreferences;
  final _RecordingHapticDriver hapticDriver;
}

Future<_DemoSettingsHarness> _pumpDemoSettings(
  WidgetTester tester, {
  AppMode mode = AppMode.demo,
}) async {
  final settings = AppSettingsController.memory();
  await settings.setMode(mode);
  addTearDown(settings.dispose);
  final repositoryPreferences = MemoryAppPreferences();
  final repositories = RepositoryBundle.demo(preferences: repositoryPreferences);
  final hapticDriver = _RecordingHapticDriver();

  final router = GoRouter(
    initialLocation: '/settings',
    routes: <RouteBase>[
      GoRoute(
        path: '/settings',
        builder: (context, state) => SettingsScreen(
          haptics: AppHaptics(driver: hapticDriver),
          preferences: repositoryPreferences,
        ),
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
      child: AnimatedBuilder(
        animation: settings,
        builder: (context, _) => RepositoryScope(
          mode: settings.mode,
          repositories: repositories,
          child: MaterialApp.router(
            routerConfig: router,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();

  return _DemoSettingsHarness(
    settings: settings,
    repositoryPreferences: repositoryPreferences,
    hapticDriver: hapticDriver,
  );
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

  testWidgets('Reset demo is visible in Demo mode and hidden in Live mode', (
    tester,
  ) async {
    await _pumpDemoSettings(tester, mode: AppMode.demo);
    expect(find.byKey(const Key('settingsResetDemoTile')), findsOneWidget);

    await _pumpDemoSettings(tester, mode: AppMode.live);
    expect(find.byKey(const Key('settingsResetDemoTile')), findsNothing);
  });

  testWidgets('canceling Reset demo leaves seeded data untouched', (tester) async {
    final harness = await _pumpDemoSettings(tester);
    final assessments =
        RepositoryBundle.demo(preferences: harness.repositoryPreferences)
                .assessments
            as DemoAssessmentRepository;
    await assessments.seedHistory(<AssessmentRecord>[
      const AssessmentRecord(
        id: 'seed-1',
        siteCode: 'DEMO-RIVER-01',
        submittedAt: DateTime.utc(2026, 1, 1),
        overallAssessment: 'GOOD',
      ),
    ]);

    await tester.tap(find.byKey(const Key('settingsResetDemoTile')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(await assessments.history(), hasLength(1));
    expect(harness.hapticDriver.calls, isEmpty);
  });

  testWidgets('confirming Reset demo wipes and reseeds the demo story', (tester) async {
    final harness = await _pumpDemoSettings(tester);
    final assessments =
        RepositoryBundle.demo(preferences: harness.repositoryPreferences)
                .assessments
            as DemoAssessmentRepository;
    await assessments.seedHistory(<AssessmentRecord>[
      const AssessmentRecord(
        id: 'judge-own-check',
        siteCode: 'DEMO-RIVER-01',
        submittedAt: DateTime.utc(2026, 1, 1),
        overallAssessment: 'GOOD',
      ),
    ]);

    await tester.tap(find.byKey(const Key('settingsResetDemoTile')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('settingsResetDemoConfirmButton')));
    await tester.pumpAndSettle();

    final history = await assessments.history();
    expect(history, hasLength(8));
    expect(history.any((record) => record.id == 'judge-own-check'), isFalse);
    expect(harness.hapticDriver.calls, contains('medium'));
    expect(find.text('Demo data reset.'), findsOneWidget);
  });

  testWidgets('holding the version line ~2s restarts onboarding with a haptic', (
    tester,
  ) async {
    final harness = await _pumpDemoSettings(tester);

    final gesture = await tester.startGesture(
      tester.getCenter(find.textContaining('OneAquaHealth v')),
    );
    await tester.pump(const Duration(seconds: 2, milliseconds: 100));
    await gesture.up();
    await tester.pumpAndSettle();

    expect(harness.hapticDriver.calls, <String>['light']);
    expect(find.text('onboarding-stub'), findsOneWidget);
  });

  testWidgets('releasing the version line before ~2s does nothing', (tester) async {
    final harness = await _pumpDemoSettings(tester);

    final gesture = await tester.startGesture(
      tester.getCenter(find.textContaining('OneAquaHealth v')),
    );
    await tester.pump(const Duration(milliseconds: 800));
    await gesture.up();
    await tester.pumpAndSettle();

    expect(harness.hapticDriver.calls, isEmpty);
    expect(find.text('onboarding-stub'), findsNothing);
  });
}
