import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

import '../../core/map/map_style.dart';
import '../../core/map/site_markers.dart';
import '../../data/repositories/repository_models.dart';

/// The MapLibre-backed map itself, isolated behind [StreamMapViewBuilder] so
/// widget tests can substitute a plain widget instead of standing up the
/// native MapLibre platform view (see `home_map_screen.dart`).
typedef StreamMapViewBuilder =
    Widget Function({
      required List<StreamSite> sites,
      required Set<String> visitedCodes,
      required bool myLocationEnabled,
      required ValueChanged<StreamSite> onSiteTapped,
      required ValueChanged<MapLibreMapController> onControllerReady,
    });

Widget buildDefaultStreamMapView({
  required List<StreamSite> sites,
  required Set<String> visitedCodes,
  required bool myLocationEnabled,
  required ValueChanged<StreamSite> onSiteTapped,
  required ValueChanged<MapLibreMapController> onControllerReady,
}) => StreamMapView(
  sites: sites,
  visitedCodes: visitedCodes,
  myLocationEnabled: myLocationEnabled,
  onSiteTapped: onSiteTapped,
  onControllerReady: onControllerReady,
);

class StreamMapView extends StatefulWidget {
  const StreamMapView({
    super.key,
    required this.sites,
    required this.visitedCodes,
    required this.onSiteTapped,
    required this.onControllerReady,
    this.myLocationEnabled = false,
  });

  final List<StreamSite> sites;
  final Set<String> visitedCodes;
  final bool myLocationEnabled;
  final ValueChanged<StreamSite> onSiteTapped;
  final ValueChanged<MapLibreMapController> onControllerReady;

  @override
  State<StreamMapView> createState() => _StreamMapViewState();
}

class _StreamMapViewState extends State<StreamMapView> {
  static const Duration _duplicateTapWindow = Duration(milliseconds: 300);

  MapLibreMapController? _controller;
  bool _styleReady = false;
  final Stopwatch _tapClock = Stopwatch()..start();
  math.Point<double>? _lastTapPoint;
  int? _lastTapMilliseconds;

  late final OnFeatureInteractionCallback _featureTapListener =
      _onFeatureTapped;

  @override
  void dispose() {
    _controller?.onFeatureTapped.remove(_featureTapListener);
    super.dispose();
  }

  @override
  void didUpdateWidget(StreamMapView oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Compared by content, not identity: the parent rebuilds the sites/
    // visited lists on every state change (e.g. selecting a pin), so an
    // identity check would re-feed the source on unrelated rebuilds.
    if (_styleReady &&
        (!_sameSites(oldWidget.sites, widget.sites) ||
            !_sameCodes(oldWidget.visitedCodes, widget.visitedCodes))) {
      unawaited(_updateSource());
    }
  }

