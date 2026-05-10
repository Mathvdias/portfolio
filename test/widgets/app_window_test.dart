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
                onClose: () => closed = true,
                onFocus: () {},
                child: const Text('x'),
              ),
            ],
          ),
        ),
      ),
    );
    await tester.tap(find.byKey(const Key('close_button')));
    await tester.pump();
    expect(closed, isTrue);
  });
}
