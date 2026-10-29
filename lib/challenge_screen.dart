
import 'package:flutter/material.dart';
import 'camera_object_selection_screen.dart';

class ChallengeScreen extends StatefulWidget {
  final String? selectedChallenge;

  const ChallengeScreen({
    super.key,
    this.selectedChallenge,
  });

  @override
  State<ChallengeScreen> createState() => _ChallengeScreenState();
}

class _ChallengeScreenState extends State<ChallengeScreen> {
  static const Color background = Color(0xFF1B1C1F);
  static const Color cardColor = Color(0xFF2A2C30);
  static const Color blueAccent = Color(0xFFABD7E1);

  late String selectedChallenge;

  @override
  void initState() {
    super.initState();

    final incoming =
        widget.selectedChallenge?.trim().toLowerCase() ?? 'none';

    if (incoming == 'math' || incoming == 'math challenge') {
      selectedChallenge = 'math';
    } else if (incoming == 'puzzle' ||
        incoming == 'puzzle challenge') {
      selectedChallenge = 'puzzle';
    } else if (incoming.startsWith('jigsaw')) {
      selectedChallenge = 'jigsaw';
    } else if (incoming == 'color memory' ||
        incoming == 'color_memory' ||
        incoming == 'color memory challenge') {
      selectedChallenge = 'color_memory';
    } else if (incoming == 'camera' ||
        incoming == 'camera challenge' ||
        incoming == 'picture' ||
        incoming == 'picture challenge' ||
        incoming == 'picture_test') {
      selectedChallenge = 'camera';
    } else {
      selectedChallenge = 'none';
    }
  }

  Future<void> _openCameraSelection() async {
    final result = await Navigator.push<List<String>>(
      context,
      MaterialPageRoute(
        builder: (context) =>
            const CameraObjectSelectionScreen(),
      ),
    );

    if (!mounted) return;

    if (result == null || result.isEmpty) return;

    Navigator.pop(context, {
      'challenge': 'camera',
      'cameraObjects': result,
    });
  }

  Future<void> _openJigsawDifficulty() async {
    final result = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (context) =>
            const _JigsawDifficultyScreen(),
      ),
    );

    if (!mounted) return;

    if (result == null) return;

    Navigator.pop(context, result);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        backgroundColor: background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back,
            color: Colors.white,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Wake-up Challenge',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Choose a challenge',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Select a challenge for your alarm.',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    _challengeCard(
                      title: 'No Challenge',
                      description: 'Alarm will ring normally',
                      icon: Icons.notifications_none_rounded,
                      value: 'none',
                    ),
                    const SizedBox(height: 12),
                    _challengeCard(
                      title: 'Math Challenge',
                      description: 'Solve a simple math question',
                      icon: Icons.calculate_rounded,
                      value: 'math',
                    ),
                    const SizedBox(height: 12),
                    _challengeCard(
                      title: 'Puzzle Challenge',
                      description:
                          'Solve a puzzle to wake up your brain',
                      icon: Icons.extension_rounded,
                      value: 'puzzle',
                    ),
                    const SizedBox(height: 12),
                    _challengeCard(
                      title: 'Jigsaw Puzzle',
                      description:
                          'Complete a jigsaw puzzle to wake up',
                      icon: Icons.grid_view_rounded,
                      value: 'jigsaw',
                    ),
                    const SizedBox(height: 12),
                    _challengeCard(
                      title: 'Color Memory',
                      description:
                          'Remember six colors and their positions',
                      icon: Icons.palette_rounded,
                      value: 'color_memory',
                    ),
                    const SizedBox(height: 12),
                    _challengeCard(
                      title: 'Camera Challenge',
                      description:
                          'Take a photo of a selected object',
                      icon: Icons.camera_alt_rounded,
                      value: 'camera',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: () {
                    if (selectedChallenge == 'camera') {
                      _openCameraSelection();
                    } else if (selectedChallenge == 'jigsaw') {
                      _openJigsawDifficulty();
                    } else {
                      Navigator.pop(context, selectedChallenge);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: blueAccent,
                    foregroundColor: const Color(0xFF1C1C1E),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    'Done',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
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

  Widget _challengeCard({
    required String title,
    required String description,
    required IconData icon,
    required String value,
  }) {
    final bool isSelected = selectedChallenge == value;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () async {
        if (value == 'camera') {
          await _openCameraSelection();
          return;
        }

        if (value == 'jigsaw') {
          await _openJigsawDifficulty();
          return;
        }

        setState(() {
          selectedChallenge = value;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF34383D)
              : cardColor,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isSelected
                ? blueAccent
                : Colors.transparent,
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xFF45494E)
                    : const Color(0xFF3A3A3C),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Icon(
                icon,
                color: isSelected
                    ? blueAccent
                    : Colors.white,
                size: 28,
              ),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    description,
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(
                Icons.check_circle_rounded,
                color: blueAccent,
              ),
          ],
        ),
      ),
    );
  }
}

// =====================================================
// JIGSAW DIFFICULTY SCREEN
// =====================================================

class _JigsawDifficultyScreen extends StatelessWidget {
  const _JigsawDifficultyScreen();

  static const Color background = Color(0xFF1B1C1F);
  static const Color cardColor = Color(0xFF2A2C30);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        backgroundColor: background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back,
            color: Colors.white,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Jigsaw Puzzle',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Choose Difficulty',
              style: TextStyle(
                color: Colors.white,
                fontSize: 26,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Select the puzzle size.',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 30),
            _difficultyCard(
              context: context,
              title: 'Easy',
              subtitle: '2 × 2 Puzzle',
              value: 'jigsaw_easy',
              color: Colors.green,
            ),
            const SizedBox(height: 16),
            _difficultyCard(
              context: context,
              title: 'Medium',
              subtitle: '3 × 3 Puzzle',
              value: 'jigsaw_medium',
              color: Colors.orange,
            ),
            const SizedBox(height: 16),
            _difficultyCard(
              context: context,
              title: 'Hard',
              subtitle: '4 × 4 Puzzle',
              value: 'jigsaw_hard',
              color: Colors.red,
            ),
          ],
        ),
      ),
    );
  }

  Widget _difficultyCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required String value,
    required Color color,
  }) {
    return GestureDetector(
      onTap: () {
        Navigator.pop(context, value);
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: color.withValues(alpha: 0.35),
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                Icons.grid_4x4_rounded,
                color: color,
                size: 30,
              ),
            ),
            const SizedBox(width: 18),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 19,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: Colors.grey,
              size: 28,
            ),
          ],
        ),
      ),
    );
  }
}
