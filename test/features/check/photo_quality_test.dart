import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:onehealth_ui/features/check/photo_quality.dart';

void main() {
  test('flags a dark, uniform image', () {
    final image = img.Image(width: 96, height: 96)..clear(img.ColorRgb8(8, 8, 8));

    final result = PhotoProcessor.analyze(image);

    expect(result.issues, contains(PhotoQualityIssue.tooDark));
    expect(result.issues, contains(PhotoQualityIssue.obstructed));
  });

  test('flags a bright image', () {
    final image = img.Image(width: 96, height: 96)
      ..clear(img.ColorRgb8(250, 250, 250));

    expect(
      PhotoProcessor.analyze(image).issues,
      contains(PhotoQualityIssue.tooBright),
    );
  });

  test('accepts a detailed, normally exposed checker pattern', () {
    final image = img.Image(width: 96, height: 96);
    for (var y = 0; y < image.height; y++) {
      for (var x = 0; x < image.width; x++) {
        final value = (x ~/ 3 + y ~/ 3).isEven ? 55 : 205;
        image.setPixelRgb(x, y, value, value, value);
      }
    }

    expect(PhotoProcessor.analyze(image).issues, isEmpty);
  });
}
