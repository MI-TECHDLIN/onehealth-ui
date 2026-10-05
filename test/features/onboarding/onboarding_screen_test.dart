import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:onehealth_ui/app/app_router.dart';
import 'package:onehealth_ui/core/mode/app_mode.dart';
import 'package:onehealth_ui/core/settings/app_preferences.dart';
import 'package:onehealth_ui/core/settings/app_settings_controller.dart';
import 'package:onehealth_ui/data/repositories/repository_bundle.dart';
import 'package:onehealth_ui/data/repositories/repository_scope.dart';
import 'package:onehealth_ui/features/onboarding/onboarding_screen.dart';
import 'package:onehealth_ui/l10n/generated/app_localizations.dart';

Widget _wrap(Widget child, AppSettingsController settings) =>
    AppSettingsScope(
      controller: settings,
      child: AnimatedBuilder(
        animation: settings,
        builder: (context, _) => child,
      ),
    );

Widget _wrapWithRepositories(
  Widget child,
  AppSettingsController settings,
  RepositoryBundle repositories,
) => AppSettingsScope(
  controller: settings,
  child: AnimatedBuilder(
    animation: settings,
    builder: (context, _) => RepositoryScope(
      mode: settings.mode,
      repositories: repositories,
      child: child,
    ),
  ),
);

Widget _app(GoRouter router) => MaterialApp.router(
  routerConfig: router,
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  builder: (context, child) => MediaQuery(
    data: MediaQuery.of(context).copyWith(disableAnimations: true),
    child: child!,
  ),
);

