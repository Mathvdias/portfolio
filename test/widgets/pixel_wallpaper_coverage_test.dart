import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:portifolio/shared/widgets/pixel_wallpaper.dart';

/// PixelWallpaper refuses to start its timer when the binding's runtime type
/// contains "Test" (so that `pumpAndSettle` keeps working in the page tests).
/// This binding behaves exactly like the automated test binding but carries a
/// production-looking name, which lets this file exercise the real animation.
class _DesktopRuntimeBinding extends AutomatedTestWidgetsFlutterBinding {}

/// One `drawRect` call, snapshotted at call time (the painter reuses a single
/// mutable [Paint], so the paint itself cannot be kept).
class _DrawnRect {
  const _DrawnRect(this.rect, this.shader, this.color);

  final Rect rect;
  final Shader? shader;
  final Color color;
}

class _RecordingCanvas extends Fake implements Canvas {
  final drawn = <_DrawnRect>[];

  @override
  void drawRect(Rect rect, Paint paint) {
    drawn.add(_DrawnRect(rect, paint.shader, paint.color));
  }
}

const _size = Size(400, 300);
const _origin = Offset(200, 150);
const _outside = Offset(10, 10);

final _wallpaperPaint = find.descendant(
  of: find.byType(PixelWallpaper),
  matching: find.byType(CustomPaint),
);

/// Lays the wallpaper out as a 400x300 box whose top-left corner sits at
/// (200, 150), so local and global pointer coordinates differ.
Future<void> _pumpWallpaper(WidgetTester tester, {required bool animate}) {
  return tester.pumpWidget(
    Directionality(
      textDirection: TextDirection.ltr,
      child: Align(
        alignment: Alignment.topLeft,
        child: Padding(
          padding: EdgeInsets.only(left: _origin.dx, top: _origin.dy),
          child: SizedBox.fromSize(
            size: _size,
            child: PixelWallpaper(animate: animate),
          ),
        ),
      ),
    ),
  );
}

/// The painter currently attached to the wallpaper. It reads the state's clock
/// and pointer notifiers, so a reference kept from the first frame keeps
/// showing what is drawn on later frames.
CustomPainter _painterOf(WidgetTester tester) =>
    tester.widget<CustomPaint>(_wallpaperPaint).painter!;

List<_DrawnRect> _paint(CustomPainter painter) {
  final canvas = _RecordingCanvas();
  painter.paint(canvas, _size);
  return canvas.drawn;
}

List<Offset> _positions(CustomPainter painter) => [
  for (final d in _paint(painter)) d.rect.topLeft,
];

