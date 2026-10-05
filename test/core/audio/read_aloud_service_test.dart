import 'dart:async';
import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onehealth_ui/core/audio/narration_audio_player.dart';
import 'package:onehealth_ui/core/audio/read_aloud_service.dart';
import 'package:onehealth_ui/core/mascot/ripple_controller.dart';

class _FakeNarrationAudioPlayer implements NarrationAudioPlayer {
  final StreamController<Duration> _position =
      StreamController<Duration>.broadcast();
  final StreamController<bool> _completion =
      StreamController<bool>.broadcast();
  final List<String> loadedAssets = <String>[];
  int playCalls = 0;
  int pauseCalls = 0;
  int seekToStartCalls = 0;

  void emitPosition(Duration position) => _position.add(position);
  void emitCompletion() => _completion.add(true);

  @override
  Stream<Duration> get positionStream => _position.stream;

  @override
  Stream<bool> get completionStream => _completion.stream;

  @override
  Future<void> load(String assetPath) async {
    loadedAssets.add(assetPath);
  }

  @override
  Future<void> play() async => playCalls++;

  @override
  Future<void> pause() async => pauseCalls++;

  @override
  Future<void> seekToStart() async => seekToStartCalls++;

  @override
  Future<void> dispose() async {
    await _position.close();
    await _completion.close();
  }
}

class _FakeAssetBundle extends AssetBundle {
  _FakeAssetBundle(this._strings);
  final Map<String, String> _strings;

  @override
  Future<ByteData> load(String key) async => throw UnimplementedError();

  @override
  Future<String> loadString(String key, {bool cache = true}) async {
    final value = _strings[key];
    if (value == null) throw FlutterError('Asset not found: $key');
    return value;
  }
}

String _sidecarJson({String id = 'problem'}) => jsonEncode(<String, dynamic>{
  'id': id,
  'locale': 'en',
  'voice': 'en_GB-alba-medium',
  'sampleRate': 22050,
  'durationMs': 1000,
  'segments': <Map<String, Object>>[
    <String, Object>{'id': 'headline', 'words': 2},
    <String, Object>{'id': 'body', 'words': 1},
  ],
  'words': <String>['Hello', 'world.', 'Narration.'],
  'timings': <Map<String, int>>[
    <String, int>{'start': 0, 'end': 300},
    <String, int>{'start': 300, 'end': 600},
    <String, int>{'start': 700, 'end': 1000},
  ],
});

void main() {
  late _FakeNarrationAudioPlayer player;
  late RippleController ripple;
  late ReadAloudService service;

  setUp(() {
    player = _FakeNarrationAudioPlayer();
    ripple = RippleController();
    service = ReadAloudService(
      player: player,
      rippleController: ripple,
      bundle: _FakeAssetBundle(<String, String>{
        'assets/audio/onboarding/en/problem.json': _sidecarJson(),
      }),
    );
  });

  tearDown(() {
    service.dispose();
    ripple.dispose();
  });

  test('load resolves the matching track and loads its audio asset', () async {
    final loaded = await service.load(
      narrationId: 'problem',
      locale: const Locale('en'),
    );

    expect(loaded, isTrue);
    expect(service.isAvailable, isTrue);
    expect(service.state, ReadAloudPlaybackState.idle);
    expect(player.loadedAssets, <String>['assets/audio/onboarding/en/problem.ogg']);
  });

  test('load returns false and stays unavailable for a missing locale', () async {
    final loaded = await service.load(
      narrationId: 'problem',
      locale: const Locale('ar'),
    );

    expect(loaded, isFalse);
    expect(service.isAvailable, isFalse);
  });

  test('play starts playback and pause stops it without losing position', () async {
    await service.load(narrationId: 'problem', locale: const Locale('en'));

    await service.play();
    expect(service.state, ReadAloudPlaybackState.playing);
    expect(player.playCalls, 1);

    await service.pause();
    expect(service.state, ReadAloudPlaybackState.paused);
    expect(player.pauseCalls, 1);
    expect(ripple.viseme, RippleViseme.rest);
  });

  test('position updates drive the current word index and Ripple visemes', () async {
    await service.load(narrationId: 'problem', locale: const Locale('en'));
    await service.play();

    player.emitPosition(const Duration(milliseconds: 100));
    expect(service.wordIndex, 0);
    expect(ripple.gesture, RippleGesture.talk);

    player.emitPosition(const Duration(milliseconds: 750));
    expect(service.wordIndex, 2);

    player.emitPosition(const Duration(milliseconds: 310));
    expect(service.wordIndex, 1);
  });

  test('natural completion resets viseme/gesture and flips to completed', () async {
    await service.load(narrationId: 'problem', locale: const Locale('en'));
    await service.play();
    player.emitPosition(const Duration(milliseconds: 100));

    player.emitCompletion();
    expect(service.state, ReadAloudPlaybackState.completed);
    expect(service.wordIndex, isNull);
    expect(ripple.viseme, RippleViseme.rest);
    expect(ripple.gesture, RippleGesture.none);
  });

  test('replay seeks to the start and resumes playback', () async {
    await service.load(narrationId: 'problem', locale: const Locale('en'));
    await service.play();
    player.emitCompletion();

    await service.replay();
    expect(player.seekToStartCalls, 1);
    expect(service.state, ReadAloudPlaybackState.playing);
  });

  test('stop rewinds and returns to idle without playing', () async {
    await service.load(narrationId: 'problem', locale: const Locale('en'));
    await service.play();

    await service.stop();
    expect(service.state, ReadAloudPlaybackState.idle);
    expect(player.seekToStartCalls, 1);
    expect(service.wordIndex, isNull);
  });
}
