import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../theme/app_theme.dart';
import '../../l10n/app_localizations.dart';
import '../constants/app_strings.dart';
import '../constants/app_sizes.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../features/desktop/presentation/viewmodels/desktop_viewmodel.dart';

class Dock extends StatelessWidget {
  const Dock({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    final items = [
      _DockItemData(
        iconWidget: const FaIcon(FontAwesomeIcons.github),
        label: AppStrings.dockGitHub,
        color: AppTheme.subtext,
        url: AppStrings.urlGitHub,
      ),
      _DockItemData(
        iconWidget: const FaIcon(FontAwesomeIcons.medium),
        label: AppStrings.dockMedium,
        color: AppTheme.yellow,
        url: AppStrings.urlMedium,
      ),
      _DockItemData(
        iconWidget: const FaIcon(FontAwesomeIcons.linkedin),
        label: AppStrings.dockLinkedIn,
        color: AppTheme.blue,
        url: AppStrings.urlLinkedIn,
      ),
      _DockItemData(
        iconWidget: const Icon(Icons.email),
        label: AppStrings.dockEmail,
        color: AppTheme.peach,
        url: AppStrings.emailAddress,
      ),
      _DockItemData(
        iconWidget: const Icon(Icons.book),
        label: l10n.guestbook,
        color: AppTheme.blue,
        windowId: AppStrings.winGuestbook,
      ),
      _DockItemData(
        iconWidget: const Icon(Icons.analytics),
        label: l10n.projectStats,
        color: AppTheme.yellow,
        windowId: AppStrings.winProjectStats,
      ),
    ];

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
    if (widget.data.url != null) {
      final uri = Uri.parse(widget.data.url!);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      }
    } else if (widget.data.windowId != null) {
      // Logic for opening windows handled via callback or viewmodel
      context.read<DesktopViewModel>().openWindowById(
        widget.data.windowId!,
        context,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final desktopVM = context.watch<DesktopViewModel>();
    final isWindowOpen =
        widget.data.windowId != null &&
        desktopVM.windows.any((w) => w.id == widget.data.windowId);

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: () => _handleTap(context),
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
          ),
        ),
      ),
    );
  }
}
