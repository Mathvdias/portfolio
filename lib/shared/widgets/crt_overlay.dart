import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';

/// Fullscreen CRT post-process overlay.
///
/// Must be placed as the top layer in a Stack that covers the entire desktop.
/// It captures everything below it via OffsetLayer snapshot and applies
/// scanlines, barrel distortion, chromatic aberration, vignette, and flicker.
///
/// [intensity] controls the effect strength (0 = invisible, 1 = full retro).
class CrtOverlay extends StatefulWidget {
  const CrtOverlay({super.key, this.intensity = 0.35});

  final double intensity;

  @override
  State<CrtOverlay> createState() => _CrtOverlayState();
}

class _CrtOverlayState extends State<CrtOverlay>
    with SingleTickerProviderStateMixin {
  static ui.FragmentProgram? _program;
  static Future<ui.FragmentProgram>? _loading;

  ui.FragmentShader? _shader;
  late final Ticker _ticker;
  late final ValueNotifier<double> _elapsed;
  Duration _lastTick = Duration.zero;

  @override
  void initState() {
    super.initState();
    _elapsed = ValueNotifier(0.0);
    _loadShader();
    _ticker = createTicker((elapsed) {
      final dt = (elapsed - _lastTick).inMicroseconds / 1e6;
      _lastTick = elapsed;
      _elapsed.value += dt;
    });
    _ticker.start();
  }

  Future<void> _loadShader() async {
    try {
      _loading ??= ui.FragmentProgram.fromAsset('shaders/crt.frag');
      _program ??= await _loading!;
      if (mounted) setState(() => _shader = _program!.fragmentShader());
    } catch (_) {
      // Shader unavailable — overlay disappears gracefully.
    }
  }

  @override
  void dispose() {
    _ticker.dispose();
    _elapsed.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_shader == null) return const SizedBox.expand();
    return IgnorePointer(
      child: _CrtShaderBox(
        shader: _shader!,
        elapsed: _elapsed,
        intensity: widget.intensity,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Render object that snapshots its own layer and applies the CRT shader.
// ---------------------------------------------------------------------------

class _CrtShaderBox extends SingleChildRenderObjectWidget {
  const _CrtShaderBox({
    required this.shader,
    required this.elapsed,
    required this.intensity,
  }) : super(child: const SizedBox.expand());

  final ui.FragmentShader shader;
  final ValueNotifier<double> elapsed;
  final double intensity;

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _CrtRenderBox(shader: shader, elapsed: elapsed, intensity: intensity);

  @override
  void updateRenderObject(
      BuildContext context, covariant _CrtRenderBox renderObject) {
    renderObject
      ..shader = shader
      ..elapsed = elapsed
      ..intensity = intensity;
  }
}

class _CrtRenderBox extends RenderProxyBox {
  _CrtRenderBox({
    required ui.FragmentShader shader,
    required ValueNotifier<double> elapsed,
    required double intensity,
  })  : _shader = shader,
        _intensity = intensity {
    this.elapsed = elapsed;
  }

  ui.FragmentShader _shader;
  double _intensity;
  ValueNotifier<double>? _elapsed;

  set shader(ui.FragmentShader v) {
    if (_shader == v) return;
    _shader = v;
    markNeedsPaint();
  }

  set intensity(double v) {
    if (_intensity == v) return;
    _intensity = v;
    markNeedsPaint();
  }

  set elapsed(ValueNotifier<double> v) {
    _elapsed?.removeListener(markNeedsPaint);
    _elapsed = v;
    _elapsed!.addListener(markNeedsPaint);
  }

  @override
  void detach() {
    _elapsed?.removeListener(markNeedsPaint);
    super.detach();
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    if (_intensity <= 0.0) {
      super.paint(context, offset);
      return;
    }

    final w = size.width;
    final h = size.height;

    // The CRT effect samples what is already painted below (the entire desktop).
    // We capture our own bounds via an OffsetLayer snapshot so the shader has
    // access to the composited pixel data.
    final offscreen = OffsetLayer();
    final childCtx = PaintingContext(offscreen, Offset.zero & size);
    super.paint(childCtx, Offset.zero);
    childCtx.stopRecordingIfNeeded();
    final image = offscreen.toImageSync(Offset.zero & size);

    _shader
      ..setImageSampler(0, image)
      ..setFloat(0, w)
      ..setFloat(1, h)
      ..setFloat(2, _elapsed?.value ?? 0.0)
      ..setFloat(3, _intensity);

    context.canvas.drawRect(
      offset & size,
      Paint()..shader = _shader,
    );

    image.dispose();
    offscreen.dispose();
  }
}