void main() {
  _DesktopRuntimeBinding();

  group('PixelWallpaper rendering', () {
    testWidgets('first frame draws the 70-particle CPU field inside its box', (
      tester,
    ) async {
      await _pumpWallpaper(tester, animate: false);

      final drawn = _paint(_painterOf(tester));

      expect(drawn, hasLength(70));
      for (final d in drawn) {
        expect(d.shader, isNull);
        expect(d.rect.left, inInclusiveRange(0, _size.width));
        expect(d.rect.top, inInclusiveRange(0, _size.height));
        // Pixel-art squares of 1, 2 or 3 px (right - left is not exact).
        expect(d.rect.width, closeTo(d.rect.height, 1e-9));
        expect(d.rect.width, closeTo(d.rect.width.round(), 1e-9));
        expect(d.rect.width.round(), inInclusiveRange(1, 3));
        expect(d.color.a, inInclusiveRange(0.15, 0.45));
      }
      // The field is scattered over the box, not stacked on one spot.
      expect(drawn.map((d) => d.rect.topLeft).toSet(), hasLength(70));
    });

    testWidgets('the particle field is deterministic across instances', (
      tester,
    ) async {
      await _pumpWallpaper(tester, animate: false);
      final first = _positions(_painterOf(tester));

      await tester.pumpWidget(const SizedBox());
      await _pumpWallpaper(tester, animate: false);

      expect(_positions(_painterOf(tester)), first);
    });

    testWidgets('stays seventy plain rectangles: no full-screen shader pass', (
      tester,
    ) async {
      await _pumpWallpaper(tester, animate: true);
      final painter = _painterOf(tester);

      await tester.pump(const Duration(seconds: 1));

      // Nothing swaps the painter in later (a fragment program used to).
      expect(_painterOf(tester), same(painter));
      final drawn = _paint(painter);
      expect(drawn, hasLength(70));
      expect(drawn.where((d) => d.shader != null), isEmpty);
      expect(
        drawn.map((d) => d.rect.width * d.rect.height).reduce((a, b) => a + b),
        lessThan(70 * 9 + 1),
        reason: 'the wallpaper touches a few hundred pixels, not the screen',
      );
    });
  });

  group('PixelWallpaper animation', () {
    testWidgets('particles fall at a steady per-particle speed and keep '
        'their column', (tester) async {
      await _pumpWallpaper(tester, animate: true);
      final cpuPainter = _painterOf(tester);
      final start = _positions(cpuPainter);

      await tester.pump(const Duration(seconds: 1));
      final afterOne = _positions(cpuPainter);
      await tester.pump(const Duration(seconds: 2));
      final afterThree = _positions(cpuPainter);

      for (var i = 0; i < start.length; i++) {
        expect(afterOne[i].dx, start[i].dx);
        expect(afterThree[i].dx, start[i].dx);

        // Falling wraps around at the bottom edge, hence the modulo.
        final firstSecond = (afterOne[i].dy - start[i].dy) % _size.height;
        final nextTwo = (afterThree[i].dy - afterOne[i].dy) % _size.height;
        // 1.2% to 3.7% of the height per second (30 frames of 33 ms = 0.99 s).
        expect(firstSecond, inInclusiveRange(3.6 * 0.99 - 1e-6, 11.1 + 1e-6));
        expect(nextTwo, closeTo(firstSecond * 2, 1e-6));
      }
    });

    testWidgets('repaints thirty times a second, whatever the display rate', (
      tester,
    ) async {
      await _pumpWallpaper(tester, animate: true);
      var repaints = 0;
      void count() => repaints++;
      final painter = _painterOf(tester)..addListener(count);

      // A 120 Hz display: 120 frames in one second.
      for (var i = 0; i < 120; i++) {
        await tester.pump(const Duration(microseconds: 8333));
      }
      painter.removeListener(count);

      expect(repaints, 30);
    });

    testWidgets('animate: false keeps the field frozen and asks for no frame', (
      tester,
    ) async {
      await _pumpWallpaper(tester, animate: false);
      final cpuPainter = _painterOf(tester);
      final start = _positions(cpuPainter);

      await tester.pump(const Duration(seconds: 1));
      await tester.pump(const Duration(seconds: 1));

      expect(_positions(cpuPainter), start);
      expect(tester.binding.hasScheduledFrame, isFalse);
      expect(tester.binding.transientCallbackCount, 0);
    });

    testWidgets('turning animate on starts the fall, turning it off '
        'freezes it again', (tester) async {
      await _pumpWallpaper(tester, animate: false);
      final cpuPainter = _painterOf(tester);
      final start = _positions(cpuPainter);

      await _pumpWallpaper(tester, animate: true);
      await tester.pump(const Duration(seconds: 1));
      final moved = _positions(cpuPainter);
      expect(moved, isNot(start));

      await _pumpWallpaper(tester, animate: false);
      await tester.pump(const Duration(seconds: 1));
      expect(_positions(cpuPainter), moved);
      expect(tester.binding.hasScheduledFrame, isFalse);
    });

    testWidgets('resuming continues from where the fall stopped', (
      tester,
    ) async {
      await _pumpWallpaper(tester, animate: true);
      final cpuPainter = _painterOf(tester);
      final start = _positions(cpuPainter);
      await tester.pump(const Duration(seconds: 1));
      final afterOne = _positions(cpuPainter);

      // Paused for a long while, e.g. behind another page.
      await _pumpWallpaper(tester, animate: false);
      await tester.pump(const Duration(seconds: 30));
      await _pumpWallpaper(tester, animate: true);
      await tester.pump(const Duration(seconds: 1));
      final resumed = _positions(cpuPainter);

      for (var i = 0; i < start.length; i++) {
        final firstSecond = (afterOne[i].dy - start[i].dy) % _size.height;
        final secondSecond = (resumed[i].dy - afterOne[i].dy) % _size.height;
        // One more second of fall: the pause is not caught up in one jump.
        expect(secondSecond, closeTo(firstSecond, 1e-6));
      }
    });

    testWidgets('rebuilding with the same animate value leaves the running '
        'animation alone', (tester) async {
      await _pumpWallpaper(tester, animate: true);
      final cpuPainter = _painterOf(tester);
      final start = _positions(cpuPainter);
      await tester.pump(const Duration(seconds: 1));
      final afterOne = _positions(cpuPainter);

      await _pumpWallpaper(tester, animate: true);
      // Same clock and pointer: the new painter has nothing new to draw.
      expect(_painterOf(tester).shouldRepaint(cpuPainter), isFalse);

      await tester.pump(const Duration(seconds: 1));
      final afterTwo = _positions(cpuPainter);
      for (var i = 0; i < start.length; i++) {
        final firstSecond = (afterOne[i].dy - start[i].dy) % _size.height;
        final secondSecond = (afterTwo[i].dy - afterOne[i].dy) % _size.height;
        // Neither restarted from the top nor driven by a second timer.
        expect(secondSecond, closeTo(firstSecond, 1e-6));
      }
    });

    testWidgets('removing the wallpaper stops the timer and releases its '
        'notifiers', (tester) async {
      await _pumpWallpaper(tester, animate: true);
      final cpuPainter = _painterOf(tester);
      await tester.pump(const Duration(seconds: 1));
      final last = _positions(cpuPainter);

      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 1));

      // A timer that outlived the widget would write to a disposed notifier
      // (an error) and is also reported by the test framework when it ends.
      expect(tester.takeException(), isNull);
      expect(tester.binding.hasScheduledFrame, isFalse);
      expect(_positions(cpuPainter), last);
      // The painter repaints off the state's clock notifier: once the state is
      // disposed, that notifier must refuse new listeners.
      expect(() => cpuPainter.addListener(() {}), throwsFlutterError);
    });
  });

  group('PixelWallpaper pointer repulsion', () {
    /// Hovers 10 px away from the particle closest to the centre of the box
    /// and returns the pointer position in the wallpaper's local coordinates.
    Future<(TestGesture, Offset)> hoverNearCentralParticle(
      WidgetTester tester,
      List<Offset> particles,
    ) async {
      final centre = _size.center(Offset.zero);
      final target = particles.reduce(
        (a, b) => (a - centre).distance <= (b - centre).distance ? a : b,
      );
      final pointer = target + const Offset(6, 8);

      final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await gesture.addPointer(location: _outside);
      addTearDown(gesture.removePointer);
      await gesture.moveTo(_origin + pointer);
      return (gesture, pointer);
    }

    testWidgets('particles within 100 px are pushed straight away from the '
        'pointer, the rest stay put', (tester) async {
      await _pumpWallpaper(tester, animate: false);
      final cpuPainter = _painterOf(tester);
      final before = _positions(cpuPainter);

      final (_, pointer) = await hoverNearCentralParticle(tester, before);
      final after = _positions(cpuPainter);

      final pushes = <(double distance, double push)>[];
      var untouched = 0;
      for (var i = 0; i < before.length; i++) {
        final fromPointer = before[i] - pointer;
        final shift = after[i] - before[i];
        if (fromPointer.distance >= 100) {
          expect(shift, Offset.zero);
          untouched++;
          continue;
        }
        pushes.add((fromPointer.distance, shift.distance));
        expect(shift.distance, inInclusiveRange(0, 40));
        // Radial: the shift is parallel to pointer -> particle and points
        // outwards.
        expect(
          shift.dx * fromPointer.dy - shift.dy * fromPointer.dx,
          closeTo(0, 1e-6),
        );
        expect(
          shift.dx * fromPointer.dx + shift.dy * fromPointer.dy,
          greaterThanOrEqualTo(0),
        );
      }

      expect(untouched, greaterThan(0));
      expect(pushes, isNotEmpty);
      // The closer to the pointer, the stronger the push; the particle that
      // was 10 px away gets almost the full 40 px.
      pushes.sort((a, b) => a.$1.compareTo(b.$1));
      expect(pushes.first.$1, closeTo(10, 1e-6));
      expect(pushes.first.$2, greaterThan(35));
      for (var i = 1; i < pushes.length; i++) {
        expect(pushes[i].$2, lessThanOrEqualTo(pushes[i - 1].$2));
      }
    });

    testWidgets('particles return to their lane when the pointer leaves', (
      tester,
    ) async {
      await _pumpWallpaper(tester, animate: false);
      final cpuPainter = _painterOf(tester);
      final before = _positions(cpuPainter);

      final (gesture, _) = await hoverNearCentralParticle(tester, before);
      expect(_positions(cpuPainter), isNot(before));

      await gesture.moveTo(_outside);

      expect(_positions(cpuPainter), before);
    });
  });
}
