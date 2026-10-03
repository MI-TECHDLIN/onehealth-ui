import 'package:flutter/material.dart';

import '../mascot/aqua_mascot.dart';
import '../theme/tokens.dart';
import 'reduced_motion_lottie.dart';

enum AquaButtonVariant { primary, secondary, ghost }

/// Tactile 52 dp action used for primary, secondary and ghost actions.
class AquaButton extends StatefulWidget {
  const AquaButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = AquaButtonVariant.primary,
    this.leading,
    this.loading = false,
    this.expand = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final AquaButtonVariant variant;
  final Widget? leading;
  final bool loading;
  final bool expand;

  @override
  State<AquaButton> createState() => _AquaButtonState();
}

class _AquaButtonState extends State<AquaButton> {
  bool _pressed = false;

  bool get _enabled => widget.onPressed != null && !widget.loading;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final (background, foreground, border, base) = switch (widget.variant) {
      AquaButtonVariant.primary => (
        AppColors.deepWater,
        AppColors.white,
        AppColors.deepWater,
        const Color(0xFF0B4C57),
      ),
      AquaButtonVariant.secondary => (
        colors.surface,
        dark ? AppColors.waterLight : AppColors.deepWater,
        AppColors.waterLight,
        AppColors.waterLight,
      ),
      AquaButtonVariant.ghost => (
        Colors.transparent,
        dark ? AppColors.waterLight : AppColors.deepWater,
        Colors.transparent,
        Colors.transparent,
      ),
    };
    final baseDepth = widget.variant == AquaButtonVariant.ghost ? 0.0 : 5.0;
    final opacity = _enabled ? 1.0 : AppOpacity.disabled;

