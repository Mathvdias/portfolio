import 'dart:convert';
import 'dart:ui' as ui;
import 'package:flutter/services.dart';

import '../demo/lava_demo_baker.dart';
import '../model/lava_manifest.dart';
import '../model/lava_types.dart';

/// Container encapsulating a decoded texture atlas [ui.Image] and its
/// associated [LavaManifest] layout parameters.
class LavaBundle {
  const LavaBundle({
    this.atlas,
    this.images = const [],
    required this.manifest,
  });

  /// Hardware texture holding animation frames for single-atlas grid mode.
  final ui.Image? atlas;

  /// Multi-image hardware textures for OpenLava diff mode.
  final List<ui.Image> images;

  /// Structural layout and timing metadata.
  final LavaManifest manifest;

  /// Asset directory (inside the host application) holding the OpenLava bundle
  /// for each built-in [LavaDemoType].
  static const Map<LavaDemoType, String> demoAssetPaths = {
    LavaDemoType.macintosh: 'assets/lava/macintosh',
    LavaDemoType.sunflower: 'assets/lava/sunflower',
    LavaDemoType.lavaLamp: 'assets/lava/lavalamp',
    LavaDemoType.campfire: 'assets/lava/campfire',
    LavaDemoType.rocket: 'assets/lava/rocket',
    LavaDemoType.senna: 'assets/lava/senna',
    LavaDemoType.christmasTree: 'assets/lava/christmastree',
  };

  /// Loads the built-in demo bundle for [type].
  ///
  /// Every demo is an OpenLava diff tileset (`manifest.json` + `image_1.png`
  /// key frame + `image_2.png` diff atlas) declared by the host application
  /// under [demoAssetPaths]. When the asset directory is not bundled (for
  /// example inside the package's own tests) the Macintosh and sunflower icons fall
  /// back to the procedural [LavaDemoBaker] atlas via [procedural].
  static Future<LavaBundle> demo({
    LavaDemoType type = LavaDemoType.macintosh,
    bool forceRegenerate = false,
    AssetBundle? bundle,
  }) async {
    try {
      return await openLavaAsset(
        assetPath: demoAssetPaths[type]!,
        bundle: bundle,
      );
    } catch (_) {
      switch (type) {
        case LavaDemoType.macintosh:
        case LavaDemoType.sunflower:
          return procedural(type: type, forceRegenerate: forceRegenerate);
        case LavaDemoType.lavaLamp:
        case LavaDemoType.campfire:
        case LavaDemoType.rocket:
        case LavaDemoType.senna:
        case LavaDemoType.christmasTree:
          rethrow;
      }
    }
  }

  /// Bakes the procedural Canvas-rendered demo atlas for [type]
  /// (only [LavaDemoType.macintosh] and [LavaDemoType.sunflower] are supported;
  /// the sunflower falls back to the procedural nature tree).
  static Future<LavaBundle> procedural({
    LavaDemoType type = LavaDemoType.macintosh,
    bool forceRegenerate = false,
  }) async {
    assert(
      type == LavaDemoType.macintosh || type == LavaDemoType.sunflower,
      'Only the Macintosh and sunflower demos have a procedural renderer.',
    );
    final image = await LavaDemoBaker.bakeAtlas(
      type: type,
      forceRegenerate: forceRegenerate,
    );
    return LavaBundle(atlas: image, manifest: LavaDemoBaker.defaultManifest);
  }

  /// Convenience shortcut to load the sunflower demo bundle.
  static Future<LavaBundle> demoSunflower({bool forceRegenerate = false}) =>
      demo(type: LavaDemoType.sunflower, forceRegenerate: forceRegenerate);

  /// Loads an OpenLava format animation directory containing `manifest.json` and image tilesets.
  static Future<LavaBundle> openLavaAsset({
    required String assetPath,
    AssetBundle? bundle,
  }) async {
    final effectiveBundle = bundle ?? rootBundle;

    final jsonStr = await effectiveBundle.loadString(
      '$assetPath/manifest.json',
    );
    final manifestJson = jsonDecode(jsonStr) as Map<String, dynamic>;
    final manifest = LavaManifest.fromJson(manifestJson);

    final loadedImages = <ui.Image>[];
    for (final imgName in manifest.images) {
      final byteData = await effectiveBundle.load('$assetPath/$imgName');
      final bytes = byteData.buffer.asUint8List(
        byteData.offsetInBytes,
        byteData.lengthInBytes,
      );
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      codec.dispose();
      loadedImages.add(frame.image);
    }

    return LavaBundle(
      images: loadedImages,
      atlas: loadedImages.isNotEmpty ? loadedImages.first : null,
      manifest: manifest,
    );
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
    atlas?.dispose();
    for (final img in images) {
      if (img != atlas) {
        img.dispose();
      }
    }
  }
}
