import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_image_labeling/google_mlkit_image_labeling.dart';
import 'package:path_provider/path_provider.dart';

void main() => runApp(const MaterialApp(home: _Dump()));

class _Dump extends StatefulWidget {
  const _Dump();
  @override
  State<_Dump> createState() => _DumpState();
}

class _DumpState extends State<_Dump> {
  String out = 'running...';

  @override
  void initState() {
    super.initState();
    _run();
  }

  Future<void> _run() async {
    final dir = await getTemporaryDirectory();
    final modelFile = File('${dir.path}/efficientnet_lite0.tflite');
    await modelFile.writeAsBytes(
      (await rootBundle.load('assets/models/efficientnet_lite0.tflite'))
          .buffer
          .asUint8List(),
    );
    final labeler = ImageLabeler(
      options: LocalLabelerOptions(
        modelPath: modelFile.path,
        confidenceThreshold: 0.02,
        maxCount: 15,
      ),
    );
    final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
    final assets = manifest
        .listAssets()
        .where((a) => a.startsWith('assets/reference_images/'))
        .toList()
      ..sort();
    final sb = StringBuffer();
    for (final a in assets) {
      final bytes = (await rootBundle.load(a)).buffer.asUint8List();
      final f = File('${dir.path}/${a.split('/').last}');
      await f.writeAsBytes(bytes);
      final res = await labeler.processImage(InputImage.fromFilePath(f.path));
      final labels = res
          .map((r) => '${r.label}:${r.confidence.toStringAsFixed(2)}')
          .join(',');
      final line = 'LBL|${a.split('/').last}|$labels';
      debugPrint(line);
      sb.writeln(line);
    }
    debugPrint('LBL|DONE');
    await labeler.close();
    if (mounted) setState(() => out = sb.toString());
  }

  @override
  Widget build(BuildContext context) =>
      Scaffold(body: SingleChildScrollView(child: Text(out)));
}
