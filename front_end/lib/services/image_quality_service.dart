import 'dart:typed_data';
import 'package:image/image.dart' as img;
import '../config/app_config.dart';

/// Client-side image quality check.
/// Computes sharpness via variance of Laplacian on a center crop.
class ImageQualityService {
  /// Check if the image is sharp enough for analysis.
  /// Returns (isSharp, sharpnessScore).
  static (bool, double) checkSharpness(Uint8List imageBytes) {
    try {
      final image = img.decodeImage(imageBytes);
      if (image == null) return (true, 999); // Can't decode → skip check

      final cropSize = AppConfig.sharpnessCropSize;
      final cx = image.width ~/ 2;
      final cy = image.height ~/ 2;
      final x0 = (cx - cropSize ~/ 2).clamp(0, image.width - cropSize);
      final y0 = (cy - cropSize ~/ 2).clamp(0, image.height - cropSize);

      final crop = img.copyCrop(
        image,
        x: x0,
        y: y0,
        width: cropSize,
        height: cropSize,
      );

      // Convert to grayscale
      final gray = img.grayscale(crop);

      // Compute variance of Laplacian (discrete approximation)
      double sum = 0;
      double sumSq = 0;
      int count = 0;

      for (int y = 1; y < gray.height - 1; y++) {
        for (int x = 1; x < gray.width - 1; x++) {
          final c = gray.getPixel(x, y).r.toDouble();
          final l = gray.getPixel(x - 1, y).r.toDouble();
          final r = gray.getPixel(x + 1, y).r.toDouble();
          final t = gray.getPixel(x, y - 1).r.toDouble();
          final b = gray.getPixel(x, y + 1).r.toDouble();
          final laplacian = -4 * c + l + r + t + b;
          sum += laplacian;
          sumSq += laplacian * laplacian;
          count++;
        }
      }

      if (count == 0) return (true, 999);

      final mean = sum / count;
      final variance = (sumSq / count) - (mean * mean);

      return (variance >= AppConfig.sharpnessThreshold, variance);
    } catch (_) {
      // On any error, skip the check and let the user proceed
      return (true, 999);
    }
  }
}
