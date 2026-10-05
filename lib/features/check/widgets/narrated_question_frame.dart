import 'package:flutter/material.dart';

import '../../../core/audio/assessment_narration_controller.dart';
import '../../../core/mascot/ripple_controller.dart';

/// Owns one [AssessmentNarrationController] for the lifetime of a single
/// question page: loads Piper narration (or prepares the device-voice
/// fallback text) once, and disposes it when the page is replaced.
class NarratedQuestionFrame extends StatefulWidget {
  const NarratedQuestionFrame({
    super.key,
    required this.narrationId,
    required this.fullText,
    required this.rippleController,
    required this.builder,
  });

  /// Matches the Piper asset filename under `assets/audio/assessment/<locale>/`.
  final String narrationId;

  /// Plain-text fallback spoken by the on-device TTS when no Piper track
  /// exists for the current locale.
  final String fullText;
  final RippleController rippleController;
  final Widget Function(BuildContext context, AssessmentNarrationController narration) builder;

  @override
  State<NarratedQuestionFrame> createState() => _NarratedQuestionFrameState();
}

class _NarratedQuestionFrameState extends State<NarratedQuestionFrame> {
  late final AssessmentNarrationController _controller = AssessmentNarrationController(
    rippleController: widget.rippleController,
  );
  bool _loaded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_loaded) return;
    _loaded = true;
    _load();
  }

  void _load() {
    _controller.load(
      narrationId: widget.narrationId,
      locale: Localizations.localeOf(context),
      fullText: widget.fullText,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _controller,
    builder: (context, _) => widget.builder(context, _controller),
  );
}
