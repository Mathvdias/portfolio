import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:portifolio/core/constants/app_svgs.dart';
import 'package:portifolio/shared/widgets/desktop_icon.dart';

void main() {
  testWidgets('DesktopIcon renders label', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: DesktopIcon(
            label: 'About',
            iconWidgetPath: AppSvgs.person,
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
            iconWidgetPath: AppSvgs.person,
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
              iconWidgetPath: AppSvgs.flutter,
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
}
