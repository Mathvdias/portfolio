import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pixel_art/pixel_art.dart';
import 'package:portifolio/shared/widgets/spotlight_overlay.dart';
import 'package:portifolio/shared/constants/app_strings.dart';
import 'package:portifolio/theme/app_theme.dart';

void main() {
  final items = [
    SpotlightItem(
      id: 'terminal',
      label: 'Terminal',
      pixels: kTerminalPixels,
      color: AppTheme.green,
    ),
    SpotlightItem(
      id: 'calculator',
      label: 'Calculator',
      pixels: kCalculatorPixels,
      color: AppTheme.peach,
    ),
    SpotlightItem(
      id: 'contact',
      label: 'Contact',
      pixels: kMailPixels,
      color: AppTheme.teal,
    ),
  ];

  group('SpotlightOverlay', () {
    testWidgets('renders search hint', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Stack(
              children: [
                SpotlightOverlay(
                  items: items,
                  onSelect: (_) {},
                  onDismiss: () {},
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text(AppStrings.spotlightHint), findsOneWidget);
    });

    testWidgets('shows all items initially', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Stack(
              children: [
                SpotlightOverlay(
                  items: items,
                  onSelect: (_) {},
                  onDismiss: () {},
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Terminal'), findsOneWidget);
      expect(find.text('Calculator'), findsOneWidget);
      expect(find.text('Contact'), findsOneWidget);
    });

    testWidgets('filters items by search text', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Stack(
              children: [
                SpotlightOverlay(
                  items: items,
                  onSelect: (_) {},
                  onDismiss: () {},
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pump();

      await tester.enterText(find.byType(TextField), 'ter');
      await tester.pump();

      expect(find.text('Terminal'), findsOneWidget);
      expect(find.text('Calculator'), findsNothing);
      expect(find.text('Contact'), findsNothing);
    });

    testWidgets('tapping an item calls onSelect', (tester) async {
      SpotlightItem? selected;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Stack(
              children: [
                SpotlightOverlay(
                  items: items,
                  onSelect: (item) => selected = item,
                  onDismiss: () {},
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pump();

      await tester.tap(find.text('Calculator'));
      expect(selected?.id, 'calculator');
    });

    testWidgets('tapping background dismisses', (tester) async {
      bool dismissed = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Stack(
              children: [
                SpotlightOverlay(
                  items: items,
                  onSelect: (_) {},
                  onDismiss: () => dismissed = true,
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pump();

      // Tap outside the spotlight card
      await tester.tapAt(const Offset(10, 10));
      expect(dismissed, isTrue);
    });
  });

  group('SpotlightItem', () {
    test('stores all fields', () {
      final item = SpotlightItem(
        id: 'test',
        label: 'Test',
        pixels: kPersonPixels,
        color: Colors.blue,
      );

      expect(item.id, 'test');
      expect(item.label, 'Test');
      expect(item.pixels, kPersonPixels);
      expect(item.color, Colors.blue);
    });
  });
}
