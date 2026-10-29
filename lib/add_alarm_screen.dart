import 'package:flutter/cupertino.dart';
import 'alarm_scheduler.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'challenge_screen.dart';
import 'data/alarm_database.dart';
import 'models/alarm_model.dart';

class AddAlarmScreen extends StatefulWidget {
  const AddAlarmScreen({super.key});

  @override
  State<AddAlarmScreen> createState() => _AddAlarmScreenState();
}

class _AddAlarmScreenState extends State<AddAlarmScreen> {
  final AlarmDatabase _alarmDatabase = AlarmDatabase();

  int selectedHour = 7;
  int selectedMinute = 30;
  bool isAM = true;

  String repeatValue = 'Never';
  String soundValue = 'Journey';
  bool snoozeEnabled = true;
  int snoozeMinutes = 9;

  String challengeValue = 'none';
  List<String> selectedCameraObjects = [];

  // Jigsaw difficulty:
  // Easy = 2 x 2
  // Medium = 3 x 3
  // Hard = 4 x 4
  String jigsawDifficulty = 'Medium';

  final TextEditingController labelController =
      TextEditingController();

  late final FixedExtentScrollController _hourController =
      FixedExtentScrollController(
    initialItem: selectedHour - 1,
  );

  late final FixedExtentScrollController _minuteController =
      FixedExtentScrollController(
    initialItem: selectedMinute,
  );

  late final FixedExtentScrollController _periodController =
      FixedExtentScrollController(
    initialItem: isAM ? 0 : 1,
  );

  final List<String> sounds = AlarmScheduler.soundFiles.keys.toList();

  final List<int> snoozeOptions = [
    5,
    9,
    10,
    15,
    20,
    30,
  ];

  final List<String> repeatOptions = [
    'Never',
    'Every Day',
    'Weekdays',
    'Weekends',
  ];

  static const Color backgroundColor = Color(0xFF1C1C1E);
  static const Color cardColor = Color(0xFF2C2C2E);
  static const Color blueAccent = Color(0xFFABD7E1);
  static const Color orange = Color(0xFFFF9F0A);
  static const Color green = Color(0xFF34C759);
  static const Color secondaryText = Color(0xFF8E8E93);

  @override
  void initState() {
    super.initState();

    final now = TimeOfDay.now();

    selectedHour = now.hourOfPeriod;
    selectedMinute = now.minute;
    isAM = now.period == DayPeriod.am;

    challengeValue = 'none';
    jigsawDifficulty = 'Medium';

    _loadLastSound();
  }

  Future<void> _loadLastSound() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('last_sound');

