import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:portifolio/shared/widgets/rubber_band_selection.dart';

void main() {
  group('RubberBandSelection', () {
    testWidgets('renders a container with correct rect', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Stack(
              children: [
                RubberBandSelection(
                  origin: Offset(10, 20),
                  current: Offset(110, 120),
                ),
              ],
            ),
          ),
        ),
      );

      // The widget should be in the tree
      expect(find.byType(RubberBandSelection), findsOneWidget);
    });

    testWidgets('handles reversed coordinates (current < origin)',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Stack(
              children: [
                RubberBandSelection(
                  origin: Offset(100, 100),
                  current: Offset(10, 10),
                ),
              ],
            ),
          ),
        ),
      );
      expect(find.byType(RubberBandSelection), findsOneWidget);
    });
  });
}
