import 'package:app_window/app_window.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('AppWindow renders title', (tester) async {
    bool closed = false;
    bool focused = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Stack(
            children: [
              AppWindow(
                title: 'Test Window',
                initialPosition: Offset.zero,
                onClose: () => closed = true,
                onFocus: () => focused = true,
                child: const Text('content'),
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Test Window'), findsOneWidget);
    expect(closed, isFalse);
    expect(focused, isFalse);
  });

  testWidgets('AppWindow close button calls onClose', (tester) async {
    bool closed = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Stack(
            children: [
              AppWindow(
                title: 'Win',
                initialPosition: Offset.zero,
                onClose: () {
                  closed = true;
                },
                onFocus: () {},
                child: const Text('x'),
              ),
            ],
          ),
        ),
      ),
    );

    // Wait for entry animations
    await tester.pumpAndSettle();

    // Find and tap the close button
    final closeButton = find.byKey(const Key('close_button'));
    expect(closeButton, findsOneWidget);

    await tester.tap(closeButton);

    // Wait for exit animation (300ms)
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pumpAndSettle();

    expect(closed, isTrue);
  });

  testWidgets('AppWindow updates position on pan update', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Stack(
            children: [
              AppWindow(
                title: 'Drag Test',
                initialPosition: const Offset(10, 10),
                onClose: () {},
                onFocus: () {},
                child: const Text('content'),
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final windowFinder = find.byType(AppWindow);
    final RenderBox box = tester.renderObject(windowFinder);
    final Offset initialOffset = box.localToGlobal(Offset.zero);

    // The title bar is at the top. We drag from the center of the title bar.
    // Title bar height is 32.0 by default.
    final Offset dragStart = Offset(
      initialOffset.dx + box.size.width / 2,
      initialOffset.dy + 16,
    );

    await tester.drag(
      find.text('Drag Test'), 
      const Offset(50, 50),
    );
    
    // If drag doesn't work on text, try dragging the widget area
    // Use a more direct gesture if needed, but let's try pumping first
    await tester.pump();

    final RenderBox boxAfter = tester.renderObject(windowFinder);
    final Offset finalOffset = boxAfter.localToGlobal(Offset.zero);

    expect(finalOffset, isNot(equals(initialOffset)));
  });
}
