// Conditional import strategy:
//   dart.library.js       → JS build (dart2js)   → uses dart:js
//   dart.library.js_interop (fallback) → WASM build (dart2wasm) → static Skwasm
//   neither              → native                → stub (Impeller/Skia)
//
// NOTE: dart.library.js is false in WASM builds because dart:js is unavailable.
// dart.library.js_interop is true in BOTH JS and WASM builds, so the second
// condition only fires when the first has already failed (i.e. WASM only).
import 'renderer_detector_stub.dart'
    if (dart.library.js) 'renderer_detector_web_js.dart'
    if (dart.library.js_interop) 'renderer_detector_web_wasm.dart';

bool isGpuRenderer() => isCanvasKitActive();

String getRendererText() => getRendererName();

String getRendererSubtitle() => getRendererDescription();
