import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pixel_art/pixel_art.dart';
import 'package:portifolio/shared/widgets/desktop_icon.dart';

void main() {
  testWidgets('DesktopIcon renders label', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: DesktopIcon(
            label: 'About',
            pixels: kPersonPixels,
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
            pixels: kPersonPixels,
            color: Colors.blue,
            onTap: () => tapped = true,
          ),
        ),
      ),
    );
    await tester.tap(find.byType(DesktopIcon));
    expect(tapped, isTrue);
  });
}
