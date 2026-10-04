import 'package:flutter_test/flutter_test.dart';
import 'package:onehealth_ui/core/audio/read_aloud_models.dart';

NarrationTrack _track() => NarrationTrack.fromJson(<String, dynamic>{
  'id': 'problem',
  'locale': 'en',
  'voice': 'en_GB-alba-medium',
  'sampleRate': 22050,
  'durationMs': 1000,
  'segments': <Map<String, Object>>[
    <String, Object>{'id': 'headline', 'words': 2},
    <String, Object>{'id': 'body', 'words': 3},
  ],
  'words': <String>['Hello', 'world.', 'This', 'is', 'narration.'],
  'timings': <Map<String, int>>[
    <String, int>{'start': 0, 'end': 200},
    <String, int>{'start': 200, 'end': 400},
    <String, int>{'start': 500, 'end': 650},
    <String, int>{'start': 650, 'end': 750},
    <String, int>{'start': 750, 'end': 1000},
  ],
}, audioAssetPath: 'assets/audio/onboarding/en/problem.ogg');

void main() {
  test('parses words, timings and segments from JSON', () {
    final track = _track();

    expect(track.id, 'problem');
    expect(track.words, <String>['Hello', 'world.', 'This', 'is', 'narration.']);
    expect(track.timings.length, 5);
    expect(track.duration, const Duration(milliseconds: 1000));
  });

  test('offsetFor resolves each named segment in order', () {
    final track = _track();

    expect(track.offsetFor('headline'), 0);
    expect(track.offsetFor('body'), 2);
    expect(track.offsetFor('missing'), 0);
  });

  test('wordIndexAt holds the most recent word through its trailing silence', () {
    final track = _track();

    expect(track.wordIndexAt(const Duration(milliseconds: -1)), isNull);
    expect(track.wordIndexAt(Duration.zero), 0);
    expect(track.wordIndexAt(const Duration(milliseconds: 150)), 0);
    expect(track.wordIndexAt(const Duration(milliseconds: 450)), 1);
    expect(track.wordIndexAt(const Duration(milliseconds: 999)), 4);
  });
}
