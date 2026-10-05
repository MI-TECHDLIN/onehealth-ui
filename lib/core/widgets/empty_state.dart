import 'package:flutter/material.dart';

import '../mascot/aqua_mascot.dart';
import '../theme/tokens.dart';

/// A guiding Ripple, a plain reason, and at most one action -- "no dead
/// end" per the component inventory. Shared so every empty state in the app
/// (My Streams, map filters, a stream with no history yet, ...) reads the
/// same way instead of each screen hand-rolling its own.
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.title,
    required this.body,
    this.actionLabel,
    this.onAction,
    this.mood = MascotMood.guiding,
  });

  final String title;
  final String body;
  final String? actionLabel;
  final VoidCallback? onAction;
  final MascotMood mood;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.page),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            AquaMascot(mood: mood, size: 112),
            const SizedBox(height: AppSpacing.md),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              body,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            if (actionLabel != null) ...<Widget>[
              const SizedBox(height: AppSpacing.md),
              TextButton(onPressed: onAction, child: Text(actionLabel!)),
            ],
          ],
        ),
      ),
    );
  }
}
