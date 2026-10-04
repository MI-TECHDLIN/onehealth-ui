import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:onehealth_ui/app/app_router.dart';
import 'package:onehealth_ui/core/mode/app_mode.dart';
import 'package:onehealth_ui/core/settings/app_preferences.dart';
import 'package:onehealth_ui/core/settings/app_settings_controller.dart';
import 'package:onehealth_ui/data/repositories/assessment_repository.dart';
import 'package:onehealth_ui/data/repositories/auth_repository.dart';
import 'package:onehealth_ui/data/repositories/reference_repository.dart';
import 'package:onehealth_ui/data/repositories/repository_bundle.dart';
import 'package:onehealth_ui/data/repositories/repository_models.dart';
import 'package:onehealth_ui/data/repositories/repository_scope.dart';
import 'package:onehealth_ui/data/repositories/site_repository.dart';
import 'package:onehealth_ui/features/profile/profile_screen.dart';
import 'package:onehealth_ui/l10n/generated/app_localizations.dart';

final DateTime _now = DateTime.utc(2026, 6, 15);

class _FakeAssessmentRepository implements AssessmentRepository {
  _FakeAssessmentRepository(this.historyResult);
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
  Future<AssessmentRecord> submit(AssessmentDraft draft) => throw UnimplementedError();
}

Future<MemoryAppPreferences> _pumpProfile(
  WidgetTester tester, {
  required List<AssessmentRecord> history,
}) async {
  final preferences = MemoryAppPreferences();
  final settings = AppSettingsController.memory();
  addTearDown(settings.dispose);
  final bundle = RepositoryBundle(
    auth: DemoAuthRepository(),
    sites: DemoSiteRepository(),
    references: DemoReferenceRepository(),
    assessments: _FakeAssessmentRepository(history),
  );
  final router = GoRouter(
    initialLocation: AppRoutes.profile,
    routes: <RouteBase>[
      GoRoute(
        path: AppRoutes.profile,
        builder: (context, state) => ProfileScreen(
          preferences: preferences,
          now: () => _now,
        ),
      ),
      GoRoute(
        path: AppRoutes.avatar,
        builder: (context, state) => const Scaffold(body: Text('avatar-stub')),
      ),
      GoRoute(
        path: AppRoutes.home,
        builder: (context, state) => const Scaffold(body: Text('home-stub')),
      ),
    ],
  );
  addTearDown(router.dispose);

  await tester.pumpWidget(
    AppSettingsScope(
      controller: settings,
      child: RepositoryScope(
        mode: AppMode.demo,
        repositories: bundle,
        child: MaterialApp.router(
          routerConfig: router,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return preferences;
}

void main() {
  testWidgets('shows checks-this-season and streams-covered stats from history', (
    tester,
  ) async {
    await _pumpProfile(
      tester,
      history: <AssessmentRecord>[
        AssessmentRecord(id: '1', siteCode: 'DEMO-RIVER-01', submittedAt: _now),
      ],
    );

    expect(find.text('Checks this season'), findsOneWidget);
    expect(find.text('Streams covered'), findsOneWidget);
    expect(find.text('This week: done'), findsOneWidget);
    expect(find.text('1-week run'), findsOneWidget);
  });

  testWidgets('shows this-week-pending and no-run copy with empty history', (tester) async {
    await _pumpProfile(tester, history: const <AssessmentRecord>[]);

    expect(find.text('This week: not yet'), findsOneWidget);
    expect(find.text('No run yet — any check this week starts one'), findsOneWidget);
  });

  testWidgets('an unlocked-but-unopened badge shows as newly unlocked', (tester) async {
    await _pumpProfile(
      tester,
      history: <AssessmentRecord>[
        AssessmentRecord(id: '1', siteCode: 'DEMO-RIVER-01', submittedAt: _now),
      ],
    );

    expect(
      find.bySemanticsLabel('First signal. Newly unlocked. Complete one check.'),
      findsOneWidget,
    );
    expect(
      find.bySemanticsLabel('Three streams. Locked. Visit three streams.'),
      findsOneWidget,
    );
  });

  testWidgets('opening a new badge shows the reveal and acknowledges it', (tester) async {
    final preferences = await _pumpProfile(
      tester,
      history: <AssessmentRecord>[
        AssessmentRecord(id: '1', siteCode: 'DEMO-RIVER-01', submittedAt: _now),
      ],
    );

    await tester.tap(
      find.bySemanticsLabel('First signal. Newly unlocked. Complete one check.'),
    );
    await tester.pumpAndSettle();

    expect(find.text('Badge unlocked!'), findsOneWidget);

    await tester.tap(find.text('Nice!'));
    await tester.pumpAndSettle();

    expect(
      find.bySemanticsLabel('First signal. Unlocked. Complete one check.'),
      findsOneWidget,
    );
    expect(
      await preferences.readString('${AppMode.demo.storageNamespace}.badges.acknowledged'),
      'firstSignal',
    );
  });
}
