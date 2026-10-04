import 'package:flutter_test/flutter_test.dart';
import 'package:onehealth_ui/core/gamification/badge_rules.dart';
import 'package:onehealth_ui/data/repositories/repository_models.dart';

AssessmentRecord _record({
  required String id,
  required String siteCode,
  required DateTime submittedAt,
  Map<AssessmentMediaRole, String> fileIds = const <AssessmentMediaRole, String>{},
}) => AssessmentRecord(
  id: id,
  siteCode: siteCode,
  submittedAt: submittedAt,
  overallAssessment: 'GOOD',
  fileIds: fileIds,
);

void main() {
  test('no badges unlock from empty history', () {
    expect(computeUnlockedBadges(const <AssessmentRecord>[]), isEmpty);
  });

  test('first signal unlocks on any single submitted check', () {
    final unlocked = computeUnlockedBadges(<AssessmentRecord>[
      _record(id: '1', siteCode: 'A', submittedAt: DateTime.utc(2026, 1, 1)),
    ]);

    expect(unlocked, <EvidenceBadgeId>{EvidenceBadgeId.firstSignal});
  });

  test('three streams unlocks only once three distinct sites are checked', () {
    final twoSites = computeUnlockedBadges(<AssessmentRecord>[
      _record(id: '1', siteCode: 'A', submittedAt: DateTime.utc(2026, 1, 1)),
      _record(id: '2', siteCode: 'B', submittedAt: DateTime.utc(2026, 1, 2)),
    ]);
    expect(twoSites.contains(EvidenceBadgeId.threeStreams), isFalse);

    final threeSites = computeUnlockedBadges(<AssessmentRecord>[
      _record(id: '1', siteCode: 'A', submittedAt: DateTime.utc(2026, 1, 1)),
      _record(id: '2', siteCode: 'B', submittedAt: DateTime.utc(2026, 1, 2)),
      _record(id: '3', siteCode: 'C', submittedAt: DateTime.utc(2026, 1, 3)),
    ]);
    expect(threeSites.contains(EvidenceBadgeId.threeStreams), isTrue);
  });

  test('habitat eye requires the same site checked in two different seasons', () {
    final sameSeason = computeUnlockedBadges(<AssessmentRecord>[
      _record(id: '1', siteCode: 'A', submittedAt: DateTime.utc(2026, 1, 1)),
      _record(id: '2', siteCode: 'A', submittedAt: DateTime.utc(2026, 2, 20)),
    ]);
    expect(sameSeason.contains(EvidenceBadgeId.habitatEye), isFalse);

    final differentSeasons = computeUnlockedBadges(<AssessmentRecord>[
      _record(id: '1', siteCode: 'A', submittedAt: DateTime.utc(2026, 1, 1)),
      _record(id: '2', siteCode: 'A', submittedAt: DateTime.utc(2026, 4, 10)),
    ]);
    expect(differentSeasons.contains(EvidenceBadgeId.habitatEye), isTrue);
  });

  test('clear view requires all four photo roles on one check', () {
    final partial = computeUnlockedBadges(<AssessmentRecord>[
      _record(
        id: '1',
        siteCode: 'A',
        submittedAt: DateTime.utc(2026, 1, 1),
        fileIds: const <AssessmentMediaRole, String>{
          AssessmentMediaRole.upstreamPhoto: 'f1',
          AssessmentMediaRole.downstreamPhoto: 'f2',
        },
      ),
    ]);
    expect(partial.contains(EvidenceBadgeId.clearView), isFalse);

    final complete = computeUnlockedBadges(<AssessmentRecord>[
      _record(
        id: '1',
        siteCode: 'A',
        submittedAt: DateTime.utc(2026, 1, 1),
        fileIds: const <AssessmentMediaRole, String>{
          AssessmentMediaRole.upstreamPhoto: 'f1',
          AssessmentMediaRole.downstreamPhoto: 'f2',
          AssessmentMediaRole.surroundingPhoto: 'f3',
          AssessmentMediaRole.interestingPhoto: 'f4',
        },
      ),
    ]);
    expect(complete.contains(EvidenceBadgeId.clearView), isTrue);
  });

  test('biodiversity observation unlocks from an interesting/biodiversity photo alone', () {
    final unlocked = computeUnlockedBadges(<AssessmentRecord>[
      _record(
        id: '1',
        siteCode: 'A',
        submittedAt: DateTime.utc(2026, 1, 1),
        fileIds: const <AssessmentMediaRole, String>{
          AssessmentMediaRole.interestingPhoto: 'f4',
        },
      ),
    ]);
    expect(unlocked, contains(EvidenceBadgeId.biodiversityObservation));
    expect(unlocked.contains(EvidenceBadgeId.clearView), isFalse);
  });
}
