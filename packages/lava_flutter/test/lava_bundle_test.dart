import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lava_flutter/lava_flutter.dart';

class _MissingAssetBundle extends Fake implements AssetBundle {
  @override
  Future<String> loadString(String key, {bool cache = true}) async {
    throw Exception('Asset not found: $key');
  }

  @override
  Future<ByteData> load(String key) async {
    throw Exception('Asset not found: $key');
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('LavaDemoBaker & LavaBundle', () {
    test('bakes procedural demo atlas and constructs LavaBundle', () async {
      final bundle = await LavaBundle.procedural(forceRegenerate: true);

      expect(bundle.atlas!.width, 768); // 6 cols * 128
      expect(bundle.atlas!.height, 512); // 4 rows * 128
      expect(bundle.manifest.totalFrames, 24);
      expect(bundle.manifest.columns, 6);
      expect(bundle.manifest.rows, 4);
      expect(bundle.manifest.tileWidth, 128);
      expect(bundle.manifest.tileHeight, 128);

      LavaDemoBaker.clearCache();
    });

    test('reuses cached image across subsequent calls unless forced', () async {
      final bundle1 = await LavaBundle.procedural();
      final bundle2 = await LavaBundle.procedural();

      expect(identical(bundle1.atlas, bundle2.atlas), isTrue);

      LavaDemoBaker.clearCache();
    });

    test('demo() falls back to the procedural atlas when the OpenLava asset '
        'directory is not bundled', () async {
      final bundle = await LavaBundle.demo(
        type: LavaDemoType.sunflower,
        bundle: _MissingAssetBundle(),
      );

      expect(bundle.images, isEmpty);
      expect(bundle.atlas, isNotNull);
      expect(bundle.manifest, LavaDemoBaker.defaultManifest);

      LavaDemoBaker.clearCache();
    });

    test(
      'demo() rethrows for campfire when assets are missing',
      () async {
        expect(
          () => LavaBundle.demo(
            type: LavaDemoType.campfire,
            bundle: _MissingAssetBundle(),
          ),
          throwsA(isA<Object>()),
        );
      },
    );

    test(
      'demo() rethrows for senna and christmasTree when assets are missing',
      () async {
        expect(
          () => LavaBundle.demo(
            type: LavaDemoType.senna,
            bundle: _MissingAssetBundle(),
          ),
          throwsA(isA<Object>()),
        );
        expect(
          () => LavaBundle.demo(
            type: LavaDemoType.christmasTree,
            bundle: _MissingAssetBundle(),
          ),
          throwsA(isA<Object>()),
        );
      },
    );
  });
}
