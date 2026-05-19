import 'dart:ui' as ui;

/// Central registry for all fragment shaders used by the app.
///
/// Calling [preloadAll] during bootstrap fires all [FragmentProgram.fromAsset]
/// calls in parallel (via [Future.wait]) so the compiled programs are ready
/// before any widget mounts.  Each widget still uses the same cached Future —
/// the `??=` guards in [get] ensure no double-compilation ever happens.
abstract final class ShaderRegistry {
  static final Map<String, Future<ui.FragmentProgram>> _cache = {};

  /// Returns a shared Future for [assetPath], compiling once on first call.
  static Future<ui.FragmentProgram> get(String assetPath) =>
      _cache.putIfAbsent(
          assetPath, () => ui.FragmentProgram.fromAsset(assetPath));

  /// Fire all known shaders in parallel.  Safe to call before any widget
  /// mounts — errors are swallowed per-shader so one failure doesn't block
  /// the rest (e.g. shader unavailable in a minimal test environment).
  static Future<void> preloadAll() => Future.wait(
        [
          'shaders/icons.frag',
          'shaders/wallpaper.frag',
          'shaders/pixelate.frag',
          'shaders/glow.frag',
          'shaders/crt.frag',
        ].map(_tryGet),
        eagerError: false,
      );

  /// Loads one shader and silently swallows errors so a missing shader in
  /// a test or restricted environment never blocks the others.
  static Future<void> _tryGet(String path) async {
    try {
      await get(path);
    } catch (_) {
      // Unavailable (test host, no GPU) — widget will use its fallback.
    }
  }
}
