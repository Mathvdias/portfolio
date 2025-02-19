import 'package:flutter/material.dart';

class ParallaxBackground extends StatelessWidget {
  final ScrollController scrollController;

  const ParallaxBackground({
    super.key,
    required this.scrollController,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: scrollController,
      builder: (context, child) {
        final offset = scrollController.hasClients ? scrollController.offset : 0.0;
        final screenHeight = MediaQuery.of(context).size.height;
        final opacity = (1 - (offset / (screenHeight * 0.8))).clamp(0.0, 1.0);

        return Positioned(
          top: -offset,
          left: 0,
          right: 0,
          bottom: -screenHeight,  // Extend beyond screen height to prevent gaps
          child: Transform.translate(
            offset: Offset(0, offset * 0.5),
            child: Opacity(
              opacity: opacity,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color.lerp(
                        Colors.blue.withOpacity(0.1),
                        Colors.transparent,
                        1 - opacity,
                      ) ?? Colors.transparent,
                      Color.lerp(
                        Colors.purple.withOpacity(0.1),
                        Colors.transparent,
                        1 - opacity,
                      ) ?? Colors.transparent,
                    ],
                  ),
                  backgroundBlendMode: BlendMode.overlay,
                ),
                child: CustomPaint(
                  painter: ParallaxPainter(
                    scrollOffset: offset,
                    opacity: opacity,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class ParallaxPainter extends CustomPainter {
  final double scrollOffset;
  final double opacity;

  ParallaxPainter({
    required this.scrollOffset,
    required this.opacity,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.1 * opacity)
      ..strokeWidth = 1;

    final dotSpacing = 30.0;
    final rows = (size.height / dotSpacing).ceil() + 10;
    final cols = (size.width / dotSpacing).ceil();

    final yOffset = scrollOffset * 0.5 % dotSpacing;

    for (var row = -5; row < rows; row++) {
      for (var col = 0; col < cols; col++) {
        final x = col * dotSpacing;
        final y = (row * dotSpacing) + yOffset;
        
        if (y >= -dotSpacing && y <= size.height + dotSpacing) {
          canvas.drawCircle(
            Offset(x, y),
            2 * opacity,
            paint,
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(ParallaxPainter oldDelegate) {
    return oldDelegate.scrollOffset != scrollOffset || 
           oldDelegate.opacity != opacity;
  }
}