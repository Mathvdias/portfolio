import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:portifolio/app.dart';
import 'package:portifolio/core/bootstrap/app_bootstrap.dart';
import 'package:portifolio/core/services/analytics_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _NoOpAnalytics implements AnalyticsService {
  @override
  Future<void> logWindowOpen(String windowId) async {}
  @override
  Future<void> logWindowClose(String windowId) async {}
  @override
  Future<void> logLinkClick(String destination, String url) async {}
  @override
  Future<void> logResumeDownload() async {}
  @override
  Future<void> logLocaleChange(String locale) async {}
  @override
  Future<void> logSpotlightOpen() async {}
  @override
  Future<void> logSpotlightSelect(String windowId) async {}
  @override
  Future<void> logContextMenuOpen() async {}
  @override
  Future<void> logContextMenuAction(String action) async {}
  @override
  Future<void> logGuestbookPost(int rating) async {}
  @override
  Future<void> logError(
    String errorType,
    String message, {
    String? stackTrace,
  }) async {}
  @override
  Future<void> logJankFrame({
    required int totalMs,
    required int buildMs,
    required int rasterMs,
  }) async {}
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('App boots and renders desktop scaffold', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final config = AppConfig(prefs: prefs, analytics: _NoOpAnalytics());

    await tester.pumpWidget(App(config: config));
    await tester.pumpAndSettle(const Duration(seconds: 2));

    expect(find.byType(MaterialApp), findsOneWidget);
    expect(find.byType(Scaffold), findsAtLeast(1));
  });
}
