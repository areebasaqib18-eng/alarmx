import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_image_labeling/google_mlkit_image_labeling.dart';
import 'package:path_provider/path_provider.dart';

import 'object_matcher.dart';

/// Runs two on-device models on a photo and merges their labels:
///  * ML Kit's built-in labeler (generic labels such as "Shoe", "Tableware")
///  * the bundled EfficientNet-Lite0 ImageNet model (specific labels such as
///    "ballpoint", "remote control", "tennis ball")
class ObjectDetector {
  static const String _modelAsset = 'assets/models/efficientnet_lite0.tflite';

  ImageLabeler? _base;
  ImageLabeler? _custom;

  Future<void> init() async {
    _base = ImageLabeler(
      options: ImageLabelerOptions(
        confidenceThreshold: ObjectMatcher.reportThreshold,
      ),
    );

    try {
      final path = await _modelFilePath();

      _custom = ImageLabeler(
        options: LocalLabelerOptions(
          modelPath: path,
          confidenceThreshold: 0.02,
          maxCount: 15,
        ),
      );
    } catch (e) {
      // The built-in model alone still works, just with fewer objects.
      debugPrint('Custom model unavailable, using ML Kit only: $e');
    }
  }

  /// ML Kit needs a real file path, so the asset is copied out once.
  Future<String> _modelFilePath() async {
    final dir = await getApplicationSupportDirectory();
    final file = File('${dir.path}/efficientnet_lite0.tflite');
    final data = await rootBundle.load(_modelAsset);

    if (!await file.exists() || await file.length() != data.lengthInBytes) {
      await file.writeAsBytes(
        data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
        flush: true,
      );
    }

    return file.path;
  }

  Future<List<DetectedLabel>> detect(String photoPath) async {
    final input = InputImage.fromFilePath(photoPath);
    final byName = <String, DetectedLabel>{};

    for (final labeler in [_base, _custom]) {
      if (labeler == null) continue;

      try {
        final results = await labeler.processImage(input);

        for (final r in results) {
          final key = ObjectMatcher.normalize(r.label);
          final existing = byName[key];

          if (existing == null || r.confidence > existing.confidence) {
            byName[key] = DetectedLabel(r.label, r.confidence);
          }
        }
      } catch (e) {
        debugPrint('Labeler failed: $e');
      }
    }

    return byName.values.toList()
      ..sort((a, b) => b.confidence.compareTo(a.confidence));
  }

  Future<void> dispose() async {
    await _base?.close();
    await _custom?.close();
  }
}
