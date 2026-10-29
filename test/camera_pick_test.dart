import 'package:alarmx/camera_target_picker.dart';
import 'package:alarmx/data/alarm_database.dart';
import 'package:alarmx/models/alarm_model.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _NoRemote implements AlarmRemote {
  @override
  Future<int> insert(Map<String, dynamic> data) async => throw Exception('x');
  @override
  Future<void> update(int remoteId, Map<String, dynamic> data) async =>
      throw Exception('x');
  @override
  Future<void> delete(int remoteId) async => throw Exception('x');
  @override
  Future<List<Map<String, dynamic>>> fetchAll() async => throw Exception('x');
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('selected objects survive save and reload through the real path',
      () async {
    final db = AlarmDatabase(remote: _NoRemote());

    final model = AlarmModel(
      hour: 7,
      minute: 0,
      label: '',
      repeatDays: 'Never',
      soundName: 'Journey',
      snoozeEnabled: true,
      snoozeMinutes: 9,
      challengeType: 'camera',
      jigsawDifficulty: 'Medium',
      isEnabled: true,
      cameraObjects: ['Cup', 'Pen', 'Phone', 'Shoes'],
    );

    await db.addAlarm(model.toMap());
    final rows = await db.getAlarms(sync: false);
    final loaded = AlarmModel.fromMap(rows.single);

    expect(loaded.cameraObjects, ['Cup', 'Pen', 'Phone', 'Shoes']);
  });

  group('CameraTargetPicker', () {
    test('uses every selected object before repeating any', () async {
      final objects = ['Cup', 'Pen', 'Phone', 'Shoes', 'Mouse'];
      final picks = <String>[];
      for (var i = 0; i < 5; i++) {
        picks.add(await CameraTargetPicker.pick(objects));
      }
      expect(picks.toSet(), objects.toSet());
    });

    test('never repeats the same object back to back', () async {
      final objects = ['Cup', 'Pen', 'Phone'];
      String? previous;
      for (var i = 0; i < 60; i++) {
        final p = await CameraTargetPicker.pick(objects);
        expect(p, isNot(previous));
        previous = p;
      }
    });

    test('picks are spread evenly, with no favourite object', () async {
      final objects = ['Cup', 'Pen', 'Phone', 'Shoes'];
      final counts = <String, int>{};
      for (var i = 0; i < 400; i++) {
        final p = await CameraTargetPicker.pick(objects);
        counts[p] = (counts[p] ?? 0) + 1;
      }
      for (final o in objects) {
        expect(counts[o], 100);
      }
    });

    test('handles a single object and a changed selection', () async {
      expect(await CameraTargetPicker.pick(['Phone']), 'Phone');
      await CameraTargetPicker.pick(['Cup', 'Pen', 'Mouse']);
      final p = await CameraTargetPicker.pick(['Shoes', 'Chair']);
      expect(['Shoes', 'Chair'], contains(p));
    });
  });
}
