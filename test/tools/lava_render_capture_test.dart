// Renders the bundled OpenLava demos through the real LavaPainter and dumps
// PNG frames so the output can be inspected outside the app.
// Run: flutter test test/tools/lava_render_capture_test.dart
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lava_flutter/lava_flutter.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('capture lava frames', (tester) async {
    final outDir = Platform.environment['LAVA_CAPTURE_DIR'];
    if (outDir == null) return;
    await tester.runAsync(() async {
      for (final type in LavaDemoType.values) {
        final bundle = await LavaBundle.demo(type: type);
        for (final size in [140.0, 44.0]) {
          final controller = LavaController(
            totalFrames: bundle.manifest.totalFrames,
            fps: bundle.manifest.frameRate,
            autoPlay: false,
          );
          final key = GlobalKey();
          await tester.pumpWidget(
            MaterialApp(
              home: Scaffold(
                backgroundColor: const Color(0xFF1E1E2E),
                body: Center(
                  child: RepaintBoundary(
                    key: key,
                    child: LavaIcon(
                      bundle: bundle,
                      controller: controller,
                      size: size,
                    ),
                  ),
                ),
              ),
            ),
          );
          final n = bundle.manifest.totalFrames;
          for (final f in [0, n ~/ 4, n ~/ 2, (3 * n) ~/ 4, n - 1]) {
            controller.seekToFrame(f);
            await tester.pump();
            final boundary =
                key.currentContext!.findRenderObject() as RenderRepaintBoundary;
            final image = await boundary.toImage(pixelRatio: 2.0);
            final bytes = await image.toByteData(
              format: ui.ImageByteFormat.png,
            );
            final file = File(
              '$outDir/${type.name}_${size.toInt()}_f${f.toString().padLeft(3, '0')}.png',
            );
            await file.writeAsBytes(bytes!.buffer.asUint8List());
          }
          controller.dispose();
        }
      }
    });
  });
}
