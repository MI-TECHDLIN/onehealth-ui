import 'dart:convert';
import 'dart:math' as math;

import 'package:http/http.dart' as http;

import 'live_api_client.dart';
import 'repository_models.dart';

abstract interface class SiteRepository {
  Future<List<StreamSite>> nearbySites({double? latitude, double? longitude});
  Future<List<StreamSite>> mySites();
  Future<StreamSite> createSite({
    required String name,
    required double latitude,
    required double longitude,
  });
}

class DemoSiteRepository implements SiteRepository {
  static const List<StreamSite> _sites = <StreamSite>[
    StreamSite(
      code: 'DEMO-RIVER-01',
      name: 'Willow Bend Stream',
      latitude: 41.444,
      longitude: -8.296,
      cityName: 'Guimarães',
    ),
    StreamSite(
      code: 'DEMO-BROOK-02',
      name: 'Old Mill Brook',
      latitude: 41.449,
      longitude: -8.289,
      cityName: 'Guimarães',
    ),
    StreamSite(
      code: 'DEMO-CREEK-03',
      name: 'Meadow Gate Creek',
      latitude: 41.452,
      longitude: -8.304,
      cityName: 'Guimarães',
    ),
    StreamSite(
      code: 'DEMO-URBAN-04',
      name: 'Market Quarter Channel',
      latitude: 41.439,
      longitude: -8.282,
      cityName: 'Guimarães',
    ),
  ];

  final List<StreamSite> _personalSites = <StreamSite>[];

  @override
  Future<List<StreamSite>> nearbySites({
    double? latitude,
    double? longitude,
  }) async => _sortByDistance(
    <StreamSite>[..._sites, ..._personalSites],
    latitude,
    longitude,
  );

  @override
  Future<List<StreamSite>> mySites() async =>
      List<StreamSite>.unmodifiable(_personalSites);

  @override
  Future<StreamSite> createSite({
    required String name,
    required double latitude,
    required double longitude,
  }) async {
    final site = StreamSite(
      code: 'DEMO-MY-${_personalSites.length + 1}',
      name: name,
      latitude: latitude,
      longitude: longitude,
      isUserGenerated: true,
    );
    _personalSites.add(site);
    return site;
  }
}

class LiveSiteRepository implements SiteRepository {
  LiveSiteRepository({required LiveApiClient api}) : _api = api;

  final LiveApiClient _api;

  @override
  Future<List<StreamSite>> nearbySites({
    double? latitude,
    double? longitude,
  }) async {
    final responses = await Future.wait(<Future<http.Response>>[
      _api.get('/api/sites/all'),
      _api.get('/api/sites/user-generated'),
    ]);
    final sites = <StreamSite>[
      ..._decodeSites(jsonDecode(responses[0].body)),
      ..._decodeSites(
        jsonDecode(responses[1].body),
        userGenerated: true,
      ),
    ];
    return _sortByDistance(sites, latitude, longitude);
  }

  @override
  Future<List<StreamSite>> mySites() async {
    final response = await _api.get(
      '/api/citizens/user-generated-sites/my-sites',
    );
    return _decodeSites(jsonDecode(response.body), userGenerated: true);
  }

  @override
  Future<StreamSite> createSite({
    required String name,
    required double latitude,
    required double longitude,
  }) async {
    final response = await _api.putJson(
      '/api/citizens/user-generated-sites/insert',
      <String, Object?>{
        'name': name,
        'latitude': latitude,
        'longitude': longitude,
      },
    );
    final text = response.body.trim();
    Object? decoded;
    try {
      decoded = jsonDecode(text);
    } on FormatException {
      decoded = text;
    }
    final code = decoded is Map
        ? (decoded['userSiteCode'] ?? decoded['code'] ?? decoded['id'])
              .toString()
        : decoded.toString();
    return StreamSite(
      code: code,
      name: name,
      latitude: latitude,
      longitude: longitude,
      isUserGenerated: true,
    );
  }
}

List<StreamSite> _decodeSites(Object? raw, {bool userGenerated = false}) {
  if (raw is! List) return const <StreamSite>[];
  return raw.whereType<Map>().map((value) {
    final json = Map<String, dynamic>.from(value);
    final city = json['city'];
    return StreamSite(
      code: (userGenerated ? json['userSiteCode'] : json['code']).toString(),
      name: json['name'].toString(),
      latitude: _coordinate(json['latitude']),
      longitude: _coordinate(json['longitude']),
      altitude: (json['altitude'] as num?)?.toDouble(),
      cityName: city is Map ? city['name']?.toString() : null,
      isUserGenerated: userGenerated,
    );
  }).toList(growable: false);
}

double _coordinate(Object? value) => value is num
    ? value.toDouble()
    : double.parse(value.toString());

List<StreamSite> _sortByDistance(
  List<StreamSite> sites,
  double? latitude,
  double? longitude,
) {
  if (latitude == null || longitude == null) {
    sites.sort((left, right) => left.name.compareTo(right.name));
    return List<StreamSite>.unmodifiable(sites);
  }
  final measured = sites
      .map(
        (site) => site.withDistance(
          _haversineKm(latitude, longitude, site.latitude, site.longitude),
        ),
      )
      .toList();
  measured.sort((left, right) => left.distanceKm!.compareTo(right.distanceKm!));
  return List<StreamSite>.unmodifiable(measured);
}

double _haversineKm(double lat1, double lon1, double lat2, double lon2) {
  const radiusKm = 6371.0088;
  final latitudeDelta = _radians(lat2 - lat1);
  final longitudeDelta = _radians(lon2 - lon1);
  final a =
      math.sin(latitudeDelta / 2) * math.sin(latitudeDelta / 2) +
      math.cos(_radians(lat1)) *
          math.cos(_radians(lat2)) *
          math.sin(longitudeDelta / 2) *
          math.sin(longitudeDelta / 2);
  return radiusKm * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
}

double _radians(double degrees) => degrees * math.pi / 180;
