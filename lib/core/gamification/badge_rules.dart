import '../../data/repositories/repository_models.dart';
import 'season.dart';

/// The release-1 evidence badge set. No tiers -- see the design report's
/// "Badge family" section for why no observation should read as worth less
/// than another.
enum EvidenceBadgeId {
  firstSignal,
  threeStreams,
  habitatEye,
  clearView,
  biodiversityObservation,
}

/// Photo roles that make up a "complete photo set" for [EvidenceBadgeId.clearView].
/// `video` is deliberately excluded -- it is a separate, optional capture.
const List<AssessmentMediaRole> _completePhotoSetRoles = <AssessmentMediaRole>[
  AssessmentMediaRole.upstreamPhoto,
  AssessmentMediaRole.downstreamPhoto,
  AssessmentMediaRole.surroundingPhoto,
  AssessmentMediaRole.interestingPhoto,
];

/// Computes which release-1 evidence badges a citizen's own check history
/// has unlocked. Pure and deterministic: the same history always unlocks the
/// same badges, so this can run against Live or Demo history alike.
Set<EvidenceBadgeId> computeUnlockedBadges(List<AssessmentRecord> history) {
  final unlocked = <EvidenceBadgeId>{};
  if (history.isEmpty) return unlocked;

  unlocked.add(EvidenceBadgeId.firstSignal);

  final distinctSites = history.map((record) => record.siteCode).toSet();
  if (distinctSites.length >= 3) {
    unlocked.add(EvidenceBadgeId.threeStreams);
  }

  final bySite = <String, List<AssessmentRecord>>{};
  for (final record in history) {
    bySite.putIfAbsent(record.siteCode, () => <AssessmentRecord>[]).add(record);
  }
  for (final records in bySite.values) {
    final seasons = records.map((r) => seasonOf(r.submittedAt)).toSet();
    if (seasons.length >= 2) {
      unlocked.add(EvidenceBadgeId.habitatEye);
      break;
    }
  }

  for (final record in history) {
    if (_completePhotoSetRoles.every(record.fileIds.containsKey)) {
      unlocked.add(EvidenceBadgeId.clearView);
    }
    if (record.fileIds.containsKey(AssessmentMediaRole.interestingPhoto)) {
      unlocked.add(EvidenceBadgeId.biodiversityObservation);
    }
  }

  return unlocked;
}