void main() {
  late AppSettingsController settings;

  setUp(() {
    settings = AppSettingsController.memory();
  });

  tearDown(() {
    settings.dispose();
  });

  testWidgets('first screen shows the problem story and a Skip action', (
    tester,
  ) async {
    final router = createAppRouter(initialLocation: AppRoutes.onboarding);
    addTearDown(router.dispose);

    await tester.pumpWidget(
      _wrap(_app(router), settings),
    );
    await tester.pumpAndSettle();

    expect(find.text('Your stream is part of city health'), findsOneWidget);
    expect(find.text('Show me how'), findsOneWidget);
    expect(find.text('Skip'), findsOneWidget);
  });

  testWidgets('Continue advances through the story in order', (tester) async {
    final router = createAppRouter(initialLocation: AppRoutes.onboarding);
    addTearDown(router.dispose);

    await tester.pumpWidget(
      _wrap(_app(router), settings),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Show me how'));
    await tester.pumpAndSettle();
    expect(find.text('One stream. Many lives.'), findsOneWidget);
    expect(find.text('Continue'), findsOneWidget);
    expect(find.text('Skip'), findsNothing);
  });

  testWidgets('Skip jumps straight to the final screen', (tester) async {
    final router = createAppRouter(initialLocation: AppRoutes.onboarding);
    addTearDown(router.dispose);

    await tester.pumpWidget(
      _wrap(_app(router), settings),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Skip'));
    await tester.pumpAndSettle();

    expect(find.text('Ready when you are'), findsOneWidget);
    expect(find.text('Get started'), findsOneWidget);
    expect(find.text('Look around first'), findsOneWidget);
  });

  testWidgets('the data-journey screen carries the field safety reminder', (
    tester,
  ) async {
    final router = createAppRouter(initialLocation: AppRoutes.onboarding);
    addTearDown(router.dispose);

    await tester.pumpWidget(
      _wrap(_app(router), settings),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Show me how'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    expect(find.text('Your data reaches researchers'), findsOneWidget);
    expect(find.text('A quick safety reminder'), findsOneWidget);
    expect(
      find.text('Stay on the bank. Never enter the water.'),
      findsOneWidget,
    );
  });

  testWidgets('Get started marks onboarding complete and hands off to sign-in', (
    tester,
  ) async {
    final router = createAppRouter(initialLocation: AppRoutes.onboarding);
    addTearDown(router.dispose);

    await tester.pumpWidget(
      _wrap(_app(router), settings),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Skip'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Get started'));
    await tester.pumpAndSettle();

    expect(settings.onboardingComplete, isTrue);
    expect(settings.mode, AppMode.live);
    expect(find.text('Welcome back'), findsOneWidget);
  });

  testWidgets('Look around first enters Demo mode at avatar setup', (
    tester,
  ) async {
    final router = createAppRouter(initialLocation: AppRoutes.onboarding);
    addTearDown(router.dispose);

    await tester.pumpWidget(
      _wrap(_app(router), settings),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Skip'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Look around first'));
    await tester.pumpAndSettle();

    expect(settings.onboardingComplete, isTrue);
    expect(settings.mode, AppMode.demo);
    expect(find.text('Choose your avatar'), findsOneWidget);
  });

  testWidgets('Look around first seeds the judge-demo story exactly once', (
    tester,
  ) async {
    final preferences = MemoryAppPreferences();
    final repositories = RepositoryBundle.demo(preferences: preferences);

    // Deliberately left at the default (no avatar chosen yet), same as
    // "Look around first enters Demo mode at avatar setup" above, so this
    // lands on the avatar screen rather than Home -- avoiding the real
    // native MapLibre view that screen would otherwise stand up in a
    // widget test (see AGENTS.md). Seeding happens before that hand-off
    // either way.
    final router = createAppRouter(initialLocation: AppRoutes.onboarding);
    addTearDown(router.dispose);

    await tester.pumpWidget(
      _wrapWithRepositories(_app(router), settings, repositories),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Skip'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Look around first'));
    await tester.pumpAndSettle();

    final history = await repositories.assessments.history();
    expect(history, isNotEmpty);
    expect(history.map((record) => record.siteCode).toSet(), <String>{
      'DEMO-RIVER-01',
      'DEMO-BROOK-02',
      'DEMO-CREEK-03',
    });
    expect(await repositories.assessments.drafts(), hasLength(1));
  });

  testWidgets('replaying onboarding never reseeds the demo story', (
    tester,
  ) async {
    final preferences = MemoryAppPreferences();
    final repositories = RepositoryBundle.demo(preferences: preferences);

    final router = GoRouter(
      initialLocation: '/settings-stub',
      routes: <RouteBase>[
        GoRoute(
          path: '/settings-stub',
          builder: (context, state) =>
              const Scaffold(body: Center(child: Text('Settings stub'))),
        ),
        GoRoute(
          path: AppRoutes.onboarding,
          builder: (context, state) => const OnboardingScreen(isReplay: true),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      _wrapWithRepositories(_app(router), settings, repositories),
    );
    await tester.pumpAndSettle();

    router.push(AppRoutes.onboarding);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Skip'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Look around first'));
    await tester.pumpAndSettle();

    expect(await repositories.assessments.history(), isEmpty);
  });

  testWidgets('replay mode returns to the previous screen instead of hand-off', (
    tester,
  ) async {
    final router = GoRouter(
      initialLocation: '/settings-stub',
      routes: <RouteBase>[
        GoRoute(
          path: '/settings-stub',
          builder: (context, state) =>
              const Scaffold(body: Center(child: Text('Settings stub'))),
        ),
        GoRoute(
          path: AppRoutes.onboarding,
          builder: (context, state) => const OnboardingScreen(isReplay: true),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(_wrap(_app(router), settings));
    await tester.pumpAndSettle();

    router.push(AppRoutes.onboarding);
    await tester.pumpAndSettle();
    expect(find.text('Your stream is part of city health'), findsOneWidget);

    await tester.tap(find.text('Skip'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Get started'));
    await tester.pumpAndSettle();

    expect(find.text('Settings stub'), findsOneWidget);
    // Replaying a completed onboarding must not re-run first-run hand-off.
    expect(settings.onboardingComplete, isFalse);
  });
}
