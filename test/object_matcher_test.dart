import 'dart:io';

import 'package:alarmx/object_matcher.dart';
import 'package:flutter_test/flutter_test.dart';

/// Real model output for every file in assets/reference_images, captured on
/// the emulator (see lib/debug/label_dump.dart). Both models ran on each
/// photo and their labels are merged, exactly like the app does.
Map<String, List<DetectedLabel>> _loadFixture() {
  final out = <String, List<DetectedLabel>>{};
  final valid = RegExp(r':\d\.\d\d$');

  for (final path in [
    'test/fixtures/ml_kit_reference_labels.txt',
    'test/fixtures/ml_kit_custom_labels.txt',
  ]) {
    for (final line in File(path).readAsLinesSync()) {
      final parts = line.trim().split('|');
      if (parts.length < 3) continue;

      // logcat truncates long lines, so skip a cut-off last pair.
      out.putIfAbsent(parts[1], () => []).addAll(
        parts[2].split(',').where(valid.hasMatch).map((p) {
          final i = p.lastIndexOf(':');
          return DetectedLabel(
            p.substring(0, i),
            double.parse(p.substring(i + 1)),
          );
        }),
      );
    }
  }

  return out;
}

const Map<String, String> _fileToTarget = {
  'Keys.jpg': 'Keys',
  'bag.jpg': 'Bag',
  'ball.jpg': 'Ball',
  'book.jpg': 'Book',
  'bottle cap.jpg': 'Bottle Cap',
  'bottle.jpg': 'Bottle',
  'chair.jpg': 'Chair',
  'comb.jpg': 'Comb',
  'cup.jpg': 'Cup',
  'glasses.jpg': 'Glasses',
  'headphones.jpg': 'Headphones',
  'keyboard.jpg': 'Keyboard',
  'laptop.jpg': 'Laptop',
  'mouse.jpg': 'Mouse',
  'notebook.jpg': 'Notebook',
  'pen.jpg': 'Pen',
  'phone.jpg': 'Phone',
  'pillow.jpg': 'Pillow',
  'plate.jpg': 'Plate',
  'remote.jpg': 'Remote',
  'shoes.jpg': 'Shoes',
  'soap.jpg': 'Soap',
  'spoon.jpg': 'Spoon',
  'teddy_bear.jpg': 'Teddy Bear',
  'toothbrush.jpg': 'Toothbrush',
  'toothpaste.jpg': 'Toothpaste',
  'towel.jpg': 'Towel',
  'umbrella.jpg': 'Umbrella',
  'wallet.jpg': 'Wallet',
  'watch.jpg': 'Watch',
};

void main() {
  final fixture = _loadFixture();

  test('each reference photo passes for its own object', () {
    final failed = <String>[];
    for (final e in _fileToTarget.entries) {
      final labels = fixture[e.key]!;
      if (!ObjectMatcher.match(e.value, labels).matched) failed.add(e.value);
    }
    // ignore: avoid_print
    print('Own-object misses (${failed.length}/30): $failed');
    expect(failed, isEmpty);
  });

  test('report false-accept rate (photo of X accepted for target Y)', () {
    var accepts = 0;
    var total = 0;
    final perTarget = <String, int>{};
    for (final target in _fileToTarget.values) {
      for (final e in _fileToTarget.entries) {
        if (e.value == target) continue;
        total++;
        if (ObjectMatcher.match(target, fixture[e.key]!).matched) {
          accepts++;
          perTarget[target] = (perTarget[target] ?? 0) + 1;
        }
      }
    }
    // ignore: avoid_print
    print('False accepts: $accepts / $total  per target: $perTarget');
  });
}
