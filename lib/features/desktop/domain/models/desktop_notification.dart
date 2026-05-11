import 'package:flutter/material.dart';

class DesktopNotification {
  final String title;
  final String message;
  final IconData icon;
  final Color color;
  final DateTime time;

  const DesktopNotification({
    required this.title,
    required this.message,
    required this.icon,
    required this.color,
    required this.time,
  });
}
