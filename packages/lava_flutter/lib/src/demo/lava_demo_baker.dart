import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/painting.dart';

import '../model/lava_manifest.dart';

/// Procedural rasterizer that generates a 24-frame 3D dimensional
/// Macintosh / Cyberdeck micro-animation atlas with 32-bit alpha channel
/// entirely in memory.
///
/// Models the iconic 1984 Macintosh chassis with backward wedge tilt,
/// recessed phosphor CRT screen with cyan/green scanline glow, floppy drive slot,
/// rainbow badge, top carrying handle, and soft ambient occlusion ground shadow.
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
    final cy = (height / 2.0) - 2.0;

    // Levitation physics (subtle vertical bobbing)
    final bobbing = math.sin(t * 2 * math.pi) * 3.8;
    final currentCy = cy + bobbing;

    // Turntable rotation and isometric pitch
    final rotY = t * 2 * math.pi;
    const pitch = 0.38; // ~22 degrees downward pitch angle

    // Ambient Occlusion Ground Drop Shadow
    final shadowScale = 1.0 - (bobbing / 28.0);
    final shadowWidth = (54.0 + math.cos(rotY * 2).abs() * 6.0) * shadowScale;
    final shadowHeight = (18.0 - math.sin(rotY * 2).abs() * 2.5) * shadowScale;
    final shadowOpacity = (0.28 * shadowScale).clamp(0.10, 0.36);

    final shadowPaint =
        Paint()
          ..color = Color.from(
            alpha: shadowOpacity,
            red: 0.05,
            green: 0.08,
            blue: 0.16,
          )
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 7.0);

    final shadowRect = Rect.fromCenter(
      center: Offset(cx, height - 16.0),
      width: shadowWidth,
      height: shadowHeight,
    );
    canvas.drawOval(shadowRect, shadowPaint);

    // Light direction (Top-Left-Front key light)
    final lightDir = const _Vec3(-0.45, -0.75, -0.48).normalized();

    // 3D Model Definition: Classic Macintosh 128K
    final faces = _buildMacintoshFaces();

    // Depth sort visible faces (Painter's algorithm)
    final visibleFaces = <_RenderFace>[];

    for (final face in faces) {
      final tn = face.normal.rotateY(rotY).rotateX(pitch);
      // Back-face culling: camera looks down +Z
      if (tn.z < 0.0) {
        final projected = <Offset>[];
        double totalZ = 0.0;

        for (final v in face.vertices) {
          final r = v.rotateY(rotY).rotateX(pitch);
          projected.add(Offset(cx + r.x, currentCy + r.y));
          totalZ += r.z;
        }

        final avgZ = totalZ / face.vertices.length;
        final diffuse = (0.38 + 0.62 * tn.dot(lightDir)).clamp(0.22, 1.0);
        final shadedColor = _shadeColor(face.color, diffuse);

        visibleFaces.add(
          _RenderFace(
            type: face.type,
            projected: projected,
            avgZ: avgZ,
            diffuse: diffuse,
            color: shadedColor,
            normal: tn,
          ),
        );
      }
    }

    visibleFaces.sort((a, b) => b.avgZ.compareTo(a.avgZ));

    final facePaint = Paint()..style = PaintingStyle.fill;
    final edgePaint =
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.9;

    for (final rf in visibleFaces) {
      final path = Path()..moveTo(rf.projected[0].dx, rf.projected[0].dy);
      for (int k = 1; k < rf.projected.length; k++) {
        path.lineTo(rf.projected[k].dx, rf.projected[k].dy);
      }
      path.close();

      // Render base face geometry
      facePaint.color = rf.color;
      canvas.drawPath(path, facePaint);

      // Specular edge highlight
      final rimFactor = (rf.diffuse * 0.45).clamp(0.12, 0.55);
      edgePaint.color = Color.from(
        alpha: rimFactor,
        red: 1.0,
        green: 1.0,
        blue: 1.0,
      );
      canvas.drawPath(path, edgePaint);

      // Decorative face features
      switch (rf.type) {
        case _FaceType.screen:
          _drawCrtContent(canvas, rf.projected, path, t);
        case _FaceType.chin:
          _drawChinDetails(canvas, rf.projected, cx, currentCy, rotY, pitch);
        case _FaceType.back:
          _drawBackVentilation(canvas, rf.projected);
        case _FaceType.top:
          _drawTopHandle(canvas, rf.projected);
        default:
          break;
      }
    }
  }

  static List<_Face> _buildMacintoshFaces() {
    // Coordinate dimensions
    // Height: top = -24, bottom = 22
    // Width: bottom = ±18, top = ±16.5 (tapered)
    // Depth: back = -15, front bottom = 15, front top = 12.5 (wedge tilt)
    const vBackBotLeft = _Vec3(-18.0, 22.0, -15.0);
    const vBackBotRight = _Vec3(18.0, 22.0, -15.0);
    const vBackTopRight = _Vec3(16.5, -24.0, -15.0);
    const vBackTopLeft = _Vec3(-16.5, -24.0, -15.0);

    const vFrontBotLeft = _Vec3(-18.0, 22.0, 15.0);
    const vFrontBotRight = _Vec3(18.0, 22.0, 15.0);
    const vFrontTopRight = _Vec3(16.5, -24.0, 12.5);
    const vFrontTopLeft = _Vec3(-16.5, -24.0, 12.5);

    // Front Brow & Chin transition points
    const vBrowBotLeft = _Vec3(-16.8, -16.0, 13.0);
    const vBrowBotRight = _Vec3(16.8, -16.0, 13.0);

    const vChinTopLeft = _Vec3(-17.6, 7.0, 14.5);
    const vChinTopRight = _Vec3(17.6, 7.0, 14.5);

    // Recessed Screen corners (recessed into bezel)
    const vScreenTopLeft = _Vec3(-11.5, -14.5, 11.2);
    const vScreenTopRight = _Vec3(11.5, -14.5, 11.2);
    const vScreenBotRight = _Vec3(11.5, 5.5, 12.8);
    const vScreenBotLeft = _Vec3(-11.5, 5.5, 12.8);

    // Colors (Apple Vintage Platinum / Warm Beige)
    const cTop = Color(0xFFECE6DA);
    const cBottom = Color(0xFFA8A193);
    const cBack = Color(0xFFC7BFA8);
    const cLeft = Color(0xFFBFB7A6);
    const cRight = Color(0xFFD6CEC0);
    const cBezel = Color(0xFFD9D2C4);
    const cChamferDark = Color(0xFF8B8476);
    const cChamferLight = Color(0xFFB5ADA0);
    const cScreenBg = Color(0xFF071913);

    return const [
      // 1. Bottom shell
      _Face(
        [vBackBotLeft, vBackBotRight, vFrontBotRight, vFrontBotLeft],
        _Vec3(0, 1, 0),
        cBottom,
        _FaceType.bottom,
      ),
      // 2. Top shell
      _Face(
        [vBackTopLeft, vFrontTopLeft, vFrontTopRight, vBackTopRight],
        _Vec3(0, -1, 0),
        cTop,
        _FaceType.top,
      ),
      // 3. Back shell
      _Face(
        [vBackBotRight, vBackBotLeft, vBackTopLeft, vBackTopRight],
        _Vec3(0, 0, -1),
        cBack,
        _FaceType.back,
      ),
      // 4. Left shell
      _Face(
        [vFrontBotLeft, vBackBotLeft, vBackTopLeft, vFrontTopLeft],
        _Vec3(-1, 0, 0),
        cLeft,
        _FaceType.left,
      ),
      // 5. Right shell
      _Face(
        [vBackBotRight, vFrontBotRight, vFrontTopRight, vBackTopRight],
        _Vec3(1, 0, 0),
        cRight,
        _FaceType.right,
      ),
      // 6. Front Brow (above CRT screen)
      _Face(
        [vBrowBotLeft, vBrowBotRight, vFrontTopRight, vFrontTopLeft],
        _Vec3(0, 0.05, 1.0),
        cBezel,
        _FaceType.bezel,
      ),
      // 7. Front Chin (below CRT screen, holding floppy drive)
      _Face(
        [vFrontBotLeft, vFrontBotRight, vChinTopRight, vChinTopLeft],
        _Vec3(0, 0.05, 1.0),
        cBezel,
        _FaceType.chin,
      ),
      // 8. Left Bezel Cheek
      _Face(
        [
          vChinTopLeft,
          _Vec3(-11.5, 7.0, 14.5),
          _Vec3(-11.5, -16.0, 13.0),
          vBrowBotLeft,
        ],
        _Vec3(0, 0.05, 1.0),
        cBezel,
        _FaceType.bezel,
      ),
      // 9. Right Bezel Cheek
      _Face(
        [
          _Vec3(11.5, 7.0, 14.5),
          vChinTopRight,
          vBrowBotRight,
          _Vec3(11.5, -16.0, 13.0),
        ],
        _Vec3(0, 0.05, 1.0),
        cBezel,
        _FaceType.bezel,
      ),
      // 10. Recessed Screen Top Chamfer
      _Face(
        [
          _Vec3(-11.5, -16.0, 13.0),
          _Vec3(11.5, -16.0, 13.0),
          vScreenTopRight,
          vScreenTopLeft,
        ],
        _Vec3(0, -0.7, 0.7),
        cChamferDark,
        _FaceType.bezel,
      ),
      // 11. Recessed Screen Bottom Chamfer
      _Face(
        [
          vScreenBotLeft,
          vScreenBotRight,
          _Vec3(11.5, 7.0, 14.5),
          _Vec3(-11.5, 7.0, 14.5),
        ],
        _Vec3(0, 0.7, 0.7),
        cChamferLight,
        _FaceType.bezel,
      ),
      // 12. Recessed Screen Left Chamfer
      _Face(
        [
          _Vec3(-11.5, 7.0, 14.5),
          _Vec3(-11.5, -16.0, 13.0),
          vScreenTopLeft,
          vScreenBotLeft,
        ],
        _Vec3(-0.7, 0, 0.7),
        cChamferDark,
        _FaceType.bezel,
      ),
      // 13. Recessed Screen Right Chamfer
      _Face(
        [
          _Vec3(11.5, -16.0, 13.0),
          _Vec3(11.5, 7.0, 14.5),
          vScreenBotRight,
          vScreenTopRight,
        ],
        _Vec3(0.7, 0, 0.7),
        cChamferLight,
        _FaceType.bezel,
      ),
      // 14. Phosphor CRT Screen Face
      _Face(
        [vScreenBotLeft, vScreenBotRight, vScreenTopRight, vScreenTopLeft],
        _Vec3(0, 0.05, 1.0),
        cScreenBg,
        _FaceType.screen,
      ),
    ];
  }

  static void _drawCrtContent(
    Canvas canvas,
    List<Offset> pts,
    Path screenPath,
    double t,
  ) {
    canvas.save();
    canvas.clipPath(screenPath);

    // Deep glowing CRT background
    final crtBounds = screenPath.getBounds();
    final crtBgPaint =
        Paint()
          ..shader = ui.Gradient.linear(
            crtBounds.topLeft,
            crtBounds.bottomRight,
            const [Color(0xFF031A12), Color(0xFF052B1E), Color(0xFF02120C)],
            const [0.0, 0.5, 1.0],
          );
    canvas.drawRect(crtBounds, crtBgPaint);

    // CRT Scanlines
    final scanlinePaint =
        Paint()
          ..color = const Color.from(
            alpha: 0.18,
            red: 0.0,
            green: 0.0,
            blue: 0.0,
          )
          ..strokeWidth = 1.0;
    for (double y = crtBounds.top; y <= crtBounds.bottom; y += 2.0) {
      canvas.drawLine(
        Offset(crtBounds.left, y),
        Offset(crtBounds.right, y),
        scanlinePaint,
      );
    }

    // Glowing Phosphor Terminal Prompt
    final phosphorPaint =
        Paint()
          ..color = const Color(0xFF00FF9D)
          ..style = PaintingStyle.fill;

    // Terminal command text bar & cursor
    final textX = crtBounds.left + crtBounds.width * 0.16;
    final textY1 = crtBounds.top + crtBounds.height * 0.28;
    final textY2 = crtBounds.top + crtBounds.height * 0.50;

    // Line 1: Code block / title bar
    canvas.drawRect(
      Rect.fromLTWH(textX, textY1, crtBounds.width * 0.55, 2.0),
      phosphorPaint,
    );

    // Line 2: Retro terminal prompt `>_`
    final promptPath =
        Path()
          ..moveTo(textX, textY2)
          ..lineTo(textX + 3.0, textY2 + 2.0)
          ..lineTo(textX, textY2 + 4.0);
    final promptStroke =
        Paint()
          ..color = const Color(0xFF00FF9D)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2;
    canvas.drawPath(promptPath, promptStroke);

    // Blinking cursor
    final cursorVisible = (t * 6).floor() % 2 == 0;
    if (cursorVisible) {
      final cursorPaint = Paint()..color = const Color(0xFF50FFAF);
      canvas.drawRect(
        Rect.fromLTWH(textX + 6.0, textY2, 3.5, 4.5),
        cursorPaint,
      );
    }

    // Phosphor Inner Radial Bloom
    final bloomPaint =
        Paint()
          ..color = const Color.from(
            alpha: 0.22,
            red: 0.0,
            green: 1.0,
            blue: 0.6,
          )
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5.0);
    canvas.drawCircle(crtBounds.center, crtBounds.width * 0.32, bloomPaint);

    // Specular curved CRT glass reflection streak
    final glarePaint =
        Paint()
          ..shader = ui.Gradient.linear(crtBounds.topLeft, crtBounds.center, [
            const Color.from(alpha: 0.45, red: 1.0, green: 1.0, blue: 1.0),
            const Color.from(alpha: 0.0, red: 1.0, green: 1.0, blue: 1.0),
          ]);
    final glarePath =
        Path()
          ..moveTo(crtBounds.left, crtBounds.top)
          ..lineTo(crtBounds.left + crtBounds.width * 0.65, crtBounds.top)
          ..lineTo(crtBounds.left, crtBounds.top + crtBounds.height * 0.65)
          ..close();
    canvas.drawPath(glarePath, glarePaint);

    canvas.restore();
  }

  static void _drawChinDetails(
    Canvas canvas,
    List<Offset> pts,
    double cx,
    double currentCy,
    double rotY,
    double pitch,
  ) {
    // 3D Floppy Drive Slot
    final slotP1 = const _Vec3(-7.5, 13.5, 15.2).rotateY(rotY).rotateX(pitch);
    final slotP2 = const _Vec3(7.5, 13.5, 15.2).rotateY(rotY).rotateX(pitch);
    final slotP3 = const _Vec3(7.5, 15.2, 15.2).rotateY(rotY).rotateX(pitch);
    final slotP4 = const _Vec3(-7.5, 15.2, 15.2).rotateY(rotY).rotateX(pitch);

    final slotPath =
        Path()
          ..moveTo(cx + slotP1.x, currentCy + slotP1.y)
          ..lineTo(cx + slotP2.x, currentCy + slotP2.y)
          ..lineTo(cx + slotP3.x, currentCy + slotP3.y)
          ..lineTo(cx + slotP4.x, currentCy + slotP4.y)
          ..close();

    final slotPaint = Paint()..color = const Color(0xFF262420);
    canvas.drawPath(slotPath, slotPaint);

    // Drive read activity LED (emerald green dot)
    final ledPt = const _Vec3(9.2, 14.3, 15.2).rotateY(rotY).rotateX(pitch);
    final ledPaint =
        Paint()
          ..color = const Color(0xFF00FF66)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.2);
    canvas.drawCircle(Offset(cx + ledPt.x, currentCy + ledPt.y), 1.2, ledPaint);

    // Retro Rainbow Badge (6 iconic stripes)
    const rainbowColors = [
      Color(0xFF61BB46), // Green
      Color(0xFFFDB827), // Yellow
      Color(0xFFF58220), // Orange
      Color(0xFFE03A3E), // Red
      Color(0xFF963D97), // Purple
      Color(0xFF009DDC), // Blue
    ];

    for (int s = 0; s < rainbowColors.length; s++) {
      final y0 = 12.8 + (s * 0.5);
      final y1 = y0 + 0.45;
      final b1 = _Vec3(-14.2, y0, 15.2).rotateY(rotY).rotateX(pitch);
      final b2 = _Vec3(-12.2, y0, 15.2).rotateY(rotY).rotateX(pitch);
      final b3 = _Vec3(-12.2, y1, 15.2).rotateY(rotY).rotateX(pitch);
      final b4 = _Vec3(-14.2, y1, 15.2).rotateY(rotY).rotateX(pitch);

      final badgePath =
          Path()
            ..moveTo(cx + b1.x, currentCy + b1.y)
            ..lineTo(cx + b2.x, currentCy + b2.y)
            ..lineTo(cx + b3.x, currentCy + b3.y)
            ..lineTo(cx + b4.x, currentCy + b4.y)
            ..close();

      canvas.drawPath(badgePath, Paint()..color = rainbowColors[s]);
    }
  }

  static void _drawBackVentilation(Canvas canvas, List<Offset> pts) {
    if (pts.length < 4) return;
    // Horizontal ventilation grille lines
    final pTopLeft = pts[1];
    final pTopRight = pts[2];
    final pBotLeft = pts[0];

    final ventPaint =
        Paint()
          ..color = const Color(0xFF5E574B)
          ..strokeWidth = 1.0;

    for (int i = 2; i <= 6; i++) {
      final frac = i / 10.0;
      final start = Offset.lerp(pTopLeft, pBotLeft, frac)!;
      final end = Offset.lerp(pTopRight, pts[3], frac)!;
      final leftInset = Offset.lerp(start, end, 0.22)!;
      final rightInset = Offset.lerp(start, end, 0.78)!;
      canvas.drawLine(leftInset, rightInset, ventPaint);
    }
  }

  static void _drawTopHandle(Canvas canvas, List<Offset> pts) {
    if (pts.length < 4) return;
    // Recessed carrying handle cavity
    final handleCenter = (pts[0] + pts[1] + pts[2] + pts[3]) / 4.0;
    final handlePaint =
        Paint()
          ..color = const Color(0xFF918A7C)
          ..style = PaintingStyle.fill;

    final handleRect = Rect.fromCenter(
      center: handleCenter,
      width: 14.0,
      height: 4.5,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(handleRect, const Radius.circular(2.0)),
      handlePaint,
    );
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

enum _FaceType { body, top, bottom, back, left, right, bezel, chin, screen }

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
  const _Face(
    this.vertices,
    this.normal,
    this.color, [
    this.type = _FaceType.body,
  ]);
  final List<_Vec3> vertices;
  final _Vec3 normal;
  final Color color;
  final _FaceType type;
}

class _RenderFace {
  const _RenderFace({
    required this.type,
    required this.projected,
    required this.avgZ,
    required this.diffuse,
    required this.color,
    required this.normal,
  });

  final _FaceType type;
  final List<Offset> projected;
  final double avgZ;
  final double diffuse;
  final Color color;
  final _Vec3 normal;
}
