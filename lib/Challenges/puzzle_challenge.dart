import 'dart:math';

import 'package:flutter/material.dart';

class PuzzleChallengeDialog extends StatefulWidget {
  const PuzzleChallengeDialog({
    super.key,
  });

  @override
  State<PuzzleChallengeDialog> createState() =>
      _PuzzleChallengeDialogState();
}

class _PuzzleChallengeDialogState
    extends State<PuzzleChallengeDialog> {
  late final TextEditingController _answerController;

  bool _isClosing = false;

  late final Map<String, dynamic> _puzzle;

  static final List<Map<String, dynamic>> _puzzles = [
    {
      'question': 'What comes next?\n\n2, 4, 6, 8, ?',
      'answer': 10,
    },
    {
      'question': 'What comes next?\n\n5, 10, 15, 20, ?',
      'answer': 25,
    },
    {
      'question': 'What comes next?\n\n3, 6, 9, 12, ?',
      'answer': 15,
    },
    {
      'question': 'What comes next?\n\n1, 3, 5, 7, ?',
      'answer': 9,
    },
    {
      'question': 'What comes next?\n\n10, 20, 30, 40, ?',
      'answer': 50,
    },
    {
      'question': 'What comes next?\n\n2, 6, 10, 14, ?',
      'answer': 18,
    },
    {
      'question': 'What comes next?\n\n20, 18, 16, 14, ?',
      'answer': 12,
    },
    {
      'question': 'What comes next?\n\n4, 8, 12, 16, ?',
      'answer': 20,
    },
    {
      'question': 'What comes next?\n\n1, 2, 4, 8, ?',
      'answer': 16,
    },
    {
      'question': 'What comes next?\n\n30, 25, 20, 15, ?',
      'answer': 10,
    },
  ];

  static final Random _random = Random();

  static final List<int> _remainingPuzzleIndexes = [];

  int _getRandomPuzzleIndex() {
    if (_remainingPuzzleIndexes.isEmpty) {
      _remainingPuzzleIndexes.addAll(
        List<int>.generate(
          _puzzles.length,
          (index) => index,
        ),
      );

      _remainingPuzzleIndexes.shuffle(_random);
    }

    return _remainingPuzzleIndexes.removeLast();
  }

  @override
  void initState() {
    super.initState();

    _answerController = TextEditingController();

    final puzzleIndex = _getRandomPuzzleIndex();

    _puzzle = _puzzles[puzzleIndex];
  }

  void _cancel() {
    if (_isClosing || !mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Solve the challenge to turn off the alarm.',
        ),
      ),
    );
  }

  void _submit() {
    if (_isClosing || !mounted) return;

    final answer = int.tryParse(
      _answerController.text.trim(),
    );

    if (answer == _puzzle['answer']) {
      _isClosing = true;

      Navigator.of(context).pop(true);
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Wrong answer. Alarm will stay ON.',
        ),
      ),
    );

    _answerController.clear();
  }

  @override
  void dispose() {
    _answerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF202833),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      title: const Text(
        'Puzzle Challenge',
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Complete the puzzle to turn off the alarm.',
            style: TextStyle(
              color: Color(0xFFB7C0CC),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            _puzzle['question'],
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 23,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _answerController,
            keyboardType: TextInputType.number,
            autofocus: true,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
            ),
            decoration: const InputDecoration(
              hintText: 'Enter answer',
              hintStyle: TextStyle(
                color: Colors.white38,
              ),
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(
                  color: Color(0xFF7C9CFF),
                ),
              ),
              focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(
                  color: Color(0xFF7C9CFF),
                ),
              ),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _cancel,
          child: const Text(
            'Cancel',
            style: TextStyle(
              color: Colors.white70,
            ),
          ),
        ),
        ElevatedButton(
          onPressed: _submit,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF7C9CFF),
            foregroundColor: Colors.white,
          ),
          child: const Text(
            'Submit',
          ),
        ),
      ],
    );
  }
}