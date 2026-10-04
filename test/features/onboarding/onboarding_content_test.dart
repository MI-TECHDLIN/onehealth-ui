import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:onehealth_ui/features/onboarding/onboarding_content.dart';
import 'package:onehealth_ui/l10n/generated/app_localizations_en.dart';

/// These checks guard the one invariant `ReadAloudHighlightedText` depends
/// on: each displayed segment's word count must match the word count the
/// narration sidecar recorded for that same segment id, because
/// `NarrationTrack.offsetFor` locates a segment purely by summing the
/// *counts* that came before it. If onboarding copy changes without
/// regenerating narration (see scripts/narration/README.md), this is the
/// test that catches it.
void main() {
  final strings = AppLocalizationsEn();

  for (final page in OnboardingContent.pages) {
    test('${page.id}: segment word counts match its narration sidecar', () {
      final sidecarFile = File(
        'assets/audio/onboarding/en/${page.id}.json',
      );
      final sidecar =
          jsonDecode(sidecarFile.readAsStringSync()) as Map<String, dynamic>;
      final segments = (sidecar['segments'] as List)
          .cast<Map<String, dynamic>>();
      final wordCountById = <String, int>{
        for (final segment in segments)
          segment['id'] as String: segment['words'] as int,
      };

      expect(
        page.headline(strings).split(' ').length,
        wordCountById['headline'],
        reason: 'headline word count must match the generated sidecar',
      );
      expect(
        page.body(strings).split(' ').length,
        wordCountById['body'],
        reason: 'body word count must match the generated sidecar',
      );

      final safetyTitle = page.safetyTitle;
      final safetyPoints = page.safetyPoints;
      if (safetyTitle != null && safetyPoints != null) {
        final safetyWords = <String>[
          safetyTitle(strings),
          for (final point in safetyPoints) point(strings),
        ].join(' ').split(' ').length;
        expect(
          safetyWords,
          wordCountById['safety'],
          reason: 'safety word count must match the generated sidecar',
        );
      }
    });
  }

  test('the locked arc has exactly five screens in the approved order', () {
    expect(OnboardingContent.pages.map((p) => p.id), <String>[
      'problem',
      'oneHealth',
      'fieldCheck',
      'dataJourney',
      'getStarted',
    ]);
  });
}
