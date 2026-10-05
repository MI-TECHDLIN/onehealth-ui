import '../../data/repositories/repository_models.dart';

/// Identifiers for the GeoJSON source/layers the stream map draws, shared
/// between the view that creates them and the tap handling that queries them.
abstract final class SiteMapLayers {
  static const String sourceId = 'oneaquahealth-sites';
  static const String clusterCircleLayerId = 'oneaquahealth-site-clusters';
  static const String clusterCountLayerId = 'oneaquahealth-site-cluster-count';
  static const String siteCircleLayerId = 'oneaquahealth-site-points';
}

/// MapLibre clustering options, matching the approved board's live preview
/// (`clusterMaxZoom: 13, clusterRadius: 52`) exactly.
abstract final class MapClusterConfig {
  static const int maxZoom = 13;
  static const double radius = 52;
}

/// Hex paint colors for the map layers. MapLibre layer paint properties take
/// plain hex strings, not [Color], so these mirror `AppColors` rather than
/// reading it directly.
abstract final class SiteMapColors {
  static const String deepWater = '#126B78';
  static const String sage = '#78A98A';
  static const String sparkle = '#FFE6AB';
  static const String navy = '#123047';
  static const String white = '#FFFFFF';
}

/// Builds the GeoJSON `FeatureCollection` fed to [SiteMapLayers.sourceId].
///
/// Each feature carries its site `code` (used to look the [StreamSite] back
/// up on tap) and a `visited` flag so the unclustered-point layer can color
/// already-checked sites differently without a second source.
Map<String, Object?> buildSiteFeatureCollection(
  List<StreamSite> sites,
  Set<String> visitedCodes,
) => <String, Object?>{
  'type': 'FeatureCollection',
  'features': <Object?>[
    for (final site in sites)
      <String, Object?>{
        'type': 'Feature',
        'geometry': <String, Object?>{
          'type': 'Point',
          'coordinates': <double>[site.longitude, site.latitude],
        },
        'properties': <String, Object?>{
          'code': site.code,
          'name': site.name,
          'visited': visitedCodes.contains(site.code),
          'userGenerated': site.isUserGenerated,
        },
      },
  ],
};
