abstract class AnalyticsService {
  Future<void> logWindowOpen(String windowId);
  Future<void> logWindowClose(String windowId);
  Future<void> logLinkClick(String destination, String url);
  Future<void> logResumeDownload();
  Future<void> logLocaleChange(String locale);

  /// Logs which locale was active when the desktop loaded (initial) or after
  /// the user explicitly changed it (changed). Use to measure real language
  /// distribution across sessions, not just switcher engagement.
  Future<void> logLocaleView(String locale, {required bool initial});
  Future<void> logSpotlightOpen();
  Future<void> logSpotlightSelect(String windowId);
  Future<void> logContextMenuOpen();
  Future<void> logContextMenuAction(String action);
  Future<void> logGuestbookPost(int rating);

  /// Logs an unhandled error. [errorType] identifies the source
  /// ('flutter_error' or 'dart_error'). Strings are capped at 100 chars
  /// to stay within Firebase Analytics parameter limits.
  Future<void> logError(String errorType, String message, {String? stackTrace});

  /// Logs a severe jank frame (> 32 ms total). Callers are responsible for
  /// throttling so this is not fired on every frame.
  Future<void> logJankFrame({
    required int totalMs,
    required int buildMs,
    required int rasterMs,
    int? openWindowCount,
  });

  /// Logs how long a deferred JS bundle took to load.
  Future<void> logDeferredLoad({
    required String windowId,
    required int durationMs,
    required bool fromCache,
  });

  /// Logs how long a user kept a window open before closing it.
  Future<void> logWindowDwellTime({
    required String windowId,
    required int seconds,
  });

  /// Logs which window the user opens first in a session.
  Future<void> logFirstWindow(String windowId);
}
