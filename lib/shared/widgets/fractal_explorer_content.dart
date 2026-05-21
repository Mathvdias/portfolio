import 'dart:async';
import 'dart:ui' as ui;

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import '../../core/services/wasm_engine_service.dart';

class FractalExplorerContent extends StatefulWidget {
  const FractalExplorerContent({super.key});

  @override
  State<FractalExplorerContent> createState() => _FractalExplorerContentState();
}

class _FractalExplorerContentState extends State<FractalExplorerContent>
    with SingleTickerProviderStateMixin {
  late final WasmEngineService _engineService;
  ui.Image? _fractalImage;
  bool _isLoading = true;

  double _zoom = 1.0;
  double _offsetX = -0.5;
  double _offsetY = 0.0;
  final int _maxIterations = 100;

  // Auto-animation state
  late final Ticker _ticker;
  bool _autoAnimating = true;

  // Interesting point in the Mandelbrot set for the auto-zoom journey
  static const double _targetX = -0.7435;
  static const double _targetY = 0.1314;
  static const double _zoomSpeed = 0.12; // zoom multiplier per second

  // Resolution of the fractal rendering
  static const int renderWidth = 800;
  static const int renderHeight = 600;

  @override
  void initState() {
    super.initState();
    _engineService = WasmEngineService();
    _ticker = createTicker(_onTick);
    _initEngine();
  }

  Future<void> _initEngine() async {
    await _engineService.init();
    if (mounted) {
      setState(() => _isLoading = false);
      _renderFractal();
      // Start auto-animation
      _startAutoAnimation();
    }
  }

  void _startAutoAnimation() {
    _autoAnimating = true;
    // Reset to the interesting point
    _zoom = 1.0;
    _offsetX = _targetX;
    _offsetY = _targetY;
    if (!_ticker.isActive) {
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
    if (!_autoAnimating || !_engineService.isReady || !mounted) return;

    // Smooth exponential zoom — increases by _zoomSpeed per second
    final seconds = elapsed.inMicroseconds / 1e6;
    final newZoom = math.pow(1.0 + _zoomSpeed, seconds).toDouble();

    // Cap zoom to avoid precision loss
    if (newZoom > 1e12) {
      _stopAutoAnimation();
      return;
    }

    _zoom = newZoom;
    _renderFractal();
  }

  Future<void> _renderFractal() async {
    if (!_engineService.isReady) return;

    _engineService.generateMandelbrot(
      width: renderWidth,
      height: renderHeight,
      zoom: _zoom,
      offsetX: _offsetX,
      offsetY: _offsetY,
      maxIterations: _maxIterations,
    );

    final pixels = _engineService.getPixelBuffer();

    // Decode pixels into a Flutter ui.Image
    final completer = Completer<ui.Image>();
    ui.decodeImageFromPixels(
      // Ensure we get a copy of the Uint8List since the underlying buffer might be overwritten
      pixels,
      renderWidth,
      renderHeight,
      ui.PixelFormat.rgba8888,
      (img) => completer.complete(img),
    );

    final image = await completer.future;
    if (mounted) {
      setState(() {
        _fractalImage = image;
      });
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

    _renderFractal();
  }

  void _handleReset() {
    _stopAutoAnimation();
    setState(() {
      _zoom = 1.0;
      _offsetX = -0.5;
      _offsetY = 0.0;
    });
    _renderFractal();
    // Restart the auto-animation from the interesting point
    _startAutoAnimation();
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        return Stack(
          children: [
            GestureDetector(
              onTapUp: (details) => _handleTap(details, constraints),
              child: SizedBox(
                width: double.infinity,
                height: double.infinity,
                child: CustomPaint(
                  painter:
                      _fractalImage != null
                          ? _FractalPainter(image: _fractalImage!)
                          : null,
                ),
              ),
            ),
            Positioned(
              bottom: 16,
              right: 16,
              child: FloatingActionButton.small(
                onPressed: _handleReset,
                backgroundColor: Colors.white24,
                elevation: 0,
                child: const Icon(Icons.refresh, color: Colors.white),
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
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.auto_awesome,
                          color: Colors.white70,
                          size: 14,
                        ),
                        SizedBox(width: 4),
                        Text(
                          'Auto-exploring • Tap to navigate',
                          style: TextStyle(color: Colors.white70, fontSize: 11),
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
  final ui.Image image;

  _FractalPainter({required this.image});

  @override
  void paint(Canvas canvas, Size size) {
    final src = Rect.fromLTWH(
      0,
      0,
      image.width.toDouble(),
      image.height.toDouble(),
    );
    final dst = Rect.fromLTWH(0, 0, size.width, size.height);

    final paint =
        Paint()
          ..filterQuality = FilterQuality.high
          ..isAntiAlias = true;

    canvas.drawImageRect(image, src, dst, paint);
  }

  @override
  bool shouldRepaint(covariant _FractalPainter oldDelegate) {
    return oldDelegate.image != image;
  }
}
