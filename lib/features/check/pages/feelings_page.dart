import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../core/mascot/ripple_controller.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/aqua_components.dart';
import '../../../data/assessment/assessment_protocol.dart';
import '../../../data/repositories/repository_models.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../widgets/narrated_question_frame.dart';
import '../widgets/question_frame.dart';

/// The feelings moment: four independent 0-5 intensity ratings (joy,
/// serenity, anger, fear), each with its own "Not applicable" escape
/// hatch, plus the short research explainer from the protocol content.
class FeelingsPage extends StatelessWidget {
  const FeelingsPage({
    super.key,
    required this.questions,
    required this.draft,
    required this.onChanged,
    required this.rippleController,
    required this.readAloudEnabled,
  });

  final List<AssessmentQuestion> questions;
  final AssessmentDraft draft;
  final void Function(AssessmentQuestion question, int value) onChanged;
  final RippleController rippleController;
  final bool readAloudEnabled;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final prompt = questions.first.prompt;
    final info = questions.first.info;
    final instructions = questions.first.placeholder;

    return NarratedQuestionFrame(
      narrationId: 'feelings',
      fullText: <String>[
        prompt,
        if (info != null) info,
        if (instructions != null) instructions,
        for (final question in questions) question.title,
      ].join('. '),
      rippleController: rippleController,
      builder: (context, narration) => QuestionFrame(
        prompt: prompt,
        narration: narration,
        readAloudEnabled: readAloudEnabled,
        info: info,
        badge: strings.assessOptionalLabel,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            if (instructions != null) ...<Widget>[
              Text(instructions, style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(height: AppSpacing.md),
            ],
            for (final question in questions) ...<Widget>[
              _FeelingRow(
                question: question,
                value: draft.feelingAnswer(question),
                onChanged: (value) => onChanged(question, value),
              ),
              const SizedBox(height: AppSpacing.md),
            ],
          ],
        ),
      ),
    );
  }
}

class _FeelingRow extends StatelessWidget {
  const _FeelingRow({required this.question, required this.value, required this.onChanged});

  final AssessmentQuestion question;
  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final isNotApplicable = value == question.notApplicableValue;
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
          Text(
            strings.assessFeelingIntensityPrompt(question.title),
            style: Theme.of(context).textTheme.labelLarge,
          ),
          const SizedBox(height: AppSpacing.sm),
          Semantics(
            label: '${question.title}, ${value.toString()} of ${question.max}',
            child: ExcludeSemantics(
              child: Wrap(
                spacing: AppSpacing.xs,
                children: <Widget>[
                  for (var level = question.min; level <= question.max; level++)
                    _LevelButton(
                      level: level,
                      selected: !isNotApplicable && value == level,
                      onTap: () => onChanged(level),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          InkWell(
            key: Key('feelingNotApplicable_${question.id}'),
            onTap: () => onChanged(question.notApplicableValue),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Icon(
                  isNotApplicable
                      ? PhosphorIconsFill.checkSquare
                      : PhosphorIconsRegular.square,
                  size: 20,
                  color: isNotApplicable ? AppColors.deepWater : AppColors.inkMuted,
                ),
                const SizedBox(width: AppSpacing.xxs),
                Text(
                  question.notApplicableLabel ?? 'Not applicable',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LevelButton extends StatelessWidget {
  const _LevelButton({required this.level, required this.selected, required this.onTap});

  final int level;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadii.pill),
      child: Container(
        width: 40,
        height: 40,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? AppColors.deepWater : Colors.transparent,
          shape: BoxShape.circle,
          border: Border.all(
            color: selected ? AppColors.deepWater : AppColors.outline,
            width: 2,
          ),
        ),
        child: Text(
          '$level',
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: selected ? AppColors.white : AppColors.ink,
          ),
        ),
      ),
    );
  }
}
