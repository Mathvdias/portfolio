import 'package:flutter_test/flutter_test.dart';
import 'package:portifolio/shared/constants/app_sizes.dart';

void main() {
  group('AppSizes', () {
    test('spacing tokens are positive and in ascending order', () {
      final spacings = [
        AppSizes.spacingXxs,
        AppSizes.spacingXs,
        AppSizes.spacingSm,
        AppSizes.spacingMd,
        AppSizes.spacingLg,
        AppSizes.spacingXl,
        AppSizes.spacingXxl,
        AppSizes.spacing3xl,
        AppSizes.spacing4xl,
      ];
      for (int i = 0; i < spacings.length; i++) {
        expect(spacings[i], greaterThan(0));
        if (i > 0) expect(spacings[i], greaterThanOrEqualTo(spacings[i - 1]));
      }
    });

    test('font sizes are positive and in ascending order', () {
      final fonts = [
        AppSizes.fontXxs,
        AppSizes.fontXs,
        AppSizes.fontSm,
        AppSizes.fontMd,
        AppSizes.fontBase,
        AppSizes.fontLg,
        AppSizes.fontXl,
        AppSizes.fontXxl,
        AppSizes.font2xl,
        AppSizes.font3xl,
        AppSizes.font4xl,
        AppSizes.font5xl,
      ];
      for (int i = 0; i < fonts.length; i++) {
        expect(fonts[i], greaterThan(0));
        if (i > 0) expect(fonts[i], greaterThanOrEqualTo(fonts[i - 1]));
      }
    });

    test('breakpoints are sensible', () {
      expect(AppSizes.mobileBreakpoint, lessThan(AppSizes.desktopBreakpoint));
    });

    test('window cascade modulo is positive', () {
      expect(AppSizes.windowCascadeModulo, greaterThan(0));
    });

    test('component dimensions are positive', () {
      expect(AppSizes.windowWidth, greaterThan(0));
      expect(AppSizes.windowHeight, greaterThan(0));
      expect(AppSizes.menuBarHeight, greaterThan(0));
      expect(AppSizes.notificationCenterWidth, greaterThan(0));
      expect(AppSizes.dockIconSize, greaterThan(0));
      expect(AppSizes.stickyNoteSize, greaterThan(0));
      expect(AppSizes.spotlightWidth, greaterThan(0));
      expect(AppSizes.contextMenuWidth, greaterThan(0));
    });
  });
}
