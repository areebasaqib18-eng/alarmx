
import 'dart:convert';

class AlarmModel {
  final int? id;
  final int hour;
  final int minute;
  final String label;
  final String repeatDays;
  final String soundName;
  final bool snoozeEnabled;
  final int snoozeMinutes;
  final String challengeType;
  final String jigsawDifficulty;
  final bool isEnabled;

  // Objects selected for Camera Challenge
  final List<String> cameraObjects;

  AlarmModel({
    this.id,
    required this.hour,
    required this.minute,
    required this.label,
    required this.repeatDays,
    required this.soundName,
    required this.snoozeEnabled,
    required this.snoozeMinutes,
    required this.challengeType,
    this.jigsawDifficulty = 'Medium',
    required this.isEnabled,
    this.cameraObjects = const [],
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'hour': hour,
      'minute': minute,
      'label': label,
      'repeat_days': repeatDays,
      'sound_name': soundName,
      'snooze_enabled': snoozeEnabled,
      'snooze_minutes': snoozeMinutes,
      'challenge_type': challengeType,
      'jigsaw_difficulty': jigsawDifficulty,
      'is_enabled': isEnabled,

      // SQLite stores the list as a JSON string.
      'camera_objects': jsonEncode(cameraObjects),
    };
  }

  factory AlarmModel.fromMap(Map<String, dynamic> map) {
    final rawChallenge = map['challenge_type'];

    String challenge;

    if (rawChallenge == null) {
      challenge = 'none';
    } else {
      final value = rawChallenge.toString().trim().toLowerCase();

      if (value == 'math' || value == 'math challenge') {
        challenge = 'math';
      } else if (value == 'puzzle' ||
          value == 'puzzle challenge') {
        challenge = 'puzzle';
      } else if (value == 'jigsaw' ||
          value == 'jigsaw puzzle' ||
          value == 'jigsaw challenge' ||
          value == 'jigsaw_puzzle' ||
          value == 'jigsaw_easy' ||
          value == 'jigsaw_medium' ||
          value == 'jigsaw_hard') {
        challenge = value;
      } else if (value == 'color memory' ||
          value == 'color_memory' ||
          value == 'color memory challenge') {
        challenge = 'color_memory';
      } else if (value == 'camera' ||
          value == 'camera challenge' ||
          value == 'picture' ||
          value == 'picture challenge' ||
          value == 'picture_test') {
        challenge = 'camera';
      } else {
        challenge = 'none';
      }
    }

    final rawDifficulty = map['jigsaw_difficulty'];

    String difficulty = 'Medium';

    if (rawDifficulty != null) {
      final value = rawDifficulty.toString().trim().toLowerCase();

      if (value == 'easy') {
        difficulty = 'Easy';
      } else if (value == 'medium') {
        difficulty = 'Medium';
      } else if (value == 'hard') {
        difficulty = 'Hard';
      }
    }

    // Read saved Camera Challenge objects safely.
    List<String> objects = [];

    final rawObjects = map['camera_objects'];

    if (rawObjects is List) {
      objects = rawObjects.map((item) => item.toString()).toList();
    } else if (rawObjects is String && rawObjects.isNotEmpty) {
      try {
        final decoded = jsonDecode(rawObjects);

        if (decoded is List) {
          objects = decoded.map((item) => item.toString()).toList();
        }
      } catch (_) {
        objects = [];
      }
    }

    return AlarmModel(
      id: map['id'],
      hour: map['hour'] ?? 0,
      minute: map['minute'] ?? 0,
      label: map['label'] ?? '',
      repeatDays: map['repeat_days'] ?? 'Never',
      soundName: map['sound_name'] ?? 'Journey',
      snoozeEnabled: map['snooze_enabled'] == null
          ? true
          : map['snooze_enabled'] == true ||
              map['snooze_enabled'] == 1,
      snoozeMinutes: map['snooze_minutes'] ?? 9,
      challengeType: challenge,
      jigsawDifficulty: difficulty,
      isEnabled: map['is_enabled'] == null
          ? true
          : map['is_enabled'] == true ||
              map['is_enabled'] == 1,
      cameraObjects: objects,
    );
  }

  AlarmModel copyWith({
    int? id,
    int? hour,
    int? minute,
    String? label,
    String? repeatDays,
    String? soundName,
    bool? snoozeEnabled,
    int? snoozeMinutes,
    String? challengeType,
    String? jigsawDifficulty,
    bool? isEnabled,
    List<String>? cameraObjects,
  }) {
    return AlarmModel(
      id: id ?? this.id,
      hour: hour ?? this.hour,
      minute: minute ?? this.minute,
      label: label ?? this.label,
      repeatDays: repeatDays ?? this.repeatDays,
      soundName: soundName ?? this.soundName,
      snoozeEnabled: snoozeEnabled ?? this.snoozeEnabled,
      snoozeMinutes: snoozeMinutes ?? this.snoozeMinutes,
      challengeType: challengeType ?? this.challengeType,
      jigsawDifficulty: jigsawDifficulty ?? this.jigsawDifficulty,
      isEnabled: isEnabled ?? this.isEnabled,
      cameraObjects: cameraObjects ?? this.cameraObjects,
    );
  }
}