  static bool _sameSites(List<StreamSite> a, List<StreamSite> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i].code != b[i].code) return false;
    }
    return true;
  }

  static bool _sameCodes(Set<String> a, Set<String> b) =>
      a.length == b.length && a.containsAll(b);

  @override
  Widget build(BuildContext context) {
    final target = _initialTarget();
    return MapLibreMap(
      styleString: MapStyleAssets.forBrightness(Theme.of(context).brightness),
      onMapCreated: _onMapCreated,
      onStyleLoadedCallback: _onStyleLoaded,
      initialCameraPosition: CameraPosition(target: target, zoom: 12),
      trackCameraPosition: true,
      compassEnabled: false,
      myLocationEnabled: widget.myLocationEnabled,
      onMapClick: _onMapClick,
      // Keeps the attribution control clear of the bottom sheet-style site
      // preview card, which is required to stay visible at all times.
      attributionButtonPosition: AttributionButtonPosition.topRight,
    );
  }

  LatLng _initialTarget() {
    if (widget.sites.isEmpty) {
      return const LatLng(41.4446, -8.2918); // Guimarães pilot area fallback.
    }
    final first = widget.sites.first;
    return LatLng(first.latitude, first.longitude);
  }

  void _onMapCreated(MapLibreMapController controller) {
    _controller?.onFeatureTapped.remove(_featureTapListener);
    _controller = controller;
    controller.onFeatureTapped.add(_featureTapListener);
    widget.onControllerReady(controller);
  }

  Future<void> _onStyleLoaded() async {
    final controller = _controller;
    if (controller == null) return;
    await controller.addSource(
      SiteMapLayers.sourceId,
      GeojsonSourceProperties(
        data: buildSiteFeatureCollection(widget.sites, widget.visitedCodes),
        cluster: true,
        clusterMaxZoom: MapClusterConfig.maxZoom,
        clusterRadius: MapClusterConfig.radius,
      ),
    );

    await controller.addCircleLayer(
      SiteMapLayers.sourceId,
      SiteMapLayers.clusterCircleLayerId,
      const CircleLayerProperties(
        circleRadius: <Object>[
          'step',
          <Object>['get', 'point_count'],
          20,
          10,
          26,
          25,
          32,
        ],
        circleColor: SiteMapColors.sparkle,
        circleStrokeWidth: 4,
        circleStrokeColor: SiteMapColors.white,
      ),
      filter: const <Object>['has', 'point_count'],
    );

    await controller.addSymbolLayer(
      SiteMapLayers.sourceId,
      SiteMapLayers.clusterCountLayerId,
      const SymbolLayerProperties(
        textField: <Object>['get', 'point_count_abbreviated'],
        textSize: 13,
        textColor: SiteMapColors.navy,
        textAllowOverlap: true,
      ),
      filter: const <Object>['has', 'point_count'],
    );

    await controller.addCircleLayer(
      SiteMapLayers.sourceId,
      SiteMapLayers.siteCircleLayerId,
      const CircleLayerProperties(
        circleRadius: 9,
        circleColor: <Object>[
          'case',
          <Object>[
            '==',
            <Object>['get', 'visited'],
            true,
          ],
          SiteMapColors.sage,
          SiteMapColors.deepWater,
        ],
        circleStrokeWidth: 2,
        circleStrokeColor: SiteMapColors.white,
      ),
      filter: const <Object>[
        '!',
        <Object>['has', 'point_count'],
      ],
    );

    _styleReady = true;
  }

  Future<void> _updateSource() async {
    final controller = _controller;
    if (controller == null) return;
    await controller.setGeoJsonSource(
      SiteMapLayers.sourceId,
      buildSiteFeatureCollection(widget.sites, widget.visitedCodes),
    );
  }

  Future<void> _onMapClick(math.Point<double> point, LatLng coordinates) async {
    await _handleMapTap(point, coordinates);
  }

  void _onFeatureTapped(
    dynamic _,
    math.Point<double> point,
    LatLng coordinates,
    String layerId,
  ) {
    if (!isStreamMapInteractiveLayer(layerId)) return;
    unawaited(_handleMapTap(point, coordinates));
  }

  Future<void> _handleMapTap(
    math.Point<double> point,
    LatLng coordinates,
  ) async {
    // Some MapLibre platforms may emit both callbacks for one interactive
    // feature. Collapse that pair before it can select or zoom twice.
    final now = _tapClock.elapsedMilliseconds;
    final lastTapMilliseconds = _lastTapMilliseconds;
    if (_lastTapPoint == point &&
        lastTapMilliseconds != null &&
        now - lastTapMilliseconds <= _duplicateTapWindow.inMilliseconds) {
      return;
    }
    _lastTapPoint = point;
    _lastTapMilliseconds = now;

    final controller = _controller;
    if (controller == null) return;
    final features = await controller.queryRenderedFeatures(point, <String>[
      SiteMapLayers.clusterCircleLayerId,
      SiteMapLayers.siteCircleLayerId,
    ], null);
    if (features.isEmpty) return;

    final feature = features.first as Map;
    final properties =
        (feature['properties'] as Map?) ?? const <String, Object?>{};

    if (properties.containsKey('point_count')) {
      await _zoomIntoCluster(controller, feature, properties, coordinates);
      return;
    }

    final code = properties['code']?.toString();
    if (code == null) return;
    final site = widget.sites.where((site) => site.code == code).firstOrNull;
    if (site != null) widget.onSiteTapped(site);
  }

  Future<void> _zoomIntoCluster(
    MapLibreMapController controller,
    Map feature,
    Map properties,
    LatLng tapCoordinates,
  ) async {
    final clusterId = (properties['cluster_id'] as num?)?.toInt();
    if (clusterId == null) return;
    final expansionZoom = ((controller.cameraPosition?.zoom ?? 12) + 2)
        .clamp(0, 22)
        .toDouble();
    final coordinates = (feature['geometry'] as Map?)?['coordinates'];
    final target = coordinates is List && coordinates.length >= 2
        ? LatLng(
            (coordinates[1] as num).toDouble(),
            (coordinates[0] as num).toDouble(),
          )
        : tapCoordinates;
    await controller.animateCamera(
      CameraUpdate.newLatLngZoom(target, expansionZoom),
    );
  }
}

/// Whether a MapLibre feature callback belongs to a layer whose tap should be
/// routed through the stream-map rendered-feature query.
bool isStreamMapInteractiveLayer(String layerId) =>
    layerId == SiteMapLayers.clusterCircleLayerId ||
    layerId == SiteMapLayers.clusterCountLayerId ||
    layerId == SiteMapLayers.siteCircleLayerId;

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
