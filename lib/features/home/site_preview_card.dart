import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../core/theme/tokens.dart';
import '../../data/repositories/repository_models.dart';
import '../../l10n/generated/app_localizations.dart';
import 'walk_time.dart';

/// Bottom card shown when a map pin is tapped, leading to site detail.
class SitePreviewCard extends StatelessWidget {
  const SitePreviewCard({
    super.key,
    required this.site,
    required this.visited,
    required this.onViewDetails,
    required this.onClose,
  });

  final StreamSite site;
  final bool visited;
  final VoidCallback onViewDetails;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final colors = Theme.of(context).colorScheme;
    final walkMinutes = walkMinutesFor(site.distanceKm);
    final subtitle = <String>[
      if (walkMinutes != null) strings.mapWalkMinutes(walkMinutes),
      visited ? strings.mapFilterVisited : strings.mapFilterNeedsData,
    ].join(' · ');

    return Material(
      color: colors.surface,
      borderRadius: BorderRadius.circular(AppRadii.lg),
      child: InkWell(
        key: const Key('sitePreviewCard'),
        borderRadius: BorderRadius.circular(AppRadii.lg),
        onTap: onViewDetails,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadii.lg),
            border: Border.all(color: colors.outlineVariant),
            boxShadow: AppElevation.high,
          ),
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: <Widget>[
              const PhosphorIcon(
                PhosphorIconsRegular.mapPin,
                color: AppColors.deepWater,
                size: 28,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(
                      site.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              IconButton(
                key: const Key('sitePreviewCardClose'),
                tooltip: strings.mapSitePreviewCloseLabel,
                onPressed: onClose,
                icon: const PhosphorIcon(PhosphorIconsRegular.x),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
