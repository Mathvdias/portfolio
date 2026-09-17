import 'package:flutter_test/flutter_test.dart';
import 'package:lava_flutter/src/model/lava_manifest.dart';

void main() {
  group('LavaManifest', () {
    test('parses complete JSON correctly', () {
      final json = {
        'version': 1,
        'frameRate': 60,
        'tileWidth': 128,
        'tileHeight': 128,
        'columns': 6,
        'rows': 4,
        'totalFrames': 24,
        'loop': true,
        'loopStartFrame': 2,
        'loopEndFrame': 22,
      };

      final manifest = LavaManifest.fromJson(json);

      expect(manifest.version, 1);
      expect(manifest.frameRate, 60);
      expect(manifest.tileWidth, 128);
      expect(manifest.tileHeight, 128);
      expect(manifest.columns, 6);
      expect(manifest.rows, 4);
      expect(manifest.totalFrames, 24);
      expect(manifest.loop, isTrue);
      expect(manifest.loopStartFrame, 2);
      expect(manifest.loopEndFrame, 22);
      expect(manifest.frameDuration.inMilliseconds, closeTo(16, 1));
      expect(manifest.totalDuration.inMilliseconds, closeTo(400, 10));
    });

    test('applies safe defaults when optional fields are omitted', () {
      final json = {'tileWidth': 64, 'tileHeight': 64, 'columns': 4, 'rows': 4};

      final manifest = LavaManifest.fromJson(json);

      expect(manifest.version, 1);
      expect(manifest.frameRate, 30);
      expect(manifest.totalFrames, 16);
      expect(manifest.loop, isTrue);
      expect(manifest.loopStartFrame, 0);
      expect(manifest.loopEndFrame, 15);
    });

    test('serializes to JSON and round-trips identically', () {
      const original = LavaManifest(
        tileWidth: 48,
        tileHeight: 48,
        columns: 4,
        rows: 3,
        totalFrames: 12,
        frameRate: 24,
        loop: false,
      );

      final serialized = original.toJson();
      final reconstructed = LavaManifest.fromJson(serialized);

      expect(reconstructed, equals(original));
      expect(reconstructed.hashCode, equals(original.hashCode));
    });

    test('copyWith creates modified copy correctly', () {
      const original = LavaManifest(
        tileWidth: 64,
        tileHeight: 64,
        columns: 4,
        rows: 4,
        totalFrames: 16,
      );

      final modified = original.copyWith(frameRate: 45, loop: false);

      expect(modified.frameRate, 45);
      expect(modified.loop, isFalse);
      expect(modified.tileWidth, original.tileWidth);
    });
  });
}
