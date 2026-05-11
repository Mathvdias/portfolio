import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../theme/app_theme.dart';
import '../constants/app_strings.dart';
import '../constants/app_sizes.dart';
import 'package:pixel_art/pixel_art.dart';

class Dock extends StatelessWidget {
  const Dock({super.key});

  static const _items = [
    _DockItemData(
      pixels: kGithubPixels,
      label: AppStrings.dockGitHub,
      color: AppTheme.subtext,
      url: AppStrings.urlGitHub,
    ),
    _DockItemData(
      pixels: kMediumPixels,
      label: AppStrings.dockMedium,
      color: AppTheme.yellow,
      url: AppStrings.urlMedium,
    ),
    _DockItemData(
      pixels: kDartPixels,
      label: AppStrings.dockPubDev,
      color: AppTheme.teal,
      url: AppStrings.urlPubDev,
    ),
    _DockItemData(
      pixels: kLinkedInPixels,
      label: AppStrings.dockLinkedIn,
      color: AppTheme.blue,
      url: AppStrings.urlLinkedIn,
    ),
    _DockItemData(
      pixels: kMailPixels,
      label: AppStrings.dockEmail,
      color: AppTheme.peach,
      url: AppStrings.emailAddress,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.dockPaddingH,
        vertical: AppSizes.dockPaddingV,
      ),
      decoration: BoxDecoration(
        color: AppTheme.surface.withValues(alpha: 0.90),
        borderRadius: BorderRadius.circular(AppSizes.radiusDock),
        border: Border.all(color: AppTheme.surface0, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (int i = 0; i < _items.length; i++) ...[
            if (i > 0) const SizedBox(width: AppSizes.dockItemSpacing),
            _DockItem(data: _items[i]),
          ],
        ],
      ),
    );
  }
}

class _DockItemData {
  final List<List<int>> pixels;
  final String label;
  final Color color;
  final String url;

  const _DockItemData({
    required this.pixels,
    required this.label,
    required this.color,
    required this.url,
  });
}

class _DockItem extends StatefulWidget {
  const _DockItem({required this.data});
  final _DockItemData data;

  @override
  State<_DockItem> createState() => _DockItemState();
}

class _DockItemState extends State<_DockItem> {
  bool _hovered = false;

  Future<void> _launch() async {
    final uri = Uri.parse(widget.data.url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: _launch,
        child: AnimatedScale(
          scale: _hovered ? AppSizes.dockHoverScale : 1.0,
          duration: const Duration(milliseconds: 150),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: AppSizes.dockIconSize,
                height: AppSizes.dockIconSize,
                child: CustomPaint(
                  painter: PixelIconPainter(
                    pixels: widget.data.pixels,
                    color: widget.data.color,
                  ),
                ),
              ),
              const SizedBox(height: AppSizes.spacingXs),
              Text(
                widget.data.label,
                style: GoogleFonts.pressStart2p(
                  fontSize: AppSizes.fontXxs,
                  color: AppTheme.subtext,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
