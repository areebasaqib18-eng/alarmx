import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

class ColorMemoryChallengeDialog extends StatefulWidget {
  const ColorMemoryChallengeDialog({super.key});

  @override
  State<ColorMemoryChallengeDialog> createState() =>
      _ColorMemoryChallengeDialogState();
}

class _ColorMemoryChallengeDialogState
    extends State<ColorMemoryChallengeDialog> {
  static const List<Color> _colors = [
    Color(0xFFFF4545),
    Color(0xFF438AFF),
    Color(0xFF40C878),
    Color(0xFFFFD740),
    Color(0xFFB76AFF),
    Color(0xFFFF914D),
  ];

  final Random _random = Random();

  late List<Color> _targetColors;
  late List<Color?> _answers;

  Timer? _revealTimer;
  Timer? _recallTimer;
  Timer? _messageTimer;

  OverlayEntry? _messageOverlay;

  bool _revealing = true;
  bool _isClosing = false;

  @override
  void initState() {
    super.initState();

    _targetColors = List<Color>.from(_colors)..shuffle(_random);
    _answers = List<Color?>.filled(6, null);

    _showSequenceAgain();
  }

  void _showMessage(String message, {bool isError = true}) {
    _messageTimer?.cancel();

    _messageOverlay?.remove();
    _messageOverlay = null;

    _messageOverlay = OverlayEntry(
      builder: (overlayContext) {
        return Positioned(
          left: 20,
          right: 20,
          bottom: MediaQuery.of(overlayContext).padding.bottom + 24,
          child: Material(
            color: Colors.transparent,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 18,
                vertical: 14,
              ),
              decoration: BoxDecoration(
                color: const Color(0xFF2C2C2E),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isError
                      ? const Color(0xFFFF9F0A)
                      : const Color(0xFF40C878),
                  width: 1,
                ),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 12,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isError
                        ? Icons.info_outline_rounded
                        : Icons.check_circle_outline_rounded,
                    color: isError
                        ? const Color(0xFFFF9F0A)
                        : const Color(0xFF40C878),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      message,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );

    Overlay.of(context).insert(_messageOverlay!);

    _messageTimer = Timer(const Duration(seconds: 5), () {
      _messageOverlay?.remove();
      _messageOverlay = null;
    });
  }

  void _showSequenceAgain({bool resetAnswers = false}) {
    _revealTimer?.cancel();
    _recallTimer?.cancel();

    if (!mounted || _isClosing) return;

    setState(() {
      _revealing = true;

      if (resetAnswers) {
        _answers = List<Color?>.filled(6, null);
      }
    });

    _revealTimer = Timer(
      const Duration(seconds: 5),
      () {
        if (!mounted || _isClosing) return;

        setState(() {
          _revealing = false;
        });

        _startRecallTimer();
      },
    );
  }

  void _startRecallTimer() {
    _recallTimer?.cancel();

    _recallTimer = Timer(
      const Duration(seconds: 45),
      () {
        if (!mounted || _isClosing) return;

        _showSequenceAgain();
      },
    );
  }

  Future<void> _chooseColor(int index) async {
    if (_revealing || _isClosing) return;

    final availableColors = _colors.where((color) {
      for (int i = 0; i < _answers.length; i++) {
        if (i != index && _answers[i] == color) {
          return false;
        }
      }

      return true;
    }).toList();

    final selectedColor = await showDialog<Color>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: const Color(0xFF202833),
          title: const Text(
            'Choose a color',
            style: TextStyle(color: Colors.white),
          ),
          content: Wrap(
            spacing: 12,
            runSpacing: 12,
            children: availableColors.map((color) {
              return InkWell(
                onTap: () {
                  Navigator.of(dialogContext).pop(color);
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              );
            }).toList(),
          ),
        );
      },
    );

    if (!mounted || _isClosing || selectedColor == null) {
      return;
    }

    setState(() {
      _answers[index] = selectedColor;
    });
  }

  void _checkAnswers() {
    if (_isClosing || _revealing) return;

    // Incomplete answer: show a message without any button.
    if (_answers.any((color) => color == null)) {
      _showMessage('Please select all six colors!');
      return;
    }

    bool correct = true;

    for (int i = 0; i < 6; i++) {
      if (_answers[i] != _targetColors[i]) {
        correct = false;
        break;
      }
    }

    // Correct answer: complete the challenge.
    if (correct) {
      _isClosing = true;

      _revealTimer?.cancel();
      _recallTimer?.cancel();
      _messageTimer?.cancel();

      _messageOverlay?.remove();
      _messageOverlay = null;

      Navigator.of(context).pop(true);
      return;
    }

    // Wrong answer: show a temporary message and restart automatically.
    _revealTimer?.cancel();
    _recallTimer?.cancel();

    _showMessage('Wrong colors! Try again!');

    _showSequenceAgain(resetAnswers: true);
  }

  @override
  void dispose() {
    _revealTimer?.cancel();
    _recallTimer?.cancel();
    _messageTimer?.cancel();

    _messageOverlay?.remove();
    _messageOverlay = null;

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: AlertDialog(
        backgroundColor: const Color(0xFF202833),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text(
          'Color Memory',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 270,
              height: 180,
              child: GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: 6,
                gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 1,
                ),
                itemBuilder: (context, index) {
                  final Color blockColor = _revealing
                      ? _targetColors[index]
                      : (_answers[index] ?? const Color(0xFF454B55));

                  return GestureDetector(
                    onTap: () => _chooseColor(index),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 120),
                      decoration: BoxDecoration(
                        color: blockColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.18),
                          width: 1,
                        ),
                      ),
                      child: Center(
                        child: Icon(
                          _answers[index] != null && !_revealing
                              ? Icons.check
                              : Icons.circle,
                          color: Colors.white.withValues(alpha: 0.85),
                          size: 22,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            if (_revealing)
              const Text(
                'Colors will hide automatically.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFFB7C0CC),
                  fontSize: 12,
                ),
              )
            else
              const Text(
                'Colors reappear automatically after 45 seconds.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFFB7C0CC),
                  fontSize: 12,
                ),
              ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: !_revealing ? _checkAnswers : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF9F0A),
                  disabledBackgroundColor: const Color(0xFF454B55),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Submit',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}