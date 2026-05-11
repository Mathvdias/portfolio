import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../l10n/app_localizations.dart';
import '../../theme/app_theme.dart';
import '../constants/app_sizes.dart';
import '../constants/app_strings.dart';

const _kLanguages = [
  ('en', '🇺🇸', 'English'),
  ('pt', '🇧🇷', 'Português'),
  ('es', '🇪🇸', 'Español'),
  ('fr', '🇫🇷', 'Français'),
  ('it', '🇮🇹', 'Italiano'),
];

enum AppMenuAction { about, licenses, github, linkedin }

class MacMenuBar extends StatefulWidget {
  const MacMenuBar({
    super.key,
    required this.currentLanguage,
    required this.onLanguageChanged,
    this.onToggleNotifications,
    this.onAppMenuAction,
  });

  final String currentLanguage;
  final void Function(String) onLanguageChanged;
  final VoidCallback? onToggleNotifications;
  final void Function(AppMenuAction)? onAppMenuAction;

  @override
  State<MacMenuBar> createState() => _MacMenuBarState();
}

class _MacMenuBarState extends State<MacMenuBar> {
  String _time = '';
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _updateTime();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _updateTime());
  }

  void _updateTime() {
    final now = DateTime.now();
    final h = now.hour.toString().padLeft(2, '0');
    final m = now.minute.toString().padLeft(2, '0');
    if (mounted) setState(() => _time = '$h:$m');
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _flagFor(String code) =>
      _kLanguages
          .firstWhere((l) => l.$1 == code, orElse: () => _kLanguages.first)
          .$2;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: AppSizes.menuBarHeight,
      decoration: const BoxDecoration(
        color: AppTheme.surface,
        border: Border(bottom: BorderSide(color: AppTheme.surface0, width: 1)),
      ),
      child: Row(
        children: [
          // Left: apple-style name menu
          _AppNameMenu(onAction: widget.onAppMenuAction),

          const Spacer(),

          // Right: Music + WiFi + Battery + language picker + clock + notifications
          const _MusicPlayerWidget(),
          const SizedBox(width: AppSizes.spacingBase),
          const _WifiIndicator(),
          const SizedBox(width: AppSizes.spacingBase),
          const _BatteryIndicator(level: 0.82),
          const SizedBox(width: AppSizes.font2xl),

          _CompactLanguagePicker(
            currentLanguage: widget.currentLanguage,
            currentFlag: _flagFor(widget.currentLanguage),
            onLanguageChanged: widget.onLanguageChanged,
          ),

          const SizedBox(width: AppSizes.spacingXl),

          Text(
            _time,
            style: GoogleFonts.spaceMono(
              fontSize: AppSizes.fontXl,
              color: AppTheme.subtext,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(width: AppSizes.font2xl),

          if (widget.onToggleNotifications != null) ...[
            GestureDetector(
              onTap: widget.onToggleNotifications,
              child: const MouseRegion(
                cursor: SystemMouseCursors.click,
                child: Icon(Icons.menu_open, size: AppSizes.font3xl, color: AppTheme.text),
              ),
            ),
            const SizedBox(width: AppSizes.spacingBase),
          ],
        ],
      ),
    );
  }
}

// ── App name dropdown (mirrors the macOS  menu) ────────────────────────────

