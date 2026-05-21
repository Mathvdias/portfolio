import 'package:flutter_test/flutter_test.dart';
import 'package:portifolio/shared/utils/renderer_detector.dart';

void main() {
  // In the test environment the stub implementation is loaded
  // (dart.library.js is absent), so all assertions reflect stub behaviour.
  group('renderer_detector (stub — non-web environment)', () {
    test('isGpuRenderer returns false in test env', () {
      expect(isGpuRenderer(), isFalse);
    });

    test('getRendererText returns Native GPU label', () {
      expect(getRendererText(), 'Native GPU');
    });

    test('getRendererSubtitle returns pipeline description', () {
      final subtitle = getRendererSubtitle();
      expect(subtitle, isNotEmpty);
      expect(subtitle, contains('Metal'));
    });
  });
}
