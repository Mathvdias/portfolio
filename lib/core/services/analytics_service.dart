abstract class AnalyticsService {
  Future<void> logWindowOpen(String windowId);
  Future<void> logWindowClose(String windowId);
  Future<void> logLinkClick(String destination, String url);
  Future<void> logResumeDownload();
  Future<void> logLocaleChange(String locale);
  Future<void> logSpotlightOpen();
  Future<void> logSpotlightSelect(String windowId);
  Future<void> logContextMenuOpen();
  Future<void> logContextMenuAction(String action);
  Future<void> logGuestbookPost(int rating);
}
