import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:onehealth_ui/core/mode/app_mode.dart';
import 'package:onehealth_ui/data/repositories/assessment_repository.dart';
import 'package:onehealth_ui/data/repositories/auth_repository.dart';
import 'package:onehealth_ui/data/repositories/reference_repository.dart';
import 'package:onehealth_ui/data/repositories/repository_bundle.dart';
import 'package:onehealth_ui/data/repositories/repository_models.dart';
import 'package:onehealth_ui/data/repositories/repository_scope.dart';
import 'package:onehealth_ui/data/repositories/site_repository.dart';
import 'package:onehealth_ui/features/home/site_detail_screen.dart';
import 'package:onehealth_ui/l10n/generated/app_localizations.dart';

const _site = StreamSite(
  code: 'UG-COU-04',
  name: 'Ribeira de Couros',
  latitude: 41.444,
  longitude: -8.296,
  cityName: 'Guimarães',
);

const _siteWithoutCity = StreamSite(
  code: 'DEMO-RIVER-01',
  name: 'Willow Bend Stream',
  latitude: 41.444,
  longitude: -8.296,
);

void main() {
  testWidgets('renders the human name with the research code secondary', (
    tester,
  ) async {
    await _pumpSiteDetail(tester, site: _siteWithoutCity);

    expect(find.text('Willow Bend Stream'), findsOneWidget);
    expect(find.text('Site code DEMO-RIVER-01'), findsOneWidget);
  });

  testWidgets('includes the city when known', (tester) async {
    await _pumpSiteDetail(tester, site: _site);

    expect(find.text('Guimarães · site code UG-COU-04'), findsOneWidget);
  });

  testWidgets('shows a safety note under Before you go', (tester) async {
    await _pumpSiteDetail(tester, site: _site);

    expect(find.text('Before you go'), findsOneWidget);
    expect(
      find.text(
        'Stay on public paths, never enter the water, and bring a friend when you can.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('shows never-checked when there is no history for this site', (
    tester,
  ) async {
    await _pumpSiteDetail(tester, site: _site);

    expect(find.text("You haven't checked this stream yet"), findsOneWidget);
  });

  testWidgets('shows a days-ago freshness cue from the citizen\'s own history', (
    tester,
  ) async {
    await _pumpSiteDetail(
      tester,
      site: _site,
      history: <AssessmentRecord>[
        AssessmentRecord(
          id: 'r1',
          siteCode: _site.code,
          submittedAt: DateTime.now().toUtc().subtract(const Duration(days: 3)),
        ),
      ],
    );

    expect(find.text('You last checked this stream 3 days ago'), findsOneWidget);
  });

  testWidgets('shows the demo-seeded health timeline for a bundled demo site', (
    tester,
  ) async {
    await _pumpSiteDetail(tester, site: _siteWithoutCity);

    expect(find.text('Past checks'), findsOneWidget);
    // DEMO-RIVER-01's seed data (see `demo_stream_health_seed.dart`) is one
    // GOOD and one MODERATE check -- no real history was passed here.
    expect(find.text('Good'), findsOneWidget);
    expect(find.text('Moderate'), findsOneWidget);
  });

  testWidgets('shows an empty timeline for a site with no checks and no seed data', (
    tester,
  ) async {
    await _pumpSiteDetail(tester, site: _site);

    expect(find.text('No past checks yet for this stream.'), findsOneWidget);
  });

  testWidgets('a real check appears on the timeline alongside the freshness cue', (
    tester,
  ) async {
    await _pumpSiteDetail(
      tester,
      site: _site,
      history: <AssessmentRecord>[
        AssessmentRecord(
          id: 'r1',
          siteCode: _site.code,
          submittedAt: DateTime.now().toUtc().subtract(const Duration(days: 3)),
          overallAssessment: 'POOR',
        ),
      ],
    );

    expect(find.text('Poor'), findsOneWidget);
  });

  testWidgets('Check this stream pushes to the assess route with the full site', (
    tester,
  ) async {
    await _pumpSiteDetail(tester, site: _site);

    await tester.tap(find.byKey(const Key('siteDetailCheckAction')));
    await tester.pumpAndSettle();

    expect(find.textContaining('check-placeholder:Ribeira de Couros'), findsOneWidget);
  });

  testWidgets(
    'Get directions falls back to a friendly message with no maps app available',
    (tester) async {
      await _pumpSiteDetail(tester, site: _site);

      await tester.tap(find.byKey(const Key('siteDetailDirectionsAction')));
      await tester.pumpAndSettle();

      expect(
        find.text("Couldn't open a maps app. Check that one is installed."),
        findsOneWidget,
      );
    },
  );

  testWidgets('a missing site shows a guiding state with a way back to the map', (
    tester,
  ) async {
    await _pumpSiteDetail(tester, site: null);

    expect(find.text('Stream not found'), findsOneWidget);

    await tester.tap(find.text('Back to map'));
    await tester.pumpAndSettle();

    expect(find.text('home-placeholder'), findsOneWidget);
  });
}

Future<void> _pumpSiteDetail(
  WidgetTester tester, {
  required StreamSite? site,
  List<AssessmentRecord> history = const <AssessmentRecord>[],
}) async {
  final bundle = RepositoryBundle(
    auth: DemoAuthRepository(),
    sites: DemoSiteRepository(),
    references: DemoReferenceRepository(),
    assessments: _FakeAssessmentRepository(historyResult: history),
  );
  final router = GoRouter(
    initialLocation: '/site/${site?.code ?? 'missing'}',
    routes: <RouteBase>[
      GoRoute(
        path: '/site/:code',
        builder: (context, state) => SiteDetailScreen(
          code: state.pathParameters['code']!,
          site: site,
        ),
      ),
      GoRoute(
        path: '/check/assess',
        builder: (context, state) => Scaffold(
          body: Text(
            'check-placeholder:${(state.extra as StreamSite?)?.name ?? ''}',
          ),
        ),
      ),
      GoRoute(
        path: '/home',
        builder: (context, state) => const Scaffold(
          body: Text('home-placeholder'),
        ),
      ),
    ],
  );
  addTearDown(router.dispose);

  await tester.pumpWidget(
    RepositoryScope(
      mode: AppMode.demo,
      repositories: bundle,
      child: MaterialApp.router(
        routerConfig: router,
        locale: const Locale('en'),
        localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
      ),
    ),
  );
  await tester.pumpAndSettle();
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
