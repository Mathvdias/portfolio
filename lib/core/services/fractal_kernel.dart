import 'dart:math' as math;
import 'dart:typed_data';

/// Line-by-line Dart port of `generate_fractal` in packages/mathos_engine
/// (same shortcuts, same colouring), so timing both is a like-for-like
/// comparison between Rust → WASM and whatever this app was compiled to.
///
/// Writes `width * height` RGBA pixels at the start of [buffer].
void renderFractalDart({
  required Uint8List buffer,
  required int width,
  required int height,
  required double zoom,
  required double offsetX,
  required double offsetY,
  required int maxIterations,
  bool isJulia = false,
  double cxJulia = 0.0,
  double cyJulia = 0.0,
  double time = 0.0,
}) {
  if (width <= 0 || height <= 0) return;
  assert(buffer.length >= width * height * 4);

  final w = width.toDouble();
  final h = height.toDouble();
  final aspect = w / h;
  final stepX = 4.0 * aspect / (w * zoom);
  final stepY = 4.0 / (h * zoom);
  final halfW = w / 2.0;
  final halfH = h / 2.0;
  final invLn2 = 1.0 / math.ln2;
  final hueShift = time * 0.1;

  for (var y = 0; y < height; y++) {
    final py = (y - halfH) * stepY + offsetY;
    final row = y * width * 4;
    for (var x = 0; x < width; x++) {
      final px = (x - halfW) * stepX + offsetX;
      final idx = row + x * 4;

      var zx = isJulia ? px : 0.0;
      var zy = isJulia ? py : 0.0;
      final cx = isJulia ? cxJulia : px;
      final cy = isJulia ? cyJulia : py;

      // Main cardioid and period-2 bulb never escape.
      var inside = false;
      if (!isJulia) {
        final xq = cx - 0.25;
        final q = xq * xq + cy * cy;
        inside =
            q * (q + xq) <= 0.25 * cy * cy ||
            (cx + 1.0) * (cx + 1.0) + cy * cy <= 0.0625;
      }

      var iteration = 0;
      var zx2 = zx * zx;
      var zy2 = zy * zy;

      if (!inside) {
        // Periodicity check (Brent), as in the Rust kernel.
        var ox = zx;
        var oy = zy;
        var lap = 0;
        var lapLen = 8;
        while (zx2 + zy2 <= 100.0 && iteration < maxIterations) {
          zy = 2.0 * zx * zy + cy;
          zx = zx2 - zy2 + cx;
          zx2 = zx * zx;
          zy2 = zy * zy;
          iteration++;
          if (zx == ox && zy == oy) {
            iteration = maxIterations;
            break;
          }
          lap++;
          if (lap == lapLen) {
            ox = zx;
            oy = zy;
            lap = 0;
            lapLen += lapLen;
          }
        }
      }

      if (inside || iteration == maxIterations) {
        buffer[idx] = 0;
        buffer[idx + 1] = 0;
        buffer[idx + 2] = 0;
        buffer[idx + 3] = 255;
      } else {
        // Smooth coloring
        final logZn = math.log(zx2 + zy2) / 2.0;
        final nu = math.log(logZn * invLn2) * invLn2;
        final smoothIter = iteration + 1.0 - nu;

        final hue = (smoothIter * 0.05 + hueShift).remainder(1.0);
        final h6 = hue * 6.0;
        final i = h6.floor();
        final f = h6 - i;
        const v = 0.9;
        const s = 0.7;
        const p = v * (1.0 - s);
        final q = v * (1.0 - f * s);
        final t = v * (1.0 - (1.0 - f) * s);

        final double r, g, b;
        switch (i % 6) {
          case 0:
            r = v;
            g = t;
            b = p;
          case 1:
            r = q;
            g = v;
            b = p;
          case 2:
            r = p;
            g = v;
            b = t;
          case 3:
            r = p;
            g = q;
            b = v;
          case 4:
            r = t;
            g = p;
            b = v;
          default:
            r = v;
            g = p;
            b = q;
        }

        buffer[idx] = (r * 255.0).toInt();
        buffer[idx + 1] = (g * 255.0).toInt();
        buffer[idx + 2] = (b * 255.0).toInt();
        buffer[idx + 3] = 255;
      }
    }
  }
}
