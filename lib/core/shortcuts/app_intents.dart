import 'package:flutter/widgets.dart';

/// Toggle the Spotlight search overlay.
/// Bound to ⌘K (macOS) and Ctrl+K (Windows / Linux / Web).
class OpenSpotlightIntent extends Intent {
  const OpenSpotlightIntent();
}

/// Close the topmost open window.
/// Bound to ⌘W (macOS) and Ctrl+W (Windows / Linux / Web).
class CloseTopWindowIntent extends Intent {
  const CloseTopWindowIntent();
}

/// Dismiss the highest-priority desktop overlay in order:
/// Spotlight → context menu → notification panel.
/// Bound to Escape on all platforms.
class DismissDesktopIntent extends Intent {
  const DismissDesktopIntent();
}
