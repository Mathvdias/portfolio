import 'dart:typed_data';
import 'dart:ui' show FrameTiming;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:portifolio/core/services/wasm_engine_service.dart';
import 'package:portifolio/shared/constants/app_strings.dart';
import 'package:portifolio/shared/widgets/wasm_diagnostics_content.dart';

/// Stands in for the Rust engine: ready or not, with a render that costs a
/// measurable amount of wall-clock time.
class _FakeEngine implements WasmEngineService {
  _FakeEngine({this.ready = true});

  final bool ready;
  int renders = 0;

  @override
  Future<void> init() async {}

  @override
  bool get isReady => ready;

  @override
  int get memoryBytes => 3 * 1024 * 1024;

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
    renders++;
    final stopwatch = Stopwatch()..start();
    while (stopwatch.elapsedMicroseconds < 300) {}
  }

  @override
  Uint8List getPixelBuffer() => Uint8List(0);
}

FrameTiming _timing({required int buildMicros, required int rasterMicros}) {
  return FrameTiming(
    vsyncStart: 0,
    buildStart: 0,
    buildFinish: buildMicros,
    rasterStart: buildMicros,
    rasterFinish: buildMicros + rasterMicros,
    rasterFinishWallTime: buildMicros + rasterMicros,
  );
}

