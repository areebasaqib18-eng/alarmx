import 'package:flutter/material.dart';

class MathChallengeDialog extends StatefulWidget {
  final int number1;
  final int number2;
  final int correctAnswer;

  const MathChallengeDialog({
    super.key,
    required this.number1,
    required this.number2,
    required this.correctAnswer,
  });

  @override
  State<MathChallengeDialog> createState() =>
      _MathChallengeDialogState();
}

class _MathChallengeDialogState
    extends State<MathChallengeDialog> {
  late final TextEditingController _answerController;

  bool _isClosing = false;

  @override
  void initState() {
    super.initState();

    _answerController = TextEditingController();
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

    if (answer == widget.correctAnswer) {
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
        'Math Challenge',
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Solve this question to turn off the alarm.',
            style: TextStyle(
              color: Color(0xFFB7C0CC),
            ),
          ),

          const SizedBox(height: 20),

          Text(
            '${widget.number1} + ${widget.number2} = ?',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
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