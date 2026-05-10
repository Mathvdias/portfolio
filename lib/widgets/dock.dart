import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme/app_theme.dart';
import 'pixel_icon_painter.dart';

class Dock extends StatelessWidget {
  const Dock({super.key});

  static const _items = [
    _DockItemData(
      pixels: kGithubPixels,
      label: 'GitHub',
      color: AppTheme.subtext,
      url: 'https://github.com/Mathvdias',
    ),
    _DockItemData(
      pixels: kPackagePixels,
      label: 'pub.dev',
      color: AppTheme.teal,
      url: 'https://pub.dev/packages/intercepted_http',
    ),
    _DockItemData(
      pixels: kLinkPixels,
      label: 'LinkedIn',
      color: AppTheme.blue,
      url: 'https://www.linkedin.com/in/matheusvdias/',
    ),
    _DockItemData(
      pixels: kMailPixels,
      label: 'Email',
      color: AppTheme.peach,
      url: 'mailto:mattmvc56@gmail.com',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60,
      decoration: BoxDecoration(
        color: AppTheme.surface.withValues(alpha: 0.85),
        border: const Border(
          top: BorderSide(color: AppTheme.surface0, width: 1),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (int i = 0; i < _items.length; i++) ...[
            if (i > 0) const SizedBox(width: 16),
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
          scale: _hovered ? 1.15 : 1.0,
          duration: const Duration(milliseconds: 150),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 44,
                height: 44,
                child: CustomPaint(
                  painter: PixelIconPainter(
                    pixels: widget.data.pixels,
                    color: widget.data.color,
                  ),
                ),
              ),
              Text(
                widget.data.label,
                style: GoogleFonts.pressStart2p(
                  fontSize: 5,
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
