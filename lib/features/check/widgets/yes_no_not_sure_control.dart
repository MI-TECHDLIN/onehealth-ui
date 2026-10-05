import 'package:flutter/material.dart';

import '../../../core/theme/tokens.dart';
import '../../../core/widgets/aqua_components.dart';
import '../../../l10n/generated/app_localizations.dart';

/// The shared Yes / No / "I'm not sure" chip trio for every
/// `AssessmentFieldType.yesNoNotSure` question.
class YesNoNotSureControl extends StatelessWidget {
  const YesNoNotSureControl({
    super.key,
    required this.value,
    required this.isNotSure,
    required this.onChanged,
  });

  final bool? value;
  final bool isNotSure;

  /// `value` is `null` exactly when `notSure` is true.
  final void Function(bool? value, bool notSure) onChanged;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: <Widget>[
        AquaFilterChip(
          label: strings.assessYesAction,
          selected: !isNotSure && value == true,
          onSelected: (_) => onChanged(true, false),
        ),
        AquaFilterChip(
          label: strings.assessNoAction,
          selected: !isNotSure && value == false,
          onSelected: (_) => onChanged(false, false),
        ),
        AquaFilterChip(
          label: strings.assessNotSureLabel,
          selected: isNotSure,
          onSelected: (_) => onChanged(null, true),
        ),
      ],
    );
  }
}
