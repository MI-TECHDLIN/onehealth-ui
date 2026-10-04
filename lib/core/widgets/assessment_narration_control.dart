import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../l10n/generated/app_localizations.dart';
import '../audio/assessment_narration_controller.dart';
import '../icons/water_icons.dart';
import 'aqua_components.dart';
import 'read_aloud_control.dart';

/// The Listen control for one assessment question/glossary term: the
/// natural-voice Piper control when narration exists for the current
/// locale, otherwise a small "device voice" fallback button driving
/// `flutter_tts` -- per the round-4 build brief's narration-extension spec.
class AssessmentNarrationControl extends StatelessWidget {
  const AssessmentNarrationControl({
    super.key,
    required this.controller,
    required this.enabled,
  });

  final AssessmentNarrationController controller;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    if (!enabled) return const SizedBox.shrink();
    if (controller.isPiperAvailable) {
      return ReadAloudControl(service: controller.readAloud, enabled: enabled);
    }
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final strings = AppLocalizations.of(context);
        final speaking = controller.deviceVoiceState == DeviceVoiceState.speaking;
        return Semantics(
          liveRegion: speaking,
          child: AquaButton(
            variant: AquaButtonVariant.secondary,
            expand: false,
            leading: speaking
                ? const Icon(PhosphorIconsFill.pauseCircle)
                : const WaterIconWidget(WaterIcon.narrationWave),
            label: speaking
                ? strings.onboardingReadAloudPause
                : '${strings.onboardingReadAloudListen} (${strings.assessDeviceVoiceLabel})',
            onPressed: speaking
                ? () => controller.stopDeviceVoice()
                : () => controller.speakDeviceVoice(),
          ),
        );
      },
    );
  }
}
