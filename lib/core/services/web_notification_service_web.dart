import 'dart:js_interop';
import 'dart:js_interop_unsafe';
import 'web_notification_service.dart';

@JS()
external JSObject get window;

@JS('Notification')
extension type WebNotification._(JSObject _) implements JSObject {
  external static JSString get permission;
  external static JSPromise<JSString> requestPermission();
  external factory WebNotification(
    JSString title, [
    WebNotificationOptions options,
  ]);
}

@JS()
@anonymous
extension type WebNotificationOptions._(JSObject _) implements JSObject {
  external factory WebNotificationOptions({JSString? body, JSString? icon});
}

class WebNotificationServiceImpl implements WebNotificationService {
  @override
  Future<bool> requestPermission() async {
    final hasNotification = window.hasProperty('Notification'.toJS);
    if (!hasNotification.toDart) return false;

    final permission = WebNotification.permission.toDart;
    if (permission == 'granted') return true;

    if (permission == 'default' || permission == '') {
      final result = await WebNotification.requestPermission().toDart;
      return result.toDart == 'granted';
    }
    return false;
  }

  @override
  Future<void> showNotification({
    required String title,
    required String body,
  }) async {
    final hasNotification = window.hasProperty('Notification'.toJS);
    if (!hasNotification.toDart) return;

    final permission = WebNotification.permission.toDart;
    if (permission == 'granted') {
      _show(title: title, body: body);
    }
  }

  void _show({required String title, required String body}) {
    WebNotification(
      title.toJS,
      WebNotificationOptions(body: body.toJS, icon: 'icons/Icon-192.png'.toJS),
    );
  }
}

WebNotificationService getService() => WebNotificationServiceImpl();
