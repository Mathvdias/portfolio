import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/di/app_dependencies.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/app_theme.dart';
import '../constants/app_sizes.dart';
import '../constants/app_strings.dart';
import '../models/sdf_shape.dart';
import 'glow_on_hover.dart';
import 'pixelate_on_hover.dart';
import 'sdf_icon.dart';

class Dock extends StatelessWidget {
  const Dock({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    const iconSize = AppSizes.dockIconSize * 0.8;
    final items = [
      _DockItemData(
        iconWidget: const SdfIcon(SdfShape.code, size: iconSize, color: AppTheme.subtext),
        label: AppStrings.dockGitHub,
        color: AppTheme.subtext,
        url: AppStrings.urlGitHub,
      ),
      _DockItemData(
        iconWidget: const SdfIcon(SdfShape.globe, size: iconSize, color: AppTheme.blue),
        label: AppStrings.dockPubDev,
        color: AppTheme.blue,
        url: AppStrings.urlPubDev,
      ),
      _DockItemData(
        iconWidget: const SdfIcon(SdfShape.file, size: iconSize, color: AppTheme.yellow),
        label: AppStrings.dockMedium,
        color: AppTheme.yellow,
        url: AppStrings.urlMedium,
      ),
      _DockItemData(
        iconWidget: const SdfIcon(SdfShape.briefcase, size: iconSize, color: AppTheme.blue),
        label: AppStrings.dockLinkedIn,
        color: AppTheme.blue,
        url: AppStrings.urlLinkedIn,
      ),
      _DockItemData(
        iconWidget: const SdfIcon(SdfShape.envelope, size: iconSize, color: AppTheme.peach),
        label: AppStrings.dockEmail,
        color: AppTheme.peach,
        url: AppStrings.emailAddress,
      ),
      _DockItemData(
        iconWidget: const SdfIcon(SdfShape.book, size: iconSize, color: AppTheme.blue),
        label: l10n.guestbook,
        color: AppTheme.blue,
        windowId: AppStrings.winGuestbook,
      ),
      _DockItemData(
        iconWidget: const SdfIcon(SdfShape.barChart, size: iconSize, color: AppTheme.yellow),
        label: l10n.projectStats,
        color: AppTheme.yellow,
        windowId: AppStrings.winProjectStats,
      ),
    ];

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppSizes.radiusDock),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.dockPaddingH,
        vertical: AppSizes.dockPaddingV,
      ),
      decoration: BoxDecoration(
        color: AppTheme.surface.withValues(alpha: 0.70),
        borderRadius: BorderRadius.circular(AppSizes.radiusDock),
        border: Border.all(color: AppTheme.surface0, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (int i = 0; i < items.length; i++) ...[
            if (i > 0) const SizedBox(width: AppSizes.dockItemSpacing),
            if (i == 4) ...[
              Container(
                width: 1,
                height: 30,
                color: AppTheme.surface0,
                margin: const EdgeInsets.symmetric(horizontal: 8),
              ),
            ],
            _DockItem(data: items[i]),
          ],
        ],
      ),
        ),
      ),
    );
  }
}

class _DockItemData {
  final Widget iconWidget;
  final String label;
  final Color color;
  final String? url;
  final String? windowId;

  const _DockItemData({
    required this.iconWidget,
    required this.label,
    required this.color,
    this.url,
    this.windowId,
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

  Future<void> _handleTap(BuildContext context) async {
    final deps = AppDependencies.of(context);
    if (widget.data.url != null) {
      unawaited(
        deps.analyticsService.logLinkClick(widget.data.label, widget.data.url!),
      );
      final uri = Uri.parse(widget.data.url!);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      }
    } else if (widget.data.windowId != null) {
      deps.desktopViewModel.openWindowById(widget.data.windowId!, context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final desktopVM = AppDependencies.of(context).desktopViewModel;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: () => _handleTap(context),
        child: AnimatedScale(
          scale: _hovered ? AppSizes.dockHoverScale : 1.0,
          duration: const Duration(milliseconds: 150),
          child: ListenableBuilder(
            listenable: desktopVM,
            builder: (context, _) {
              final isWindowOpen =
                  widget.data.windowId != null &&
                  desktopVM.windows.any((w) => w.id == widget.data.windowId);

              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: AppSizes.dockIconSize,
                    height: AppSizes.dockIconSize,
                    child: Center(
                      child: GlowOnHover(
                        color: widget.data.color,
                        child: PixelateOnHover(
                          child: widget.data.iconWidget,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSizes.spacingXs),
                  if (isWindowOpen)
                    Container(
                      width: 4,
                      height: 4,
                      decoration: const BoxDecoration(
                        color: AppTheme.text,
                        shape: BoxShape.circle,
                      ),
                    )
                  else
                    Text(
                      widget.data.label,
                      style: GoogleFonts.pressStart2p(
                        fontSize: AppSizes.fontXxs,
                        color: AppTheme.subtext,
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
