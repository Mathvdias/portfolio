// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:js' as js;

bool isCanvasKitActive() {
  return js.context['flutterCanvasKit'] != null;
}

String getRendererName() {
  final isCanvasKit = js.context['flutterCanvasKit'] != null;
  final isSkwasm = js.context['flutterSkwasm'] != null;
  if (isSkwasm) return 'Skwasm (GPU)';
  if (isCanvasKit) return 'CanvasKit (GPU)';
  return 'HTML (DOM)';
}
