import 'package:app_window/app_window.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('WindowEntry', () {
    test('stores all properties correctly', () {
      const content = Text('hello');
      final entry = WindowEntry(
        id: 'test-id',
        title: 'My Window',
        content: content,
        accentColor: Colors.blue,
        position: const Offset(100, 200),
      );

      expect(entry.id, 'test-id');
      expect(entry.title, 'My Window');
      expect(entry.content, content);
      expect(entry.accentColor, Colors.blue);
      expect(entry.position, const Offset(100, 200));
    });
  });

  group('AppWindow widget', () {
    testWidgets('renders title text', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Stack(
              children: [
                AppWindow(
                  title: 'Hello World',
                  initialPosition: Offset.zero,
                  onClose: () {},
                  onFocus: () {},
                  child: const SizedBox(),
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Hello World'), findsOneWidget);
    });

    testWidgets('close button fires onClose', (tester) async {
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
                  child: const SizedBox(),
                ),
              ],
            ),
          ),
        ),
      );

      // Wait for entrance animation to finish
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('close_button')));

      // Wait for exit animation to finish
      await tester.pumpAndSettle();

      expect(closed, isTrue);
    });

    testWidgets('renders child content', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Stack(
              children: [
                AppWindow(
                  title: 'Win',
                  initialPosition: Offset.zero,
                  onClose: () {},
                  onFocus: () {},
                  child: const Text('Child Content'),
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Child Content'), findsOneWidget);
    });

    testWidgets('startMaximized fills the desktop and the button restores it', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Stack(
              children: [
                AppWindow(
                  title: 'Studio',
                  initialPosition: const Offset(60, 90),
                  width: 760,
                  height: 680,
                  maximizeTopOffset: 28,
                  maximizeBottomOffset: 80,
                  startMaximized: true,
                  onClose: () {},
                  onFocus: () {},
                  child: const SizedBox.expand(),
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final frame = find.descendant(
        of: find.byType(AppWindow),
        matching: find.byType(AnimatedContainer),
      );
      expect(tester.getTopLeft(frame.first), const Offset(0, 28));
      expect(tester.getSize(frame.first), const Size(1200, 800 - 28 - 80));

      // A maximized window follows the viewport.
      tester.view.physicalSize = const Size(900, 700);
      await tester.pumpAndSettle();
      expect(tester.getSize(frame.first), const Size(900, 700 - 28 - 80));
    });
  });
}
