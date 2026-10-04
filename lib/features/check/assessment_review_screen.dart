import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../app/app_router.dart';
import '../../core/errors/friendly_error.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/aqua_components.dart';
import '../../core/widgets/friendly_error_banner.dart';
import '../../data/assessment/assessment_protocol.dart';
import '../../data/repositories/assessment_repository.dart';
import '../../data/repositories/repository_models.dart';
import '../../data/repositories/repository_scope.dart';
import '../../l10n/generated/app_localizations.dart';
import 'assessment_celebration_screen.dart';
import 'assessment_completeness.dart';

class AssessmentReviewScreen extends StatefulWidget {
  const AssessmentReviewScreen({super.key, required this.draft});

  final AssessmentDraft draft;

  @override
  State<AssessmentReviewScreen> createState() => _AssessmentReviewScreenState();
}

class _AssessmentReviewScreenState extends State<AssessmentReviewScreen> {
  Future<AssessmentProtocol>? _protocolFuture;
  bool _submitting = false;
  bool _queued = false;
  String? _friendlyError;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _protocolFuture ??= RepositoryScope.of(context)
        .repositories
        .assessments
        .contentForLocale(Localizations.localeOf(context).languageCode)
        .then(AssessmentProtocol.fromContent);
  }

  Future<void> _submit() async {
    setState(() {
      _submitting = true;
      _friendlyError = null;
    });
    try {
      final repository = RepositoryScope.of(context).repositories.assessments;
      AssessmentRecord? record;
      if (repository is QueuedAssessmentRepository) {
        final outcome = await repository.submitOrQueue(widget.draft);
        if (outcome.queued) {
          if (mounted) setState(() => _queued = true);
          return;
        }
        record = outcome.record;
      } else {
        record = await repository.submit(widget.draft);
      }
      if (!mounted || record == null) return;
      context.go(
        AppRoutes.checkCelebration,
        extra: AssessmentCelebrationData(
          record: record,
          photoCount: widget.draft.attachments.length,
        ),
      );
    } catch (error) {
      if (mounted) {
        setState(() => _friendlyError = FriendlyError.fromFailure(error: error));
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  bool _requiredComplete(AssessmentProtocol protocol) => protocol.allQuestions
      .where((question) => question.required && question.isVisible(widget.draft))
      .every(widget.draft.satisfiesRequired);

  void _editPage(int page) {
    final draft = widget.draft;
    context.go(
      '${AppRoutes.checkAssess}?page=$page',
      extra: StreamSite(
        code: draft.siteCode,
        name: draft.siteCode,
        latitude: draft.siteLatitude ?? draft.latitude,
        longitude: draft.siteLongitude ?? draft.longitude,
        isUserGenerated: draft.siteKind == SiteKind.userGenerated,
      ),
    );
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
              return Center(child: RippleLoadingState(label: strings.assessLoadingLabel));
            }
            final requiredComplete = _requiredComplete(protocol);
            final completeness = AssessmentCompletenessMeter.evaluate(widget.draft);
            return ListView(
              padding: const EdgeInsets.all(AppSpacing.page),
              children: <Widget>[
                Text(strings.assessReviewBody, style: Theme.of(context).textTheme.bodyLarge),
                const SizedBox(height: AppSpacing.lg),
                _CompletenessCard(completeness: completeness),
                const SizedBox(height: AppSpacing.lg),
                _ReviewGroup(
                  title: strings.assessReviewPhotosGroup,
                  icon: PhosphorIconsRegular.camera,
                  summary: strings.assessReviewPhotoCount(widget.draft.attachments.length),
                  onEdit: () => context.go(AppRoutes.checkPhotos, extra: widget.draft),
                ),
                _ReviewGroup(
                  title: strings.assessReviewLocationGroup,
                  icon: PhosphorIconsRegular.mapPin,
                  summary: !widget.draft.gpsConfirmed
                      ? strings.assessGpsNotChecked
                      : widget.draft.gpsDistanceMeters == null ||
                          widget.draft.gpsAccuracyMeters == null
                      ? strings.assessGpsManuallyConfirmed
                      : strings.assessGpsResult(
                          widget.draft.gpsDistanceMeters!.round(),
                          widget.draft.gpsAccuracyMeters!.round(),
                        ),
                  onEdit: () => context.go(
                    AppRoutes.checkPhotos,
                    extra: widget.draft,
                  ),
                ),
                _QuestionGroup(
                  title: strings.assessReviewChannelGroup,
                  icon: PhosphorIconsRegular.path,
                  questions: protocol.allQuestions.where((question) => question.step == 4),
                  draft: widget.draft,
                  onEdit: () => _editPage(0),
                ),
                _QuestionGroup(
                  title: strings.assessReviewWaterGroup,
                  icon: PhosphorIconsRegular.waves,
                  questions: protocol.allQuestions.where((question) => question.step == 5),
                  draft: widget.draft,
                  onEdit: () => _editPage(6),
                ),
                _QuestionGroup(
                  title: strings.assessReviewMarginsGroup,
                  icon: PhosphorIconsRegular.tree,
                  questions: protocol.allQuestions.where((question) => question.step == 6),
                  draft: widget.draft,
                  onEdit: () => _editPage(13),
                ),
                _QuestionGroup(
                  title: strings.assessReviewHealthGroup,
                  icon: PhosphorIconsRegular.heartbeat,
                  questions: protocol.allQuestions.where((question) => question.step == 7),
                  draft: widget.draft,
                  onEdit: () => _editPage(18),
                ),
                _QuestionGroup(
                  title: strings.assessReviewFeelingsGroup,
                  icon: PhosphorIconsRegular.smiley,
                  questions: protocol.allQuestions.where((question) => question.step == 8),
                  draft: widget.draft,
                  onEdit: () => _editPage(19),
                ),
                const SizedBox(height: AppSpacing.md),
                if (!requiredComplete)
                  FriendlyErrorBanner(message: strings.assessReviewRequiredMissing),
                if (_friendlyError != null)
                  Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.sm),
                    child: FriendlyErrorBanner(
                      message: _friendlyError!,
                      onRetry: _submit,
                    ),
                  ),
                if (_queued)
                  const Padding(
                    padding: EdgeInsets.only(top: AppSpacing.sm),
                    child: _QueuedReceipt(),
                  ),
                const SizedBox(height: AppSpacing.md),
                Text(strings.assessReviewConsent, style: Theme.of(context).textTheme.bodySmall),
                const SizedBox(height: AppSpacing.md),
                if (_submitting)
                  RippleLoadingState(label: strings.assessReviewSubmitting)
                else
                  AquaButton(
                    key: const Key('assessmentSubmitButton'),
                    label: strings.assessReviewSubmitAction,
                    onPressed: requiredComplete && !_queued
                        ? _submit
                        : null,
                  ),
                if (_queued) ...<Widget>[
                  const SizedBox(height: AppSpacing.sm),
                  AquaButton(
                    label: strings.assessReviewBackToHomeAction,
                    variant: AquaButtonVariant.secondary,
                    onPressed: () => context.go(AppRoutes.home),
                  ),
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}

class _CompletenessCard extends StatelessWidget {
  const _CompletenessCard({required this.completeness});
  final AssessmentCompleteness completeness;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    return Semantics(
      value: strings.assessReviewCompletenessValue(
        completeness.completed,
        completeness.total,
      ),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.waterMist,
          borderRadius: BorderRadius.circular(AppRadii.lg),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(strings.assessReviewCompleteness, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: AppSpacing.xs),
            LinearProgressIndicator(
              value: completeness.fraction,
              minHeight: AppSpacing.xs,
              borderRadius: BorderRadius.circular(AppRadii.pill),
              color: AppColors.deepWater,
              backgroundColor: AppColors.waterLight,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(strings.assessReviewCompletenessValue(
              completeness.completed,
              completeness.total,
            )),
            Text(
              completeness.mostValuableMissingField == null
                  ? strings.assessReviewCompleteTip
                  : strings.assessReviewMissingTip(
                      _missingFieldLabel(
                        strings,
                        completeness.mostValuableMissingField!,
                      ),
                    ),
              style: Theme.of(context).textTheme.labelMedium,
            ),
          ],
        ),
      ),
    );
  }
}

