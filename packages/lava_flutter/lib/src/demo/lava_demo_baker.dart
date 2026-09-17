import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/painting.dart';

import '../model/lava_manifest.dart';

/// Procedural rasterizer that generates a 24-frame 3D dimensional
/// micro-animation atlas with a 32-bit alpha channel entirely in memory.
///
/// Eliminates external asset dependencies for rapid prototyping,
/// automated testing, and zero-configuration demonstrations.
abstract final class LavaDemoBaker {
  static ui.Image? _cachedImage;

  /// Default manifest configuration corresponding to the baked atlas.
  static const LavaManifest defaultManifest = LavaManifest(
    version: 1,
    frameRate: 30,
    tileWidth: 128,
    tileHeight: 128,
    columns: 6,
    rows: 4,
    totalFrames: 24,
    loop: true,
  );

  /// Bakes the 24-frame 3D texture atlas.
  ///
  /// Subsequent calls return the cached [ui.Image] instance unless [forceRegenerate]
  /// is set to true.
  static Future<ui.Image> bakeAtlas({
    int tileWidth = 128,
    int tileHeight = 128,
    int columns = 6,
    int rows = 4,
    int totalFrames = 24,
    bool forceRegenerate = false,
  }) async {
    if (_cachedImage != null && !forceRegenerate) {
      return _cachedImage!;
    }

    final totalWidth = columns * tileWidth;
    final totalHeight = rows * tileHeight;

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    for (int i = 0; i < totalFrames; i++) {
      final col = i % columns;
      final row = i ~/ columns;
      final xOffset = (col * tileWidth).toDouble();
      final yOffset = (row * tileHeight).toDouble();

      canvas.save();
      canvas.translate(xOffset, yOffset);
      _renderFrame(
        canvas: canvas,
        frameIndex: i,
        totalFrames: totalFrames,
        width: tileWidth.toDouble(),
        height: tileHeight.toDouble(),
      );
      canvas.restore();
    }

    final picture = recorder.endRecording();
    final image = await picture.toImage(totalWidth, totalHeight);
    picture.dispose();

    _cachedImage = image;
    return image;
  }

  /// Clears the cached texture atlas to free GPU memory.
  static void clearCache() {
    _cachedImage?.dispose();
    _cachedImage = null;
  }

  static void _renderFrame({
    required Canvas canvas,
    required int frameIndex,
    required int totalFrames,
    required double width,
    required double height,
  }) {
    final t = frameIndex / totalFrames;
    final cx = width / 2.0;
    final cy = height / 2.0;

    // Levitation physics
    final bobbing = math.sin(t * 2 * math.pi) * 6.0;
    final currentCy = cy + bobbing;

    // Drop shadow
    final shadowScale = 1.0 - (bobbing / 30.0);
    final shadowOpacity = (0.28 * shadowScale).clamp(0.08, 0.35);
    final shadowPaint =
        Paint()
          ..color = Color.fromRGBO(15, 23, 42, shadowOpacity)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6.0);

    final shadowRect = Rect.fromCenter(
      center: Offset(cx, height - 18.0),
      width: 52.0 * shadowScale,
      height: 16.0 * shadowScale,
    );
    canvas.drawOval(shadowRect, shadowPaint);

    // 3D Geometry
    final rotationAngle = t * 2 * math.pi;
    const pitchAngle = 0.52; // ~30 degrees isometric tilt
    const cubeRadius = 26.0;

    const localVertices = [
      _Vec3(-cubeRadius, -cubeRadius, -cubeRadius), // 0: Top-Left-Back
      _Vec3(cubeRadius, -cubeRadius, -cubeRadius), // 1: Top-Right-Back
      _Vec3(cubeRadius, cubeRadius, -cubeRadius), // 2: Bottom-Right-Back
      _Vec3(-cubeRadius, cubeRadius, -cubeRadius), // 3: Bottom-Left-Back
      _Vec3(-cubeRadius, -cubeRadius, cubeRadius), // 4: Top-Left-Front
      _Vec3(cubeRadius, -cubeRadius, cubeRadius), // 5: Top-Right-Front
      _Vec3(cubeRadius, cubeRadius, cubeRadius), // 6: Bottom-Right-Front
      _Vec3(-cubeRadius, cubeRadius, cubeRadius), // 7: Bottom-Left-Front
    ];

    // Transform vertices
    final transformed = localVertices
        .map((v) {
          final rotatedY = v.rotateY(rotationAngle);
          final tilted = rotatedY.rotateX(pitchAngle);
          return Offset(cx + tilted.x, currentCy + tilted.y);
        })
        .toList(growable: false);

