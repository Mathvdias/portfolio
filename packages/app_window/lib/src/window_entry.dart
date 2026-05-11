import 'package:flutter/material.dart';

class WindowEntry {
  final String id;
  final String title;
  final Widget content;
  final Color accentColor;
  final Offset position;
  final double width;
  final double height;

  WindowEntry({
    required this.id,
    required this.title,
    required this.content,
    required this.accentColor,
    required this.position,
    this.width = 480.0,
    this.height = 360.0,
  });
}
