import 'package:flutter/material.dart';

class WindowEntry {
  WindowEntry({
    required this.id,
    required this.title,
    required this.content,
    required this.accentColor,
    required this.position,
  });

  final String id;
  final String title;
  final Widget content;
  final Color accentColor;
  final Offset position;
}
