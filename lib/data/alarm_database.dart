import 'dart:async';
import 'dart:convert';

import 'package:alarm/alarm.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/alarm_model.dart';

/// The cloud side of alarm storage. Swappable so the sync logic can be tested
/// without a network.
abstract class AlarmRemote {
  Future<int> insert(Map<String, dynamic> data);
  Future<void> update(int remoteId, Map<String, dynamic> data);
  Future<void> delete(int remoteId);
  Future<List<Map<String, dynamic>>> fetchAll();
}

class SupabaseAlarmRemote implements AlarmRemote {
  SupabaseClient get _client => Supabase.instance.client;

  @override
  Future<int> insert(Map<String, dynamic> data) async {
    final response =
        await _client.from('alarms').insert(data).select('id').single();

    return (response['id'] as num).toInt();
  }

  @override
  Future<void> update(int remoteId, Map<String, dynamic> data) async {
    await _client.from('alarms').update(data).eq('id', remoteId);
  }

  @override
  Future<void> delete(int remoteId) async {
    await _client.from('alarms').delete().eq('id', remoteId);
  }

  @override
  Future<List<Map<String, dynamic>>> fetchAll() async {
    final response = await _client
        .from('alarms')
        .select()
        .order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(response);
  }
}

/// Alarms live on the phone first, so saving, editing, deleting and ringing
/// never depend on internet. Changes are copied to Supabase in the background
/// and retried whenever the connection is back.
///
/// Local ids: alarms pulled from Supabase keep their Supabase id (so alarms
/// scheduled by earlier app versions stay valid). Alarms created on the phone
/// get ids from [firstLocalId] upwards, which can never collide with them.
class AlarmDatabase {
  static const String _storeKey = 'alarmx_alarm_store_v2';
  static const String _nextIdKey = 'alarmx_next_local_id';
  static const int firstLocalId = 1000000001;

  /// Bumped when a background sync changed what is stored locally, so the
  /// home screen knows to reload.
  static final ValueNotifier<int> syncVersion = ValueNotifier<int>(0);

  static AlarmDatabase? _shared;

  final AlarmRemote _remote;

  AlarmDatabase._(this._remote);

  /// Every screen asks for `AlarmDatabase()`; they all share one instance so
  /// the lock and sync state are shared too.
  factory AlarmDatabase({AlarmRemote? remote}) {
    if (remote != null) return AlarmDatabase._(remote);

    return _shared ??= AlarmDatabase._(SupabaseAlarmRemote());
  }

  // ---------------------------------------------------------------
  // Serialising access: SharedPreferences read-modify-write must not
  // interleave between the UI and the background sync.
  // ---------------------------------------------------------------

  Future<void> _lock = Future.value();

  Future<T> _locked<T>(Future<T> Function() action) {
    final result = _lock.then((_) => action());
    _lock = result.then((_) {}, onError: (_) {});
    return result;
  }

  Future<bool>? _running;
  bool _resyncRequested = false;

  // ---------------------------------------------------------------
  // Value conversion (unchanged rules from the Supabase-only version)
  // ---------------------------------------------------------------

  String _convertChallengeType(dynamic value) {
    if (value == null) return 'none';

    final normalized = value.toString().toLowerCase().trim();

    if (normalized == 'none' ||
        normalized == 'no challenge' ||
        normalized.isEmpty) {
      return 'none';
    }

    if (normalized.startsWith('math')) return 'math';
    if (normalized.startsWith('puzzle')) return 'puzzle';
    if (normalized.startsWith('jigsaw')) return 'jigsaw';

    if (normalized == 'color_memory' ||
        normalized == 'color memory' ||
        normalized == 'color memory challenge') {
      return 'color_memory';
    }

    if (normalized == 'camera' ||
        normalized == 'camera challenge' ||
        normalized == 'picture' ||
        normalized == 'picture challenge' ||
        normalized == 'picture_test') {
      return 'camera';
    }

    return 'none';
  }

  String _convertJigsawDifficulty(dynamic value) {
    if (value == null) return 'Medium';

    final normalized = value.toString().trim().toLowerCase();

    if (normalized == 'easy') return 'Easy';
    if (normalized == 'hard') return 'Hard';

    return 'Medium';
  }

