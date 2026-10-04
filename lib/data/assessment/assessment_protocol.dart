import '../repositories/repository_models.dart';

/// How one [AssessmentQuestion] expects an answer to be captured and mapped
/// onto [AssessmentDraft]'s submission-contract fields.
enum AssessmentFieldType {
  /// One option from [AssessmentQuestion.options], written as its `code`.
  /// When [AssessmentQuestion.picture] is true this renders as a grid of
  /// `PictureChoiceCard`s rather than chips.
  singleChoice,

  /// Any number of options from [AssessmentQuestion.options], written as a
  /// `List<String>` of codes.
  multiChoice,

  /// Yes / No / "I'm not sure", written as `bool?` (not sure and unanswered
  /// both map to `null`, matching the API contract's omission rule).
  yesNoNotSure,

  /// Free-form text, written as a `String?`.
  freeText,

  /// A guided numeric estimate (metres), written as a `String?` to match the
  /// wire contract, which never enforces a numeric type server-side.
  numericText,

  /// A 0-5 intensity rating with a "Not applicable" escape hatch, written as
  /// an `int`.
  slider,

  /// The three-way Good / Moderate / Poor stream health choice. Always
  /// required, never offers "I'm not sure".
  overallChoice,
}

/// One answerable value inside a [AssessmentFieldType.singleChoice],
/// [AssessmentFieldType.multiChoice] or [AssessmentFieldType.overallChoice]
/// question.
class AssessmentOption {
  const AssessmentOption({required this.code, required this.label, this.description});

  /// The wire code (e.g. `'FLAT'`, `'GOOD'`), or `null` for the synthetic
  /// "I'm not sure" option, which always maps to omitting the field.
  final String? code;
  final String label;
  final String? description;

  bool get isNotSure => code == null;
}

/// One question in the protocol, normalized from `assessment-content.json`'s
/// `fields`/`referenceData`/`contentByLocale` tables (see
/// `AssessmentProtocol.fromContent`).
class AssessmentQuestion {
  const AssessmentQuestion({
    required this.id,
    required this.payloadField,
    required this.step,
    required this.type,
    required this.title,
    required this.prompt,
    this.revealPrompt,
    this.info,
    this.options = const <AssessmentOption>[],
    this.required = false,
    this.picture = false,
    this.variant,
    this.visibleWhen,
    this.placeholder,
    this.min = 0,
    this.max = 5,
    this.defaultValue = 3,
    this.notApplicableValue = 0,
    this.notApplicableLabel,
    this.glossaryTermIds = const <String>[],
  });

  /// Stable id matching the draft's payload field name (e.g.
  /// `'channelForm'`), except for the two UI-only two-stage multi-choice
  /// gates, which still use their payload field id for simplicity.
  final String id;
  final String payloadField;
  final int step;
  final AssessmentFieldType type;

  /// Short label used in progress/review contexts (`fields[].question`).
  final String title;

  /// The full prompt sentence shown on the question screen
  /// (`fields[].questiontext`).
  final String prompt;

  /// The two-stage disclosure gate question shown before a multi-choice
  /// list is revealed (only set for habitats/natural debris).
  final String? revealPrompt;

  /// Optional coaching/help copy shown under the prompt.
  final String? info;
  final List<AssessmentOption> options;
  final bool required;

  /// True for the channel/bottom/bank questions, which render illustrated
  /// picture-choice cards instead of chips.
  final bool picture;

  /// `'left'` or `'right'` for the paired riparian-margin questions.
  final String? variant;

  /// Gate for conditional questions (vegetation type, invasive species
  /// free text). Evaluated against the current draft.
  final bool Function(AssessmentDraft draft)? visibleWhen;

  /// Placeholder copy for [AssessmentFieldType.freeText]/
  /// [AssessmentFieldType.numericText] inputs.
  final String? placeholder;

  final int min;
  final int max;
  final int defaultValue;
  final int notApplicableValue;

  /// "Not Applicable" in the current locale, straight from
  /// `feelings.NotApplicable` -- only set for [AssessmentFieldType.slider]
  /// questions.
  final String? notApplicableLabel;

  /// Glossary term ids (see `lib/core/glossary/glossary_terms.dart`) that
  /// appear underlined inside [prompt] and should be tap-to-explain.
  final List<String> glossaryTermIds;

