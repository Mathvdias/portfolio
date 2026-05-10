import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import '../theme/app_theme.dart';

const _kColors = [
  AppTheme.blue,
  AppTheme.mauve,
  AppTheme.teal,
  AppTheme.green,
  AppTheme.peach,
];

class _Particle {
  final double x; // 0.0–1.0 horizontal start
  final double phase; // 0.0–1.0 vertical phase offset
  final double speed; // vertical drift speed (units/sec)
  final int size; // pixel size (1 or 2)
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
  double _elapsed = 0;
  Duration _lastElapsed = Duration.zero;
  final _particles = <_Particle>[];

  @override
  void initState() {
    super.initState();
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
    _ticker = createTicker((elapsed) {
      final dt = (elapsed - _lastElapsed).inMicroseconds / 1e6;
      _lastElapsed = elapsed;
      setState(() => _elapsed += dt);
    });
    _ticker.start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: CustomPaint(
        painter: _WallpaperPainter(_particles, _elapsed),
        child: const SizedBox.expand(),
      ),
    );
  }
}

class _WallpaperPainter extends CustomPainter {
  final List<_Particle> particles;
  final double elapsed;

  const _WallpaperPainter(this.particles, this.elapsed);

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in particles) {
      final y = ((p.phase + elapsed * p.speed) % 1.0) * size.height;
      final x = p.x * size.width;
      final s = p.size.toDouble();
      canvas.drawRect(Rect.fromLTWH(x, y, s, s), Paint()..color = p.color);
    }
  }

  @override
  bool shouldRepaint(_WallpaperPainter old) => old.elapsed != elapsed;
}
