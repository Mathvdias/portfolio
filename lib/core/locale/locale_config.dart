import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import '../../l10n/app_localizations.dart';

/// Static locale configuration for [MaterialApp].
///
/// Centralises supported locales, localisation delegates and the custom
/// locale-resolution algorithm so [app.dart] stays free of inline config.
abstract final class LocaleConfig {
  static const supportedLocales = <Locale>[
    Locale('en'),
    Locale('es'),
    Locale('fr'),
    Locale('it'),
    Locale('pt'),
  ];

  static const delegates = <LocalizationsDelegate<dynamic>>[
    AppLocalizationsDelegate(),
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ];

  /// Maps the device's ordered locale list to the nearest supported locale.
  ///
  /// Flutter's default algorithm only does an exact match then a language-only
  /// match. This implementation makes the priority explicit and always falls
  /// back to English, so variants such as `pt-BR`, `en-US`, or `es-419` are
  /// resolved correctly regardless of the order Flutter tries them.
  static Locale resolveLocale(
    List<Locale>? deviceLocales,
    Iterable<Locale> supportedLocales,
  ) {
    if (deviceLocales == null || deviceLocales.isEmpty) {
      return const Locale('en');
    }
    for (final device in deviceLocales) {
      final match = supportedLocales.where(
        (s) => s.languageCode == device.languageCode,
      );
      if (match.isNotEmpty) return match.first;
    }
    return const Locale('en');
  }
}
