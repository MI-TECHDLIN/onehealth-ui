import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:onehealth_ui/core/gamification/reminder_rules.dart';
import 'package:onehealth_ui/core/mode/app_mode.dart';
import 'package:onehealth_ui/core/notifications/reminder_coordinator.dart';
import 'package:onehealth_ui/core/notifications/reminder_notifier.dart';
import 'package:onehealth_ui/core/settings/app_preferences.dart';
import 'package:onehealth_ui/core/settings/app_settings_controller.dart';
import 'package:onehealth_ui/core/widgets/friendly_error_banner.dart';
import 'package:onehealth_ui/data/repositories/api_failure.dart';
import 'package:onehealth_ui/data/repositories/assessment_repository.dart';
import 'package:onehealth_ui/data/repositories/auth_repository.dart';
import 'package:onehealth_ui/data/repositories/reference_repository.dart';
import 'package:onehealth_ui/data/repositories/repository_bundle.dart';
import 'package:onehealth_ui/data/repositories/repository_models.dart';
import 'package:onehealth_ui/data/repositories/repository_scope.dart';
import 'package:onehealth_ui/data/repositories/site_repository.dart';
import 'package:onehealth_ui/features/home/home_map_screen.dart';
import 'package:onehealth_ui/features/home/stream_map_view.dart';
import 'package:onehealth_ui/l10n/generated/app_localizations.dart';

const _siteA = StreamSite(
  code: 'DEMO-A',
  name: 'Willow Bend Stream',
  latitude: 41.444,
  longitude: -8.296,
);
const _siteB = StreamSite(
  code: 'DEMO-B',
  name: 'Old Mill Brook',
  latitude: 41.449,
  longitude: -8.289,
);

void main() {
  testWidgets('shows a loading state before the map appears', (tester) async {
    final pending = Completer<List<StreamSite>>();
    await _pumpHome(
      tester,
      sites: _FakeSiteRepository(pending: pending),
      assessments: _FakeAssessmentRepository(),
      mapBuilder: _recordingMapBuilder(),
    );

    expect(find.text('Finding nearby streams…'), findsOneWidget);

    pending.complete(const <StreamSite>[_siteA]);
    await tester.pumpAndSettle();
    expect(find.text('Finding nearby streams…'), findsNothing);
  });

  testWidgets('a failed load shows a friendly error with retry', (
    tester,
  ) async {
    var attempts = 0;
    await _pumpHome(
      tester,
      sites: _FakeSiteRepository(
        onRequest: () => attempts++,
        error: const ApiFailure(statusCode: 500),
      ),
      assessments: _FakeAssessmentRepository(),
      mapBuilder: _recordingMapBuilder(),
    );

    expect(find.byType(FriendlyErrorBanner), findsOneWidget);
    expect(
      find.textContaining("Something went wrong on our end"),
      findsOneWidget,
    );
    expect(attempts, 1);

    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();
    expect(attempts, 2);
  });

  testWidgets('Needs data and Visited filters change which sites reach the map', (
    tester,
  ) async {
    List<StreamSite>? lastSites;
    await _pumpHome(
      tester,
      sites: _FakeSiteRepository(sitesResult: const <StreamSite>[_siteA, _siteB]),
      assessments: _FakeAssessmentRepository(
        historyResult: <AssessmentRecord>[
          AssessmentRecord(
            id: 'r1',
            siteCode: _siteA.code,
            submittedAt: DateTime.utc(2024, 1, 1),
          ),
        ],
      ),
      mapBuilder: _recordingMapBuilder(onBuild: (sites, _) => lastSites = sites),
    );

    expect(lastSites, hasLength(2));

    await tester.tap(find.text('Needs data'));
    await tester.pumpAndSettle();
    expect(lastSites, <StreamSite>[_siteB]);

    await tester.tap(find.text('Visited'));
    await tester.pumpAndSettle();
    expect(lastSites, <StreamSite>[_siteA]);

    await tester.tap(find.text('Nearby'));
    await tester.pumpAndSettle();
    expect(lastSites, hasLength(2));
  });

  testWidgets('an empty filtered result offers a way back to Nearby', (
    tester,
  ) async {
    await _pumpHome(
      tester,
      sites: _FakeSiteRepository(sitesResult: const <StreamSite>[_siteA]),
      assessments: _FakeAssessmentRepository(),
      mapBuilder: _recordingMapBuilder(),
    );

    await tester.tap(find.text('Visited'));
    await tester.pumpAndSettle();

    expect(find.text('No streams match this filter'), findsOneWidget);
    expect(find.text('Show all streams'), findsOneWidget);

    await tester.tap(find.text('Show all streams'));
    await tester.pumpAndSettle();
    expect(find.text('No streams match this filter'), findsNothing);
  });

  testWidgets(
    'checks for a gentle reminder exactly once per mount, with the loaded data',
    (tester) async {
      final coordinator = _SpyReminderCoordinator();
      final settings = AppSettingsController.memory();
      addTearDown(settings.dispose);
      final history = <AssessmentRecord>[
        AssessmentRecord(
          id: 'r1',
          siteCode: _siteA.code,
          submittedAt: DateTime.now().toUtc().subtract(const Duration(days: 40)),
        ),
      ];

      await _pumpHome(
        tester,
        sites: _FakeSiteRepository(sitesResult: const <StreamSite>[_siteA, _siteB]),
        assessments: _FakeAssessmentRepository(historyResult: history),
        mapBuilder: _recordingMapBuilder(),
        settings: settings,
        reminderCoordinator: coordinator,
      );

      expect(coordinator.callCount, 1);
      expect(coordinator.lastMode, AppMode.demo);
      expect(coordinator.lastRemindersEnabled, isTrue);
      expect(coordinator.lastHistory, history);
      expect(coordinator.lastSiteNames, <String, String>{
        _siteA.code: _siteA.name,
        _siteB.code: _siteB.name,
      });

      // Reopening the filter chips re-renders but must not re-fire the check.
      await tester.tap(find.text('Needs data'));
      await tester.pumpAndSettle();
      expect(coordinator.callCount, 1);
    },
  );
}

