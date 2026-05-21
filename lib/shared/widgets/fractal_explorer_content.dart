import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import '../../core/services/wasm_engine_service.dart';

class FractalExplorerContent extends StatefulWidget {
  const FractalExplorerContent({super.key});

  @override
  State<FractalExplorerContent> createState() => _FractalExplorerContentState();
}

class _FractalExplorerContentState extends State<FractalExplorerContent> {
  late final WasmEngineService _engineService;
  ui.Image? _fractalImage;
  bool _isLoading = true;

  double _zoom = 1.0;
  double _offsetX = -0.5;
  double _offsetY = 0.0;
  final int _maxIterations = 100;

  // Resolution of the fractal rendering
  static const int renderWidth = 800;
  static const int renderHeight = 600;

  @override
  void initState() {
    super.initState();
    _engineService = WasmEngineService();
    _initEngine();
  }

  Future<void> _initEngine() async {
    await _engineService.init();
    if (mounted) {
      setState(() => _isLoading = false);
      _renderFractal();
    }
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
    setState(() {
      _zoom = 1.0;
      _offsetX = -0.5;
      _offsetY = 0.0;
    });
    _renderFractal();
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
            const Positioned(
              top: 16,
              left: 16,
              child: IgnorePointer(
                child: Text(
                  'Tap to Zoom In',
                  style: TextStyle(
                    color: Colors.white,
                    backgroundColor: Colors.black54,
                    fontSize: 12,
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