    if (saved != null && sounds.contains(saved) && mounted) {
      setState(() {
        soundValue = saved;
      });
    }
  }

  @override
  void dispose() {
    labelController.dispose();
    _hourController.dispose();
    _minuteController.dispose();
    _periodController.dispose();
    super.dispose();
  }

  // ---------------- SAVE ALARM ----------------

  Future<void> saveAlarm() async {
    try {
      int hour24 = selectedHour;

      if (isAM) {
        if (hour24 == 12) {
          hour24 = 0;
        }
      } else {
        if (hour24 != 12) {
          hour24 += 12;
        }
      }

      final alarm = AlarmModel(
        hour: hour24,
        minute: selectedMinute,
        label: labelController.text.trim(),
       
repeatDays: repeatValue,
soundName: soundValue,
snoozeEnabled: snoozeEnabled,
snoozeMinutes: snoozeMinutes,

challengeType: challengeValue,
cameraObjects: selectedCameraObjects,
jigsawDifficulty: jigsawDifficulty,
isEnabled: true,
);

final int alarmId = await _alarmDatabase.addAlarm(
  alarm.toMap(),
);


      await AlarmScheduler.schedule(alarm.copyWith(id: alarmId));

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('last_sound', soundValue);

      if (!mounted) return;

      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFF303033),
          content: Text(
            'Failed to save alarm: ${e.toString().replaceFirst('Exception: ', '')}',
            style: const TextStyle(color: Colors.white),
          ),
        ),
      );
    }
  }

  // ---------------- MAIN UI ----------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: Padding(
          padding: const EdgeInsets.only(left: 12),
          child: Center(
            child: _circleButton(
              icon: CupertinoIcons.xmark,
              onTap: () => Navigator.pop(context),
            ),
          ),
        ),
        title: const Text(
          'Add Alarm',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Center(
              child: _circleButton(
                icon: CupertinoIcons.checkmark,
                isBlue: true,
                onTap: saveAlarm,
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 30),
          children: [
            _buildTimePicker(),
            const SizedBox(height: 20),
            _buildSettingsCard(),
            const SizedBox(height: 14),
            _buildChallengeCard(),
          ],
        ),
      ),
    );
  }

  // ---------------- CIRCLE BUTTON ----------------

  Widget _circleButton({
    required IconData icon,
    required VoidCallback onTap,
    bool isBlue = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: isBlue
              ? blueAccent
              : const Color(0xFF343438),
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          color: isBlue
              ? const Color(0xFF1C1C1E)
              : Colors.white,
          size: isBlue ? 21 : 18,
        ),
      ),
    );
  }

  // ---------------- TIME PICKER ----------------

  Widget _buildTimePicker() {
    return SizedBox(
      height: 220,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            left: 10,
            right: 10,
            top: 84,
            child: Container(
              height: 52,
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildWheel(
                width: 70,
                itemCount: 12,
                controller: _hourController,
                fontSize: 30,
                builder: (index) => '${(index % 12) + 1}',
                onChanged: (index) {
                  setState(() {
                    selectedHour = (index % 12) + 1;
                  });
                },
              ),
              const Text(
                ':',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 30,
                  fontWeight: FontWeight.w600,
                ),
              ),
              _buildWheel(
                width: 76,
                itemCount: 60,
                controller: _minuteController,
                fontSize: 30,
                builder: (index) => (index % 60)
                    .toString()
                    .padLeft(2, '0'),
                onChanged: (index) {
                  setState(() {
                    selectedMinute = index % 60;
                  });
                },
              ),
              const SizedBox(width: 8),
              _buildWheel(
                width: 65,
                itemCount: 2,
                controller: _periodController,
                fontSize: 22,
                looping: false,
                builder: (index) => index == 0 ? 'AM' : 'PM',
                onChanged: (index) {
                  setState(() {
                    isAM = index == 0;
                  });
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWheel({
    required double width,
    required int itemCount,
    required FixedExtentScrollController controller,
    required double fontSize,
    required String Function(int) builder,
    required ValueChanged<int> onChanged,
    bool looping = true,
  }) {
    return SizedBox(
      width: width,
      height: 210,
      child: ShaderMask(
        shaderCallback: (bounds) {
          return const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.transparent,
              Colors.white,
              Colors.white,
              Colors.transparent,
            ],
            stops: [0.02, 0.25, 0.75, 0.98],
          ).createShader(bounds);
        },
        blendMode: BlendMode.dstIn,
        child: CupertinoPicker(
          looping: looping,
          itemExtent: 52,
          squeeze: 1.05,
          useMagnifier: true,
          magnification: 1.08,
          selectionOverlay: const SizedBox.shrink(),
          scrollController: controller,
          onSelectedItemChanged: onChanged,
          children: List.generate(
            itemCount,
            (index) {
              return Center(
                child: Text(
                  builder(index),
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.95),
                    fontSize: fontSize,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  // ---------------- SETTINGS CARD ----------------

  Widget _buildSettingsCard() {
    final label = labelController.text.trim();

    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        children: [
          _settingTile(
            title: 'Repeat',
            value: repeatValue,
            onTap: _showRepeatSheet,
          ),
          _divider(),
          _settingTile(
            title: 'Label',
            value: label.isEmpty ? 'Alarm' : label,
            onTap: _showLabelDialog,
          ),
          _divider(),
          _settingTile(
            title: 'Sound',
            value: soundValue,
            onTap: _showSoundSheet,
          ),
          _divider(),
          _settingSwitchTile(),
          if (snoozeEnabled) ...[
            _divider(),
            _settingTile(
              title: 'Duration',
              value: '$snoozeMinutes min',
              onTap: _showSnoozeSheet,
            ),
          ],
        ],
      ),
    );
  }

  // ---------------- CHALLENGE CARD ----------------

  Widget _buildChallengeCard() {
    String displayChallenge;

    switch (challengeValue) {
      case 'math':
        displayChallenge = 'Math Challenge';
        break;

      case 'puzzle':
        displayChallenge = 'Puzzle Challenge';
        break;

      case 'jigsaw':
        displayChallenge = 'Jigsaw Puzzle - $jigsawDifficulty';
        break;

      case 'color_memory':
        displayChallenge = 'Color Memory';
        break;

      case 'camera':
      case 'camera challenge':
        displayChallenge = 'Camera Challenge';
        break;

      case 'none':
      default:
        displayChallenge = 'No Challenge';
    }

    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(22),
      ),
      child: _settingTile(
        title: 'Wake-up Challenge',
        value: displayChallenge,
        onTap: () async {
          
final result = await Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => ChallengeScreen(
      selectedChallenge: challengeValue,
    ),
  ),
);

if (result == null) return;

if (result is Map) {
  setState(() {
    challengeValue = result['challenge'] ?? 'camera';
    selectedCameraObjects =
        List<String>.from(result['cameraObjects'] ?? []);
  });
  return;
}

if (result is String) {
  // Purane challenge results handle honge
}


          if (result == 'jigsaw_easy') {
            setState(() {
              challengeValue = 'jigsaw';
              jigsawDifficulty = 'Easy';
            });
            return;
          }

          if (result == 'jigsaw_medium') {
            setState(() {
              challengeValue = 'jigsaw';
              jigsawDifficulty = 'Medium';
            });
            return;
          }

          if (result == 'jigsaw_hard') {
            setState(() {
              challengeValue = 'jigsaw';
              jigsawDifficulty = 'Hard';
            });
            return;
          }

          // Camera Challenge ko valid result mein include kiya hai.
          const validChallenges = {
            'none',
            'math',
            'puzzle',
            'color_memory',
            'camera',
          };

          if (!validChallenges.contains(result)) {
            return;
          }

          setState(() {
            challengeValue = result;
          });
        },
      ),
    );
  }

  // ---------------- DIVIDER ----------------

  Widget _divider() {
    return Padding(
      padding: const EdgeInsets.only(left: 18),
      child: Container(
        height: 0.7,
        color: Colors.white.withValues(alpha: 0.10),
      ),
    );
  }

  // ---------------- SETTING ROW ----------------

  Widget _settingTile({
    required String title,
    required String value,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      height: 54,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18),
          child: Row(
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  value,
                  textAlign: TextAlign.end,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: orange,
                    fontSize: 15,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
              const SizedBox(width: 7),
              const Icon(
                CupertinoIcons.chevron_right,
                color: secondaryText,
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------- SNOOZE SWITCH ----------------

  Widget _settingSwitchTile() {
    return SizedBox(
      height: 54,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18),
        child: Row(
          children: [
            const Expanded(
              child: Text(
                'Snooze',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
            CupertinoSwitch(
              value: snoozeEnabled,
              activeTrackColor: green,
              thumbColor: Colors.white,
              onChanged: (value) {
                setState(() {
                  snoozeEnabled = value;
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  // ---------------- BOTTOM SHEETS ----------------

  void _showOptionSheet({
    required List<String> options,
    required String selected,
    required ValueChanged<String> onSelected,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(24),
        ),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(sheetContext).size.height * 0.7,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _sheetHandle(),
                Flexible(
                  child: ListView(
                    shrinkWrap: true,
                    children: options.map(
                      (option) {
                        return ListTile(
                          title: Text(
                            option,
                            style: const TextStyle(color: Colors.white),
                          ),
                          trailing: selected == option
                              ? const Icon(
                                  CupertinoIcons.checkmark,
                                  color: orange,
                                )
                              : null,
                          onTap: () {
                            onSelected(option);
                            Navigator.pop(sheetContext);
                          },
                        );
                      },
                    ).toList(),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
//<--------------------show bottom sheet---------------------->

  void _showRepeatSheet() {
    _showOptionSheet(
      options: repeatOptions,
      selected: repeatValue,
      onSelected: (value) {
        setState(() {
          repeatValue = value;
        });
      },
    );
  }

  void _showSoundSheet() {
    _showOptionSheet(
      options: sounds,
      selected: soundValue,
      onSelected: (value) {
        setState(() {
          soundValue = value;
        });
      },
    );
  }

  void _showSnoozeSheet() {
    _showOptionSheet(
      options: snoozeOptions.map((m) => '$m minutes').toList(),
      selected: '$snoozeMinutes minutes',
      onSelected: (value) {
        setState(() {
          snoozeMinutes = int.parse(value.split(' ').first);
        });
      },
    );
  }

  // ---------------- SHEET HANDLE ----------------

  Widget _sheetHandle() {
    return Container(
      width: 38,
      height: 4,
      margin: const EdgeInsets.only(top: 10, bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(10),
      ),
    );
  }

  // ---------------- LABEL DIALOG ----------------

  void _showLabelDialog() {
    final controller = TextEditingController(
      text: labelController.text,
    );

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: cardColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            'Alarm Label',
            style: TextStyle(color: Colors.white),
          ),
          content: TextField(
            controller: controller,
            autofocus: true,
            style: const TextStyle(color: Colors.white),
            cursorColor: orange,
            decoration: const InputDecoration(
              hintText: 'Alarm',
              hintStyle: TextStyle(color: secondaryText),
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: orange),
              ),
              focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(
                  color: orange,
                  width: 1.5,
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: const Text(
                'Cancel',
                style: TextStyle(color: secondaryText),
              ),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  labelController.text = controller.text;
                });

                Navigator.pop(dialogContext);
              },
              child: const Text(
                'Save',
                style: TextStyle(
                  color: orange,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
