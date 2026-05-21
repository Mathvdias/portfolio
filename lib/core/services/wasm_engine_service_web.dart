import 'dart:js_interop';
import 'dart:js_interop_unsafe';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';

import 'wasm_engine_service.dart';

@JS('fetch')
external JSPromise _fetch(JSString url);

@JS('WebAssembly.instantiateStreaming')
external JSPromise _instantiateStreaming(JSAny source);

@JS()
extension type WebAssemblyInstanceResult._(JSObject _) implements JSObject {
  external WebAssemblyInstance get instance;
}

@JS()
extension type WebAssemblyInstance._(JSObject _) implements JSObject {
  external JSObject get exports;
}

@JS()
extension type WebAssemblyMemory._(JSObject _) implements JSObject {
  external JSArrayBuffer get buffer;
}

class WasmEngineServiceImpl implements WasmEngineService {
  WebAssemblyInstance? _instance;
  bool _isReady = false;

  @override
  bool get isReady => _isReady;

  @override
  Future<void> init() async {
    if (_isReady) return;
    try {
      final paths = [
        'assets/wasm/mathos_engine.wasm',
        'assets/assets/wasm/mathos_engine.wasm',
      ];

      Object? lastError;
      for (final path in paths) {
        try {
          debugPrint('Attempting to load Wasm from: \$path');
          final fetchPromise = _fetch(path.toJS);
          final instantiatePromise = _instantiateStreaming(fetchPromise);
          final jsResult =
              await instantiatePromise.toDart as WebAssemblyInstanceResult;
          _instance = jsResult.instance;
          _isReady = true;
          debugPrint('Wasm loaded successfully from: \$path');
          break;
        } catch (e) {
          lastError = e;
          debugPrint('Failed to load Wasm from \$path: \$e');
        }
      }

      if (!_isReady) {
        throw lastError ?? 'Unknown error';
      }
    } catch (e) {
      debugPrint('Wasm initialization failed entirely: \$e');
    }
  }

  @override
  void generateFractal({
    required int width,
    required int height,
    required double zoom,
    required double offsetX,
    required double offsetY,
    required int maxIterations,
    required bool isJulia,
    required double cxJulia,
    required double cyJulia,
    required double time,
  }) {
    if (!_isReady) return;
    final exports = _instance!.exports;

    exports.callMethod(
      'generate_fractal'.toJS,
      width.toJS,
      height.toJS,
      zoom.toJS,
      offsetX.toJS,
      offsetY.toJS,
      maxIterations.toJS,
      isJulia.toJS,
      cxJulia.toJS,
      cyJulia.toJS,
      time.toJS,
    );
  }

  @override
  Uint8List getPixelBuffer() {
    if (!_isReady) return Uint8List(0);
    final exports = _instance!.exports;

    final ptrVal = exports.callMethod('get_buffer_pointer'.toJS) as JSNumber;
    final ptr = ptrVal.toDartInt;

    final sizeVal = exports.callMethod('get_buffer_size'.toJS) as JSNumber;
    final size = sizeVal.toDartInt;

    final memory = exports.getProperty<WebAssemblyMemory>('memory'.toJS);
    final buffer = memory.buffer.toDart;

    return Uint8List.view(buffer, ptr, size);
  }
}

WasmEngineService getService() => WasmEngineServiceImpl();
