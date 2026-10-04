import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../core/mascot/ripple_controller.dart';
import '../../../core/theme/tokens.dart';
import '../../../data/assessment/assessment_protocol.dart';
import '../../../data/repositories/repository_models.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../widgets/narrated_question_frame.dart';
import '../widgets/question_frame.dart';

/// The required Good / Moderate / Poor overall-quality choice -- three
/// stacked cards with their own one-line descriptor, never offering
/// "I'm not sure" since every stream check needs one.
class OverallAssessmentPage extends StatelessWidget {
  const OverallAssessmentPage({
    super.key,
    required this.question,
    required this.draft,
    required this.onSelected,
    required this.rippleController,
    required this.readAloudEnabled,
  });

  final AssessmentQuestion question;
  final AssessmentDraft draft;
  final ValueChanged<AssessmentOption> onSelected;
  final RippleController rippleController;
  final bool readAloudEnabled;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final selected = draft.selectedOption(question);

    return NarratedQuestionFrame(
      narrationId: question.id,
      fullText: <String>[
        question.prompt,
        for (final option in question.options) '${option.label}. ${option.description ?? ''}',
      ].join(' '),
      rippleController: rippleController,
      builder: (context, narration) => QuestionFrame(
        prompt: question.prompt,
        narration: narration,
        readAloudEnabled: readAloudEnabled,
        badge: strings.assessRequiredLabel,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            for (final option in question.options) ...<Widget>[
              _OverallCard(
                option: option,
                selected: selected?.code == option.code,
                onTap: () => onSelected(option),
              ),
              const SizedBox(height: AppSpacing.sm),
            ],
          ],
        ),
      ),
    );
  }
}

class _OverallCard extends StatelessWidget {
  const _OverallCard({required this.option, required this.selected, required this.onTap});

  final AssessmentOption option;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final icon = switch (option.code) {
      'GOOD' => PhosphorIconsFill.leaf,
      'POOR' => PhosphorIconsFill.warning,
      _ => PhosphorIconsFill.drop,
    };
    final iconColor = switch (option.code) {
      'GOOD' => AppColors.success,
      'POOR' => AppColors.error,
      _ => AppColors.warning,
    };
    return Semantics(
      button: true,
      selected: selected,
      label: '${option.label}. ${option.description ?? ''}',
      child: ExcludeSemantics(
        child: Material(
          color: colors.surface,
          borderRadius: BorderRadius.circular(AppRadii.lg),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(AppRadii.lg),
            child: Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppRadii.lg),
                border: Border.all(
                  color: selected ? AppColors.deepWater : colors.outlineVariant,
                  width: selected ? AppStrokes.selected : 1,
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Icon(icon, color: iconColor, size: 28),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(option.label, style: Theme.of(context).textTheme.titleLarge),
                        if (option.description != null) ...<Widget>[
                          const SizedBox(height: AppSpacing.xxs),
                          Text(
                            option.description!,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
