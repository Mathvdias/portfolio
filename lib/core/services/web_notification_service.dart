import 'web_notification_service_stub.dart'
    if (dart.library.js_interop) 'web_notification_service_web.dart';

abstract class WebNotificationService {
  factory WebNotificationService() => getService();
  
  Future<void> showNotification({
    required String title,
    required String body,
  });
}
