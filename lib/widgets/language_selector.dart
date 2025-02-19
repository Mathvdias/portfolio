import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class LanguageSelector extends StatelessWidget {
  final Function(String) onLanguageChanged;
  final String currentLanguage;

  const LanguageSelector({
    super.key,
    required this.onLanguageChanged,
    required this.currentLanguage,
  });

  Map<String, String> _getLanguageInfo(String code) {
    final languages = {
      'en': {'name': 'English', 'flag': '🇺🇸'},
      'es': {'name': 'Español', 'flag': '🇪🇸'},
      'fr': {'name': 'Français', 'flag': '🇫🇷'},
      'it': {'name': 'Italiano', 'flag': '🇮🇹'},
      'pt': {'name': 'Português', 'flag': '🇧🇷'},
    };
    return {
      'name': languages[code]?['name'] ?? code,
      'flag': languages[code]?['flag'] ?? '🏳️',
    };
  }

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      color: AppTheme.surfaceColor,
      icon: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(_getLanguageInfo(currentLanguage)['flag']!, 
              style: const TextStyle(fontSize: 18)),
          const SizedBox(width: 4),
          Text(
            _getLanguageInfo(currentLanguage)['name']!,
            style: const TextStyle(
              color: AppTheme.textColor,
              fontSize: 16,
            ),
          ),
          const SizedBox(width: 4),
          const Icon(Icons.arrow_drop_down, color: AppTheme.textColor),
        ],
      ),
      onSelected: onLanguageChanged,
      itemBuilder: (context) {
        final allLanguages = ['en', 'es', 'fr', 'it', 'pt'];
        final languages = [
          currentLanguage,
          ...allLanguages.where((code) => code != currentLanguage),
        ];

        return languages.map((code) {
          final info = _getLanguageInfo(code);
          return PopupMenuItem(
            value: code,
            child: Container(
              decoration: BoxDecoration(
                color: code == currentLanguage 
                    ? AppTheme.primaryColor.withOpacity(0.1) 
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(4),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Row(
                children: [
                  Text(info['flag']!, style: const TextStyle(fontSize: 18)),
                  const SizedBox(width: 8),
                  Text(
                    info['name']!,
                    style: TextStyle(
                      color: code == currentLanguage 
                          ? AppTheme.primaryColor 
                          : AppTheme.textColor,
                      fontWeight: code == currentLanguage 
                          ? FontWeight.bold 
                          : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList();
      },
    );
  }
}