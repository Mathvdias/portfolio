import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import '../../theme/app_theme.dart';

const _kColors = [
  AppTheme.blue,
  AppTheme.mauve,
  AppTheme.teal,
  AppTheme.green,
  AppTheme.peach,
];

class _Particle {
  final double x;
  final double phase;
  final double speed;
  final int size;
  final Color color;

  const _Particle({
    required this.x,
    required this.phase,
    required this.speed,
    required this.size,
    required this.color,
  });
}

class PixelWallpaper extends StatefulWidget {
  const PixelWallpaper({super.key});

  @override
  State<PixelWallpaper> createState() => _PixelWallpaperState();
}

class _PixelWallpaperState extends State<PixelWallpaper>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  late final ValueNotifier<double> _elapsed;
  late final ValueNotifier<Offset> _mousePos;
  Duration _lastElapsed = Duration.zero;
  final _particles = <_Particle>[];
  ui.FragmentShader? _shader;

  @override
  void initState() {
    super.initState();
    _elapsed = ValueNotifier(0.0);
    _mousePos = ValueNotifier(const Offset(-1000, -1000));
    _buildParticles();
    _loadShader();
    _ticker = createTicker((elapsed) {
      final dt = (elapsed - _lastElapsed).inMicroseconds / 1e6;
      _lastElapsed = elapsed;
      _elapsed.value += dt;
    });
    _ticker.start();
  }

  void _buildParticles() {
    final rng = math.Random(42);
    for (int i = 0; i < 70; i++) {
      _particles.add(
        _Particle(
          x: rng.nextDouble(),
          phase: rng.nextDouble(),
          speed: 0.012 + rng.nextDouble() * 0.025,
          size: rng.nextInt(3) + 1,
          color: _kColors[rng.nextInt(_kColors.length)].withValues(
            alpha: 0.15 + rng.nextDouble() * 0.3,
          ),
        ),
      );
    }
  }

  Future<void> _loadShader() async {
    try {
      final program = await ui.FragmentProgram.fromAsset(
        'shaders/wallpaper.frag',
      );
      if (mounted) setState(() => _shader = program.fragmentShader());
    } catch (_) {
      // Shader unavailable — CPU fallback stays active.
    }
  }

  @override
  void dispose() {
    _elapsed.dispose();
    _mousePos.dispose();
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onHover: (event) => _mousePos.value = event.localPosition,
      onExit: (_) => _mousePos.value = const Offset(-1000, -1000),
      child: RepaintBoundary(
        child: CustomPaint(
          painter: _WallpaperPainter(_particles, _elapsed, _shader, _mousePos),
          child: const SizedBox.expand(),
        ),
      ),
    );
  }
}

class _WallpaperPainter extends CustomPainter {
  _WallpaperPainter(
    this._particles,
    this._elapsed,
    this._shader,
    this._mousePos,
  ) : super(repaint: _elapsed);

  final List<_Particle> _particles;
  final ValueNotifier<double> _elapsed;
  final ui.FragmentShader? _shader;
  final ValueNotifier<Offset> _mousePos;

  // Single Paint reused for both GPU and CPU paths — no per-frame allocations.
  final _paint = Paint();

  @override
  void paint(Canvas canvas, Size size) {
    final shader = _shader;
    final mouse = _mousePos.value;
    if (shader != null) {
      shader.setFloat(0, _elapsed.value);
      shader.setFloat(1, size.width);
      shader.setFloat(2, size.height);
      shader.setFloat(3, mouse.dx);
      shader.setFloat(4, mouse.dy);
      _paint.shader = shader;
      canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), _paint);
    } else {
      _paint.shader = null;
      final elapsed = _elapsed.value;
      const radius = 100.0;
      const maxPush = 40.0;

      for (final p in _particles) {
        final baseDirY = ((p.phase + elapsed * p.speed) % 1.0) * size.height;
        final baseDirX = p.x * size.width;

        double x = baseDirX;
        double y = baseDirY;

        // Repulsion logic
        final dx = x - mouse.dx;
        final dy = y - mouse.dy;
        final dist = math.sqrt(dx * dx + dy * dy) + 0.0001;

        if (dist < radius) {
          final force = 1.0 - (dist / radius);
          final smoothForce = force * force * (3.0 - 2.0 * force);
          x += (dx / dist) * smoothForce * maxPush;
          y += (dy / dist) * smoothForce * maxPush;
        }

        _paint.color = p.color;
        canvas.drawRect(
          Rect.fromLTWH(x, y, p.size.toDouble(), p.size.toDouble()),
          _paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(_WallpaperPainter old) =>
      old._shader != _shader || old._mousePos != _mousePos;
}
