import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onehealth_ui/core/mode/app_mode.dart';
import 'package:onehealth_ui/data/repositories/assessment_repository.dart';
import 'package:onehealth_ui/data/repositories/auth_repository.dart';
import 'package:onehealth_ui/data/repositories/reference_repository.dart';
import 'package:onehealth_ui/data/repositories/repository_bundle.dart';
import 'package:onehealth_ui/data/repositories/repository_models.dart';
import 'package:onehealth_ui/data/repositories/repository_scope.dart';
import 'package:onehealth_ui/data/repositories/site_repository.dart';
import 'package:onehealth_ui/features/impact/impact_screen.dart';
import 'package:onehealth_ui/l10n/generated/app_localizations.dart';

void main() {
  testWidgets('shows a friendly action when there are no saved checks', (
    tester,
  ) async {
    await _pumpImpact(tester);

    expect(find.text('No checks yet'), findsOneWidget);
    expect(find.text('Check a stream'), findsOneWidget);
  });

  testWidgets('summarises saved checks and opens their factual receipt', (
    tester,
  ) async {
    await _pumpImpact(
      tester,
      history: <AssessmentRecord>[
        AssessmentRecord(
          id: 'one',
          siteCode: 'DEMO-RIVER-01',
          submittedAt: DateTime.utc(2026, 9, 1),
          overallAssessment: 'GOOD',
          fileIds: const <AssessmentMediaRole, String>{
            AssessmentMediaRole.upstreamPhoto: 'upstream',
            AssessmentMediaRole.downstreamPhoto: 'downstream',
          },
        ),
        AssessmentRecord(
          id: 'two',
          siteCode: 'DEMO-BROOK-02',
          submittedAt: DateTime.utc(2026, 9, 2),
          overallAssessment: 'MODERATE',
          fileIds: const <AssessmentMediaRole, String>{
            AssessmentMediaRole.video: 'video-does-not-count-as-photo',
          },
        ),
      ],
    );

    expect(find.text('Checks submitted'), findsOneWidget);
    expect(find.text('Streams covered'), findsOneWidget);
    expect(find.text('Photos included'), findsOneWidget);
    expect(find.text('2'), findsNWidgets(3));
    expect(find.text('Willow Bend Stream'), findsOneWidget);
    expect(find.text('Old Mill Brook'), findsOneWidget);

    await tester.tap(find.text('Willow Bend Stream'));
    await tester.pumpAndSettle();

    expect(find.text('Check receipt'), findsOneWidget);
    expect(find.text('2 of 4'), findsOneWidget);
  });
}

class _FakeAssessmentRepository implements AssessmentRepository {
  const _FakeAssessmentRepository(this.historyResult);

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

Future<void> _pumpImpact(
  WidgetTester tester, {
  List<AssessmentRecord> history = const <AssessmentRecord>[],
}) async {
  final repositories = RepositoryBundle(
    auth: DemoAuthRepository(),
    sites: DemoSiteRepository(),
    references: DemoReferenceRepository(),
    assessments: _FakeAssessmentRepository(history),
  );
  await tester.pumpWidget(
    RepositoryScope(
      mode: AppMode.demo,
      repositories: repositories,
      child: MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const Scaffold(body: ImpactScreen()),
      ),
    ),
  );
  await tester.pumpAndSettle();
}
