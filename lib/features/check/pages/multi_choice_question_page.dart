import 'package:flutter/material.dart';

import '../../../core/mascot/ripple_controller.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/aqua_components.dart';
import '../../../data/assessment/assessment_protocol.dart';
import '../../../data/repositories/repository_models.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../widgets/narrated_question_frame.dart';
import '../widgets/question_frame.dart';

/// Habitats / natural debris: a two-stage disclosure -- a yes/no gate
/// question, then (only on "yes") the multi-select chip list -- matching
/// the protocol's own `questiontextshow` reveal-gate copy. The gate itself
/// is UI-only; an empty answer list means the same thing on the wire
/// whether the citizen said "no" or left every chip unticked.
class MultiChoiceQuestionPage extends StatefulWidget {
  const MultiChoiceQuestionPage({
    super.key,
    required this.question,
    required this.draft,
    required this.onChanged,
    required this.rippleController,
    required this.readAloudEnabled,
  });

  final AssessmentQuestion question;
  final AssessmentDraft draft;
  final ValueChanged<List<String>> onChanged;
  final RippleController rippleController;
  final bool readAloudEnabled;

  @override
  State<MultiChoiceQuestionPage> createState() => _MultiChoiceQuestionPageState();
}

class _MultiChoiceQuestionPageState extends State<MultiChoiceQuestionPage> {
  late bool? _gateYes = _currentCodes.isEmpty ? null : true;

  List<String> get _currentCodes => switch (widget.question.payloadField) {
    'habitats' => widget.draft.habitats,
    'fallenBiomassTypes' => widget.draft.fallenBiomassTypes,
    _ => const <String>[],
  };

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final question = widget.question;
    final codes = _currentCodes;

    return NarratedQuestionFrame(
      narrationId: question.id,
      fullText: <String>[
        question.revealPrompt ?? question.prompt,
        question.prompt,
        ...question.options.map((o) => o.label),
      ].join('. '),
      rippleController: widget.rippleController,
      builder: (context, narration) => QuestionFrame(
        prompt: question.revealPrompt ?? question.prompt,
        narration: narration,
        readAloudEnabled: widget.readAloudEnabled,
        info: question.info,
        badge: strings.assessOptionalLabel,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Wrap(
              spacing: AppSpacing.sm,
              children: <Widget>[
                AquaFilterChip(
                  label: strings.assessYesAction,
                  selected: _gateYes == true,
                  onSelected: (_) => setState(() => _gateYes = true),
                ),
                AquaFilterChip(
                  label: strings.assessNoAction,
                  selected: _gateYes == false,
                  onSelected: (_) {
                    setState(() => _gateYes = false);
                    widget.onChanged(const <String>[]);
                  },
                ),
              ],
            ),
            if (_gateYes == true) ...<Widget>[
              const SizedBox(height: AppSpacing.md),
              Text(question.prompt, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: <Widget>[
                  for (final option in question.options)
                    AquaFilterChip(
                      label: option.label,
                      selected: codes.contains(option.code),
                      onSelected: (selected) {
                        final updated = <String>[...codes];
                        if (selected) {
                          updated.add(option.code!);
                        } else {
                          updated.remove(option.code);
                        }
                        widget.onChanged(updated);
                      },
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