void main() {
  // The real ticker is muted so each test decides which frames exist.
  Future<WasmDiagnosticsContentState> pumpMonitor(
    WidgetTester tester, {
    WasmEngineService? engine,
    double Function()? heap,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TickerMode(
            enabled: false,
            child: WasmDiagnosticsContent(
              engine: engine ?? _FakeEngine(),
              heapSizeOverride: heap,
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    return tester.state(find.byType(WasmDiagnosticsContent));
  }

  // Windows start 5 s apart: a gap that long is dropped as a suspended tab, so
  // it never counts as a frame.
  void feed(
    WasmDiagnosticsContentState state,
    List<int> intervalsMs, {
    int startMs = 0,
  }) {
    var now = startMs;
    state.onTick(Duration(milliseconds: now));
    for (final interval in intervalsMs) {
      now += interval;
      state.onTick(Duration(milliseconds: now));
    }
  }

  group('WasmDiagnosticsContent', () {
    testWidgets('shows n/a instead of inventing what it cannot measure', (
      tester,
    ) async {
      final state = await pumpMonitor(
        tester,
        engine: _FakeEngine(ready: false),
      );

      // No frame measured, no performance.memory, no engine: three unknowns.
      expect(find.text(AppStrings.wasmNotAvailable), findsNWidgets(4));
      expect(find.text(AppStrings.wasmHeapUnavailableCaption), findsOneWidget);
      expect(find.text(AppStrings.wasmRustMemoryUnavailable), findsOneWidget);
      expect(
        state.logs.any((l) => l.contains(AppStrings.wasmHeapUnavailableLog)),
        isTrue,
      );
      expect(
        state.logs.any((l) => l.contains(AppStrings.wasmEngineUnavailableLog)),
        isTrue,
      );

      // A window with no frames changes nothing.
      state.flushWindow();
      await tester.pump();
      expect(find.text(AppStrings.wasmNotAvailable), findsNWidgets(4));
    });

    testWidgets('the default engine is the app one (not loaded off the web)', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: TickerMode(enabled: false, child: WasmDiagnosticsContent()),
          ),
        ),
      );
      await tester.pump();
      expect(find.text(AppStrings.wasmRustMemoryUnavailable), findsOneWidget);
      expect(WasmEngineService().memoryBytes, 0);
    });

    testWidgets('FPS, frame cost, heap and Rust memory are the measured ones', (
      tester,
    ) async {
      final state = await pumpMonitor(tester, heap: () => 42.5);

      feed(state, List.filled(10, 16));
      state.handleTimings([
        _timing(buildMicros: 1000, rasterMicros: 2000),
        _timing(buildMicros: 3000, rasterMicros: 4000),
      ]);
      state.flushWindow();
      await tester.pump();

      expect(find.text('62.5'), findsOneWidget);
      expect(find.text('16.0 ms/frame'), findsOneWidget);
      expect(find.text('5.0ms'), findsOneWidget);
      expect(find.text('build 2.0 · raster 3.0'), findsOneWidget);
      expect(find.text('42.5 MB'), findsOneWidget);
      expect(find.text('3.0 MB'), findsOneWidget);
      expect(find.text(AppStrings.wasmRustMemoryCaption), findsOneWidget);
    });

    testWidgets('a window without FrameTiming keeps the last cost and leaves '
        'a gap on the chart', (tester) async {
      final state = await pumpMonitor(tester);

      // Timed, timed, gap, timed: the cost line is drawn, broken and resumed.
      for (var window = 0; window < 4; window++) {
        feed(state, List.filled(5, 16), startMs: window * 5000);
        if (window != 2) {
          state.handleTimings([_timing(buildMicros: 1000, rasterMicros: 1000)]);
        }
        state.flushWindow();
        await tester.pump();
      }

      expect(find.text('2.0ms'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('refresh rate follows the median frame and never goes down', (
      tester,
    ) async {
      final state = await pumpMonitor(tester);
      expect(state.detectedRefreshRate, 60.0);

      // One 4 ms glitch among 16 ms frames is not a 240 Hz display.
      feed(state, [16, 16, 4, 16, 16, 16]);
      state.flushWindow();
      expect(state.detectedRefreshRate, 60.0);

      // Too few frames to judge.
      feed(state, [8, 8], startMs: 5000);
      state.flushWindow();
      expect(state.detectedRefreshRate, 60.0);

      final expected = {14: 75.0, 11: 90.0, 8: 120.0, 7: 144.0, 6: 165.0};
      var start = 10000;
      for (final MapEntry(key: interval, value: rate) in expected.entries) {
        feed(state, List.filled(6, interval), startMs: start);
        state.flushWindow();
        expect(state.detectedRefreshRate, rate);
        start += 5000;
      }
      feed(state, List.filled(6, 4), startMs: start);
      state.flushWindow();
      expect(state.detectedRefreshRate, 240.0);

      // The app dropping to 30 fps does not turn the display into a slower one.
      feed(state, List.filled(6, 33), startMs: start + 5000);
      state.flushWindow();
      expect(state.detectedRefreshRate, 240.0);
      expect(
        state.logs.where((l) => l.contains('Display refresh rate')).length,
        6,
      );
    });

    testWidgets(
      'slow frames are counted and reported, a suspended tab is not',
      (tester) async {
        final state = await pumpMonitor(tester);

        // 100 ms blows the 16.7 ms budget; 5 s means the tab was in background.
        feed(state, [16, 100, 16, 5000, 16]);
        expect(state.slowFrames, 1);

        for (var window = 0; window < 8; window++) {
          state.flushWindow();
          feed(state, [16], startMs: 10000 + window * 5000);
        }
        await tester.pump();

        expect(find.textContaining('Slow frames: 1 /'), findsOneWidget);
        final report = state.logs.singleWhere((l) => l.contains('slow frames'));
        expect(report, contains('1 slow frames in the last 2 s'));
        expect(report, contains('worst 100.0 ms'));
      },
    );

    testWidgets('history and log stay bounded', (tester) async {
      final state = await pumpMonitor(tester);

      for (var window = 0; window < 70; window++) {
        feed(state, [16, 16], startMs: window * 5000);
        state.flushWindow();
      }
      for (var i = 0; i < 60; i++) {
        state.addLog('Test', 'Msg $i');
      }
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(state.logs.length, 55);
      expect(state.logs.last, contains('Msg 59'));
      expect(tester.takeException(), isNull);
    });

    testWidgets('benchmark times the Rust engine and the Dart port', (
      tester,
    ) async {
      final engine = _FakeEngine();
      final state = await pumpMonitor(tester, engine: engine);

      await tester.tap(find.text(AppStrings.wasmRunBenchmark));
      await tester.pump();
      expect(find.text(AppStrings.wasmBenchmarkRunning), findsOneWidget);

      // A second request while one is running is ignored.
      await state.runBenchmark();

      for (var i = 0; i < 40; i++) {
        await tester.pump(const Duration(milliseconds: 16));
      }

      expect(find.text(AppStrings.wasmRunBenchmark), findsOneWidget);
      expect(engine.renders, 8); // warm-up + 7 timed runs
      expect(find.text(AppStrings.wasmBenchmarkRust), findsOneWidget);
      expect(find.text('Dart → Dart VM'), findsOneWidget);
      expect(state.logs.any((l) => l.contains('Mandelbrot 800x600')), isTrue);
      expect(state.logs.any((l) => l.contains('Rust → WASM: ')), isTrue);
      expect(state.logs.any((l) => l.contains('Dart → Dart VM: ')), isTrue);
      expect(state.logs.any((l) => l.contains('x faster than')), isTrue);
    });

    testWidgets('benchmark without the Rust engine reports Dart alone', (
      tester,
    ) async {
      final state = await pumpMonitor(
        tester,
        engine: _FakeEngine(ready: false),
      );

      await tester.tap(find.text(AppStrings.wasmRunBenchmark));
      for (var i = 0; i < 40; i++) {
        await tester.pump(const Duration(milliseconds: 16));
      }

      expect(find.text(AppStrings.wasmBenchmarkRust), findsNothing);
      expect(find.text('Dart → Dart VM'), findsOneWidget);
      expect(state.logs.any((l) => l.contains('x faster than')), isFalse);
    });

    testWidgets('closing the window mid-benchmark is harmless', (tester) async {
      for (final ready in [true, false]) {
        await pumpMonitor(tester, engine: _FakeEngine(ready: ready));
        await tester.tap(find.text(AppStrings.wasmRunBenchmark));
        await tester.pump();

        await tester.pumpWidget(const MaterialApp(home: SizedBox()));
        await tester.pump(const Duration(milliseconds: 16));
        expect(tester.takeException(), isNull);
      }
    });

    testWidgets('narrow windows stack the cards two by two', (tester) async {
      tester.view.physicalSize = const Size(400, 700);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpMonitor(tester);

      final fps = tester.getTopLeft(find.text(AppStrings.wasmFps));
      final heap = tester.getTopLeft(
        find.text(AppStrings.wasmHeap.toUpperCase()),
      );
      expect(heap.dy, greaterThan(fps.dy));
      expect(tester.takeException(), isNull);
    });

    testWidgets('the live ticker feeds the monitor on its own', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: WasmDiagnosticsContent(engine: _FakeEngine())),
        ),
      );
      for (var i = 0; i < 20; i++) {
        await tester.pump(const Duration(milliseconds: 16));
      }
      expect(find.text('62.5'), findsOneWidget);
    });
  });

  group('WasmDiagnosticsContentState helpers', () {
    test('device memory is reported as the browser states it', () {
      expect(
        WasmDiagnosticsContentState.deviceMemoryLabel(0),
        AppStrings.wasmNotAvailable,
      );
      expect(WasmDiagnosticsContentState.deviceMemoryLabel(4), '4 GB');
      expect(WasmDiagnosticsContentState.deviceMemoryLabel(0.5), '0.5 GB');
      expect(
        WasmDiagnosticsContentState.deviceMemoryLabel(8),
        AppStrings.wasmDeviceMemoryCapped,
      );
    });

    test('throughput needs a measurable time', () {
      expect(WasmDiagnosticsContentState.megapixelsPerSecond(48), '10.0');
      expect(
        WasmDiagnosticsContentState.megapixelsPerSecond(0),
        AppStrings.wasmNotAvailable,
      );
    });

    test('the verdict names whichever side won', () {
      expect(
        WasmDiagnosticsContentState.benchmarkVerdict(10, 25, 'Dart → dart2js'),
        'Rust → WASM is 2.5x faster than Dart → dart2js.',
      );
      expect(
        WasmDiagnosticsContentState.benchmarkVerdict(30, 10, 'Dart → dart2js'),
        'Dart → dart2js is 3.0x faster than Rust → WASM.',
      );
      expect(
        WasmDiagnosticsContentState.benchmarkVerdict(null, 10, 'Dart'),
        isNull,
      );
      expect(
        WasmDiagnosticsContentState.benchmarkVerdict(0, 10, 'Dart'),
        isNull,
      );
    });
  });
}
