import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../../core/bootstrap/shader_registry.dart';

/// Wraps [child] with a GPU glow halo effect that fades in on hover.
///
/// On mouse enter the glow animates to [radius] pixels; on leave it fades out.
/// Falls back transparently when the fragment shader is unavailable.
class GlowOnHover extends StatefulWidget {
  const GlowOnHover({
    super.key,
    required this.child,
    required this.color,
    this.radius = 16.0,
    this.intensity = 0.85,
    this.duration = const Duration(milliseconds: 250),
  });

  final Widget child;

  /// Accent colour for the halo.
  final Color color;

  /// Glow spread radius in logical pixels.
  final double radius;

  /// Peak opacity multiplier for the halo (0–1).
  final double intensity;

  final Duration duration;

  @override
  State<GlowOnHover> createState() => _GlowOnHoverState();
}

class _GlowOnHoverState extends State<GlowOnHover>
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
      final program = await ShaderRegistry.get('shaders/glow.frag');
      if (mounted) setState(() => _shader = program.fragmentShader());
    } catch (_) {
      // Shader unavailable — render child as-is.
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
              builder: (context, child) => _GlowShaderBox(
                shader: _shader!,
                color: widget.color,
                radius: _anim.value * widget.radius,
                intensity: widget.intensity,
                child: child!,
              ),
              child: widget.child,
            ),
    );
  }
}

class _GlowShaderBox extends SingleChildRenderObjectWidget {
  const _GlowShaderBox({
    required this.shader,
    required this.color,
    required this.radius,
    required this.intensity,
    required super.child,
  });

  final ui.FragmentShader shader;
  final Color color;
  final double radius;
  final double intensity;

  @override
  RenderObject createRenderObject(BuildContext context) => _GlowRenderBox(
        shader: shader,
        color: color,
        radius: radius,
        intensity: intensity,
      );

  @override
  void updateRenderObject(
      BuildContext context, covariant _GlowRenderBox renderObject) {
    renderObject
      ..shader = shader
      ..color = color
      ..radius = radius
      ..intensity = intensity;
  }
}

class _GlowRenderBox extends RenderProxyBox {
  _GlowRenderBox({
    required ui.FragmentShader shader,
    required Color color,
    required double radius,
    required double intensity,
  })  : _shader = shader,
        _color = color,
        _radius = radius,
        _intensity = intensity;

  ui.FragmentShader _shader;
  Color _color;
  double _radius;
  double _intensity;
  ui.Image? _cachedImage;
  bool _capturing = false;

  set shader(ui.FragmentShader v) {
    if (_shader == v) return;
    _shader = v;
    markNeedsPaint();
  }

  set color(Color v) {
    if (_color == v) return;
    _color = v;
    markNeedsPaint();
  }

  set radius(double v) {
    if (_radius == v) return;
    _radius = v;
    markNeedsPaint();
  }

  set intensity(double v) {
    if (_intensity == v) return;
    _intensity = v;
    markNeedsPaint();
  }

  @override
  void detach() {
    _cachedImage?.dispose();
    _cachedImage = null;
    super.detach();
  }

  Future<void> _captureAsync() async {
    if (_capturing) return;
    _capturing = true;
    final offscreen = OffsetLayer();
    final childCtx = PaintingContext(offscreen, Offset.zero & size);
    super.paint(childCtx, Offset.zero);
    childCtx.stopRecordingIfNeeded();
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
    if (_radius <= 0.0) {
      super.paint(context, offset);
      _cachedImage?.dispose();
      _cachedImage = null;
      return;
    }

    if (_cachedImage == null) {
      super.paint(context, offset);
      _captureAsync();
      return;
    }

    _shader
      ..setImageSampler(0, _cachedImage!)
      ..setFloat(0, size.width)
      ..setFloat(1, size.height)
      ..setFloat(2, _color.r)
      ..setFloat(3, _color.g)
      ..setFloat(4, _color.b)
      ..setFloat(5, _radius)
      ..setFloat(6, _intensity);

    context.canvas.drawRect(offset & size, Paint()..shader = _shader);

    _captureAsync();
  }
}
