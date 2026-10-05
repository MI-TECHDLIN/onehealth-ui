import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app/app_router.dart';
import '../../core/gamification/demo_stream_health_seed.dart';
import '../../core/icons/water_icons.dart';
import '../../core/mascot/aqua_mascot.dart';
import '../../core/mode/app_mode.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/aqua_components.dart';
import '../../core/widgets/friendly_error_banner.dart';
import '../../core/widgets/stream_health_timeline.dart';
import '../../data/repositories/repository_models.dart';
import '../../data/repositories/repository_scope.dart';
import '../../l10n/generated/app_localizations.dart';
import 'walk_time.dart';

/// Human site name with the research code secondary, a freshness cue, a
/// short safety note, directions, and the round-4 "Check this stream" entry
/// point. Reached from a map pin; [site] is `null` only on a direct deep
/// link with no map context, which this screen degrades gracefully for.
class SiteDetailScreen extends StatelessWidget {
  const SiteDetailScreen({super.key, required this.code, this.site});

  final String code;
  final StreamSite? site;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final site = this.site;
    return Scaffold(
      appBar: AppBar(title: Text(strings.siteDetailTitle)),
      body: SafeArea(
        child: site == null
            ? _MissingSiteState(strings: strings)
            : _SiteDetailBody(site: site, strings: strings),
      ),
    );
  }
}

class _MissingSiteState extends StatelessWidget {
  const _MissingSiteState({required this.strings});
  final AppLocalizations strings;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.page),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const AquaMascot(mood: MascotMood.guiding, size: 112),
            const SizedBox(height: AppSpacing.md),
            Text(
              strings.siteDetailMissingTitle,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              strings.siteDetailMissingBody,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: AppSpacing.lg),
            AquaButton(
              label: strings.siteDetailBackToMapAction,
              expand: false,
              onPressed: () => context.go(AppRoutes.home),
            ),
          ],
        ),
      ),
    );
  }
}

class _SiteDetailBody extends StatelessWidget {
  const _SiteDetailBody({required this.site, required this.strings});

  final StreamSite site;
  final AppLocalizations strings;

  @override
  Widget build(BuildContext context) {
    final walkMinutes = walkMinutesFor(site.distanceKm);
    final secondaryLine = site.cityName == null
        ? strings.siteDetailCodeLabel(site.code)
        : strings.siteDetailLocationWithCity(site.cityName!, site.code);

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.page),
      children: <Widget>[
        AspectRatio(
          aspectRatio: 16 / 9,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadii.lg),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: <Color>[AppColors.waterLight, AppColors.deepWater],
              ),
            ),
            child: const Align(
              alignment: Alignment.bottomRight,
              child: Padding(
                padding: EdgeInsets.all(AppSpacing.sm),
                child: PhosphorIcon(
                  PhosphorIconsRegular.waves,
                  color: AppColors.white,
                  size: 32,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Text(site.name, style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: AppSpacing.xxs),
        Text(secondaryLine, style: Theme.of(context).textTheme.bodyMedium),
        const SizedBox(height: AppSpacing.md),
        if (walkMinutes != null) ...<Widget>[
          _InfoRow(
            icon: PhosphorIconsRegular.personSimpleWalk,
            label: strings.mapWalkMinutes(walkMinutes),
          ),
          const SizedBox(height: AppSpacing.xs),
        ],
        _LastCheckedRow(site: site, strings: strings),
        const SizedBox(height: AppSpacing.lg),
        Text(strings.siteDetailTimelineTitle, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: AppSpacing.sm),
        _HealthTimelineSection(site: site, strings: strings),
        const SizedBox(height: AppSpacing.lg),
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.sageLight,
            borderRadius: BorderRadius.circular(AppRadii.lg),
            border: Border.all(color: AppColors.sage),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const WaterIconWidget(
                WaterIcon.fieldSafety,
                color: AppColors.deepWater,
              ),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(
                      strings.siteDetailBeforeYouGoTitle,
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      strings.siteDetailSafetyNote,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        AquaButton(
          key: const Key('siteDetailCheckAction'),
          label: strings.siteDetailCheckAction,
          leading: const WaterIconWidget(WaterIcon.streamCheck),
          onPressed: () => _checkThisStream(context),
        ),
        const SizedBox(height: AppSpacing.sm),
        Center(
          child: TextButton.icon(
            key: const Key('siteDetailDirectionsAction'),
            onPressed: () => _openDirections(context),
            icon: const PhosphorIcon(PhosphorIconsRegular.navigationArrow),
            label: Text(strings.siteDetailDirectionsAction),
          ),
        ),
      ],
    );
  }

  void _checkThisStream(BuildContext context) {
    context.push(AppRoutes.checkAssess, extra: site);
  }

  Future<void> _openDirections(BuildContext context) async {
    final label = Uri.encodeComponent(site.name);
    final geoUri = Uri.parse(
      'geo:${site.latitude},${site.longitude}'
      '?q=${site.latitude},${site.longitude}($label)',
    );
    final httpsUri = Uri.parse(
      'https://www.google.com/maps/search/?api=1'
      '&query=${site.latitude},${site.longitude}',
    );

    var opened = await _tryLaunch(geoUri);
    if (!opened) opened = await _tryLaunch(httpsUri);

    if (!opened && context.mounted) {
      showFriendlyErrorSnackBar(context, strings.siteDetailDirectionsUnavailable);
    }
  }

  Future<bool> _tryLaunch(Uri uri) async {
    try {
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      return false;
    }
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        PhosphorIcon(icon, size: 18, color: AppColors.inkMuted),
        const SizedBox(width: AppSpacing.xs),
        Text(label, style: Theme.of(context).textTheme.bodyMedium),
      ],
    );
  }
}

