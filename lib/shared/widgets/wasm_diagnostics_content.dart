import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../theme/app_theme.dart';
import '../constants/app_sizes.dart';
import '../constants/app_strings.dart';
import '../utils/renderer_detector.dart';

class WasmDiagnosticsContent extends StatefulWidget {
  const WasmDiagnosticsContent({
    super.key,
    this.heapSizeOverride,
  });

  final double Function()? heapSizeOverride;

  @override
  State<WasmDiagnosticsContent> createState() => _WasmDiagnosticsContentState();
}

class _WasmDiagnosticsContentState extends State<WasmDiagnosticsContent> {
  late final Timer _statsTimer;
  final _random = math.Random(10);

  // Metrics
  double _fps = 60.0;
  double _frameTime = 16.6;
  double _heapMemory = 18.2;
  double _gcPause = 0.0;
  bool _simdEnabled = true;
  bool _gcEnabled = true;
  bool _compiling = false;
  double _detectedRefreshRate = 60.0; // Starts at 60Hz and dynamically scales upwards based on hardware VSync
  double get detectedRefreshRate => _detectedRefreshRate;

  // Real-time Frame Profiler
  int _lastFrameMicros = 0;
  final List<double> _recordedFrameTimes = [];

  // Chart History
  final List<double> _frameHistory = List.generate(60, (_) => 8.0 + math.Random().nextDouble() * 4.0);

  // System Logs
  final List<String> _logs = [];
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();

    // Query hardware features dynamically from browser APIs
    _simdEnabled = isHardwareSimdSupported();
    _gcEnabled = isHardwareWasmGcSupported();
    final cores = getHardwareCpuCores();
    final ram = getHardwareDeviceMemory();

    // Setup initial system logs based on actual hardware specifications
    addLog('System', AppStrings.wasmEngineInit);
    addLog(
      'Hardware',
      AppStrings.wasmCpuDetect
          .replaceFirst('%d', '$cores')
          .replaceFirst('%s', ram.toStringAsFixed(0)),
    );
    addLog(
      'Graphics',
      AppStrings.wasmRendererDetect
          .replaceFirst('%s', getRendererText())
          .replaceFirst('%s', getRendererSubtitle()),
    );
    addLog(
      'SIMD',
      _simdEnabled ? AppStrings.wasmSimdSupported : AppStrings.wasmSimdUnsupported,
    );
    addLog(
      'GC',
      _gcEnabled ? AppStrings.wasmGcSupported : AppStrings.wasmGcUnsupported,
    );
    addLog('Diagnostics', AppStrings.wasmProfilingActive);

    // Fetch initial real memory
    _heapMemory = widget.heapSizeOverride != null ? widget.heapSizeOverride!() : getJsHeapSize();

    // Start listening to actual frames rendered by the device
    WidgetsBinding.instance.addPostFrameCallback(onFrame);

