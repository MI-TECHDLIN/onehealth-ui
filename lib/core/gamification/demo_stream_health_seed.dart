/// Seeded past checks for Demo mode's stream health timeline, keyed by the
/// bundled demo site code (see `DemoSiteRepository`). These exist only to
/// make the site-detail timeline "look alive" in Demo mode -- they are
/// synthetic, generated at read time (never persisted) and never counted by
/// `computeUnlockedBadges`/`computeWeeklyRhythm`, which only ever see the
/// citizen's real submitted history. Live mode never sees this data.
library;

/// One synthetic past check: `daysAgo` is relative to the moment the
/// timeline is rendered, so the series always reads as recent.
class SeedHealthCheck {
  const SeedHealthCheck({required this.daysAgo, required this.overallAssessment});

  final int daysAgo;

  /// 'GOOD' | 'MODERATE' | 'POOR', matching `AssessmentRecord.overallAssessment`.
  final String overallAssessment;
}

const Map<String, List<SeedHealthCheck>> demoStreamHealthSeed =
    <String, List<SeedHealthCheck>>{
      'DEMO-RIVER-01': <SeedHealthCheck>[
        SeedHealthCheck(daysAgo: 150, overallAssessment: 'GOOD'),
        SeedHealthCheck(daysAgo: 48, overallAssessment: 'MODERATE'),
      ],
      'DEMO-BROOK-02': <SeedHealthCheck>[
        SeedHealthCheck(daysAgo: 21, overallAssessment: 'GOOD'),
      ],
      'DEMO-CREEK-03': <SeedHealthCheck>[
        SeedHealthCheck(daysAgo: 6, overallAssessment: 'POOR'),
      ],
    };
