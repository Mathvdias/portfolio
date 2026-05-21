import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:portifolio/app.dart';
import 'package:portifolio/core/bootstrap/app_bootstrap.dart';
import 'package:portifolio/core/result/result.dart';
import 'package:portifolio/core/services/analytics_service.dart';
import 'package:portifolio/features/visitors/domain/repositories/visitor_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _NoOpVisitorRepository implements VisitorRepository {
  @override
  Future<Result<void>> recordVisit() async => const Success(null);

  @override
  Stream<int> watchVisitorCount() => const Stream.empty();
}

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
    int? openWindowCount,
  }) async {}
  @override
  Future<void> logDeferredLoad({
    required String windowId,
    required int durationMs,
    required bool fromCache,
  }) async {}
  @override
  Future<void> logWindowDwellTime({
    required String windowId,
    required int seconds,
  }) async {}
  @override
  Future<void> logFirstWindow(String windowId) async {}
  @override
  Future<void> logLocaleView(String locale, {required bool initial}) async {}
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('App boots and renders desktop scaffold', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final config = AppConfig(
      prefs: prefs,
      analytics: _NoOpAnalytics(),
      visitorRepository: _NoOpVisitorRepository(),
    );

    await tester.pumpWidget(App(config: config));
    await tester.pumpAndSettle(const Duration(seconds: 2));

    expect(find.byType(MaterialApp), findsOneWidget);
    expect(find.byType(Scaffold), findsAtLeast(1));
  });
}
