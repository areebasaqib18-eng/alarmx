import 'dart:io';

import 'package:alarmx/data/alarm_database.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FakeRemote implements AlarmRemote {
  final Map<int, Map<String, dynamic>> rows = {};
  bool offline = false;
  int _next = 1;
  int insertCalls = 0;

  void _check() {
    if (offline) throw const SocketException('Failed host lookup');
  }

  @override
  Future<int> insert(Map<String, dynamic> data) async {
    _check();
    insertCalls++;
    final id = _next++;
    rows[id] = {'id': id, ...data};
    return id;
  }

  @override
  Future<void> update(int remoteId, Map<String, dynamic> data) async {
    _check();
    rows[remoteId] = {'id': remoteId, ...data};
  }

  @override
  Future<void> delete(int remoteId) async {
    _check();
    rows.remove(remoteId);
  }

  @override
  Future<List<Map<String, dynamic>>> fetchAll() async {
    _check();
    return rows.values.map((r) => Map<String, dynamic>.from(r)).toList();
  }
}

Map<String, dynamic> alarmMap({int hour = 7, String label = 'Wake'}) => {
      'hour': hour,
      'minute': 30,
      'label': label,
      'repeat_days': 'Never',
      'sound_name': 'Journey',
      'snooze_enabled': true,
      'snooze_minutes': 9,
      'challenge_type': 'camera',
      'jigsaw_difficulty': 'Medium',
      'is_enabled': true,
      'camera_objects': ['Cup', 'Pen'],
    };

void main() {
  late FakeRemote remote;
  late AlarmDatabase db;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    remote = FakeRemote();
    db = AlarmDatabase(remote: remote);
  });

  test('saving works with no internet and uses a local id', () async {
    remote.offline = true;

    final id = await db.addAlarm(alarmMap());
    await db.syncNow();

    expect(id, greaterThanOrEqualTo(AlarmDatabase.firstLocalId));

    final alarms = await db.getAlarms(sync: false);
    expect(alarms, hasLength(1));
    expect(alarms.first['id'], id);
    expect(alarms.first['camera_objects'], ['Cup', 'Pen']);
    expect(remote.rows, isEmpty);
  });

  test('offline alarm is uploaded once the connection returns', () async {
    remote.offline = true;
    await db.addAlarm(alarmMap());
    await db.syncNow();

    remote.offline = false;
    expect(await db.syncNow(), isTrue);

    expect(remote.rows, hasLength(1));
    expect(remote.rows.values.first['label'], 'Wake');

    // A second sync must not upload it again.
    await db.syncNow();
    expect(remote.insertCalls, 1);
  });

  test('edits made offline are pushed later', () async {
    final id = await db.addAlarm(alarmMap());
    await db.syncNow();
    expect(remote.rows, hasLength(1));

    remote.offline = true;
    await db.updateAlarm(id, alarmMap(hour: 9, label: 'Gym'));
    await db.syncNow();
    expect(remote.rows.values.first['label'], 'Wake');

    remote.offline = false;
    await db.syncNow();
    expect(remote.rows.values.first['label'], 'Gym');
    expect(remote.rows.values.first['hour'], 9);

    final alarms = await db.getAlarms(sync: false);
    expect(alarms.single['label'], 'Gym');
  });

  test('deleting a never-uploaded alarm never touches the cloud', () async {
    remote.offline = true;
    final id = await db.addAlarm(alarmMap());
    await db.deleteAlarm(id);

    remote.offline = false;
    await db.syncNow();

    expect(await db.getAlarms(sync: false), isEmpty);
    expect(remote.rows, isEmpty);
    expect(remote.insertCalls, 0);
  });

  test('deleting an uploaded alarm offline is applied later', () async {
    final id = await db.addAlarm(alarmMap());
    await db.syncNow();

    remote.offline = true;
    await db.deleteAlarm(id);
    expect(await db.getAlarms(sync: false), isEmpty);
    await db.syncNow();
    expect(remote.rows, hasLength(1));

    remote.offline = false;
    await db.syncNow();
    expect(remote.rows, isEmpty);
  });

  test('alarms already in the cloud keep their id', () async {
    remote.rows[42] = {'id': 42, ...alarmMap(label: 'Old')};

    await db.syncNow();

    final alarms = await db.getAlarms(sync: false);
    expect(alarms.single['id'], 42);
    expect(alarms.single['label'], 'Old');
  });

  test('alarm deleted in the cloud disappears here', () async {
    remote.rows[5] = {'id': 5, ...alarmMap()};
    await db.syncNow();
    expect(await db.getAlarms(sync: false), hasLength(1));

    remote.rows.clear();
    await db.syncNow();
    expect(await db.getAlarms(sync: false), isEmpty);
  });

  test('local edit is not overwritten by an older cloud copy', () async {
    final id = await db.addAlarm(alarmMap());
    await db.syncNow();

    remote.offline = true;
    await db.updateAlarm(id, alarmMap(label: 'Edited offline'));
    await db.syncNow();

    remote.offline = false;
    await db.syncNow();

    final alarms = await db.getAlarms(sync: false);
    expect(alarms.single['label'], 'Edited offline');
  });

  test('local ids are unique', () async {
    remote.offline = true;
    final a = await db.addAlarm(alarmMap());
    final b = await db.addAlarm(alarmMap());
    expect(a, isNot(b));
  });
}
