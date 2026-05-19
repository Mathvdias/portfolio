import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../core/bootstrap/shader_registry.dart';

/// Fullscreen CRT scanline + vignette overlay.
///
/// Drawn as a pure transparent black quad on top of the desktop — no
/// per-frame image capture, no GPU readback.  The shader computes scanline
/// bands, radial vignette, and a slow brightness flicker entirely from
/// screen-space coordinates, making it very cheap even on low-end devices.
///
/// [intensity] controls the effect strength (0.0 = invisible, 1.0 = strong).
class CrtOverlay extends StatefulWidget {
  const CrtOverlay({super.key, this.intensity = 0.35});

  final double intensity;

  @override
  State<CrtOverlay> createState() => _CrtOverlayState();
}

class _CrtOverlayState extends State<CrtOverlay>
    with SingleTickerProviderStateMixin {
  ui.FragmentShader? _shader;
  late final Ticker _ticker;
  final ValueNotifier<double> _elapsed = ValueNotifier(0.0);
  Duration _lastTick = Duration.zero;

  @override
  void initState() {
    super.initState();
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
      final program = await ShaderRegistry.get('shaders/crt.frag');
      if (mounted) setState(() => _shader = program.fragmentShader());
    } catch (_) {
      // Shader unavailable — overlay is invisible (graceful).
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
    final shader = _shader;
    if (shader == null) return const SizedBox.expand();

    return IgnorePointer(
      child: ValueListenableBuilder<double>(
        valueListenable: _elapsed,
        builder: (context, elapsed, _) => CustomPaint(
          painter: _CrtPainter(
            shader: shader,
            elapsed: elapsed,
            intensity: widget.intensity,
          ),
          child: const SizedBox.expand(),
        ),
      ),
    );
  }
}

class _CrtPainter extends CustomPainter {
  const _CrtPainter({
    required this.shader,
    required this.elapsed,
    required this.intensity,
  });

  final ui.FragmentShader shader;
  final double elapsed;
  final double intensity;

  @override
  void paint(Canvas canvas, Size size) {
    shader
      ..setFloat(0, size.width)
      ..setFloat(1, size.height)
      ..setFloat(2, elapsed)
      ..setFloat(3, intensity);
    canvas.drawRect(Offset.zero & size, Paint()..shader = shader);
  }

  @override
  bool shouldRepaint(_CrtPainter old) =>
      old.elapsed != elapsed || old.intensity != intensity;
}
