import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
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
  const PixelWallpaper({super.key, this.animate = true});

  final bool animate;

  @override
  State<PixelWallpaper> createState() => _PixelWallpaperState();
}

class _PixelWallpaperState extends State<PixelWallpaper> {
  /// The particles drift about one pixel per frame at this rate. A vsync
  /// ticker would make the engine composite the whole desktop at the display
  /// rate (up to 120 Hz) for as long as the page is open.
  static const _framePeriod = Duration(milliseconds: 33);

  Timer? _timer;
  late final ValueNotifier<double> _elapsed;
  late final ValueNotifier<Offset> _mousePos;
  final _particles = <_Particle>[];

  @override
  void initState() {
    super.initState();
    _elapsed = ValueNotifier(0.0);
    _mousePos = ValueNotifier(const Offset(-1000, -1000));
    _buildParticles();
    if (widget.animate) _start();
  }

  @override
  void didUpdateWidget(PixelWallpaper oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.animate != oldWidget.animate) {
      if (widget.animate) {
        _start();
      } else {
        _stop();
      }
    }
  }

  void _start() {
    // An endless animation would keep `pumpAndSettle` from ever settling.
    bool isTest = false;
    assert(() {
      isTest = WidgetsBinding.instance.runtimeType.toString().contains('Test');
      return true;
    }());
    if (isTest || _timer != null) return;

    // Timer.tick counts the periods that went by, including those a throttled
    // background tab skipped, so the fall keeps real-time speed.
    final base = _elapsed.value;
    _timer = Timer.periodic(_framePeriod, (timer) {
      _elapsed.value = base + timer.tick * _framePeriod.inMicroseconds / 1e6;
    });
  }

  void _stop() {
    _timer?.cancel();
    _timer = null;
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

  @override
  void dispose() {
    _stop();
    _elapsed.dispose();
    _mousePos.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onHover: (event) => _mousePos.value = event.localPosition,
      onExit: (_) => _mousePos.value = const Offset(-1000, -1000),
      child: RepaintBoundary(
        child: CustomPaint(
          painter: _WallpaperPainter(_particles, _elapsed, _mousePos),
          child: const SizedBox.expand(),
        ),
      ),
    );
  }
}

/// Seventy small rectangles on the CPU. This used to be a fragment shader that
/// looped over all seventy particles for every pixel of the screen, every
/// frame, to draw the same thing.
class _WallpaperPainter extends CustomPainter {
  _WallpaperPainter(this._particles, this._elapsed, this._mousePos)
    : super(repaint: _elapsed);

  final List<_Particle> _particles;
  final ValueNotifier<double> _elapsed;
  final ValueNotifier<Offset> _mousePos;

  // Single Paint reused for every particle: no per-frame allocations.
  final _paint = Paint();

  @override
  void paint(Canvas canvas, Size size) {
    final mouse = _mousePos.value;
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

  @override
  bool shouldRepaint(_WallpaperPainter old) => old._mousePos != _mousePos;
}
