import 'package:flutter/material.dart';

import '../theme/tokens.dart';

/// A calm, non-alarming list of field safety reminders.
///
/// Introduced for onboarding's data-journey screen (the moment the app asks
/// a citizen to actually go stand at a stream) and built as a standalone
/// component so the first assessment step can show the same reminders again
/// before a real field visit, per the captain's request.
class FieldSafetyNotice extends StatelessWidget {
  const FieldSafetyNotice({
    super.key,
    required this.title,
    required this.points,
  });

  final String title;
  final List<String> points;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Semantics(
      container: true,
      label: title,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.sageLight,
          borderRadius: BorderRadius.circular(AppRadii.lg),
          border: Border.all(color: AppColors.sage),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Row(
              children: <Widget>[
                const Icon(
                  Icons.health_and_safety_outlined,
                  color: AppColors.deepWater,
                ),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Text(title, style: textTheme.labelLarge),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            for (final point in points)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const Padding(
                      padding: EdgeInsets.only(top: 7),
                      child: Icon(
                        Icons.circle,
                        size: 6,
                        color: AppColors.deepWater,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Expanded(child: Text(point, style: textTheme.bodyMedium)),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
