import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:onehealth_ui/core/mode/app_mode.dart';
import 'package:onehealth_ui/core/widgets/aqua_components.dart';
import 'package:onehealth_ui/data/repositories/repository_bundle.dart';
import 'package:onehealth_ui/data/repositories/repository_models.dart';
import 'package:onehealth_ui/data/repositories/repository_scope.dart';
import 'package:onehealth_ui/features/check/assessment_review_screen.dart';
import 'package:onehealth_ui/l10n/generated/app_localizations.dart';

Future<void> _pumpReview(
  WidgetTester tester,
  AssessmentDraft draft,
) async {
  final router = GoRouter(
    initialLocation: '/review',
    routes: <RouteBase>[
      GoRoute(
        path: '/review',
        builder: (context, state) => AssessmentReviewScreen(draft: draft),
      ),
      GoRoute(
        path: '/home',
        builder: (context, state) => const Scaffold(body: Text('home')),
      ),
      GoRoute(
        path: '/check/photos',
        builder: (context, state) => const Scaffold(body: Text('photos')),
      ),
      GoRoute(
        path: '/check/assess',
        builder: (context, state) => const Scaffold(body: Text('assess')),
      ),
      GoRoute(
        path: '/check/celebration',
        builder: (context, state) => const Scaffold(body: Text('celebration')),
      ),
    ],
  );
  addTearDown(router.dispose);
  await tester.pumpWidget(
    RepositoryScope(
      mode: AppMode.demo,
      repositories: RepositoryBundle.demo(),
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

void main() {
  testWidgets('submit stays gated until the required health answer exists', (
    tester,
  ) async {
    await _pumpReview(
      tester,
      const AssessmentDraft(id: 'draft-1', siteCode: 'SITE-1'),
    );

    final button = tester.widget<AquaButton>(
      find.byKey(const Key('assessmentSubmitButton')),
    );
    expect(button.onPressed, isNull);
    expect(
      find.text('Choose an overall stream-health assessment before submitting.'),
      findsOneWidget,
    );
  });

  testWidgets('submit is enabled after the required health answer', (
    tester,
  ) async {
    await _pumpReview(
      tester,
      const AssessmentDraft(
        id: 'draft-1',
        siteCode: 'SITE-1',
        overallAssessment: 'GOOD',
        answeredQuestionIds: <String>{'overallAssessment'},
      ),
    );

    final button = tester.widget<AquaButton>(
      find.byKey(const Key('assessmentSubmitButton')),
    );
    expect(button.onPressed, isNotNull);
  });
}
