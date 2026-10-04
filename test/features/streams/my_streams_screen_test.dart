import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:onehealth_ui/core/drafts/draft_queue_status_source.dart';
import 'package:onehealth_ui/core/mode/app_mode.dart';
import 'package:onehealth_ui/data/repositories/assessment_repository.dart';
import 'package:onehealth_ui/data/repositories/auth_repository.dart';
import 'package:onehealth_ui/data/repositories/reference_repository.dart';
import 'package:onehealth_ui/data/repositories/repository_bundle.dart';
import 'package:onehealth_ui/data/repositories/repository_models.dart';
import 'package:onehealth_ui/data/repositories/repository_scope.dart';
import 'package:onehealth_ui/data/repositories/site_repository.dart';
import 'package:onehealth_ui/features/streams/my_streams_screen.dart';
import 'package:onehealth_ui/l10n/generated/app_localizations.dart';

void main() {
  testWidgets('shows a guiding empty state with no drafts or history', (tester) async {
    await _pumpMyStreams(tester);

    expect(find.text('No checks yet'), findsOneWidget);
    expect(find.text('Check a stream'), findsOneWidget);
  });

  testWidgets('lists a draft under Continue and a submitted check under History', (
    tester,
  ) async {
    await _pumpMyStreams(
      tester,
      drafts: <AssessmentDraft>[
        const AssessmentDraft(id: 'draft-1', siteCode: 'DEMO-RIVER-01'),
      ],
      history: <AssessmentRecord>[
        AssessmentRecord(
          id: 'r1',
          siteCode: 'DEMO-BROOK-02',
          submittedAt: DateTime.utc(2026, 1, 1),
          overallAssessment: 'GOOD',
        ),
      ],
    );

    expect(find.text('Continue where you left off'), findsOneWidget);
    expect(find.text('Willow Bend Stream'), findsOneWidget);
    expect(find.text('Draft'), findsOneWidget);

    expect(find.text('History'), findsOneWidget);
    expect(find.text('Old Mill Brook'), findsOneWidget);
    expect(find.text('Good'), findsOneWidget);
  });

  testWidgets('a queued draft shows the queued status instead of draft', (tester) async {
    await _pumpMyStreams(
      tester,
      drafts: <AssessmentDraft>[
        const AssessmentDraft(id: 'draft-1', siteCode: 'DEMO-RIVER-01'),
      ],
      queuedDraftIds: <String>{'draft-1'},
    );

    expect(find.text('Queued to upload'), findsOneWidget);
    expect(find.text('Draft'), findsNothing);
  });

  testWidgets('tapping Continue on a draft resumes the assessment for that site', (
    tester,
  ) async {
    await _pumpMyStreams(
      tester,
      drafts: <AssessmentDraft>[
        const AssessmentDraft(id: 'draft-1', siteCode: 'DEMO-RIVER-01'),
      ],
    );

    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    expect(find.textContaining('check-placeholder:Willow Bend Stream'), findsOneWidget);
  });

  testWidgets('tapping a history card opens a read-only receipt', (tester) async {
    await _pumpMyStreams(
      tester,
      history: <AssessmentRecord>[
        AssessmentRecord(
          id: 'r1',
          siteCode: 'DEMO-CREEK-03',
          submittedAt: DateTime.utc(2026, 2, 3),
          overallAssessment: 'POOR',
          fileIds: const <AssessmentMediaRole, String>{
            AssessmentMediaRole.upstreamPhoto: 'f1',
          },
        ),
      ],
    );

    await tester.tap(find.text('Meadow Gate Creek'));
    await tester.pumpAndSettle();

    expect(find.text('Check receipt'), findsOneWidget);
    // The My Streams card underneath also shows the site name, so this
    // route keeps both mounted (`PageRoute.maintainState` defaults to true).
    expect(find.text('Meadow Gate Creek'), findsWidgets);
    expect(find.text('Poor'), findsWidgets);
    expect(find.text('1 of 4'), findsOneWidget);
  });
}

class _FakeAssessmentRepository implements AssessmentRepository {
  _FakeAssessmentRepository({
    this.draftsResult = const <AssessmentDraft>[],
    this.historyResult = const <AssessmentRecord>[],
  });

  final List<AssessmentDraft> draftsResult;
  final List<AssessmentRecord> historyResult;

  @override
  Future<Map<String, dynamic>> contentForLocale(String languageCode) async =>
      <String, dynamic>{};

  @override
  Future<List<AssessmentDraft>> drafts() async => draftsResult;

  @override
  Future<List<AssessmentRecord>> history() async => historyResult;

  @override
  Future<void> saveDraft(AssessmentDraft draft) async {}

  @override
  Future<AssessmentRecord> submit(AssessmentDraft draft) => throw UnimplementedError();
}

class _FakeQueueStatusSource implements DraftQueueStatusSource {
  _FakeQueueStatusSource(this._ids);
  final Set<String> _ids;

  @override
  Future<Set<String>> queuedDraftIds() async => _ids;
}

Future<void> _pumpMyStreams(
  WidgetTester tester, {
  List<AssessmentDraft> drafts = const <AssessmentDraft>[],
  List<AssessmentRecord> history = const <AssessmentRecord>[],
  Set<String> queuedDraftIds = const <String>{},
}) async {
  final bundle = RepositoryBundle(
    auth: DemoAuthRepository(),
    sites: DemoSiteRepository(),
    references: DemoReferenceRepository(),
    assessments: _FakeAssessmentRepository(
      draftsResult: drafts,
      historyResult: history,
    ),
  );
  final router = GoRouter(
    initialLocation: '/streams',
    routes: <RouteBase>[
      GoRoute(
        path: '/streams',
        builder: (context, state) => Scaffold(
          body: MyStreamsScreen(
            queueStatusSource: _FakeQueueStatusSource(queuedDraftIds),
          ),
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
        builder: (context, state) => const Scaffold(body: Text('home-placeholder')),
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