    final depths = localVertices
        .map((v) {
          final rotatedY = v.rotateY(rotationAngle);
          return rotatedY.rotateX(pitchAngle).z;
        })
        .toList(growable: false);

    // Cube faces: indices, base normal, base color
    const faces = [
      _Face([4, 5, 6, 7], _Vec3(0, 0, 1), Color(0xFFFF385C)), // Front
      _Face([1, 0, 3, 2], _Vec3(0, 0, -1), Color(0xFFE00B41)), // Back
      _Face([0, 1, 5, 4], _Vec3(0, -1, 0), Color(0xFFFF5A5F)), // Top
      _Face([7, 6, 2, 3], _Vec3(0, 1, 0), Color(0xFF990024)), // Bottom
      _Face([5, 1, 2, 6], _Vec3(1, 0, 0), Color(0xFFD70466)), // Right
      _Face([0, 4, 7, 3], _Vec3(-1, 0, 0), Color(0xFFC10037)), // Left
    ];

    final lightDir = const _Vec3(-0.45, -0.75, -0.48).normalized();

    // Sort visible faces back to front
    final visibleFaces = <_RenderFace>[];
    for (final face in faces) {
      final transformedNormal = face.normal
          .rotateY(rotationAngle)
          .rotateX(pitchAngle);
      // Camera looks down the +Z axis towards negative Z
      if (transformedNormal.z < 0.0) {
        double avgZ = 0;
        for (final idx in face.vertexIndices) {
          avgZ += depths[idx];
        }
        avgZ /= face.vertexIndices.length;

        final diffuse = (0.38 + 0.62 * transformedNormal.dot(lightDir)).clamp(
          0.25,
          1.0,
        );
        final shadedColor = _shadeColor(face.color, diffuse);

        visibleFaces.add(
          _RenderFace(
            indices: face.vertexIndices,
            avgZ: avgZ,
            color: shadedColor,
          ),
        );
      }
    }

    visibleFaces.sort((a, b) => b.avgZ.compareTo(a.avgZ));

    final facePaint = Paint()..style = PaintingStyle.fill;
    final edgePaint =
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2
          ..color = const Color.fromRGBO(255, 255, 255, 0.45);

    for (final face in visibleFaces) {
      final path = Path();
      final p0 = transformed[face.indices[0]];
      path.moveTo(p0.dx, p0.dy);
      for (int k = 1; k < face.indices.length; k++) {
        final p = transformed[face.indices[k]];
        path.lineTo(p.dx, p.dy);
      }
      path.close();

      facePaint.color = face.color;
      canvas.drawPath(path, facePaint);
      canvas.drawPath(path, edgePaint);
    }

    // Glowing core particle inside/above
    final coreOffset = Offset(
      cx + math.sin(rotationAngle * 2) * 4.0,
      currentCy - 4.0,
    );
    final glowPaint =
        Paint()
          ..color = const Color.fromRGBO(255, 255, 255, 0.85)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3.5);
    canvas.drawCircle(coreOffset, 3.0, glowPaint);
  }

  static Color _shadeColor(Color base, double factor) {
    return Color.from(
      alpha: base.a,
      red: (base.r * factor).clamp(0.0, 1.0),
      green: (base.g * factor).clamp(0.0, 1.0),
      blue: (base.b * factor).clamp(0.0, 1.0),
    );
  }
}

class _Vec3 {
  const _Vec3(this.x, this.y, this.z);
  final double x;
  final double y;
  final double z;

  _Vec3 rotateY(double angle) {
    final cosA = math.cos(angle);
    final sinA = math.sin(angle);
    return _Vec3(x * cosA + z * sinA, y, -x * sinA + z * cosA);
  }

  _Vec3 rotateX(double angle) {
    final cosA = math.cos(angle);
    final sinA = math.sin(angle);
    return _Vec3(x, y * cosA - z * sinA, y * sinA + z * cosA);
  }

  double dot(_Vec3 o) => x * o.x + y * o.y + z * o.z;

  _Vec3 normalized() {
    final len = math.sqrt(x * x + y * y + z * z);
    if (len == 0) return this;
    return _Vec3(x / len, y / len, z / len);
  }
}

class _Face {
  const _Face(this.vertexIndices, this.normal, this.color);
  final List<int> vertexIndices;
  final _Vec3 normal;
  final Color color;
}

class _RenderFace {
  const _RenderFace({
    required this.indices,
    required this.avgZ,
    required this.color,
  });
  final List<int> indices;
  final double avgZ;
  final Color color;
}