  List<String> _convertCameraObjects(dynamic value) {
    if (value == null) return [];

    if (value is List) {
      return value
          .map((item) => item.toString())
          .where((item) => item.trim().isNotEmpty)
          .toList();
    }

    if (value is String && value.trim().isNotEmpty) {
      try {
        final decoded = jsonDecode(value);

        if (decoded is List) {
          return decoded
              .map((item) => item.toString())
              .where((item) => item.trim().isNotEmpty)
              .toList();
        }
      } catch (_) {
        return [];
      }
    }

    return [];
  }

  Map<String, dynamic> _prepareAlarmData(Map<String, dynamic> alarmData) {
    return {
      'hour': alarmData['hour'],
      'minute': alarmData['minute'],
      'label': alarmData['label'],
      'repeat_days': alarmData['repeat_days'],
      'sound_name': alarmData['sound_name'],
      'snooze_enabled': alarmData['snooze_enabled'],
      'snooze_minutes': alarmData['snooze_minutes'],
      'challenge_type': _convertChallengeType(alarmData['challenge_type']),
      'jigsaw_difficulty':
          _convertJigsawDifficulty(alarmData['jigsaw_difficulty']),
      'is_enabled': alarmData['is_enabled'],
      'camera_objects': _convertCameraObjects(alarmData['camera_objects']),
    };
  }

  // ---------------------------------------------------------------
  // Local store. Each entry:
  //   { id, remote_id?, dirty, deleted, ...alarm fields }
  // ---------------------------------------------------------------

