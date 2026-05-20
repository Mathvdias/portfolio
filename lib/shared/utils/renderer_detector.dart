import 'renderer_detector_stub.dart'
    if (dart.library.js) 'renderer_detector_web.dart';

bool isGpuRenderer() {
  return isCanvasKitActive();
}

String getRendererText() {
  return getRendererName();
}
