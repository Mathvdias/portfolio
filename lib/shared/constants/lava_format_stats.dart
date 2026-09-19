// Measured on 2026-09-18 by encoding the same frames of every icon with ffmpeg (GIF with an
// optimal palette, APNG), Pillow (animated WebP q90) and tool/openlava_encode.py (Lava bundles).
// Regenerate after re-encoding a bundle: the numbers are shown as-is in the Lava Studio.
import 'package:lava_flutter/lava_flutter.dart';

/// On-disk size in bytes of one icon animation in each container.
class LavaFormatStats {
  const LavaFormatStats({
    required this.frames,
    required this.pngSequence,
    required this.apng,
    required this.gif,
    required this.animatedWebp,
    required this.lavaAvif,
    required this.lavaWebp,
    required this.lavaHdAvif,
  });

  final int frames;
  final int pngSequence;
  final int apng;
  final int gif;
  final int animatedWebp;
  final int lavaAvif;
  final int lavaWebp;
  final int lavaHdAvif;

  static const Map<LavaDemoType, LavaFormatStats> byIcon = {
    LavaDemoType.macintosh: LavaFormatStats(
      frames: 48,
      pngSequence: 696823,
      apng: 664201,
      gif: 227727,
      animatedWebp: 207132,
      lavaAvif: 118425,
      lavaWebp: 172349,
      lavaHdAvif: 216481,
    ),
    LavaDemoType.sunflower: LavaFormatStats(
      frames: 48,
      pngSequence: 695974,
      apng: 610730,
      gif: 180768,
      animatedWebp: 223810,
      lavaAvif: 148765,
      lavaWebp: 129159,
      lavaHdAvif: 209705,
    ),
    LavaDemoType.lavaLamp: LavaFormatStats(
      frames: 48,
      pngSequence: 463887,
      apng: 199532,
      gif: 153867,
      animatedWebp: 68934,
      lavaAvif: 66627,
      lavaWebp: 63508,
      lavaHdAvif: 82393,
    ),
    LavaDemoType.campfire: LavaFormatStats(
      frames: 48,
      pngSequence: 2170230,
      apng: 1838843,
      gif: 604034,
      animatedWebp: 535420,
      lavaAvif: 283545,
      lavaWebp: 348220,
      lavaHdAvif: 527974,
    ),
    LavaDemoType.rocket: LavaFormatStats(
      frames: 48,
      pngSequence: 610090,
      apng: 492692,
      gif: 176338,
      animatedWebp: 178288,
      lavaAvif: 125496,
      lavaWebp: 134804,
      lavaHdAvif: 221215,
    ),
    LavaDemoType.senna: LavaFormatStats(
      frames: 72,
      pngSequence: 1110027,
      apng: 1175918,
      gif: 411452,
      animatedWebp: 352180,
      lavaAvif: 240571,
      lavaWebp: 369192,
      lavaHdAvif: 394422,
    ),
    LavaDemoType.christmasTree: LavaFormatStats(
      frames: 60,
      pngSequence: 1792592,
      apng: 1794549,
      gif: 496932,
      animatedWebp: 539844,
      lavaAvif: 393352,
      lavaWebp: 386796,
      lavaHdAvif: 745846,
    ),
    LavaDemoType.f1Car: LavaFormatStats(
      frames: 48,
      pngSequence: 1478368,
      apng: 1027664,
      gif: 429886,
      animatedWebp: 372502,
      lavaAvif: 116500,
      lavaWebp: 179018,
      lavaHdAvif: 180524,
    ),
    LavaDemoType.f1Front: LavaFormatStats(
      frames: 72,
      pngSequence: 2955830,
      apng: 197103,
      gif: 907933,
      animatedWebp: 67346,
      lavaAvif: 28424,
      lavaWebp: 36195,
      lavaHdAvif: 50432,
    ),
    LavaDemoType.sennaMp4: LavaFormatStats(
      frames: 36,
      pngSequence: 1107127,
      apng: 261752,
      gif: 286108,
      animatedWebp: 176598,
      lavaAvif: 98358,
      lavaWebp: 99531,
      lavaHdAvif: 170443,
    ),
  };
}
