import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lava_flutter/lava_flutter.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('LavaIcon & LavaInteractive Widgets', () {
    testWidgets('LavaIcon.demo renders without errors', (tester) async {
      await tester.runAsync(() async {
        await tester.pumpWidget(
          const Directionality(
            textDirection: TextDirection.ltr,
            child: Center(child: LavaIcon.demo(size: 64, interactive: true)),
          ),
        );
        await Future<void>.delayed(const Duration(milliseconds: 300));
      });
      await tester.pump();

      expect(find.byType(LavaIcon), findsOneWidget);
      expect(find.byType(CustomPaint), findsOneWidget);
      expect(find.byType(LavaInteractive), findsOneWidget);

      LavaDemoBaker.clearCache();
    });

    testWidgets('LavaIcon.demoSunflower renders without errors', (tester) async {
      await tester.runAsync(() async {
        await tester.pumpWidget(
          const Directionality(
            textDirection: TextDirection.ltr,
            child: Center(child: LavaIcon.demoSunflower(size: 64, interactive: true)),
          ),
        );
        await Future<void>.delayed(const Duration(milliseconds: 300));
      });
      await tester.pump();

      expect(find.byType(LavaIcon), findsOneWidget);
      expect(find.byType(CustomPaint), findsOneWidget);
      expect(find.byType(LavaInteractive), findsOneWidget);

      LavaDemoBaker.clearCache();
    });

    testWidgets('LavaInteractive handles taps and state transitions', (
      tester,
    ) async {
      bool tapped = false;
      final states = <LavaInteractiveState>[];

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Center(
            child: LavaInteractive(
              enableHaptics: false,
              onTap: () {
                tapped = true;
              },
              onStateChanged: (state) {
                states.add(state);
              },
              child: const SizedBox(width: 50, height: 50),
            ),
          ),
        ),
      );

      expect(states, isEmpty);

      // Tap down
      await tester.tap(find.byType(LavaInteractive));
      await tester.pumpAndSettle();

      expect(tapped, isTrue);
      expect(states, contains(LavaInteractiveState.pressed));
    });

    testWidgets('LavaInteractive rotates frames via horizontal pan drag', (
      tester,
    ) async {
      final controller = LavaController(totalFrames: 24, autoPlay: false);

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Center(
            child: LavaInteractive(
              controller: controller,
              dragToRotate: true,
              child: const SizedBox(width: 100, height: 100),
            ),
          ),
        ),
      );

      expect(controller.currentFrame, 0);

      // Drag right by 40 pixels (advances frames)
      await tester.drag(find.byType(LavaInteractive), const Offset(40, 0));
      await tester.pump();

      expect(controller.currentFrame, greaterThan(0));

      controller.dispose();
    });

    test('LavaPainter shouldRepaint reflects property changes', () async {
      final bundle = await LavaBundle.procedural();
      final controller1 = LavaController(totalFrames: 24, autoPlay: false);
      final controller2 = LavaController(totalFrames: 24, autoPlay: false);

      final painter1 = LavaPainter(
        atlas: bundle.atlas,
        manifest: bundle.manifest,
        controller: controller1,
      );

      final painter2 = LavaPainter(
        atlas: bundle.atlas,
        manifest: bundle.manifest,
        controller: controller1,
      );

      expect(painter1.shouldRepaint(painter2), isFalse);

      final painterDifferentController = LavaPainter(
        atlas: bundle.atlas,
        manifest: bundle.manifest,
        controller: controller2,
      );
      expect(painter1.shouldRepaint(painterDifferentController), isTrue);

      final painterDifferentFit = LavaPainter(
        atlas: bundle.atlas,
        manifest: bundle.manifest,
        controller: controller1,
        fit: BoxFit.cover,
      );
      expect(painter1.shouldRepaint(painterDifferentFit), isTrue);

      controller1.dispose();
      controller2.dispose();
      LavaDemoBaker.clearCache();
    });

    testWidgets('LavaPainter OpenLava diff mode blits with boundary clamping without error', (
      tester,
    ) async {
      final img1 = await LavaDemoBaker.bakeAtlas(type: LavaDemoType.macintosh);
      final img2 = await LavaDemoBaker.bakeAtlas(type: LavaDemoType.sunflower);

      final manifest = const LavaManifest(
        tileWidth: 180,
        tileHeight: 162,
        columns: 6,
        rows: 4,
        totalFrames: 2,
        cellSize: 32,
        rawFrames: [
          {'type': 'key', 'imageIndex': 0},
          {
            'type': 'diff',
            'diffs': [
              // Intentionally specify blocks that exceed 180x162 bounds
              [0, 0, 6, 1, 0],
              [0, 30, 6, 1, 30],
              [1, 0, 4, 4, 1],
            ],
          },
        ],
      );

      final controller = LavaController(totalFrames: 2, autoPlay: false);

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Center(
            child: CustomPaint(
              size: const Size(180, 162),
              painter: LavaPainter(
                images: [img1, img2],
                manifest: manifest,
                controller: controller,
              ),
            ),
          ),
        ),
      );

      // Frame 0 (key)
      expect(controller.currentFrame, 0);
      expect(tester.takeException(), isNull);

      // Frame 1 (diff with out-of-bounds tile blits)
      controller.seekToFrame(1);
      await tester.pump();
      expect(controller.currentFrame, 1);
      expect(tester.takeException(), isNull);

      controller.dispose();
      LavaDemoBaker.clearCache();
    });
  });
}
