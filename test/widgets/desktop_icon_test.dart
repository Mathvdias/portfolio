import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:portifolio/shared/widgets/desktop_icon.dart';

void main() {
  group('DesktopIcon', () {
    testWidgets('renders label', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: DesktopIcon(
              label: 'About',
              iconAsset: 'assets/icons/person.svg',
              color: Colors.blue,
              onTap: null,
            ),
          ),
        ),
      );
      expect(find.text('About'), findsOneWidget);
    });

    testWidgets('calls onTap', (tester) async {
      bool tapped = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DesktopIcon(
              label: 'Test',
              iconAsset: 'assets/icons/person.svg',
              color: Colors.blue,
              onTap: () => tapped = true,
            ),
          ),
        ),
      );
      await tester.tap(find.byType(DesktopIcon));
      expect(tapped, isTrue);
    });

    testWidgets('changes appearance on hover enter and exit', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: DesktopIcon(
                label: 'Hover',
                iconAsset: 'assets/icons/star.svg',
                color: Colors.blue,
                onTap: null,
              ),
            ),
          ),
        ),
      );

      final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await gesture.addPointer(location: const Offset(1, 1));
      addTearDown(gesture.removePointer);
      await tester.pump();

      await gesture.moveTo(tester.getCenter(find.byType(DesktopIcon)));
      await tester.pump();

      await gesture.moveTo(const Offset(1, 1));
      await tester.pump();

      expect(find.text('Hover'), findsOneWidget);
    });
  });
}
