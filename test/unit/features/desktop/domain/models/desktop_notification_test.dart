import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:portifolio/features/desktop/domain/models/desktop_notification.dart';

void main() {
  test('DesktopNotification creates instance correctly', () {
    final time = DateTime(2026, 1, 1);
    final notification = DesktopNotification(
      title: 'Title',
      message: 'Message',
      icon: Icons.abc,
      color: Colors.red,
      time: time,
    );

    expect(notification.title, 'Title');
    expect(notification.message, 'Message');
    expect(notification.icon, Icons.abc);
    expect(notification.color, Colors.red);
    expect(notification.time, time);
  });
}
