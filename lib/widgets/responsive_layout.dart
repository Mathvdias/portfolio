import 'package:flutter/material.dart';

class ResponsiveLayout extends StatelessWidget {
  final Widget child;
  final double desktopBreakpoint;
  final double tabletBreakpoint;

  const ResponsiveLayout({
    super.key,
    required this.child,
    this.desktopBreakpoint = 1200,
    this.tabletBreakpoint = 600,
  });

  static bool isDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width > 1200;

  static bool isTablet(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width > 600 && width <= 1200;
  }

  static bool isMobile(BuildContext context) =>
      MediaQuery.of(context).size.width <= 600;

  static double getHorizontalPadding(BuildContext context) {
    if (isDesktop(context)) return 120.0;
    if (isTablet(context)) return 60.0;
    return 24.0;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return child;
      },
    );
  }
}
