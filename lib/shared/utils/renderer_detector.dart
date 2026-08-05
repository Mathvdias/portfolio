import 'renderer_detector_stub.dart'
    if (dart.library.js) 'renderer_detector_web_js.dart'
    if (dart.library.js_interop) 'renderer_detector_web_wasm.dart';

bool isGpuRenderer() => isCanvasKitActive();

String getRendererText() => getRendererName();

String getRendererSubtitle() => getRendererDescription();

double getJsHeapSize() => getMemoryHeapSize();

bool isHardwareSimdSupported() => isSimdSupported();

bool isHardwareWasmGcSupported() => isWasmGcSupported();

int getHardwareCpuCores() => getCpuCores();

double getHardwareDeviceMemory() => getDeviceMemoryGb();
