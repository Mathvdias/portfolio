// WASM builds (dart2wasm / --wasm flag) always use Skwasm:
// Skia compiled to WebAssembly, rendering via WebGL → GPU.
// There is no alternative renderer in a WASM build, so no runtime check needed.
bool isCanvasKitActive() => true;
String getRendererName() => 'Skwasm GPU';
String getRendererDescription() => 'Dart WASM + Skia → WebGL → GPU';