  bool isVisible(AssessmentDraft draft) => visibleWhen?.call(draft) ?? true;

  bool get allowsNotSure =>
      type == AssessmentFieldType.yesNoNotSure ||
      (type == AssessmentFieldType.singleChoice &&
          options.any((option) => option.isNotSure));
}

/// One step of the nine-step protocol (`workflow[]`), grouping the
/// questions whose `fields[].step` matches.
class AssessmentStepDefinition {
  const AssessmentStepDefinition({
    required this.step,
    required this.kind,
    required this.title,
    required this.required,
    required this.questions,
  });

  final int step;
  final String kind;
  final String title;
  final bool required;
  final List<AssessmentQuestion> questions;
}

/// The fully parsed, typed assessment protocol for one locale, built from
/// the raw JSON `AssessmentRepository.contentForLocale` returns.
///
/// Locale fallback to English is already handled upstream by
/// `AssessmentContentSource.localized`, which deep-merges the requested
/// locale over the English template -- this parser only ever sees content
/// that has an English value for every key, even when a locale's own
/// translation is partial or absent (see `localeStatus` in
/// `assessment-content.json`, e.g. Greek's assessment questions).
class AssessmentProtocol {
  const AssessmentProtocol({required this.steps});

  final List<AssessmentStepDefinition> steps;

  List<AssessmentQuestion> get allQuestions =>
      steps.expand((step) => step.questions).toList(growable: false);

  AssessmentQuestion? questionById(String id) {
    for (final question in allQuestions) {
      if (question.id == id) return question;
    }
    return null;
  }

