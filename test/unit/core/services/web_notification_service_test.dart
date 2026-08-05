import 'package:flutter_test/flutter_test.dart';
import 'package:portifolio/core/services/web_notification_service.dart';

void main() {
  group('WebNotificationService (Stub)', () {
    late WebNotificationService service;

    setUp(() {
      service = WebNotificationService();
    });

    test('requestPermission returns false on stub platform', () async {
      final result = await service.requestPermission();
      expect(result, isFalse);
    });

    test('showNotification runs without error on stub platform', () async {
      await expectLater(
        service.showNotification(title: 'Test', body: 'Test Body'),
        completes,
      );
    });
  });
}
