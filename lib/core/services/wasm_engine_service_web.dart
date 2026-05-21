import 'dart:js_interop';
import 'dart:js_interop_unsafe';

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
          debugPrint('Attempting to load Wasm from: $path');
          final fetchPromise = _fetch(path.toJS);
          final instantiatePromise = _instantiateStreaming(fetchPromise);
          final jsResult =
              await instantiatePromise.toDart as WebAssemblyInstanceResult;
          _instance = jsResult.instance;
          _isReady = true;
          debugPrint('Wasm loaded successfully from: $path');
          break;
        } catch (e) {
          lastError = e;
          debugPrint('Failed to load Wasm from $path: $e');
        }
      }

      if (!_isReady) {
        throw lastError ?? 'Unknown error';
      }
    } catch (e) {
      debugPrint('Wasm initialization failed entirely: $e');
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

    // We must call the WASM function directly via the property name
    // Since we have more than 4 arguments, we must use a helper or multiple callMethod calls if supported,
    // but callMethod supports up to 4 arguments in the basic version.
    // For WASM, the most compatible way in dart:js_interop is to use the Function object.
    final func = exports['generate_fractal'] as JSFunction;
    // Use callMethod on the function object itself, passing arguments
    // Note: JS interop extensions allow up to a certain number of args.
    // Since we have 10, we'll use a direct JS call to avoid argument limits.
    _callWasm(
      func,
      exports,
      width,
      height,
      zoom,
      offsetX,
      offsetY,
      maxIterations,
      isJulia,
      cxJulia,
      cyJulia,
      time,
    );
  }

  @override
  Uint8List getPixelBuffer() {
    if (!_isReady) return Uint8List(0);
    final exports = _instance!.exports;

    final ptr =
        (exports['get_buffer_pointer'] as JSFunction).callMethod(
              'call'.toJS,
              exports,
            )
            as JSNumber;
    final size =
        (exports['get_buffer_size'] as JSFunction).callMethod(
              'call'.toJS,
              exports,
            )
            as JSNumber;

    final memory = exports['memory'] as WebAssemblyMemory;
    final buffer = memory.buffer.toDart;

    return Uint8List.view(buffer, ptr.toDartInt, size.toDartInt);
  }
}

@JS('Function.prototype.apply.call')
external JSAny? _callWasmInternal(JSFunction f, JSObject thisArg, JSArray args);

void _callWasm(
  JSFunction f,
  JSObject thisArg,
  int width,
  int height,
  double zoom,
  double offsetX,
  double offsetY,
  int maxIterations,
  bool isJulia,
  double cxJulia,
  double cyJulia,
  double time,
) {
  final args =
      [
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
      ].toJS;
  _callWasmInternal(f, thisArg, args);
}

WasmEngineService getService() => WasmEngineServiceImpl();
