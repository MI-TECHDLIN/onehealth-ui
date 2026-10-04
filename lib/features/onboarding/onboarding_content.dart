import 'package:flutter/foundation.dart';

import '../../core/mascot/ripple_controller.dart';
import '../../l10n/generated/app_localizations.dart';

/// One of the five onboarding story beats.
///
/// [id] names the matching narration asset under
/// `assets/audio/onboarding/<locale>/<id>.{ogg,json}` -- see
/// `scripts/narration/README.md` for how those are generated. [gesture] is
/// the one-shot Ripple action this screen plays once when it becomes active.
@immutable
class OnboardingPageData {
  const OnboardingPageData({
    required this.id,
    required this.gesture,
    required this.headline,
    required this.body,
    this.safetyTitle,
    this.safetyPoints,
  });

  final String id;
  final RippleGesture gesture;
  final String Function(AppLocalizations strings) headline;
  final String Function(AppLocalizations strings) body;

  /// A calm field-safety reminder shown (and narrated) alongside this
  /// screen's body text, rendered with `FieldSafetyNotice`. Null for screens
  /// that don't carry one.
  final String Function(AppLocalizations strings)? safetyTitle;
  final List<String Function(AppLocalizations strings)>? safetyPoints;
}

/// The locked five-screen arc from the approved Ripple Field Guide design
/// board: problem -> One Health -> field check -> researcher impact ->
/// start/explore. Copy is grounded in OneAquaHealth's published mission
/// (urban freshwater ecosystems, One Health, citizen data reaching
/// researchers, early-warning monitoring) -- see the PR description for the
/// source links.
abstract final class OnboardingContent {
  static const List<OnboardingPageData> pages = <OnboardingPageData>[
    OnboardingPageData(
      id: 'problem',
      gesture: RippleGesture.swimIn,
      headline: _problemHeadline,
      body: _problemBody,
    ),
    OnboardingPageData(
      id: 'oneHealth',
      gesture: RippleGesture.wave,
      headline: _oneHealthHeadline,
      body: _oneHealthBody,
    ),
    OnboardingPageData(
      id: 'fieldCheck',
      gesture: RippleGesture.point,
      headline: _fieldCheckHeadline,
      body: _fieldCheckBody,
    ),
    OnboardingPageData(
      id: 'dataJourney',
      gesture: RippleGesture.nod,
      headline: _dataJourneyHeadline,
      body: _dataJourneyBody,
      safetyTitle: _safetyTitle,
      safetyPoints: <String Function(AppLocalizations strings)>[
        _safetyPoint1,
        _safetyPoint2,
        _safetyPoint3,
        _safetyPoint4,
      ],
    ),
    OnboardingPageData(
      id: 'getStarted',
      gesture: RippleGesture.jump,
      headline: _startHeadline,
      body: _startBody,
    ),
  ];
}

String _problemHeadline(AppLocalizations s) => s.onboardingProblemHeadline;
String _problemBody(AppLocalizations s) => s.onboardingProblemBody;
String _oneHealthHeadline(AppLocalizations s) => s.onboardingOneHealthHeadline;
String _oneHealthBody(AppLocalizations s) => s.onboardingOneHealthBody;
String _fieldCheckHeadline(AppLocalizations s) => s.onboardingFieldCheckHeadline;
String _fieldCheckBody(AppLocalizations s) => s.onboardingFieldCheckBody;
String _dataJourneyHeadline(AppLocalizations s) => s.onboardingDataJourneyHeadline;
String _dataJourneyBody(AppLocalizations s) => s.onboardingDataJourneyBody;
String _startHeadline(AppLocalizations s) => s.onboardingStartHeadline;
String _startBody(AppLocalizations s) => s.onboardingStartBody;
String _safetyTitle(AppLocalizations s) => s.onboardingSafetyTitle;
String _safetyPoint1(AppLocalizations s) => s.onboardingSafetyPoint1;
String _safetyPoint2(AppLocalizations s) => s.onboardingSafetyPoint2;
String _safetyPoint3(AppLocalizations s) => s.onboardingSafetyPoint3;
String _safetyPoint4(AppLocalizations s) => s.onboardingSafetyPoint4;