/// Past good/moderate/poor checks for this one site. Live only ever shows
/// the citizen's own checks; Demo blends in a small seeded series (see
/// `demo_stream_health_seed.dart`) so the screen "looks alive" even before
/// the citizen has checked anything themselves.
class _HealthTimelineSection extends StatelessWidget {
  const _HealthTimelineSection({required this.site, required this.strings});

  final StreamSite site;
  final AppLocalizations strings;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<StreamHealthEntry>>(
      future: _entries(context),
      builder: (context, snapshot) {
        final entries = snapshot.data;
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(height: 24);
        }
        if (entries == null || entries.isEmpty) {
          return Text(
            strings.siteDetailTimelineEmpty,
            style: Theme.of(context).textTheme.bodyMedium,
          );
        }
        return StreamHealthTimeline(
          entries: entries,
          levelLabel: (level) => switch (level) {
            StreamHealthLevel.good => strings.healthLevelGood,
            StreamHealthLevel.moderate => strings.healthLevelModerate,
            StreamHealthLevel.poor => strings.healthLevelPoor,
            StreamHealthLevel.unknown => strings.healthLevelUnknown,
          },
          rowSemanticLabel: (dateLabel, levelLabel) => '$dateLabel, $levelLabel',
        );
      },
    );
  }

  Future<List<StreamHealthEntry>> _entries(BuildContext context) async {
    final scope = RepositoryScope.of(context);
    List<AssessmentRecord> history;
    try {
      history = await scope.repositories.assessments.history();
    } catch (_) {
      history = const <AssessmentRecord>[];
    }
    final own = history
        .where((record) => record.siteCode == site.code)
        .map(
          (record) => StreamHealthEntry(
            date: record.submittedAt,
            level: streamHealthLevelFromOverallAssessment(record.overallAssessment),
          ),
        );

    final seeded = scope.mode == AppMode.demo
        ? (demoStreamHealthSeed[site.code] ?? const <SeedHealthCheck>[]).map(
            (seed) => StreamHealthEntry(
              date: DateTime.now().toUtc().subtract(Duration(days: seed.daysAgo)),
              level: streamHealthLevelFromOverallAssessment(seed.overallAssessment),
            ),
          )
        : const Iterable<StreamHealthEntry>.empty();

    final combined = <StreamHealthEntry>[...own, ...seeded]
      ..sort((a, b) => b.date.compareTo(a.date));
    return combined;
  }
}

class _LastCheckedRow extends StatelessWidget {
  const _LastCheckedRow({required this.site, required this.strings});

  final StreamSite site;
  final AppLocalizations strings;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DateTime?>(
      future: _lastCheckedBy(context),
      builder: (context, snapshot) {
        // Reserve the row's height while loading rather than flashing
        // "never checked" before the real answer is known.
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(height: 18);
        }
        return _InfoRow(
          icon: PhosphorIconsRegular.clockCountdown,
          label: _freshnessLabel(snapshot.data),
        );
      },
    );
  }

  Future<DateTime?> _lastCheckedBy(BuildContext context) async {
    try {
      final history = await RepositoryScope.of(
        context,
      ).repositories.assessments.history();
      final matches = history.where((record) => record.siteCode == site.code);
      if (matches.isEmpty) return null;
      return matches
          .map((record) => record.submittedAt)
          .reduce((a, b) => a.isAfter(b) ? a : b);
    } catch (_) {
      return null;
    }
  }

  String _freshnessLabel(DateTime? lastChecked) {
    if (lastChecked == null) return strings.siteDetailNeverChecked;
    final days = DateTime.now().toUtc().difference(lastChecked.toUtc()).inDays;
    if (days <= 0) return strings.siteDetailLastCheckedToday;
    if (days == 1) return strings.siteDetailLastCheckedYesterday;
    return strings.siteDetailLastCheckedDaysAgo(days);
  }
}
