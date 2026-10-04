import 'package:flutter/material.dart';

import '../../../core/audio/assessment_narration_controller.dart';
import '../../../core/glossary/glossary_term_text.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/assessment_narration_control.dart';
import '../../../core/widgets/read_aloud_control.dart';

/// One idea per screen: the shared layout every question page renders
/// into -- an optional "Optional"/"Required" badge, the glossary-aware (or
/// word-highlighted) prompt, optional coaching copy, the narration
/// control, and the question-specific answer control passed as [child].
class QuestionFrame extends StatelessWidget {
  const QuestionFrame({
    super.key,
    required this.prompt,
    required this.narration,
    required this.readAloudEnabled,
    this.glossaryTermIds = const <String>[],
    this.info,
    this.badge,
    required this.child,
  });

  final String prompt;
  final AssessmentNarrationController narration;
  final bool readAloudEnabled;
  final List<String> glossaryTermIds;
  final String? info;
  final String? badge;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.page,
        vertical: AppSpacing.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          if (badge != null) ...<Widget>[
            Align(alignment: Alignment.centerLeft, child: QuestionBadge(text: badge!)),
            const SizedBox(height: AppSpacing.xs),
          ],
          if (glossaryTermIds.isNotEmpty)
            GlossaryTermText(
              text: prompt,
              termIds: glossaryTermIds,
              readAloudEnabled: readAloudEnabled,
              style: textTheme.headlineMedium,
            )
          else if (narration.isPiperAvailable)
            ReadAloudHighlightedText(
              text: prompt,
              service: narration.readAloud,
              segmentId: 'prompt',
              style: textTheme.headlineMedium,
            )
          else
            Text(prompt, style: textTheme.headlineMedium),
          if (info != null) ...<Widget>[
            const SizedBox(height: AppSpacing.xs),
            Text(
              info!,
              style: textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.sm),
          AssessmentNarrationControl(controller: narration, enabled: readAloudEnabled),
          const SizedBox(height: AppSpacing.lg),
          child,
        ],
      ),
    );
  }
}

class QuestionBadge extends StatelessWidget {
  const QuestionBadge({super.key, required this.text});
  final String text;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(
      horizontal: AppSpacing.sm,
      vertical: AppSpacing.xxs,
    ),
    decoration: BoxDecoration(
      color: AppColors.waterMist,
      borderRadius: BorderRadius.circular(AppRadii.pill),
      border: Border.all(color: AppColors.outline),
    ),
    child: Text(
      text,
      style: Theme.of(context).textTheme.labelSmall?.copyWith(
        color: AppColors.inkMuted,
        fontWeight: FontWeight.w700,
      ),
    ),
  );
}
