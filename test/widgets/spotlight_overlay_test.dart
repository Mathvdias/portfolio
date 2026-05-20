import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:portifolio/l10n/app_localizations.dart';
import 'package:portifolio/shared/widgets/spotlight_overlay.dart';
import 'package:portifolio/shared/constants/app_strings.dart';
import 'package:portifolio/theme/app_theme.dart';

Widget buildSpotlight(SpotlightOverlay overlay) => MaterialApp(
  localizationsDelegates: const [AppLocalizationsDelegate()],
  home: Scaffold(body: Stack(children: [overlay])),
);

void main() {
  final items = [
    const SpotlightItem(
      id: 'terminal',
      label: 'Terminal',
      iconWidget: Icon(Icons.terminal),
      color: AppTheme.green,
    ),
    const SpotlightItem(
      id: 'calculator',
      label: 'Calculator',
      iconWidget: Icon(Icons.calculate),
      color: AppTheme.peach,
    ),
    const SpotlightItem(
      id: 'contact',
      label: 'Contact',
      iconWidget: Icon(Icons.mail),
      color: AppTheme.teal,
    ),
  ];

  group('SpotlightOverlay', () {
    testWidgets('renders search hint', (tester) async {
      await tester.pumpWidget(
        buildSpotlight(
          SpotlightOverlay(items: items, onSelect: (_) {}, onDismiss: () {}),
        ),
      );
      await tester.pump();

      expect(find.text(AppStrings.spotlightHint), findsOneWidget);
    });

    testWidgets('shows all items initially', (tester) async {
      await tester.pumpWidget(
        buildSpotlight(
          SpotlightOverlay(items: items, onSelect: (_) {}, onDismiss: () {}),
        ),
      );
      await tester.pump();

      expect(find.text('Terminal'), findsOneWidget);
      expect(find.text('Calculator'), findsOneWidget);
      expect(find.text('Contact'), findsOneWidget);
    });

    testWidgets('filters items by search text', (tester) async {
      await tester.pumpWidget(
        buildSpotlight(
          SpotlightOverlay(items: items, onSelect: (_) {}, onDismiss: () {}),
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
        buildSpotlight(
          SpotlightOverlay(
            items: items,
            onSelect: (item) => selected = item,
            onDismiss: () {},
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
        buildSpotlight(
          SpotlightOverlay(
            items: items,
            onSelect: (_) {},
            onDismiss: () => dismissed = true,
          ),
        ),
      );
      await tester.pump();

      await tester.tapAt(const Offset(10, 10));
      expect(dismissed, isTrue);
    });

    testWidgets('escape key calls onDismiss', (tester) async {
      bool dismissed = false;
      await tester.pumpWidget(
        buildSpotlight(
          SpotlightOverlay(
            items: items,
            onSelect: (_) {},
            onDismiss: () => dismissed = true,
          ),
        ),
      );
      await tester.pump();

      await tester.sendKeyDownEvent(LogicalKeyboardKey.escape);
      await tester.pump();

      expect(dismissed, isTrue);
    });

    testWidgets('enter key calls onSelect for current item', (tester) async {
      SpotlightItem? selected;
      await tester.pumpWidget(
        buildSpotlight(
          SpotlightOverlay(
            items: items,
            onSelect: (item) => selected = item,
            onDismiss: () {},
          ),
        ),
      );
      await tester.pump();

      await tester.sendKeyDownEvent(LogicalKeyboardKey.enter);
      await tester.pump();

      expect(selected?.id, items.first.id);
    });

    testWidgets('arrow down moves selection down', (tester) async {
      SpotlightItem? selected;
      await tester.pumpWidget(
        buildSpotlight(
          SpotlightOverlay(
            items: items,
            onSelect: (item) => selected = item,
            onDismiss: () {},
          ),
        ),
      );
      await tester.pump();

      await tester.sendKeyDownEvent(LogicalKeyboardKey.arrowDown);
      await tester.pump();
      await tester.sendKeyDownEvent(LogicalKeyboardKey.enter);
      await tester.pump();

      expect(selected?.id, items[1].id);
    });

    testWidgets('arrow up moves selection up', (tester) async {
      SpotlightItem? selected;
      await tester.pumpWidget(
        buildSpotlight(
          SpotlightOverlay(
            items: items,
            onSelect: (item) => selected = item,
            onDismiss: () {},
          ),
        ),
      );
      await tester.pump();

      await tester.sendKeyDownEvent(LogicalKeyboardKey.arrowDown);
      await tester.pump();
      await tester.sendKeyDownEvent(LogicalKeyboardKey.arrowUp);
      await tester.pump();
      await tester.sendKeyDownEvent(LogicalKeyboardKey.enter);
      await tester.pump();

      expect(selected?.id, items.first.id);
    });
  });

  group('SpotlightItem', () {
    test('stores all fields', () {
      final item = const SpotlightItem(
        id: 'test',
        label: 'Test',
        iconWidget: Icon(Icons.person),
        color: Colors.blue,
      );

      expect(item.id, 'test');
      expect(item.label, 'Test');
      expect(item.iconWidget, isA<Icon>());
      expect(item.color, Colors.blue);
    });
  });
}
