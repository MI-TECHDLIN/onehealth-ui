import '../../data/repositories/assessment_repository.dart';
import '../../data/repositories/repository_models.dart';
import '../mode/app_mode.dart';
import '../settings/app_preferences.dart';
import 'badge_acknowledgement_store.dart';

/// The judge-demo story: a coherent, idempotent seed for Demo mode's "home"
/// stream (Willow Bend Stream, a believable good/moderate/poor timeline over
/// several months), two streams checked once each, and one resumable draft
/// -- so a judge's first minutes in Demo mode land on a lived-in app rather
/// than an empty one. Coordinates match `DemoSiteRepository`'s bundled
/// Guimarães sites; this never writes fabricated photos or touches Live.
///
/// Unlike `demo_stream_health_seed.dart`'s read-time-only decoration for the
/// site-detail timeline, this writes real [AssessmentRecord]s into Demo's
/// local history store, so `computeUnlockedBadges`/`computeWeeklyRhythm` --
/// which only ever look at real submitted history -- pick the story up too:
/// First signal, Three streams, and Habitat eye unlock; Clear view and
/// Biodiversity observation stay locked (no seeded record carries any
/// `fileIds`).
class DemoStorySeeder {
  DemoStorySeeder({required AppPreferences preferences, DateTime Function()? now})
    : _preferences = preferences,
      _now = now ?? DateTime.now;

  static final String _seededKey = '${AppMode.demo.storageNamespace}.story.seeded';

  final AppPreferences _preferences;
  final DateTime Function() _now;

  Future<bool> isSeeded() async =>
      (await _preferences.readString(_seededKey)) == 'true';

  /// Seeds the story only the first time Demo mode is entered. Safe to call
  /// repeatedly -- a later call is a no-op once seeded.
  Future<void> seedIfNeeded({
    required DemoSeedableAssessmentRepository assessments,
    required BadgeAcknowledgementStore badges,
  }) async {
    if (await isSeeded()) return;
    await _seed(assessments: assessments, badges: badges);
  }

  /// Wipes whatever is there (seeded or the citizen's own Demo activity) and
  /// reseeds the standard story from scratch. Used by Settings > Demo data >
  /// Reset demo.
  Future<void> reset({
    required DemoSeedableAssessmentRepository assessments,
    required BadgeAcknowledgementStore badges,
  }) =>
      _seed(assessments: assessments, badges: badges);

  Future<void> _seed({
    required DemoSeedableAssessmentRepository assessments,
    required BadgeAcknowledgementStore badges,
  }) async {
    final now = _now().toUtc();
    await assessments.clearSeededData();
    await badges.clear();
    await assessments.seedHistory(buildDemoSeedHistory(now));
    await assessments.seedDraft(buildDemoSeedDraft());
    await _preferences.writeString(_seededKey, 'true');
  }
}

/// The "home" stream: Willow Bend Stream, checked repeatedly over several
/// months with a rough patch and a recovery -- and recently enough, at a
/// steady weekly cadence, to read as an active rhythm no matter which day of
/// the week the story is (re)seeded on.
const String _homeSite = 'DEMO-RIVER-01';

List<AssessmentRecord> buildDemoSeedHistory(DateTime now) => <AssessmentRecord>[
  _seedRecord(now, daysAgo: 120, site: _homeSite, assessment: 'GOOD', idSuffix: 'home-1'),
  _seedRecord(now, daysAgo: 60, site: _homeSite, assessment: 'POOR', idSuffix: 'home-2'),
  _seedRecord(now, daysAgo: 21, site: _homeSite, assessment: 'MODERATE', idSuffix: 'home-3'),
  _seedRecord(now, daysAgo: 14, site: _homeSite, assessment: 'GOOD', idSuffix: 'home-4'),
  _seedRecord(now, daysAgo: 7, site: _homeSite, assessment: 'MODERATE', idSuffix: 'home-5'),
  _seedRecord(now, daysAgo: 0, site: _homeSite, assessment: 'GOOD', idSuffix: 'home-6'),
  _seedRecord(
    now,
    daysAgo: 10,
    site: 'DEMO-BROOK-02',
    assessment: 'GOOD',
    idSuffix: 'brook-1',
  ),
  _seedRecord(
    now,
    daysAgo: 3,
    site: 'DEMO-CREEK-03',
    assessment: 'MODERATE',
    idSuffix: 'creek-1',
  ),
];

/// One check left mid-flow on Market Quarter Channel -- the one bundled
/// Guimarães site with no past checks -- so Streams/"Continue where you left
/// off" has something to resume on a fresh demo.
AssessmentDraft buildDemoSeedDraft() => const AssessmentDraft(
  id: 'demo-seed-draft-urban-04',
  siteCode: 'DEMO-URBAN-04',
  latitude: 41.439,
  longitude: -8.282,
  siteLatitude: 41.439,
  siteLongitude: -8.282,
  channelForm: 'U',
  answeredQuestionIds: <String>{'channelForm'},
);

AssessmentRecord _seedRecord(
  DateTime now, {
  required int daysAgo,
  required String site,
  required String assessment,
  required String idSuffix,
}) => AssessmentRecord(
  id: 'demo-seed-$idSuffix',
  siteCode: site,
  submittedAt: now.subtract(Duration(days: daysAgo)),
  overallAssessment: assessment,
);