  factory AssessmentProtocol.fromContent(Map<String, dynamic> content) {
    final referenceData = _asMap(content['referenceData']);
    final questions1To3 = _asMap(content['questions_1_3']);
    final questions2To3 = _asMap(content['questions_2_3']);
    final questions3To3 = _asMap(content['questions_3_3']);
    final streamHealth = _asMap(content['stream_health']);
    final feelings = _asMap(content['feelings']);

    List<AssessmentOption> options(
      String referenceKey,
      Map<String, dynamic> block, {
      bool notSure = true,
    }) {
      final reference = _asList(referenceData[referenceKey]);
      final labels = _asMap(block['labels']).isNotEmpty
          ? _asMap(block['labels'])
          : _asMap(block['options']);
      final resolved = <AssessmentOption>[
        for (final entry in reference)
          AssessmentOption(
            code: (entry['code'] as Object).toString(),
            label:
                (labels[entry['name']] as String?) ??
                (entry['name'] as Object).toString(),
          ),
      ];
      if (notSure) {
        resolved.add(
          AssessmentOption(
            code: null,
            label: (labels['I am not sure'] as String?) ?? "I'm not sure",
          ),
        );
      }
      return resolved;
    }

    List<AssessmentOption> yesNoNotSure(Map<String, dynamic> block) {
      final labels = _asMap(block['labels']);
      return <AssessmentOption>[
        AssessmentOption(code: 'true', label: (labels['Yes'] as String?) ?? 'Yes'),
        AssessmentOption(code: 'false', label: (labels['No'] as String?) ?? 'No'),
        AssessmentOption(
          code: null,
          label: (labels['I am not sure'] as String?) ?? "I'm not sure",
        ),
      ];
    }

    String title(Map<String, dynamic> block, [String fallback = '']) =>
        (block['question'] as String?) ?? fallback;
    String prompt(Map<String, dynamic> block, [String fallback = '']) =>
        (block['questiontext'] as String?) ?? fallback;

    final channelForm = AssessmentQuestion(
      id: 'channelForm',
      payloadField: 'channelForm',
      step: 4,
      type: AssessmentFieldType.singleChoice,
      picture: true,
      title: title(questions1To3['channel_form'] ?? const {}),
      prompt: prompt(questions1To3['channel_form'] ?? const {}),
      options: options('channelForms', questions1To3['channel_form'] ?? const {}),
      glossaryTermIds: const <String>['channel'],
    );
    final bottomChannelType = AssessmentQuestion(
      id: 'bottomChannelType',
      payloadField: 'bottomChannelType',
      step: 4,
      type: AssessmentFieldType.singleChoice,
      picture: true,
      title: title(questions1To3['bottom_type'] ?? const {}),
      prompt: prompt(questions1To3['bottom_type'] ?? const {}),
      options: options('channelTypes', questions1To3['bottom_type'] ?? const {}),
      glossaryTermIds: const <String>['substrate'],
    );
    final banksChannelType = AssessmentQuestion(
      id: 'banksChannelType',
      payloadField: 'banksChannelType',
      step: 4,
      type: AssessmentFieldType.singleChoice,
      picture: true,
      title: title(questions1To3['bank_type'] ?? const {}),
      prompt: prompt(questions1To3['bank_type'] ?? const {}),
      options: options('bankTypes', questions1To3['bank_type'] ?? const {}),
      glossaryTermIds: const <String>['bank'],
    );
    final habitats = AssessmentQuestion(
      id: 'habitats',
      payloadField: 'habitats',
      step: 4,
      type: AssessmentFieldType.multiChoice,
      title: title(questions1To3['habitats'] ?? const {}),
      prompt: prompt(questions1To3['habitats'] ?? const {}),
      revealPrompt: questions1To3['habitats']?['questiontextshow'] as String?,
      info: questions1To3['habitats']?['info'] as String?,
      options: options(
        'habitats',
        questions1To3['habitats'] ?? const {},
        notSure: false,
      ),
    );
    final fallenBiomassTypes = AssessmentQuestion(
      id: 'fallenBiomassTypes',
      payloadField: 'fallenBiomassTypes',
      step: 4,
      type: AssessmentFieldType.multiChoice,
      title: title(questions1To3['natural_debris'] ?? const {}),
      prompt: prompt(questions1To3['natural_debris'] ?? const {}),
      revealPrompt: questions1To3['natural_debris']?['questiontextshow'] as String?,
      info: questions1To3['natural_debris']?['info'] as String?,
      options: options(
        'fallenBiomass',
        questions1To3['natural_debris'] ?? const {},
        notSure: false,
      ),
    );
    final waterFlow = AssessmentQuestion(
      id: 'waterFlow',
      payloadField: 'waterFlow',
      step: 4,
      type: AssessmentFieldType.singleChoice,
      title: title(questions1To3['water_flow'] ?? const {}),
      prompt: prompt(questions1To3['water_flow'] ?? const {}),
      options: options('waterFlows', questions1To3['water_flow'] ?? const {}),
    );

    final waterColor = AssessmentQuestion(
      id: 'waterColor',
      payloadField: 'waterColor',
      step: 5,
      type: AssessmentFieldType.singleChoice,
      title: title(questions2To3['water_aspect_labels'] ?? const {}),
      prompt: prompt(questions2To3['water_aspect_labels'] ?? const {}),
      options: options(
        'waterColors',
        questions2To3['water_aspect_labels'] ?? const {},
      ),
    );
    AssessmentQuestion yesNo(
      String id,
      String translationKey, {
      List<String> glossaryTermIds = const <String>[],
    }) {
      final block = questions2To3[translationKey] ?? const {};
      return AssessmentQuestion(
        id: id,
        payloadField: id,
        step: 5,
        type: AssessmentFieldType.yesNoNotSure,
        title: title(block),
        prompt: prompt(block),
        options: yesNoNotSure(block),
        glossaryTermIds: glossaryTermIds,
      );
    }
    final waterAbstraction = yesNo('waterAbstraction', 'water_withdrawal');
    final hasDams = yesNo('hasDams', 'barriers');
    final pipes = yesNo('pipes', 'draining_pipes');
    final waterDischarge = yesNo('waterDischarge', 'sewage_discharge');
    final construction = yesNo('construction', 'construction');
    final waterHeight = AssessmentQuestion(
      id: 'waterHeight',
      payloadField: 'waterHeight',
      step: 5,
      type: AssessmentFieldType.numericText,
      title: title(questions2To3['water_height'] ?? const {}),
      prompt: prompt(questions2To3['water_height'] ?? const {}),
      placeholder: questions2To3['water_height']?['placeholder'] as String?,
      info: questions2To3['water_height']?['info'] as String?,
    );

    AssessmentQuestion riparianYesNo(
      String id,
      String translationKey,
      String variant,
    ) {
      final block = questions3To3[translationKey] ?? const {};
      return AssessmentQuestion(
        id: id,
        payloadField: id,
        step: 6,
        type: AssessmentFieldType.yesNoNotSure,
        variant: variant,
        title: title(block),
        prompt: prompt(block),
        options: yesNoNotSure(block),
        glossaryTermIds: const <String>['riparianZone'],
      );
    }
    final imperviousAreasLeft = riparianYesNo(
      'imperviousAreasLeft',
      'impervious_left',
      'left',
    );
    final imperviousAreasRight = riparianYesNo(
      'imperviousAreasRight',
      'impervious_right',
      'right',
    );
    final isVegetationCoveredLeft = riparianYesNo(
      'isVegetationCoveredLeft',
      'vegetation_left',
      'left',
    );
    final isVegetationCoveredRight = riparianYesNo(
      'isVegetationCoveredRight',
      'vegetation_right',
      'right',
    );
    final vegetationTypeLeft = AssessmentQuestion(
      id: 'vegetationTypeLeft',
      payloadField: 'vegetationTypeLeft',
      step: 6,
      type: AssessmentFieldType.singleChoice,
      variant: 'left',
      title: title(questions3To3['vegetation_type_left'] ?? const {}),
      prompt: prompt(questions3To3['vegetation_type_left'] ?? const {}),
      info: questions3To3['vegetation_type_left']?['info'] as String?,
      options: options(
        'vegetationTypes',
        questions3To3['vegetation_type_left'] ?? const {},
      ),
      visibleWhen: (draft) => draft.isVegetationCoveredLeft == true,
    );
    final vegetationTypeRight = AssessmentQuestion(
      id: 'vegetationTypeRight',
      payloadField: 'vegetationTypeRight',
      step: 6,
      type: AssessmentFieldType.singleChoice,
      variant: 'right',
      title: title(questions3To3['vegetation_type_right'] ?? const {}),
      prompt: prompt(questions3To3['vegetation_type_right'] ?? const {}),
      info: questions3To3['vegetation_type_right']?['info'] as String?,
      options: options(
        'vegetationTypes',
        questions3To3['vegetation_type_right'] ?? const {},
      ),
      visibleWhen: (draft) => draft.isVegetationCoveredRight == true,
    );
    final hasInvasivePlantSpecies = AssessmentQuestion(
      id: 'hasInvasivePlantSpecies',
      payloadField: 'hasInvasivePlantSpecies',
      step: 6,
      type: AssessmentFieldType.yesNoNotSure,
      title: title(questions3To3['invasive_species'] ?? const {}),
      prompt: prompt(questions3To3['invasive_species'] ?? const {}),
      options: yesNoNotSure(questions3To3['invasive_species'] ?? const {}),
      glossaryTermIds: const <String>['invasiveSpecies'],
    );
    final invasivePlantSpecies = AssessmentQuestion(
      id: 'invasivePlantSpecies',
      payloadField: 'invasivePlantSpecies',
      step: 6,
      type: AssessmentFieldType.freeText,
      title: title(questions3To3['invasive_species'] ?? const {}),
      prompt: (questions3To3['invasive_species']?['placeholder'] as String?) ??
          'Which ones?',
      placeholder:
          (questions3To3['invasive_species']?['placeholder'] as String?) ??
          'Which ones?',
      visibleWhen: (draft) => draft.hasInvasivePlantSpecies == true,
    );
    final recentVegetationCuts = AssessmentQuestion(
      id: 'recentVegetationCuts',
      payloadField: 'recentVegetationCuts',
      step: 6,
      type: AssessmentFieldType.yesNoNotSure,
      title: title(questions3To3['vegetation_cut'] ?? const {}),
      prompt: prompt(questions3To3['vegetation_cut'] ?? const {}),
      options: yesNoNotSure(questions3To3['vegetation_cut'] ?? const {}),
    );

    final overallAssessment = AssessmentQuestion(
      id: 'overallAssessment',
      payloadField: 'overallAssessment',
      step: 7,
      type: AssessmentFieldType.overallChoice,
      required: true,
      title: title(streamHealth, 'Overall assessment'),
      prompt: prompt(streamHealth, title(streamHealth, 'Overall assessment')),
      options: <AssessmentOption>[
        AssessmentOption(
          code: 'GOOD',
          label: (streamHealth['good_quality'] as String?) ?? 'Good quality',
          description: streamHealth['good_quality_description'] as String?,
        ),
        AssessmentOption(
          code: 'MODERATE',
          label:
              (streamHealth['moderate_quality'] as String?) ??
              'Moderate quality',
          description: streamHealth['moderate_quality_description'] as String?,
        ),
        AssessmentOption(
          code: 'POOR',
          label: (streamHealth['poor_quality'] as String?) ?? 'Poor quality',
          description: streamHealth['poor_quality_description'] as String?,
        ),
      ],
    );

    AssessmentQuestion feeling(String id, String feelingKey) {
      return AssessmentQuestion(
        id: id,
        payloadField: id,
        step: 8,
        type: AssessmentFieldType.slider,
        title: (feelings[feelingKey] as String?) ?? feelingKey,
        prompt: (feelings['question'] as String?) ?? '',
        info: feelings['info'] as String?,
        placeholder: feelings['instructions'] as String?,
        min: 0,
        max: 5,
        defaultValue: 3,
        notApplicableValue: 0,
        notApplicableLabel: feelings['NotApplicable'] as String?,
      );
    }
    final joy = feeling('joy', 'Joy');
    final serenity = feeling('serenity', 'Serenity');
    final anger = feeling('anger', 'Anger');
    final fear = feeling('fear', 'Fear');

    return AssessmentProtocol(
      steps: <AssessmentStepDefinition>[
        AssessmentStepDefinition(
          step: 4,
          kind: 'assessment',
          title: (content['questions_1_3_'] as String?) ?? 'Questions (1/3)',
          required: false,
          questions: <AssessmentQuestion>[
            channelForm,
            bottomChannelType,
            banksChannelType,
            habitats,
            fallenBiomassTypes,
            waterFlow,
          ],
        ),
        AssessmentStepDefinition(
          step: 5,
          kind: 'assessment',
          title: (content['questions_2_3_'] as String?) ?? 'Questions (2/3)',
          required: false,
          questions: <AssessmentQuestion>[
            waterColor,
            waterAbstraction,
            hasDams,
            pipes,
            waterDischarge,
            construction,
            waterHeight,
          ],
        ),
        AssessmentStepDefinition(
          step: 6,
          kind: 'assessment',
          title: (content['questions_3_3_'] as String?) ?? 'Questions (3/3)',
          required: false,
          questions: <AssessmentQuestion>[
            imperviousAreasLeft,
            imperviousAreasRight,
            isVegetationCoveredLeft,
            vegetationTypeLeft,
            isVegetationCoveredRight,
            vegetationTypeRight,
            hasInvasivePlantSpecies,
            invasivePlantSpecies,
            recentVegetationCuts,
          ],
        ),
        AssessmentStepDefinition(
          step: 7,
          kind: 'overallAssessment',
          title: (content['feedback_1_2'] as String?) ?? 'Feedback (1/2)',
          required: true,
          questions: <AssessmentQuestion>[overallAssessment],
        ),
        AssessmentStepDefinition(
          step: 8,
          kind: 'feelings',
          title: (content['feedback_2_2'] as String?) ?? 'Feedback (2/2)',
          required: false,
          questions: <AssessmentQuestion>[joy, serenity, anger, fear],
        ),
      ],
    );
  }
}

