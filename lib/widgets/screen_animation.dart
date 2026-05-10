import 'dart:math';

import 'package:flutter/material.dart';
import 'package:portifolio/theme/app_theme.dart' show AppTheme;

class ScreenAnimation extends StatefulWidget {
  final ScrollController scrollController;
  const ScreenAnimation({super.key, required this.scrollController});

  @override
  State<ScreenAnimation> createState() => _ScreenAnimationState();
}

class _ScreenAnimationState extends State<ScreenAnimation> {
  final ValueNotifier<double> interpolation = ValueNotifier(0.0);
  final ValueNotifier<bool> showScrollToTop = ValueNotifier(false);

  @override
  void initState() {
    widget.scrollController.addListener(scrollListener);
    super.initState();
  }

  void scrollListener() {
    final end = widget.scrollController.position.maxScrollExtent;
    final currentScroll = widget.scrollController.offset;

    interpolation.value = (currentScroll / end).clamp(0.0, 1.0);
    showScrollToTop.value = currentScroll / end > 0.5;
  }

  @override
  void dispose() {
    widget.scrollController.removeListener(scrollListener);
    interpolation.dispose();
    showScrollToTop.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<double>(
      valueListenable: interpolation,
      builder: (context, value, child) {
        final translateAnimation = const Interval(0.0, 0.5).transform(value);
        final opacityAnimation = const Interval(0.0, 0.5).transform(value);
        final rotateAnimation = const Interval(0.0, 0.5).transform(value);

        return Stack(
          children: [
            ValueListenableBuilder<bool>(
              valueListenable: showScrollToTop,
              builder: (context, show, _) {
                return Stack(
                  children: [
                    if (show)
                      Positioned(
                        bottom: 32,
                        right: 32,
                        child: Transform.rotate(
                          angle: 2 * pi * (1 - rotateAnimation),
                          child: Transform.translate(
                            offset: Offset(0, 100 * (1 - translateAnimation)),
                            child: Opacity(
                              opacity: opacityAnimation,
                              child: MouseRegion(
                                cursor: SystemMouseCursors.click,
                                child: GestureDetector(
                                  onTap: () {
                                    widget.scrollController.animateTo(
                                      0,
                                      duration: const Duration(
                                        milliseconds: 800,
                                      ),
                                      curve: Curves.easeInOut,
                                    );
                                  },
                                  child: Container(
                                    width: 48,
                                    height: 48,
                                    decoration: BoxDecoration(
                                      color: AppTheme.blue,
                                      borderRadius: BorderRadius.circular(12),
                                      boxShadow: [
                                        BoxShadow(
                                          color: AppTheme.blue.withValues(
                                            alpha: 0.3,
                                          ),
                                          blurRadius: 10,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: const Center(
                                      child: Icon(
                                        Icons.arrow_upward,
                                        color: Colors.white,
                                        size: 24,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          ],
        );
      },
    );
  }
}
