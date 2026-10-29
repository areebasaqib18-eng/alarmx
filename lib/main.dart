import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:alarm/alarm.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'add_alarm_screen.dart';
import 'alarm_scheduler.dart';
import 'data/alarm_database.dart';
import 'edit_alarm_sheet.dart';
import 'models/alarm_model.dart';
import 'challenges/math_challenge.dart';
import 'challenges/puzzle_challenge.dart';
import 'challenges/jigsaw_challenge.dart';
import 'challenges/color_memory_challenge.dart';
import 'picture_test_screen.dart';
import 'camera_target_picker.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Alarm.init();

  await _requestAlarmPermissions();

  await Supabase.initialize(
    url: 'https://rparikzbeobiuxgszlih.supabase.co',
    publishableKey:
        'sb_publishable_6zpOLtCkXUFoTvG8W-YiHA_R5FR68OA',
  );

  runApp(const AlarmXApp());
}

/// Android 12+ will not fire exact alarms, and Android 13+ will not show the
/// ringing notification, unless the user has granted these.
Future<void> _requestAlarmPermissions() async {
  try {
    if (await Permission.notification.isDenied) {
      await Permission.notification.request();
    }

    if (await Permission.scheduleExactAlarm.isDenied) {
      await Permission.scheduleExactAlarm.request();
    }
  } catch (e) {
    debugPrint('Permission request failed: $e');
  }
}

class AlarmXApp extends StatelessWidget {
  const AlarmXApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'AlarmX',
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF10141A),
        primaryColor: const Color(0xFF7C9CFF),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF7C9CFF),
          surface: Color(0xFF181F29),
        ),
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late DateTime _now;
  Timer? _timer;

  final AlarmDatabase _alarmDatabase = AlarmDatabase();

  List<AlarmModel> _alarms = [];
  bool _isLoading = true;

  StreamSubscription? _ringingSubscription;

  final Map<int, Timer> _autoStopTimers = {};

  final Set<int> _challengeDialogsShowing = {};

  Set<int> _previouslyRinging = {};

  @override
  void initState() {
    super.initState();

    _now = DateTime.now();

    _timer = Timer.periodic(
      const Duration(minutes: 1),
      (_) {
        if (!mounted) return;

        setState(() {
          _now = DateTime.now();
        });

        // Retry sending any changes made while offline.
        _alarmDatabase.syncNow();
      },
    );

    // A background sync changed the stored alarms: show them.
    AlarmDatabase.syncVersion.addListener(_onSynced);

    _ringingSubscription = Alarm.ringing.listen(

  (alarmSet) {
    debugPrint('🔔 ALARM RINGING EVENT RECEIVED');

    final nowRinging = alarmSet.alarms.map((a) => a.id).toSet();

    for (final id in _previouslyRinging.difference(nowRinging)) {
      _handleRingingEnded(id);
    }

    _previouslyRinging = nowRinging;

    for (final ringingAlarm in alarmSet.alarms) {
      debugPrint('🔔 Ringing Alarm ID: ${ringingAlarm.id}');
      _handleAlarmRinging(ringingAlarm.id);
    }
  },
);

    _loadAlarms();
  }

  void _onSynced() {
    _loadAlarms(sync: false);
  }

  Future<void> _loadAlarms({bool sync = true}) async {
    try {
      final data = await _alarmDatabase.getAlarms(sync: sync);

      if (!mounted) return;

      final loadedAlarms = data
          .map(
            (item) => AlarmModel.fromMap(item),
          )
          .toList();

      loadedAlarms.sort((a, b) {
        final timeA = a.hour * 60 + a.minute;
        final timeB = b.hour * 60 + b.minute;

        return timeA.compareTo(timeB);
      });

      setState(() {
        _alarms = loadedAlarms;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to load alarms: ${e.toString().replaceFirst('Exception: ', '')}',
          ),
        ),
      );
    }
  }


// ============================================================
// ALARM RINGING
// ============================================================