/// Applies answers from the assessment shell onto an [AssessmentDraft],
/// keeping the draft's typed, submission-contract-shaped fields (see
/// `repository_models.dart`) in sync with the generic [AssessmentQuestion]
/// the UI renders. This is the single place that knows which payload field
/// each question id writes to.
extension AssessmentDraftAnswers on AssessmentDraft {
  bool isNotSure(String questionId) => notSureFieldIds.contains(questionId);

  Set<String> _notSureFlag(String questionId, bool notSure) {
    final updated = Set<String>.of(notSureFieldIds);
    if (notSure) {
      updated.add(questionId);
    } else {
      updated.remove(questionId);
    }
    return updated;
  }

  Set<String> _answered(String questionId) =>
      Set<String>.of(answeredQuestionIds)..add(questionId);

  /// Applies a [AssessmentFieldType.singleChoice]/
  /// [AssessmentFieldType.overallChoice] answer, or clears it when [option]
  /// is `null`.
  AssessmentDraft withChoice(AssessmentQuestion question, AssessmentOption? option) {
    final notSure = option?.isNotSure ?? false;
    final updatedNotSure = _notSureFlag(question.id, notSure);
    final value = notSure ? null : option?.code;
    final updated = switch (question.payloadField) {
      'channelForm' => copyWith(channelForm: value, notSureFieldIds: updatedNotSure),
      'bottomChannelType' => copyWith(
        bottomChannelType: value,
        notSureFieldIds: updatedNotSure,
      ),
      'banksChannelType' => copyWith(
        banksChannelType: value,
        notSureFieldIds: updatedNotSure,
      ),
      'waterFlow' => copyWith(waterFlow: value, notSureFieldIds: updatedNotSure),
      'waterColor' => copyWith(waterColor: value, notSureFieldIds: updatedNotSure),
      'vegetationTypeLeft' => copyWith(
        vegetationTypeLeft: value,
        notSureFieldIds: updatedNotSure,
      ),
      'vegetationTypeRight' => copyWith(
        vegetationTypeRight: value,
        notSureFieldIds: updatedNotSure,
      ),
      'overallAssessment' => copyWith(
        overallAssessment: value ?? overallAssessment,
        notSureFieldIds: updatedNotSure,
      ),
      _ => throw ArgumentError(
        'Unknown single-choice field ${question.payloadField}',
      ),
    };
    return updated.copyWith(answeredQuestionIds: _answered(question.id));
  }

