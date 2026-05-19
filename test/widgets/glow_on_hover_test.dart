import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:portifolio/shared/widgets/glow_on_hover.dart';

Widget _wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  group('GlowOnHover — constructor', () {
    test('default radius is 16', () {
      const w = GlowOnHover(color: Colors.blue, child: SizedBox());
      expect(w.radius, 16.0);
    });

    test('default intensity is 0.85', () {
      const w = GlowOnHover(color: Colors.blue, child: SizedBox());
      expect(w.intensity, 0.85);
    });

    test('default duration is 250 ms', () {
      const w = GlowOnHover(color: Colors.blue, child: SizedBox());
      expect(w.duration, const Duration(milliseconds: 250));
    });
  });

  group('GlowOnHover — widget', () {
    testWidgets('renders child without throwing', (tester) async {
      await tester.pumpWidget(_wrap(
        const GlowOnHover(color: Colors.teal, child: Text('hi')),
      ));
      expect(find.text('hi'), findsOneWidget);
    });

    testWidgets('wraps child in MouseRegion', (tester) async {
      await tester.pumpWidget(_wrap(
        const GlowOnHover(
            color: Colors.teal, child: SizedBox(width: 48, height: 48)),
      ));
      expect(find.byType(MouseRegion), findsWidgets);
    });

    testWidgets('does not throw on pointer enter/exit', (tester) async {
      await tester.pumpWidget(_wrap(
        const GlowOnHover(
            color: Colors.teal, child: SizedBox(width: 48, height: 48)),
      ));
      final gesture =
          await tester.createGesture(kind: PointerDeviceKind.mouse);
      await gesture.moveTo(tester.getCenter(find.byType(GlowOnHover)));
      await tester.pump();
      await gesture.moveTo(Offset.zero);
      await tester.pump();
      expect(tester.takeException(), isNull);
    });

    testWidgets('animation completes without error', (tester) async {
      await tester.pumpWidget(_wrap(
        const GlowOnHover(
            color: Colors.teal, child: SizedBox(width: 48, height: 48)),
      ));
      final gesture =
          await tester.createGesture(kind: PointerDeviceKind.mouse);
      await gesture.moveTo(tester.getCenter(find.byType(GlowOnHover)));
      await tester.pumpAndSettle();
      await gesture.moveTo(Offset.zero);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });

    testWidgets('accepts custom radius and intensity', (tester) async {
      await tester.pumpWidget(_wrap(
        const GlowOnHover(
          color: Colors.amber,
          radius: 24.0,
          intensity: 0.5,
          child: SizedBox(width: 48, height: 48),
        ),
      ));
      expect(tester.takeException(), isNull);
    });
  });
}
