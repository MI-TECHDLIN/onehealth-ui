import 'package:just_audio/just_audio.dart';

/// Narrow seam between [ReadAloudService][1] and a real audio engine, mirroring
/// the `HapticDriver`/`SystemHapticDriver` split in `app_haptics.dart` so tests
/// can substitute a fake player instead of touching platform channels.
///
/// [1]: ../../core/audio/read_aloud_service.dart
abstract interface class NarrationAudioPlayer {
  /// Emits playback position while a track is loaded.
  Stream<Duration> get positionStream;

  /// Emits `true` exactly when the current track finishes on its own.
  Stream<bool> get completionStream;

  /// Loads the asset at [assetPath], replacing any previously loaded track.
  Future<void> load(String assetPath);

  Future<void> play();
  Future<void> pause();
  Future<void> seekToStart();
  Future<void> dispose();
}

class JustAudioNarrationPlayer implements NarrationAudioPlayer {
  JustAudioNarrationPlayer() : _player = AudioPlayer();

  final AudioPlayer _player;

  @override
  Stream<Duration> get positionStream => _player.positionStream;

  @override
  Stream<bool> get completionStream => _player.processingStateStream.map(
    (state) => state == ProcessingState.completed,
  );

  @override
  Future<void> load(String assetPath) async {
    await _player.setAsset(assetPath);
  }

  @override
  Future<void> play() => _player.play();

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> seekToStart() => _player.seek(Duration.zero);

  @override
  Future<void> dispose() => _player.dispose();
}
