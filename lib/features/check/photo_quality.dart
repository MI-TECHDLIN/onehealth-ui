import 'dart:isolate';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:image/image.dart' as img;

enum PhotoQualityIssue { tooDark, tooBright, blurry, obstructed }

class PhotoQualityResult {
  const PhotoQualityResult({
    required this.issues,
    required this.meanLuminance,
    required this.laplacianVariance,
    required this.uniformRegionFraction,
  });

  final Set<PhotoQualityIssue> issues;
  final double meanLuminance;
  final double laplacianVariance;
  final double uniformRegionFraction;

  bool get shouldSuggestRetake => issues.isNotEmpty;
}

class ProcessedPhoto {
  const ProcessedPhoto({required this.bytes, required this.quality});

  final Uint8List bytes;
  final PhotoQualityResult quality;
}

abstract final class PhotoProcessor {
  static const int maxDimension = 1600;

  static Future<ProcessedPhoto> process(Uint8List bytes) =>
      Isolate.run(() => processSync(bytes));

  static ProcessedPhoto processSync(Uint8List bytes) {
    final decoded = img.decodeImage(bytes);
    if (decoded == null) throw const FormatException('Unsupported image data.');
    final oriented = img.bakeOrientation(decoded);
    final longest = math.max(oriented.width, oriented.height);
    final compressedImage = longest > maxDimension
        ? img.copyResize(
            oriented,
            width: oriented.width >= oriented.height ? maxDimension : null,
            height: oriented.height > oriented.width ? maxDimension : null,
            interpolation: img.Interpolation.average,
          )
        : oriented;
    final qualityImage = img.copyResize(
      compressedImage,
      width: compressedImage.width >= compressedImage.height ? 320 : null,
      height: compressedImage.height > compressedImage.width ? 320 : null,
      interpolation: img.Interpolation.average,
    );
    return ProcessedPhoto(
      bytes: Uint8List.fromList(img.encodeJpg(compressedImage, quality: 85)),
      quality: analyze(qualityImage),
    );
  }

  static PhotoQualityResult analyze(img.Image image) {
    final width = image.width;
    final height = image.height;
    final luminance = List<double>.filled(width * height, 0);
    var sum = 0.0;
    var sumSquares = 0.0;
    for (var y = 0; y < height; y++) {
      for (var x = 0; x < width; x++) {
        final pixel = image.getPixel(x, y);
        final value =
            (0.2126 * pixel.r + 0.7152 * pixel.g + 0.0722 * pixel.b)
                .toDouble();
        luminance[y * width + x] = value;
        sum += value;
        sumSquares += value * value;
      }
    }
    final count = math.max(1, width * height);
    final mean = sum / count;

    var laplacianSum = 0.0;
    var laplacianSquares = 0.0;
    var laplacianCount = 0;
    for (var y = 1; y < height - 1; y++) {
      for (var x = 1; x < width - 1; x++) {
        final center = luminance[y * width + x];
        final laplacian = luminance[(y - 1) * width + x] +
            luminance[(y + 1) * width + x] +
            luminance[y * width + x - 1] +
            luminance[y * width + x + 1] -
            4 * center;
        laplacianSum += laplacian;
        laplacianSquares += laplacian * laplacian;
        laplacianCount++;
      }
    }
    final laplacianMean = laplacianCount == 0 ? 0 : laplacianSum / laplacianCount;
    final laplacianVariance = laplacianCount == 0
        ? 0.0
        : laplacianSquares / laplacianCount - laplacianMean * laplacianMean;
    final overallVariance = sumSquares / count - mean * mean;

    const grid = 4;
    var uniformTiles = 0;
    var tileCount = 0;
    for (var tileY = 0; tileY < grid; tileY++) {
      for (var tileX = 0; tileX < grid; tileX++) {
        final startX = tileX * width ~/ grid;
        final endX = (tileX + 1) * width ~/ grid;
        final startY = tileY * height ~/ grid;
        final endY = (tileY + 1) * height ~/ grid;
        var tileSum = 0.0;
        var tileSquares = 0.0;
        var samples = 0;
        for (var y = startY; y < endY; y++) {
          for (var x = startX; x < endX; x++) {
            final value = luminance[y * width + x];
            tileSum += value;
            tileSquares += value * value;
            samples++;
          }
        }
        if (samples > 0) {
          final tileMean = tileSum / samples;
          final variance = tileSquares / samples - tileMean * tileMean;
          if (variance < 18) uniformTiles++;
          tileCount++;
        }
      }
    }
    final uniformFraction = tileCount == 0 ? 1.0 : uniformTiles / tileCount;
    final issues = <PhotoQualityIssue>{};
    if (mean < 42) issues.add(PhotoQualityIssue.tooDark);
    if (mean > 225) issues.add(PhotoQualityIssue.tooBright);
    if (laplacianVariance < 55) issues.add(PhotoQualityIssue.blurry);
    if (uniformFraction >= 0.625 || overallVariance < 80) {
      issues.add(PhotoQualityIssue.obstructed);
    }
    return PhotoQualityResult(
      issues: Set<PhotoQualityIssue>.unmodifiable(issues),
      meanLuminance: mean,
      laplacianVariance: laplacianVariance,
      uniformRegionFraction: uniformFraction,
    );
  }
}