Future<void> _handleAlarmRinging(int alarmId) async {
  AlarmModel? alarm;

  // 1. Find alarm in current list
  for (final item in _alarms) {
    if (item.id == alarmId) {
      alarm = item;
      break;
    }
  }


  // 2. If not found, load from database
  if (alarm == null) {
    try {
      final data = await _alarmDatabase.getAlarms(sync: false);

      final loadedAlarms = data
          .map((item) => AlarmModel.fromMap(item))
          .toList();

      if (mounted) {
        setState(() {
          _alarms = loadedAlarms;
          _isLoading = false;
        });
      }

      for (final item in loadedAlarms) {
        if (item.id == alarmId) {
          alarm = item;
          break;
        }
      }
    } catch (e) {
      debugPrint('Failed to load alarm: $e');
      return;
    }
  }

  if (alarm == null) {
    debugPrint('Alarm not found: $alarmId');
    return;
  }

  // 3. Normalize challenge name
  final challenge = alarm.challengeType
      .toLowerCase()
      .trim()
      .replaceAll('_', ' ')
      .replaceAll('-', ' ');

  debugPrint('🔔 Alarm ID: $alarmId');
  debugPrint('🔔 Challenge type: "$challenge"');
  debugPrint('📸 Camera objects: ${alarm.cameraObjects}');

  // 4. Identify selected challenge
  final hasMathChallenge =
      challenge == 'math' || challenge == 'math challenge';

  final hasPuzzleChallenge =
      challenge == 'puzzle' || challenge == 'puzzle challenge';

  final hasJigsawChallenge =
      challenge == 'jigsaw' ||
      challenge == 'jigsaw puzzle' ||
      challenge == 'jigsaw challenge';

  final hasColorMemoryChallenge =
      challenge == 'color memory' ||
      challenge == 'color memory challenge';

  final hasCameraChallenge =
      challenge == 'camera' ||
      challenge == 'camera challenge' ||
      challenge == 'picture' ||
      challenge == 'picture challenge' ||
      challenge == 'picture test';

  final hasChallenge = hasMathChallenge ||
      hasPuzzleChallenge ||
      hasJigsawChallenge ||
      hasColorMemoryChallenge ||
      hasCameraChallenge;

  // 5. Open selected challenge
  if (hasChallenge) {
    // Prevent opening the same challenge multiple times
    if (_challengeDialogsShowing.contains(alarmId)) {
      return;
    }

    _autoStopTimers[alarmId]?.cancel();
    _autoStopTimers.remove(alarmId);

    _challengeDialogsShowing.add(alarmId);

    try {
      await Future.delayed(
        const Duration(milliseconds: 800),
      );

      if (!mounted) return;

      debugPrint('🚀 Opening challenge: $challenge');

      final solved = await _showDisableChallenge(alarm);

      if (!mounted) return;

      if (solved == true) {
        debugPrint('✅ Challenge completed. Stopping alarm.');
        await _finishRingingAlarm(alarm);
      } else {
        debugPrint(
          '❌ Challenge not completed. Alarm remains enabled.',
        );
      }
    } catch (e, stackTrace) {
      debugPrint('Challenge opening error: $e');
      debugPrintStack(stackTrace: stackTrace);
    } finally {
      _challengeDialogsShowing.remove(alarmId);
    }

    return;
  }

  // 6. Normal alarm: stop after one minute
  _autoStopTimers[alarmId]?.cancel();

  _autoStopTimers[alarmId] = Timer(
    const Duration(minutes: 1),
    () async {
      await _stopAlarmAutomatically(alarm!);
    },
  );
}


  /// An alarm stopped ringing. If it was stopped (not snoozed) and nothing
  /// else has dealt with it, switch a one-time alarm off, or schedule the next
  /// day of a repeating one, so tomorrow's alarm is not lost.
  Future<void> _handleRingingEnded(int alarmId) async {
    await Future.delayed(const Duration(milliseconds: 1500));

    if (!mounted || _challengeDialogsShowing.contains(alarmId)) return;

    try {
      // Snooze (or an already-rescheduled repeat) leaves the alarm set.
      if (await Alarm.getAlarm(alarmId) != null) return;
    } catch (_) {
      return;
    }

    AlarmModel? alarm;

    for (final item in _alarms) {
      if (item.id == alarmId) {
        alarm = item;
        break;
      }
    }

    if (alarm == null || !alarm.isEnabled) return;

    _autoStopTimers[alarmId]?.cancel();
    _autoStopTimers.remove(alarmId);

    await _finishRingingAlarm(alarm);
  }

  // ============================================================
  // AUTO STOP
  // ============================================================

  Future<void> _stopAlarmAutomatically(
    AlarmModel alarm,
  ) async {
    if (alarm.id == null) {
      return;
    }

    final challenge = alarm.challengeType.toLowerCase().trim();

    final hasMathChallenge =
        challenge == 'math' ||
        challenge == 'math challenge';

    final hasPuzzleChallenge =
        challenge == 'puzzle' ||
        challenge == 'puzzle challenge';

    
    final hasJigsawChallenge =
        challenge == 'jigsaw' ||
        challenge == 'jigsaw puzzle' ||
        challenge == 'jigsaw challenge';

    final hasColorMemoryChallenge =
        challenge == 'color memory' ||
        challenge == 'color_memory' ||
        challenge == 'color memory challenge';

    if (hasMathChallenge ||
    hasPuzzleChallenge ||
    hasJigsawChallenge ||
    hasColorMemoryChallenge ||
    challenge == 'camera') {
  return;
}

    await _finishRingingAlarm(alarm);
  }

  /// One-time alarms switch off after ringing; repeating alarms stay on and
  /// are scheduled for their next day.
  Future<void> _finishRingingAlarm(AlarmModel alarm) async {
    if (alarm.id == null) {
      return;
    }

    if (AlarmScheduler.isRepeating(alarm.repeatDays)) {
      try {
        await _scheduleAlarm(alarm);
      } catch (e) {
        debugPrint('Failed to reschedule repeating alarm: $e');
      }
      return;
    }

    await _updateAlarmStatus(alarm, false);
  }

  // ============================================================
  // OPEN ADD ALARM
  // ============================================================

  Future<void> _openAddAlarm() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AddAlarmScreen(),
      ),
    );

    if (!mounted) return;

    await _loadAlarms();
  }

  // ============================================================
  // OPEN EDIT ALARM
  // ============================================================

  Future<void> _openEditAlarm(
    AlarmModel alarm,
  ) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return EditAlarmSheet(
          alarm: alarm,
        );
      },
    );

    if (!mounted) return;

    if (result == true) {
      await _loadAlarms();
    }
  }

  // ============================================================
  // TOGGLE ALARM
  // ============================================================

  Future<void> _toggleAlarm(
    AlarmModel alarm,
    bool value,
  ) async {
    if (alarm.id == null) {
      return;
    }

    if (value == true) {
      await _updateAlarmStatus(
        alarm,
        true,
      );
      return;
    }

    final challenge = alarm.challengeType.toLowerCase().trim();

    final hasMathChallenge =
        challenge == 'math' ||
        challenge == 'math challenge';

    final hasPuzzleChallenge =
        challenge == 'puzzle' ||
        challenge == 'puzzle challenge';

    final hasJigsawChallenge =
        challenge == 'jigsaw' ||
        challenge == 'jigsaw puzzle' ||
        challenge == 'jigsaw challenge';

    final hasColorMemoryChallenge =
        challenge == 'color_memory' ||
        challenge == 'color memory' ||
        challenge == 'color memory challenge';

    final hasCameraChallenge =
        challenge == 'camera' || challenge == 'camera challenge';

    if (!hasMathChallenge &&
        !hasPuzzleChallenge &&
        !hasJigsawChallenge &&
        !hasColorMemoryChallenge &&
        !hasCameraChallenge) {
      await _updateAlarmStatus(
        alarm,
        false,
      );
      return;
    }

    final solved = await _showDisableChallenge(
      alarm,
    );

    if (!mounted) return;

    if (solved == true) {
      await _updateAlarmStatus(
        alarm,
        false,
      );
    }
  }

  // ============================================================
  // ACTUAL ALARM SCHEDULING
  // ============================================================

  Future<void> _scheduleAlarm(
    AlarmModel alarm,
  ) async {
    if (alarm.id == null) {
      return;
    }

    await AlarmScheduler.schedule(alarm);
  }

  // ============================================================
  // UPDATE ALARM STATUS
  // ============================================================

  Future<void> _updateAlarmStatus(
    AlarmModel alarm,
    bool value,
  ) async {
    if (alarm.id == null) {
      return;
    }

    try {
      final updatedAlarm = alarm.copyWith(
        isEnabled: value,
      );

      await _alarmDatabase.updateAlarm(
        alarm.id!,
        updatedAlarm.toMap(),
      );

      if (value) {
        await _scheduleAlarm(
          updatedAlarm,
        );
      } else {
        _autoStopTimers[alarm.id!]?.cancel();
        _autoStopTimers.remove(alarm.id!);

        await Alarm.stop(
          alarm.id!,
        );
      }

      if (!mounted) return;

      setState(() {
        final index = _alarms.indexWhere(
          (item) => item.id == alarm.id,
        );

        if (index != -1) {
          _alarms[index] = updatedAlarm;
        }
      });
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to update alarm: ${e.toString().replaceFirst('Exception: ', '')}',
          ),
        ),
      );
    }
  }

  // ============================================================
  // SHOW CHALLENGE
  // ============================================================


  Future<bool?> _showDisableChallenge(
    AlarmModel alarm,
  ) async {
    final challenge = alarm.challengeType.toLowerCase().trim();

    if (challenge == 'math' ||
        challenge == 'math challenge') {
      return _showMathChallenge();
    }

    if (challenge == 'puzzle' ||
        challenge == 'puzzle challenge') {
      return _showPuzzleChallenge();
    }

    if (challenge == 'jigsaw' ||
        challenge == 'jigsaw puzzle' ||
        challenge == 'jigsaw challenge') {
      return _showJigsawChallenge(alarm);
    }

    if (challenge == 'color memory' ||
        challenge == 'color_memory' ||
        challenge == 'color memory challenge') {
      return _showColorMemoryChallenge();
    }
    if (challenge == 'camera' ||
    challenge == 'camera challenge') {
  return _showCameraChallenge(alarm);
}

    return false;
  }

  // ============================================================
  // MATH CHALLENGE
  // ============================================================

  Future<bool?> _showMathChallenge() async {
    final random = Random();

    final number1 = random.nextInt(20) + 10;
    final number2 = random.nextInt(20) + 5;

    final correctAnswer = number1 + number2;

    if (!mounted) return false;

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return PopScope(
          canPop: false,
          child: MathChallengeDialog(
            number1: number1,
            number2: number2,
            correctAnswer: correctAnswer,
          ),
        );
      },
    );

    return result;
  }

  // ============================================================
  // PUZZLE CHALLENGE
  // ============================================================

  Future<bool?> _showPuzzleChallenge() async {
    if (!mounted) return false;

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return const PopScope(
          canPop: false,
          child: PuzzleChallengeDialog(),
        );
      },
    );

    return result;
  }

  // ============================================================
  // JIGSAW CHALLENGE
  // ============================================================

  Future<bool?> _showJigsawChallenge(
    AlarmModel alarm,
  ) async {
    if (!mounted) return false;

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return PopScope(
          canPop: false,
          child: JigsawChallengeDialog(
            difficulty: alarm.jigsawDifficulty,
          ),
        );
      },
    );

    return result;
  }
  
  // ============================================================
  // COLOR MEMORY CHALLENGE
  // ============================================================

  Future<bool?> _showColorMemoryChallenge() async {
    if (!mounted) return false;

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return const ColorMemoryChallengeDialog();
      },
    );

    return result;
  }


  // ============================================================
  // CAMERA CHALLENGE
  // ============================================================

