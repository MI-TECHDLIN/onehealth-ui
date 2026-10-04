import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../l10n/generated/app_localizations.dart';
import '../audio/read_aloud_service.dart';
import '../icons/water_icons.dart';
import '../theme/tokens.dart';
import 'aqua_components.dart';

/// The Listen / Pause narration / Replay control required on every narrated
/// screen. Hidden entirely when [enabled] is false (the user's remembered
/// narration preference) or when [service] has no track for the current
/// locale -- narration never autoplays, so there is always an explicit tap
/// between showing this control and any sound playing.
class ReadAloudControl extends StatelessWidget {
  const ReadAloudControl({super.key, required this.service, required this.enabled});

  final ReadAloudService service;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    if (!enabled) return const SizedBox.shrink();
    return AnimatedBuilder(
      animation: service,
      builder: (context, _) {
        if (!service.isAvailable) return const SizedBox.shrink();
        final strings = AppLocalizations.of(context);
        final (Widget leading, String label, Future<void> Function() onTap) =
            switch (service.state) {
              ReadAloudPlaybackState.playing => (
                const Icon(PhosphorIconsFill.pauseCircle),
                strings.onboardingReadAloudPause,
                service.pause,
              ),
              ReadAloudPlaybackState.completed => (
                const Icon(PhosphorIconsFill.arrowCounterClockwise),
                strings.onboardingReadAloudReplay,
                service.replay,
              ),
              ReadAloudPlaybackState.idle || ReadAloudPlaybackState.paused => (
                const WaterIconWidget(WaterIcon.narrationWave),
                strings.onboardingReadAloudListen,
                service.play,
              ),
            };
        return Semantics(
          liveRegion: service.state == ReadAloudPlaybackState.playing,
          child: AquaButton(
            variant: AquaButtonVariant.secondary,
            expand: false,
            leading: leading,
            label: label,
            onPressed: () => onTap(),
          ),
        );
      },
    );
  }
}

/// Renders [text] with a word-by-word background-fill + underline highlight
/// while [service] speaks the matching slice of its loaded track.
///
/// Highlighting is never color-only (per the design report's accessibility
/// contract): the active word gets both a fill and an underline, so it stays
/// legible for color-blind users and under Reduce Motion, which this widget
/// never needs to check -- it reacts to narration position, not animation.
class ReadAloudHighlightedText extends StatelessWidget {
  const ReadAloudHighlightedText({
    super.key,
    required this.text,
    required this.service,
    required this.segmentId,
    this.style,
    this.highlightStyle,
    this.textAlign,
  });

  final String text;
  final ReadAloudService service;

  /// The matching `segments[].id` in the loaded [NarrationTrack], e.g.
  /// `'headline'`, `'body'`, or `'safety'`.
  final String segmentId;
  final TextStyle? style;
  final TextStyle? highlightStyle;
  final TextAlign? textAlign;

  @override
  Widget build(BuildContext context) {
    final words = text.split(' ');
    return AnimatedBuilder(
      animation: service,
      builder: (context, _) {
        final baseStyle = style ?? DefaultTextStyle.of(context).style;
        final activeStyle =
            highlightStyle ??
            baseStyle.copyWith(
              backgroundColor: AppColors.sparkle,
              decoration: TextDecoration.underline,
              decorationColor: AppColors.deepWater,
              decorationThickness: 2,
            );
        final activeGlobalIndex = service.state == ReadAloudPlaybackState.playing
            ? service.wordIndex
            : null;
        final offset = service.track?.offsetFor(segmentId) ?? 0;
        final activeLocalIndex = activeGlobalIndex == null
            ? -1
            : activeGlobalIndex - offset;
        return Text.rich(
          TextSpan(
            children: <InlineSpan>[
              for (var i = 0; i < words.length; i++) ...<InlineSpan>[
                TextSpan(
                  text: words[i],
                  style: i == activeLocalIndex ? activeStyle : baseStyle,
                ),
                if (i != words.length - 1) const TextSpan(text: ' '),
              ],
            ],
          ),
          textAlign: textAlign,
        );
      },
    );
  }
}
