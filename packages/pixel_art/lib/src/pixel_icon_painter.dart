import 'package:flutter/material.dart';

class PixelIconPainter extends CustomPainter {
  const PixelIconPainter({required this.pixels, required this.color});

  final List<List<int>> pixels;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (pixels.isEmpty) return;
    final rows = pixels.length;
    final cols = pixels[0].length;
    final cellW = size.width / cols;
    final cellH = size.height / rows;
    final gap = cellW * 0.1; // subtle gap between pixels
    final radius = Radius.circular(cellW * 0.2);
    final paint =
        Paint()
          ..color = color
          ..isAntiAlias = true;

    for (int r = 0; r < rows; r++) {
      for (int c = 0; c < cols; c++) {
        if (pixels[r][c] == 1) {
          canvas.drawRRect(
            RRect.fromRectAndRadius(
              Rect.fromLTWH(
                c * cellW + gap,
                r * cellH + gap,
                cellW - gap * 2,
                cellH - gap * 2,
              ),
              radius,
            ),
            paint,
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(PixelIconPainter oldDelegate) =>
      oldDelegate.pixels != pixels || oldDelegate.color != color;
}
