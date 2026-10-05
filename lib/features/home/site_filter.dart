import '../../data/repositories/repository_models.dart';

/// The map's filter chips. "Needs data" and "Visited" are derived from the
/// signed-in citizen's own assessment history (the only "has this site been
/// checked" signal the client has access to — see `SiteDetailScreen`'s
/// freshness cue for the same constraint), not an aggregate across all
/// researchers.
enum SiteMapFilter { nearby, needsData, visited }

List<StreamSite> applySiteMapFilter(
  List<StreamSite> sites,
  Set<String> visitedCodes,
  SiteMapFilter filter,
) {
  switch (filter) {
    case SiteMapFilter.nearby:
      return sites;
    case SiteMapFilter.needsData:
      return sites
          .where((site) => !visitedCodes.contains(site.code))
          .toList(growable: false);
    case SiteMapFilter.visited:
      return sites
          .where((site) => visitedCodes.contains(site.code))
          .toList(growable: false);
  }
}
