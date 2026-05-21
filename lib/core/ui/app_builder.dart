import 'package:flutter/widgets.dart';

/// Static [MaterialApp.builder] callbacks.
abstract final class AppBuilder {
  /// Pins [MediaQuery.textScaler] to [TextScaler.noScaling] for the entire
  /// widget tree.
  ///
  /// Without this, a user who has increased their OS / browser font size
  /// would see Flutter honour the system text-scale factor, which inflates
  /// every [Text] widget.  For a fixed-dimension desktop layout (dock,
  /// window chrome, desktop icons) that breaks the UI in a way that cannot
  /// be fixed with responsive layouts — the positions and sizes are designed
  /// around 1× scale.
  ///
  /// This is a deliberate product decision: the portfolio is a pixel-precise
  /// desktop simulator, not a document reader.
  static Widget withFixedTextScale(BuildContext context, Widget? child) {
    return MediaQuery(
      data: MediaQuery.of(context).copyWith(textScaler: TextScaler.noScaling),
      child: child!,
    );
  }
}
