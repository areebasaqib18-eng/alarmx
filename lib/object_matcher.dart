/// Decides whether the labels returned by ML Kit's on-device image labeler
/// mean "the user photographed [target]".
///
/// ML Kit's built-in model only knows ~400 generic labels ("Shoe", "Mobile
/// phone", "Tableware"...). Many of our target objects have no label of their
/// own, so each target lists every label that realistically shows up when
/// that object is in frame, with a minimum confidence per label.
library;

class DetectedLabel {
  final String label;
  final double confidence;

  const DetectedLabel(this.label, this.confidence);
}

/// A rule passes when EVERY (label, minConfidence) pair is present.
/// A target matches when ANY of its rules passes.
class _Rule {
  final Map<String, double> all;

  const _Rule(this.all);
}

/// Shortcut: a rule with a single label.
_Rule _one(String label, double min) => _Rule({label: min});

class MatchResult {
  final bool matched;

  /// The label(s) that triggered the match, for the on-screen/debug message.
  final String? reason;

  const MatchResult(this.matched, [this.reason]);
}

class ObjectMatcher {
  ObjectMatcher._();

  /// Lowest confidence worth asking ML Kit to report at all.
  static const double reportThreshold = 0.10;

  static String normalize(String value) {
    return value
        .toLowerCase()
        .replaceAll('_', ' ')
        .replaceAll('-', ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  /// Objects ML Kit's base model cannot reliably recognise. The matcher still
  /// tries (using indirect labels), but the UI offers a way out.
  static bool isHardToDetect(String target) {
    return _hard.contains(normalize(target));
  }

  static const Set<String> _hard = {
    'bottle cap',
    'comb',
    'headphones',
    'keys',
    'soap',
    'toothbrush',
    'toothpaste',
  };

  static MatchResult match(String target, List<DetectedLabel> detected) {
    final key = normalize(target);
    final rules = _rules[key];

    final byLabel = <String, double>{};
    for (final d in detected) {
      final name = normalize(d.label);
      final current = byLabel[name];
      if (current == null || d.confidence > current) {
        byLabel[name] = d.confidence;
      }
    }

    // Unknown target: fall back to the target's own name / plural / singular.
    final effectiveRules = rules ??
        [
          _one(key, 0.2),
          if (key.endsWith('s')) _one(key.substring(0, key.length - 1), 0.2),
          if (!key.endsWith('s')) _one('${key}s', 0.2),
        ];

    for (final rule in effectiveRules) {
      var ok = true;
      for (final entry in rule.all.entries) {
        final conf = byLabel[entry.key];
        if (conf == null || conf < entry.value) {
          ok = false;
          break;
        }
      }
      if (ok) return MatchResult(true, rule.all.keys.join(' + '));
    }

    return const MatchResult(false);
  }

  // Labels come from two models merged together: ML Kit's built-in model
  // (generic: "Shoe", "Tableware"...) and the bundled EfficientNet-Lite0
  // ImageNet model (specific: "ballpoint", "remote control", "tennis ball"...).
  // Minimum confidences are deliberately below what clean reference photos
  // score, because live camera shots are blurrier and worse lit.
  static final Map<String, List<_Rule>> _rules = {
    'bag': [
      _one('bag', 0.4), _one('handbag', 0.5), _one('backpack', 0.2),
      _one('luggage and bags', 0.2), _one('suitcase', 0.2),
      _one('mailbag', 0.15), _one('purse', 0.2), _one('shopping basket', 0.2),
      _one('briefcase', 0.2),
    ],
    'ball': [
      _one('ball', 0.15), _one('sports ball', 0.15), _one('football', 0.15),
      _one('tennis ball', 0.15), _one('golf ball', 0.15),
      _one('soccer ball', 0.15), _one('basketball', 0.15),
      _one('volleyball', 0.15), _one('baseball', 0.15),
      _one('rugby ball', 0.15), _one('ping pong ball', 0.15),
      _one('croquet ball', 0.15), _one('cricket ball', 0.15),
    ],
    'book': [
      _one('book', 0.15), _one('publication', 0.25), _one('paper', 0.6),
      _one('comics', 0.25), _one('book jacket', 0.05), _one('binder', 0.05),
      _one('comic book', 0.1), _one('notebook', 0.08),
    ],
    'bottle': [
      _one('bottle', 0.15), _one('water bottle', 0.1), _one('plastic bottle', 0.15),
      _one('glass bottle', 0.15), _one('wine bottle', 0.1), _one('beer bottle', 0.1),
      _one('pop bottle', 0.1), _one('pill bottle', 0.1), _one('bottled water', 0.15),
      _one('beaker', 0.25), _one('water jug', 0.2), _one('whiskey jug', 0.2),
      _one('drinkware', 0.3),
    ],
    'bottle cap': [
      _one('bottle cap', 0.1), _one('bottlecap', 0.03), _one('pill bottle', 0.05),
      _one('water bottle', 0.03), _one('pop bottle', 0.03),
    ],
    'chair': [
      _one('chair', 0.25), _one('armchair', 0.25), _one('furniture', 0.35),
      _one('stool', 0.25), _one('rocking chair', 0.15), _one('folding chair', 0.15),
      _one('barber chair', 0.15), _one('throne', 0.2), _one('armrest', 0.45),
    ],
    'comb': [
      _one('comb', 0.1), _one('hair slide', 0.1), _one('hair accessory', 0.15),
      _one('hairbrush', 0.1), _one('brush', 0.15),
    ],
    'cup': [
      _one('cup', 0.2), _one('mug', 0.25), _one('coffee cup', 0.25),
      _one('coffee mug', 0.1), _one('teacup', 0.25), _one('drinkware', 0.35),
      _one('saucer', 0.45), _one('espresso', 0.15),
    ],
    'glasses': [
      _one('glasses', 0.25), _one('eyewear', 0.25), _one('sunglasses', 0.35),
      _one('sunglass', 0.1), _one('goggles', 0.5), _one('spectacles', 0.25),
    ],
    'headphones': [
      _one('headphones', 0.1), _one('headset', 0.1), _one('earphone', 0.1),
      _one('audio equipment', 0.2), _one('microphone', 0.03),
      _one('loudspeaker', 0.02), _one('stethoscope', 0.03),
    ],
    'keyboard': [
      _one('computer keyboard', 0.15), _one('keyboard', 0.15), _one('space bar', 0.2),
      _one('typewriter keyboard', 0.08), _one('piano', 0.15),
      _Rule({'musical instrument': 0.6, 'computer': 0.3}),
    ],
    'keys': [
      _one('key', 0.1), _one('keychain', 0.1), _one('padlock', 0.03),
      _one('chime', 0.08), _one('bolo tie', 0.05), _one('safety pin', 0.03),
      _Rule({'metal': 0.5, 'jewellery': 0.25}),
    ],
    'laptop': [
      _one('laptop', 0.03), _one('netbook', 0.15), _one('personal computer', 0.2),
      _one('notebook', 0.25), _one('desktop computer', 0.08), _one('monitor', 0.08),
      _one('computer', 0.3), _one('television', 0.4),
    ],
    'mouse': [
      _one('mouse', 0.15), _one('computer mouse', 0.1), _one('input device', 0.15),
    ],
    'notebook': [
      _one('notebook', 0.1), _one('paper', 0.5), _one('publication', 0.25),
      _one('book', 0.15), _one('diary', 0.15), _one('binder', 0.03),
      _one('book jacket', 0.05), _one('stationery', 0.2), 
    ],
    'pen': [
      _one('pen', 0.1), _one('ballpoint', 0.1), _one('ballpoint pen', 0.1),
      _one('fountain pen', 0.1), _one('writing instrument', 0.1),
      _one('pencil', 0.1), _one('marker', 0.1), _one('quill', 0.1),
    ],
    'phone': [
      _one('mobile phone', 0.55), _one('cell phone', 0.25), _one('smartphone', 0.25),
      _one('telephone', 0.25), _one('phone', 0.25), _one('cellular telephone', 0.08),
      _one('ipod', 0.15), _one('dial telephone', 0.15), _one('hand held computer', 0.15),
      _one('communication device', 0.3),
    ],
    'pillow': [
      _one('pillow', 0.02), _one('cushion', 0.5), _one('bedding', 0.5),
      _one('quilt', 0.2), _one('bedroom', 0.5),
    ],
    'plate': [
      _one('plate', 0.02), _one('dishware', 0.25), _one('tableware', 0.45),
      _one('saucer', 0.45), _one('porcelain', 0.45), _one('platter', 0.2),
      _one('dish', 0.25),
    ],
    'remote': [
      _one('remote control', 0.2), _one('remote', 0.1), _one('electronic device', 0.2),
      _one('input device', 0.15),
    ],
    'shoes': [
      _one('shoe', 0.45), _one('footwear', 0.35), _one('sneakers', 0.4),
      _one('sandal', 0.1), _one('boot', 0.25), _one('running shoe', 0.1),
      _one('loafer', 0.05), _one('clog', 0.05), _one('cowboy boot', 0.1),
      _one('high heels', 0.25), _one('slipper', 0.25),
    ],
    'soap': [
      _one('soap', 0.1), _one('bar soap', 0.1), _one('soap dispenser', 0.05),
      _one('lotion', 0.02), _one('perfume', 0.1), _one('rubber eraser', 0.15),
      _one('personal care', 0.15), _one('cosmetics', 0.2),
    ],
    'spoon': [
      _one('spoon', 0.1), _one('wooden spoon', 0.05), _one('cutlery', 0.35),
      _one('ladle', 0.02), _one('spatula', 0.05), _one('fork', 0.1),
      _one('kitchen utensil', 0.1), _one('can opener', 0.08),
    ],
    'teddy bear': [
      _one('teddy bear', 0.1), _one('teddy', 0.2), _one('stuffed toy', 0.2),
      _one('plush', 0.25), _one('toy', 0.45), _one('bear', 0.3),
    ],
    'toothbrush': [
      _one('toothbrush', 0.05), _one('swab', 0.08), _one('paintbrush', 0.05),
      _one('oral hygiene', 0.1), _one('brush', 0.15),
      _Rule({'cutlery': 0.25, 'lipstick': 0.25}),
    ],
    'toothpaste': [
      _one('toothpaste', 0.05), _one('sunscreen', 0.03), _one('whistle', 0.1),
      _one('oral hygiene', 0.1), _one('lipstick', 0.3), _one('packet', 0.05),
    ],
    'towel': [
      _one('towel', 0.1), _one('bath towel', 0.1), _one('paper towel', 0.1),
      _one('textile', 0.45), _one('wool', 0.45), _one('linens', 0.2),
    ],
    'umbrella': [
      _one('umbrella', 0.2), _one('canopy', 0.3), _one('parasol', 0.2),
    ],
    'wallet': [
      _one('wallet', 0.1), _one('purse', 0.1), _one('coin purse', 0.1),
      _one('leather', 0.4), _one('fashion accessory', 0.3),
    ],
    'watch': [
      _one('watch', 0.2), _one('wristwatch', 0.2), _one('clock', 0.3),
      _one('analog clock', 0.1), _one('digital watch', 0.05), _one('stopwatch', 0.05),
      _one('magnetic compass', 0.15), _one('digital clock', 0.1), _one('wall clock', 0.1),
      _one('strap', 0.45), _Rule({'jewellery': 0.4, 'metal': 0.3}),
    ],
    
    'tree': [
      _one('tree', 0.15),
    ],
    'plant': [
      _one('plant', 0.15),
      _one('houseplant', 0.15),
      _one('potted plant', 0.15),
      _one('flowerpot', 0.20),
    ],
    'car': [
      _one('car', 0.15),
      _one('automobile', 0.15),
      _one('sports car', 0.15),
      _one('minivan', 0.15),
      _one('taxi', 0.15),
      _one('jeep', 0.15),
    ],
    'bike': [
      _one('motorcycle', 0.15),
      _one('motorbike', 0.15),
      _one('bicycle', 0.15),
      _one('mountain bike', 0.15),
      _one('bike', 0.15),
    ],
    'road': [
      _one('road', 0.15),
      _one('street', 0.15),
      _one('asphalt', 0.20),
      _one('highway', 0.15),
      _one('roadway', 0.15),
    ],

  };
}
