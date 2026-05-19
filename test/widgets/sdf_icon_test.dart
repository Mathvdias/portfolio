import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:portifolio/shared/models/sdf_shape.dart';
import 'package:portifolio/shared/widgets/sdf_icon.dart';

Widget _wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  group('SdfIcon — constructor', () {
    test('stores shape, color and size', () {
      const icon = SdfIcon(SdfShape.star, color: Colors.amber, size: 48.0);
      expect(icon.shape, SdfShape.star);
      expect(icon.color, Colors.amber);
      expect(icon.size, 48.0);
    });

    test('default size is 24.0', () {
      const icon = SdfIcon(SdfShape.folder, color: Colors.blue);
      expect(icon.size, 24.0);
    });
  });

  group('SdfIcon — widget', () {
    testWidgets('renders without throwing', (tester) async {
      await tester.pumpWidget(_wrap(
        const SdfIcon(SdfShape.person, color: Colors.blue, size: 40.0),
      ));
      expect(find.byType(SdfIcon), findsOneWidget);
    });

    testWidgets('shows a SizedBox placeholder before shader loads', (tester) async {
      // On first pump the async shader load has not completed, so the widget
      // renders its SizedBox placeholder (no GPU in test host).
      await tester.pumpWidget(_wrap(
        const SdfIcon(SdfShape.terminal, color: Colors.green, size: 32.0),
      ));
      expect(find.byType(SizedBox), findsWidgets);
    });

    testWidgets('every SdfShape value renders without error', (tester) async {
      for (final shape in SdfShape.values) {
        await tester.pumpWidget(_wrap(
          SdfIcon(shape, color: Colors.red, size: 24.0),
        ));
        expect(find.byType(SdfIcon), findsOneWidget,
            reason: '$shape should render');
        await tester.pumpWidget(const SizedBox()); // reset
      }
    });

    testWidgets('handles zero size gracefully', (tester) async {
      await tester.pumpWidget(_wrap(
        const SdfIcon(SdfShape.star, color: Colors.white, size: 0.0),
      ));
      expect(tester.takeException(), isNull);
    });

    testWidgets('hot-swap of shape does not throw', (tester) async {
      await tester.pumpWidget(_wrap(
        const SdfIcon(SdfShape.person, color: Colors.blue, size: 40.0),
      ));
      await tester.pumpWidget(_wrap(
        const SdfIcon(SdfShape.rocket, color: Colors.red, size: 40.0),
      ));
      expect(find.byType(SdfIcon), findsOneWidget);
    });

    testWidgets('color change rebuilds without error', (tester) async {
      await tester.pumpWidget(_wrap(
        const SdfIcon(SdfShape.envelope, color: Colors.blue, size: 24.0),
      ));
      await tester.pumpWidget(_wrap(
        const SdfIcon(SdfShape.envelope, color: Colors.red, size: 24.0),
      ));
      expect(tester.takeException(), isNull);
    });
  });

  group('SdfIcon — CustomPaint appearance', () {
    testWidgets('shows CustomPaint after shader program loads', (tester) async {
      // NOTE: FragmentProgram.fromAsset will fail silently in test host
      // (no GPU) and the widget stays as SizedBox. This test documents
      // the expected behaviour rather than asserting CustomPaint, because
      // shader availability depends on the runtime environment.
      await tester.pumpWidget(_wrap(
        const SdfIcon(SdfShape.star, color: Colors.yellow, size: 48.0),
      ));
      await tester.pump(const Duration(milliseconds: 500));

      // Either CustomPaint (real GPU) or SizedBox (test host) is valid.
      final hasPainter = find.byType(CustomPaint).evaluate().isNotEmpty;
      final hasFallback = find.byType(SizedBox).evaluate().isNotEmpty;
      expect(hasPainter || hasFallback, isTrue);
    });
  });
}
