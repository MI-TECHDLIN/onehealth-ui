import 'dart:async';
import 'dart:convert';
import 'dart:ui';

import 'package:audio_session/audio_session.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../mascot/ripple_controller.dart';
import 'narration_audio_player.dart';
import 'read_aloud_models.dart';

enum ReadAloudPlaybackState { idle, playing, paused, completed }

/// Plays pre-generated natural-voice narration for one screen at a time and
/// exposes the state a read-aloud control and word highlighter need.
///
/// This is deliberately screen-agnostic: onboarding owns one instance for its
/// five pages today, and the assessment flow can own another for its
/// questions later, per the design report's read-aloud build task. Narration
/// never autoplays -- [play] only ever runs in response to a user tap.
class ReadAloudService extends ChangeNotifier {
  ReadAloudService({NarrationAudioPlayer? player, RippleController? rippleController, AssetBundle? bundle})
    : _player = player ?? JustAudioNarrationPlayer(),
      _rippleController = rippleController,
      _bundle = bundle ?? rootBundle;

  final NarrationAudioPlayer _player;
  final RippleController? _rippleController;
  final AssetBundle _bundle;

  NarrationTrack? _track;
  ReadAloudPlaybackState _state = ReadAloudPlaybackState.idle;
  Duration _position = Duration.zero;
  int? _wordIndex;
  bool _sessionConfigured = false;

  StreamSubscription<Duration>? _positionSubscription;
  StreamSubscription<bool>? _completionSubscription;

  NarrationTrack? get track => _track;
  ReadAloudPlaybackState get state => _state;
  Duration get position => _position;
  int? get wordIndex => _wordIndex;
  bool get isAvailable => _track != null;

  /// Loads the narration for [narrationId] under [assetBasePath]/[locale].
  ///
  /// Returns `false` (and clears [track]) when no narration asset exists for
  /// that locale -- callers hide the read-aloud control in that case rather
  /// than offering a control that plays nothing, or English audio under
  /// mismatched on-screen text.
  Future<bool> load({
    required String narrationId,
    required Locale locale,
    String assetBasePath = 'assets/audio/onboarding',
  }) async {
    await _ensureAudioSession();
    final base = '$assetBasePath/${locale.languageCode}/$narrationId';
    try {
      final raw = await _bundle.loadString('$base.json');
      final json = jsonDecode(raw) as Map<String, dynamic>;
      final audioPath = '$base.ogg';
      final track = NarrationTrack.fromJson(json, audioAssetPath: audioPath);
      await _player.load(audioPath);
      _track = track;
      _state = ReadAloudPlaybackState.idle;
      _position = Duration.zero;
      _wordIndex = null;
      _subscribeToPlayer();
      notifyListeners();
      return true;
    } catch (_) {
      _track = null;
      _state = ReadAloudPlaybackState.idle;
      notifyListeners();
      return false;
    }
  }

  Future<void> _ensureAudioSession() async {
    if (_sessionConfigured) return;
    _sessionConfigured = true;
    try {
      final session = await AudioSession.instance;
      await session.configure(const AudioSessionConfiguration.speech());
      session.interruptionEventStream.listen((event) {
        if (event.begin) pause();
      });
      session.becomingNoisyEventStream.listen((_) => pause());
    } catch (_) {
      // Audio-focus integration is best-effort: narration still plays
      // without it on platforms/tests that cannot host a real session.
    }
  }

  void _subscribeToPlayer() {
    unawaited(_positionSubscription?.cancel());
    unawaited(_completionSubscription?.cancel());
    _positionSubscription = _player.positionStream.listen(_handlePosition);
    _completionSubscription = _player.completionStream.listen((completed) {
      if (completed) _handleCompletion();
    });
  }

  void _handlePosition(Duration position) {
    _position = position;
    final track = _track;
    if (track != null) {
      final nextIndex = track.wordIndexAt(position);
      if (nextIndex != _wordIndex) {
        _wordIndex = nextIndex;
        _driveViseme(track, nextIndex, position);
      }
    }
    notifyListeners();
  }

  /// Steps Ripple's talk viseme on each word boundary. The sidecar only
  /// carries word-level timing (per the build brief), so this cycles a
  /// three-shape viseme sequence per word rather than attempting
  /// phoneme-accurate shapes -- `RippleVisemeSmoother`'s 160 ms low-pass
  /// (see `ripple_controller.dart`) is what keeps that from reading as
  /// chattery, exactly as the design report's talk-gesture spec describes.
  void _driveViseme(NarrationTrack track, int? index, Duration position) {
    final controller = _rippleController;
    if (controller == null) return;
    if (index == null) {
      controller.setViseme(RippleViseme.rest);
      return;
    }
    final timing = track.timings[index];
    if (position > timing.end) {
      controller.setViseme(RippleViseme.rest);
      return;
    }
    const cycle = <RippleViseme>[
      RippleViseme.open,
      RippleViseme.wide,
      RippleViseme.round,
    ];
    controller.setViseme(cycle[index % cycle.length]);
  }

  void _handleCompletion() {
    _state = ReadAloudPlaybackState.completed;
    _wordIndex = null;
    _rippleController?.setViseme(RippleViseme.rest);
    _rippleController?.stopGesture();
    notifyListeners();
  }

  Future<void> play() async {
    if (_track == null) return;
    if (_state == ReadAloudPlaybackState.completed) {
      await _player.seekToStart();
      _position = Duration.zero;
      _wordIndex = null;
    }
    _state = ReadAloudPlaybackState.playing;
    notifyListeners();
    await _player.play();
  }

  Future<void> pause() async {
    if (_state != ReadAloudPlaybackState.playing) return;
    _state = ReadAloudPlaybackState.paused;
    notifyListeners();
    await _player.pause();
    _rippleController?.setViseme(RippleViseme.rest);
  }

  Future<void> replay() async {
    await _player.seekToStart();
    _position = Duration.zero;
    _wordIndex = null;
    await play();
  }

  /// Stops and rewinds without starting playback, for leaving a screen.
  Future<void> stop() async {
    await _player.pause();
    await _player.seekToStart();
    _state = ReadAloudPlaybackState.idle;
    _position = Duration.zero;
    _wordIndex = null;
    _rippleController?.setViseme(RippleViseme.rest);
    _rippleController?.stopGesture();
    notifyListeners();
  }

  @override
  void dispose() {
    unawaited(_positionSubscription?.cancel());
    unawaited(_completionSubscription?.cancel());
    unawaited(_player.dispose());
    super.dispose();
  }
}
