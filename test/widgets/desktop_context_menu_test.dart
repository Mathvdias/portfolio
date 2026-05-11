import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:portifolio/shared/widgets/desktop_context_menu.dart';
import 'package:portifolio/shared/constants/app_strings.dart';

void main() {
  group('DesktopContextMenu', () {
    Widget buildMenu({
      ValueChanged<DesktopContextAction>? onAction,
      VoidCallback? onDismiss,
    }) {
      return MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 800,
            height: 600,
            child: Stack(
              children: [
                DesktopContextMenu(
                  position: const Offset(10, 10),
                  onAction: onAction ?? (_) {},
                  onDismiss: onDismiss ?? () {},
                ),
              ],
            ),
          ),
        ),
      );
    }

    testWidgets('renders all menu items', (tester) async {
      await tester.pumpWidget(buildMenu());

      expect(find.text(AppStrings.ctxNewNote), findsOneWidget);
      expect(find.text(AppStrings.ctxOpenTerminal), findsOneWidget);
      expect(find.text(AppStrings.ctxAbout), findsOneWidget);
      expect(find.text(AppStrings.ctxSpotlight), findsOneWidget);
    });

    testWidgets('tapping a menu item calls onAction', (tester) async {
      DesktopContextAction? received;
      await tester.pumpWidget(
        buildMenu(onAction: (action) => received = action),
      );

      await tester.tap(find.text(AppStrings.ctxOpenTerminal));
      expect(received, DesktopContextAction.openTerminal);
    });

    testWidgets('tapping background calls onDismiss', (tester) async {
      bool dismissed = false;
      await tester.pumpWidget(buildMenu(onDismiss: () => dismissed = true));

      // Tap outside the menu card in the bottom-right corner
      await tester.tapAt(const Offset(780, 580));
      expect(dismissed, isTrue);
    });

    testWidgets('hovering a menu item highlights it', (tester) async {
      await tester.pumpWidget(buildMenu());

      final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await gesture.addPointer(location: Offset.zero);
      addTearDown(gesture.removePointer);

      await gesture.moveTo(tester.getCenter(find.text(AppStrings.ctxAbout)));
      await tester.pump();

      await gesture.moveTo(Offset.zero);
      await tester.pump();

      expect(find.text(AppStrings.ctxAbout), findsOneWidget);
    });
  });
}
