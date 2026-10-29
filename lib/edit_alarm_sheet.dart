
import 'package:alarm/alarm.dart';
import 'alarm_scheduler.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'data/alarm_database.dart';
import 'models/alarm_model.dart';

class EditAlarmSheet extends StatefulWidget {
  final AlarmModel alarm;

  const EditAlarmSheet({
    super.key,
    required this.alarm,
  });

  @override
  State<EditAlarmSheet> createState() => _EditAlarmSheetState();
}

class _EditAlarmSheetState extends State<EditAlarmSheet> {
  static const Color background = Color(0xFF1C1C1E);
  static const Color cardColor = Color(0xFF2C2C2E);
  static const Color orange = Color(0xFFFF9F0A);
  static const Color red = Color(0xFFFF3B30);

  final AlarmDatabase _database = AlarmDatabase();

  // Camera Challenge objects
  static const List<String> availableCameraObjects = [
    'Bottle',
    'Shoes',
    'Toothbrush',
    'Book',
    'Keys',
    'Cup',
    'Phone',
    'Watch',
    'Glasses',
    'Wallet',
    'Bag',
    'Pillow',
    'Chair',
    'Remote',
    'Laptop',
    'Mouse',
    'Keyboard',
    'Spoon',
    'Plate',
    'Toothpaste',
    'Comb',
    'Towel',
    'Umbrella',
    'Ball',
    'Pen',
    'Notebook',
    'Bottle Cap',
    'Headphones',
    'Soap',
    'Teddy Bear',
    'Tree',
    'Plant',
    'Car',
    'Bike',
    'Road',
  ];


  List<String> selectedCameraObjects = [];

  late int selectedHour;
  late int selectedMinute;
  late bool isAM;

  late String repeatValue;
  late String soundValue;
  late bool snoozeEnabled;
  late int snoozeMinutes;

  String challengeValue = 'none';
  late String jigsawDifficulty;

  final TextEditingController labelController =
      TextEditingController();

  // Same list the Add screen uses: only sounds that really exist.
  final List<String> sounds = AlarmScheduler.soundFiles.keys.toList();

  @override
  void initState() {
    super.initState();

    final alarm = widget.alarm;

    jigsawDifficulty = alarm.jigsawDifficulty;

    // Load objects already saved for this alarm.
    selectedCameraObjects =
        List<String>.from(alarm.cameraObjects);

    if (alarm.hour == 0) {
      selectedHour = 12;
      isAM = true;
    } else if (alarm.hour == 12) {
      selectedHour = 12;
      isAM = false;
    } else if (alarm.hour > 12) {
      selectedHour = alarm.hour - 12;
      isAM = false;
    } else {
      selectedHour = alarm.hour;
      isAM = true;
    }

    selectedMinute = alarm.minute;

    repeatValue = alarm.repeatDays;
    soundValue = alarm.soundName;
    snoozeEnabled = alarm.snoozeEnabled;
    snoozeMinutes = alarm.snoozeMinutes;

    labelController.text = alarm.label;

    final challenge =
        alarm.challengeType.toString().trim().toLowerCase();

    switch (challenge) {
      case 'math':
      case 'math challenge':
        challengeValue = 'math';
        break;

      case 'puzzle':
      case 'puzzle challenge':
        challengeValue = 'puzzle';
        break;

      case 'jigsaw':
      case 'jigsaw puzzle':
      case 'jigsaw challenge':
        challengeValue = 'jigsaw';
        break;

      case 'color_memory':
      case 'color memory':
      case 'color memory challenge':
        challengeValue = 'color_memory';
        break;

      case 'camera':
      case 'camera challenge':
      case 'picture':
      case 'picture challenge':
        challengeValue = 'camera';
        break;

      case 'none':
      case 'no challenge':
      case '':
      case 'null':
      default:
        challengeValue = 'none';
        break;
    }
  }

  @override
  void dispose() {
    labelController.dispose();
    super.dispose();
  }

  String get challengeDisplayName {
    switch (challengeValue) {
      case 'math':
        return 'Math Challenge';

      case 'puzzle':
        return 'Puzzle Challenge';

      case 'jigsaw':
        return 'Jigsaw Puzzle ($jigsawDifficulty)';

      case 'color_memory':
        return 'Color Memory';

      case 'camera':
        return selectedCameraObjects.isEmpty
            ? 'Camera Challenge - Select Objects'
            : 'Camera Challenge (${selectedCameraObjects.length} objects)';

      case 'none':
      default:
        return 'No Challenge';
    }
  }

