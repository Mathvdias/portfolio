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
