import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../../core/bootstrap/shader_registry.dart';

/// Wraps [child] with a GPU pixelation effect that animates on hover.
///
/// On mouse enter the image is quantised to [pixelGridSize] cells; on leave it
/// smoothly returns to full resolution.  Falls back transparently when the
/// fragment shader cannot be loaded (test host, some browsers).
class PixelateOnHover extends StatefulWidget {
  const PixelateOnHover({
    super.key,
    required this.child,
    this.pixelGridSize = 12.0,
    this.duration = const Duration(milliseconds: 200),
  });

  final Widget child;

  /// Number of pixel cells at peak pixelation (higher = chunkier).
  final double pixelGridSize;

  final Duration duration;

  @override
  State<PixelateOnHover> createState() => _PixelateOnHoverState();
}

class _PixelateOnHoverState extends State<PixelateOnHover>
    with SingleTickerProviderStateMixin {
  ui.FragmentShader? _shader;
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: widget.duration);
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _loadShader();
  }

  Future<void> _loadShader() async {
    try {
      final program = await ShaderRegistry.get('shaders/pixelate.frag');
      if (mounted) setState(() => _shader = program.fragmentShader());
    } catch (_) {
      // Shader unavailable (test host, fallback mode) — render child as-is.
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _onEnter(_) => _ctrl.forward();
  void _onExit(_) => _ctrl.reverse();

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: _onEnter,
      onExit: _onExit,
      child: _shader == null
          ? widget.child
          : AnimatedBuilder(
              animation: _anim,
              builder: (context, child) {
                final pixels =
                    1.0 + (_anim.value * (widget.pixelGridSize - 1.0));
                return _PixelateShaderMask(
                  shader: _shader!,
                  pixels: pixels,
                  child: child!,
                );
              },
              child: widget.child,
            ),
    );
  }
}

// PaintingContext.stopRecordingIfNeeded is @protected; expose it via a
// subclass so RenderBox helpers can finalise the picture recording.
class _CapturePaintingContext extends PaintingContext {
  _CapturePaintingContext(super.containerLayer, super.estimatedBounds);
  void stopRecording() => stopRecordingIfNeeded();
}

class _PixelateShaderMask extends SingleChildRenderObjectWidget {
  const _PixelateShaderMask({
    required this.shader,
    required this.pixels,
    required super.child,
  });

  final ui.FragmentShader shader;
  final double pixels;

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _PixelateRenderBox(shader: shader, pixels: pixels);

  @override
  void updateRenderObject(
      BuildContext context, covariant _PixelateRenderBox renderObject) {
    renderObject
      ..shader = shader
      ..pixels = pixels;
  }
}

class _PixelateRenderBox extends RenderProxyBox {
  _PixelateRenderBox({
    required ui.FragmentShader shader,
    required double pixels,
  })  : _shader = shader,
        _pixels = pixels;

  ui.FragmentShader _shader;
  double _pixels;
  // Async-captured image reused across frames; refreshed whenever pixels > 1.
  ui.Image? _cachedImage;
  bool _capturing = false;

  set shader(ui.FragmentShader v) {
    if (_shader == v) return;
    _shader = v;
    markNeedsPaint();
  }

  set pixels(double v) {
    if (_pixels == v) return;
    _pixels = v;
    markNeedsPaint();
  }

  @override
  void detach() {
    _cachedImage?.dispose();
    _cachedImage = null;
    super.detach();
  }

  // Capture child into an offscreen image asynchronously to avoid blocking
  // the raster thread (toImage vs toImageSync).
  Future<void> _captureAsync() async {
    if (_capturing) return;
    _capturing = true;
    final offscreen = OffsetLayer();
    final childCtx = _CapturePaintingContext(offscreen, Offset.zero & size);
    super.paint(childCtx, Offset.zero);
    childCtx.stopRecording();
    final image = await offscreen.toImage(Offset.zero & size);
    offscreen.dispose();
    final old = _cachedImage;
    _cachedImage = image;
    old?.dispose();
    _capturing = false;
    markNeedsPaint();
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    if (_pixels <= 1.0) {
      super.paint(context, offset);
      _cachedImage?.dispose();
      _cachedImage = null;
      return;
    }

    // Kick off async capture; paint child directly on the first frame.
    if (_cachedImage == null) {
      super.paint(context, offset);
      _captureAsync();
      return;
    }

    _shader
      ..setImageSampler(0, _cachedImage!)
      ..setFloat(0, _pixels)
      ..setFloat(1, size.width)
      ..setFloat(2, size.height);

    context.canvas.drawRect(offset & size, Paint()..shader = _shader);

    // Refresh the snapshot every other paint so the effect stays in sync.
    _captureAsync();
  }
}
