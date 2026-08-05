import 'package:flutter_test/flutter_test.dart';
import 'package:portifolio/shared/utils/renderer_detector.dart';

void main() {
  // In the test environment neither dart.library.js nor dart.library.js_interop
  // is active, so the stub implementation (native/non-web) is loaded.
  // Assertions reflect stub behaviour; the web_js and web_wasm files are
  // exercised by the browser-based integration environment.
  group('renderer_detector (stub — non-web environment)', () {
    test('isGpuRenderer returns false in test env', () {
      expect(isGpuRenderer(), isFalse);
    });

    test('getRendererText returns Native GPU label', () {
      expect(getRendererText(), 'Native GPU');
    });

    test('getRendererSubtitle returns Impeller/Skia pipeline description', () {
      final subtitle = getRendererSubtitle();
      expect(subtitle, isNotEmpty);
      expect(subtitle, contains('Metal'));
    });

    test('getJsHeapSize returns stub default', () {
      expect(getJsHeapSize(), 18.2);
    });

    test('isHardwareSimdSupported returns stub default', () {
      expect(isHardwareSimdSupported(), isTrue);
    });

    test('isHardwareWasmGcSupported returns stub default', () {
      expect(isHardwareWasmGcSupported(), isTrue);
    });

    test('getHardwareCpuCores returns stub default', () {
      expect(getHardwareCpuCores(), 8);
    });

    test('getHardwareDeviceMemory returns stub default', () {
      expect(getHardwareDeviceMemory(), 8.0);
    });
  });
}
