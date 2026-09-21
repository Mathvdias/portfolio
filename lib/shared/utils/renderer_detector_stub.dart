import 'dart:io';

bool isCanvasKitActive() => false;
String getRendererName() => 'Native GPU';
String getRendererDescription() => 'Impeller / Skia → Metal · Vulkan · OpenGL';

// Off the web there is no JS heap, no WebAssembly and no navigator: 0 / false
// mean "not available", the same convention the web implementations use.
double getMemoryHeapSize() => 0.0;
bool isSimdSupported() => false;
bool isWasmGcSupported() => false;
int getCpuCores() => Platform.numberOfProcessors;
double getDeviceMemoryGb() => 0.0;
