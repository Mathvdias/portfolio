import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'app_intents.dart';

/// Constant shortcut → intent mapping for [MaterialApp.shortcuts].
///
/// Each action is registered for both the Meta (⌘, macOS) and Control
/// (Windows / Linux / Web) modifier so the portfolio is fully keyboard-
/// navigable on every platform.
abstract final class AppShortcuts {
  static const map = <ShortcutActivator, Intent>{
    SingleActivator(LogicalKeyboardKey.keyK, meta: true): OpenSpotlightIntent(),
    SingleActivator(LogicalKeyboardKey.keyK, control: true):
        OpenSpotlightIntent(),
    SingleActivator(LogicalKeyboardKey.keyW, meta: true):
        CloseTopWindowIntent(),
    SingleActivator(LogicalKeyboardKey.keyW, control: true):
        CloseTopWindowIntent(),
    SingleActivator(LogicalKeyboardKey.escape): DismissDesktopIntent(),
  };
}
