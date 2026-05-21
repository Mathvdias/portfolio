import 'wasm_engine_service_stub.dart'
    if (dart.library.js_interop) 'wasm_engine_service_web.dart';

abstract class WasmEngineService {
  factory WasmEngineService() => getService();
  
  Future<void> init();
  bool get isReady;
  
  void generateMandelbrot({
    required int width,
    required int height,
    required double zoom,
    required double offsetX,
    required double offsetY,
    required int maxIterations,
  });

  /// Returns the pointer memory RGBA pixel buffer
  List<int> getPixelBuffer();
}
