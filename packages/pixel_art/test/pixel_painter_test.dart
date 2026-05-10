import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pixel_art/pixel_art.dart';

void main() {
  group('PixelIconPainter', () {
    test('shouldRepaint returns false when same inputs', () {
      const painter = PixelIconPainter(pixels: kPersonPixels, color: Colors.blue);
      const same = PixelIconPainter(pixels: kPersonPixels, color: Colors.blue);
      expect(painter.shouldRepaint(same), isFalse);
    });

    test('shouldRepaint returns true when color changes', () {
      const painter = PixelIconPainter(pixels: kPersonPixels, color: Colors.blue);
      const other = PixelIconPainter(pixels: kPersonPixels, color: Colors.red);
      expect(painter.shouldRepaint(other), isTrue);
    });

    test('shouldRepaint returns true when pixels change', () {
      const painter = PixelIconPainter(pixels: kPersonPixels, color: Colors.blue);
      const other = PixelIconPainter(pixels: kTerminalPixels, color: Colors.blue);
      expect(painter.shouldRepaint(other), isTrue);
    });

    testWidgets('renders without errors', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 48,
              height: 48,
              child: CustomPaint(
                painter: PixelIconPainter(
                  pixels: kPersonPixels,
                  color: Colors.blue,
                ),
              ),
            ),
          ),
        ),
      );
      expect(tester.takeException(), isNull);
    });

    test('all 19 pattern constants have 16 rows', () {
      final patterns = [
        kPersonPixels,
        kTerminalPixels,
        kBankPixels,
        kConecthusPixels,
        kZallpyPixels,
        kOiPixels,
        kMarianaPixels,
        kShieldPixels,
        kDartPixels,
        kGithubPixels,
        kLinkPixels,
        kMailPixels,
        kMediumPixels,
        kSnakePixels,
        kSkillsPixels,
        kCalculatorPixels,
        kFinderPixels,
        kLinkedInPixels,
        kAndroidPixels,
      ];
      for (final p in patterns) {
        expect(p.length, 16, reason: '${p.runtimeType} should have 16 rows');
        for (final row in p) {
          expect(row.length, 16, reason: 'Each row should have 16 cols');
        }
      }
    });
  });
}
