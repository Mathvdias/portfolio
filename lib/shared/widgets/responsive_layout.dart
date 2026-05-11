import 'package:flutter/material.dart';
import '../constants/app_sizes.dart';

class ResponsiveLayout extends StatelessWidget {
  final Widget child;
  final double desktopBreakpoint;
  final double tabletBreakpoint;

  const ResponsiveLayout({
    super.key,
    required this.child,
    this.desktopBreakpoint = AppSizes.desktopBreakpoint,
    this.tabletBreakpoint = AppSizes.mobileBreakpoint,
  });

  static bool isDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width > AppSizes.desktopBreakpoint;

  static bool isTablet(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width > AppSizes.mobileBreakpoint &&
        width <= AppSizes.desktopBreakpoint;
  }

  static bool isMobile(BuildContext context) =>
      MediaQuery.of(context).size.width <= AppSizes.mobileBreakpoint;

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
