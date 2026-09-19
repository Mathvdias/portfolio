import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:portifolio/shared/widgets/fractal_explorer_content.dart';

void main() {
  group('fractalRenderSize', () {
    test('keeps the aspect ratio of the view', () {
      final (w, h) = fractalRenderSize(
        viewSize: const Size(1600, 800),
        pixelRatio: 2,
        pixelBudget: 120000,
      );
      expect(w / h, closeTo(2.0, 0.02));
      expect(w * h, closeTo(120000, 2000));
    });

    test('full quality is capped by the engine buffer in both dimensions', () {
      final (w, h) = fractalRenderSize(
        viewSize: const Size(1600, 800),
        pixelRatio: 2,
        pixelBudget: double.infinity,
      );
      expect(w, lessThanOrEqualTo(800));
      expect(h, lessThanOrEqualTo(600));
      expect(w / h, closeTo(2.0, 0.02));
    });

    test('never renders more than the widget can show', () {
      final (w, h) = fractalRenderSize(
        viewSize: const Size(300, 200),
        pixelRatio: 1,
        pixelBudget: double.infinity,
      );
      expect(w * h, lessThanOrEqualTo(300 * 200 + 600));
    });

    test('never drops below the floor, whatever the budget says', () {
      final (w, h) = fractalRenderSize(
        viewSize: const Size(900, 600),
        pixelRatio: 2,
        pixelBudget: 10,
      );
      expect(w * h, greaterThanOrEqualTo(240 * 180 - 600));
    });

    test('extreme aspect ratios stay inside the buffer', () {
      for (final size in const [Size(2000, 200), Size(200, 2000)]) {
        final (w, h) = fractalRenderSize(
          viewSize: size,
          pixelRatio: 2,
          pixelBudget: double.infinity,
        );
        expect(w, inInclusiveRange(16, 800));
        expect(h, inInclusiveRange(16, 600));
      }
    });
  });
}