  Future<void> _scheduleUpdatedAlarm(
    AlarmModel updatedAlarm,
  ) async {
    await AlarmScheduler.schedule(updatedAlarm);
  }

  // CAMERA OBJECT SELECTION
  Future<void> showCameraObjectsSheet() async {
    final Set<String> tempSelectedObjects =
        Set<String>.from(selectedCameraObjects);

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(24),
        ),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return SafeArea(
              child: SizedBox(
                height: MediaQuery.of(context).size.height * 0.75,
                child: Column(
                  children: [
                    const SizedBox(height: 18),
                    const Text(
                      'Select Camera Objects',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20),
                      child: Text(
                        'Select one or more objects. When the alarm rings, '
                        'one object will be chosen randomly.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: ListView.builder(
                        itemCount: availableCameraObjects.length,
                        itemBuilder: (context, index) {
                          final object =
                              availableCameraObjects[index];

                          return CheckboxListTile(
                            value: tempSelectedObjects.contains(object),
                            activeColor: orange,
                            checkColor: Colors.black,
                            title: Text(
                              object,
                              style: const TextStyle(
                                color: Colors.white,
                              ),
                            ),
                            onChanged: (checked) {
                              setModalState(() {
                                if (checked == true) {
                                  tempSelectedObjects.add(object);
                                } else {
                                  tempSelectedObjects.remove(object);
                                }
                              });
                            },
                          );
                        },
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                        20,
                        10,
                        20,
                        20,
                      ),
                      child: SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: orange,
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(
                              vertical: 14,
                            ),
                          ),
                          onPressed: () {
                            if (tempSelectedObjects.isEmpty) {
                              ScaffoldMessenger.of(context)
                                  .showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Please select at least one object.',
                                  ),
                                ),
                              );
                              return;
                            }

                            setState(() {
                              selectedCameraObjects =
                                  availableCameraObjects
                                      .where(
                                        (object) =>
                                            tempSelectedObjects
                                                .contains(object),
                                      )
                                      .toList();

                              challengeValue = 'camera';
                            });

                            Navigator.pop(sheetContext);
                          },
                          child: Text(
                            'Save Selected Objects '
                            '(${tempSelectedObjects.length})',
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void showChallengeSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(24),
        ),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              20,
              20,
              20,
              30,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Wake-up Challenge',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),

                ListTile(
                  title: const Text(
                    'No Challenge',
                    style: TextStyle(color: Colors.white),
                  ),
                  trailing: challengeValue == 'none'
                      ? const Icon(Icons.check, color: orange)
                      : null,
                  onTap: () {
                    setState(() {
                      challengeValue = 'none';
                    });
                    Navigator.pop(sheetContext);
                  },
                ),

                ListTile(
                  leading: const Icon(
                    Icons.calculate_rounded,
                    color: orange,
                  ),
                  title: const Text(
                    'Math Challenge',
                    style: TextStyle(color: Colors.white),
                  ),
                  trailing: challengeValue == 'math'
                      ? const Icon(Icons.check, color: orange)
                      : null,
                  onTap: () {
                    setState(() {
                      challengeValue = 'math';
                    });
                    Navigator.pop(sheetContext);
                  },
                ),

                ListTile(
                  leading: const Icon(
                    Icons.extension_rounded,
                    color: orange,
                  ),
                  title: const Text(
                    'Puzzle Challenge',
                    style: TextStyle(color: Colors.white),
                  ),
                  trailing: challengeValue == 'puzzle'
                      ? const Icon(Icons.check, color: orange)
                      : null,
                  onTap: () {
                    setState(() {
                      challengeValue = 'puzzle';
                    });
                    Navigator.pop(sheetContext);
                  },
                ),

                ListTile(
                  leading: const Icon(
                    Icons.grid_view_rounded,
                    color: orange,
                  ),
                  title: const Text(
                    'Jigsaw Puzzle',
                    style: TextStyle(color: Colors.white),
                  ),
                  trailing: challengeValue == 'jigsaw'
                      ? const Icon(Icons.check, color: orange)
                      : null,
                  onTap: () {
                    setState(() {
                      challengeValue = 'jigsaw';
                    });
                    Navigator.pop(sheetContext);
                  },
                ),

