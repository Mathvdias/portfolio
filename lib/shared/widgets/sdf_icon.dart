import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../models/sdf_shape.dart';

/// A GPU-rendered scalable icon drawn by a fragment-shader SDF.
///
/// The [FragmentProgram] is loaded once per app session (shared static
/// cache) and each instance creates its own [FragmentShader] from it, so
/// uniform writes are never aliased between widgets.
///
/// Falls back gracefully to an empty [SizedBox] in environments that do not
/// support fragment shaders (e.g. pure-Dart unit tests).
class SdfIcon extends StatefulWidget {
  const SdfIcon(
    this.shape, {
    super.key,
    this.size = 24.0,
    required this.color,
  });

  final SdfShape shape;
  final double size;
  final Color color;

  @override
  State<SdfIcon> createState() => _SdfIconState();
}

class _SdfIconState extends State<SdfIcon> {
  // One FragmentProgram shared across all SdfIcon instances.
  static ui.FragmentProgram? _program;
  static Future<ui.FragmentProgram>? _loading;

  ui.FragmentShader? _shader;

  @override
  void initState() {
    super.initState();
    _loadShader();
  }

  Future<void> _loadShader() async {
    try {
      _loading ??= ui.FragmentProgram.fromAsset('shaders/icons.frag');
      _program ??= await _loading!;
      if (mounted) setState(() => _shader = _program!.fragmentShader());
    } catch (_) {
      // Shader unavailable (e.g. test environment) — keep placeholder.
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_shader == null) return SizedBox.square(dimension: widget.size);
    return CustomPaint(
      size: Size.square(widget.size),
      painter: _SdfPainter(
        shader: _shader!,
        shape: widget.shape,
        color: widget.color,
        size: widget.size,
      ),
    );
  }
}

class _SdfPainter extends CustomPainter {
  const _SdfPainter({
    required this.shader,
    required this.shape,
    required this.color,
    required this.size,
  });

  final ui.FragmentShader shader;
  final SdfShape shape;
  final Color color;
  final double size;

  @override
  void paint(Canvas canvas, Size canvasSize) {
    // Uniforms must match the layout declared in shaders/icons.frag:
    //   0: uSize, 1: uRed, 2: uGreen, 3: uBlue, 4: uShape
    shader
      ..setFloat(0, size)
      ..setFloat(1, color.r)
      ..setFloat(2, color.g)
      ..setFloat(3, color.b)
      ..setFloat(4, shape.glslIndex.toDouble());
    canvas.drawRect(Offset.zero & canvasSize, Paint()..shader = shader);
  }

  @override
  bool shouldRepaint(_SdfPainter old) =>
      old.shape != shape || old.color != color || old.size != size;
}
