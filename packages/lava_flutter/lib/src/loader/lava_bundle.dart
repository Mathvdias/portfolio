import 'dart:convert';
import 'dart:ui' as ui;
import 'package:flutter/services.dart';

import '../demo/lava_demo_baker.dart';
import '../model/lava_manifest.dart';

/// Container encapsulating a decoded texture atlas [ui.Image] and its
/// associated [LavaManifest] layout parameters.
class LavaBundle {
  const LavaBundle({required this.atlas, required this.manifest});

  /// Hardware texture holding animation frames.
  final ui.Image atlas;

  /// Structural layout and timing metadata.
  final LavaManifest manifest;

  /// Loads the procedurally generated 3D demo icon bundle.
  static Future<LavaBundle> demo({bool forceRegenerate = false}) async {
    final image = await LavaDemoBaker.bakeAtlas(
      forceRegenerate: forceRegenerate,
    );
    return LavaBundle(atlas: image, manifest: LavaDemoBaker.defaultManifest);
  }

  /// Loads a [LavaBundle] from application asset files.
  static Future<LavaBundle> fromAsset({
    required String imageAsset,
    required String manifestAsset,
    AssetBundle? bundle,
  }) async {
    final effectiveBundle = bundle ?? rootBundle;

    final jsonStr = await effectiveBundle.loadString(manifestAsset);
    final manifestJson = jsonDecode(jsonStr) as Map<String, dynamic>;
    final manifest = LavaManifest.fromJson(manifestJson);

    final byteData = await effectiveBundle.load(imageAsset);
    final bytes = byteData.buffer.asUint8List(
      byteData.offsetInBytes,
      byteData.lengthInBytes,
    );

    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    codec.dispose();

    return LavaBundle(atlas: frame.image, manifest: manifest);
  }

  /// Creates a [LavaBundle] from raw in-memory encoded image bytes.
  static Future<LavaBundle> fromMemory({
    required Uint8List imageBytes,
    required LavaManifest manifest,
  }) async {
    final codec = await ui.instantiateImageCodec(imageBytes);
    final frame = await codec.getNextFrame();
    codec.dispose();

    return LavaBundle(atlas: frame.image, manifest: manifest);
  }

  /// Releases the GPU texture resources.
  void dispose() {
    atlas.dispose();
  }
}
