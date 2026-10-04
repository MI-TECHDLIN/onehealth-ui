import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onehealth_ui/core/audio/narration_audio_player.dart';
import 'package:onehealth_ui/core/audio/read_aloud_service.dart';
import 'package:onehealth_ui/core/theme/tokens.dart';
import 'package:onehealth_ui/core/widgets/read_aloud_control.dart';
import 'package:onehealth_ui/l10n/generated/app_localizations.dart';

class _FakePlayer implements NarrationAudioPlayer {
  final StreamController<Duration> _position =
      StreamController<Duration>.broadcast();
  final StreamController<bool> _completion =
      StreamController<bool>.broadcast();

  void emitPosition(Duration position) => _position.add(position);

  @override
  Stream<Duration> get positionStream => _position.stream;

  @override
  Stream<bool> get completionStream => _completion.stream;

  @override
  Future<void> load(String assetPath) async {}

  @override
  Future<void> play() async {}

  @override
  Future<void> pause() async {}

  @override
  Future<void> seekToStart() async {}

  @override
  Future<void> dispose() async {
    await _position.close();
    await _completion.close();
  }
}

class _FakeBundle extends AssetBundle {
  _FakeBundle(this._strings);
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

String _sidecar() => jsonEncode(<String, dynamic>{
  'id': 'problem',
  'locale': 'en',
  'voice': 'en_GB-alba-medium',
  'sampleRate': 22050,
  'durationMs': 1000,
  'segments': <Map<String, Object>>[
    <String, Object>{'id': 'headline', 'words': 2},
    <String, Object>{'id': 'body', 'words': 2},
  ],
  'words': <String>['Hello', 'world.', 'Second', 'line.'],
  'timings': <Map<String, int>>[
    <String, int>{'start': 0, 'end': 200},
    <String, int>{'start': 200, 'end': 400},
    <String, int>{'start': 500, 'end': 700},
    <String, int>{'start': 700, 'end': 900},
  ],
});

Widget _app(Widget child) => MaterialApp(
  locale: const Locale('en'),
  supportedLocales: const <Locale>[Locale('en')],
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  home: Scaffold(body: Center(child: child)),
);

void main() {
  late _FakePlayer player;
  late ReadAloudService service;

  setUp(() async {
    player = _FakePlayer();
    service = ReadAloudService(
      player: player,
      bundle: _FakeBundle(<String, String>{
        'assets/audio/onboarding/en/problem.json': _sidecar(),
      }),
    );
    await service.load(narrationId: 'problem', locale: const Locale('en'));
  });

  tearDown(() {
    service.dispose();
  });

  testWidgets('control cycles through Listen, Pause narration and back', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(ReadAloudControl(service: service, enabled: true)),
    );

    expect(find.text('Listen'), findsOneWidget);

    await tester.tap(find.text('Listen'));
    await tester.pumpAndSettle();
    expect(find.text('Pause narration'), findsOneWidget);

    await tester.tap(find.text('Pause narration'));
    await tester.pumpAndSettle();
    expect(find.text('Listen'), findsOneWidget);
  });

  testWidgets('control hides entirely when the preference is off', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(ReadAloudControl(service: service, enabled: false)),
    );

    expect(find.byType(ReadAloudControl), findsOneWidget);
    expect(find.text('Listen'), findsNothing);
  });

  testWidgets('highlighted text fills and underlines only the spoken word', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        ReadAloudHighlightedText(
          text: 'Second line.',
          service: service,
          segmentId: 'body',
        ),
      ),
    );

    await service.play();
    player.emitPosition(const Duration(milliseconds: 600));
    await tester.pump();

    final richText = tester.widget<Text>(find.byType(Text));
    final root = richText.textSpan! as TextSpan;
    final secondSpan = root.children!.firstWhere(
      (span) => (span as TextSpan).text == 'Second',
    ) as TextSpan;
    final lineSpan = root.children!.firstWhere(
      (span) => (span as TextSpan).text == 'line.',
    ) as TextSpan;

    expect(secondSpan.style?.backgroundColor, AppColors.sparkle);
    expect(secondSpan.style?.decoration, TextDecoration.underline);
    expect(lineSpan.style?.backgroundColor, isNot(AppColors.sparkle));
  });
}
