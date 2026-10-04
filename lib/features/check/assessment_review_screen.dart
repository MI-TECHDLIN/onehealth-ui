import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/app_router.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/aqua_components.dart';
import '../../data/assessment/assessment_protocol.dart';
import '../../data/repositories/repository_models.dart';
import '../../data/repositories/repository_scope.dart';
import '../../l10n/generated/app_localizations.dart';

/// Hand-off placeholder after the feelings step: lists the answered draft
/// so far. Photo capture and the real review/submit/celebration are the
/// next round's scope -- this screen exists only to give that work a
/// clean seam (the route, and the draft object it receives via `extra`).
class AssessmentReviewScreen extends StatefulWidget {
  const AssessmentReviewScreen({super.key, required this.draft});

  final AssessmentDraft draft;

  @override
  State<AssessmentReviewScreen> createState() => _AssessmentReviewScreenState();
}

class _AssessmentReviewScreenState extends State<AssessmentReviewScreen> {
  Future<AssessmentProtocol>? _protocolFuture;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _protocolFuture ??= RepositoryScope.of(context)
        .repositories
        .assessments
        .contentForLocale(Localizations.localeOf(context).languageCode)
        .then(AssessmentProtocol.fromContent);
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(strings.assessReviewTitle)),
      body: SafeArea(
        child: FutureBuilder<AssessmentProtocol>(
          future: _protocolFuture,
          builder: (context, snapshot) {
            final protocol = snapshot.data;
            if (protocol == null) {
              return const Center(child: CircularProgressIndicator());
            }
            final draft = widget.draft;
            return ListView(
              padding: const EdgeInsets.all(AppSpacing.page),
              children: <Widget>[
                Text(strings.assessReviewBody, style: Theme.of(context).textTheme.bodyLarge),
                const SizedBox(height: AppSpacing.lg),
                for (final question in protocol.allQuestions)
                  if (question.isVisible(draft))
                    Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Expanded(
                            child: Text(
                              question.title,
                              style: Theme.of(context).textTheme.labelLarge,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Text(
                              _answerSummary(strings, draft, question),
                              textAlign: TextAlign.end,
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ),
                        ],
                      ),
                    ),
                const SizedBox(height: AppSpacing.lg),
                AquaButton(
                  label: strings.assessReviewBackToHomeAction,
                  variant: AquaButtonVariant.secondary,
                  onPressed: () => context.go(AppRoutes.home),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  String _answerSummary(
    AppLocalizations strings,
    AssessmentDraft draft,
    AssessmentQuestion question,
  ) {
    if (draft.isNotSure(question.id)) return strings.assessReviewNotSure;
    switch (question.type) {
      case AssessmentFieldType.singleChoice:
      case AssessmentFieldType.overallChoice:
        return draft.selectedOption(question)?.label ?? strings.assessReviewUnanswered;
      case AssessmentFieldType.multiChoice:
        final codes = question.payloadField == 'habitats'
            ? draft.habitats
            : draft.fallenBiomassTypes;
        if (codes.isEmpty) return strings.assessReviewUnanswered;
        return question.options
            .where((option) => codes.contains(option.code))
            .map((option) => option.label)
            .join(', ');
      case AssessmentFieldType.yesNoNotSure:
        final value = draft.yesNoAnswer(question);
        if (value == null) return strings.assessReviewUnanswered;
        return value ? strings.assessYesAction : strings.assessNoAction;
      case AssessmentFieldType.freeText:
      case AssessmentFieldType.numericText:
        return draft.textAnswer(question) ?? strings.assessReviewUnanswered;
      case AssessmentFieldType.slider:
        return '${draft.feelingAnswer(question)} / ${question.max}';
    }
  }
}
