import 'package:flutter/material.dart';

import '../../../core/illustrations/assessment_illustrations.dart';
import '../../../core/mascot/ripple_controller.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/aqua_components.dart';
import '../../../data/assessment/assessment_protocol.dart';
import '../../../data/repositories/repository_models.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../widgets/narrated_question_frame.dart';
import '../widgets/question_frame.dart';

/// Channel form / bottom type / bank type: a grid of illustrated picture
/// cards, with "I'm not sure" as a ghost link beneath (per the component
/// inventory's picture-choice spec).
class PictureChoiceQuestionPage extends StatelessWidget {
  const PictureChoiceQuestionPage({
    super.key,
    required this.question,
    required this.draft,
    required this.onSelected,
    required this.rippleController,
    required this.readAloudEnabled,
  });

  final AssessmentQuestion question;
  final AssessmentDraft draft;
  final ValueChanged<AssessmentOption?> onSelected;
  final RippleController rippleController;
  final bool readAloudEnabled;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final realOptions = question.options.where((o) => !o.isNotSure).toList();
    final selected = draft.selectedOption(question);
    final isNotSure = draft.isNotSure(question.id);

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
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: AppSpacing.sm,
              crossAxisSpacing: AppSpacing.sm,
              childAspectRatio: 0.85,
              children: <Widget>[
                for (final option in realOptions)
                  PictureChoiceCard(
                    image: AssessmentIllustrations.widgetFor(
                      question.id,
                      option.code,
                    ),
                    label: option.label,
                    selected: !isNotSure && selected?.code == option.code,
                    onSelected: (_) => onSelected(option),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Center(
              child: NotSureButton(
                label: strings.assessNotSureLabel,
                onPressed: () => onSelected(question.options.last),
              ),
            ),
            if (isNotSure) ...<Widget>[
              const SizedBox(height: AppSpacing.sm),
              Text(
                strings.assessNotSureCoaching,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
