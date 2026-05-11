import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../theme/app_theme.dart';
import '../constants/app_strings.dart';
import '../constants/app_sizes.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class Dock extends StatelessWidget {
  const Dock({super.key});

  static const _items = [
    _DockItemData(
      iconWidget: FaIcon(FontAwesomeIcons.github),
      label: AppStrings.dockGitHub,
      color: AppTheme.subtext,
      url: AppStrings.urlGitHub,
    ),
    _DockItemData(
      iconWidget: FaIcon(FontAwesomeIcons.medium),
      label: AppStrings.dockMedium,
      color: AppTheme.yellow,
      url: AppStrings.urlMedium,
    ),
    _DockItemData(
      iconWidget: Icon(Icons.code),
      label: AppStrings.dockPubDev,
      color: AppTheme.teal,
      url: AppStrings.urlPubDev,
    ),
    _DockItemData(
      iconWidget: FaIcon(FontAwesomeIcons.linkedin),
      label: AppStrings.dockLinkedIn,
      color: AppTheme.blue,
      url: AppStrings.urlLinkedIn,
    ),
    _DockItemData(
      iconWidget: Icon(Icons.email),
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
  final Widget iconWidget;
  final String label;
  final Color color;
  final String url;

  const _DockItemData({
    required this.iconWidget,
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
                child: IconTheme(
                  data: IconThemeData(
                    color: widget.data.color,
                    size: AppSizes.dockIconSize * 0.8,
                  ),
                  child: widget.data.iconWidget,
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
