import 'package:flutter/material.dart';

enum AppLocale {
  en('en', 'EN'),
  es('es', 'ES'),
  fr('fr', 'FR'),
  it('it', 'IT'),
  pt('pt', 'PT');

  const AppLocale(this.code, this.label);

  final String code;
  final String label;

  Locale get locale => Locale(code);

  static AppLocale fromCode(String code) {
    return AppLocale.values.firstWhere(
      (l) => l.code == code,
      orElse: () => AppLocale.en,
    );
  }
}
