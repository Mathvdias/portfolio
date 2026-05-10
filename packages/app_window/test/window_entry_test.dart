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

      await tester.tap(find.byKey(const Key('close_button')));
      await tester.pump();

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
      expect(find.text('Child Content'), findsOneWidget);
    });
  });
}