Future<bool?> _showCameraChallenge(
  AlarmModel alarm,
) async {
  if (!mounted) return false;

  // An alarm with no objects saved must never trap the user, so fall back
  // to objects the camera recognises reliably.
  const fallbackObjects = ['Cup', 'Shoes', 'Chair', 'Umbrella', 'Keyboard'];

  final savedObjects = alarm.cameraObjects.isEmpty
      ? fallbackObjects
      : alarm.cameraObjects;

  final targetObject = await CameraTargetPicker.pick(savedObjects);

  debugPrint(
    '📸 Picked "$targetObject" from ${savedObjects.length} selected: '
    '$savedObjects',
  );

  if (!mounted) return false;

  final result = await Navigator.push<bool>(
    context,
    MaterialPageRoute(
      builder: (context) => PictureTestScreen(
        targetObject: targetObject,
        candidateObjects: savedObjects,
      ),
    ),
  );

  return result == true;
}

  // ============================================================
  // CHALLENGE NAME
  // ============================================================


String? _getChallengeName(
  String challengeType,
) {
  final value = challengeType.toLowerCase().trim();

  if (value == 'math' ||
      value == 'math challenge') {
    return 'Math Challenge';
  }

  if (value == 'puzzle' ||
      value == 'puzzle challenge') {
    return 'Puzzle Challenge';
  }

  if (value == 'jigsaw' ||
      value == 'jigsaw puzzle' ||
      value == 'jigsaw challenge') {
    return 'Jigsaw Puzzle';
  }

  if (value == 'color memory' ||
      value == 'color_memory' ||
      value == 'color memory challenge') {
    return 'Color Memory';
  }
  if (value == 'camera' ||
    value == 'camera challenge') {
  return 'Camera Challenge';
}

  return null;
}


  @override
  void dispose() {
    _timer?.cancel();

    AlarmDatabase.syncVersion.removeListener(_onSynced);

    _ringingSubscription?.cancel();

    for (final timer in _autoStopTimers.values) {
      timer.cancel();
    }

    _autoStopTimers.clear();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final timeText = _formatTime(_now);
    final dateText = _formatDate(_now);

    return Scaffold(
      backgroundColor: const Color(0xFF10141A),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 20,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),

              const Text(
                'AlarmX',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),

              const SizedBox(height: 32),

              Center(
                child: Column(
                  children: [
                    Text(
                      timeText,
                      style: const TextStyle(
                        fontSize: 58,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      dateText,
                      style: const TextStyle(
                        fontSize: 16,
                        color: Color(0xFFB7C0CC),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 36),

              const Text(
                'My Alarms',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),

              const SizedBox(height: 18),

              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: const Color(0xFF181F29),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: const Color(0xFF2B3440),
                    ),
                  ),
                  child: _buildAlarmContent(),
                ),
              ),

              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                height: 58,
                child: ElevatedButton.icon(
                  onPressed: _openAddAlarm,
                  icon: const Icon(Icons.add),
                  label: const Text(
                    'Add Alarm',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        const Color(0xFF7C9CFF),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              const SizedBox(height: 18),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: const Color(0xFF141A20),
        selectedItemColor:
            const Color(0xFF7C9CFF),
        unselectedItemColor:
            const Color(0xFF9AA7B5),
        type: BottomNavigationBarType.fixed,
        currentIndex: 0,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history_outlined),
            activeIcon: Icon(Icons.history),
            label: 'History',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings_outlined),
            activeIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }

  Widget _buildAlarmContent() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: Color(0xFF7C9CFF),
        ),
      );
    }

    if (_alarms.isEmpty) {
      return const Center(
        child: Text(
          'No alarms set',
          style: TextStyle(
            fontSize: 20,
            color: Color(0xFF9AA7B5),
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: _alarms.length,
      itemBuilder: (context, index) {
        final alarm = _alarms[index];

        final challengeName =
            _getChallengeName(
          alarm.challengeType,
        );

        return Container(
          margin: const EdgeInsets.only(
            bottom: 10,
          ),
          decoration: BoxDecoration(
            color: const Color(0xFF202833),
            borderRadius:
                BorderRadius.circular(16),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius:
                  BorderRadius.circular(16),
              onTap: () {
                _openEditAlarm(alarm);
              },
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  crossAxisAlignment:
                      CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          Text(
                            _formatAlarmTime(
                              alarm.hour,
                              alarm.minute,
                            ),
                            style: const TextStyle(
                              fontSize: 30,
                              fontWeight:
                                  FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            alarm.label.isEmpty
                                ? 'Alarm'
                                : alarm.label,
                            style: const TextStyle(
                              fontSize: 15,
                              color:
                                  Color(0xFFB7C0CC),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            alarm.repeatDays,
                            style: const TextStyle(
                              fontSize: 13,
                              color:
                                  Color(0xFF7C9CFF),
                            ),
                          ),
                          if (challengeName != null) ...[
                            const SizedBox(height: 5),
                            Row(
                              children: [
                                const Icon(
                                  Icons
                                      .psychology_outlined,
                                  color:
                                      Color(0xFFFF9F0A),
                                  size: 16,
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  challengeName,
                                  style:
                                      const TextStyle(
                                    fontSize: 13,
                                    color:
                                        Color(0xFFFF9F0A),
                                    fontWeight:
                                        FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                    Switch(
                      value: alarm.isEnabled,
                      onChanged: (value) {
                        _toggleAlarm(
                          alarm,
                          value,
                        );
                      },
                      activeThumbColor:
                          const Color(0xFF7C9CFF),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  String _formatTime(
    DateTime dateTime,
  ) {
    final hour = dateTime.hour
        .toString()
        .padLeft(
          2,
          '0',
        );

    final minute = dateTime.minute
        .toString()
        .padLeft(
          2,
          '0',
        );

    return '$hour:$minute';
  }

  String _formatAlarmTime(
    int hour,
    int minute,
  ) {
    String period;

    if (hour >= 12) {
      period = 'PM';
    } else {
      period = 'AM';
    }

    int hour12 = hour % 12;

    if (hour12 == 0) {
      hour12 = 12;
    }

    final minuteText = minute
        .toString()
        .padLeft(
          2,
          '0',
        );

    return '$hour12:$minuteText $period';
  }

  String _formatDate(
    DateTime dateTime,
  ) {
    const weekdays = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];

    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];

    final weekday =
        weekdays[dateTime.weekday - 1];

    final month =
        months[dateTime.month - 1];

    return '$weekday, $month ${dateTime.day}';
  }
}

