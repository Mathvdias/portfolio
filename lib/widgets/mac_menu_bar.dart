import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import 'language_selector.dart';

class MacMenuBar extends StatefulWidget {
  const MacMenuBar({
    super.key,
    required this.currentLanguage,
    required this.onLanguageChanged,
  });

  final String currentLanguage;
  final void Function(String) onLanguageChanged;

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
    if (mounted) {
      setState(() {
        _time = '$h:$m';
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 28,
      decoration: const BoxDecoration(
        color: AppTheme.surface,
        border: Border(
          bottom: BorderSide(color: AppTheme.surface0, width: 1),
        ),
      ),
      child: Row(
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 12),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(width: 8, height: 8, color: AppTheme.blue),
                const SizedBox(width: 8),
                Text(
                  'Matheus Dias',
                  style: GoogleFonts.pressStart2p(
                    fontSize: 7,
                    color: AppTheme.text,
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          LanguageSelector(
            currentLanguage: widget.currentLanguage,
            onLanguageChanged: widget.onLanguageChanged,
          ),
          const SizedBox(width: 8),
          Text(
            _time,
            style: GoogleFonts.spaceMono(
              fontSize: 12,
              color: AppTheme.subtext,
            ),
          ),
          const SizedBox(width: 12),
        ],
      ),
    );
  }
}