  AssessmentDraft withMultiChoice(AssessmentQuestion question, List<String> codes) {
    final updated = switch (question.payloadField) {
      'habitats' => copyWith(habitats: codes),
      'fallenBiomassTypes' => copyWith(fallenBiomassTypes: codes),
      _ => throw ArgumentError(
        'Unknown multi-choice field ${question.payloadField}',
      ),
    };
    return updated.copyWith(answeredQuestionIds: _answered(question.id));
  }

  /// Applies a yes/no/not-sure answer. [value] is ignored when [notSure] is
  /// true (both map to a `null` payload field, per the API contract).
  /// Clears a now-hidden dependent question's own answer so stale data
  /// never outlives the gate that revealed it (vegetation type when
  /// vegetation coverage flips off, invasive species text when the
  /// yes/no/not-sure gate flips off).
  AssessmentDraft withYesNo(
    AssessmentQuestion question, {
    bool? value,
    bool notSure = false,
  }) {
    final updatedNotSure = _notSureFlag(question.id, notSure);
    final resolved = notSure ? null : value;
    final updated = switch (question.payloadField) {
      'waterAbstraction' => copyWith(
        waterAbstraction: resolved,
        notSureFieldIds: updatedNotSure,
      ),
      'hasDams' => copyWith(hasDams: resolved, notSureFieldIds: updatedNotSure),
      'pipes' => copyWith(pipes: resolved, notSureFieldIds: updatedNotSure),
      'waterDischarge' => copyWith(
        waterDischarge: resolved,
        notSureFieldIds: updatedNotSure,
      ),
      'construction' => copyWith(
        construction: resolved,
        notSureFieldIds: updatedNotSure,
      ),
      'imperviousAreasLeft' => copyWith(
        imperviousAreasLeft: resolved,
        notSureFieldIds: updatedNotSure,
      ),
      'imperviousAreasRight' => copyWith(
        imperviousAreasRight: resolved,
        notSureFieldIds: updatedNotSure,
      ),
      'isVegetationCoveredLeft' => copyWith(
        isVegetationCoveredLeft: resolved,
        vegetationTypeLeft: resolved == true ? vegetationTypeLeft : null,
        notSureFieldIds: resolved == true
            ? updatedNotSure
            : (updatedNotSure..remove('vegetationTypeLeft')),
      ),
      'isVegetationCoveredRight' => copyWith(
        isVegetationCoveredRight: resolved,
        vegetationTypeRight: resolved == true ? vegetationTypeRight : null,
        notSureFieldIds: resolved == true
            ? updatedNotSure
            : (updatedNotSure..remove('vegetationTypeRight')),
      ),
      'hasInvasivePlantSpecies' => copyWith(
        hasInvasivePlantSpecies: resolved,
        invasivePlantSpecies: resolved == true ? invasivePlantSpecies : null,
        notSureFieldIds: updatedNotSure,
      ),
      'recentVegetationCuts' => copyWith(
        recentVegetationCuts: resolved,
        notSureFieldIds: updatedNotSure,
      ),
      _ => throw ArgumentError('Unknown yes/no field ${question.payloadField}'),
    };
    return updated.copyWith(answeredQuestionIds: _answered(question.id));
  }

