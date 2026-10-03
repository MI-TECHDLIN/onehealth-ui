import 'repository_models.dart';

abstract interface class SiteRepository {
  Future<List<StreamSite>> nearbySites();
  Future<List<StreamSite>> mySites();
}

class DemoSiteRepository implements SiteRepository {
  static const List<StreamSite> _sites = <StreamSite>[
    StreamSite(
      code: 'DEMO-RIVER-01',
      name: 'Willow Bend Stream',
      latitude: 41.444,
      longitude: -8.296,
    ),
    StreamSite(
      code: 'DEMO-BROOK-02',
      name: 'Old Mill Brook',
      latitude: 41.449,
      longitude: -8.289,
    ),
  ];

  @override
  Future<List<StreamSite>> nearbySites() async => _sites;

  @override
  Future<List<StreamSite>> mySites() async => const <StreamSite>[];
}
