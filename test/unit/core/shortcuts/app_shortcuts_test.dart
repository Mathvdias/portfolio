import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:portifolio/core/shortcuts/app_intents.dart';
import 'package:portifolio/core/shortcuts/app_shortcuts.dart';

void main() {
  group('AppShortcuts', () {
    test('map is not empty', () {
      expect(AppShortcuts.map, isNotEmpty);
    });

    test('⌘K / Ctrl+K maps to OpenSpotlightIntent', () {
      expect(
        AppShortcuts.map[const SingleActivator(
          LogicalKeyboardKey.keyK,
          meta: true,
        )],
        isA<OpenSpotlightIntent>(),
      );
      expect(
        AppShortcuts.map[const SingleActivator(
          LogicalKeyboardKey.keyK,
          control: true,
        )],
        isA<OpenSpotlightIntent>(),
      );
    });

    test('⌘W / Ctrl+W maps to CloseTopWindowIntent', () {
      expect(
        AppShortcuts.map[const SingleActivator(
          LogicalKeyboardKey.keyW,
          meta: true,
        )],
        isA<CloseTopWindowIntent>(),
      );
      expect(
        AppShortcuts.map[const SingleActivator(
          LogicalKeyboardKey.keyW,
          control: true,
        )],
        isA<CloseTopWindowIntent>(),
      );
    });

    test('Escape maps to DismissDesktopIntent', () {
      expect(
        AppShortcuts.map[const SingleActivator(LogicalKeyboardKey.escape)],
        isA<DismissDesktopIntent>(),
      );
    });

    test('map contains exactly 5 entries', () {
      expect(AppShortcuts.map.length, 5);
    });
  });
}
