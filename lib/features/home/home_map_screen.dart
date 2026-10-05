import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../app/app_router.dart';
import '../../core/errors/friendly_error.dart';
import '../../core/gamification/reminder_rules.dart';
import '../../core/mascot/aqua_mascot.dart';
import '../../core/notifications/reminder_coordinator.dart';
import '../../core/notifications/reminder_notifier.dart';
import '../../core/settings/app_preferences.dart';
import '../../core/settings/app_settings_controller.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/aqua_components.dart';
import '../../core/widgets/friendly_error_banner.dart';
import '../../data/repositories/api_failure.dart';
import '../../data/repositories/repository_models.dart';
import '../../data/repositories/repository_scope.dart';
import '../../l10n/generated/app_localizations.dart';
import 'site_filter.dart';
import 'site_preview_card.dart';
import 'stream_map_view.dart';

enum _LoadState { loading, loaded, error }

class HomeMapScreen extends StatefulWidget {
  const HomeMapScreen({
    super.key,
    this.mapViewBuilder = buildDefaultStreamMapView,
    this.reminderCoordinator,
  });

  /// Swappable so widget tests can skip the native MapLibre view. Everything
  /// else on this screen (filters, loading/empty/offline/error states, the
  /// preview card) is ordinary Flutter and is tested directly.
  final StreamMapViewBuilder mapViewBuilder;

  /// Overridable so tests can verify the gentle-reminder check without the
  /// real notifications plugin; production constructs one lazily.
  final ReminderCoordinator? reminderCoordinator;

  @override
  State<HomeMapScreen> createState() => _HomeMapScreenState();
}

