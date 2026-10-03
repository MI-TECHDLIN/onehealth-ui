import 'repository_models.dart';

abstract interface class ReferenceRepository {
  Future<List<ReferenceValue>> valuesFor(String category);
}

class DemoReferenceRepository implements ReferenceRepository {
  static const Map<String, List<ReferenceValue>> _values =
      <String, List<ReferenceValue>>{
        'stream_assessments': <ReferenceValue>[
          ReferenceValue(code: 'GOOD', name: 'Good quality'),
          ReferenceValue(code: 'MODERATE', name: 'Moderate quality'),
          ReferenceValue(code: 'POOR', name: 'Poor quality'),
        ],
      };

  @override
  Future<List<ReferenceValue>> valuesFor(String category) async =>
      _values[category] ?? const <ReferenceValue>[];
}
