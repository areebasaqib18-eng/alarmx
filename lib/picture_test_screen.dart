import 'dart:io';

import 'package:flutter/material.dart';
import 'package:camera/camera.dart';

import 'object_detector.dart';
import 'object_matcher.dart';

class PictureTestScreen extends StatefulWidget {
  final String targetObject;

  /// All objects the user selected for this alarm. Used to offer a different
  /// object when the current one cannot be recognised.
  final List<String> candidateObjects;

  const PictureTestScreen({
    super.key,
    required this.targetObject,
    this.candidateObjects = const [],
  });

  @override
  State<PictureTestScreen> createState() => _PictureTestScreenState();
}

class _PictureTestScreenState extends State<PictureTestScreen> {
  static const int _failsBeforeSwap = 2;

  CameraController? _controller;
  final ObjectDetector _detector = ObjectDetector();

  late String _target;
  final Set<String> _skipped = {};

  bool _loading = true;
  bool _checking = false;
  bool _passed = false;
  bool _cameraFailed = false;
  int _failedAttempts = 0;

  String _message = 'Camera starting...';
  List<String> _labels = [];
  String? _photoPath;

  @override
  void initState() {
    super.initState();

    _target = widget.targetObject;

    _detector.init();

    _startCamera();
  }

  Future<void> _startCamera() async {
    CameraController? controller;

    try {
      final cameras = await availableCameras();

      if (cameras.isEmpty) {
        throw Exception('No camera available on this device.');
      }

      final camera = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );

      controller = CameraController(
        camera,
        ResolutionPreset.high,
        enableAudio: false,
      );

      await controller.initialize();

      try {
        await controller.setFlashMode(FlashMode.off);
        await controller.setFocusMode(FocusMode.auto);
      } catch (_) {
        // Not every camera supports these; the photo still works.
      }

      if (!mounted) {
        await controller.dispose();
        return;
      }

      setState(() {
        _controller = controller;
        _loading = false;
        _message = 'Show ${_articleFor(_target)} to the camera.';
      });
    } catch (e) {
      await controller?.dispose();

      if (!mounted) return;

      setState(() {
        _loading = false;
        _cameraFailed = true;
        _message = 'Camera setup error: $e';
      });
    }
  }

  String _normalize(String value) => ObjectMatcher.normalize(value);

  String _articleFor(String object) {
    final target = _normalize(object);

    const pluralObjects = {'keys', 'shoes', 'glasses', 'headphones'};

    if (pluralObjects.contains(target)) {
      return 'your $target';
    }

    if (target == 'umbrella') {
      return 'an umbrella';
    }

    return 'a $target';
  }

  /// Other selected objects the user has not already been swapped away from.
  List<String> get _swapOptions {
    final current = _normalize(_target);

    return widget.candidateObjects.where((o) {
      final n = _normalize(o);
      return n != current && !_skipped.contains(n);
    }).toList();
  }

  bool get _canSwap => _swapOptions.isNotEmpty;

  bool get _offerSwap =>
      !_passed &&
      _canSwap &&
      (_failedAttempts >= _failsBeforeSwap ||
          (ObjectMatcher.isHardToDetect(_target) && _failedAttempts >= 1));

  void _swapObject() {
    final options = _swapOptions;

    if (options.isEmpty) return;

    // Prefer an object the camera is good at.
    final easy = options.where((o) => !ObjectMatcher.isHardToDetect(o));
    final pool = easy.isNotEmpty ? easy.toList() : options;
    pool.shuffle();

    _skipped.add(_normalize(_target));

    setState(() {
      _target = pool.first;
      _failedAttempts = 0;
      _photoPath = null;
      _labels = [];
      _message = 'Show ${_articleFor(_target)} to the camera.';
    });
  }

  void _retake() {
    setState(() {
      _photoPath = null;
      _labels = [];
      _message = 'Show ${_articleFor(_target)} to the camera.';
    });
  }

  Future<void> _takePhoto() async {
    final controller = _controller;

    if (controller == null ||
        !controller.value.isInitialized ||
        _checking ||
        _passed) {
      return;
    }

    setState(() {
      _checking = true;
      _labels = [];
      _message = 'Checking your photo...';
    });

    try {
      final photo = await controller.takePicture();

      if (!mounted) return;

      setState(() {
        _photoPath = photo.path;
      });

      final detected = await _detector.detect(photo.path);

      final result = ObjectMatcher.match(_target, detected);

      debugPrint(
        '📸 target=$_target matched=${result.matched} '
        'via=${result.reason} labels='
        '${detected.take(12).map((d) => "${d.label}:${d.confidence.toStringAsFixed(2)}").join(", ")}',
      );

      if (!mounted) return;

      setState(() {
        _labels = detected
            .take(6)
            .map((d) => '${d.label} ${(d.confidence * 100).round()}%')
            .toList();
        _passed = result.matched;

        if (!result.matched) _failedAttempts++;

        _message = result.matched
            ? 'Challenge Passed! $_target detected.'
            : 'Could not see ${_articleFor(_target)}. '
                  'Get closer, add light and fill the frame.';
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _photoPath = null;
        _message = 'Photo check error: $e';
      });
    } finally {
      if (mounted) {
        setState(() {
          _checking = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    _detector.dispose();
    super.dispose();
  }

  Widget _buildReferenceImage() {
    final object = _normalize(_target);

    const imageNames = <String, String>{
      'tree': 'tree.jpg',
'plant': 'plant.jpg',
'car': 'car.jpg',
'bike': 'bike.jpg',
'road': 'road.jpg',
      'bag': 'bag.jpg',
      'ball': 'ball.jpg',
      'book': 'book.jpg',
      'bottle cap': 'bottle cap.jpg',
      'bottle': 'bottle.jpg',
      'chair': 'chair.jpg',
      'comb': 'comb.jpg',
      'cup': 'cup.jpg',
      'glasses': 'glasses.jpg',
      'headphones': 'headphones.jpg',
      'keyboard': 'keyboard.jpg',
      'keys': 'Keys.jpg',
      'laptop': 'laptop.jpg',
      'mouse': 'mouse.jpg',
      'notebook': 'notebook.jpg',
      'pen': 'pen.jpg',
      'phone': 'phone.jpg',
      'pillow': 'pillow.jpg',
      'plate': 'plate.jpg',
      'remote': 'remote.jpg',
      'shoes': 'shoes.jpg',
      'soap': 'soap.jpg',
      'spoon': 'spoon.jpg',
      'teddy bear': 'teddy_bear.jpg',
      'toothbrush': 'toothbrush.jpg',
      'toothpaste': 'toothpaste.jpg',
      'towel': 'towel.jpg',
      'umbrella': 'umbrella.jpg',
      'wallet': 'wallet.jpg',
      'watch': 'watch.jpg',
    };

    final fileName = imageNames[object];

    if (fileName == null) {
      return const SizedBox(
        height: 100,
        width: 120,
        child: Center(child: Icon(Icons.image_not_supported)),
      );
    }

    return Container(
      height: 120,
      width: 150,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.blueGrey.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Image.asset(
        'assets/reference_images/$fileName',
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Text(
                'Could not load image:\n$fileName',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red, fontSize: 12),
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // The alarm is ringing: the only ways out are passing the challenge or,
    // if the camera itself is broken, the "Continue without camera" button.
    return PopScope(
      canPop: false,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Camera Challenge'),
          automaticallyImplyLeading: false,
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Text(
                  'Find: $_target',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                _buildReferenceImage(),
                const SizedBox(height: 16),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: _loading
                        ? const Center(child: CircularProgressIndicator())
                        : _photoPath != null
                        ? Image.file(
                            File(_photoPath!),
                            width: double.infinity,
                            fit: BoxFit.contain,
                          )
                        : _controller != null &&
                              _controller!.value.isInitialized
                        ? CameraPreview(_controller!)
                        : Center(child: Text(_message)),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  _message,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: _passed
                        ? Colors.green
                        : _message.toLowerCase().contains('error')
                        ? Colors.red
                        : null,
                  ),
                ),
                if (_labels.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Detected: ${_labels.join(', ')}',
                    textAlign: TextAlign.center,
                  ),
                ],
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: _photoPath != null && !_passed && !_checking
                      ? ElevatedButton.icon(
                          onPressed: _retake,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Try Again'),
                        )
                      : ElevatedButton.icon(
                          onPressed: _loading || _checking || _passed
                              ? null
                              : _takePhoto,
                          icon: const Icon(Icons.camera_alt),
                          label: Text(_checking ? 'Checking...' : 'Take Photo'),
                        ),
                ),
                if (_offerSwap && !_checking) ...[
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _swapObject,
                      icon: const Icon(Icons.swap_horiz),
                      label: const Text('Try a different object'),
                    ),
                  ),
                ],
                if (_cameraFailed) ...[
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('Continue without camera'),
                    ),
                  ),
                ],
                if (_passed) ...[
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context, true);
                      },
                      child: const Text('Complete Challenge'),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