class _AppNameMenu extends StatelessWidget {
  const _AppNameMenu({this.onAction});
  final void Function(AppMenuAction)? onAction;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<AppMenuAction>(
      color: AppTheme.surface,
      tooltip: '',
      offset: const Offset(0, AppSizes.menuBarOffset),
      padding: EdgeInsets.zero,
      onSelected: (action) => onAction?.call(action),
      itemBuilder: (_) => [
        _menuItem(AppMenuAction.about, AppStrings.menuAbout, Icons.person_outline),
        const PopupMenuDivider(),
        _menuItem(AppMenuAction.licenses, AppStrings.menuLicenses, Icons.verified_outlined),
        const PopupMenuDivider(),
        _menuItem(AppMenuAction.github, AppStrings.menuGitHub, Icons.code),
        _menuItem(AppMenuAction.linkedin, AppStrings.menuLinkedIn, Icons.link),
      ],
      child: Padding(
        padding: const EdgeInsets.only(left: AppSizes.font2xl, right: AppSizes.spacingBase),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: AppSizes.spacingBase,
              height: AppSizes.spacingBase,
              decoration: const BoxDecoration(
                color: AppTheme.blue,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: AppSizes.spacingBase),
            Text(
              AppStrings.appName,
              style: GoogleFonts.spaceMono(
                fontSize: AppSizes.fontXxl,
                fontWeight: FontWeight.bold,
                color: AppTheme.text,
              ),
            ),
            const SizedBox(width: AppSizes.spacingSm),
            SizedBox(
              width: AppSizes.spacingBase,
              height: AppSizes.spacingBase,
              child: const Icon(
                Icons.description,
                color: AppTheme.blue,
                size: AppSizes.spacingBase,
              ),
            ),
          ],
        ),
      ),
    );
  }

  PopupMenuItem<AppMenuAction> _menuItem(
    AppMenuAction action,
    String label,
    IconData icon,
  ) {
    return PopupMenuItem<AppMenuAction>(
      value: action,
      height: 36,
      child: Row(
        children: [
          Icon(icon, size: AppSizes.font2xl, color: AppTheme.subtext),
          const SizedBox(width: AppSizes.spacingBase),
          Text(
            label,
            style: GoogleFonts.spaceMono(fontSize: AppSizes.fontXl, color: AppTheme.text),
          ),
        ],
      ),
    );
  }
}

// ── Shared widgets ─────────────────────────────────────────────────────────

class _MusicPlayerWidget extends StatelessWidget {
  const _MusicPlayerWidget();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.music_note, size: 14, color: AppTheme.green),
        const SizedBox(width: 6),
        Text(
          l10n.musicPlaying,
          style: GoogleFonts.spaceMono(fontSize: 11, color: AppTheme.subtext),
        ),
      ],
    );
  }
}

class _CompactLanguagePicker extends StatelessWidget {
  const _CompactLanguagePicker({
    required this.currentLanguage,
    required this.currentFlag,
    required this.onLanguageChanged,
  });

  final String currentLanguage;
  final String currentFlag;
  final void Function(String) onLanguageChanged;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      color: AppTheme.surface,
      tooltip: '',
      offset: const Offset(0, 24),
      padding: EdgeInsets.zero,
      onSelected: onLanguageChanged,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(currentFlag, style: const TextStyle(fontSize: 15)),
            const SizedBox(width: 4),
            Text(
              currentLanguage.toUpperCase(),
              style: GoogleFonts.spaceMono(
                fontSize: 11,
                color: AppTheme.subtext,
              ),
            ),
          ],
        ),
      ),
      itemBuilder: (context) =>
          _kLanguages
              .map(
                (lang) => PopupMenuItem<String>(
                  value: lang.$1,
                  child: Row(
                    children: [
                      Text(lang.$2, style: const TextStyle(fontSize: 14)),
                      const SizedBox(width: 10),
                      Text(
                        lang.$3,
                        style: GoogleFonts.spaceMono(
                          fontSize: 12,
                          color:
                              lang.$1 == currentLanguage
                                  ? AppTheme.blue
                                  : AppTheme.text,
                        ),
                      ),
                    ],
                  ),
                ),
              )
              .toList(),
    );
  }
}

class _WifiIndicator extends StatelessWidget {
  const _WifiIndicator();

  @override
  Widget build(BuildContext context) {
    return const Icon(Icons.wifi, size: 16, color: AppTheme.text);
  }
}

class _BatteryIndicator extends StatelessWidget {
  const _BatteryIndicator({required this.level});
  final double level;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 24,
      height: 12,
      child: CustomPaint(painter: _BatteryPainter(level: level)),
    );
  }
}

class _BatteryPainter extends CustomPainter {
  const _BatteryPainter({required this.level});
  final double level;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final border =
        Paint()
          ..color = AppTheme.subtext
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.0;
    final fill =
        Paint()
          ..color = level > 0.2 ? AppTheme.green : AppTheme.red
          ..style = PaintingStyle.fill;

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 1, w * 0.88, h - 2),
        const Radius.circular(2),
      ),
      border,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.88, h * 0.3, w * 0.12, h * 0.4),
        const Radius.circular(1),
      ),
      Paint()..color = AppTheme.subtext,
    );
    final fillW = (w * 0.88 - 4) * level;
    if (fillW > 0) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(2, 3, fillW, h - 6),
          const Radius.circular(1),
        ),
        fill,
      );
    }
  }

  @override
  bool shouldRepaint(_BatteryPainter old) => old.level != level;
}
