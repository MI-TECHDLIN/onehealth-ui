import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onehealth_ui/core/mascot/ripple_controller.dart';
import 'package:onehealth_ui/data/assessment/assessment_protocol.dart';
import 'package:onehealth_ui/data/repositories/repository_models.dart';
import 'package:onehealth_ui/features/check/pages/feelings_page.dart';
import 'package:onehealth_ui/features/check/pages/riparian_pages.dart';
import 'package:onehealth_ui/l10n/generated/app_localizations.dart';

final _leftCover = AssessmentQuestion(
  id: 'isVegetationCoveredLeft',
  payloadField: 'isVegetationCoveredLeft',
  step: 6,
  type: AssessmentFieldType.yesNoNotSure,
  variant: 'left',
  title: 'Vegetation (Left)',
  prompt: 'Is the left margin covered by vegetation?',
  options: const <AssessmentOption>[
    AssessmentOption(code: 'true', label: 'Yes'),
    AssessmentOption(code: 'false', label: 'No'),
    AssessmentOption(code: null, label: "I'm not sure"),
  ],
);
final _rightCover = AssessmentQuestion(
  id: 'isVegetationCoveredRight',
  payloadField: 'isVegetationCoveredRight',
  step: 6,
  type: AssessmentFieldType.yesNoNotSure,
  variant: 'right',
  title: 'Vegetation (Right)',
  prompt: 'Is the right margin covered by vegetation?',
  options: _leftCover.options,
);
final _leftType = AssessmentQuestion(
  id: 'vegetationTypeLeft',
  payloadField: 'vegetationTypeLeft',
  step: 6,
  type: AssessmentFieldType.singleChoice,
  variant: 'left',
  title: 'Vegetation Type (Left)',
  prompt: 'Which vegetation is dominant on the left margin?',
  options: const <AssessmentOption>[
    AssessmentOption(code: 'H', label: 'Herbs (A)'),
    AssessmentOption(code: 'B', label: 'Shrubs (B)'),
    AssessmentOption(code: 'T', label: 'Trees (C)'),
    AssessmentOption(code: null, label: "I'm not sure"),
  ],
  visibleWhen: (draft) => draft.isVegetationCoveredLeft == true,
);
final _rightType = AssessmentQuestion(
  id: 'vegetationTypeRight',
  payloadField: 'vegetationTypeRight',
  step: 6,
  type: AssessmentFieldType.singleChoice,
  variant: 'right',
  title: 'Vegetation Type (Right)',
  prompt: 'Which vegetation is dominant on the right margin?',
  options: _leftType.options,
  visibleWhen: (draft) => draft.isVegetationCoveredRight == true,
);

Widget _wrap(Widget child) => MaterialApp(
  locale: const Locale('en'),
  localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
    AppLocalizations.delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ],
  supportedLocales: AppLocalizations.supportedLocales,
  home: Scaffold(body: child),
);

void main() {
  testWidgets(
    'vegetation type stays hidden until that margin is marked covered',
    (tester) async {
      var draft = const AssessmentDraft(id: 'd1', siteCode: 'SITE-1');
      final rippleController = RippleController();
      addTearDown(rippleController.dispose);

      await tester.pumpWidget(
        _wrap(
          StatefulBuilder(
            builder: (context, setState) => VegetationCoveragePage(
              leftCoverQuestion: _leftCover,
              rightCoverQuestion: _rightCover,
              leftTypeQuestion: _leftType,
              rightTypeQuestion: _rightType,
              draft: draft,
              onCoverChanged: (question, value, notSure) {
                setState(() {
                  draft = draft.withYesNo(question, value: value, notSure: notSure);
                });
              },
              onTypeChanged: (question, option) {
                setState(() => draft = draft.withChoice(question, option));
              },
              rippleController: rippleController,
              readAloudEnabled: false,
            ),
          ),
        ),
      );

      expect(find.text('Herbs (A)'), findsNothing);

      await tester.tap(find.text('Yes').first);
      await tester.pumpAndSettle();

      expect(find.text('Herbs (A)'), findsOneWidget);

      await tester.tap(find.text('Herbs (A)'));
      await tester.pumpAndSettle();
      expect(draft.vegetationTypeLeft, 'H');

      await tester.tap(find.text('No').first);
      await tester.pumpAndSettle();

      expect(find.text('Herbs (A)'), findsNothing);
      expect(draft.vegetationTypeLeft, isNull);
    },
  );

  testWidgets('feelings: marking Not applicable zeroes the value, picking a level clears it', (
    tester,
  ) async {
    final joy = AssessmentQuestion(
      id: 'joy',
      payloadField: 'joy',
      step: 8,
      type: AssessmentFieldType.slider,
      title: 'Joy',
      prompt: 'Which feeling(s) best describe your experience?',
      min: 0,
      max: 5,
      defaultValue: 3,
      notApplicableValue: 0,
      notApplicableLabel: 'Not Applicable',
    );
    var draft = const AssessmentDraft(id: 'd1', siteCode: 'SITE-1', joy: 3);
    final rippleController = RippleController();
    addTearDown(rippleController.dispose);

    await tester.pumpWidget(
      _wrap(
        StatefulBuilder(
          builder: (context, setState) => FeelingsPage(
            questions: <AssessmentQuestion>[joy],
            draft: draft,
            onChanged: (question, value) {
              setState(() => draft = draft.withFeeling(question, value));
            },
            rippleController: rippleController,
            readAloudEnabled: false,
          ),
        ),
      ),
    );

    await tester.tap(find.byKey(const Key('feelingNotApplicable_joy')));
    await tester.pumpAndSettle();
    expect(draft.joy, 0);

    await tester.tap(find.text('4'));
    await tester.pumpAndSettle();
    expect(draft.joy, 4);
  });
}
