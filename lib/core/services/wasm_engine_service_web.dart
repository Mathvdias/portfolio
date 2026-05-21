import 'dart:js_interop';
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
  external WebAssemblyExports get exports;
}

@JS()
extension type WebAssemblyExports._(JSObject _) implements JSObject {
  external WebAssemblyMemory get memory;
  @JS('get_buffer_pointer')
  external JSNumber getBufferPointer();
  @JS('get_buffer_size')
  external JSNumber getBufferSize();
  @JS('generate_mandelbrot')
  external void generateMandelbrot(
    JSNumber renderWidth,
    JSNumber renderHeight,
    JSNumber zoom,
    JSNumber offsetX,
    JSNumber offsetY,
    JSNumber maxIterations,
  );
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
      final fetchPromise = _fetch('assets/wasm/mathos_engine.wasm'.toJS);
      final instantiatePromise = _instantiateStreaming(fetchPromise);
      final jsResult =
          await instantiatePromise.toDart as WebAssemblyInstanceResult;
      _instance = jsResult.instance;
      _isReady = true;
    } catch (e) {
      debugPrint('Wasm initialization failed: $e');
    }
  }

  @override
  void generateMandelbrot({
    required int width,
    required int height,
    required double zoom,
    required double offsetX,
    required double offsetY,
    required int maxIterations,
  }) {
    if (!_isReady) return;
    final exports = _instance!.exports;

    exports.generateMandelbrot(
      width.toJS,
      height.toJS,
      zoom.toJS,
      offsetX.toJS,
      offsetY.toJS,
      maxIterations.toJS,
    );
  }

  @override
  Uint8List getPixelBuffer() {
    if (!_isReady) return Uint8List(0);
    final exports = _instance!.exports;

    final ptrVal = exports.getBufferPointer();
    final ptr = ptrVal.toDartInt;

    final sizeVal = exports.getBufferSize();
    final size = sizeVal.toDartInt;

    final memory = exports.memory;
    final buffer = memory.buffer.toDart;

    return Uint8List.view(buffer, ptr, size);
  }
}

WasmEngineService getService() => WasmEngineServiceImpl();
