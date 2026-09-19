import 'dart:async';
import 'dart:ui' as ui;

import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import '../../core/services/wasm_engine_service.dart';

class FractalExplorerContent extends StatefulWidget {
  const FractalExplorerContent({super.key, this.engine});

  /// Engine to render with; defaults to the platform engine. Read once, when
  /// the window opens.
  final WasmEngineService? engine;

  @override
  State<FractalExplorerContent> createState() => _FractalExplorerContentState();
}

/// Render size for a view: the widget's aspect ratio (the engine derives its
/// own from width / height, so anything else stretches the image and shifts
/// where a tap lands), holding about [pixelBudget] pixels, capped by what the
/// widget can show and by the engine's buffer.
@visibleForTesting
(int, int) fractalRenderSize({
  required Size viewSize,
  required double pixelRatio,
  required double pixelBudget,
  int maxWidth = 800,
  int maxHeight = 600,
  int minPixels = 240 * 180,
}) {
  final aspect = (viewSize.width / viewSize.height).clamp(0.4, 3.0);
  final visible = viewSize.width * viewSize.height * pixelRatio * pixelRatio;
  final maxPixels = math.max(
    minPixels.toDouble(),
    math.min(maxWidth * maxHeight.toDouble(), visible),
  );
  final pixels = pixelBudget.clamp(minPixels.toDouble(), maxPixels);
  var height = math.sqrt(pixels / aspect);
  var width = height * aspect;
  final fit = math.min(1.0, math.min(maxWidth / width, maxHeight / height));
  width *= fit;
  height *= fit;
  return (math.max(16, width.floor()), math.max(16, height.floor()));
}

class FractalScenario {
  final String name;
  final double targetX;
  final double targetY;
  final double zoomSpeed;
  final bool isJulia;
  final double cxJulia;
  final double cyJulia;

  const FractalScenario({
    required this.name,
    required this.targetX,
    required this.targetY,
    this.zoomSpeed = 0.12,
    this.isJulia = false,
    this.cxJulia = 0.0,
    this.cyJulia = 0.0,
  });
}

