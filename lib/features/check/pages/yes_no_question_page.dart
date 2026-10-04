import 'package:flutter/material.dart';

import '../../../core/mascot/ripple_controller.dart';
import '../../../core/theme/tokens.dart';
import '../../../data/assessment/assessment_protocol.dart';
import '../../../data/repositories/repository_models.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../widgets/narrated_question_frame.dart';
import '../widgets/question_frame.dart';
import '../widgets/yes_no_not_sure_control.dart';

/// A single yes/no/not-sure question (water abstraction, dams, pipes,
/// sewage discharge, construction, vegetation cuts, and the riparian
/// invasive-species gate).
class YesNoQuestionPage extends StatelessWidget {
  const YesNoQuestionPage({
    super.key,
    required this.question,
    required this.draft,
    required this.onChanged,
    required this.rippleController,
    required this.readAloudEnabled,
  });

  final AssessmentQuestion question;
  final AssessmentDraft draft;
  final void Function(bool? value, bool notSure) onChanged;
  final RippleController rippleController;
  final bool readAloudEnabled;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
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
        info: question.info,
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
          ],
        ),
      ),
    );
  }
}
