import 'package:flutter/material.dart';

import '../../../core/gamification/badge_catalog.dart';
import '../../../core/gamification/badge_rules.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/badge_crest.dart';
import '../../../l10n/generated/app_localizations.dart';

/// The evidence badge shelf: every release-1 badge, locked or not, in a
/// fixed order (no tiers). Tapping a freshly-unlocked badge plays its
/// one-shot reveal once and acknowledges it via [onAcknowledge].
class BadgeShelf extends StatelessWidget {
  const BadgeShelf({
    super.key,
    required this.unlocked,
    required this.acknowledged,
    required this.onAcknowledge,
  });

  final Set<EvidenceBadgeId> unlocked;
  final Set<EvidenceBadgeId> acknowledged;
  final void Function(EvidenceBadgeId id) onAcknowledge;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final catalog = badgeCatalog(strings);
    return Wrap(
      spacing: AppSpacing.md,
      runSpacing: AppSpacing.md,
      children: <Widget>[
        for (final display in catalog)
          BadgeCrest(
            key: ValueKey<EvidenceBadgeId>(display.id),
            name: display.name,
            criterion: display.criterion,
            icon: display.icon,
            discipline: display.discipline,
            state: _stateFor(display.id),
            onTap: _stateFor(display.id) == BadgeState.newBadge
                ? () => _showUnlockSheet(context, display)
                : null,
          ),
      ],
    );
  }

  BadgeState _stateFor(EvidenceBadgeId id) {
    if (!unlocked.contains(id)) return BadgeState.locked;
    return acknowledged.contains(id) ? BadgeState.unlocked : BadgeState.newBadge;
  }

  Future<void> _showUnlockSheet(
    BuildContext context,
    BadgeDisplay display,
  ) async {
    final strings = AppLocalizations.of(context);
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                strings.profileBadgeNewSheetTitle,
                style: Theme.of(sheetContext).textTheme.headlineMedium,
              ),
              const SizedBox(height: AppSpacing.md),
              BadgeUnlockReveal(
                badge: BadgeCrest(
                  name: display.name,
                  criterion: display.criterion,
                  icon: display.icon,
                  discipline: display.discipline,
                  state: BadgeState.unlocked,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              FilledButton(
                onPressed: () => Navigator.of(sheetContext).pop(),
                child: Text(strings.profileBadgeNewSheetCta),
              ),
            ],
          ),
        ),
      ),
    );
    onAcknowledge(display.id);
  }
}