    // Periodic updates to refresh stats in UI without overloading build pipeline
    _statsTimer = Timer.periodic(const Duration(milliseconds: 250), (_) {
      if (!mounted || _compiling) return;
      if (_recordedFrameTimes.isEmpty) return;

      setState(() {
        // Average frame time over the last 250ms period
        final sum = _recordedFrameTimes.reduce((a, b) => a + b);
        double avgFrameTime = sum / _recordedFrameTimes.length;
        _recordedFrameTimes.clear(); // Reset buffer for next interval

        // Add minor realistic render jitter and micro-spikes (e.g. mouse move, canvas updates)
        if (_random.nextDouble() > 0.85) {
          avgFrameTime += 2.0 + _random.nextDouble() * 4.0; // Simulated layout spike
        } else {
          avgFrameTime += (_random.nextDouble() - 0.5) * 0.8; // Normal jitter
        }

        if (!_simdEnabled) {
          avgFrameTime += 3.0 + _random.nextDouble() * 2.0; // Simulate software fallback overhead
        }

        // Clamp values to realistic ranges
        _frameTime = math.max(1.0, avgFrameTime);

        // Calculate current real-time FPS
        _fps = math.min(240.0, 1000.0 / _frameTime);

        // Fetch actual JS heap memory from native browser API
        final realMemory = widget.heapSizeOverride != null ? widget.heapSizeOverride!() : getJsHeapSize();
        if (realMemory > 0.0) {
          _heapMemory = realMemory;
        } else {
          // Fallback simulation if browser performance.memory is blocked/unsupported
          _heapMemory += 0.02 + _random.nextDouble() * 0.01;
          if (_heapMemory >= 21.0 && _gcEnabled) {
            runGarbageCollection(auto: true);
          }
        }

        // Add actual frame performance to history
        _frameHistory.removeAt(0);
        _frameHistory.add(_frameTime);
      });
    });
  }

  void onFrame(Duration timestamp) {
    if (!mounted) return;
    final currentMicros = timestamp.inMicroseconds;
    if (_lastFrameMicros != 0) {
      final elapsed = currentMicros - _lastFrameMicros;
      if (elapsed > 0) {
        final frameMs = elapsed / 1000.0;
        _recordedFrameTimes.add(frameMs);

        // Dynamic refresh rate detection based on VSync frame intervals.
        // We look for intervals (with 10% safety margin for OS/browser task runner scheduling jitter)
        // and scale the active target hardware capabilities accordingly.
        if (frameMs > 1.0) {
          if (frameMs <= 4.6) {
            _detectedRefreshRate = 240.0;
          } else if (frameMs <= 6.2) {
            _detectedRefreshRate = 165.0;
          } else if (frameMs <= 7.4) {
            _detectedRefreshRate = 144.0;
          } else if (frameMs <= 9.0) {
            _detectedRefreshRate = 120.0;
          } else if (frameMs <= 12.0) {
            _detectedRefreshRate = 90.0;
          } else if (frameMs <= 14.5) {
            _detectedRefreshRate = 75.0;
          }
        }

        // Safety cap on size
        if (_recordedFrameTimes.length > 500) {
          _recordedFrameTimes.removeAt(0);
        }
      }
    }
    _lastFrameMicros = currentMicros;
    
    // Listen for next frame rendering callback
    WidgetsBinding.instance.addPostFrameCallback(onFrame);
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

  void runGarbageCollection({bool auto = false}) {
    _gcPause = 0.2 + _random.nextDouble() * 0.4;
    final realMemory = widget.heapSizeOverride != null ? widget.heapSizeOverride!() : getJsHeapSize();

    // If real memory API works, it will naturally drop after a GC signal,
    // otherwise we simulate a memory drop.
    if (realMemory <= 0.0) {
      _heapMemory = 14.5 + _random.nextDouble() * 1.5;
    }

    final gcType = auto ? AppStrings.wasmGcAuto : AppStrings.wasmGcManual;
    addLog(
      'GC',
      AppStrings.wasmGcLogTemplate
          .replaceFirst('%s', gcType)
          .replaceFirst('%s', _heapMemory.toStringAsFixed(1))
          .replaceFirst('%s', _gcPause.toStringAsFixed(1)),
    );

    // Reset GC pause visual after a short delay
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _gcPause = 0.0;
        });
      }
    });
  }

  void _triggerHotReload() {
    if (_compiling) return;

    setState(() {
      _compiling = true;
    });

    addLog('Compiler', AppStrings.wasmHotReloadTrigger);

    Future.delayed(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      addLog('Compiler', AppStrings.wasmHotReloadCompile);

      Future.delayed(const Duration(milliseconds: 400), () {
        if (!mounted) return;
        addLog('Compiler', AppStrings.wasmHotReloadSuccess);
        setState(() {
          _compiling = false;
        });
        _showToast();
      });
    });
  }

  void _showToast() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppTheme.blue,
        duration: const Duration(seconds: 3),
        content: Row(
          children: [
            const Icon(Icons.flash_on, color: AppTheme.background),
            const SizedBox(width: AppSizes.spacingMd),
            Expanded(
              child: Text(
                AppStrings.wasmHotReloadToast,
                style: GoogleFonts.spaceMono(
                  color: AppTheme.background,
                  fontSize: AppSizes.fontXl,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _statsTimer.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Dynamic chart scaling and target VSync calculations based on detected device refresh rate
    final double targetMs = 1000.0 / _detectedRefreshRate;
    final double maxInHistory = _frameHistory.reduce(math.max);
    final bool isHighRefreshRate = _detectedRefreshRate > 90.0;
    final double baseMax = isHighRefreshRate ? 16.0 : 28.0;
    final double maxMs = math.max(baseMax, (maxInHistory * 1.15).ceilToDouble());

    return Container(
      color: AppTheme.background,
      padding: const EdgeInsets.all(AppSizes.spacingMd),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Row of stats cards
          Row(
            children: [
              _buildStatCard(
                AppStrings.wasmFps,
                _fps.toStringAsFixed(1),
                _fps > (_detectedRefreshRate * 0.95) ? AppTheme.green : AppTheme.yellow,
                icon: Icons.speed,
              ),
              const SizedBox(width: AppSizes.spacingSm),
              _buildStatCard(
                AppStrings.wasmFrameLatency,
                '${_frameTime.toStringAsFixed(1)}ms',
                _frameTime < targetMs ? AppTheme.blue : AppTheme.peach,
                icon: Icons.timelapse,
              ),
              const SizedBox(width: AppSizes.spacingSm),
              _buildStatCard(
                AppStrings.wasmHeap,
                '${_heapMemory.toStringAsFixed(1)} MB',
                _heapMemory < 19 ? AppTheme.teal : AppTheme.pink,
                icon: Icons.memory,
              ),
              const SizedBox(width: AppSizes.spacingSm),
              _buildStatCard(
                AppStrings.wasmGcPause,
                _gcPause > 0 ? '${_gcPause.toStringAsFixed(1)}ms' : '0.0ms',
                _gcPause > 0 ? AppTheme.red : AppTheme.subtext,
                icon: Icons.delete_sweep,
                pulse: _gcPause > 0,
              ),
            ],
          ),
          const SizedBox(height: AppSizes.spacingMd),

          // Chart Section
          Expanded(
            flex: 5,
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF11111B),
                borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                border: Border.all(color: AppTheme.surface),
              ),
              padding: const EdgeInsets.all(AppSizes.spacingMd),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                        '${AppStrings.wasmTargetBudgetPrefix}${_detectedRefreshRate.toStringAsFixed(0)}Hz (${targetMs.toStringAsFixed(1)}ms)',
                        style: GoogleFonts.spaceMono(
                          color: AppTheme.subtext,
                          fontSize: 9,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSizes.spacingSm),
                  Expanded(
                    child: RepaintBoundary(
                      child: CustomPaint(
                        painter: _DiagnosticsChartPainter(
                          history: _frameHistory,
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

          // Controls & Custom toggles
          Row(
            children: [
              ElevatedButton.icon(
                onPressed: _compiling ? null : _triggerHotReload,
                icon: const Icon(Icons.flash_on, size: 13),
                label: Text(_compiling ? AppStrings.wasmCompiling : AppStrings.wasmHotReload),
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
              const SizedBox(width: AppSizes.spacingSm),
              OutlinedButton.icon(
                onPressed: () => runGarbageCollection(),
                icon: const Icon(Icons.cleaning_services_outlined, size: 13),
                label: const Text(AppStrings.wasmTriggerGc),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.pink,
                  side: const BorderSide(color: AppTheme.pink, width: 1),
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
              const Spacer(),
              // Custom switches
              _buildCustomToggle(AppStrings.wasmSimd, _simdEnabled, (val) {
                setState(() => _simdEnabled = val);
                addLog(
                  AppStrings.wasmSimd,
                  val ? AppStrings.wasmSimdEnabledLog : AppStrings.wasmSimdDisabledLog,
                );
              }),
              const SizedBox(width: AppSizes.spacingLg),
              _buildCustomToggle(AppStrings.wasmWasmGc, _gcEnabled, (val) {
                setState(() => _gcEnabled = val);
                addLog(
                  AppStrings.wasmWasmGc,
                  val ? AppStrings.wasmGcEnabledLog : AppStrings.wasmGcDisabledLog,
                );
              }),
            ],
          ),
          const SizedBox(height: AppSizes.spacingMd),

          // Log terminal
          Expanded(
            flex: 3,
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF11111B),
                borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                border: Border.all(color: AppTheme.surface),
              ),
              padding: const EdgeInsets.all(AppSizes.spacingMd),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.terminal, size: 12, color: AppTheme.green),
                      const SizedBox(width: AppSizes.spacingSm),
                      Text(
                        AppStrings.wasmConsoleTitle,
                        style: GoogleFonts.spaceMono(
                          color: AppTheme.green,
                          fontSize: AppSizes.fontXl,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        AppStrings.wasmCompilerVersion,
                        style: GoogleFonts.spaceMono(
                          color: AppTheme.subtext,
                          fontSize: 9,
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
                          padding: const EdgeInsets.only(bottom: AppSizes.spacingXxs),
                          child: Text(
                            _logs[index],
                            style: GoogleFonts.spaceMono(
                              color: AppTheme.text,
                              fontSize: 10,
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
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    String val,
    Color color, {
    required IconData icon,
    bool pulse = false,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(
          vertical: AppSizes.spacingMd,
          horizontal: AppSizes.spacingSm,
        ),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          border: Border.all(
            color: pulse ? AppTheme.red : AppTheme.surface0,
            width: pulse ? 1.5 : 1.0,
          ),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 10, color: AppTheme.subtext),
                const SizedBox(width: 4),
                Text(
                  title.toUpperCase(),
                  style: GoogleFonts.spaceMono(
                    color: AppTheme.subtext,
                    fontSize: 8,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSizes.spacingXs),
            Text(
              val,
              style: GoogleFonts.spaceMono(
                color: color,
                fontSize: AppSizes.font2xl,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomToggle(
    String label,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: GoogleFonts.spaceMono(
                color: AppTheme.subtext,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              width: 32,
              height: 18,
              decoration: BoxDecoration(
                color: value ? AppTheme.green : AppTheme.surface0,
                borderRadius: BorderRadius.circular(9),
                border: Border.all(color: AppTheme.surface),
              ),
              child: Stack(
                children: [
                  AnimatedPositioned(
                    duration: const Duration(milliseconds: 120),
                    left: value ? 16.0 : 2.0,
                    top: 2.0,
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DiagnosticsChartPainter extends CustomPainter {
  _DiagnosticsChartPainter({
    required this.history,
    required this.maxMs,
    required this.targetMs,
  });

  final List<double> history;
  final double maxMs;
  final double targetMs;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Grid lines (budget levels)
    final gridPaint = Paint()
      ..color = AppTheme.surface0.withValues(alpha: 0.3)
      ..strokeWidth = 1.0;

    // Draw horizontal budget grid lines (4 lines partition)
    final step = maxMs / 4.0;
    for (double ms = step; ms < maxMs; ms += step) {
      final y = h - (ms / maxMs) * h;
      if (y >= 0 && y <= h) {
        canvas.drawLine(Offset(0, y), Offset(w, y), gridPaint);
      }
    }

    // Target VSync baseline (e.g. 16.67ms or 8.33ms)
    final targetPaint = Paint()
      ..color = AppTheme.blue.withValues(alpha: 0.4)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final targetY = h - (targetMs / maxMs) * h;
    canvas.drawLine(Offset(0, targetY), Offset(w, targetY), targetPaint);

    // Label for Target Budget
    final textPainter = TextPainter(
      text: TextSpan(
        text: '${targetMs.toStringAsFixed(1)}ms Target',
        style: GoogleFonts.spaceMono(
          color: AppTheme.blue.withValues(alpha: 0.7),
          fontSize: 8,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(w - textPainter.width - 8, targetY - textPainter.height - 2),
    );

    // Plot graph line
    final linePaint = Paint()
      ..color = AppTheme.teal
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final fillPaint = Paint()
      ..style = PaintingStyle.fill
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          AppTheme.teal.withValues(alpha: 0.3),
          AppTheme.teal.withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromLTWH(0, 0, w, h));

    final path = Path();
    final fillPath = Path();

    if (history.isNotEmpty) {
      final xStep = w / (history.length - 1);
      double getX(int index) => index * xStep;
      double getY(double val) {
        final clamped = math.min(maxMs, val);
        return h - (clamped / maxMs) * h;
      }

      path.moveTo(0, getY(history[0]));
      fillPath.moveTo(0, h);
      fillPath.lineTo(0, getY(history[0]));

      for (int i = 1; i < history.length; i++) {
        final x = getX(i);
        final y = getY(history[i]);
        path.lineTo(x, y);
        fillPath.lineTo(x, y);
      }

      fillPath.lineTo(w, h);
      fillPath.close();

      canvas.drawPath(fillPath, fillPaint);
      canvas.drawPath(path, linePaint);
    }
  }

  @override
  bool shouldRepaint(_DiagnosticsChartPainter oldDelegate) => true;
}
