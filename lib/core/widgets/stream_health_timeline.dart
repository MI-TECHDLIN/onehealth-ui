import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../theme/tokens.dart';

enum StreamHealthLevel { good, moderate, poor, unknown }

StreamHealthLevel streamHealthLevelFromOverallAssessment(String? value) {
  switch (value) {
    case 'GOOD':
      return StreamHealthLevel.good;
    case 'MODERATE':
      return StreamHealthLevel.moderate;
    case 'POOR':
      return StreamHealthLevel.poor;
    default:
      return StreamHealthLevel.unknown;
  }
}

Color _colorFor(StreamHealthLevel level) => switch (level) {
  StreamHealthLevel.good => AppColors.success,
  StreamHealthLevel.moderate => AppColors.warning,
  StreamHealthLevel.poor => AppColors.error,
  StreamHealthLevel.unknown => AppColors.outline,
};

/// One past check worth showing on a site's health timeline.
class StreamHealthEntry {
  const StreamHealthEntry({required this.date, required this.level});

  final DateTime date;
  final StreamHealthLevel level;
}

/// A simple, accessible vertical timeline of past good/moderate/poor checks
/// for one site. Quality is never color-only: every row also carries its
/// word label and a full sentence in its semantics.
class StreamHealthTimeline extends StatelessWidget {
  const StreamHealthTimeline({
    super.key,
    required this.entries,
    required this.levelLabel,
    required this.rowSemanticLabel,
  });

  /// Newest first.
  final List<StreamHealthEntry> entries;
  final String Function(StreamHealthLevel level) levelLabel;
  final String Function(String dateLabel, String levelLabel) rowSemanticLabel;

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat.yMMMd(Localizations.localeOf(context).toString());
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        for (var i = 0; i < entries.length; i++)
          _TimelineRow(
            entry: entries[i],
            dateLabel: dateFormat.format(entries[i].date.toLocal()),
            levelLabel: levelLabel(entries[i].level),
            semanticLabel: rowSemanticLabel(
              dateFormat.format(entries[i].date.toLocal()),
              levelLabel(entries[i].level),
            ),
            isLast: i == entries.length - 1,
          ),
      ],
    );
  }
}

class _TimelineRow extends StatelessWidget {
  const _TimelineRow({
    required this.entry,
    required this.dateLabel,
    required this.levelLabel,
    required this.semanticLabel,
    required this.isLast,
  });

  final StreamHealthEntry entry;
  final String dateLabel;
  final String levelLabel;
  final String semanticLabel;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final color = _colorFor(entry.level);
    return Semantics(
      label: semanticLabel,
      child: ExcludeSemantics(
        child: Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Column(
                  children: <Widget>[
                    Container(
                      width: 14,
                      height: 14,
                      margin: const EdgeInsets.only(top: 2),
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.white, width: 2),
                      ),
                    ),
                    if (!isLast)
                      Expanded(
                        child: Container(
                          width: 2,
                          margin: const EdgeInsets.symmetric(vertical: 2),
                          color: AppColors.outline,
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                    child: Row(
                      children: <Widget>[
                        Expanded(
                          child: Text(
                            dateLabel,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.xs,
                            vertical: AppSpacing.xxs,
                          ),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.16),
                            borderRadius: BorderRadius.circular(AppRadii.pill),
                          ),
                          child: Text(
                            levelLabel,
                            style: Theme.of(context).textTheme.labelSmall
                                ?.copyWith(color: color, fontWeight: FontWeight.w700),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
