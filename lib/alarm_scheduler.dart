import 'package:alarm/alarm.dart';

import 'models/alarm_model.dart';

/// The single place alarms are scheduled with the OS, so Add, Edit, toggle
/// and "repeat after ringing" all behave identically.
class AlarmScheduler {
  AlarmScheduler._();

 
static const Map<String, String> soundFiles = {
  'Journey': 'assets/3dabrar-funny-alarm-317531.mp3',
  'Radar': 'assets/8footdino_on_scratch-alarm-301729.mp3',
  'Sencha': 'assets/alexzavesa-calm-elegant-logo-519008.mp3',
  'Silk': 'assets/audiorezout-dark-future-logo-196217.mp3',
  'Summit': 'assets/dragon-studio-clock-ticking-sfx-467486.mp3',
  'Classic': 'assets/freesound_community-cinematic-intro-6097.mp3',
  'Pulse': 'assets/freesound_community-alarm-beep-34359.mp3',
  'Echo': 'assets/freesound_community-random-beep-76811.mp3',
  'Siren': 'assets/jeremayjimenez-bermuda-eas-alarm-2025-my-own-alarm-441470.mp3',
  'Tropic': 'assets/lesiakower-tropical-alarm-clock-168821.mp3',
};


  static bool isRepeating(String repeatDays) {
    final value = repeatDays.trim().toLowerCase();
    return value == 'every day' ||
        value == 'weekdays' ||
        value == 'weekends';
  }

  static bool _runsOn(String repeatDays, int weekday) {
    switch (repeatDays.trim().toLowerCase()) {
      case 'weekdays':
        return weekday >= DateTime.monday && weekday <= DateTime.friday;
      case 'weekends':
        return weekday == DateTime.saturday || weekday == DateTime.sunday;
      default:
        return true;
    }
  }

  /// The next moment strictly after [from] that matches the alarm's time
  /// and repeat rule.
  static DateTime nextOccurrence(
    int hour,
    int minute,
    String repeatDays, {
    DateTime? from,
  }) {
    final now = from ?? DateTime.now();

    for (var offset = 0; offset <= 8; offset++) {
      final day = DateTime(now.year, now.month, now.day + offset);
      final candidate = DateTime(day.year, day.month, day.day, hour, minute);

      if (candidate.isAfter(now) && _runsOn(repeatDays, candidate.weekday)) {
        return candidate;
      }
    }

    // Unreachable (a matching day always exists within a week).
    return DateTime(now.year, now.month, now.day + 1, hour, minute);
  }

  /// Replaces any existing OS alarm with this model's schedule.
  static Future<DateTime> schedule(AlarmModel alarm) async {
    final id = alarm.id;

    if (id == null) {
      throw StateError('Cannot schedule an alarm without an id.');
    }

    try {
      await Alarm.stop(id);
    } catch (_) {}

    final when = nextOccurrence(
      alarm.hour,
      alarm.minute,
      alarm.repeatDays,
    );

    final title = alarm.label.trim().isEmpty ? 'AlarmX' : alarm.label.trim();

    await Alarm.set(
      alarmSettings: AlarmSettings(
        id: id,
        dateTime: when,
        assetAudioPath:
            soundFiles[alarm.soundName] ?? soundFiles['Journey']!,
        loopAudio: true,
        vibrate: true,
        androidFullScreenIntent: true,
        volumeSettings: const VolumeSettings.fixed(
          volume: null,
          volumeEnforced: false,
        ),
        androidSnoozeDuration: alarm.snoozeEnabled
            ? Duration(minutes: alarm.snoozeMinutes)
            : null,
        notificationSettings: NotificationSettings(
          title: title,
          body: 'Time to wake up!',
          // A Stop button would let the user skip the wake-up challenge.
          stopButton: alarm.challengeType == 'none' ? 'Stop' : null,
          androidSnoozeButton: alarm.snoozeEnabled ? 'Snooze' : null,
        ),
      ),
    );

    return when;
  }
}