  Future<List<Map<String, dynamic>>> _readStore() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_storeKey);

      if (raw == null) return [];

      return (jsonDecode(raw) as List)
          .map((item) => Map<String, dynamic>.from(item as Map))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> _writeStore(List<Map<String, dynamic>> entries) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storeKey, jsonEncode(entries));
  }

  Future<int> _newLocalId(List<Map<String, dynamic>> entries) async {
    final prefs = await SharedPreferences.getInstance();

    var next = prefs.getInt(_nextIdKey) ?? firstLocalId;

    // Never reuse an id that is still in the store.
    final used = entries.map((e) => e['id']).toSet();
    while (used.contains(next)) {
      next++;
    }

    await prefs.setInt(_nextIdKey, next + 1);

    return next;
  }

  Map<String, dynamic> _publicRow(Map<String, dynamic> entry) {
    return {
      'id': entry['id'],
      ..._prepareAlarmData(entry),
    };
  }

  // ---------------------------------------------------------------
  // Public API (same shape as before)
  // ---------------------------------------------------------------

  Future<int> addAlarm(Map<String, dynamic> alarmData) async {
    final data = _prepareAlarmData(alarmData);

    final id = await _locked(() async {
      final entries = await _readStore();
      final newId = await _newLocalId(entries);

      entries.add({
        'id': newId,
        'remote_id': null,
        'dirty': true,
        'deleted': false,
        ...data,
      });

      await _writeStore(entries);

      return newId;
    });

    unawaited(syncNow());

    return id;
  }

  /// Returns the alarms stored on the phone immediately and, unless
  /// [sync] is false, starts a background sync with Supabase.
  Future<List<Map<String, dynamic>>> getAlarms({bool sync = true}) async {
    final entries = await _locked(_readStore);

    if (sync) unawaited(syncNow());

    return entries
        .where((e) => e['deleted'] != true)
        .map(_publicRow)
        .toList();
  }

  Future<void> updateAlarm(
    int id,
    Map<String, dynamic> alarmData,
  ) async {
    final data = _prepareAlarmData(alarmData);

    await _locked(() async {
      final entries = await _readStore();
      final index = entries.indexWhere((e) => e['id'] == id);

      if (index == -1) {
        // Unknown locally (e.g. very old row): keep it as a local entry.
        entries.add({
          'id': id,
          'remote_id': id < firstLocalId ? id : null,
          'dirty': true,
          'deleted': false,
          ...data,
        });
      } else {
        entries[index] = {
          ...entries[index],
          ...data,
          'dirty': true,
        };
      }

      await _writeStore(entries);
    });

    unawaited(syncNow());
  }

  Future<void> deleteAlarm(int id) async {
    await _locked(() async {
      final entries = await _readStore();
      final index = entries.indexWhere((e) => e['id'] == id);

      if (index == -1) return;

      if (entries[index]['remote_id'] == null) {
        // Never reached the cloud, so nothing to delete there.
        entries.removeAt(index);
      } else {
        entries[index] = {...entries[index], 'deleted': true, 'dirty': true};
      }

      await _writeStore(entries);
    });

    unawaited(syncNow());
  }

  AlarmModel convertToAlarmModel(Map<String, dynamic> data) {
    return AlarmModel.fromMap(data);
  }

  // ---------------------------------------------------------------
  // Background sync
  // ---------------------------------------------------------------

  /// Pushes local changes to Supabase, then pulls anything new from it.
  /// Safe to call at any time; it quietly does nothing when offline.
  /// Returns true when it completed and false when it could not.
  Future<bool> syncNow() {
    final running = _running;

    if (running != null) {
      // A change arrived mid-sync: share the running sync, and make it run
      // once more so that change is included.
      _resyncRequested = true;
      return running;
    }

    return _running = _syncLoop().whenComplete(() => _running = null);
  }

  Future<bool> _syncLoop() async {
    var ok = true;

    do {
      _resyncRequested = false;
      ok = await _syncOnce();
    } while (_resyncRequested && ok);

    return ok;
  }

  Future<bool> _syncOnce() async {
    try {
      var changed = false;

      // ---- push ----
      final pending = await _locked(_readStore);

      for (final entry in pending) {
        if (entry['dirty'] != true) continue;

        final id = entry['id'] as int;
        final remoteId = entry['remote_id'] as int?;

        if (entry['deleted'] == true) {
          if (remoteId != null) await _remote.delete(remoteId);

          await _locked(() async {
            final entries = await _readStore();
            entries.removeWhere((e) => e['id'] == id);
            await _writeStore(entries);
          });

          continue;
        }

        final data = _prepareAlarmData(entry);

        if (remoteId == null) {
          final newRemoteId = await _remote.insert(data);

          await _locked(() async {
            final entries = await _readStore();
            final i = entries.indexWhere((e) => e['id'] == id);

            if (i != -1) {
              entries[i] = {
                ...entries[i],
                'remote_id': newRemoteId,
                // Edited again while the insert was in flight? stay dirty.
                'dirty': _changedSince(entries[i], data),
              };
              await _writeStore(entries);
            }
          });

          changed = true;
        } else {
          await _remote.update(remoteId, data);

          await _locked(() async {
            final entries = await _readStore();
            final i = entries.indexWhere((e) => e['id'] == id);

            if (i != -1) {
              entries[i] = {
                ...entries[i],
                'dirty': _changedSince(entries[i], data),
              };
              await _writeStore(entries);
            }
          });
        }
      }

      // ---- pull ----
      final remoteRows = await _remote.fetchAll();
      final stopped = <int>[];

      await _locked(() async {
        final entries = await _readStore();
        final remoteIds = <int>{};

        for (final row in remoteRows) {
          final remoteId = (row['id'] as num).toInt();
          remoteIds.add(remoteId);

          final i = entries.indexWhere((e) => e['remote_id'] == remoteId);
          final data = _prepareAlarmData(row);

          if (i == -1) {
            // Alarm we have never seen: adopt it under its Supabase id.
            if (entries.any((e) => e['id'] == remoteId)) continue;

            entries.add({
              'id': remoteId,
              'remote_id': remoteId,
              'dirty': false,
              'deleted': false,
              ...data,
            });
            changed = true;
          } else if (entries[i]['dirty'] != true) {
            if (jsonEncode(_prepareAlarmData(entries[i])) !=
                jsonEncode(data)) {
              entries[i] = {...entries[i], ...data};
              changed = true;
            }
          }
        }

        // Deleted elsewhere (and we have no unsent edits): remove here too.
        entries.removeWhere((e) {
          final remoteId = e['remote_id'] as int?;
          final gone = remoteId != null &&
              !remoteIds.contains(remoteId) &&
              e['dirty'] != true;

          if (gone) {
            stopped.add(e['id'] as int);
            changed = true;
          }

          return gone;
        });

        await _writeStore(entries);
      });

      for (final id in stopped) {
        try {
          await Alarm.stop(id);
        } catch (_) {}
      }

      if (changed) syncVersion.value++;

      return true;
    } catch (e) {
      // Offline or server problem: local data is untouched and the changes
      // stay marked dirty, so the next sync retries them.
      debugPrint('Alarm sync skipped: $e');
      return false;
    }
  }

  /// True when the stored entry no longer matches what was just uploaded.
  bool _changedSince(Map<String, dynamic> entry, Map<String, dynamic> sent) {
    return jsonEncode(_prepareAlarmData(entry)) != jsonEncode(sent);
  }
}