class _HomeMapScreenState extends State<HomeMapScreen> {
  _LoadState _state = _LoadState.loading;
  List<StreamSite> _sites = <StreamSite>[];
  Set<String> _visitedCodes = <String>{};
  SiteMapFilter _filter = SiteMapFilter.nearby;
  StreamSite? _selected;
  String? _errorMessage;
  bool _initialized = false;
  bool _locationGranted = false;
  bool _reminderChecked = false;
  MapLibreMapController? _mapController;
  ReminderCoordinator? _reminderCoordinator;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initialized = true;
      unawaited(_load());
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    return Column(
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.page,
            AppSpacing.sm,
            AppSpacing.page,
            AppSpacing.sm,
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: <Widget>[
                AquaFilterChip(
                  label: strings.mapFilterNearby,
                  selected: _filter == SiteMapFilter.nearby,
                  onSelected: (_) => _onFilterSelected(SiteMapFilter.nearby),
                ),
                const SizedBox(width: AppSpacing.xs),
                AquaFilterChip(
                  label: strings.mapFilterNeedsData,
                  selected: _filter == SiteMapFilter.needsData,
                  onSelected: (_) => _onFilterSelected(SiteMapFilter.needsData),
                ),
                const SizedBox(width: AppSpacing.xs),
                AquaFilterChip(
                  label: strings.mapFilterVisited,
                  selected: _filter == SiteMapFilter.visited,
                  onSelected: (_) => _onFilterSelected(SiteMapFilter.visited),
                ),
              ],
            ),
          ),
        ),
        Expanded(child: _buildBody(context, strings)),
      ],
    );
  }

  Widget _buildBody(BuildContext context, AppLocalizations strings) {
    switch (_state) {
      case _LoadState.loading:
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.page),
            child: RippleLoadingState(label: strings.mapLoadingLabel),
          ),
        );
      case _LoadState.error:
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.page),
            child: FriendlyErrorBanner(
              key: const Key('mapErrorBanner'),
              message: _errorMessage ?? FriendlyError.generic,
              onRetry: () => unawaited(_load()),
            ),
          ),
        );
      case _LoadState.loaded:
        final visible = applySiteMapFilter(_sites, _visitedCodes, _filter);
        if (visible.isEmpty) {
          return _EmptyStreamsState(
            title: strings.mapEmptyFilteredTitle,
            body: strings.mapEmptyFilteredBody,
            actionLabel: _filter == SiteMapFilter.nearby
                ? null
                : strings.mapEmptyFilteredAction,
            onAction: _filter == SiteMapFilter.nearby
                ? null
                : () => _onFilterSelected(SiteMapFilter.nearby),
          );
        }
        return Stack(
          children: <Widget>[
            Positioned.fill(
              child: widget.mapViewBuilder(
                sites: visible,
                visitedCodes: _visitedCodes,
                myLocationEnabled: _locationGranted,
                onSiteTapped: (site) => setState(() => _selected = site),
                onControllerReady: (controller) => _mapController = controller,
              ),
            ),
            Positioned(
              right: AppSpacing.md,
              bottom: _selected != null ? 112 : AppSpacing.md,
              child: FloatingActionButton.small(
                key: const Key('locateMeButton'),
                heroTag: 'mapLocateMe',
                tooltip: strings.mapLocateMeTooltip,
                onPressed: _locateMe,
                child: const PhosphorIcon(PhosphorIconsRegular.gpsFix),
              ),
            ),
            if (_selected != null)
              Positioned(
                left: AppSpacing.md,
                right: AppSpacing.md,
                bottom: AppSpacing.md,
                child: SitePreviewCard(
                  site: _selected!,
                  visited: _visitedCodes.contains(_selected!.code),
                  onClose: () => setState(() => _selected = null),
                  onViewDetails: () => _openSiteDetail(_selected!),
                ),
              ),
          ],
        );
    }
  }

  void _onFilterSelected(SiteMapFilter filter) {
    setState(() {
      _filter = filter;
      _selected = null;
    });
  }

  void _openSiteDetail(StreamSite site) {
    context.push(
      '${AppRoutes.siteDetail}/${Uri.encodeComponent(site.code)}',
      extra: site,
    );
  }

  Future<void> _load({double? latitude, double? longitude}) async {
    setState(() {
      _state = _LoadState.loading;
      _errorMessage = null;
    });
    final repositories = RepositoryScope.of(context).repositories;
    try {
      final sites = await repositories.sites.nearbySites(
        latitude: latitude,
        longitude: longitude,
      );
      var visited = const <String>{};
      try {
        final history = await repositories.assessments.history();
        visited = history.map((record) => record.siteCode).toSet();
      } catch (_) {
        // Freshness/visited data is a non-critical enhancement; the map
        // still works without it.
      }
      if (!mounted) return;
      setState(() {
        _sites = sites;
        _visitedCodes = visited;
        _state = _LoadState.loaded;
      });
      unawaited(_maybeShowReminder(sites));
    } catch (error) {
      if (!mounted) return;
      final failure = error is ApiFailure ? error : null;
      setState(() {
        _state = _LoadState.error;
        _errorMessage = FriendlyError.fromFailure(
          statusCode: failure?.statusCode,
          error: failure?.cause ?? error,
        );
      });
    }
  }

  /// Checks once per screen mount whether a gentle reminder is due. Reads
  /// its own history rather than reusing `_load`'s scoped result, since this
  /// must survive being called again after a retry or a locate-me refresh
  /// without re-firing -- see the `_reminderChecked` guard.
  Future<void> _maybeShowReminder(List<StreamSite> sites) async {
    if (_reminderChecked) return;
    _reminderChecked = true;
    if (!mounted) return;
    // A plain `AppSettingsScope.of` would throw if a test pumps this screen
    // without one (several existing ones do, predating this feature); skip
    // quietly instead of crashing an unrelated test's async gap.
    final settings = context
        .dependOnInheritedWidgetOfExactType<AppSettingsScope>()
        ?.notifier;
    if (settings == null) return;
    final mode = RepositoryScope.of(context).mode;
    final strings = AppLocalizations.of(context);
    List<AssessmentRecord> history;
    try {
      history = await RepositoryScope.of(context).repositories.assessments.history();
    } catch (_) {
      return;
    }
    if (!mounted) return;
    final coordinator = _reminderCoordinator ??= widget.reminderCoordinator ??
        ReminderCoordinator(
          preferences: SharedPreferencesAppPreferences(),
          notifier: LocalReminderNotifier(),
        );
    await coordinator.maybeNotify(
      mode: mode,
      remindersEnabled: settings.remindersEnabled,
      history: history,
      siteNamesByCode: <String, String>{
        for (final site in sites) site.code: site.name,
      },
      buildMessage: (candidate) => switch (candidate.kind) {
        ReminderKind.staleSite => (
          title: strings.reminderStaleSiteTitle,
          body: strings.reminderStaleSiteBody(candidate.siteName),
        ),
        ReminderKind.seasonalRevisit => (
          title: strings.reminderSeasonalTitle,
          body: strings.reminderSeasonalBody(candidate.siteName),
        ),
      },
    );
  }

  Future<void> _locateMe() async {
    final strings = AppLocalizations.of(context);

    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _showLocationUnavailable(strings);
      return;
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      _showLocationUnavailable(strings);
      return;
    }

    if (!mounted) return;
    setState(() => _locationGranted = true);
    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );
      await _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(
          LatLng(position.latitude, position.longitude),
          14,
        ),
      );
      await _load(latitude: position.latitude, longitude: position.longitude);
    } catch (_) {
      _showLocationUnavailable(strings);
    }
  }

  void _showLocationUnavailable(AppLocalizations strings) {
    if (!mounted) return;
    showFriendlyErrorSnackBar(context, strings.mapLocationUnavailable);
  }
}

class _EmptyStreamsState extends StatelessWidget {
  const _EmptyStreamsState({
    required this.title,
    required this.body,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String body;
  final String? actionLabel;
  final VoidCallback? onAction;

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
              title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              body,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            if (actionLabel != null) ...<Widget>[
              const SizedBox(height: AppSpacing.md),
              TextButton(onPressed: onAction, child: Text(actionLabel!)),
            ],
          ],
        ),
      ),
    );
  }
}
