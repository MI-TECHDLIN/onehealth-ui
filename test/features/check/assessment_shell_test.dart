import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:onehealth_ui/core/mode/app_mode.dart';
import 'package:onehealth_ui/core/settings/app_settings_controller.dart';
import 'package:onehealth_ui/core/widgets/aqua_components.dart';
import 'package:onehealth_ui/data/assessment/assessment_protocol.dart';
import 'package:onehealth_ui/data/repositories/repository_bundle.dart';
import 'package:onehealth_ui/data/repositories/repository_models.dart';
import 'package:onehealth_ui/data/repositories/repository_scope.dart';
import 'package:onehealth_ui/features/check/assessment_shell.dart';
import 'package:onehealth_ui/l10n/generated/app_localizations.dart';

const _site = StreamSite(
  code: 'DEMO-RIVER-01',
  name: 'Willow Bend Stream',
  latitude: 41.444,
  longitude: -8.296,
);

Future<RepositoryBundle> _pumpShell(
  WidgetTester tester, {
  RepositoryBundle? bundle,
}) async {
  final repositories = bundle ?? RepositoryBundle.demo();
  final settings = AppSettingsController.memory();
  await settings.load();
  final router = GoRouter(
    initialLocation: '/check/assess',
    routes: <RouteBase>[
      GoRoute(
        path: '/check/assess',
        builder: (context, state) => AssessmentShell(site: _site),
      ),
      GoRoute(
        path: '/home',
        builder: (context, state) =>
            const Scaffold(body: Text('home-placeholder')),
      ),
      GoRoute(
        path: '/check/photos',
        builder: (context, state) =>
            const Scaffold(body: Text('photos-placeholder')),
      ),
    ],
  );
  addTearDown(router.dispose);
  addTearDown(settings.dispose);

  await tester.pumpWidget(
    RepositoryScope(
      mode: AppMode.demo,
      repositories: repositories,
      child: AppSettingsScope(
        controller: settings,
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
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(disableAnimations: true),
            child: child!,
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return repositories;
}

Future<void> _tapNext(WidgetTester tester) async {
  await tester.tap(find.text('Next'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('renders illustrated cards and water-flow answer chips', (
    tester,
  ) async {
    await _pumpShell(tester);

    expect(find.byType(PictureChoiceCard), findsNWidgets(3));
    expect(find.text('Flat (A)'), findsOneWidget);
    expect(find.text('U Shape (B)'), findsOneWidget);
    expect(find.text('V Shape (C)'), findsOneWidget);

    for (var i = 0; i < 5; i++) {
      await _tapNext(tester);
    }

    expect(find.text('How is the water flowing'), findsOneWidget);
    expect(find.text('Fast (with waves or high velocity) (A)'), findsOneWidget);
    expect(find.text('Slow (B)'), findsOneWidget);
    expect(find.text('Stagnant/intermittent (C)'), findsOneWidget);
    expect(find.text('Dry (D)'), findsOneWidget);
    expect(find.byType(AquaFilterChip), findsNWidgets(4));
  });

  testWidgets('starts on the first question and Next/Back navigate between pages', (
    tester,
  ) async {
    await _pumpShell(tester);

    expect(find.text('The channel form is...'), findsOneWidget);

    await _tapNext(tester);
    expect(find.text('The bottom of the wet channel is…'), findsOneWidget);
    expect(find.text('Back'), findsOneWidget);

    await tester.tap(find.text('Back'));
    await tester.pumpAndSettle();
    expect(find.text('The channel form is...'), findsOneWidget);
  });

  testWidgets('saves an answer to the draft as soon as it is picked', (
    tester,
  ) async {
    final repositories = await _pumpShell(tester);

    await tester.tap(find.text('U Shape (B)'));
    await tester.pumpAndSettle();

    final drafts = await repositories.assessments.drafts();
    expect(drafts, hasLength(1));
    expect(drafts.single.channelForm, 'U');
    expect(drafts.single.siteCode, _site.code);
  });

  testWidgets(
    'required gating blocks Next on overall assessment until answered',
    (tester) async {
      await _pumpShell(tester);

      // Step through every optional question to reach the required overall
      // assessment page (index 18) without answering any of them.
      for (var i = 0; i < 18; i++) {
        await _tapNext(tester);
      }

      expect(
        find.text(
          'Provide an overall assessment of the stream ecosystem health (choose one of the below possibilities)',
        ),
        findsOneWidget,
      );
      AquaButton nextButton() =>
          tester.widget<AquaButton>(find.widgetWithText(AquaButton, 'Next'));
      expect(nextButton().onPressed, isNull);

      await tester.tap(find.text('Good quality'));
      await tester.pumpAndSettle();
      expect(nextButton().onPressed, isNotNull);
      await _tapNext(tester);

      expect(find.text('Which feeling(s) best describe your experience?'), findsOneWidget);
    },
  );

  testWidgets('offers to resume a saved draft, restoring its answers', (
    tester,
  ) async {
    final repositories = RepositoryBundle.demo();
    final seeded = AssessmentDraft(
      id: 'assess-${_site.code}-seed',
      siteCode: _site.code,
    ).withYesNo(
      AssessmentQuestion(
        id: 'hasDams',
        payloadField: 'hasDams',
        step: 5,
        type: AssessmentFieldType.yesNoNotSure,
        title: 'Barriers',
        prompt: 'Do you see any dams?',
      ),
      value: true,
    );
    await repositories.assessments.saveDraft(seeded);

    await _pumpShell(tester, bundle: repositories);

    expect(
      find.text("You have an unfinished stream check for Willow Bend Stream."),
      findsOneWidget,
    );

    await tester.tap(find.text('Continue checking'));
    await tester.pumpAndSettle();

    final drafts = await repositories.assessments.drafts();
    expect(drafts.single.hasDams, isTrue);
  });

  testWidgets('starting over resets a saved draft', (tester) async {
    final repositories = RepositoryBundle.demo();
    final seeded = AssessmentDraft(
      id: 'assess-${_site.code}-seed',
      siteCode: _site.code,
      channelForm: 'FLAT',
      answeredQuestionIds: const <String>{'channelForm'},
    );
    await repositories.assessments.saveDraft(seeded);

    await _pumpShell(tester, bundle: repositories);
    await tester.tap(find.text('Start over'));
    await tester.pumpAndSettle();

    final drafts = await repositories.assessments.drafts();
    expect(drafts.single.channelForm, isNull);
  });

  testWidgets('save and exit returns to the map after confirming', (
    tester,
  ) async {
    await _pumpShell(tester);

    await tester.tap(find.byTooltip('Save and exit'));
    await tester.pumpAndSettle();
    expect(find.text('Save and exit?'), findsOneWidget);

    await tester.tap(find.text('Save and exit'));
    await tester.pumpAndSettle();

    expect(find.text('home-placeholder'), findsOneWidget);
  });
}
