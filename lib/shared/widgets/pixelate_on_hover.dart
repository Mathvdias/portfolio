import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

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
  static ui.FragmentProgram? _program;
  static Future<ui.FragmentProgram>? _loading;

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
      _loading ??= ui.FragmentProgram.fromAsset('shaders/pixelate.frag');
      _program ??= await _loading!;
      if (mounted) setState(() => _shader = _program!.fragmentShader());
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
  void paint(PaintingContext context, Offset offset) {
    if (_pixels <= 1.0) {
      super.paint(context, offset);
      return;
    }

    final w = size.width;
    final h = size.height;

    // Render child into an offscreen layer, then snapshot to a ui.Image.
    final offscreen = OffsetLayer();
    final childCtx = PaintingContext(offscreen, Offset.zero & size);
    super.paint(childCtx, Offset.zero);
    childCtx.stopRecordingIfNeeded();
    final image = offscreen.toImageSync(Offset.zero & size);

    _shader
      ..setImageSampler(0, image)
      ..setFloat(0, _pixels)
      ..setFloat(1, w)
      ..setFloat(2, h);

    context.canvas.drawRect(
      offset & size,
      Paint()..shader = _shader,
    );

    image.dispose();
    offscreen.dispose();
  }
}
