import 'dart:convert';

import 'assessment_content_source.dart';
import 'live_api_client.dart';
import 'repository_models.dart';

abstract interface class ReferenceRepository {
  Future<List<ReferenceValue>> valuesFor(String category);
}

const Map<String, String> _contentKeys = <String, String>{
  'channel_forms': 'channelForms',
  'channel_types': 'channelTypes',
  'bank_types': 'bankTypes',
  'habitats': 'habitats',
  'fallen_biomass': 'fallenBiomass',
  'water_flows': 'waterFlows',
  'water_colors': 'waterColors',
  'vegetation_types': 'vegetationTypes',
  'stream_assessments': 'streamAssessments',
};

class DemoReferenceRepository implements ReferenceRepository {
  DemoReferenceRepository({AssessmentContentSource? contentSource})
    : _contentSource = contentSource ?? AssessmentContentSource();

  final AssessmentContentSource _contentSource;

  @override
  Future<List<ReferenceValue>> valuesFor(String category) async {
    final key = _contentKeys[category];
    if (key == null) return const <ReferenceValue>[];
    final content = await _contentSource.load();
    final referenceData = content['referenceData'];
    if (referenceData is! Map) return const <ReferenceValue>[];
    return _decodeValues(referenceData[key]);
  }
}

class LiveReferenceRepository implements ReferenceRepository {
  LiveReferenceRepository({required LiveApiClient api}) : _api = api;

  final LiveApiClient _api;

  @override
  Future<List<ReferenceValue>> valuesFor(String category) async {
    if (!_contentKeys.containsKey(category)) {
      return const <ReferenceValue>[];
    }
    final response = await _api.get('/api/citizens/$category');
    return _decodeValues(jsonDecode(response.body));
  }
}

List<ReferenceValue> _decodeValues(Object? raw) {
  if (raw is! List) return const <ReferenceValue>[];
  return raw.whereType<Map>().map((value) {
    final json = Map<String, dynamic>.from(value);
    return ReferenceValue(
      code: json['code'].toString(),
      name: json['name'].toString(),
      description: json['description'] as String?,
    );
  }).toList(growable: false);
}
