import 'package:flutter_test/flutter_test.dart';
import 'package:onehealth_ui/core/map/site_markers.dart';
import 'package:onehealth_ui/features/home/stream_map_view.dart';

void main() {
  test('routes feature taps from every interactive stream-map layer', () {
    expect(
      <String>{
        SiteMapLayers.clusterCircleLayerId,
        SiteMapLayers.clusterCountLayerId,
        SiteMapLayers.siteCircleLayerId,
      }.every(isStreamMapInteractiveLayer),
      isTrue,
    );
    expect(isStreamMapInteractiveLayer('unrelated-style-layer'), isFalse);
  });
}
