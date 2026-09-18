import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lava_flutter/lava_flutter.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('LavaIcon & LavaInteractive Widgets', () {
    testWidgets('LavaIcon.demo renders without errors', (tester) async {
      await tester.pumpWidget(
        const Directionality(
          textDirection: TextDirection.ltr,
          child: Center(child: LavaIcon.demo(size: 64, interactive: true)),
        ),
      );

      // Await async bundle loading and advance a few frames
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(LavaIcon), findsOneWidget);
      expect(find.byType(CustomPaint), findsOneWidget);
      expect(find.byType(LavaInteractive), findsOneWidget);

      LavaDemoBaker.clearCache();
    });

    testWidgets('LavaIcon.demoTree renders without errors', (tester) async {
      await tester.pumpWidget(
        const Directionality(
          textDirection: TextDirection.ltr,
          child: Center(child: LavaIcon.demoTree(size: 64, interactive: true)),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

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
      final bundle = await LavaBundle.demo();
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
  });
}
