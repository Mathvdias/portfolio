import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

/// Rubber-band area selection on the desktop background.
///
/// Renders a translucent blue rectangle while the user drags.
class RubberBandSelection extends StatelessWidget {
  const RubberBandSelection({
    super.key,
    required this.origin,
    required this.current,
  });

  /// Where the drag started (in desktop-local coordinates).
  final Offset origin;

  /// Current pointer position.
  final Offset current;

  @override
  Widget build(BuildContext context) {
    final rect = Rect.fromPoints(origin, current);
    return Positioned(
      left: rect.left,
      top: rect.top,
      width: rect.width,
      height: rect.height,
      child: IgnorePointer(
        child: Container(
          decoration: BoxDecoration(
            color: AppTheme.blue.withValues(alpha: 0.12),
            border: Border.all(
              color: AppTheme.blue.withValues(alpha: 0.55),
              width: 1,
            ),
          ),
        ),
      ),
    );
  }
}
