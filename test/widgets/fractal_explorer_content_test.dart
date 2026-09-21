import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:portifolio/core/services/wasm_engine_service.dart';
import 'package:portifolio/core/services/wasm_engine_service_stub.dart';
import 'package:portifolio/shared/widgets/fractal_explorer_content.dart';

/// One `generateFractal` request, as the engine received it.
class _FractalCall {
  const _FractalCall({
    required this.width,
    required this.height,
    required this.zoom,
    required this.offsetX,
    required this.offsetY,
    required this.maxIterations,
    required this.isJulia,
    required this.cxJulia,
    required this.cyJulia,
    required this.time,
  });

  final int width;
  final int height;
  final double zoom;
  final double offsetX;
  final double offsetY;
  final int maxIterations;
  final bool isJulia;
  final double cxJulia;
  final double cyJulia;
  final double time;

  int get pixels => width * height;
}

/// Stands in for the WASM engine: records every request and hands back a
/// buffer shaped like the real one (800x600 RGBA, rows packed at the start).
class _FakeEngine implements WasmEngineService {
  _FakeEngine({
    this.ready = true,
    this.initError,
    this.initGate,
    this.renderCost = Duration.zero,
  });

  static const List<int> pixel = [10, 200, 30, 255];

  bool ready;
  final Object? initError;
  final Completer<void>? initGate;

  /// Wall-clock time each `generateFractal` call burns; the widget measures
  /// it with a real Stopwatch to size the next frame.
  final Duration renderCost;

  /// When set, the next buffer is too small for the requested frame.
  bool truncateNextBuffer = false;

  final List<_FractalCall> calls = [];

  final Uint8List _memory = () {
    final bytes = Uint8List(800 * 600 * 4);
    for (var i = 0; i < bytes.length; i++) {
      bytes[i] = pixel[i % 4];
    }
    return bytes;
  }();

  @override
  bool get isReady => ready;

  @override
  int get memoryBytes => _memory.length;

  @override
  Future<void> init() async {
    if (initGate != null) await initGate!.future;
    if (initError != null) throw initError!;
  }

  @override
  void generateFractal({
    required int width,
    required int height,
    required double zoom,
    required double offsetX,
    required double offsetY,
    required int maxIterations,
    required bool isJulia,
    required double cxJulia,
    required double cyJulia,
    required double time,
  }) {
    calls.add(
      _FractalCall(
        width: width,
        height: height,
        zoom: zoom,
        offsetX: offsetX,
        offsetY: offsetY,
        maxIterations: maxIterations,
        isJulia: isJulia,
        cxJulia: cxJulia,
        cyJulia: cyJulia,
        time: time,
      ),
    );
    final clock = Stopwatch()..start();
    while (clock.elapsed < renderCost) {}
  }

  @override
  Uint8List getPixelBuffer() {
    if (truncateNextBuffer) {
      truncateNextBuffer = false;
      return Uint8List(16);
    }
    return _memory;
  }
}

/// What the fractal layer puts on the canvas.
class _PaintedFrame {
  const _PaintedFrame(this.image, this.source, this.destination, this.quality);

  final ui.Image image;
  final Rect source;
  final Rect destination;
  final FilterQuality quality;
}

final Finder _fractalLayer = find.byWidgetPredicate(
  (widget) =>
      widget is CustomPaint &&
      widget.painter.runtimeType.toString() == '_FractalPainter',
);

/// Paints the fractal layer on a recording canvas and returns the frame it
/// drew, or null when it drew nothing.
_PaintedFrame? _paintedFrame(WidgetTester tester) {
  if (_fractalLayer.evaluate().isEmpty) return null;
  final canvas = TestRecordingCanvas();
  tester
      .renderObject(_fractalLayer)
      .paint(TestRecordingPaintingContext(canvas), Offset.zero);
  for (final recorded in canvas.invocations) {
    final invocation = recorded.invocation;
    if (invocation.memberName != #drawImageRect) continue;
    final args = invocation.positionalArguments;
    return _PaintedFrame(
      args[0] as ui.Image,
      args[1] as Rect,
      args[2] as Rect,
      (args[3] as Paint).filterQuality,
    );
  }
  return null;
}

/// Waits until the frame being decoded reaches the screen and returns it.
/// `ui.decodeImageFromPixels` only completes on the real event loop.
Future<_PaintedFrame> _settleFrame(WidgetTester tester) async {
  final before = _paintedFrame(tester)?.image;
  for (var i = 0; i < 400; i++) {
    final current = _paintedFrame(tester);
    if (current != null && !identical(current.image, before)) return current;
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 5)),
    );
  }
  fail('No new fractal frame reached the screen.');
}

