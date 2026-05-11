import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../theme/app_theme.dart';
import '../constants/app_strings.dart';
import '../constants/app_sizes.dart';

/// Action the user picked from the desktop right-click menu.
enum DesktopContextAction { newNote, openTerminal, about, spotlight }

/// macOS-style right-click context menu shown on the desktop background.
class DesktopContextMenu extends StatelessWidget {
  const DesktopContextMenu({
    super.key,
    required this.position,
    required this.onAction,
    required this.onDismiss,
  });

  final Offset position;
  final ValueChanged<DesktopContextAction> onAction;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Invisible full-screen tap catcher
        Positioned.fill(
          child: GestureDetector(
            onTap: onDismiss,
            onSecondaryTap: onDismiss,
            behavior: HitTestBehavior.opaque,
            child: const ColoredBox(color: Colors.transparent),
          ),
        ),
        Positioned(
          left: position.dx,
          top: position.dy,
          child: _MenuCard(onAction: onAction),
        ),
      ],
    );
  }
}

class _MenuCard extends StatelessWidget {
  const _MenuCard({required this.onAction});
  final ValueChanged<DesktopContextAction> onAction;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: AppSizes.contextMenuWidth,
      padding: const EdgeInsets.symmetric(vertical: AppSizes.spacingXs),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        border: Border.all(color: AppTheme.surface0),
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _MenuItem(
            icon: Icons.note_add,
            label: AppStrings.ctxNewNote,
            action: DesktopContextAction.newNote,
            onTap: onAction,
          ),
          _MenuItem(
            icon: Icons.terminal,
            label: AppStrings.ctxOpenTerminal,
            action: DesktopContextAction.openTerminal,
            onTap: onAction,
          ),
          const _Divider(),
          _MenuItem(
            icon: Icons.search,
            label: AppStrings.ctxSpotlight,
            action: DesktopContextAction.spotlight,
            onTap: onAction,
          ),
          _MenuItem(
            icon: Icons.info_outline,
            label: AppStrings.ctxAbout,
            action: DesktopContextAction.about,
            onTap: onAction,
          ),
        ],
      ),
    );
  }
}

class _MenuItem extends StatefulWidget {
  const _MenuItem({
    required this.icon,
    required this.label,
    required this.action,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final DesktopContextAction action;
  final ValueChanged<DesktopContextAction> onTap;

  @override
  State<_MenuItem> createState() => _MenuItemState();
}

class _MenuItemState extends State<_MenuItem> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: () => widget.onTap(widget.action),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSizes.spacingLg,
            vertical: AppSizes.spacingMd,
          ),
          color: _hovered ? AppTheme.blue.withValues(alpha: 0.15) : Colors.transparent,
          child: Row(
            children: [
              Icon(widget.icon, size: 14, color: AppTheme.subtext),
              const SizedBox(width: AppSizes.spacingMd),
              Expanded(
                child: Text(
                  widget.label,
                  style: GoogleFonts.spaceMono(
                    fontSize: AppSizes.fontXl,
                    color: AppTheme.text,
                  ),
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

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSizes.spacingXs),
      child: Container(height: 1, color: AppTheme.surface0),
    );
  }
}
