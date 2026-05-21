import 'dart:typed_data';
import 'wasm_engine_service_stub.dart'
    if (dart.library.js_interop) 'wasm_engine_service_web.dart';

abstract class WasmEngineService {
  factory WasmEngineService() => getService();

  Future<void> init();
  bool get isReady;

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
  });

  /// Returns the pointer memory RGBA pixel buffer
  Uint8List getPixelBuffer();
}
