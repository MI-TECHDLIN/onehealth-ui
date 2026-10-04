import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/mascot/ripple_controller.dart';
import '../../../core/theme/tokens.dart';
import '../../../data/assessment/assessment_protocol.dart';
import '../../../data/repositories/repository_models.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../widgets/narrated_question_frame.dart';
import '../widgets/question_frame.dart';

/// The guided numeric water-height estimate. The wire contract never
/// enforces a numeric type (see `api-contract.md`), so this only restricts
/// the keyboard/characters, not the submitted value's shape.
class NumericTextQuestionPage extends StatefulWidget {
  const NumericTextQuestionPage({
    super.key,
    required this.question,
    required this.draft,
    required this.onChanged,
    required this.rippleController,
    required this.readAloudEnabled,
  });

  final AssessmentQuestion question;
  final AssessmentDraft draft;
  final ValueChanged<String?> onChanged;
  final RippleController rippleController;
  final bool readAloudEnabled;

  @override
  State<NumericTextQuestionPage> createState() => _NumericTextQuestionPageState();
}

class _NumericTextQuestionPageState extends State<NumericTextQuestionPage> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.draft.textAnswer(widget.question) ?? '',
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final question = widget.question;

    return NarratedQuestionFrame(
      narrationId: question.id,
      fullText: <String>[question.prompt, if (question.info != null) question.info!].join('. '),
      rippleController: widget.rippleController,
      builder: (context, narration) => QuestionFrame(
        prompt: question.prompt,
        narration: narration,
        readAloudEnabled: widget.readAloudEnabled,
        info: question.info,
        badge: strings.assessOptionalLabel,
        child: TextField(
          controller: _controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: <TextInputFormatter>[
            FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
          ],
          decoration: InputDecoration(
            hintText: question.placeholder,
            suffixText: 'm',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadii.md),
            ),
          ),
          onChanged: (value) =>
              widget.onChanged(value.trim().isEmpty ? null : value.trim()),
        ),
      ),
    );
  }
}
