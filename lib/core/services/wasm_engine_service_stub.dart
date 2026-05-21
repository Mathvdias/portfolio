import 'dart:typed_data';

import 'wasm_engine_service.dart';

class WasmEngineServiceImpl implements WasmEngineService {
  @override
  bool get isReady => false;

  @override
  Future<void> init() async {}

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
  }) {}

  @override
  Uint8List getPixelBuffer() => Uint8List(0);
}

WasmEngineService getService() => WasmEngineServiceImpl();
