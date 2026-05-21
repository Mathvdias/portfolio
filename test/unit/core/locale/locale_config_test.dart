import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:portifolio/core/locale/locale_config.dart';

void main() {
  group('LocaleConfig', () {
    group('supportedLocales', () {
      test('contains exactly the five declared locales', () {
        expect(
          LocaleConfig.supportedLocales.map((l) => l.languageCode),
          containsAll(['en', 'es', 'fr', 'it', 'pt']),
        );
        expect(LocaleConfig.supportedLocales.length, 5);
      });
    });

    group('resolveLocale', () {
      const supported = LocaleConfig.supportedLocales;

      test('returns English for null device locales', () {
        expect(LocaleConfig.resolveLocale(null, supported).languageCode, 'en');
      });

      test('returns English for empty device locale list', () {
        expect(LocaleConfig.resolveLocale([], supported).languageCode, 'en');
      });

      test('resolves exact language code match — pt-BR → pt', () {
        expect(
          LocaleConfig.resolveLocale([
            const Locale('pt', 'BR'),
          ], supported).languageCode,
          'pt',
        );
      });

      test('resolves exact language code match — en-US → en', () {
        expect(
          LocaleConfig.resolveLocale([
            const Locale('en', 'US'),
          ], supported).languageCode,
          'en',
        );
      });

      test('resolves es-419 (Latin America Spanish) → es', () {
        expect(
          LocaleConfig.resolveLocale([
            const Locale('es', '419'),
          ], supported).languageCode,
          'es',
        );
      });

      test('falls back to English for unsupported language code', () {
        expect(
          LocaleConfig.resolveLocale([
            const Locale('zh', 'CN'),
          ], supported).languageCode,
          'en',
        );
      });

      test('uses first matching locale when multiple device locales given', () {
        // Device prefers zh-CN first (unsupported), then fr — should resolve fr
        expect(
          LocaleConfig.resolveLocale([
            const Locale('zh', 'CN'),
            const Locale('fr'),
          ], supported).languageCode,
          'fr',
        );
      });

      test('resolves it (Italian) correctly', () {
        expect(
          LocaleConfig.resolveLocale([
            const Locale('it', 'IT'),
          ], supported).languageCode,
          'it',
        );
      });
    });
  });
}
