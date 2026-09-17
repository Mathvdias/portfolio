import 'dart:ui' as ui;
import 'package:flutter/widgets.dart';

import '../model/lava_manifest.dart';
import 'lava_controller.dart';
import 'tile_math.dart';

/// Blits sub-rectangles from a Lava texture atlas to the canvas.
///
/// Driven directly by [LavaController], rendering individual frames
/// with zero heap allocations during the paint cycle.
class LavaPainter extends CustomPainter {
  LavaPainter({
    required this.atlas,
    required this.manifest,
    required this.controller,
    this.fit = BoxFit.contain,
    this.alignment = Alignment.center,
    this.color,
    this.blendMode = BlendMode.srcIn,
    this.filterQuality = FilterQuality.medium,
  }) : super(repaint: controller);

  /// Hardware texture containing the packed animation frames.
  final ui.Image atlas;

  /// Dimension and layout metadata for the animation.
  final LavaManifest manifest;

  /// Playback controller providing the active frame index.
  final LavaController controller;

  /// How the animation frame should be inscribed into the render box.
  final BoxFit fit;

  /// Alignment of the frame within the render box.
  final Alignment alignment;

  /// Optional color filter tint applied to the atlas frame.
  final Color? color;

  /// Blend mode used when [color] is specified.
  final BlendMode blendMode;

  /// Filter quality applied when scaling the texture frame.
  final FilterQuality filterQuality;

  final Paint _paint = Paint();

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;

    final frameIndex = controller.currentFrame;
    final srcRect = TileMath.getSourceRect(
      frameIndex: frameIndex,
      tileWidth: manifest.tileWidth,
      tileHeight: manifest.tileHeight,
      columns: manifest.columns,
    );

    if (srcRect.isEmpty) return;

    final inputSize = Size(
      manifest.tileWidth.toDouble(),
      manifest.tileHeight.toDouble(),
    );
    final fittedSizes = applyBoxFit(fit, inputSize, size);
    final destRect = alignment.inscribe(
      fittedSizes.destination,
      Offset.zero & size,
    );

    _paint.filterQuality = filterQuality;
    if (color != null) {
      _paint.colorFilter = ColorFilter.mode(color!, blendMode);
    } else {
      _paint.colorFilter = null;
    }

    canvas.drawImageRect(atlas, srcRect, destRect, _paint);
  }

  @override
  bool shouldRepaint(covariant LavaPainter oldDelegate) {
    return oldDelegate.atlas != atlas ||
        oldDelegate.manifest != manifest ||
        oldDelegate.controller != controller ||
        oldDelegate.fit != fit ||
        oldDelegate.alignment != alignment ||
        oldDelegate.color != color ||
        oldDelegate.blendMode != blendMode ||
        oldDelegate.filterQuality != filterQuality;
  }
}
