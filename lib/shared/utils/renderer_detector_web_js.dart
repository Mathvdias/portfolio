// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:js' as js;

bool isCanvasKitActive() {
  return js.context['flutterCanvasKit'] != null;
}

String getRendererName() {
  final isSkwasm = js.context['flutterSkwasm'] != null;
  final isCanvasKit = js.context['flutterCanvasKit'] != null;
  if (isSkwasm) return 'Skwasm GPU';
  if (isCanvasKit) return 'CanvasKit GPU';
  return 'HTML Renderer';
}

String getRendererDescription() {
  final isSkwasm = js.context['flutterSkwasm'] != null;
  final isCanvasKit = js.context['flutterCanvasKit'] != null;
  if (isSkwasm) return 'Dart WASM + Skia → WebGL → GPU';
  if (isCanvasKit) return 'Skia WASM → WebGL → GPU';
  return 'DOM · CSS · Canvas2D — no GPU shaders';
}

double getMemoryHeapSize() {
  try {
    final performance = js.context['performance'];
    if (performance != null && performance['memory'] != null) {
      final memory = performance['memory'];
      final used = memory['usedJSHeapSize'];
      if (used != null) {
        return (used as num).toDouble() / (1024 * 1024);
      }
    }
  } catch (_) {}
  return 18.2;
}

bool isSimdSupported() {
  try {
    final res =
        js.context.callMethod('eval', [
              'typeof WebAssembly !== "undefined" && WebAssembly.validate(new Uint8Array([0,97,115,109,1,0,0,0,1,5,1,96,0,0,3,2,1,0,10,9,1,7,0,65,0,253,15,26]))',
            ])
            as bool?;
    return res ?? false;
  } catch (_) {}
  return false;
}

bool isWasmGcSupported() {
  try {
    final res =
        js.context.callMethod('eval', [
              'typeof WebAssembly !== "undefined" && WebAssembly.validate(new Uint8Array([0,97,115,109,1,0,0,0,1,5,1,96,0,0,3,2,1,0,10,7,1,5,0,251,2,11]))',
            ])
            as bool?;
    return res ?? false;
  } catch (_) {}
  return false;
}

int getCpuCores() {
  try {
    final navigator = js.context['navigator'];
    if (navigator != null) {
      final cores = navigator['hardwareConcurrency'];
      if (cores != null) return (cores as num).toInt();
    }
  } catch (_) {}
  return 4;
}

double getDeviceMemoryGb() {
  try {
    final navigator = js.context['navigator'];
    if (navigator != null) {
      final mem = navigator['deviceMemory'];
      if (mem != null) return (mem as num).toDouble();
    }
  } catch (_) {}
  return 8.0;
}