    final button = AnimatedOpacity(
      duration: AppMotion.press,
      opacity: opacity,
      child: AnimatedContainer(
        duration: AppMotion.press,
        curve: AppMotion.quickCurve,
        transform: Matrix4.translationValues(0, _pressed ? 4 : 0, 0),
        constraints: const BoxConstraints(
          minHeight: 52,
          minWidth: AppSpacing.minTouchTarget,
        ),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(AppRadii.md),
          border: Border.all(
            color: border,
            width: widget.variant == AquaButtonVariant.secondary ? 2 : 0,
          ),
          boxShadow: baseDepth == 0
              ? null
              : <BoxShadow>[
                  BoxShadow(
                    color: base,
                    offset: Offset(0, _pressed ? 1 : baseDepth),
                  ),
                ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            key: const Key('aqua_button_inkwell'),
            onTap: _enabled ? widget.onPressed : null,
            excludeFromSemantics: true,
            onHighlightChanged: (pressed) {
              if (_pressed != pressed) setState(() => _pressed = pressed);
            },
            borderRadius: BorderRadius.circular(AppRadii.md),
            overlayColor: WidgetStatePropertyAll(
              foreground.withValues(alpha: AppOpacity.pressedOverlay),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.sm,
              ),
              child: Center(
                widthFactor: widget.expand ? null : 1,
                child: AnimatedSwitcher(
                  duration: AppMotion.quick,
                  child: widget.loading
                      ? SizedBox.square(
                          key: const Key('aqua_button_loading'),
                          dimension: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: foreground,
                          ),
                        )
                      : Row(
                          key: const Key('aqua_button_label'),
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                            if (widget.leading != null) ...<Widget>[
                              IconTheme(
                                data: IconThemeData(color: foreground, size: 20),
                                child: widget.leading!,
                              ),
                              const SizedBox(width: AppSpacing.xs),
                            ],
                            Flexible(
                              child: Text(
                                widget.label,
                                textAlign: TextAlign.center,
                                style: Theme.of(context).textTheme.labelLarge
                                    ?.copyWith(color: foreground),
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    return Semantics(
      button: true,
      enabled: _enabled,
      label: widget.loading ? '${widget.label}, loading' : widget.label,
      child: ExcludeSemantics(
        child: widget.expand
            ? SizedBox(width: double.infinity, child: button)
            : button,
      ),
    );
  }
}

class StepProgressBar extends StatelessWidget {
  const StepProgressBar({
    super.key,
    required this.sectionLabel,
    required this.currentStep,
    required this.totalSteps,
  }) : assert(totalSteps > 0),
       assert(currentStep >= 0 && currentStep <= totalSteps);

  final String sectionLabel;
  final int currentStep;
  final int totalSteps;

  @override
  Widget build(BuildContext context) {
    final progress = currentStep / totalSteps;
    return Semantics(
      label: '$sectionLabel, step $currentStep of $totalSteps',
      value: '${(progress * 100).round()} percent',
      child: ExcludeSemantics(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    sectionLabel,
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                ),
                Text(
                  '$currentStep of $totalSteps',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            ClipRRect(
              borderRadius: BorderRadius.circular(AppRadii.pill),
              child: ColoredBox(
                color: AppColors.waterLight,
                child: SizedBox(
                  height: 10,
                  child: Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: AnimatedFractionallySizedBox(
                      duration: AppMotion.quick,
                      curve: AppMotion.quickCurve,
                      widthFactor: progress,
                      heightFactor: 1,
                      child: const ColoredBox(color: AppColors.deepWater),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class OnboardingPager extends StatelessWidget {
  const OnboardingPager({
    super.key,
    required this.page,
    required this.pageCount,
  }) : assert(pageCount > 0),
       assert(page >= 0 && page < pageCount);

  final int page;
  final int pageCount;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Page ${page + 1} of $pageCount',
      child: ExcludeSemantics(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: List<Widget>.generate(pageCount, (index) {
            final active = index == page;
            return AnimatedContainer(
              key: ValueKey<String>('pager-dot-$index'),
              duration: AppMotion.quick,
              curve: AppMotion.quickCurve,
              width: active ? 24 : 7,
              height: 7,
              margin: const EdgeInsets.symmetric(horizontal: 3),
              decoration: BoxDecoration(
                color: active ? AppColors.deepWater : AppColors.waterLight,
                borderRadius: BorderRadius.circular(AppRadii.pill),
                border: active
                    ? Border.all(color: AppColors.deepWater)
                    : Border.all(color: AppColors.outline),
              ),
            );
          }),
        ),
      ),
    );
  }
}

class AquaFilterChip extends StatelessWidget {
  const AquaFilterChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onSelected,
    this.leading,
  });

  final String label;
  final bool selected;
  final ValueChanged<bool>? onSelected;
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: onSelected,
      avatar: leading,
      showCheckmark: true,
      selectedColor: AppColors.deepWater,
      checkmarkColor: AppColors.white,
      labelStyle: Theme.of(context).textTheme.labelLarge?.copyWith(
        color: selected
            ? AppColors.white
            : Theme.of(context).colorScheme.onSurface,
      ),
      side: BorderSide(
        color: selected
            ? AppColors.deepWater
            : Theme.of(context).colorScheme.outline,
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      shape: const StadiumBorder(),
    );
  }
}

class PictureChoiceCard extends StatelessWidget {
  const PictureChoiceCard({
    super.key,
    required this.image,
    required this.label,
    required this.selected,
    required this.onSelected,
    this.enabled = true,
    this.multiSelect = false,
  });

  final Widget image;
  final String label;
  final bool selected;
  final ValueChanged<bool>? onSelected;
  final bool enabled;
  final bool multiSelect;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final effectiveEnabled = enabled && onSelected != null;
    return Semantics(
      button: true,
      enabled: effectiveEnabled,
      selected: selected,
      label: label,
      child: ExcludeSemantics(
        child: AnimatedOpacity(
          duration: AppMotion.quick,
          opacity: effectiveEnabled ? 1 : AppOpacity.disabled,
          child: AnimatedContainer(
            duration: AppMotion.quick,
            curve: AppMotion.quickCurve,
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(AppRadii.lg),
              border: Border.all(
                color: selected ? AppColors.deepWater : colors.outline,
                width: AppStrokes.selected,
              ),
              boxShadow: selected
                  ? const <BoxShadow>[
                      BoxShadow(color: AppColors.waterLight, spreadRadius: 4),
                    ]
                  : null,
            ),
            clipBehavior: Clip.antiAlias,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: effectiveEnabled ? () => onSelected!(!selected) : null,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    AspectRatio(
                      aspectRatio: 4 / 3,
                      child: ColoredBox(
                        color: AppColors.waterMist,
                        child: image,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(AppSpacing.sm),
                      child: Row(
                        children: <Widget>[
                          Expanded(
                            child: Text(
                              label,
                              style: Theme.of(context).textTheme.labelLarge,
                            ),
                          ),
                          AnimatedContainer(
                            duration: AppMotion.quick,
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              color: selected
                                  ? AppColors.deepWater
                                  : Colors.transparent,
                              border: Border.all(
                                color: selected
                                    ? AppColors.deepWater
                                    : colors.outline,
                                width: 2,
                              ),
                              borderRadius: BorderRadius.circular(
                                multiSelect ? AppRadii.sm : AppRadii.pill,
                              ),
                            ),
                            child: selected
                                ? const Icon(
                                    Icons.check_rounded,
                                    size: 18,
                                    color: AppColors.white,
                                  )
                                : null,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class NotSureButton extends StatelessWidget {
  const NotSureButton({super.key, required this.onPressed});
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => AquaButton(
    label: "I'm not sure",
    variant: AquaButtonVariant.ghost,
    onPressed: onPressed,
    leading: const Icon(Icons.help_outline_rounded),
  );
}

class RippleLoadingState extends StatelessWidget {
  const RippleLoadingState({super.key, required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      label: label,
      child: ExcludeSemantics(
        child: Row(
          children: <Widget>[
            const AquaMascot(mood: MascotMood.thinking, size: 84),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(label, style: Theme.of(context).textTheme.labelLarge),
                  const SizedBox(height: AppSpacing.sm),
                  const LinearProgressIndicator(
                    minHeight: 8,
                    color: AppColors.deepWater,
                    backgroundColor: AppColors.waterLight,
                    borderRadius: BorderRadius.all(
                      Radius.circular(AppRadii.pill),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class RippleCelebrationOverlay extends StatelessWidget {
  const RippleCelebrationOverlay({
    super.key,
    required this.title,
    required this.message,
    this.replayKey = 0,
  });

  final String title;
  final String message;
  final Object replayKey;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      label: '$title. $message',
      child: ExcludeSemantics(
        child: Material(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(AppRadii.xl),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                SizedBox(
                  height: 230,
                  child: Stack(
                    alignment: Alignment.center,
                    children: <Widget>[
                      Positioned.fill(
                        child: ReducedMotionLottie(
                          asset: 'assets/animations/celebration-burst.json',
                          semanticLabel: 'Celebration burst',
                          replayKey: replayKey,
                        ),
                      ),
                      const AquaMascot(
                        mood: MascotMood.celebrating,
                        size: 154,
                      ),
                    ],
                  ),
                ),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
