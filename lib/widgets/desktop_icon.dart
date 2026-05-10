import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import 'pixel_icon_painter.dart';

class DesktopIcon extends StatefulWidget {
  const DesktopIcon({
    super.key,
    required this.label,
    required this.pixels,
    required this.color,
    required this.onTap,
  });

  final String label;
  final List<List<int>> pixels;
  final Color color;
  final VoidCallback? onTap;

  @override
  State<DesktopIcon> createState() => _DesktopIconState();
}

class _DesktopIconState extends State<DesktopIcon> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          width: 88,
          padding: const EdgeInsets.all(8),
          decoration:
              _hovered
                  ? BoxDecoration(
                    color: AppTheme.blue.withValues(alpha: 0.15),
                    border: Border.all(color: AppTheme.blue, width: 1),
                  )
                  : null,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 56,
                height: 56,
                child: CustomPaint(
                  painter: PixelIconPainter(
                    pixels: widget.pixels,
                    color: widget.color,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              SizedBox(
                width: 72,
                child: Text(
                  widget.label,
                  style: GoogleFonts.pressStart2p(
                    fontSize: 7,
                    color: AppTheme.text,
                    height: 1.6,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