  AssessmentDraft withText(AssessmentQuestion question, String? text) {
    final updated = switch (question.payloadField) {
      'waterHeight' => copyWith(waterHeight: text),
      'invasivePlantSpecies' => copyWith(invasivePlantSpecies: text),
      _ => throw ArgumentError('Unknown text field ${question.payloadField}'),
    };
    return updated.copyWith(answeredQuestionIds: _answered(question.id));
  }

  AssessmentDraft withFeeling(AssessmentQuestion question, int value) {
    final updated = switch (question.payloadField) {
      'joy' => copyWith(joy: value),
      'serenity' => copyWith(serenity: value),
      'anger' => copyWith(anger: value),
      'fear' => copyWith(fear: value),
      _ => throw ArgumentError('Unknown feeling field ${question.payloadField}'),
    };
    return updated.copyWith(answeredQuestionIds: _answered(question.id));
  }

  /// The current answer for a question, as an option from its own list (for
  /// single/overall choice), or `null` if unanswered/not-sure.
  AssessmentOption? selectedOption(AssessmentQuestion question) {
    if (isNotSure(question.id)) {
      return question.options.firstWhere(
        (option) => option.isNotSure,
        orElse: () => const AssessmentOption(code: null, label: ''),
      );
    }
    final code = switch (question.payloadField) {
      'channelForm' => channelForm,
      'bottomChannelType' => bottomChannelType,
      'banksChannelType' => banksChannelType,
      'waterFlow' => waterFlow,
      'waterColor' => waterColor,
      'vegetationTypeLeft' => vegetationTypeLeft,
      'vegetationTypeRight' => vegetationTypeRight,
      'overallAssessment' => overallAssessment,
      _ => null,
    };
    if (code == null) return null;
    for (final option in question.options) {
      if (option.code == code) return option;
    }
    return null;
  }

