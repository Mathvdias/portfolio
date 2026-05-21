import 'wasm_engine_service.dart';

class WasmEngineServiceImpl implements WasmEngineService {
  @override
  Future<void> init() async {}

  @override
  bool get isReady => false;

  @override
  void generateMandelbrot({
    required int width,
    required int height,
    required double zoom,
    required double offsetX,
    required double offsetY,
    required int maxIterations,
  }) {}

  @override
  List<int> getPixelBuffer() => [];
}

WasmEngineService getService() => WasmEngineServiceImpl();
