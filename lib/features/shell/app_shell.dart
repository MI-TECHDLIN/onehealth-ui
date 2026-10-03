import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/settings/app_settings_controller.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/mode_badge.dart';
import '../../l10n/generated/app_localizations.dart';

class AppShell extends StatelessWidget {
  const AppShell({required this.currentPath, required this.child, super.key});

  final String currentPath;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final settings = AppSettingsScope.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(_titleFor(strings, currentPath)),
        actions: <Widget>[
          Padding(
            padding: const EdgeInsetsDirectional.only(end: AppSpacing.sm),
            child: ModeBadge(
              mode: settings.mode,
              onTap: () => context.push('/settings'),
            ),
          ),
        ],
      ),
      body: child,
      bottomNavigationBar: _FieldNavigationBar(currentPath: currentPath),
    );
  }

  static String _titleFor(AppLocalizations strings, String path) {
    if (path.startsWith('/streams')) return strings.streamsTitle;
    if (path.startsWith('/check')) return strings.checkTitle;
    if (path.startsWith('/impact')) return strings.impactTitle;
    if (path.startsWith('/profile')) return strings.profileTitle;
    return strings.homeTitle;
  }
}

class _FieldNavigationBar extends StatelessWidget {
  const _FieldNavigationBar({required this.currentPath});

  final String currentPath;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;

    return SafeArea(
      top: false,
      child: Container(
        height: AppSizes.bottomNavigationHeight,
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerLow,
          border: Border(top: BorderSide(color: colorScheme.outlineVariant)),
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: <Widget>[
            Row(
              children: <Widget>[
                _NavItem(
                  label: strings.navHome,
                  icon: Icons.home_outlined,
                  selectedIcon: Icons.home_rounded,
                  selected: currentPath == '/home',
                  onTap: () => context.go('/home'),
                ),
                _NavItem(
                  label: strings.navStreams,
                  icon: Icons.water_outlined,
                  selectedIcon: Icons.water,
                  selected: currentPath.startsWith('/streams'),
                  onTap: () => context.go('/streams'),
                ),
                const Expanded(child: SizedBox()),
                _NavItem(
                  label: strings.navImpact,
                  icon: Icons.insights_outlined,
                  selectedIcon: Icons.insights_rounded,
                  selected: currentPath.startsWith('/impact'),
                  onTap: () => context.go('/impact'),
                ),
                _NavItem(
                  label: strings.navProfile,
                  icon: Icons.person_outline_rounded,
                  selectedIcon: Icons.person_rounded,
                  selected: currentPath.startsWith('/profile'),
                  onTap: () => context.go('/profile'),
                ),
              ],
            ),
            PositionedDirectional(
              top: -AppSpacing.sm,
              start: 0,
              end: 0,
              child: Center(
                child: _CheckAction(
                  label: strings.navCheck,
                  selected: currentPath.startsWith('/check'),
                  onTap: () => context.go('/check'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.label,
    required this.icon,
    required this.selectedIcon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final IconData selectedIcon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final foreground = selected ? colors.primary : colors.onSurfaceVariant;
    return Expanded(
      child: Semantics(
        selected: selected,
        button: true,
        excludeSemantics: true,
        label: label,
        child: InkResponse(
          onTap: onTap,
          radius: AppSpacing.lg,
          child: SizedBox.expand(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                AnimatedContainer(
                  duration: AppMotion.quick,
                  curve: AppMotion.quickCurve,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: AppSpacing.xxs,
                  ),
                  decoration: BoxDecoration(
                    color: selected
                        ? colors.primaryContainer
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(AppRadii.pill),
                  ),
                  child: Icon(
                    selected ? selectedIcon : icon,
                    size: AppSizes.navigationIcon,
                    color: foreground,
                  ),
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: foreground,
                    fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
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

class _CheckAction extends StatelessWidget {
  const _CheckAction({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Semantics(
      selected: selected,
      button: true,
      excludeSemantics: true,
      label: label,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: AppElevation.raisedAction,
              border: Border.all(
                color: colors.surfaceContainerLow,
                width: AppSpacing.xxs,
              ),
            ),
            child: Material(
              color: AppColors.deepWater,
              shape: const CircleBorder(),
              clipBehavior: Clip.antiAlias,
              child: InkResponse(
                onTap: onTap,
                radius: AppSizes.raisedNavigationAction / 2,
                child: const SizedBox.square(
                  dimension: AppSizes.raisedNavigationAction,
                  child: Icon(
                    Icons.add_rounded,
                    color: AppColors.white,
                    size: AppSpacing.xl,
                  ),
                ),
              ),
            ),
          ),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: selected ? colors.primary : colors.onSurfaceVariant,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
