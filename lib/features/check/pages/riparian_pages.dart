import 'package:flutter/material.dart';

import '../../../core/glossary/glossary_term_text.dart';
import '../../../core/icons/water_icons.dart';
import '../../../core/mascot/ripple_controller.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/aqua_components.dart';
import '../../../data/assessment/assessment_protocol.dart';
import '../../../data/repositories/repository_models.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../widgets/narrated_question_frame.dart';
import '../widgets/question_frame.dart';
import '../widgets/yes_no_not_sure_control.dart';

/// The riparian step's downstream orientation primer -- a static context
/// screen (no question) explaining that left/right are defined facing
/// downstream, shown once before the paired margin questions.
class DownstreamPrimerPage extends StatelessWidget {
  const DownstreamPrimerPage({super.key, required this.rippleController});

  final RippleController rippleController;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    return NarratedQuestionFrame(
      narrationId: 'downstreamPrimer',
      fullText: '${strings.assessDownstreamPrimerTitle}. ${strings.assessDownstreamPrimerBody}',
      rippleController: rippleController,
      builder: (context, narration) => QuestionFrame(
        prompt: strings.assessDownstreamPrimerTitle,
        narration: narration,
        readAloudEnabled: true,
        glossaryTermIds: const <String>['riparianZone'],
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Center(
              child: WaterIconWidget(
                WaterIcon.riparianBank,
                size: 96,
                color: AppColors.deepWater,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            GlossaryTermText(
              text: strings.assessDownstreamPrimerBody,
              termIds: const <String>['riparianZone'],
              readAloudEnabled: true,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ],
        ),
      ),
    );
  }
}

/// Impervious areas, paired left/right margins.
class ImperviousAreasPage extends StatelessWidget {
  const ImperviousAreasPage({
    super.key,
    required this.leftQuestion,
    required this.rightQuestion,
    required this.draft,
    required this.onChanged,
    required this.rippleController,
    required this.readAloudEnabled,
  });

  final AssessmentQuestion leftQuestion;
  final AssessmentQuestion rightQuestion;
  final AssessmentDraft draft;
  final void Function(AssessmentQuestion question, bool? value, bool notSure) onChanged;
  final RippleController rippleController;
  final bool readAloudEnabled;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    return NarratedQuestionFrame(
      narrationId: 'imperviousAreas',
      fullText: <String>[
        leftQuestion.prompt,
        ...leftQuestion.options.map((o) => o.label),
        rightQuestion.prompt,
        ...rightQuestion.options.map((o) => o.label),
      ].join('. '),
      rippleController: rippleController,
      builder: (context, narration) => QuestionFrame(
        prompt: leftQuestion.title,
        narration: narration,
        readAloudEnabled: readAloudEnabled,
        glossaryTermIds: const <String>['riparianZone'],
        badge: strings.assessOptionalLabel,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            _MarginSection(
              label: strings.assessMarginLeftLabel,
              question: leftQuestion,
              value: draft.yesNoAnswer(leftQuestion),
              isNotSure: draft.isNotSure(leftQuestion.id),
              onChanged: (value, notSure) => onChanged(leftQuestion, value, notSure),
            ),
            const SizedBox(height: AppSpacing.lg),
            _MarginSection(
              label: strings.assessMarginRightLabel,
              question: rightQuestion,
              value: draft.yesNoAnswer(rightQuestion),
              isNotSure: draft.isNotSure(rightQuestion.id),
              onChanged: (value, notSure) => onChanged(rightQuestion, value, notSure),
            ),
          ],
        ),
      ),
    );
  }
}

/// Vegetation cover, paired left/right margins, each with its own
/// conditional vegetation-type picker once that side is marked covered.
class VegetationCoveragePage extends StatelessWidget {
  const VegetationCoveragePage({
    super.key,
    required this.leftCoverQuestion,
    required this.rightCoverQuestion,
    required this.leftTypeQuestion,
    required this.rightTypeQuestion,
    required this.draft,
    required this.onCoverChanged,
    required this.onTypeChanged,
    required this.rippleController,
    required this.readAloudEnabled,
  });