String _missingFieldLabel(
  AppLocalizations strings,
  CompletenessField field,
) => switch (field) {
  CompletenessField.upstreamPhoto => strings.assessMissingUpstreamPhoto,
  CompletenessField.downstreamPhoto => strings.assessMissingDownstreamPhoto,
  CompletenessField.channelForm => strings.assessMissingChannelForm,
  CompletenessField.streambedType => strings.assessMissingStreambedType,
  CompletenessField.bankType => strings.assessMissingBankType,
  CompletenessField.waterFlow => strings.assessMissingWaterFlow,
  CompletenessField.waterAppearance => strings.assessMissingWaterAppearance,
  CompletenessField.habitatObservations => strings.assessMissingHabitats,
  CompletenessField.marginVegetation => strings.assessMissingMarginVegetation,
};

class _QuestionGroup extends StatelessWidget {
  const _QuestionGroup({
    required this.title,
    required this.icon,
    required this.questions,
    required this.draft,
    required this.onEdit,
  });

  final String title;
  final IconData icon;
  final Iterable<AssessmentQuestion> questions;
  final AssessmentDraft draft;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final summaries = questions
        .where((question) => question.isVisible(draft))
        .map((question) => _answerSummary(strings, draft, question))
        .where((answer) => answer != strings.assessReviewUnanswered)
        .toList();
    return _ReviewGroup(
      title: title,
      icon: icon,
      summary: summaries.isEmpty ? strings.assessReviewUnanswered : summaries.join(' · '),
      onEdit: onEdit,
    );
  }
}

class _ReviewGroup extends StatelessWidget {
  const _ReviewGroup({
    required this.title,
    required this.icon,
    required this.summary,
    required this.onEdit,
  });

  final String title;
  final IconData icon;
  final String summary;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppRadii.md),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(icon, color: AppColors.deepWater),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(title, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: AppSpacing.xxs),
                Text(summary, maxLines: 3, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          TextButton(onPressed: onEdit, child: Text(strings.assessReviewEditAction)),
        ],
      ),
    );
  }
}

class _QueuedReceipt extends StatelessWidget {
  const _QueuedReceipt();

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.warningContainer,
        borderRadius: BorderRadius.circular(AppRadii.md),
      ),
      child: Row(
        children: <Widget>[
          const Icon(PhosphorIconsRegular.cloudArrowUp, color: AppColors.warning),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(strings.assessReviewQueuedTitle, style: Theme.of(context).textTheme.labelLarge),
                Text(strings.assessReviewQueuedBody),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

String _answerSummary(
  AppLocalizations strings,
  AssessmentDraft draft,
  AssessmentQuestion question,
) {
  if (draft.isNotSure(question.id)) return strings.assessReviewNotSure;
  if (question.required && !draft.answeredQuestionIds.contains(question.id)) {
    return strings.assessReviewUnanswered;
  }
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
