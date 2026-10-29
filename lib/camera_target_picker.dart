import 'dart:math';

import 'package:shared_preferences/shared_preferences.dart';

/// Chooses which object the Camera Challenge asks for.
///
/// Plain random picks can repeat the same object several mornings in a row.
/// This uses a "shuffle bag": every selected object is used once, in random
/// order, before any object repeats, and the first pick of a new round is never
/// the object that was just used. The bag is remembered between alarms.
class CameraTargetPicker {
  CameraTargetPicker._();

  static const String _bagKey = 'alarmx_camera_bag';
  static const String _lastKey = 'alarmx_camera_last';

  static Future<String> pick(
    List<String> selected, {
    Random? random,
  }) async {
    if (selected.isEmpty) {
      throw ArgumentError('No camera objects to pick from.');
    }

    final rng = random ?? Random();

    if (selected.length == 1) return selected.first;

    SharedPreferences? prefs;
    var bag = <String>[];
    String? last;

    try {
      prefs = await SharedPreferences.getInstance();
      bag = List<String>.from(prefs.getStringList(_bagKey) ?? const []);
      last = prefs.getString(_lastKey);
    } catch (_) {
      // Storage unavailable: still random, just without the memory.
    }

    // Forget anything that is no longer selected for this alarm.
    bag.removeWhere((object) => !selected.contains(object));

    if (bag.isEmpty) {
      bag = List<String>.from(selected)..shuffle(rng);

      // Avoid asking for the same object twice in a row across rounds.
      if (bag.last == last && bag.length > 1) {
        final swapWith = rng.nextInt(bag.length - 1);
        final tmp = bag.last;
        bag[bag.length - 1] = bag[swapWith];
        bag[swapWith] = tmp;
      }
    }

    final choice = bag.removeLast();

    try {
      await prefs?.setStringList(_bagKey, bag);
      await prefs?.setString(_lastKey, choice);
    } catch (_) {}

    return choice;
  }
}
