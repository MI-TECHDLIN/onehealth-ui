import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../mascot/aqua_mascot.dart';
import '../theme/tokens.dart';

/// Reusable, consistent way to display a translated (already friendly, see
/// `lib/core/errors/friendly_error.dart`) error message. Use this instead of
/// letting each screen invent its own error-display pattern.
class FriendlyErrorBanner extends StatelessWidget {
  const FriendlyErrorBanner({
    super.key,
    required this.message,
    this.onRetry,
    this.mood,
    this.title,
    this.onDismiss,
  });

  /// The already-translated, plain-language message to show. Callers should
  /// produce this via `FriendlyError.fromFailure(...)`, never a raw
  /// exception message or status code.
  final String message;

  /// Optional retry action surfaced next to the message.
  final VoidCallback? onRetry;

  /// Optional mascot override. When omitted, concerned Ripple is shown.
  final Widget? mood;

  final String? title;
  final VoidCallback? onDismiss;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      color: colorScheme.errorContainer,
      borderRadius: BorderRadius.circular(AppRadii.md),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.sm),
        child: Row(
          children: [
            SizedBox(
              width: 62,
              child: mood ??
                  const AquaMascot(
                    mood: MascotMood.concerned,
                    size: 58,
                    pauseAnimations: true,
                  ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  if (title != null) ...<Widget>[
                    Text(
                      title!,
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: colorScheme.onErrorContainer,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                  ],
                  Text(
                    message,
                    style: TextStyle(color: colorScheme.onErrorContainer),
                  ),
                ],
              ),
            ),
            if (onRetry != null)
              TextButton(
                onPressed: onRetry,
                child: const Text('Retry'),
              ),
            if (onDismiss != null)
              IconButton(
                tooltip: 'Dismiss',
                onPressed: onDismiss,
                icon: const Icon(PhosphorIconsRegular.x),
              ),
          ],
        ),
      ),
    );
  }
}

/// Shows [message] as a [SnackBar] using the same consistent styling as
/// [FriendlyErrorBanner]. Prefer this for transient failures; use
/// [FriendlyErrorBanner] inline when the error should stay visible on
/// screen until dismissed or retried.
void showFriendlyErrorSnackBar(
  BuildContext context,
  String message, {
  VoidCallback? onRetry,
  // Integration point for a mood-aware mascot character; see
  // FriendlyErrorBanner.mood.
  Widget? mood,
}) {
  final colorScheme = Theme.of(context).colorScheme;

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      backgroundColor: colorScheme.errorContainer,
      content: Row(
        children: [
          SizedBox(
            width: 44,
            child: mood ??
                const AquaMascot(
                  mood: MascotMood.concerned,
                  size: 42,
                  pauseAnimations: true,
                ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: colorScheme.onErrorContainer),
            ),
          ),
        ],
      ),
      action: onRetry == null
          ? null
          : SnackBarAction(
              label: 'Retry',
              textColor: colorScheme.onErrorContainer,
              onPressed: onRetry,
            ),
    ),
  );
}
