import '../../l10n/generated/app_localizations.dart';
import '../widgets/badge_crest.dart';
import 'badge_rules.dart';

/// Display metadata for one release-1 evidence badge, pairing the pure
/// [EvidenceBadgeId] with the crest's icon/discipline and localized copy.
class BadgeDisplay {
  const BadgeDisplay({
    required this.id,
    required this.name,
    required this.criterion,
    required this.icon,
    required this.discipline,
  });

  final EvidenceBadgeId id;
  final String name;
  final String criterion;
  final BadgeIcon icon;
  final BadgeDiscipline discipline;
}

/// The release-1 badge set in a fixed display order, independent of unlock
/// state -- locked badges still show their criterion (see `badge_crest.dart`).
List<BadgeDisplay> badgeCatalog(AppLocalizations strings) => <BadgeDisplay>[
  BadgeDisplay(
    id: EvidenceBadgeId.firstSignal,
    name: strings.badgeFirstSignalName,
    criterion: strings.badgeFirstSignalCriterion,
    icon: BadgeIcon.firstSignal,
    discipline: BadgeDiscipline.water,
  ),
  BadgeDisplay(
    id: EvidenceBadgeId.threeStreams,
    name: strings.badgeThreeStreamsName,
    criterion: strings.badgeThreeStreamsCriterion,
    icon: BadgeIcon.streamExplorer,
    discipline: BadgeDiscipline.water,
  ),
  BadgeDisplay(
    id: EvidenceBadgeId.habitatEye,
    name: strings.badgeHabitatEyeName,
    criterion: strings.badgeHabitatEyeCriterion,
    icon: BadgeIcon.habitatEye,
    discipline: BadgeDiscipline.habitat,
  ),
  BadgeDisplay(
    id: EvidenceBadgeId.clearView,
    name: strings.badgeClearViewName,
    criterion: strings.badgeClearViewCriterion,
    icon: BadgeIcon.clearView,
    discipline: BadgeDiscipline.community,
  ),
  BadgeDisplay(
    id: EvidenceBadgeId.biodiversityObservation,
    name: strings.badgeBiodiversityObservationName,
    criterion: strings.badgeBiodiversityObservationCriterion,
    icon: BadgeIcon.biodiversity,
    discipline: BadgeDiscipline.habitat,
  ),
];
