import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';
import '../constants/app_sizes.dart';
import 'pixelate_on_hover.dart';

class DesktopIcon extends StatefulWidget {
  const DesktopIcon({
    super.key,
    required this.label,
    required this.iconWidget,
    required this.color,
    required this.onTap,
  });

  final String label;
  final Widget iconWidget;
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
          width: AppSizes.iconWidth,
          padding: const EdgeInsets.all(AppSizes.spacingMd),
          decoration: BoxDecoration(
            color:
                _hovered
                    ? AppTheme.blue.withValues(alpha: 0.15)
                    : Colors.transparent,
            border: Border.all(
              color: _hovered ? AppTheme.blue : Colors.transparent,
              width: 1,
            ),
            borderRadius: BorderRadius.circular(AppSizes.radiusSm),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: AppSizes.iconArtSize,
                height: AppSizes.iconArtSize,
                child: PixelateOnHover(
                  child: IconTheme(
                    data: IconThemeData(
                      color: widget.color,
                      size: AppSizes.iconArtSize * 0.8,
                    ),
                    child: widget.iconWidget,
                  ),
                ),
              ),
              const SizedBox(height: AppSizes.spacingXs),
              SizedBox(
                width: AppSizes.iconLabelWidth,
                child: Text(
                  widget.label,
                  style: GoogleFonts.pressStart2p(
                    fontSize: AppSizes.fontXs,
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
