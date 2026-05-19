import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:portifolio/shared/widgets/crt_overlay.dart';

Widget _wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  group('CrtOverlay — constructor', () {
    test('default intensity is 0.35', () {
      const w = CrtOverlay();
      expect(w.intensity, 0.35);
    });
  });

  group('CrtOverlay — widget', () {
    testWidgets('renders without throwing', (tester) async {
      await tester.pumpWidget(_wrap(
        Stack(children: [
          const SizedBox.expand(),
          const Positioned.fill(child: CrtOverlay()),
        ]),
      ));
      expect(tester.takeException(), isNull);
    });

    testWidgets('is pointer-transparent (IgnorePointer wraps content)',
        (tester) async {
      await tester.pumpWidget(_wrap(
        Stack(children: [
          const SizedBox.expand(),
          const Positioned.fill(child: CrtOverlay()),
        ]),
      ));
      expect(find.byType(IgnorePointer), findsWidgets);
    });

    testWidgets('custom intensity accepted', (tester) async {
      await tester.pumpWidget(_wrap(
        Stack(children: [
          const SizedBox.expand(),
          const Positioned.fill(child: CrtOverlay(intensity: 0.8)),
        ]),
      ));
      expect(tester.takeException(), isNull);
    });

    testWidgets('zero intensity renders without error', (tester) async {
      await tester.pumpWidget(_wrap(
        Stack(children: [
          const SizedBox.expand(),
          const Positioned.fill(child: CrtOverlay(intensity: 0.0)),
        ]),
      ));
      expect(tester.takeException(), isNull);
    });
  });
}
