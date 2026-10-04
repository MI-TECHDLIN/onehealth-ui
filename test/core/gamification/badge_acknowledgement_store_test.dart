import 'package:flutter_test/flutter_test.dart';
import 'package:onehealth_ui/core/gamification/badge_acknowledgement_store.dart';
import 'package:onehealth_ui/core/gamification/badge_rules.dart';
import 'package:onehealth_ui/core/mode/app_mode.dart';
import 'package:onehealth_ui/core/settings/app_preferences.dart';

void main() {
  test('badges start unacknowledged and persist once acknowledged', () async {
    final preferences = MemoryAppPreferences();
    final store = BadgeAcknowledgementStore(
      preferences: preferences,
      mode: AppMode.demo,
    );

    expect(await store.acknowledged(), isEmpty);

    await store.acknowledge(EvidenceBadgeId.firstSignal);
    expect(await store.acknowledged(), <EvidenceBadgeId>{EvidenceBadgeId.firstSignal});

    final reopened = BadgeAcknowledgementStore(
      preferences: preferences,
      mode: AppMode.demo,
    );
    expect(await reopened.acknowledged(), <EvidenceBadgeId>{EvidenceBadgeId.firstSignal});
  });

  test('Demo and Live acknowledgements are isolated by mode', () async {
    final preferences = MemoryAppPreferences();
    final demoStore = BadgeAcknowledgementStore(preferences: preferences, mode: AppMode.demo);
    final liveStore = BadgeAcknowledgementStore(preferences: preferences, mode: AppMode.live);

    await demoStore.acknowledge(EvidenceBadgeId.firstSignal);

    expect(await demoStore.acknowledged(), isNotEmpty);
    expect(await liveStore.acknowledged(), isEmpty);
  });
}