                ListTile(
                  leading: const Icon(
                    Icons.palette_rounded,
                    color: orange,
                  ),
                  title: const Text(
                    'Color Memory',
                    style: TextStyle(color: Colors.white),
                  ),
                  trailing: challengeValue == 'color_memory'
                      ? const Icon(Icons.check, color: orange)
                      : null,
                  onTap: () {
                    setState(() {
                      challengeValue = 'color_memory';
                    });
                    Navigator.pop(sheetContext);
                  },
                ),

                // CAMERA CHALLENGE
                ListTile(
                  leading: const Icon(
                    Icons.camera_alt_rounded,
                    color: orange,
                  ),
                  title: const Text(
                    'Camera Challenge',
                    style: TextStyle(color: Colors.white),
                  ),
                  subtitle: selectedCameraObjects.isEmpty
                      ? const Text(
                          'Select objects',
                          style: TextStyle(color: Colors.white54),
                        )
                      : Text(
                          '${selectedCameraObjects.length} objects selected',
                          style: const TextStyle(
                            color: Colors.white54,
                          ),
                        ),
                  trailing: challengeValue == 'camera'
                      ? const Icon(Icons.check, color: orange)
                      : null,
                  onTap: () async {
                    Navigator.pop(sheetContext);

                    await Future.delayed(
                      const Duration(milliseconds: 250),
                    );

                    if (!mounted) return;

                    await showCameraObjectsSheet();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void showJigsawDifficultySheet() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: cardColor,
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final level in ['Easy', 'Medium', 'Hard'])
                ListTile(
                  title: Text(
                    level,
                    style: const TextStyle(color: Colors.white),
                  ),
                  trailing: jigsawDifficulty == level
                      ? const Icon(
                          Icons.check,
                          color: Colors.blue,
                        )
                      : null,
                  onTap: () {
                    setState(() {
                      jigsawDifficulty = level;
                      challengeValue = 'jigsaw';
                    });
                    Navigator.pop(sheetContext);
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  Future<void> saveChanges() async {
    if (widget.alarm.id == null) {
      return;
    }

    if (challengeValue == 'camera' &&
        selectedCameraObjects.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please select at least one camera object.',
          ),
        ),
      );
      return;
    }

    int hour24 = selectedHour;

    if (isAM) {
      if (selectedHour == 12) {
        hour24 = 0;
      }
    } else {
      if (selectedHour != 12) {
        hour24 = selectedHour + 12;
      }
    }

    String finalChallenge;

    switch (challengeValue) {
      case 'math':
        finalChallenge = 'math';
        break;

      case 'puzzle':
        finalChallenge = 'puzzle';
        break;

      case 'jigsaw':
        finalChallenge = 'jigsaw';
        break;

      case 'color_memory':
        finalChallenge = 'color_memory';
        break;

      case 'camera':
        finalChallenge = 'camera';
        break;

      case 'none':
      default:
        finalChallenge = 'none';
        break;
    }

    final updatedAlarm = widget.alarm.copyWith(
      hour: hour24,
      minute: selectedMinute,
      label: labelController.text.trim(),
      repeatDays: repeatValue,
      soundName: soundValue,
      snoozeEnabled: snoozeEnabled,
      snoozeMinutes: snoozeMinutes,
      challengeType: finalChallenge,
      jigsawDifficulty: jigsawDifficulty,
      cameraObjects: List<String>.from(selectedCameraObjects),
    );

    try {
      await _database.updateAlarm(
        widget.alarm.id!,
        updatedAlarm.toMap(),
      );

      if (updatedAlarm.isEnabled) {
        await _scheduleUpdatedAlarm(updatedAlarm);
      } else {
        try {
          await Alarm.stop(updatedAlarm.id!);
        } catch (_) {}
      }

      if (!mounted) {
        return;
      }

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update alarm: ${e.toString().replaceFirst('Exception: ', '')}'),
        ),
      );
    }
  }

  Future<void> confirmDelete() async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: cardColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          title: const Text(
            'Delete this alarm?',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
          content: const Text(
            'This alarm will be permanently removed.',
            style: TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context, false);
              },
              child: const Text(
                'Cancel',
                style: TextStyle(color: Colors.white70),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context, true);
              },
              child: const Text(
                'Delete',
                style: TextStyle(
                  color: red,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );

    if (shouldDelete != true) {
      return;
    }

    if (widget.alarm.id == null) {
      return;
    }

    try {
      await _database.deleteAlarm(widget.alarm.id!);

      try {
        await Alarm.stop(widget.alarm.id!);
      } catch (_) {}

      if (!mounted) {
        return;
      }

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to delete alarm: $e'),
        ),
      );
    }
  }

  void showRepeatSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(24),
        ),
      ),
      builder: (sheetContext) {
        const options = [
          'Never',
          'Every day',
          'Weekdays',
          'Weekends',
        ];

        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              20,
              20,
              20,
              30,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Repeat',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                ...options.map(
                  (value) {
                    return ListTile(
                      title: Text(
                        value,
                        style: const TextStyle(
                          color: Colors.white,
                        ),
                      ),
                      trailing: repeatValue == value
                          ? const Icon(Icons.check, color: orange)
                          : null,
                      onTap: () {
                        setState(() {
                          repeatValue = value;
                        });
                        Navigator.pop(sheetContext);
                      },
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

void showSoundSheet() {
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
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
            children: [
              ...sounds.map(
                (s) => ListTile(
                  title: Text(
                    s,
                    style: const TextStyle(color: Colors.white),
                  ),
                  trailing: soundValue == s
                      ? const Icon(Icons.check, color: orange)
                      : null,
                  onTap: () {
                    setState(() {
                      soundValue = s;
                    });
                    Navigator.pop(sheetContext);
                  },
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

  void showSnoozeDurationSheet() {
  if (!snoozeEnabled) {
    return;
  }

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
      const durations = [
        5,
        9,
        10,
        15,
        20,
        30,
      ];

      return SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(sheetContext).size.height * 0.7,
          ),
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
            children: [
              const Text(
                'Snooze Duration',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              ...durations.map(
                (minutes) {
                  return ListTile(
                    title: Text(
                      '$minutes min',
                      style: const TextStyle(color: Colors.white),
                    ),
                    trailing: snoozeMinutes == minutes
                        ? const Icon(Icons.check, color: orange)
                        : null,
                    onTap: () {
                      setState(() {
                        snoozeMinutes = minutes;
                      });
                      Navigator.pop(sheetContext);
                    },
                  );
                },
              ),
            ],
          ),
        ),
      );
    },
  );
}

  void showLabelDialog() {
    final controller = TextEditingController(
      text: labelController.text,
    );

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: cardColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          title: const Text(
            'Label',
            style: TextStyle(color: Colors.white),
          ),
          content: TextField(
            controller: controller,
            autofocus: true,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              hintText: 'Alarm',
              hintStyle: TextStyle(color: Colors.white38),
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: orange),
              ),
              focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: orange),
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
                style: TextStyle(color: Colors.white70),
              ),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  labelController.text = controller.text.trim();
                });
                Navigator.pop(dialogContext);
              },
              child: const Text(
                'Done',
                style: TextStyle(color: orange),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget timeWheel({
    required List<String> items,
    required int initialIndex,
    required ValueChanged<int> onChanged,
    bool looping = false,
  }) {
    final safeInitialIndex = looping && items.isNotEmpty
        ? initialIndex % items.length
        : initialIndex;

    final controllerInitialItem = looping
        ? (1000 ~/ items.length) * items.length + safeInitialIndex
        : safeInitialIndex;

    return SizedBox(
      width: 70,
      height: 180,
      child: CupertinoPicker.builder(
        itemExtent: 52,
        scrollController: FixedExtentScrollController(
          initialItem: controllerInitialItem,
        ),
        childCount: looping ? null : items.length,
        onSelectedItemChanged: (index) {
          final actualIndex =
              looping ? index % items.length : index;
          onChanged(actualIndex);
        },
        itemBuilder: (context, index) {
          final actualIndex =
              looping ? index % items.length : index;

          return Center(
            child: Text(
              items[actualIndex],
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w600,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget settingRow({
    required String title,
    String? value,
    VoidCallback? onTap,
    Widget? trailing,
    bool disabled = false,
  }) {
    Widget valueWidget;

    if (value == null) {
      valueWidget = const SizedBox.shrink();
    } else {
      valueWidget = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: Text(
              value,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: disabled ? Colors.white30 : orange,
                fontSize: 15,
              ),
            ),
          ),
          const SizedBox(width: 5),
          Icon(
            Icons.chevron_right,
            color: disabled ? Colors.white24 : Colors.white38,
            size: 20,
          ),
        ],
      );
    }

    final Widget trailingWidget =
        trailing ?? const SizedBox.shrink();

    return InkWell(
      onTap: disabled ? null : onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 15,
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  color: disabled ? Colors.white38 : Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Flexible(child: valueWidget),
            trailingWidget,
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hourItems = List.generate(
      12,
      (index) => (index + 1).toString(),
    );

    final minuteItems = List.generate(
      60,
      (index) => index.toString().padLeft(2, '0'),
    );

    const periodItems = [
      'AM',
      'PM',
    ];

    return SafeArea(
      child: Container(
        decoration: const BoxDecoration(
          color: background,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(28),
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            16,
            14,
            16,
            30,
          ),
          child: Column(
            children: [
              // HEADER
              Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                    },
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: const BoxDecoration(
                        color: cardColor,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.close,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                  ),
                  const Expanded(
                    child: Center(
                      child: Text(
                        'Edit Alarm',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: saveChanges,
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: const BoxDecoration(
                        color: orange,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check,
                        color: Colors.black,
                        size: 23,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // TIME
              Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    timeWheel(
                      items: hourItems,
                      initialIndex: selectedHour - 1,
                      looping: true,
                      onChanged: (index) {
                        setState(() {
                          selectedHour = index + 1;
                        });
                      },
                    ),
                    const Text(
                      ':',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    timeWheel(
                      items: minuteItems,
                      initialIndex: selectedMinute,
                      looping: true,
                      onChanged: (index) {
                        setState(() {
                          selectedMinute = index;
                        });
                      },
                    ),
                    timeWheel(
                      items: periodItems,
                      initialIndex: isAM ? 0 : 1,
                      onChanged: (index) {
                        setState(() {
                          isAM = index == 0;
                        });
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // SETTINGS
              Container(
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  children: [
                    settingRow(
                      title: 'Repeat',
                      value: repeatValue,
                      onTap: showRepeatSheet,
                    ),
                    const Divider(
                      height: 1,
                      color: Color(0xFF48484A),
                      indent: 16,
                    ),
                    settingRow(
                      title: 'Label',
                      value: labelController.text.isEmpty
                          ? 'Alarm'
                          : labelController.text,
                      onTap: showLabelDialog,
                    ),
                    const Divider(
                      height: 1,
                      color: Color(0xFF48484A),
                      indent: 16,
                    ),
                    settingRow(
                      title: 'Sound',
                      value: soundValue,
                      onTap: showSoundSheet,
                    ),
                    const Divider(
                      height: 1,
                      color: Color(0xFF48484A),
                      indent: 16,
                    ),
                    settingRow(
                      title: 'Snooze',
                      trailing: Switch(
                        value: snoozeEnabled,
                        activeThumbColor: Colors.white,
                        activeTrackColor: Colors.blue,
                        inactiveTrackColor: Colors.white24,
                        onChanged: (value) {
                          setState(() {
                            snoozeEnabled = value;
                          });
                        },
                      ),
                    ),
                    const Divider(
                      height: 1,
                      color: Color(0xFF48484A),
                      indent: 16,
                    ),
                    settingRow(
                      title: 'Duration',
                      value: '$snoozeMinutes min',
                      onTap: showSnoozeDurationSheet,
                      disabled: !snoozeEnabled,
                    ),
                    const Divider(
                      height: 1,
                      color: Color(0xFF48484A),
                      indent: 16,
                    ),
                    settingRow(
                      title: 'Wake-up Challenge',
                      value: challengeDisplayName,
                      onTap: showChallengeSheet,
                    ),
                    if (challengeValue == 'jigsaw')
                      settingRow(
                        title: 'Jigsaw Difficulty',
                        value: jigsawDifficulty,
                        onTap: showJigsawDifficultySheet,
                      ),
                  
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // DELETE
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: InkWell(
                  onTap: confirmDelete,
                  borderRadius: BorderRadius.circular(20),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 17),
                    child: Center(
                      child: Text(
                        'Delete Alarm',
                        style: TextStyle(
                          color: red,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