class _FractalExplorerContentState extends State<FractalExplorerContent>
    with SingleTickerProviderStateMixin {
  late final WasmEngineService _engineService;

  /// The frame on screen. Only the painter listens to it, so a new frame
  /// repaints one layer instead of rebuilding the window's widget tree.
  final ValueNotifier<ui.Image?> _frame = ValueNotifier<ui.Image?>(null);
  bool _isLoading = true;
  bool _isRendering = false;

  // The engine runs synchronously on the UI thread, so its cost is frame time
  // taken from the whole desktop. While animating, the render size follows a
  // time budget; when the motion stops, one pass at full quality replaces it.
  static const double _budgetMs = 9.0;
  static const int _minPixels = 240 * 180;
  static const Duration _frameInterval = Duration(milliseconds: 33);
  double _pixelBudget = 360 * 270;
  Size _viewSize = const Size(800, 600);
  double _pixelRatio = 1.0;
  Duration _lastRenderAt = Duration.zero;
  bool _refined = false;

  /// A full-quality still was asked for while a frame was decoding. No tick
  /// follows a still, so nothing else would ever draw it.
  bool _stillOwed = false;

  double _zoom = 1.0;
  double _offsetX = -0.5;
  double _offsetY = 0.0;
  final int _maxIterations = 100;

  // Auto-animation state
  late final Ticker _ticker;
  bool _autoAnimating = true;
  double _currentTime = 0.0;

  static const List<FractalScenario> _scenarios = [
    FractalScenario(
      name: 'Mandelbrot: Seahorse',
      targetX: -0.7435,
      targetY: 0.1314,
    ),
    FractalScenario(
      name: 'Mandelbrot: Triple Spiral',
      targetX: -0.088,
      targetY: 0.654,
      zoomSpeed: 0.15,
    ),
    FractalScenario(
      name: 'Julia: Cosmic Bloom',
      targetX: 0.0,
      targetY: 0.0,
      isJulia: true,
      cxJulia: -0.7,
      cyJulia: 0.27015,
      zoomSpeed: 0.08,
    ),
    FractalScenario(
      name: 'Julia: Dragon Curve',
      targetX: 0.0,
      targetY: 0.0,
      isJulia: true,
      cxJulia: -0.8,
      cyJulia: 0.156,
      zoomSpeed: 0.1,
    ),
    FractalScenario(
      name: 'Mandelbrot: Elephant Valley',
      targetX: 0.28,
      targetY: 0.008,
      zoomSpeed: 0.08,
    ),
  ];

  int _currentScenarioIndex = 0;
  FractalScenario get _currentScenario => _scenarios[_currentScenarioIndex];

  // Resolution of the fractal rendering
  static const int renderWidth = 800;
  static const int renderHeight = 600;

  @override
  void initState() {
    super.initState();
    _engineService = widget.engine ?? WasmEngineService();
    _ticker = createTicker(_onTick);
    _initEngine();
  }

  Future<void> _initEngine() async {
    try {
      await _engineService.init();
    } catch (e) {
      debugPrint('Fractal engine failed to load: $e');
    }

    if (mounted) {
      setState(() => _isLoading = false);
      if (_engineService.isReady) {
        _renderFractal();
        // Start auto-animation
        _startAutoAnimation();
      }
    }
  }

  void _startAutoAnimation() {
    _autoAnimating = true;
    // Reset to the current scenario's target
    _zoom = 1.0;
    _offsetX = _currentScenario.targetX;
    _offsetY = _currentScenario.targetY;
    // The motion is back: a still would be stale before it was decoded.
    _stillOwed = false;
    if (!_ticker.isActive) {
      // A restarted ticker counts from zero again. Pacing against the previous
      // run's clock would hold every frame back for as long as that run lasted.
      _lastRenderAt = Duration.zero;
      _ticker.start();
    }
  }

  void _stopAutoAnimation() {
    _autoAnimating = false;
    if (_ticker.isActive) {
      _ticker.stop();
    }
  }

  void _onTick(Duration elapsed) {
    if (!_engineService.isReady || !mounted || _isRendering) return;
    // The zoom is slow: 30 fractal frames a second look the same as 120 and
    // leave the rest of the UI its frame time.
    if (elapsed - _lastRenderAt < _frameInterval) return;
    _lastRenderAt = elapsed;

    _currentTime = elapsed.inMicroseconds / 1e6;

    if (_autoAnimating) {
      // Smooth exponential zoom — increases by zoomSpeed per second
      final newZoom =
          math.pow(1.0 + _currentScenario.zoomSpeed, _currentTime).toDouble();

      // Cap zoom to avoid precision loss
      if (newZoom > 1e12) {
        // Rebuild: the labels say whether the view is still moving.
        setState(_stopAutoAnimation);
        // The frame that stays on screen gets the full-quality pass.
        _renderFractal(fullQuality: true);
        return;
      }
      _zoom = newZoom;
    }

    _renderFractal();
  }

  (int, int) _renderSize({required bool fullQuality}) => fractalRenderSize(
    viewSize: _viewSize,
    pixelRatio: _pixelRatio,
    pixelBudget: fullQuality ? double.infinity : _pixelBudget,
  );

  Future<void> _renderFractal({bool fullQuality = false}) async {
    if (!_engineService.isReady) return;
    if (_isRendering) {
      // A moving frame can be dropped, the next tick draws a newer one. Nothing
      // comes after a still: it waits for the frame in flight to land.
      if (fullQuality) _stillOwed = true;
      return;
    }

    _isRendering = true;

    try {
      final (width, height) = _renderSize(fullQuality: fullQuality);
      final clock = Stopwatch()..start();
      _engineService.generateFractal(
        width: width,
        height: height,
        zoom: _zoom,
        offsetX: _offsetX,
        offsetY: _offsetY,
        maxIterations: _maxIterations,
        isJulia: _currentScenario.isJulia,
        cxJulia: _currentScenario.cxJulia,
        cyJulia: _currentScenario.cyJulia,
        time: _currentTime,
      );
      final elapsedMs = clock.elapsedMicroseconds / 1000.0;
      if (!fullQuality && elapsedMs > 0.2) {
        // Cost is proportional to the pixel count: steer it towards the budget,
        // damped so one expensive frame does not make the image pump.
        final wanted = width * height * (_budgetMs / elapsedMs);
        _pixelBudget = (_pixelBudget * 0.7 + wanted * 0.3).clamp(
          _minPixels.toDouble(),
          renderWidth * renderHeight.toDouble(),
        );
      }

      // Rows are packed at the start of the engine's buffer. The copy is needed:
      // decoding is asynchronous and the WASM memory is reused by the next call.
      final pixels = Uint8List.fromList(
        Uint8List.sublistView(
          _engineService.getPixelBuffer(),
          0,
          width * height * 4,
        ),
      );

      final completer = Completer<ui.Image>();
      ui.decodeImageFromPixels(
        pixels,
        width,
        height,
        ui.PixelFormat.rgba8888,
        completer.complete,
      );

      final image = await completer.future;
      if (!mounted) {
        image.dispose();
        return;
      }
      // Every frame is a new texture: the previous one must be released, or GPU
      // memory grows by megabytes per second until the tab stalls.
      final previous = _frame.value;
      _refined = fullQuality;
      _frame.value = image;
      previous?.dispose();
    } catch (e) {
      debugPrint('Fractal render failed: $e');
    } finally {
      _isRendering = false;
    }

    if (_stillOwed && mounted) {
      _stillOwed = false;
      _renderFractal(fullQuality: true);
    }
  }

  void _handleTap(TapUpDetails details, BoxConstraints constraints) {
    // Stop auto-animation when user interacts
    _stopAutoAnimation();

    // Map tap position to normalized coordinates (-1 to 1)
    final tapX = (details.localPosition.dx / constraints.maxWidth) * 2.0 - 1.0;
    final tapY = (details.localPosition.dy / constraints.maxHeight) * 2.0 - 1.0;

    // Convert back considering zoom and offset
    final aspect = constraints.maxWidth / constraints.maxHeight;
    final dx = tapX * (2.0 / _zoom) * aspect;
    final dy = tapY * (2.0 / _zoom);

    setState(() {
      _offsetX += dx;
      _offsetY += dy;
      _zoom *= 1.5; // Zoom in by 1.5x per tap
    });

    // Nothing is moving any more: spend the time on a full-quality still.
    _renderFractal(fullQuality: true);
  }

  void _handleReset() {
    _stopAutoAnimation();
    setState(() {
      _zoom = 1.0;
      _offsetX = _currentScenario.isJulia ? 0.0 : -0.5;
      _offsetY = 0.0;
    });
    _renderFractal();
    // Restart the auto-animation from the current point
    _startAutoAnimation();
  }

  void _nextScenario() {
    setState(() {
      _currentScenarioIndex = (_currentScenarioIndex + 1) % _scenarios.length;
    });
    _handleReset();
  }

  @override
  void dispose() {
    _ticker.dispose();
    _frame.value?.dispose();
    _frame.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    }

    _pixelRatio = MediaQuery.devicePixelRatioOf(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.hasBoundedWidth && constraints.hasBoundedHeight) {
          _viewSize = Size(
            math.max(1.0, constraints.maxWidth),
            math.max(1.0, constraints.maxHeight),
          );
        }
        return Stack(
          children: [
            GestureDetector(
              onTapUp: (details) => _handleTap(details, constraints),
              child: RepaintBoundary(
                child: SizedBox(
                  width: double.infinity,
                  height: double.infinity,
                  child: CustomPaint(
                    painter: _FractalPainter(
                      frame: _frame,
                      refined: () => _refined,
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 16,
              right: 16,
              child: Row(
                children: [
                  FloatingActionButton.small(
                    onPressed: _nextScenario,
                    backgroundColor: Colors.white24,
                    elevation: 0,
                    tooltip: 'Change Scenario',
                    child: const Icon(Icons.auto_fix_high, color: Colors.white),
                  ),
                  const SizedBox(width: 8),
                  FloatingActionButton.small(
                    onPressed: _handleReset,
                    backgroundColor: Colors.white24,
                    elevation: 0,
                    tooltip: 'Reset',
                    child: const Icon(Icons.refresh, color: Colors.white),
                  ),
                ],
              ),
            ),
            Positioned(
              top: 16,
              left: 16,
              child: IgnorePointer(
                child: AnimatedOpacity(
                  opacity: _autoAnimating ? 0.0 : 1.0,
                  duration: const Duration(milliseconds: 300),
                  child: const Text(
                    'Tap to Zoom In',
                    style: TextStyle(
                      color: Colors.white,
                      backgroundColor: Colors.black54,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ),
            // Auto-animation indicator
            if (_autoAnimating)
              Positioned(
                top: 16,
                left: 16,
                child: IgnorePointer(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.auto_awesome,
                          color: Colors.white70,
                          size: 14,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Auto-exploring: ${_currentScenario.name}',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _FractalPainter extends CustomPainter {
  _FractalPainter({required this.frame, required this.refined})
    : super(repaint: frame);

  final ValueListenable<ui.Image?> frame;
  final bool Function() refined;

  final Paint _paint = Paint();

  @override
  void paint(Canvas canvas, Size size) {
    final image = frame.value;
    if (image == null) return;
    // Bilinear is all a moving, upscaled frame needs; the full-quality still
    // that follows gets the better filter.
    _paint.filterQuality = refined() ? FilterQuality.medium : FilterQuality.low;
    canvas.drawImageRect(
      image,
      Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
      Offset.zero & size,
      _paint,
    );
  }

  @override
  bool shouldRepaint(covariant _FractalPainter oldDelegate) =>
      oldDelegate.frame != frame;
}