  final AssessmentQuestion leftCoverQuestion;
  final AssessmentQuestion rightCoverQuestion;
  final AssessmentQuestion leftTypeQuestion;
  final AssessmentQuestion rightTypeQuestion;
  final AssessmentDraft draft;
  final void Function(AssessmentQuestion question, bool? value, bool notSure) onCoverChanged;
  final void Function(AssessmentQuestion question, AssessmentOption? option) onTypeChanged;
  final RippleController rippleController;
  final bool readAloudEnabled;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    return NarratedQuestionFrame(
      narrationId: 'vegetationCoverage',
      fullText: <String>[
        leftCoverQuestion.prompt,
        rightCoverQuestion.prompt,
      ].join('. '),
      rippleController: rippleController,
      builder: (context, narration) => QuestionFrame(
        prompt: leftCoverQuestion.title,
        narration: narration,
        readAloudEnabled: readAloudEnabled,
        glossaryTermIds: const <String>['riparianZone'],
        badge: strings.assessOptionalLabel,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            _MarginSection(
              label: strings.assessMarginLeftLabel,
              question: leftCoverQuestion,
              value: draft.yesNoAnswer(leftCoverQuestion),
              isNotSure: draft.isNotSure(leftCoverQuestion.id),
              onChanged: (value, notSure) =>
                  onCoverChanged(leftCoverQuestion, value, notSure),
              trailing: leftTypeQuestion.isVisible(draft)
                  ? _VegetationTypePicker(
                      question: leftTypeQuestion,
                      draft: draft,
                      onSelected: (option) => onTypeChanged(leftTypeQuestion, option),
                    )
                  : null,
            ),
            const SizedBox(height: AppSpacing.lg),
            _MarginSection(
              label: strings.assessMarginRightLabel,
              question: rightCoverQuestion,
              value: draft.yesNoAnswer(rightCoverQuestion),
              isNotSure: draft.isNotSure(rightCoverQuestion.id),
              onChanged: (value, notSure) =>
                  onCoverChanged(rightCoverQuestion, value, notSure),
              trailing: rightTypeQuestion.isVisible(draft)
                  ? _VegetationTypePicker(
                      question: rightTypeQuestion,
                      draft: draft,
                      onSelected: (option) => onTypeChanged(rightTypeQuestion, option),
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}

class _VegetationTypePicker extends StatelessWidget {
  const _VegetationTypePicker({
    required this.question,
    required this.draft,
    required this.onSelected,
  });

  final AssessmentQuestion question;
  final AssessmentDraft draft;
  final ValueChanged<AssessmentOption?> onSelected;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final selected = draft.selectedOption(question);
    final isNotSure = draft.isNotSure(question.id);
    final realOptions = question.options.where((o) => !o.isNotSure).toList();
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(question.prompt, style: Theme.of(context).textTheme.bodyMedium),
          if (question.info != null)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                question.info!,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          const SizedBox(height: AppSpacing.xs),
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: <Widget>[
              for (final option in realOptions)
                AquaFilterChip(
                  label: option.label,
                  selected: !isNotSure && selected?.code == option.code,
                  onSelected: (_) => onSelected(option),
                ),
              AquaFilterChip(
                label: strings.assessNotSureLabel,
                selected: isNotSure,
                onSelected: (_) => onSelected(question.options.last),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MarginSection extends StatelessWidget {
  const _MarginSection({
    required this.label,
    required this.question,
    required this.value,
    required this.isNotSure,
    required this.onChanged,
    this.trailing,
  });

  final String label;
  final AssessmentQuestion question;
  final bool? value;
  final bool isNotSure;
  final void Function(bool? value, bool notSure) onChanged;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(label, style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: AppSpacing.xxs),
          Text(question.prompt, style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: AppSpacing.sm),
          YesNoNotSureControl(value: value, isNotSure: isNotSure, onChanged: onChanged),
          if (isNotSure) ...<Widget>[
            const SizedBox(height: AppSpacing.xs),
            Text(
              strings.assessNotSureCoaching,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

/// Invasive species: the yes/no/not-sure gate plus its conditional
/// "which ones?" free text, as one combined idea.
class InvasiveSpeciesPage extends StatefulWidget {
  const InvasiveSpeciesPage({
    super.key,
    required this.question,
    required this.textQuestion,
    required this.draft,
    required this.onChanged,
    required this.onTextChanged,
    required this.rippleController,
    required this.readAloudEnabled,
  });

  final AssessmentQuestion question;
  final AssessmentQuestion textQuestion;
  final AssessmentDraft draft;
  final void Function(bool? value, bool notSure) onChanged;
  final ValueChanged<String?> onTextChanged;
  final RippleController rippleController;
  final bool readAloudEnabled;

  @override
  State<InvasiveSpeciesPage> createState() => _InvasiveSpeciesPageState();
}

class _InvasiveSpeciesPageState extends State<InvasiveSpeciesPage> {
  late final TextEditingController _textController = TextEditingController(
    text: widget.draft.textAnswer(widget.textQuestion) ?? '',
  );

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final question = widget.question;
    final textQuestion = widget.textQuestion;
    final draft = widget.draft;
    final onChanged = widget.onChanged;
    final onTextChanged = widget.onTextChanged;
    final rippleController = widget.rippleController;
    final readAloudEnabled = widget.readAloudEnabled;
    final strings = AppLocalizations.of(context);
    final isNotSure = draft.isNotSure(question.id);
    final showText = textQuestion.isVisible(draft);

    return NarratedQuestionFrame(
      narrationId: question.id,
      fullText: <String>[
        question.prompt,
        ...question.options.map((o) => o.label),
      ].join('. '),
      rippleController: rippleController,
      builder: (context, narration) => QuestionFrame(
        prompt: question.prompt,
        narration: narration,
        readAloudEnabled: readAloudEnabled,
        glossaryTermIds: question.glossaryTermIds,
        badge: strings.assessOptionalLabel,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            YesNoNotSureControl(
              value: draft.yesNoAnswer(question),
              isNotSure: isNotSure,
              onChanged: onChanged,
            ),
            if (isNotSure) ...<Widget>[
              const SizedBox(height: AppSpacing.sm),
              Text(
                strings.assessNotSureCoaching,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
            if (showText) ...<Widget>[
              const SizedBox(height: AppSpacing.md),
              TextField(
                key: const Key('invasiveSpeciesTextField'),
                controller: _textController,
                decoration: InputDecoration(
                  hintText: textQuestion.placeholder,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadii.md),
                  ),
                ),
                onChanged: (value) =>
                    onTextChanged(value.trim().isEmpty ? null : value.trim()),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