Future<void> _pumpHome(
  WidgetTester tester, {
  required SiteRepository sites,
  required AssessmentRepository assessments,
  required StreamMapViewBuilder mapBuilder,
  // Most tests here predate the gentle-reminder check and never provide an
  // AppSettingsScope at all; HomeMapScreen skips that check quietly when
  // one isn't found (see its `_maybeShowReminder`), so only wrap one when a
  // test actually needs it.
  AppSettingsController? settings,
  ReminderCoordinator? reminderCoordinator,
}) async {
  final bundle = RepositoryBundle(
    auth: DemoAuthRepository(),
    sites: sites,
    references: DemoReferenceRepository(),
    assessments: assessments,
  );
  final repositoryScope = RepositoryScope(
    mode: AppMode.demo,
    repositories: bundle,
    child: MaterialApp(
      locale: const Locale('en'),
      localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: HomeMapScreen(
          mapViewBuilder: mapBuilder,
          reminderCoordinator: reminderCoordinator,
        ),
      ),
    ),
  );
  await tester.pumpWidget(
    settings == null
        ? repositoryScope
        : AppSettingsScope(controller: settings, child: repositoryScope),
  );
  await tester.pumpAndSettle();
}

/// A map builder that never touches MapLibre; it just records what it was
/// given so filter/data-flow logic can be asserted without a real map.
StreamMapViewBuilder _recordingMapBuilder({
  void Function(List<StreamSite> sites, Set<String> visitedCodes)? onBuild,
}) =>
    ({
      required List<StreamSite> sites,
      required Set<String> visitedCodes,
      required bool myLocationEnabled,
      required ValueChanged<StreamSite> onSiteTapped,
      required ValueChanged<MapLibreMapController> onControllerReady,
    }) {
      onBuild?.call(sites, visitedCodes);
      return const SizedBox.shrink();
    };

class _FakeSiteRepository implements SiteRepository {
  _FakeSiteRepository({
    this.sitesResult,
    this.error,
    this.pending,
    this.onRequest,
  });

  final List<StreamSite>? sitesResult;
  final Object? error;
  final Completer<List<StreamSite>>? pending;
  final VoidCallback? onRequest;

  @override
  Future<List<StreamSite>> nearbySites({double? latitude, double? longitude}) {
    onRequest?.call();
    if (pending != null) return pending!.future;
    if (error != null) return Future<List<StreamSite>>.error(error!);
    return Future<List<StreamSite>>.value(sitesResult ?? const <StreamSite>[]);
  }

  @override
  Future<List<StreamSite>> mySites() async =>
      sitesResult ?? const <StreamSite>[];

  @override
  Future<StreamSite> createSite({
    required String name,
    required double latitude,
    required double longitude,
  }) => throw UnimplementedError();
}

class _FakeAssessmentRepository implements AssessmentRepository {
  _FakeAssessmentRepository({this.historyResult = const <AssessmentRecord>[]});

  final List<AssessmentRecord> historyResult;

  @override
  Future<Map<String, dynamic>> contentForLocale(String languageCode) async =>
      <String, dynamic>{};

  @override
  Future<List<AssessmentDraft>> drafts() async => const <AssessmentDraft>[];

  @override
  Future<List<AssessmentRecord>> history() async => historyResult;

  @override
  Future<void> saveDraft(AssessmentDraft draft) async {}

  @override
  Future<AssessmentRecord> submit(AssessmentDraft draft) =>
      throw UnimplementedError();
}

class _NoopReminderNotifier implements ReminderNotifier {
  @override
  Future<bool> ensurePermission() async => true;

  @override
  Future<void> showReminder({required String title, required String body}) async {}
}

/// Records how `HomeMapScreen` calls its `ReminderCoordinator`, without
/// touching the pure decision logic or the real plugin -- both already have
/// their own focused tests.
class _SpyReminderCoordinator extends ReminderCoordinator {
  _SpyReminderCoordinator()
    : super(preferences: MemoryAppPreferences(), notifier: _NoopReminderNotifier());

  int callCount = 0;
  AppMode? lastMode;
  bool? lastRemindersEnabled;
  List<AssessmentRecord>? lastHistory;
  Map<String, String>? lastSiteNames;

  @override
  Future<void> maybeNotify({
    required AppMode mode,
    required bool remindersEnabled,
    required List<AssessmentRecord> history,
    required Map<String, String> siteNamesByCode,
    required ({String title, String body}) Function(ReminderCandidate candidate)
    buildMessage,
  }) async {
    callCount += 1;
    lastMode = mode;
    lastRemindersEnabled = remindersEnabled;
    lastHistory = history;
    lastSiteNames = siteNamesByCode;
  }
}
