import 'package:flutter/material.dart';

const List<List<int>> kPersonPixels = [
  [0, 0, 0, 1, 1, 0, 0, 0],
  [0, 0, 0, 1, 1, 0, 0, 0],
  [0, 0, 1, 1, 1, 1, 0, 0],
  [0, 1, 1, 1, 1, 1, 1, 0],
  [0, 1, 1, 1, 1, 1, 1, 0],
  [0, 0, 0, 1, 1, 0, 0, 0],
  [0, 0, 1, 0, 0, 1, 0, 0],
  [0, 0, 1, 0, 0, 1, 0, 0],
];

const List<List<int>> kTerminalPixels = [
  [1, 1, 1, 1, 1, 1, 1, 1],
  [1, 0, 0, 0, 0, 0, 0, 1],
  [1, 0, 1, 0, 0, 0, 0, 1],
  [1, 0, 1, 1, 1, 0, 0, 1],
  [1, 0, 1, 0, 0, 0, 0, 1],
  [1, 0, 0, 0, 1, 1, 1, 1],
  [1, 0, 0, 0, 0, 0, 0, 1],
  [1, 1, 1, 1, 1, 1, 1, 1],
];

const List<List<int>> kBankPixels = [
  [0, 0, 0, 1, 1, 0, 0, 0],
  [0, 0, 1, 1, 1, 1, 0, 0],
  [0, 1, 0, 1, 1, 0, 1, 0],
  [1, 1, 1, 1, 1, 1, 1, 1],
  [0, 1, 0, 0, 0, 0, 1, 0],
  [0, 1, 0, 0, 0, 0, 1, 0],
  [1, 1, 1, 1, 1, 1, 1, 1],
  [0, 0, 0, 0, 0, 0, 0, 0],
];

const List<List<int>> kCircuitPixels = [
  [1, 0, 1, 0, 1, 0, 1, 0],
  [1, 0, 1, 0, 1, 0, 1, 0],
  [1, 1, 0, 0, 0, 0, 1, 1],
  [0, 0, 0, 1, 1, 0, 0, 0],
  [0, 0, 0, 1, 1, 0, 0, 0],
  [1, 1, 0, 0, 0, 0, 1, 1],
  [1, 0, 1, 0, 1, 0, 1, 0],
  [1, 0, 1, 0, 1, 0, 1, 0],
];

const List<List<int>> kPackagePixels = [
  [0, 0, 1, 1, 1, 1, 0, 0],
  [0, 1, 0, 0, 0, 0, 1, 0],
  [0, 1, 0, 1, 1, 0, 1, 0],
  [0, 1, 0, 0, 0, 0, 1, 0],
  [0, 0, 1, 1, 1, 1, 0, 0],
  [0, 0, 0, 1, 1, 0, 0, 0],
  [0, 0, 0, 1, 1, 0, 0, 0],
  [0, 0, 0, 0, 0, 0, 0, 0],
];

const List<List<int>> kGithubPixels = [
  [0, 0, 1, 1, 1, 1, 0, 0],
  [0, 1, 1, 0, 0, 1, 1, 0],
  [1, 1, 0, 1, 1, 0, 1, 1],
  [1, 1, 0, 0, 0, 0, 1, 1],
  [0, 1, 1, 1, 1, 1, 1, 0],
  [0, 0, 1, 0, 0, 1, 0, 0],
  [0, 0, 1, 0, 0, 1, 0, 0],
  [0, 0, 1, 1, 1, 1, 0, 0],
];

const List<List<int>> kLinkPixels = [
  [0, 0, 0, 1, 1, 0, 0, 0],
  [0, 0, 1, 1, 1, 1, 0, 0],
  [0, 1, 1, 0, 0, 1, 1, 0],
  [1, 1, 0, 1, 1, 0, 1, 1],
  [1, 1, 0, 1, 1, 0, 1, 1],
  [0, 1, 1, 0, 0, 1, 1, 0],
  [0, 0, 1, 1, 1, 1, 0, 0],
  [0, 0, 0, 1, 1, 0, 0, 0],
];

const List<List<int>> kMailPixels = [
  [1, 1, 1, 1, 1, 1, 1, 1],
  [1, 1, 0, 0, 0, 0, 1, 1],
  [1, 0, 1, 0, 0, 1, 0, 1],
  [1, 0, 0, 1, 1, 0, 0, 1],
  [1, 0, 0, 0, 0, 0, 0, 1],
  [1, 0, 0, 0, 0, 0, 0, 1],
  [1, 0, 0, 0, 0, 0, 0, 1],
  [1, 1, 1, 1, 1, 1, 1, 1],
];

class PixelIconPainter extends CustomPainter {
  final List<List<int>> pixels;
  final Color color;

  const PixelIconPainter({required this.pixels, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    if (pixels.isEmpty) return;
    final rows = pixels.length;
    final cols = pixels[0].length;
    final cellW = size.width / cols;
    final cellH = size.height / rows;
    final paint = Paint()..color = color;

    for (int r = 0; r < rows; r++) {
      for (int c = 0; c < cols; c++) {
        if (pixels[r][c] == 1) {
          canvas.drawRect(
            Rect.fromLTWH(c * cellW, r * cellH, cellW, cellH),
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
