import 'package:flutter/material.dart';
import 'package:lava_flutter/lava_flutter.dart';

import '../../theme/app_theme.dart';
import 'lava_key.dart';

/// Restart key rendered by the Lava engine, in cooled lava.
///
/// One press is one run of the bundle (the `Restart` scene in
/// `packages/lava_flutter/tool/sdf_scenes.py`): the key sinks, the circular
/// arrow makes a full turn the way it points, heating up on the way, and
/// comes to rest on the picture it started from. The key never ticks at rest.
class LavaRestartButton extends StatefulWidget {
  const LavaRestartButton({
    super.key,
    required this.onPressed,
    this.size = 70,
    this.tooltip,
    this.assetBundle,
  });

  /// Called on tap, Enter and Space, before the key starts to turn.
  final VoidCallback onPressed;

  /// Painted width, see [LavaKey.size].
  final double size;

  /// Tooltip and semantics label.
  final String? tooltip;

  /// Where the bundle is read from (defaults to the root bundle).
  final AssetBundle? assetBundle;

  /// OpenLava directory of the key.
  static const String assetPath = 'assets/lava/restart';

  /// Frames in the bundle (`Restart.frames` in the tool scene). The last one
  /// is the first one again, so a run that completes is back at rest.
  static const int frameCount = 24;

  /// Playback rate the scene was rendered for.
  static const int fps = 30;

  @override
  State<LavaRestartButton> createState() => _LavaRestartButtonState();
}

class _LavaRestartButtonState extends State<LavaRestartButton>
    with SingleTickerProviderStateMixin {
  final LavaController _controller = LavaController(
    totalFrames: LavaRestartButton.frameCount,
    fps: LavaRestartButton.fps,
    loop: false,
    autoPlay: false,
  );
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    _controller.attach(this);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _press() {
    widget.onPressed();
    if (!_ready || MediaQuery.disableAnimationsOf(context)) return;
    // Paused first: play() rewinds a run that completed, and a press in the
    // middle of a turn starts the turn again.
    _controller.pause();
    _controller.seekToFrame(0);
    _controller.play();
  }

  Widget _buildFallback(BuildContext context, double diameter) {
    return DecoratedBox(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: AppTheme.surface0),
      ),
      child: Icon(Icons.replay, size: diameter * 0.5, color: AppTheme.subtext),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LavaKey(
      assetPath: LavaRestartButton.assetPath,
      controller: _controller,
      onPressed: _press,
      fallback: _buildFallback,
      errorContext: 'while loading the restart Lava key',
      size: widget.size,
      label: widget.tooltip,
      assetBundle: widget.assetBundle,
      onBundleReady: () => _ready = true,
    );
  }
}