/// Waits until a full-quality still is on screen and returns it.
Future<_PaintedFrame> _settleStill(WidgetTester tester) async {
  for (var i = 0; i < 400; i++) {
    final current = _paintedFrame(tester);
    if (current?.quality == FilterQuality.medium) return current!;
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 5)),
    );
  }
  fail('No full-quality still reached the screen.');
}

Widget _app(WasmEngineService? engine, {Size? size}) {
  final content = FractalExplorerContent(engine: engine);
  return MaterialApp(
    home: Scaffold(
      backgroundColor: Colors.black,
      body:
          size == null
              ? content
              : Center(child: SizedBox.fromSize(size: size, child: content)),
    ),
  );
}

/// Pumps the explorer, builds its canvas and waits for the first frame.
Future<_PaintedFrame> _pumpExplorer(
  WidgetTester tester,
  _FakeEngine engine, {
  Size? size,
}) async {
  await tester.pumpWidget(_app(engine, size: size));
  await tester.pump();
  return _settleFrame(tester);
}

/// Collects `debugPrint` output while [body] runs. The override has to be gone
/// before the test body returns, so tear-downs are too late for it.
Future<List<String>> _capturePrints(Future<void> Function() body) async {
  final logs = <String>[];
  final original = debugPrint;
  debugPrint = (String? message, {int? wrapWidth}) => logs.add(message ?? '');
  try {
    await body();
  } finally {
    debugPrint = original;
  }
  return logs;
}

double _hintOpacity(WidgetTester tester) =>
    tester
        .widget<AnimatedOpacity>(
          find.ancestor(
            of: find.text('Tap to Zoom In'),
            matching: find.byType(AnimatedOpacity),
          ),
        )
        .opacity;

final Finder _autoExploringLabel = find.textContaining('Auto-exploring');

