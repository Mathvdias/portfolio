import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart' show FlutterVersion;
import 'package:google_fonts/google_fonts.dart';

import '../../core/services/fractal_kernel.dart';
import '../../core/services/wasm_engine_service.dart';
import '../../theme/app_theme.dart';
import '../constants/app_sizes.dart';
import '../constants/app_strings.dart';
import '../utils/renderer_detector.dart';

/// Live monitor of the running app. Every number on it is measured:
/// frame intervals come from a [Ticker], build/raster cost from [FrameTiming],
/// the heap from `performance.memory`, the Rust figures from the loaded
/// `mathos_engine.wasm`. What the browser does not expose is shown as "n/a".
class WasmDiagnosticsContent extends StatefulWidget {
  const WasmDiagnosticsContent({super.key, this.heapSizeOverride, this.engine});

  /// Replaces the `performance.memory` read (MB, 0 = not available).
  final double Function()? heapSizeOverride;

  /// Replaces the Rust engine the benchmark runs against.
  final WasmEngineService? engine;

  @override
  State<WasmDiagnosticsContent> createState() => WasmDiagnosticsContentState();
}

enum _EngineState { loading, ready, unavailable }

/// One 250 ms window of the timeline.
class _FrameSample {
  const _FrameSample({required this.average, required this.worst, this.cpu});

  final double average;
  final double worst;

  /// Build + raster, null when no [FrameTiming] arrived in the window.
  final double? cpu;
}

class _BenchmarkResult {
  const _BenchmarkResult({required this.dartMs, this.rustMs});

  final double dartMs;
  final double? rustMs;
}

