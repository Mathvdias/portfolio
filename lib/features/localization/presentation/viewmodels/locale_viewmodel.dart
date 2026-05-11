import 'package:flutter/material.dart';
import '../../domain/app_locale.dart';

class LocaleViewModel extends ChangeNotifier {
  AppLocale _locale = AppLocale.en;

  AppLocale get locale => _locale;
  Locale get flutterLocale => _locale.locale;
  String get currentCode => _locale.code;

  void init() {
    // Detect system/browser language
    final systemLocale = WidgetsBinding.instance.platformDispatcher.locale.languageCode;
    _locale = AppLocale.fromCode(systemLocale);
    notifyListeners();
  }

  void setLocale(AppLocale locale) {
    if (_locale == locale) return;
    _locale = locale;
    notifyListeners();
  }

  void setLocaleByCode(String code) => setLocale(AppLocale.fromCode(code));
}
