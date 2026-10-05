import 'package:flutter/widgets.dart';

import '../mascot/ripple_controller.dart';
import 'device_voice_speaker.dart';
import 'read_aloud_service.dart';

enum DeviceVoiceState { idle, speaking }

/// Picks between pre-generated Piper narration and the on-device TTS
/// fallback for one assessment question/glossary term, per the round-4
/// build brief: Piper's natural voice where it has been generated (English
/// today), a "device voice" fallback everywhere else.
///
/// Call [load] with the full reading-order text, then check
/// [isPiperAvailable] to decide whether to drive [readAloud] (with
/// word-highlighting) or [speakDeviceVoice] (plain, no highlighting).
class AssessmentNarrationController extends ChangeNotifier {
  AssessmentNarrationController({
    RippleController? rippleController,
    DeviceVoiceSpeaker? deviceVoiceSpeaker,
  }) : readAloud = ReadAloudService(rippleController: rippleController),
       _deviceVoice = deviceVoiceSpeaker ?? FlutterTtsDeviceVoiceSpeaker();

  final ReadAloudService readAloud;
  final DeviceVoiceSpeaker _deviceVoice;

  bool _piperAvailable = false;
  DeviceVoiceState _deviceVoiceState = DeviceVoiceState.idle;
  String _fullText = '';
  String _languageCode = 'en';

  bool get isPiperAvailable => _piperAvailable;
  DeviceVoiceState get deviceVoiceState => _deviceVoiceState;

  Future<void> load({
    required String narrationId,
    required Locale locale,
    required String fullText,
    String assetBasePath = 'assets/audio/assessment',
  }) async {
    _fullText = fullText;
    _languageCode = locale.languageCode;
    _piperAvailable = await readAloud.load(
      narrationId: narrationId,
      locale: locale,
      assetBasePath: assetBasePath,
    );
    _deviceVoiceState = DeviceVoiceState.idle;
    notifyListeners();
  }

  Future<void> speakDeviceVoice() async {
    _deviceVoiceState = DeviceVoiceState.speaking;
    notifyListeners();
    try {
      await _deviceVoice.speak(_fullText, languageCode: _languageCode);
    } finally {
      _deviceVoiceState = DeviceVoiceState.idle;
      notifyListeners();
    }
  }

  Future<void> stopDeviceVoice() async {
    await _deviceVoice.stop();
    _deviceVoiceState = DeviceVoiceState.idle;
    notifyListeners();
  }

  Future<void> stopAll() async {
    await readAloud.stop();
    await stopDeviceVoice();
  }

  @override
  void dispose() {
    readAloud.dispose();
    _deviceVoice.dispose();
    super.dispose();
  }
}