  bool? yesNoAnswer(AssessmentQuestion question) {
    if (isNotSure(question.id)) return null;
    return switch (question.payloadField) {
      'waterAbstraction' => waterAbstraction,
      'hasDams' => hasDams,
      'pipes' => pipes,
      'waterDischarge' => waterDischarge,
      'construction' => construction,
      'imperviousAreasLeft' => imperviousAreasLeft,
      'imperviousAreasRight' => imperviousAreasRight,
      'isVegetationCoveredLeft' => isVegetationCoveredLeft,
      'isVegetationCoveredRight' => isVegetationCoveredRight,
      'hasInvasivePlantSpecies' => hasInvasivePlantSpecies,
      'recentVegetationCuts' => recentVegetationCuts,
      _ => null,
    };
  }

  String? textAnswer(AssessmentQuestion question) => switch (question.payloadField) {
    'waterHeight' => waterHeight,
    'invasivePlantSpecies' => invasivePlantSpecies,
    _ => null,
  };

  int feelingAnswer(AssessmentQuestion question) => switch (question.payloadField) {
    'joy' => joy,
    'serenity' => serenity,
    'anger' => anger,
    'fear' => fear,
    _ => 3,
  };

  /// Whether a required question has been answered -- only
  /// [AssessmentQuestion.required] questions (currently just overall
  /// assessment) gate progression.
  bool satisfiesRequired(AssessmentQuestion question) {
    if (!question.required) return true;
    return answeredQuestionIds.contains(question.id);
  }
}

/// [AssessmentFieldType.yesNoNotSure] questions model their two real
/// options as the sentinel codes `'true'`/`'false'` (never written to the
/// wire directly) so they can share [AssessmentOption]/[AssessmentQuestion]
/// with every other question type. Widgets read the actual boolean through
/// this accessor rather than comparing strings.
extension AssessmentYesNoOption on AssessmentOption {
  bool? get asYesNoValue => switch (code) {
    'true' => true,
    'false' => false,
    _ => null,
  };
}

Map<String, dynamic> _asMap(Object? value) =>
    value is Map ? Map<String, dynamic>.from(value) : <String, dynamic>{};

List<Map<String, dynamic>> _asList(Object? value) => value is List
    ? value.whereType<Map>().map(Map<String, dynamic>.from).toList()
    : const <Map<String, dynamic>>[];
