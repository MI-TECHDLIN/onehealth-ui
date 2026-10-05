import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../app/app_router.dart';
import '../../core/gamification/badge_acknowledgement_store.dart';
import '../../core/gamification/badge_rules.dart';
import '../../core/gamification/contribution_rhythm.dart';
import '../../core/mode/app_mode.dart';
import '../../core/profile/avatar_catalog.dart';
import '../../core/settings/app_preferences.dart';
import '../../core/settings/app_settings_controller.dart';
import '../../core/theme/tokens.dart';
import '../../data/repositories/repository_models.dart';
import '../../data/repositories/repository_scope.dart';
import '../../l10n/generated/app_localizations.dart';
import 'widgets/badge_shelf.dart';

/// A check counts toward "this season" within this rolling window, rather
/// than by meteorological season label -- simpler, and avoids a label edge
/// case at a season boundary (e.g. two checks on either side of Mar 1
/// reading as two different "seasons" despite being a week apart).
const Duration _thisSeasonWindow = Duration(days: 91);

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key, this.preferences, this.now});

  /// Overridable for tests; production uses the shared on-device store.
  final AppPreferences? preferences;
  final DateTime Function()? now;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _initialized = false;
  bool _loaded = false;
  List<AssessmentRecord> _history = const <AssessmentRecord>[];
  AuthUser? _user;
  Set<EvidenceBadgeId> _unlocked = const <EvidenceBadgeId>{};
  Set<EvidenceBadgeId> _acknowledged = const <EvidenceBadgeId>{};
  BadgeAcknowledgementStore? _badgeStore;

  DateTime get _now => (widget.now ?? DateTime.now)().toUtc();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _initialized = true;
    unawaited(_load());
  }

  Future<void> _load() async {
    final repositoryScope = RepositoryScope.of(context);
    final store = BadgeAcknowledgementStore(
      preferences: widget.preferences ?? SharedPreferencesAppPreferences(),
      mode: repositoryScope.mode,
    );
    List<AssessmentRecord> history;
    try {
      history = await repositoryScope.repositories.assessments.history();
    } catch (_) {
      history = const <AssessmentRecord>[];
    }
    AuthUser? user;
    if (repositoryScope.mode.isLive) {
      try {
        user = await repositoryScope.repositories.auth.currentUser();
      } catch (_) {
        user = null;
      }
    }
    final unlocked = computeUnlockedBadges(history);
    final acknowledged = await store.acknowledged();
    if (!mounted) return;
    setState(() {
      _badgeStore = store;
      _history = history;
      _user = user;
      _loaded = true;
      _unlocked = unlocked;
      _acknowledged = acknowledged;
    });
  }

  Future<void> _acknowledge(EvidenceBadgeId id) async {
    await _badgeStore?.acknowledge(id);
    if (!mounted) return;
    setState(() => _acknowledged = <EvidenceBadgeId>{..._acknowledged, id});
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final settings = AppSettingsScope.of(context);
    final avatarId = settings.avatarId ?? AvatarCatalog.autoAssignedId;
    final auth = RepositoryScope.of(context).repositories.auth;

    final checksThisSeason = _history
        .where((record) => _now.difference(record.submittedAt) <= _thisSeasonWindow)
        .length;
    final streamsCovered = _history.map((record) => record.siteCode).toSet().length;
    final rhythm = computeWeeklyRhythm(
      checkDates: _history.map((record) => record.submittedAt).toList(),
      now: _now,
    );

    return Scaffold(
      appBar: AppBar(title: Text(strings.profileTitle)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.page),
          children: <Widget>[
            Center(
              child: Container(
                width: 132,
                height: 132,
                padding: const EdgeInsets.all(AppSpacing.xs),
                decoration: const BoxDecoration(
                  color: AppColors.waterMist,
                  shape: BoxShape.circle,
                ),
                child: ClipOval(
                  child: SvgPicture.asset(
                    AvatarCatalog.assetFor(avatarId),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Center(
              child: OutlinedButton.icon(
                onPressed: () => context.go('${AppRoutes.avatar}?change=true'),
                icon: const Icon(PhosphorIconsRegular.userCircle),
                label: Text(strings.authAvatarChangeAction),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              strings.profileDetailsTitle,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: AppSpacing.sm),
            _ProfileDetailsCard(
              loaded: _loaded,
              user: _user,
              onSignIn: () async {
                await settings.setMode(AppMode.live);
                if (context.mounted) context.go(AppRoutes.signIn);
              },
              onSignOut: () async {
                await auth.signOut();
                if (context.mounted) context.go(AppRoutes.signIn);
              },
            ),
            const SizedBox(height: AppSpacing.lg),
            Row(
              children: <Widget>[
                Expanded(
                  child: _StatTile(
                    value: '$checksThisSeason',
                    label: strings.profileStatsChecksThisSeason,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: _StatTile(
                    value: '$streamsCovered',
                    label: strings.profileStatsStreamsCovered,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            _RhythmCard(rhythm: rhythm, strings: strings),
            const SizedBox(height: AppSpacing.lg),
            Text(strings.profileBadgesTitle, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: AppSpacing.sm),
            BadgeShelf(
              unlocked: _unlocked,
              acknowledged: _acknowledged,
              onAcknowledge: _acknowledge,
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileDetailsCard extends StatelessWidget {
  const _ProfileDetailsCard({
    required this.loaded,
    required this.user,
    required this.onSignIn,
    required this.onSignOut,
  });

  final bool loaded;
  final AuthUser? user;
  final VoidCallback onSignIn;
  final VoidCallback onSignOut;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    if (!loaded) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.lg),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }
    final currentUser = user;
    if (currentUser == null) {
      return Card(
        key: const Key('profileGuestState'),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                strings.profileGuestTitle,
                style: Theme.of(context).textTheme.labelLarge,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(strings.profileGuestBody),
              const SizedBox(height: AppSpacing.sm),
              TextButton.icon(
                onPressed: onSignIn,
                icon: const Icon(PhosphorIconsRegular.signIn),
                label: Text(strings.authSignInAction),
              ),
            ],
          ),
        ),
      );
    }
    final memberSince = currentUser.memberSince;
    final formattedMemberSince = memberSince == null
        ? null
        : DateFormat.yMMMMd(
            Localizations.localeOf(context).toString(),
          ).format(memberSince.toLocal());
    return Card(
      key: const Key('profileDetails'),
      child: Column(
        children: <Widget>[
          ListTile(
            leading: const Icon(PhosphorIconsRegular.userCircle),
            title: Text(currentUser.displayName),
            subtitle: Text('@${currentUser.username}'),
          ),
          if (currentUser.email != null)
            ListTile(
              leading: const Icon(PhosphorIconsRegular.envelope),
              title: Text(currentUser.email!),
            ),
          if (currentUser.region != null)
            ListTile(
              leading: const Icon(PhosphorIconsRegular.mapPin),
              title: Text(currentUser.region!),
            ),
          if (formattedMemberSince != null)
            ListTile(
              leading: const Icon(PhosphorIconsRegular.calendar),
              title: Text(strings.profileMemberSince(formattedMemberSince)),
            ),
          if (currentUser.preferredLanguage != null)
            ListTile(
              leading: const Icon(PhosphorIconsRegular.translate),
              title: Text(currentUser.preferredLanguage!),
              subtitle: Text(strings.settingsLanguage),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              0,
              AppSpacing.md,
              AppSpacing.sm,
            ),
            child: Align(
              alignment: AlignmentDirectional.centerStart,
              child: TextButton.icon(
                onPressed: onSignOut,
                icon: const Icon(PhosphorIconsRegular.signOut),
                label: Text(strings.authSignOutAction),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          children: <Widget>[
            Text(value, style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: AppSpacing.xxs),
            Text(
              label,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.labelMedium,
            ),
          ],
        ),
      ),
    );
  }
}

class _RhythmCard extends StatelessWidget {
  const _RhythmCard({required this.rhythm, required this.strings});

  final WeeklyRhythm rhythm;
  final AppLocalizations strings;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(strings.profileRhythmTitle, style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: AppSpacing.xs),
            Row(
              children: <Widget>[
                Icon(
                  rhythm.thisWeekDone
                      ? PhosphorIconsFill.checkCircle
                      : PhosphorIconsRegular.circleDashed,
                  color: rhythm.thisWeekDone ? AppColors.success : AppColors.inkMuted,
                  size: 20,
                ),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  rhythm.thisWeekDone
                      ? strings.profileRhythmThisWeekDone
                      : strings.profileRhythmThisWeekPending,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xxs),
            Text(
              rhythm.streakWeeks > 0
                  ? strings.profileRhythmStreak(rhythm.streakWeeks)
                  : strings.profileRhythmStreakNone,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            if (rhythm.streakWeeks > 0)
              Text(
                rhythm.graceAvailable
                    ? strings.profileRhythmGraceAvailable
                    : strings.profileRhythmGraceUsed,
                style: Theme.of(context).textTheme.bodySmall,
              ),
          ],
        ),
      ),
    );
  }
}
