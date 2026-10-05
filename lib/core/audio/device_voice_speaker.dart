import 'package:flutter_tts/flutter_tts.dart';

/// Narrow seam between the device-voice fallback and `flutter_tts`, mirroring
/// `NarrationAudioPlayer`'s split from `just_audio` so tests can substitute a
/// fake speaker instead of touching platform channels.
abstract interface class DeviceVoiceSpeaker {
  Future<void> speak(String text, {required String languageCode});
  Future<void> stop();
  Future<void> dispose();
}

class FlutterTtsDeviceVoiceSpeaker implements DeviceVoiceSpeaker {
  FlutterTtsDeviceVoiceSpeaker() : _tts = FlutterTts() {
    _tts.awaitSpeakCompletion(true);
  }

  final FlutterTts _tts;
  String? _language;

  @override
  Future<void> speak(String text, {required String languageCode}) async {
    if (text.trim().isEmpty) return;
    if (_language != languageCode) {
      try {
        await _tts.setLanguage(languageCode);
        _language = languageCode;
      } catch (_) {
        // Falls through to the device's default voice when this language
        // has no installed TTS data -- still better than no narration.
      }
    }
    await _tts.speak(text);
  }

  @override
  Future<void> stop() => _tts.stop();

  @override
  Future<void> dispose() => _tts.stop();
}
