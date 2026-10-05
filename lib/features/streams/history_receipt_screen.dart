import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/theme/tokens.dart';
import '../../core/widgets/stream_health_timeline.dart';
import '../../data/repositories/repository_models.dart';
import '../../l10n/generated/app_localizations.dart';

/// A read-only receipt for one already-submitted check. Deliberately plain:
/// it confirms what went through (stream, date, overall health, how many of
/// the four photo roles were captured), not a second copy of the full
/// submission review -- that belongs to the review/submit flow.
class HistoryReceiptScreen extends StatelessWidget {
  const HistoryReceiptScreen({
    super.key,
    required this.record,
    required this.siteName,
  });

  final AssessmentRecord record;
  final String siteName;

  static const List<AssessmentMediaRole> _photoRoles = <AssessmentMediaRole>[
    AssessmentMediaRole.upstreamPhoto,
    AssessmentMediaRole.downstreamPhoto,
    AssessmentMediaRole.surroundingPhoto,
    AssessmentMediaRole.interestingPhoto,
  ];

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final dateFormat = DateFormat.yMMMMd(
      Localizations.localeOf(context).toString(),
    );
    final level = streamHealthLevelFromOverallAssessment(record.overallAssessment);
    final photoCount = _photoRoles
        .where((role) => record.fileIds.containsKey(role))
        .length;

    return Scaffold(
      appBar: AppBar(title: Text(strings.streamsReceiptTitle)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.page),
          children: <Widget>[
            _ReceiptRow(label: strings.streamsReceiptSiteLabel, value: siteName),
            _ReceiptRow(
              label: strings.streamsReceiptDateLabel,
              value: dateFormat.format(record.submittedAt.toLocal()),
            ),
            _ReceiptRow(
              label: strings.streamsReceiptOverallLabel,
              value: _levelLabel(strings, level),
            ),
            _ReceiptRow(
              label: strings.streamsReceiptPhotosLabel,
              value: strings.streamsReceiptPhotosValue(photoCount),
            ),
            const SizedBox(height: AppSpacing.lg),
            Center(
              child: TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(strings.streamsReceiptCloseAction),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _levelLabel(AppLocalizations strings, StreamHealthLevel level) =>
      switch (level) {
        StreamHealthLevel.good => strings.healthLevelGood,
        StreamHealthLevel.moderate => strings.healthLevelModerate,
        StreamHealthLevel.poor => strings.healthLevelPoor,
        StreamHealthLevel.unknown => strings.healthLevelUnknown,
      };
}

class _ReceiptRow extends StatelessWidget {
  const _ReceiptRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Expanded(
            child: Text(label, style: Theme.of(context).textTheme.labelLarge),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}
