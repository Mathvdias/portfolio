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
}
