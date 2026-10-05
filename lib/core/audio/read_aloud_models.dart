import 'package:flutter/foundation.dart';

/// Start/end offsets of one spoken word within a [NarrationTrack].
@immutable
class WordTiming {
  const WordTiming({required this.start, required this.end});

  final Duration start;
  final Duration end;

  @override
  bool operator ==(Object other) =>
      other is WordTiming && other.start == start && other.end == end;

  @override
  int get hashCode => Object.hash(start, end);
}

/// One named slice of a [NarrationTrack]'s word list -- a headline, a body
/// paragraph, a safety reminder, or (later) an assessment question/option.
@immutable
class NarrationSegmentSpan {
  const NarrationSegmentSpan({required this.id, required this.wordCount});

  final String id;
  final int wordCount;
}

/// A narrated screen: its audio asset plus the word-timing sidecar that
/// drives on-screen highlighting and Ripple's talk viseme.
///
/// [words]/[timings] cover the full narration in reading order. [segments]
/// names each displayed slice in that same order (for example `headline`,
/// `body`, `safety`) so a caller rendering each slice in its own widget can
/// resolve its word-index offset via [offsetFor] instead of keeping a
/// separate tree of timing data per widget.
@immutable
class NarrationTrack {
  const NarrationTrack({
    required this.id,
    required this.locale,
    required this.voice,
    required this.audioAssetPath,
    required this.words,
    required this.timings,
    required this.segments,
    required this.duration,
  }) : assert(words.length == timings.length);

  final String id;
  final String locale;
  final String voice;
  final String audioAssetPath;
  final List<String> words;
  final List<WordTiming> timings;
  final List<NarrationSegmentSpan> segments;
  final Duration duration;

  factory NarrationTrack.fromJson(
    Map<String, dynamic> json, {
    required String audioAssetPath,
  }) {
    final words = List<String>.from(json['words'] as List);
    final timings = (json['timings'] as List)
        .map(
          (entry) => WordTiming(
            start: Duration(
              milliseconds: ((entry as Map)['start'] as num).round(),
            ),
            end: Duration(milliseconds: (entry['end'] as num).round()),
          ),
        )
        .toList(growable: false);
    final segments = (json['segments'] as List)
        .map(
          (entry) => NarrationSegmentSpan(
            id: (entry as Map)['id'] as String,
            wordCount: entry['words'] as int,
          ),
        )
        .toList(growable: false);
    return NarrationTrack(
      id: json['id'] as String,
      locale: json['locale'] as String,
      voice: json['voice'] as String,
      audioAssetPath: audioAssetPath,
      words: words,
      timings: timings,
      segments: segments,
      duration: Duration(milliseconds: (json['durationMs'] as num).round()),
    );
  }

  /// The word-index offset where segment [id] begins, or `0` if absent.
  int offsetFor(String id) {
    var offset = 0;
    for (final segment in segments) {
      if (segment.id == id) return offset;
      offset += segment.wordCount;
    }
    return 0;
  }

  /// The most recently started word at [position], or `null` before speech
  /// begins. A word stays "current" through the silence that follows it so
  /// highlighting does not flicker off between words.
  int? wordIndexAt(Duration position) {
    if (timings.isEmpty || position < timings.first.start) return null;
    for (var i = timings.length - 1; i >= 0; i--) {
      if (position >= timings[i].start) return i;
    }
    return null;
  }
}
