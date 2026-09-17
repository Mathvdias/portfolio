import 'package:flutter_test/flutter_test.dart';
import 'package:lava_flutter/lava_flutter.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('LavaDemoBaker & LavaBundle', () {
    test('bakes procedural demo atlas and constructs LavaBundle', () async {
      final bundle = await LavaBundle.demo(forceRegenerate: true);

      expect(bundle.atlas.width, 768); // 6 cols * 128
      expect(bundle.atlas.height, 512); // 4 rows * 128
      expect(bundle.manifest.totalFrames, 24);
      expect(bundle.manifest.columns, 6);
      expect(bundle.manifest.rows, 4);
      expect(bundle.manifest.tileWidth, 128);
      expect(bundle.manifest.tileHeight, 128);

      LavaDemoBaker.clearCache();
    });

    test('reuses cached image across subsequent calls unless forced', () async {
      final bundle1 = await LavaBundle.demo();
      final bundle2 = await LavaBundle.demo();

      expect(identical(bundle1.atlas, bundle2.atlas), isTrue);

      LavaDemoBaker.clearCache();
    });
  });
}