@visibleForTesting
class WasmDiagnosticsContentState extends State<WasmDiagnosticsContent>
    with SingleTickerProviderStateMixin {
  static const int _historyLength = 60;
  static const Duration _window = Duration(milliseconds: 250);

  // A frame is "slow" once it overshoots the display budget by half a frame.
  static const double _slowFrameFactor = 1.5;
  static const int _windowsPerSlowLog = 8;

  // Anything longer is the tab being suspended, not the app rendering.
  static const double _suspendedMs = 1000.0;

  static const int _benchWidth = 800;
  static const int _benchHeight = 600;
  static const int _benchIterations = 256;
  static const int _benchRuns = 7;

  late final Ticker _ticker;
  late final Timer _statsTimer;
  late final WasmEngineService _engine;

  // Current window
  Duration? _lastTick;
  final List<double> _windowIntervals = [];
  int _windowBuildMicros = 0;
  int _windowRasterMicros = 0;
  int _windowTimings = 0;

  // Displayed metrics (null = nothing measured yet)
  double? _fps;
  double? _frameMs;
  double? _buildMs;
  double? _rasterMs;
  double _heapMb = 0.0;
  _EngineState _engineState = _EngineState.loading;
  double _detectedRefreshRate = 60.0;
  double get detectedRefreshRate => _detectedRefreshRate;

  int _totalFrames = 0;
  int _slowFrames = 0;
  int get slowFrames => _slowFrames;
  int _pendingSlow = 0;
  double _pendingWorst = 0.0;
  int _windowsSinceSlowLog = 0;

  final List<_FrameSample> _history = [];
  int _historyRevision = 0;

  bool _benchmarking = false;
  _BenchmarkResult? _benchmark;

  final List<String> _logs = [];
  List<String> get logs => List.unmodifiable(_logs);
  final ScrollController _scrollController = ScrollController();

  late final bool _simdSupported;
  late final bool _gcSupported;

  String get _dartTarget =>
      kIsWasm
          ? AppStrings.wasmRuntimeWasm
          : kIsWeb
          ? AppStrings.wasmRuntimeJs
          : AppStrings.wasmRuntimeNative;

  @override
  void initState() {
    super.initState();

    _simdSupported = isHardwareSimdSupported();
    _gcSupported = isHardwareWasmGcSupported();
    final cores = getHardwareCpuCores();
    final ram = getHardwareDeviceMemory();

    addLog('Runtime', _fill(AppStrings.wasmRuntimeLog, [_dartTarget]));
    const flutterVersion = FlutterVersion.version;
    const dartVersion = FlutterVersion.dartVersion;
    if (flutterVersion != null && dartVersion != null) {
      addLog(
        'Runtime',
        _fill(AppStrings.wasmFlutterVersionLog, [flutterVersion, dartVersion]),
      );
    }
    addLog(
      'Hardware',
      _fill(AppStrings.wasmCpuDetect, [
        cores > 0 ? '$cores' : AppStrings.wasmNotAvailable,
        deviceMemoryLabel(ram),
      ]),
    );
    addLog(
      'Graphics',
      _fill(AppStrings.wasmRendererDetect, [
        getRendererText(),
        getRendererSubtitle(),
      ]),
    );
    addLog(
      AppStrings.wasmSimd,
      _simdSupported
          ? AppStrings.wasmCapabilityYes
          : AppStrings.wasmCapabilityNo,
    );
    addLog(
      AppStrings.wasmWasmGc,
      _gcSupported ? AppStrings.wasmCapabilityYes : AppStrings.wasmCapabilityNo,
    );

    _heapMb = _readHeap();
    if (_heapMb <= 0.0) addLog('Memory', AppStrings.wasmHeapUnavailableLog);
    addLog('Frames', AppStrings.wasmProfilingActive);

    _engine = widget.engine ?? WasmEngineService();
    _loadEngine();

    // The ticker asks for a frame on every vsync while the monitor is open, so
    // the intervals show what the app can sustain, not how often it happens to
    // repaint.
    _ticker = createTicker(onTick)..start();
    SchedulerBinding.instance.addTimingsCallback(handleTimings);
    _statsTimer = Timer.periodic(_window, (_) => flushWindow());
  }

  double _readHeap() =>
      widget.heapSizeOverride != null
          ? widget.heapSizeOverride!()
          : getJsHeapSize();

  // navigator.deviceMemory is capped at 8 by the spec.
  static String deviceMemoryLabel(double gb) {
    if (gb <= 0.0) return AppStrings.wasmNotAvailable;
    if (gb >= 8.0) return AppStrings.wasmDeviceMemoryCapped;
    return _fill(AppStrings.wasmDeviceMemoryGb, [_trimmed(gb)]);
  }

  Future<void> _loadEngine() async {
    await _engine.init();
    if (!mounted) return;
    setState(() {
      if (_engine.isReady) {
        _engineState = _EngineState.ready;
        addLog(
          'Engine',
          _fill(AppStrings.wasmEngineLoadedLog, [_megabytes(_engine)]),
        );
      } else {
        _engineState = _EngineState.unavailable;
        addLog('Engine', AppStrings.wasmEngineUnavailableLog);
      }
    });
  }

  void onTick(Duration elapsed) {
    final last = _lastTick;
    _lastTick = elapsed;
    if (last == null) return;

    final frameMs = (elapsed - last).inMicroseconds / 1000.0;
    if (frameMs <= 0.0 || frameMs > _suspendedMs) return;

    _windowIntervals.add(frameMs);
    _totalFrames++;
    if (frameMs > _slowFrameFactor * 1000.0 / _detectedRefreshRate) {
      _slowFrames++;
      _pendingSlow++;
      _pendingWorst = math.max(_pendingWorst, frameMs);
    }
  }

  void handleTimings(List<FrameTiming> timings) {
    for (final timing in timings) {
      _windowBuildMicros += timing.buildDuration.inMicroseconds;
      _windowRasterMicros += timing.rasterDuration.inMicroseconds;
    }
    _windowTimings += timings.length;
  }

  /// Turns the frames collected since the last call into one timeline sample.
  void flushWindow() {
    if (!mounted) return;
    setState(() {
      _heapMb = _readHeap();
      if (_windowIntervals.isEmpty) return;

      final sorted = [..._windowIntervals]..sort();
      final average = sorted.reduce((a, b) => a + b) / sorted.length;
      _windowIntervals.clear();

      _frameMs = average;
      _fps = 1000.0 / average;

      double? cpu;
      if (_windowTimings > 0) {
        _buildMs = _windowBuildMicros / _windowTimings / 1000.0;
        _rasterMs = _windowRasterMicros / _windowTimings / 1000.0;
        cpu = _buildMs! + _rasterMs!;
        _windowBuildMicros = 0;
        _windowRasterMicros = 0;
        _windowTimings = 0;
      }

      // The median ignores the odd short or long frame, and the rate only
      // goes up: a slow stretch is the app dropping frames, not a new display.
      if (sorted.length >= 5) {
        final rate = _refreshRateFor(sorted[sorted.length ~/ 2]);
        if (rate > _detectedRefreshRate) {
          _detectedRefreshRate = rate;
          addLog(
            'Display',
            _fill(AppStrings.wasmRefreshLog, [rate.toStringAsFixed(0)]),
          );
        }
      }

      _windowsSinceSlowLog++;
      if (_pendingSlow > 0 && _windowsSinceSlowLog >= _windowsPerSlowLog) {
        addLog(
          'Frames',
          _fill(AppStrings.wasmSlowFramesLog, [
            '$_pendingSlow',
            _trimmed(_windowsSinceSlowLog * _window.inMilliseconds / 1000.0),
            _pendingWorst.toStringAsFixed(1),
            (1000.0 / _detectedRefreshRate).toStringAsFixed(1),
          ]),
        );
        _pendingSlow = 0;
        _pendingWorst = 0.0;
        _windowsSinceSlowLog = 0;
      }

      if (_history.length == _historyLength) _history.removeAt(0);
      _history.add(
        _FrameSample(average: average, worst: sorted.last, cpu: cpu),
      );
      _historyRevision++;
    });
  }

  static double _refreshRateFor(double frameMs) {
    // 10% margin over each period for scheduling jitter.
    if (frameMs <= 4.6) return 240.0;
    if (frameMs <= 6.2) return 165.0;
    if (frameMs <= 7.4) return 144.0;
    if (frameMs <= 9.0) return 120.0;
    if (frameMs <= 12.0) return 90.0;
    if (frameMs <= 14.5) return 75.0;
    return 60.0;
  }

  void addLog(String component, String message) {
    final now = DateTime.now();
    final timeStr =
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}.${(now.millisecond ~/ 100)}';
    _logs.add('[$timeStr] [$component] $message');

    // Limit log size
    if (_logs.length > 55) {
      _logs.removeAt(0);
    }

    // Scroll to bottom
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  /// Times the same Mandelbrot frame in the Rust engine and in Dart. Both run
  /// on the UI thread, so the stall they cause shows up on the timeline too.
  Future<void> runBenchmark() async {
    if (_benchmarking) return;
    setState(() {
      _benchmarking = true;
      addLog(
        'Bench',
        _fill(AppStrings.wasmBenchmarkStartLog, [
          '$_benchWidth',
          '$_benchHeight',
          '$_benchIterations',
          '$_benchRuns',
        ]),
      );
    });

    double? rustMs;
    if (_engine.isReady) {
      rustMs = await _median(
        () => _engine.generateFractal(
          width: _benchWidth,
          height: _benchHeight,
          zoom: 1.0,
          offsetX: -0.5,
          offsetY: 0.0,
          maxIterations: _benchIterations,
          isJulia: false,
          cxJulia: 0.0,
          cyJulia: 0.0,
          time: 0.0,
        ),
      );
      if (rustMs == null) return;
    }

    final buffer = Uint8List(_benchWidth * _benchHeight * 4);
    final dartMs = await _median(
      () => renderFractalDart(
        buffer: buffer,
        width: _benchWidth,
        height: _benchHeight,
        zoom: 1.0,
        offsetX: -0.5,
        offsetY: 0.0,
        maxIterations: _benchIterations,
      ),
    );
    if (dartMs == null) return;

    setState(() {
      _benchmarking = false;
      _benchmark = _BenchmarkResult(dartMs: dartMs, rustMs: rustMs);

      final dartLabel = _fill(AppStrings.wasmBenchmarkDart, [_dartTarget]);
      if (rustMs != null) {
        _logBenchmark(AppStrings.wasmBenchmarkRust, rustMs);
      } else {
        addLog('Bench', AppStrings.wasmEngineUnavailableLog);
      }
      _logBenchmark(dartLabel, dartMs);
      final verdict = benchmarkVerdict(rustMs, dartMs, dartLabel);
      if (verdict != null) addLog('Bench', verdict);
    });
  }

  /// Median of [_benchRuns] timed calls after one warm-up, with a frame in
  /// between so the page keeps painting. Null when the window closed meanwhile.
  Future<double?> _median(VoidCallback run) async {
    final samples = <double>[];
    for (var i = 0; i <= _benchRuns; i++) {
      final stopwatch = Stopwatch()..start();
      run();
      stopwatch.stop();
      if (i > 0) samples.add(stopwatch.elapsedMicroseconds / 1000.0);
      await WidgetsBinding.instance.endOfFrame;
      if (!mounted) return null;
    }
    samples.sort();
    return samples[samples.length ~/ 2];
  }

  void _logBenchmark(String label, double ms) {
    addLog(
      'Bench',
      _fill(AppStrings.wasmBenchmarkResultLog, [
        label,
        ms.toStringAsFixed(1),
        megapixelsPerSecond(ms),
      ]),
    );
  }

  static String megapixelsPerSecond(double ms) {
    if (ms <= 0.0) return AppStrings.wasmNotAvailable;
    return (_benchWidth * _benchHeight / 1e6 / (ms / 1000.0)).toStringAsFixed(
      1,
    );
  }

  static String? benchmarkVerdict(
    double? rustMs,
    double dartMs,
    String dartLabel,
  ) {
    if (rustMs == null || rustMs <= 0.0 || dartMs <= 0.0) return null;
    final rustWins = rustMs <= dartMs;
    final ratio = rustWins ? dartMs / rustMs : rustMs / dartMs;
    return _fill(AppStrings.wasmBenchmarkVerdictLog, [
      rustWins ? AppStrings.wasmBenchmarkRust : dartLabel,
      ratio.toStringAsFixed(1),
      rustWins ? dartLabel : AppStrings.wasmBenchmarkRust,
    ]);
  }

  static String _megabytes(WasmEngineService engine) =>
      (engine.memoryBytes / (1024 * 1024)).toStringAsFixed(1);

  static String _trimmed(double value) =>
      value == value.roundToDouble()
          ? value.toStringAsFixed(0)
          : value.toStringAsFixed(1);

  static String _fill(String template, List<String> values) {
    var result = template;
    for (final value in values) {
      result = result.replaceFirst('%s', value);
    }
    return result;
  }

  @override
  void dispose() {
    _ticker.dispose();
    _statsTimer.cancel();
    SchedulerBinding.instance.removeTimingsCallback(handleTimings);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double targetMs = 1000.0 / _detectedRefreshRate;
    final double worstInHistory = _history.fold(
      0.0,
      (worst, sample) => math.max(worst, sample.worst),
    );
    // Room for two budgets, stretched when a slow frame needs more.
    final double maxMs = math.max(
      (targetMs * 2.0).ceilToDouble(),
      (worstInHistory * 1.15).ceilToDouble(),
    );

    final fps = _fps;
    final frameMs = _frameMs;
    final buildMs = _buildMs;
    final rasterMs = _rasterMs;

    final cards = [
      _WasmStatCard(
        title: AppStrings.wasmFps,
        val: fps != null ? fps.toStringAsFixed(1) : AppStrings.wasmNotAvailable,
        caption:
            frameMs != null
                ? _fill(AppStrings.wasmFpsCaption, [frameMs.toStringAsFixed(1)])
                : AppStrings.wasmFrameCpuWaiting,
        color:
            fps == null
                ? AppTheme.subtext
                : fps >= _detectedRefreshRate * 0.95
                ? AppTheme.green
                : AppTheme.yellow,
        icon: Icons.speed,
      ),
      _WasmStatCard(
        title: AppStrings.wasmFrameCpu,
        val:
            buildMs != null && rasterMs != null
                ? '${(buildMs + rasterMs).toStringAsFixed(1)}ms'
                : AppStrings.wasmNotAvailable,
        caption:
            buildMs != null && rasterMs != null
                ? _fill(AppStrings.wasmFrameCpuCaption, [
                  buildMs.toStringAsFixed(1),
                  rasterMs.toStringAsFixed(1),
                ])
                : AppStrings.wasmFrameCpuWaiting,
        color:
            buildMs == null || rasterMs == null
                ? AppTheme.subtext
                : buildMs + rasterMs < targetMs
                ? AppTheme.blue
                : AppTheme.peach,
        icon: Icons.timelapse,
      ),
      _WasmStatCard(
        title: AppStrings.wasmHeap,
        val:
            _heapMb > 0.0
                ? '${_heapMb.toStringAsFixed(1)} MB'
                : AppStrings.wasmNotAvailable,
        caption:
            _heapMb > 0.0
                ? AppStrings.wasmHeapCaption
                : AppStrings.wasmHeapUnavailableCaption,
        color: _heapMb > 0.0 ? AppTheme.teal : AppTheme.subtext,
        icon: Icons.memory,
      ),
      _WasmStatCard(
        title: AppStrings.wasmRustMemory,
        val:
            _engineState == _EngineState.ready
                ? '${_megabytes(_engine)} MB'
                : AppStrings.wasmNotAvailable,
        caption: switch (_engineState) {
          _EngineState.ready => AppStrings.wasmRustMemoryCaption,
          _EngineState.loading => AppStrings.wasmRustMemoryLoading,
          _EngineState.unavailable => AppStrings.wasmRustMemoryUnavailable,
        },
        color:
            _engineState == _EngineState.ready
                ? AppTheme.peach
                : AppTheme.subtext,
        icon: Icons.developer_board,
      ),
    ];

    return Container(
      color: AppTheme.background,
      padding: const EdgeInsets.all(AppSizes.spacingMd),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 440;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (compact) ...[
                _cardRow(cards.sublist(0, 2)),
                const SizedBox(height: AppSizes.spacingSm),
                _cardRow(cards.sublist(2)),
              ] else
                _cardRow(cards),
              const SizedBox(height: AppSizes.spacingMd),

              // Chart Section
              Expanded(
                flex: 5,
                child: _Panel(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        alignment: WrapAlignment.spaceBetween,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: AppSizes.spacingLg,
                        children: [
                          Text(
                            AppStrings.wasmTimelineTitle,
                            style: GoogleFonts.spaceMono(
                              color: AppTheme.text,
                              fontSize: AppSizes.fontXl,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '${AppStrings.wasmTargetBudgetPrefix}${_detectedRefreshRate.toStringAsFixed(0)}Hz (${targetMs.toStringAsFixed(1)}ms) · '
                            '${_fill(AppStrings.wasmSlowFrames, ['$_slowFrames', '$_totalFrames'])}',
                            style: GoogleFonts.spaceMono(
                              color:
                                  _slowFrames > 0
                                      ? AppTheme.yellow
                                      : AppTheme.subtext,
                              fontSize: AppSizes.fontLg,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSizes.spacingXs),
                      const Wrap(
                        spacing: AppSizes.spacingLg,
                        children: [
                          _LegendEntry(
                            color: AppTheme.teal,
                            label: AppStrings.wasmLegendInterval,
                          ),
                          _LegendEntry(
                            color: AppTheme.peach,
                            label: AppStrings.wasmLegendWorst,
                          ),
                          _LegendEntry(
                            color: AppTheme.mauve,
                            label: AppStrings.wasmLegendCpu,
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSizes.spacingSm),
                      Expanded(
                        child: RepaintBoundary(
                          child: CustomPaint(
                            painter: _DiagnosticsChartPainter(
                              history: _history,
                              revision: _historyRevision,
                              capacity: _historyLength,
                              maxMs: maxMs,
                              targetMs: targetMs,
                            ),
                            size: Size.infinite,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSizes.spacingMd),

              // Benchmark + what this browser supports
              Wrap(
                spacing: AppSizes.spacingSm,
                runSpacing: AppSizes.spacingSm,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  ElevatedButton.icon(
                    onPressed: _benchmarking ? null : runBenchmark,
                    icon: const Icon(Icons.bolt, size: 14),
                    label: Text(
                      _benchmarking
                          ? AppStrings.wasmBenchmarkRunning
                          : AppStrings.wasmRunBenchmark,
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.blue,
                      foregroundColor: AppTheme.background,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                      ),
                      textStyle: GoogleFonts.spaceMono(
                        fontWeight: FontWeight.bold,
                        fontSize: AppSizes.fontXl,
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSizes.spacingLg,
                        vertical: AppSizes.spacingMd,
                      ),
                    ),
                  ),
                  _CapabilityChip(
                    label: AppStrings.wasmSimd,
                    supported: _simdSupported,
                  ),
                  _CapabilityChip(
                    label: AppStrings.wasmWasmGc,
                    supported: _gcSupported,
                  ),
                  _CapabilityChip(label: _dartTarget),
                ],
              ),
              if (_benchmark != null) ...[
                const SizedBox(height: AppSizes.spacingSm),
                _BenchmarkBars(
                  result: _benchmark!,
                  dartLabel: _fill(AppStrings.wasmBenchmarkDart, [_dartTarget]),
                ),
              ],
              const SizedBox(height: AppSizes.spacingMd),

              // Log terminal
              Expanded(
                flex: 3,
                child: _Panel(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.terminal,
                            size: 14,
                            color: AppTheme.green,
                          ),
                          const SizedBox(width: AppSizes.spacingSm),
                          Text(
                            AppStrings.wasmConsoleTitle,
                            style: GoogleFonts.spaceMono(
                              color: AppTheme.green,
                              fontSize: AppSizes.fontXl,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSizes.spacingSm),
                      Expanded(
                        child: ListView.builder(
                          controller: _scrollController,
                          itemCount: _logs.length,
                          itemBuilder: (context, index) {
                            return Padding(
                              padding: const EdgeInsets.only(
                                bottom: AppSizes.spacingXxs,
                              ),
                              child: Text(
                                _logs[index],
                                style: GoogleFonts.spaceMono(
                                  color: AppTheme.text,
                                  fontSize: AppSizes.fontLg,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _cardRow(List<Widget> cards) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final (index, card) in cards.indexed) ...[
            if (index > 0) const SizedBox(width: AppSizes.spacingSm),
            Expanded(child: card),
          ],
        ],
      ),
    );
  }
}

class _Panel extends StatelessWidget {
  const _Panel({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF11111B),
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        border: Border.all(color: AppTheme.surface),
      ),
      padding: const EdgeInsets.all(AppSizes.spacingMd),
      child: child,
    );
  }
}

class _WasmStatCard extends StatelessWidget {
  const _WasmStatCard({
    required this.title,
    required this.val,
    required this.caption,
    required this.color,
    required this.icon,
  });

  final String title;
  final String val;
  final String caption;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        vertical: AppSizes.spacingMd,
        horizontal: AppSizes.spacingSm,
      ),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        border: Border.all(color: AppTheme.surface0),
      ),
      child: Column(
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 12, color: AppTheme.subtext),
                const SizedBox(width: AppSizes.spacingXs),
                Text(
                  title.toUpperCase(),
                  style: GoogleFonts.spaceMono(
                    color: AppTheme.subtext,
                    fontSize: AppSizes.fontLg,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSizes.spacingXs),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              val,
              style: GoogleFonts.spaceMono(
                color: color,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: AppSizes.spacingXxs),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              caption,
              style: GoogleFonts.spaceMono(
                color: AppTheme.subtext,
                fontSize: AppSizes.fontLg,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Read-only: what the browser reports, or (without [supported]) a plain fact.
class _CapabilityChip extends StatelessWidget {
  const _CapabilityChip({required this.label, this.supported});

  final String label;
  final bool? supported;

  @override
  Widget build(BuildContext context) {
    final supported = this.supported;
    final color =
        supported == null
            ? AppTheme.blue
            : supported
            ? AppTheme.green
            : AppTheme.overlay;

    final chip = Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.spacingMd,
        vertical: AppSizes.spacingSm,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppSizes.radiusSm),
        border: Border.all(color: color),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (supported != null) ...[
            Icon(supported ? Icons.check : Icons.close, size: 12, color: color),
            const SizedBox(width: AppSizes.spacingXs),
          ],
          Text(
            label,
            style: GoogleFonts.spaceMono(
              color: color,
              fontSize: AppSizes.fontLg,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );

    if (supported == null) return chip;
    return Tooltip(
      message:
          supported
              ? AppStrings.wasmCapabilityYes
              : AppStrings.wasmCapabilityNo,
      child: chip,
    );
  }
}

class _LegendEntry extends StatelessWidget {
  const _LegendEntry({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 10, height: 2, color: color),
        const SizedBox(width: AppSizes.spacingXs),
        Text(
          label,
          style: GoogleFonts.spaceMono(
            color: AppTheme.subtext,
            fontSize: AppSizes.fontLg,
          ),
        ),
      ],
    );
  }
}

class _BenchmarkBars extends StatelessWidget {
  const _BenchmarkBars({required this.result, required this.dartLabel});

  final _BenchmarkResult result;
  final String dartLabel;

  @override
  Widget build(BuildContext context) {
    final rustMs = result.rustMs;
    final slowest = math.max(result.dartMs, rustMs ?? 0.0);
    return _Panel(
      child: Column(
        children: [
          if (rustMs != null) ...[
            _bar(AppStrings.wasmBenchmarkRust, rustMs, slowest, AppTheme.peach),
            const SizedBox(height: AppSizes.spacingXs),
          ],
          _bar(dartLabel, result.dartMs, slowest, AppTheme.blue),
        ],
      ),
    );
  }

  Widget _bar(String label, double ms, double slowest, Color color) {
    final style = GoogleFonts.spaceMono(
      color: AppTheme.text,
      fontSize: AppSizes.fontLg,
    );
    return Row(
      children: [
        SizedBox(width: 116, child: Text(label, style: style)),
        Expanded(
          child: Align(
            alignment: Alignment.centerLeft,
            child: FractionallySizedBox(
              widthFactor:
                  slowest > 0.0 ? (ms / slowest).clamp(0.02, 1.0) : 1.0,
              child: Container(
                height: 8,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: AppSizes.spacingMd),
        Text('${ms.toStringAsFixed(1)} ms', style: style),
      ],
    );
  }
}

class _DiagnosticsChartPainter extends CustomPainter {
  _DiagnosticsChartPainter({
    required this.history,
    required this.revision,
    required this.capacity,
    required this.maxMs,
    required this.targetMs,
  });

  final List<_FrameSample> history;
  final int revision;
  final int capacity;
  final double maxMs;
  final double targetMs;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Grid lines (budget levels)
    final gridPaint =
        Paint()
          ..color = AppTheme.surface0.withValues(alpha: 0.3)
          ..strokeWidth = 1.0;

    // Draw horizontal budget grid lines (4 lines partition)
    final step = maxMs / 4.0;
    for (double ms = step; ms < maxMs; ms += step) {
      final y = h - (ms / maxMs) * h;
      canvas.drawLine(Offset(0, y), Offset(w, y), gridPaint);
    }

    // Target VSync baseline (e.g. 16.67ms or 8.33ms)
    final targetPaint =
        Paint()
          ..color = AppTheme.blue.withValues(alpha: 0.4)
          ..strokeWidth = 1.5
          ..style = PaintingStyle.stroke;

    final targetY = h - (targetMs / maxMs) * h;
    canvas.drawLine(Offset(0, targetY), Offset(w, targetY), targetPaint);
    _label(
      canvas,
      '${targetMs.toStringAsFixed(1)}ms',
      AppTheme.blue.withValues(alpha: 0.8),
      (label) => Offset(w - label.width - 4, targetY - label.height - 2),
    );

    // Top of the scale
    _label(
      canvas,
      '${maxMs.toStringAsFixed(0)}ms',
      AppTheme.subtext,
      (label) => const Offset(4, 2),
    );

    if (history.length < 2) return;

    // Samples enter on the right and scroll left, one slot per window.
    final xStep = w / (capacity - 1);
    double getX(int index) => w - (history.length - 1 - index) * xStep;
    double getY(double val) => h - (math.min(maxMs, val) / maxMs) * h;

    final averagePath = Path();
    final worstPath = Path();
    final cpuPath = Path();
    final fillPath = Path()..moveTo(getX(0), h);
    var cpuOpen = false;

    for (int i = 0; i < history.length; i++) {
      final x = getX(i);
      final sample = history[i];
      final y = getY(sample.average);
      if (i == 0) {
        averagePath.moveTo(x, y);
        worstPath.moveTo(x, getY(sample.worst));
      } else {
        averagePath.lineTo(x, y);
        worstPath.lineTo(x, getY(sample.worst));
      }
      fillPath.lineTo(x, y);

      // A window without FrameTiming leaves a gap instead of a guess.
      final cpu = sample.cpu;
      if (cpu == null) {
        cpuOpen = false;
      } else if (cpuOpen) {
        cpuPath.lineTo(x, getY(cpu));
      } else {
        cpuPath.moveTo(x, getY(cpu));
        cpuOpen = true;
      }
    }

    fillPath
      ..lineTo(w, h)
      ..close();

    final fillPaint =
        Paint()
          ..style = PaintingStyle.fill
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppTheme.teal.withValues(alpha: 0.3),
              AppTheme.teal.withValues(alpha: 0.0),
            ],
          ).createShader(Rect.fromLTWH(0, 0, w, h));

    Paint line(Color color, double width) =>
        Paint()
          ..color = color
          ..strokeWidth = width
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round;

    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(worstPath, line(AppTheme.peach.withValues(alpha: 0.7), 1));
    canvas.drawPath(cpuPath, line(AppTheme.mauve, 1.5));
    canvas.drawPath(averagePath, line(AppTheme.teal, 2));
  }

  void _label(
    Canvas canvas,
    String text,
    Color color,
    Offset Function(TextPainter label) position,
  ) {
    final label = TextPainter(
      text: TextSpan(
        text: text,
        style: GoogleFonts.spaceMono(
          color: color,
          fontSize: AppSizes.fontLg,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    label.paint(canvas, position(label));
    label.dispose();
  }

  @override
  bool shouldRepaint(_DiagnosticsChartPainter oldDelegate) =>
      oldDelegate.revision != revision ||
      oldDelegate.maxMs != maxMs ||
      oldDelegate.targetMs != targetMs;
}
