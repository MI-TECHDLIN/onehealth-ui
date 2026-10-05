import '../mode/app_mode.dart';
import '../settings/app_preferences.dart';
import 'badge_rules.dart';

/// Tracks which unlocked badges the citizen has already opened/seen, so a
/// freshly-unlocked badge can show its one-shot "new" reveal exactly once.
/// Namespaced by [AppMode] like every other mode-owned store.
class BadgeAcknowledgementStore {
  BadgeAcknowledgementStore({
    required AppPreferences preferences,
    required AppMode mode,
  }) : _preferences = preferences,
       _key = '${mode.storageNamespace}.badges.acknowledged';

  final AppPreferences _preferences;
  final String _key;

  Future<Set<EvidenceBadgeId>> acknowledged() async {
    final raw = await _preferences.readString(_key);
    if (raw == null || raw.isEmpty) return <EvidenceBadgeId>{};
    return raw
        .split(',')
        .where((name) => name.isNotEmpty)
        .map((name) => EvidenceBadgeId.values.byName(name))
        .toSet();
  }

  Future<void> acknowledge(EvidenceBadgeId id) async {
    final current = await acknowledged();
    if (!current.add(id)) return;
    await _preferences.writeString(
      _key,
      current.map((value) => value.name).join(','),
    );
  }

  /// Forgets every acknowledgement, so freshly (re)seeded badges show their
  /// one-shot "new" reveal again.
  Future<void> clear() => _preferences.remove(_key);
}
