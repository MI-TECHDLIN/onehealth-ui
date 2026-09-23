import 'package:flutter/material.dart';

/// Reusable, consistent way to display a translated (already friendly, see
/// `lib/core/errors/friendly_error.dart`) error message. Use this instead of
/// letting each screen invent its own error-display pattern.
class FriendlyErrorBanner extends StatelessWidget {
  const FriendlyErrorBanner({
    super.key,
    required this.message,
    this.onRetry,
    this.mood,
  });

  /// The already-translated, plain-language message to show. Callers should
  /// produce this via `FriendlyError.fromFailure(...)`, never a raw
  /// exception message or status code.
  final String message;

  /// Optional retry action surfaced next to the message.
  final VoidCallback? onRetry;

  /// Integration point for a mood-aware mascot character (built by a
  /// parallel task). Pass a widget here — e.g. a "concerned" mascot — to
  /// have it rendered alongside the message. Left null today; this banner
  /// works standalone without it.
  final Widget? mood;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      color: colorScheme.errorContainer,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            if (mood != null) ...[mood!, const SizedBox(width: 12)],
            Expanded(
              child: Text(
                message,
                style: TextStyle(color: colorScheme.onErrorContainer),
              ),
            ),
            if (onRetry != null)
              TextButton(
                onPressed: onRetry,
                child: const Text('Retry'),
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
          if (mood != null) ...[mood, const SizedBox(width: 12)],
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
