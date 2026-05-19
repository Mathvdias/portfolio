import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:portifolio/shared/widgets/pixelate_on_hover.dart';

Widget _wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  group('PixelateOnHover — constructor', () {
    test('default pixelGridSize is 12', () {
      const w = PixelateOnHover(child: SizedBox());
      expect(w.pixelGridSize, 12.0);
    });

    test('default duration is 200 ms', () {
      const w = PixelateOnHover(child: SizedBox());
      expect(w.duration, const Duration(milliseconds: 200));
    });
  });

  group('PixelateOnHover — widget', () {
    testWidgets('renders child without throwing', (tester) async {
      await tester.pumpWidget(_wrap(
        const PixelateOnHover(child: Text('hello')),
      ));
      expect(find.text('hello'), findsOneWidget);
    });

    testWidgets('wraps child in MouseRegion', (tester) async {
      await tester.pumpWidget(_wrap(
        const PixelateOnHover(child: SizedBox(width: 48, height: 48)),
      ));
      expect(find.byType(MouseRegion), findsWidgets);
    });

    testWidgets('does not throw on pointer enter/exit events', (tester) async {
      await tester.pumpWidget(_wrap(
        const PixelateOnHover(child: SizedBox(width: 48, height: 48)),
      ));
      final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await gesture.moveTo(tester.getCenter(find.byType(PixelateOnHover)));
      await tester.pump();
      await gesture.moveTo(Offset.zero);
      await tester.pump();
      expect(tester.takeException(), isNull);
    });

    testWidgets('animation forward and reverse completes without error',
        (tester) async {
      await tester.pumpWidget(_wrap(
        const PixelateOnHover(child: SizedBox(width: 48, height: 48)),
      ));
      final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await gesture.moveTo(tester.getCenter(find.byType(PixelateOnHover)));
      await tester.pumpAndSettle();
      await gesture.moveTo(Offset.zero);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  });
}
