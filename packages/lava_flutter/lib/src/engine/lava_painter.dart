import 'dart:math' as math;
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
    this.atlas,
    this.images = const [],
    required this.manifest,
    required this.controller,
    this.fit = BoxFit.contain,
    this.alignment = Alignment.center,
    this.color,
    this.blendMode = BlendMode.srcIn,
    this.filterQuality = FilterQuality.medium,
  }) : super(repaint: controller);

  /// Hardware texture containing the packed animation frames for grid mode.
  final ui.Image? atlas;

  /// Hardware textures for OpenLava multi-image diff mode.
  final List<ui.Image> images;

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

    _paint.filterQuality = filterQuality;
    // Tiles are blitted as adjacent rectangles; anti-aliased rectangle edges
    // leave hairline seams between them once the canvas is scaled, so edge
    // AA is disabled (texture sampling is still filtered by filterQuality).
    _paint.isAntiAlias = false;
    if (color != null) {
      _paint.colorFilter = ColorFilter.mode(color!, blendMode);
    } else {
      _paint.colorFilter = null;
    }

    final frameIndex = controller.currentFrame;

    // 1. OpenLava native diff/key rendering mode
    if (manifest.rawFrames.isNotEmpty && images.isNotEmpty) {
      final frameObj =
          manifest.rawFrames[frameIndex % manifest.rawFrames.length];
      if (frameObj is Map) {
        final contentWidth = manifest.tileWidth.toDouble();
        final contentHeight = manifest.tileHeight.toDouble();
        final cellSize = (manifest.cellSize ?? 32).toDouble();

        final fittedSizes = applyBoxFit(
          fit,
          Size(contentWidth, contentHeight),
          size,
        );
        final destRect = alignment.inscribe(
          fittedSizes.destination,
          Offset.zero & size,
        );
        final scale = destRect.width / contentWidth;

        canvas.save();
        canvas.translate(destRect.left, destRect.top);
        canvas.scale(scale);
        canvas.clipRect(Rect.fromLTWH(0, 0, contentWidth, contentHeight));

        final type = frameObj['type'];
        if (type == 'key') {
          final imgIdx = (frameObj['imageIndex'] as num?)?.toInt() ?? 0;
          if (imgIdx < images.length) {
            canvas.drawImage(images[imgIdx], Offset.zero, _paint);
          }
        } else if (type == 'diff') {
          final diffs = frameObj['diffs'] as List?;
          if (diffs != null) {
            for (final entry in diffs) {
              if (entry is List && entry.length >= 5) {
                final srcIndex = (entry[0] as num).toInt();
                final srcTileIndex = (entry[1] as num).toInt();
                final countX = (entry[2] as num).toDouble();
                final countY = (entry[3] as num).toDouble();
                final destTileIndex = (entry[4] as num).toInt();

                if (srcIndex < images.length) {
                  final srcImage = images[srcIndex];
                  final destTilesPerRow = (contentWidth / cellSize).ceil();
                  final srcTilesPerRow = (srcImage.width / cellSize).ceil();

                  final dstX = (destTileIndex % destTilesPerRow) * cellSize;
                  final dstY = (destTileIndex ~/ destTilesPerRow) * cellSize;

                  final srcX = (srcTileIndex % srcTilesPerRow) * cellSize;
                  final srcY = (srcTileIndex ~/ srcTilesPerRow) * cellSize;

                  final srcImageW = srcImage.width.toDouble();
                  final srcImageH = srcImage.height.toDouble();

                  // Boundary guards: discard if starting outside visible / texture surface
                  if (srcX >= srcImageW || srcY >= srcImageH) continue;
                  if (dstX >= contentWidth || dstY >= contentHeight) continue;

                  final availSrcW = srcImageW - srcX;
                  final availSrcH = srcImageH - srcY;
                  final availDstW = contentWidth - dstX;
                  final availDstH = contentHeight - dstY;

                  final blockW = countX * cellSize;
                  final blockH = countY * cellSize;

                  final drawW = math.min(blockW, math.min(availSrcW, availDstW));
                  final drawH = math.min(blockH, math.min(availSrcH, availDstH));

                  if (drawW <= 0 || drawH <= 0) continue;

                  final srcRect = Rect.fromLTWH(srcX, srcY, drawW, drawH);
                  final dstRect = Rect.fromLTWH(dstX, dstY, drawW, drawH);

                  canvas.drawImageRect(srcImage, srcRect, dstRect, _paint);
                }
              }
            }
          }
        }
        canvas.restore();
        return;
      }
    }

    // 2. Standard Grid Atlas mode
    if (atlas == null) return;

    final totalFrames = manifest.totalFrames > 0 ? manifest.totalFrames : 1;
    final effectiveFrame = frameIndex % totalFrames;

    final srcRect = TileMath.getSourceRect(
      frameIndex: effectiveFrame,
      tileWidth: manifest.tileWidth,
      tileHeight: manifest.tileHeight,
      columns: manifest.columns,
    );

    if (srcRect.isEmpty) return;
    if (srcRect.right > atlas!.width || srcRect.bottom > atlas!.height) return;

    final inputSize = Size(
      manifest.tileWidth.toDouble(),
      manifest.tileHeight.toDouble(),
    );
    final fittedSizes = applyBoxFit(fit, inputSize, size);
    final destRect = alignment.inscribe(
      fittedSizes.destination,
      Offset.zero & size,
    );

    canvas.drawImageRect(atlas!, srcRect, destRect, _paint);
  }

  @override
  bool shouldRepaint(covariant LavaPainter oldDelegate) {
    return oldDelegate.atlas != atlas ||
        oldDelegate.images != images ||
        oldDelegate.manifest != manifest ||
        oldDelegate.controller != controller ||
        oldDelegate.fit != fit ||
        oldDelegate.alignment != alignment ||
        oldDelegate.color != color ||
        oldDelegate.blendMode != blendMode ||
        oldDelegate.filterQuality != filterQuality;
  }
}
