import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:portifolio/shared/widgets/sticky_note.dart';

void main() {
  group('StickyNote', () {
    testWidgets('renders text', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Stack(
              children: [
                StickyNote(initialPosition: Offset(10, 10), text: 'Hello Note'),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Hello Note'), findsOneWidget);
    });

    testWidgets('can be dragged', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Stack(
              children: [
                StickyNote(initialPosition: Offset(10, 10), text: 'Drag me'),
              ],
            ),
          ),
        ),
      );

      final stickyNote = find.text('Drag me');
      await tester.drag(stickyNote, const Offset(50, 30));
      await tester.pump();

      // Should still be in the tree
      expect(find.text('Drag me'), findsOneWidget);
    });
  });

  group('VisitorStickyNote', () {
    testWidgets('renders visitor count', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Stack(
              children: [
                VisitorStickyNote(
                  initialPosition: Offset(10, 10),
                  visitorCount: 42,
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.text('42'), findsOneWidget);
      expect(find.text('VISITORS'), findsOneWidget);
    });

    testWidgets('can be dragged (updates position)', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Stack(
              children: [
                VisitorStickyNote(
                  initialPosition: Offset(10, 10),
                  visitorCount: 7,
                ),
              ],
            ),
          ),
        ),
      );

      await tester.drag(find.text('7'), const Offset(50, 50));
      await tester.pump();

      expect(find.text('7'), findsOneWidget);
    });
  });
}
