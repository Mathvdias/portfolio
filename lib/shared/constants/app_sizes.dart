/// Centralises all spacing, dimension, radius, and font-size tokens.
///
/// Use these values everywhere instead of hardcoded numbers so the
/// whole design system can be tuned from a single file.
abstract final class AppSizes {
  // ─── Spacing ────────────────────────────────────────────────────
  static const double spacingXxs = 2.0;
  static const double spacingXs = 4.0;
  static const double spacingSm = 6.0;
  static const double spacingMd = 8.0;
  static const double spacingBase = 10.0;
  static const double spacingLg = 12.0;
  static const double spacingXl = 16.0;
  static const double spacingXxl = 20.0;
  static const double spacing3xl = 24.0;
  static const double spacing4xl = 32.0;

  // ─── Border radius ──────────────────────────────────────────────
  static const double radiusSm = 4.0;
  static const double radiusMd = 6.0;
  static const double radiusLg = 8.0;
  static const double radiusXl = 12.0;
  static const double radiusXxl = 16.0;
  static const double radiusDock = 20.0;

  // ─── Desktop icon ───────────────────────────────────────────────
  static const double iconWidth = 88.0;
  static const double iconArtSize = 48.0;
  static const double iconLabelWidth = 72.0;

  // ─── Dock ───────────────────────────────────────────────────────
  static const double dockIconSize = 40.0;
  static const double dockItemSpacing = 20.0;
  static const double dockPaddingH = 20.0;
  static const double dockPaddingV = 8.0;
  static const double dockHoverScale = 1.2;

  // ─── Window ─────────────────────────────────────────────────────
  static const double windowWidth = 480.0;
  static const double windowHeight = 360.0;
  static const double windowTitleBarHeight = 32.0;
  static const double windowTrafficLightSize = 12.0;
  static const double windowTrafficLightSpacing = 6.0;
  static const double windowCascadeOffset = 28.0;
  static const double windowCascadeBase = 80.0;
  static const double windowCascadeTop = 48.0;
  static const int windowCascadeModulo = 6;

  // ─── Menu bar ───────────────────────────────────────────────────
  static const double menuBarHeight = 28.0;
  static const double menuBarOffset = 28.0;

  // ─── Notification center ────────────────────────────────────────
  static const double notificationCenterWidth = 300.0;

  // ─── Sticky notes ───────────────────────────────────────────────
  static const double stickyNoteSize = 140.0;
  static const double stickyNoteTapeHeight = 10.0;

  // ─── Terminal ───────────────────────────────────────────────────
  static const double terminalFontSize = 12.0;
  static const double terminalPadding = 12.0;

  // ─── Calculator ─────────────────────────────────────────────────
  static const double calculatorDisplayFontSize = 24.0;
  static const double calculatorButtonFontSize = 16.0;

  // ─── Snake game ─────────────────────────────────────────────────
  static const int snakeCols = 22;
  static const int snakeRows = 16;
  static const int snakeTickMs = 200;

  // ─── Font sizes ─────────────────────────────────────────────────
  static const double fontXxs = 6.0;
  static const double fontXs = 7.0;
  static const double fontSm = 8.0;
  static const double fontMd = 9.0;
  static const double fontBase = 10.0;
  static const double fontLg = 11.0;
  static const double fontXl = 12.0;
  static const double fontXxl = 13.0;
  static const double font2xl = 14.0;
  static const double font3xl = 16.0;
  static const double font4xl = 20.0;
  static const double font5xl = 24.0;

  // ─── Layout breakpoints ─────────────────────────────────────────
  static const double mobileBreakpoint = 600.0;
  static const double desktopBreakpoint = 1200.0;

  // ─── Dock bottom offset ─────────────────────────────────────────
  static const double dockBottomOffset = 10.0;
  static const double desktopBottom = 80.0;

  // ─── Spotlight ──────────────────────────────────────────────────
  static const double spotlightWidth = 480.0;
  static const double spotlightMaxHeight = 380.0;

  // ─── Context menu ───────────────────────────────────────────────
  static const double contextMenuWidth = 220.0;
}
