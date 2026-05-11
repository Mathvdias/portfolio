import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/gestures.dart';

import 'package:portifolio/shared/widgets/desktop_icon.dart';

void main() {
  testWidgets('DesktopIcon renders label', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: DesktopIcon(
            label: 'About',
            iconWidget: Icon(Icons.person),
            color: Colors.blue,
            onTap: null,
          ),
        ),
      ),
    );
    expect(find.text('About'), findsOneWidget);
  });

  testWidgets('DesktopIcon calls onTap', (tester) async {
    bool tapped = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DesktopIcon(
            label: 'Test',
            iconWidget: const Icon(Icons.person),
            color: Colors.blue,
            onTap: () => tapped = true,
          ),
        ),
      ),
    );
    await tester.tap(find.byType(DesktopIcon));
    expect(tapped, isTrue);
  });

  testWidgets('DesktopIcon changes appearance on hover enter and exit', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(
            child: DesktopIcon(
              label: 'Hover',
              iconWidget: Icon(Icons.star),
              color: Colors.blue,
              onTap: null,
            ),
          ),
        ),
      ),
    );

    final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
    // Start pointer far from widget
    await gesture.addPointer(location: const Offset(1, 1));
    addTearDown(gesture.removePointer);
    await tester.pump();

    // Move into widget — triggers onEnter
    await gesture.moveTo(tester.getCenter(find.byType(DesktopIcon)));
    await tester.pump();

    // Move away — triggers onExit
    await gesture.moveTo(const Offset(1, 1));
    await tester.pump();

    expect(find.text('Hover'), findsOneWidget);
  });
}
