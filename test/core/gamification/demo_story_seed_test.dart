import 'package:flutter_test/flutter_test.dart';
import 'package:onehealth_ui/core/gamification/badge_acknowledgement_store.dart';
import 'package:onehealth_ui/core/gamification/badge_rules.dart';
import 'package:onehealth_ui/core/gamification/contribution_rhythm.dart';
import 'package:onehealth_ui/core/gamification/demo_story_seed.dart';
import 'package:onehealth_ui/core/mode/app_mode.dart';
import 'package:onehealth_ui/core/settings/app_preferences.dart';
import 'package:onehealth_ui/data/repositories/assessment_repository.dart';
import 'package:onehealth_ui/data/repositories/repository_bundle.dart';
import 'package:onehealth_ui/data/repositories/repository_models.dart';

void main() {
  final now = DateTime.utc(2026, 10, 4);

  DemoAssessmentRepository demoAssessments(AppPreferences preferences) =>
      RepositoryBundle.demo(preferences: preferences).assessments
          as DemoAssessmentRepository;

  BadgeAcknowledgementStore badgeStore(AppPreferences preferences) =>
      BadgeAcknowledgementStore(preferences: preferences, mode: AppMode.demo);

  group('buildDemoSeedHistory', () {
    test('unlocks exactly first signal, three streams, and habitat eye', () {
      final history = buildDemoSeedHistory(now);
      final unlocked = computeUnlockedBadges(history);

      expect(unlocked, <EvidenceBadgeId>{
        EvidenceBadgeId.firstSignal,
        EvidenceBadgeId.threeStreams,
        EvidenceBadgeId.habitatEye,
      });
      expect(unlocked.contains(EvidenceBadgeId.clearView), isFalse);
      expect(unlocked.contains(EvidenceBadgeId.biodiversityObservation), isFalse);
    });

    test('reads as an active weekly rhythm as of right now', () {
      final history = buildDemoSeedHistory(now);
      final rhythm = computeWeeklyRhythm(
        checkDates: history.map((record) => record.submittedAt).toList(),
        now: now,
      );

      expect(rhythm.thisWeekDone, isTrue);
      expect(rhythm.streakWeeks, greaterThanOrEqualTo(2));
    });

    test('covers the home stream plus two others checked once', () {
      final history = buildDemoSeedHistory(now);
      final bySite = <String, int>{};
      for (final record in history) {
        bySite[record.siteCode] = (bySite[record.siteCode] ?? 0) + 1;
      }

      expect(bySite['DEMO-RIVER-01'], inInclusiveRange(4, 6));
      expect(bySite['DEMO-BROOK-02'], 1);
      expect(bySite['DEMO-CREEK-03'], 1);
      // The fourth bundled site is left with no history -- it carries the
      // resumable draft instead.
      expect(bySite.containsKey('DEMO-URBAN-04'), isFalse);
    });

    test('never attaches seeded photos -- no real OneAquaHealth media', () {
      final history = buildDemoSeedHistory(now);
      expect(history.every((record) => record.fileIds.isEmpty), isTrue);
    });
  });

  test('buildDemoSeedDraft resumes on the stream with no past checks', () {
    final draft = buildDemoSeedDraft();
    expect(draft.siteCode, 'DEMO-URBAN-04');
    expect(draft.answeredQuestionIds, isNotEmpty);
  });

  group('DemoStorySeeder', () {
    test('seeding populates history, a draft, and no badge acknowledgements', () async {
      final preferences = MemoryAppPreferences();
      final assessments = demoAssessments(preferences);
      final seeder = DemoStorySeeder(preferences: preferences, now: () => now);

      await seeder.seedIfNeeded(
        assessments: assessments,
        badges: badgeStore(preferences),
      );

      expect(await assessments.history(), hasLength(8));
      expect(await assessments.drafts(), hasLength(1));
      expect(await badgeStore(preferences).acknowledged(), isEmpty);
      expect(await seeder.isSeeded(), isTrue);
    });

    test('seeding twice does not duplicate records', () async {
      final preferences = MemoryAppPreferences();
      final assessments = demoAssessments(preferences);
      final seeder = DemoStorySeeder(preferences: preferences, now: () => now);

      await seeder.seedIfNeeded(
        assessments: assessments,
        badges: badgeStore(preferences),
      );
      final firstHistory = await assessments.history();

      await seeder.seedIfNeeded(
        assessments: assessments,
        badges: badgeStore(preferences),
      );
      final secondHistory = await assessments.history();

      expect(secondHistory.length, firstHistory.length);
    });

    test('reset wipes a judge\'s own extra activity and reseeds the standard story', () async {
      final preferences = MemoryAppPreferences();
      final assessments = demoAssessments(preferences);
      final seeder = DemoStorySeeder(preferences: preferences, now: () => now);

      await seeder.seedIfNeeded(
        assessments: assessments,
        badges: badgeStore(preferences),
      );

      // Simulate a judge completing an extra real check and acknowledging a
      // badge during the demo.
      await assessments.submit(
        const AssessmentDraft(id: 'judge-extra', siteCode: 'DEMO-CREEK-03'),
      );
      await badgeStore(preferences).acknowledge(EvidenceBadgeId.firstSignal);
      expect(await assessments.history(), hasLength(9));

      await seeder.reset(
        assessments: assessments,
        badges: badgeStore(preferences),
      );

      expect(await assessments.history(), hasLength(8));
      expect(await assessments.drafts(), hasLength(1));
      expect(await badgeStore(preferences).acknowledged(), isEmpty);
    });

    test('never writes to Live\'s namespaced storage', () async {
      final preferences = MemoryAppPreferences();
      final assessments = demoAssessments(preferences);
      final seeder = DemoStorySeeder(preferences: preferences, now: () => now);

      await seeder.seedIfNeeded(
        assessments: assessments,
        badges: badgeStore(preferences),
      );

      expect(
        await preferences.readString('${AppMode.live.storageNamespace}.assessment.history'),
        isNull,
      );
      expect(
        await preferences.readString('${AppMode.live.storageNamespace}.assessment.drafts'),
        isNull,
      );
      expect(
        await preferences.readString(
          '${AppMode.live.storageNamespace}.badges.acknowledged',
        ),
        isNull,
      );
    });
  });
}
