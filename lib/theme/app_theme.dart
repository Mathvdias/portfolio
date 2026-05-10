import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

abstract final class AppTheme {
  static const Color background = Color(0xFF1E1E2E);
  static const Color surface = Color(0xFF313244);
  static const Color surface0 = Color(0xFF45475A);
  static const Color overlay = Color(0xFF6C7086);
  static const Color text = Color(0xFFCDD6F4);
  static const Color subtext = Color(0xFFA6ADC8);
  static const Color blue = Color(0xFF89B4FA);
  static const Color green = Color(0xFFA6E3A1);
  static const Color red = Color(0xFFF38BA8);
  static const Color yellow = Color(0xFFF9E2AF);
  static const Color mauve = Color(0xFFCBA6F7);
  static const Color peach = Color(0xFFFAB387);
  static const Color teal = Color(0xFF94E2D5);
  static const Color pink = Color(0xFFF5C2E7);

  static TextStyle pixelText({double size = 10, Color? color}) =>
      GoogleFonts.pressStart2p(fontSize: size, color: color ?? text, height: 1.8);

  static TextStyle monoText({double size = 13, Color? color}) =>
      GoogleFonts.spaceMono(fontSize: size, color: color ?? text, height: 1.6);

  static ThemeData get darkTheme => ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: background,
        colorScheme: const ColorScheme.dark(
          primary: blue,
          secondary: mauve,
          surface: surface,
        ),
      );
}
