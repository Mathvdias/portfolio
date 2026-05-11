import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:portifolio/theme/app_theme.dart';

void main() {
  group('AppTheme', () {
    // Use testWidgets so async font-loading futures are properly flushed
    // by pumpAndSettle before the test completes.

    testWidgets('pixelText returns a TextStyle', (tester) async {
      final style = AppTheme.pixelText();
      expect(style, isA<TextStyle>());
      expect(style.fontSize, 10);
      expect(style.color, AppTheme.text);
      await tester.pumpAndSettle();
    });

    testWidgets('pixelText accepts custom size and color', (tester) async {
      final style = AppTheme.pixelText(size: 16, color: AppTheme.blue);
      expect(style.fontSize, 16);
      expect(style.color, AppTheme.blue);
      await tester.pumpAndSettle();
    });

    testWidgets('monoText returns a TextStyle', (tester) async {
      final style = AppTheme.monoText();
      expect(style, isA<TextStyle>());
      expect(style.fontSize, 13);
      expect(style.color, AppTheme.text);
      await tester.pumpAndSettle();
    });

    testWidgets('monoText accepts custom size and color', (tester) async {
      final style = AppTheme.monoText(size: 20, color: AppTheme.green);
      expect(style.fontSize, 20);
      expect(style.color, AppTheme.green);
      await tester.pumpAndSettle();
    });

    test('darkTheme returns ThemeData with dark brightness', () {
      final theme = AppTheme.darkTheme;
      expect(theme, isA<ThemeData>());
      expect(theme.brightness, Brightness.dark);
      expect(theme.scaffoldBackgroundColor, AppTheme.background);
    });

    test('color constants are correct Catppuccin values', () {
      expect(AppTheme.background, const Color(0xFF1E1E2E));
      expect(AppTheme.blue, const Color(0xFF89B4FA));
      expect(AppTheme.green, const Color(0xFFA6E3A1));
      expect(AppTheme.red, const Color(0xFFF38BA8));
    });
  });
}
