import 'package:firebase_analytics/firebase_analytics.dart';

import 'analytics_service.dart';

class FirebaseAnalyticsService implements AnalyticsService {
  FirebaseAnalyticsService(this._analytics);

  final FirebaseAnalytics _analytics;

  @override
  Future<void> logWindowOpen(String windowId) => _analytics.logEvent(
    name: 'window_open',
    parameters: {'window_id': windowId},
  );

  @override
  Future<void> logWindowClose(String windowId) => _analytics.logEvent(
    name: 'window_close',
    parameters: {'window_id': windowId},
  );

  @override
  Future<void> logLinkClick(String destination, String url) =>
      _analytics.logEvent(
        name: 'link_click',
        parameters: {'destination': destination, 'url': url},
      );

  @override
  Future<void> logResumeDownload() =>
      _analytics.logEvent(name: 'resume_download');

  @override
  Future<void> logLocaleChange(String locale) => _analytics.logEvent(
    name: 'locale_change',
    parameters: {'locale': locale},
  );

  @override
  Future<void> logSpotlightOpen() =>
      _analytics.logEvent(name: 'spotlight_open');

  @override
  Future<void> logSpotlightSelect(String windowId) => _analytics.logEvent(
    name: 'spotlight_select',
    parameters: {'window_id': windowId},
  );

  @override
  Future<void> logContextMenuOpen() =>
      _analytics.logEvent(name: 'context_menu_open');

  @override
  Future<void> logContextMenuAction(String action) => _analytics.logEvent(
    name: 'context_menu_action',
    parameters: {'action': action},
  );

  @override
  Future<void> logGuestbookPost(int rating) => _analytics.logEvent(
    name: 'guestbook_post',
    parameters: {'rating': rating},
  );

  @override
  Future<void> logError(
    String errorType,
    String message, {
    String? stackTrace,
  }) => _analytics.logEvent(
    name: 'app_error',
    parameters: {
      'error_type': _cap(errorType, 40),
      'message': _cap(message, 100),
      if (stackTrace != null) 'stack_trace': _cap(stackTrace, 100),
    },
  );

  @override
  Future<void> logJankFrame({
    required int totalMs,
    required int buildMs,
    required int rasterMs,
    int? openWindowCount,
  }) => _analytics.logEvent(
    name: 'jank_frame',
    parameters: {
      'total_ms': totalMs,
      'build_ms': buildMs,
      'raster_ms': rasterMs,
      if (openWindowCount != null) 'open_windows': openWindowCount,
    },
  );

  @override
  Future<void> logDeferredLoad({
    required String windowId,
    required int durationMs,
    required bool fromCache,
  }) => _analytics.logEvent(
    name: 'deferred_load',
    parameters: {
      'window_id': windowId,
      'duration_ms': durationMs,
      'from_cache': fromCache ? 1 : 0,
    },
  );

  @override
  Future<void> logWindowDwellTime({
    required String windowId,
    required int seconds,
  }) => _analytics.logEvent(
    name: 'window_dwell',
    parameters: {'window_id': windowId, 'seconds': seconds},
  );

  @override
  Future<void> logFirstWindow(String windowId) => _analytics.logEvent(
    name: 'first_window',
    parameters: {'window_id': windowId},
  );

  static String _cap(String s, int max) =>
      s.length <= max ? s : s.substring(0, max);
}
