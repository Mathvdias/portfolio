import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:portifolio/features/localization/domain/app_locale.dart';
import 'package:portifolio/features/localization/presentation/viewmodels/locale_viewmodel.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('LocaleViewModel', () {
    late LocaleViewModel vm;

    setUp(() => vm = LocaleViewModel());
    tearDown(() => vm.dispose());

    test('starts with English locale', () {
      expect(vm.locale, AppLocale.en);
      expect(vm.currentCode, 'en');
      expect(vm.flutterLocale, const Locale('en'));
    });

    test('setLocale updates locale and notifies listeners', () {
      var notified = false;
      vm.addListener(() => notified = true);

      vm.setLocale(AppLocale.pt);

      expect(vm.locale, AppLocale.pt);
      expect(vm.currentCode, 'pt');
      expect(notified, isTrue);
    });

    test('setLocale does not notify when same locale', () {
      var count = 0;
      vm.addListener(() => count++);

      vm.setLocale(AppLocale.en);

      expect(count, 0);
    });

    test('setLocaleByCode resolves correct enum value', () {
      vm.setLocaleByCode('fr');
      expect(vm.locale, AppLocale.fr);
    });

    test('setLocaleByCode falls back to English for unknown code', () {
      vm.setLocaleByCode('xx');
      expect(vm.locale, AppLocale.en);
    });

    test('can cycle through all 5 locales', () {
      for (final locale in AppLocale.values) {
        vm.setLocale(locale);
        expect(vm.locale, locale);
        expect(vm.flutterLocale, locale.locale);
      }
    });

    test('init() reads system locale and notifies listeners', () {
      var notified = false;
      vm.addListener(() => notified = true);
      vm.init();
      // Locale is updated to whatever the test platform reports
      expect(vm.locale, isA<AppLocale>());
      expect(notified, isTrue);
    });

    test('init() sets a valid locale code', () {
      vm.init();
      expect(vm.currentCode, isNotEmpty);
      expect(AppLocale.values.map((l) => l.code), contains(vm.currentCode));
    });
  });
}
