import 'package:flutter_test/flutter_test.dart';
import 'package:onehealth_ui/data/assessment/assessment_protocol.dart';
import 'package:onehealth_ui/data/repositories/assessment_content_source.dart';
import 'package:onehealth_ui/data/repositories/repository_models.dart';

Future<AssessmentProtocol> _loadProtocol([String languageCode = 'en']) async {
  final content = await AssessmentContentSource().localized(languageCode);
  return AssessmentProtocol.fromContent(content);
}

void main() {
  group('AssessmentProtocol.fromContent', () {
    test('groups every field into its protocol step', () async {
      final protocol = await _loadProtocol();

      expect(protocol.steps.map((step) => step.step), <int>[4, 5, 6, 7, 8]);
      expect(
        protocol.steps.firstWhere((step) => step.step == 4).questions.length,
        6,
      );
      expect(
        protocol.steps.firstWhere((step) => step.step == 8).questions.length,
        4,
      );
      expect(protocol.allQuestions.length, 6 + 7 + 9 + 1 + 4);
    });

    test('picture-choice channel form parses options with a not-sure sentinel', () async {
      final protocol = await _loadProtocol();
      final channelForm = protocol.questionById('channelForm')!;

      expect(channelForm.picture, isTrue);
      expect(channelForm.type, AssessmentFieldType.singleChoice);
      expect(
        channelForm.options.map((option) => option.code),
        <String?>['FLAT', 'U', 'V', null],
      );
      expect(channelForm.options.last.isNotSure, isTrue);
      expect(channelForm.options.first.label, 'Flat (A)');
    });

    test('localized content retains root reference option data', () async {
      final content = await AssessmentContentSource().localized('en');
      final referenceData = content['referenceData'] as Map<String, dynamic>;

      expect(referenceData['channelForms'], isNotEmpty);
      expect(referenceData['waterFlows'], isNotEmpty);
    });

    test('yes/no questions carry Yes/No/not-sure sentinel codes', () async {
      final protocol = await _loadProtocol();
      final hasDams = protocol.questionById('hasDams')!;

      expect(hasDams.type, AssessmentFieldType.yesNoNotSure);
      expect(
        hasDams.options.map((option) => option.asYesNoValue),
        <bool?>[true, false, null],
      );
    });

    test('overall assessment is required with GOOD/MODERATE/POOR options', () async {
      final protocol = await _loadProtocol();
      final overall = protocol.questionById('overallAssessment')!;

      expect(overall.required, isTrue);
      expect(
        overall.options.map((option) => option.code),
        <String?>['GOOD', 'MODERATE', 'POOR'],
      );
      expect(overall.options.first.description, isNotNull);
    });

    test('feelings parse as four independent 0-5 sliders', () async {
      final protocol = await _loadProtocol();
      final feelingsStep = protocol.steps.firstWhere((step) => step.step == 8);

      expect(
        feelingsStep.questions.map((question) => question.id),
        <String>['joy', 'serenity', 'anger', 'fear'],
      );
      for (final question in feelingsStep.questions) {
        expect(question.type, AssessmentFieldType.slider);
        expect(question.min, 0);
        expect(question.max, 5);
        expect(question.notApplicableValue, 0);
      }
    });

    test('falls back to English when a locale lacks assessment translations', () async {
      // Greek's shipped bundle has no assessment questions (see
      // assessment-content.json's localeStatus note), so the merged content
      // -- and therefore the parsed protocol -- must read identically to
      // English rather than coming back empty.
      final english = await _loadProtocol('en');
      final greek = await _loadProtocol('el');

      expect(
        greek.questionById('channelForm')!.prompt,
        english.questionById('channelForm')!.prompt,
      );
    });

    test(
      'loads complete translated questions for every added protocol locale',
      () async {
        final english = await _loadProtocol('en');
        final englishPrompt = english.questionById('channelForm')!.prompt;
        const addedLocales = <String>[
          'es',
          'de',
          'pl',
          'ro',
          'bg',
          'tr',
          'uk',
          'ar',
          'fi',
          'sv',
          'hr',
        ];

        for (final locale in addedLocales) {
          final protocol = await _loadProtocol(locale);
          expect(protocol.allQuestions.length, english.allQuestions.length);
          expect(
            protocol.questionById('channelForm')!.prompt,
            isNot(englishPrompt),
            reason: '$locale should use its translated assessment content',
          );
        }
      },
    );
  });

  group('conditional visibility', () {
    test('vegetation type only becomes visible once its margin is covered', () async {
      final protocol = await _loadProtocol();
      final vegetationTypeLeft = protocol.questionById('vegetationTypeLeft')!;
      const base = AssessmentDraft(id: 'draft-1', siteCode: 'SITE-1');

      expect(vegetationTypeLeft.isVisible(base), isFalse);
      expect(
        vegetationTypeLeft.isVisible(
          base.copyWith(isVegetationCoveredLeft: true),
        ),
        isTrue,
      );
      expect(
        vegetationTypeLeft.isVisible(
          base.copyWith(isVegetationCoveredLeft: false),
        ),
        isFalse,
      );
    });

    test('invasive species free text only appears once the gate is yes', () async {
      final protocol = await _loadProtocol();
      final invasiveText = protocol.questionById('invasivePlantSpecies')!;
      const base = AssessmentDraft(id: 'draft-1', siteCode: 'SITE-1');

      expect(invasiveText.isVisible(base), isFalse);
      expect(
        invasiveText.isVisible(
          base.copyWith(hasInvasivePlantSpecies: true),
        ),
        isTrue,
      );
    });
  });

  group('AssessmentDraftAnswers contract mapping', () {
    test('choosing "I\'m not sure" omits the field from the submission payload', () async {
      final protocol = await _loadProtocol();
      final channelForm = protocol.questionById('channelForm')!;
      const base = AssessmentDraft(id: 'draft-1', siteCode: 'SITE-1');

      final answered = base.withChoice(channelForm, channelForm.options.first);
      expect(answered.toSubmissionJson()['channelForm'], 'FLAT');
      expect(answered.isNotSure('channelForm'), isFalse);

      final notSure = answered.withChoice(
        channelForm,
        channelForm.options.last,
      );
      expect(notSure.toSubmissionJson().containsKey('channelForm'), isFalse);
      expect(notSure.isNotSure('channelForm'), isTrue);
      expect(notSure.selectedOption(channelForm)?.isNotSure, isTrue);
    });

    test('yes/no answers map to booleans, and not-sure maps to omission', () async {
      final protocol = await _loadProtocol();
      final hasDams = protocol.questionById('hasDams')!;
      const base = AssessmentDraft(id: 'draft-1', siteCode: 'SITE-1');

      final yes = base.withYesNo(hasDams, value: true);
      expect(yes.toSubmissionJson()['hasDams'], true);

      final notSure = yes.withYesNo(hasDams, notSure: true);
      expect(notSure.toSubmissionJson().containsKey('hasDams'), isFalse);
      expect(notSure.yesNoAnswer(hasDams), isNull);
    });

    test('turning a margin\'s vegetation cover off clears its vegetation type', () async {
      final protocol = await _loadProtocol();
      final isVegetationCoveredLeft = protocol.questionById(
        'isVegetationCoveredLeft',
      )!;
      final vegetationTypeLeft = protocol.questionById('vegetationTypeLeft')!;
      const base = AssessmentDraft(id: 'draft-1', siteCode: 'SITE-1');

      final covered = base.withYesNo(isVegetationCoveredLeft, value: true);
      final typed = covered.withChoice(
        vegetationTypeLeft,
        vegetationTypeLeft.options.first,
      );
      expect(typed.vegetationTypeLeft, isNotNull);

      final uncovered = typed.withYesNo(isVegetationCoveredLeft, value: false);
      expect(uncovered.vegetationTypeLeft, isNull);
      expect(uncovered.toSubmissionJson().containsKey('vegetationTypeLeft'), isFalse);
    });

    test('multi-choice answers write the full code list', () async {
      final protocol = await _loadProtocol();
      final habitats = protocol.questionById('habitats')!;
      const base = AssessmentDraft(id: 'draft-1', siteCode: 'SITE-1');

      final answered = base.withMultiChoice(habitats, <String>['SB', 'AV']);
      expect(answered.toSubmissionJson()['habitats'], <String>['SB', 'AV']);
    });

    test('feeling answers are independent 0-5 integers', () async {
      final protocol = await _loadProtocol();
      final joy = protocol.questionById('joy')!;
      const base = AssessmentDraft(id: 'draft-1', siteCode: 'SITE-1');

      final answered = base.withFeeling(joy, 5);
      expect(answered.toSubmissionJson()['joy'], 5);
      expect(answered.feelingAnswer(joy), 5);
      expect(answered.serenity, base.serenity);
    });

    test('required gating only blocks on overall assessment', () async {
      final protocol = await _loadProtocol();
      final overall = protocol.questionById('overallAssessment')!;
      final channelForm = protocol.questionById('channelForm')!;
      const base = AssessmentDraft(id: 'draft-1', siteCode: 'SITE-1');

      expect(channelForm.required, isFalse);
      expect(base.satisfiesRequired(channelForm), isTrue);
      expect(base.satisfiesRequired(overall), isFalse);
      expect(
        base
            .withChoice(overall, overall.options.first)
            .satisfiesRequired(overall),
        isTrue,
      );
    });
  });
}
