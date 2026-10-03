import 'package:flutter/material.dart';

import '../../l10n/generated/app_localizations.dart';
import '../mode/app_mode.dart';
import '../theme/tokens.dart';

class ModeBadge extends StatelessWidget {
  const ModeBadge({required this.mode, this.onTap, super.key});

  final AppMode mode;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final label = mode.isLive ? strings.modeLive : strings.modeDemo;
    final foreground = mode.isLive ? AppColors.success : AppColors.navy;
    final background = mode.isLive
        ? AppColors.successContainer
        : AppColors.sparkle;

    return Semantics(
      button: onTap != null,
      excludeSemantics: true,
      label: strings.modeIndicatorLabel(label),
      child: Material(
        color: background,
        borderRadius: BorderRadius.circular(AppRadii.pill),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadii.pill),
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              minHeight: AppSpacing.minTouchTarget,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: AppSpacing.xs,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  if (mode.isLive) ...<Widget>[
                    Container(
                      width: AppSpacing.xs,
                      height: AppSpacing.xs,
                      decoration: BoxDecoration(
                        color: foreground,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                  ],
                  Text(
                    label.toUpperCase(),
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: foreground,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.1,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
