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
  // Mouse position in logical pixels; Offset(-1,-1) when off-screen.
  final ValueNotifier<Offset> _mouse = ValueNotifier(const Offset(-1, -1));
  Duration _lastElapsed = Duration.zero;
  final _particles = <_Particle>[];
  ui.FragmentShader? _shader;

  @override
  void initState() {
    super.initState();
    _elapsed = ValueNotifier(0.0);
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
    _mouse.dispose();
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onHover: (event) => _mouse.value = event.localPosition,
      onExit: (_) => _mouse.value = const Offset(-1, -1),
      child: RepaintBoundary(
        child: CustomPaint(
          painter: _WallpaperPainter(_particles, _elapsed, _mouse, _shader),
          child: const SizedBox.expand(),
        ),
      ),
    );
  }
}

class _WallpaperPainter extends CustomPainter {
  _WallpaperPainter(
      this._particles, this._elapsed, this._mouse, this._shader)
      : super(repaint: Listenable.merge([_elapsed, _mouse]));

  final List<_Particle> _particles;
  final ValueNotifier<double> _elapsed;
  final ValueNotifier<Offset> _mouse;
  final ui.FragmentShader? _shader;

  // Single Paint reused for both GPU and CPU paths — no per-frame allocations.
  final _paint = Paint();

  @override
  void paint(Canvas canvas, Size size) {
    final shader = _shader;
    final mouse = _mouse.value;
    if (shader != null) {
      shader
        ..setFloat(0, _elapsed.value)
        ..setFloat(1, size.width)
        ..setFloat(2, size.height)
        ..setFloat(3, mouse.dx)
        ..setFloat(4, mouse.dy);
      _paint.shader = shader;
      canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), _paint);
    } else {
      _paint.shader = null;
      final elapsed = _elapsed.value;
      for (final p in _particles) {
        final y = ((p.phase + elapsed * p.speed) % 1.0) * size.height;
        final x = p.x * size.width;
        _paint.color = p.color;
        canvas.drawRect(
          Rect.fromLTWH(x, y, p.size.toDouble(), p.size.toDouble()),
          _paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(_WallpaperPainter old) => old._shader != _shader;
}
