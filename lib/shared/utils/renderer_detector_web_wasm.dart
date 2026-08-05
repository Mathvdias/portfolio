import 'dart:js_interop';

@JS()
@staticInterop
class Performance {}

extension PerformanceExtension on Performance {
  external PerformanceMemory? get memory;
}

@JS()
@staticInterop
class PerformanceMemory {}

extension PerformanceMemoryExtension on PerformanceMemory {
  external double get usedJSHeapSize;
}

@JS('performance')
external Performance? get performance;

@JS('eval')
external JSAny? _jsEval(JSString code);

bool isCanvasKitActive() => true;
String getRendererName() => 'Skwasm GPU';
String getRendererDescription() => 'Dart WASM + Skia → WebGL → GPU';

double getMemoryHeapSize() {
  try {
    final perf = performance;
    if (perf != null) {
      final mem = perf.memory;
      if (mem != null) {
        return mem.usedJSHeapSize / (1024 * 1024);
      }
    }
  } catch (_) {}
  return 18.2;
}

bool isSimdSupported() {
  try {
    final res = _jsEval(
      'typeof WebAssembly !== "undefined" && WebAssembly.validate(new Uint8Array([0,97,115,109,1,0,0,0,1,5,1,96,0,0,3,2,1,0,10,9,1,7,0,65,0,253,15,26]))'
          .toJS,
    );
    return (res as JSBoolean).toDart;
  } catch (_) {}
  return false;
}

bool isWasmGcSupported() {
  try {
    final res = _jsEval(
      'typeof WebAssembly !== "undefined" && WebAssembly.validate(new Uint8Array([0,97,115,109,1,0,0,0,1,5,1,96,0,0,3,2,1,0,10,7,1,5,0,251,2,11]))'
          .toJS,
    );
    return (res as JSBoolean).toDart;
  } catch (_) {}
  return false;
}

int getCpuCores() {
  try {
    final res = _jsEval('navigator.hardwareConcurrency || 4'.toJS);
    return (res as JSNumber).toDartInt;
  } catch (_) {}
  return 4;
}

double getDeviceMemoryGb() {
  try {
    final res = _jsEval('navigator.deviceMemory || 8'.toJS);
    return (res as JSNumber).toDartDouble;
  } catch (_) {}
  return 8.0;
}
