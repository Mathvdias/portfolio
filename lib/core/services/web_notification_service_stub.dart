import 'web_notification_service.dart';

class WebNotificationServiceImpl implements WebNotificationService {
  @override
  Future<void> requestPermission() async {
    // No-op
  }

  @override
  Future<void> showNotification({
    required String title,
    required String body,
  }) async {
    // No-op on unsupported platforms (like tests)
  }
}

WebNotificationService getService() => WebNotificationServiceImpl();