void main() {
  group('WasmEngineService on the VM', () {
    test('the factory returns the stub, which never becomes ready', () async {
      final service = WasmEngineService();

      expect(service, isA<WasmEngineServiceImpl>());
      expect(service.isReady, isFalse);
      await service.init();
      expect(service.isReady, isFalse);
    });

    test('the stub renders nothing and exposes an empty buffer', () {
      final service = getService();

      service.generateFractal(
        width: 320,
        height: 240,
        zoom: 1,
        offsetX: -0.5,
        offsetY: 0,
        maxIterations: 100,
        isJulia: false,
        cxJulia: 0,
        cyJulia: 0,
        time: 0,
      );

      expect(service.getPixelBuffer(), isEmpty);
    });
  });

  group('FractalScenario', () {
    test('defaults to a Mandelbrot view zooming at 12% per second', () {
      // Not const on purpose: the constructor has to run.
      final name = ['Seahorse'].first;
      final scenario = FractalScenario(name: name, targetX: -0.7, targetY: 0.1);

      expect(scenario.name, 'Seahorse');
      expect(scenario.zoomSpeed, 0.12);
      expect(scenario.isJulia, isFalse);
      expect(scenario.cxJulia, 0.0);
      expect(scenario.cyJulia, 0.0);
    });
  });

  group('FractalExplorerContent loading', () {
    testWidgets('shows a spinner until the engine has loaded', (tester) async {
      final gate = Completer<void>();
      final engine = _FakeEngine(initGate: gate);

      await tester.pumpWidget(_app(engine));

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(engine.calls, isEmpty);

      gate.complete();
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(engine.calls, hasLength(1));
    });

    testWidgets('renders the home view as its first frame', (tester) async {
      final engine = _FakeEngine();

      final frame = await _pumpExplorer(tester, engine);

      final call = engine.calls.single;
      expect((call.width, call.height), (360, 270));
      expect(call.zoom, 1.0);
      expect((call.offsetX, call.offsetY), (-0.5, 0.0));
      expect(call.maxIterations, 100);
      expect(call.isJulia, isFalse);
      expect(call.time, 0.0);

      // The animated frame is stretched over the whole view, bilinear.
      expect(frame.source, const Rect.fromLTWH(0, 0, 360, 270));
      expect(frame.destination, const Rect.fromLTWH(0, 0, 800, 600));
      expect(frame.quality, FilterQuality.low);

      expect(find.text('Auto-exploring: Mandelbrot: Seahorse'), findsOneWidget);
      expect(_hintOpacity(tester), 0.0);
    });

    testWidgets('the frame on screen holds the pixels the engine produced', (
      tester,
    ) async {
      final frame = await _pumpExplorer(tester, _FakeEngine());

      final bytes = await tester.runAsync(
        () => frame.image.toByteData(format: ui.ImageByteFormat.rawRgba),
      );

      expect(bytes!.lengthInBytes, 360 * 270 * 4);
      expect(bytes.buffer.asUint8List(0, 4), _FakeEngine.pixel);
      expect(
        bytes.buffer.asUint8List(bytes.lengthInBytes - 4, 4),
        _FakeEngine.pixel,
      );
    });

    testWidgets('an engine whose init throws is logged and renders nothing', (
      tester,
    ) async {
      final engine = _FakeEngine(
        ready: false,
        initError: StateError('wasm missing'),
      );

      final logs = await _capturePrints(() async {
        await tester.pumpWidget(_app(engine));
        await tester.pump();
      });

      expect(logs.single, contains('Fractal engine failed to load'));
      expect(logs.single, contains('wasm missing'));
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(engine.calls, isEmpty);
      expect(_fractalLayer, paintsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('an engine that is never ready leaves the canvas empty', (
      tester,
    ) async {
      // No engine injected: on the VM the factory hands out the stub.
      await tester.pumpWidget(_app(null));
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(_fractalLayer, paintsNothing);

      // The controls still answer, they just have nothing to draw.
      await tester.tapAt(const Offset(400, 300));
      await tester.pump();
      expect(_autoExploringLabel, findsNothing);
      expect(_hintOpacity(tester), 1.0);

      await tester.tap(find.byTooltip('Reset'));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      await tester.pump(const Duration(seconds: 1));

      expect(_autoExploringLabel, findsOneWidget);
      expect(_fractalLayer, paintsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('an engine that becomes unready stops being asked for frames', (
      tester,
    ) async {
      final engine = _FakeEngine();
      await _pumpExplorer(tester, engine);

      engine.ready = false;
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 100));

      expect(engine.calls, hasLength(1));
    });

    testWidgets('closing the window while the engine loads renders nothing', (
      tester,
    ) async {
      final gate = Completer<void>();
      final engine = _FakeEngine(initGate: gate);
      await tester.pumpWidget(_app(engine));

      await tester.pumpWidget(const SizedBox());
      gate.complete();
      await tester.pump();

      expect(engine.calls, isEmpty);
      expect(tester.takeException(), isNull);
    });
  });

  group('FractalExplorerContent auto-animation', () {
    testWidgets('zooms into the scenario target as time passes', (
      tester,
    ) async {
      final engine = _FakeEngine();
      await _pumpExplorer(tester, engine);

      await tester.pump(const Duration(seconds: 2));

      expect(engine.calls, hasLength(2));
      final call = engine.calls.last;
      expect(call.time, closeTo(2.0, 1e-9));
      expect(call.zoom, closeTo(math.pow(1.12, 2.0), 1e-9));
      expect((call.offsetX, call.offsetY), (-0.7435, 0.1314));

      await _settleFrame(tester);
      await tester.pump(const Duration(seconds: 1));

      expect(engine.calls.last.zoom, closeTo(math.pow(1.12, 3.0), 1e-9));
    });

    testWidgets('is paced to about 30 frames a second', (tester) async {
      final engine = _FakeEngine();
      await _pumpExplorer(tester, engine);

      // Six display frames at 60 Hz...
      for (var displayFrame = 1; displayFrame <= 6; displayFrame++) {
        final callsBefore = engine.calls.length;
        await tester.pump(const Duration(milliseconds: 16));
        if (engine.calls.length > callsBefore) await _settleFrame(tester);
      }

      // ...are two fractal frames, 48 ms apart.
      final animated = engine.calls.skip(1).toList();
      expect(animated, hasLength(2));
      expect(animated[0].time, closeTo(0.048, 1e-9));
      expect(animated[1].time, closeTo(0.096, 1e-9));
    });

    testWidgets('does not start a frame while the previous one is decoding', (
      tester,
    ) async {
      final engine = _FakeEngine();
      await _pumpExplorer(tester, engine);

      await tester.pump(const Duration(milliseconds: 40));
      expect(engine.calls, hasLength(2));

      // Without the real event loop the decode cannot finish.
      await tester.pump(const Duration(milliseconds: 40));
      await tester.pump(const Duration(milliseconds: 40));
      expect(engine.calls, hasLength(2));

      await _settleFrame(tester);
      await tester.pump(const Duration(milliseconds: 40));
      expect(engine.calls, hasLength(3));
    });

    testWidgets('stops at the zoom cap instead of losing precision', (
      tester,
    ) async {
      final engine = _FakeEngine();
      await _pumpExplorer(tester, engine);

      await tester.pump(const Duration(seconds: 100));
      await _settleFrame(tester);
      final deepest = engine.calls.last.zoom;
      expect(deepest, closeTo(math.pow(1.12, 100.0), deepest * 1e-9));

      expect(_autoExploringLabel, findsOneWidget);
      expect(_hintOpacity(tester), 0.0);

      // 1.12^250 is past 1e12: the frame is drawn at the last good zoom.
      await tester.pump(const Duration(seconds: 150));

      // The labels say so at once, not at the next unrelated rebuild.
      expect(_autoExploringLabel, findsNothing);
      expect(_hintOpacity(tester), 1.0);

      // The view that stays is drawn once more, at full quality.
      final still = await _settleStill(tester);
      expect(still.quality, FilterQuality.medium);
      expect(engine.calls, hasLength(3));
      expect(engine.calls.last.zoom, deepest);
      expect(engine.calls.last.time, closeTo(250.0, 1e-6));
      expect((engine.calls.last.width, engine.calls.last.height), (800, 600));

      // And the animation is over.
      await tester.pump(const Duration(seconds: 10));
      await tester.pump(const Duration(seconds: 10));
      expect(engine.calls, hasLength(3));
    });
  });

  group('FractalExplorerContent pixel budget', () {
    testWidgets('a slow engine gets smaller frames, down to a floor', (
      tester,
    ) async {
      // 30 ms a frame against a 9 ms budget.
      final engine = _FakeEngine(renderCost: const Duration(milliseconds: 30));
      await _pumpExplorer(tester, engine);

      for (var i = 0; i < 7; i++) {
        await tester.pump(const Duration(milliseconds: 40));
        await _settleFrame(tester);
      }

      final sizes = engine.calls.map((call) => call.pixels).toList();
      expect(sizes.first, 360 * 270);
      expect(sizes[1], lessThan(sizes[0]));
      expect(sizes[2], lessThan(sizes[1]));
      // About 240x180, whatever the engine costs.
      expect(sizes.last, sizes[sizes.length - 2]);
      expect(sizes.last, inInclusiveRange(239 * 179, 240 * 180));
      // The shape of the view is kept all the way down.
      for (final call in engine.calls) {
        expect(call.width / call.height, closeTo(800 / 600, 0.02));
      }
    });

    testWidgets('a fast engine gets larger frames, up to its buffer', (
      tester,
    ) async {
      // Half a millisecond a frame leaves most of the budget unused.
      final engine = _FakeEngine(renderCost: const Duration(microseconds: 500));
      await _pumpExplorer(tester, engine);

      // One frame at this cost is enough to reach the ceiling; the rest is
      // room for a frame the machine stalled on.
      for (var i = 0; i < 12; i++) {
        await tester.pump(const Duration(milliseconds: 40));
        await _settleFrame(tester);
      }

      final sizes = engine.calls.map((call) => call.pixels).toList();
      expect(sizes, hasLength(13));
      expect(sizes.first, 360 * 270);
      expect(sizes.reduce(math.max), greaterThan(sizes.first));
      // Settled on the whole buffer, which is this view's shape.
      expect((engine.calls.last.width, engine.calls.last.height), (800, 600));
      for (final call in engine.calls) {
        expect(call.width, lessThanOrEqualTo(800));
        expect(call.height, lessThanOrEqualTo(600));
        expect(call.width / call.height, closeTo(800 / 600, 0.02));
      }
    });

    testWidgets('a fast engine fills a wide view up to the buffer width', (
      tester,
    ) async {
      final engine = _FakeEngine(renderCost: const Duration(microseconds: 500));
      await _pumpExplorer(tester, engine, size: const Size(400, 200));

      for (var i = 0; i < 12; i++) {
        await tester.pump(const Duration(milliseconds: 40));
        await _settleFrame(tester);
      }

      expect(
        engine.calls.map((call) => call.pixels).reduce(math.max),
        greaterThan(engine.calls.first.pixels),
      );
      expect((engine.calls.last.width, engine.calls.last.height), (800, 400));
    });
  });

  group('FractalExplorerContent tap to zoom', () {
    testWidgets('stops the animation and asks for a full-quality still', (
      tester,
    ) async {
      final engine = _FakeEngine();
      final moving = await _pumpExplorer(tester, engine);
      expect(moving.quality, FilterQuality.low);

      // Halfway to the right edge, halfway to the top edge.
      await tester.tapAt(const Offset(600, 150));
      await tester.pump();

      final call = engine.calls.last;
      expect(engine.calls, hasLength(2));
      expect((call.width, call.height), (800, 600));
      expect(call.zoom, 1.5);
      expect(call.offsetX, closeTo(-0.7435 + 0.5 * 2.0 * (800 / 600), 1e-9));
      expect(call.offsetY, closeTo(0.1314 - 0.5 * 2.0, 1e-9));

      expect(_autoExploringLabel, findsNothing);
      expect(_hintOpacity(tester), 1.0);

      final still = await _settleFrame(tester);
      expect(still.source, const Rect.fromLTWH(0, 0, 800, 600));
      expect(still.quality, FilterQuality.medium);

      // Nothing moves any more.
      await tester.pump(const Duration(seconds: 1));
      await tester.pump(const Duration(seconds: 1));
      expect(engine.calls, hasLength(2));
    });

    testWidgets('each tap zooms 1.5x and moves less the deeper the view', (
      tester,
    ) async {
      final engine = _FakeEngine();
      await _pumpExplorer(tester, engine);

      // The centre of the view is the point already under it.
      await tester.tapAt(const Offset(400, 300));
      await tester.pump();
      expect(engine.calls.last.zoom, 1.5);
      expect(engine.calls.last.offsetX, closeTo(-0.7435, 1e-9));
      expect(engine.calls.last.offsetY, closeTo(0.1314, 1e-9));
      await _settleFrame(tester);

      await tester.tapAt(const Offset(600, 150));
      await tester.pump();
      final call = engine.calls.last;
      expect(call.zoom, 2.25);
      expect(
        call.offsetX,
        closeTo(-0.7435 + 0.5 * (2.0 / 1.5) * (800 / 600), 1e-9),
      );
      expect(call.offsetY, closeTo(0.1314 - 0.5 * (2.0 / 1.5), 1e-9));
    });

    testWidgets('the still keeps the shape of the view it is shown in', (
      tester,
    ) async {
      final engine = _FakeEngine();
      await _pumpExplorer(tester, engine, size: const Size(400, 200));

      // The 400x200 view sits at (200, 200): this is (300, 50) inside it.
      await tester.tapAt(const Offset(500, 250));
      await tester.pump();

      final call = engine.calls.last;
      expect((call.width, call.height), (800, 400));
      expect(call.offsetX, closeTo(-0.7435 + 0.5 * 2.0 * 2.0, 1e-9));
      expect(call.offsetY, closeTo(0.1314 - 0.5 * 2.0, 1e-9));

      final still = await _settleFrame(tester);
      expect(still.destination, const Rect.fromLTWH(0, 0, 400, 200));
    });

    testWidgets('the still never holds more pixels than the screen shows', (
      tester,
    ) async {
      tester.view.devicePixelRatio = 1.0;
      tester.view.physicalSize = const Size(800, 600);
      addTearDown(tester.view.reset);
      final engine = _FakeEngine();
      await _pumpExplorer(tester, engine, size: const Size(400, 200));

      await tester.tapAt(const Offset(400, 300));
      await tester.pump();

      final call = engine.calls.last;
      expect((call.width, call.height), (400, 200));
    });

    testWidgets('rebuilding does not repaint: frames arrive by notifier', (
      tester,
    ) async {
      final engine = _FakeEngine();
      final first = await _pumpExplorer(tester, engine);
      final before = tester.widget<CustomPaint>(_fractalLayer).painter!;
      final layer = tester.renderObject(_fractalLayer);

      // The next animated frame: requested, then decoded.
      await tester.pump(const Duration(milliseconds: 40));
      expect(layer.debugNeedsPaint, isFalse);
      final second = await _settleFrame(tester);

      // It marks the layer dirty by itself and is on screen after the next
      // display frame, with the painter the last build made.
      expect(second.image, isNot(same(first.image)));
      expect(layer.debugNeedsPaint, isTrue);
      await tester.pump();
      expect(layer.debugNeedsPaint, isFalse);
      expect(tester.widget<CustomPaint>(_fractalLayer).painter, same(before));
      expect(_paintedFrame(tester)!.image, same(second.image));

      // A rebuild swaps the painter, which is no reason to repaint.
      await tester.tapAt(const Offset(400, 300));
      await tester.pump();

      final after = tester.widget<CustomPaint>(_fractalLayer).painter!;
      expect(after, isNot(same(before)));
      expect(after.shouldRepaint(before), isFalse);
    });

    testWidgets('a tap during a decode gets its still once that frame lands', (
      tester,
    ) async {
      final engine = _FakeEngine();
      await _pumpExplorer(tester, engine);
      await tester.pump(const Duration(milliseconds: 40));
      expect(engine.calls, hasLength(2));
      final movingZoom = engine.calls.last.zoom;

      // The engine's last frame is still decoding: the still has to wait.
      await tester.tapAt(const Offset(600, 150));
      await tester.pump();
      expect(engine.calls, hasLength(2));

      await _settleFrame(tester);
      expect(engine.calls, hasLength(3));
      final call = engine.calls.last;
      expect((call.width, call.height), (800, 600));
      expect(call.zoom, closeTo(movingZoom * 1.5, 1e-9));
      expect(
        call.offsetX,
        closeTo(-0.7435 + 0.5 * (2.0 / movingZoom) * (800 / 600), 1e-9),
      );
      expect(call.offsetY, closeTo(0.1314 - 0.5 * (2.0 / movingZoom), 1e-9));

      final still = await _settleStill(tester);
      expect(still.source, const Rect.fromLTWH(0, 0, 800, 600));

      // One still, and nothing moves any more.
      await tester.pump(const Duration(seconds: 1));
      await tester.pump(const Duration(seconds: 1));
      expect(engine.calls, hasLength(3));
    });

    testWidgets(
      'taps during a still\'s decode end in one still of the last view',
      (tester) async {
        final engine = _FakeEngine();
        await _pumpExplorer(tester, engine);

        await tester.tapAt(const Offset(400, 300));
        await tester.pump();
        expect(engine.calls, hasLength(2));
        await tester.tapAt(const Offset(400, 300));
        await tester.pump();
        await tester.tapAt(const Offset(400, 300));
        await tester.pump();
        expect(engine.calls, hasLength(2));

        await _settleFrame(tester);
        expect(engine.calls, hasLength(3));
        expect((engine.calls.last.width, engine.calls.last.height), (800, 600));
        expect(engine.calls.last.zoom, closeTo(1.5 * 1.5 * 1.5, 1e-9));

        await _settleFrame(tester);
        expect(_paintedFrame(tester)!.quality, FilterQuality.medium);
        await tester.pump(const Duration(seconds: 1));
        expect(engine.calls, hasLength(3));
      },
    );

    testWidgets('a still owed when the animation restarts is forgotten', (
      tester,
    ) async {
      final engine = _FakeEngine();
      await _pumpExplorer(tester, engine);
      await tester.pump(const Duration(milliseconds: 40));
      await tester.tapAt(const Offset(400, 300));
      await tester.pump();
      expect(engine.calls, hasLength(2));

      await tester.tap(find.byTooltip('Reset'));
      await tester.pump();
      await _settleFrame(tester);

      // The frame in flight landed and no still followed it...
      expect(engine.calls, hasLength(2));

      // ...so the engine is free for the animation.
      await tester.pump(const Duration(milliseconds: 40));
      expect(engine.calls, hasLength(3));
      final call = engine.calls.last;
      expect((call.width, call.height), (360, 270));
      expect(call.time, closeTo(0.04, 1e-9));
      expect((await _settleFrame(tester)).quality, FilterQuality.low);
    });
  });

  group('FractalExplorerContent controls', () {
    testWidgets('reset returns to the home view and resumes the animation', (
      tester,
    ) async {
      final engine = _FakeEngine();
      await _pumpExplorer(tester, engine);
      await tester.pump(const Duration(seconds: 2));
      await _settleFrame(tester);
      await tester.tapAt(const Offset(600, 150));
      await tester.pump();
      await _settleFrame(tester);
      expect(_autoExploringLabel, findsNothing);

      await tester.tap(find.byTooltip('Reset'));
      await tester.pump();

      final home = engine.calls.last;
      expect(home.zoom, 1.0);
      expect((home.offsetX, home.offsetY), (-0.5, 0.0));
      expect(find.text('Auto-exploring: Mandelbrot: Seahorse'), findsOneWidget);
      expect(_hintOpacity(tester), 0.0);
      // A moving frame again, not a still.
      expect((await _settleFrame(tester)).quality, FilterQuality.low);

      // The clock restarted with the animation, and so did the pacing: the
      // first frame is due 33 ms in, however long the last run lasted.
      final callsAfterReset = engine.calls.length;
      await tester.pump(const Duration(milliseconds: 40));

      expect(engine.calls.length, callsAfterReset + 1);
      final resumed = engine.calls.last;
      expect(resumed.time, closeTo(0.04, 1e-9));
      expect(resumed.zoom, closeTo(math.pow(1.12, 0.04), 1e-9));
      expect((resumed.offsetX, resumed.offsetY), (-0.7435, 0.1314));

      await _settleFrame(tester);
      await tester.pump(const Duration(milliseconds: 40));

      expect(engine.calls.length, callsAfterReset + 2);
      expect(engine.calls.last.zoom, closeTo(math.pow(1.12, 0.08), 1e-9));
    });

    testWidgets('reset in the middle of the animation restarts it at once', (
      tester,
    ) async {
      final engine = _FakeEngine();
      await _pumpExplorer(tester, engine);
      await tester.pump(const Duration(seconds: 2));
      await _settleFrame(tester);
      expect(engine.calls.last.time, closeTo(2.0, 1e-9));

      await tester.tap(find.byTooltip('Reset'));
      await tester.pump();
      await _settleFrame(tester);
      final callsAfterReset = engine.calls.length;

      await tester.pump(const Duration(milliseconds: 40));

      expect(engine.calls.length, callsAfterReset + 1);
      expect(engine.calls.last.time, closeTo(0.04, 1e-9));
      expect(engine.calls.last.zoom, closeTo(math.pow(1.12, 0.04), 1e-9));
    });

    testWidgets('next scenario cycles through every scenario and wraps', (
      tester,
    ) async {
      final engine = _FakeEngine();
      await _pumpExplorer(tester, engine);

      // name, isJulia, (cx, cy) of the Julia constant
      const expected = [
        ('Mandelbrot: Triple Spiral', false, (0.0, 0.0)),
        ('Julia: Cosmic Bloom', true, (-0.7, 0.27015)),
        ('Julia: Dragon Curve', true, (-0.8, 0.156)),
        ('Mandelbrot: Elephant Valley', false, (0.0, 0.0)),
        ('Mandelbrot: Seahorse', false, (0.0, 0.0)),
      ];

      for (final (name, isJulia, julia) in expected) {
        final callsBefore = engine.calls.length;

        await tester.tap(find.byTooltip('Change Scenario'));
        await tester.pump();

        expect(find.text('Auto-exploring: $name'), findsOneWidget);
        expect(engine.calls.length, callsBefore + 1, reason: name);
        final call = engine.calls.last;
        expect(call.isJulia, isJulia, reason: name);
        expect((call.cxJulia, call.cyJulia), julia, reason: name);
        // Julia sets are centred on the origin, the Mandelbrot set is not.
        expect(call.zoom, 1.0, reason: name);
        expect(
          (call.offsetX, call.offsetY),
          (isJulia ? 0.0 : -0.5, 0.0),
          reason: name,
        );
        await _settleFrame(tester);
      }
    });

    testWidgets('a new scenario animates towards its own target and speed', (
      tester,
    ) async {
      final engine = _FakeEngine();
      await _pumpExplorer(tester, engine);
      await tester.pump(const Duration(seconds: 2));
      await _settleFrame(tester);

      await tester.tap(find.byTooltip('Change Scenario'));
      await tester.pump();
      await _settleFrame(tester);
      final callsAfterChange = engine.calls.length;

      // Its first frame comes 33 ms in, not once it has run for as long as
      // the scenario before it.
      await tester.pump(const Duration(milliseconds: 40));

      expect(engine.calls.length, callsAfterChange + 1);
      var call = engine.calls.last;
      expect(call.time, closeTo(0.04, 1e-9));
      expect((call.offsetX, call.offsetY), (-0.088, 0.654));
      expect(call.zoom, closeTo(math.pow(1.15, 0.04), 1e-9));

      await _settleFrame(tester);
      await tester.pump(const Duration(seconds: 1));

      call = engine.calls.last;
      expect(engine.calls.length, callsAfterChange + 2);
      expect(call.zoom, closeTo(math.pow(1.15, 1.04), 1e-9));
    });
  });

  group('FractalExplorerContent frame lifetime', () {
    testWidgets('releases the previous frame when a new one arrives', (
      tester,
    ) async {
      final engine = _FakeEngine();
      final first = await _pumpExplorer(tester, engine);

      await tester.pump(const Duration(milliseconds: 40));
      final second = await _settleFrame(tester);

      expect(first.image.debugDisposed, isTrue);
      expect(second.image.debugDisposed, isFalse);
    });

    testWidgets('dispose releases the frame on screen', (tester) async {
      final frame = await _pumpExplorer(tester, _FakeEngine());
      expect(frame.image.debugDisposed, isFalse);

      await tester.pumpWidget(const SizedBox());

      expect(frame.image.debugDisposed, isTrue);
      expect(tester.takeException(), isNull);
    });

    testWidgets('a frame decoded after the window closed is dropped quietly', (
      tester,
    ) async {
      final engine = _FakeEngine();
      final created = <ui.Image>[];
      final disposed = <ui.Image>[];
      final onCreate = ui.Image.onCreate;
      final onDispose = ui.Image.onDispose;
      ui.Image.onCreate = created.add;
      ui.Image.onDispose = disposed.add;

      try {
        final logs = await _capturePrints(() async {
          await tester.pumpWidget(_app(engine));
          expect(engine.calls, hasLength(1));
          await tester.pumpWidget(const SizedBox());
          final createdWhileOpen = created.length;

          // The decode only finishes on the real event loop.
          for (var i = 0; i < 400 && created.length == createdWhileOpen; i++) {
            await tester.runAsync(
              () => Future<void>.delayed(const Duration(milliseconds: 5)),
            );
          }
          await tester.pump();

          final afterClose = created.skip(createdWhileOpen);
          if (afterClose.isEmpty) {
            fail('The pending decode never produced an image.');
          }
          // Nobody is left to show it: it must not stay in GPU memory.
          expect(afterClose, hasLength(1));
          expect(disposed, contains(same(afterClose.single)));
          expect(afterClose.single.debugDisposed, isTrue);
        });

        // Touching the disposed notifier would surface as a failed render.
        expect(logs, isEmpty);
        expect(tester.takeException(), isNull);
      } finally {
        ui.Image.onCreate = onCreate;
        ui.Image.onDispose = onDispose;
      }
    });

    testWidgets('a render that fails is logged and the next frame still runs', (
      tester,
    ) async {
      final engine = _FakeEngine();
      final first = await _pumpExplorer(tester, engine);

      engine.truncateNextBuffer = true;
      final logs = await _capturePrints(() async {
        await tester.pump(const Duration(milliseconds: 40));
      });

      expect(engine.calls, hasLength(2));
      expect(logs.single, contains('Fractal render failed'));
      // The last good frame stays up.
      expect(_paintedFrame(tester)!.image, same(first.image));
      expect(first.image.debugDisposed, isFalse);

      await tester.pump(const Duration(milliseconds: 40));
      final recovered = await _settleFrame(tester);

      expect(engine.calls, hasLength(3));
      expect(recovered.image, isNot(same(first.image)));
    });
  });
}
