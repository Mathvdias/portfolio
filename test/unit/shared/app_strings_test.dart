import 'package:flutter_test/flutter_test.dart';
import 'package:portifolio/shared/constants/app_strings.dart';

void main() {
  group('AppStrings', () {
    test('window IDs are unique', () {
      final ids = [
        AppStrings.winAbout,
        AppStrings.winFinder,
        AppStrings.winSkills,
        AppStrings.winAndroid,
        AppStrings.winTerminal,
        AppStrings.winCalculator,
        AppStrings.winSnake,
        AppStrings.winContact,
        AppStrings.winLicenses,
        AppStrings.winInterceptedHttp,
      ];
      expect(ids.toSet().length, ids.length);
    });

    test('all URLs start with https or mailto or /', () {
      final urls = [
        AppStrings.urlGitHub,
        AppStrings.urlLinkedIn,
        AppStrings.urlMedium,
        AppStrings.urlPubDev,
        AppStrings.urlResume,
        AppStrings.urlWhitepaper,
        AppStrings.urlGitHubIntercepted,
        AppStrings.emailAddress,
      ];
      for (final url in urls) {
        expect(
          url.startsWith('https://') ||
              url.startsWith('mailto:') ||
              url.startsWith('/'),
          isTrue,
          reason: 'URL "$url" should start with https://, mailto:, or /',
        );
      }
    });

    test('all window titles are non-empty', () {
      final titles = [
        AppStrings.titleFinder,
        AppStrings.titleSkills,
        AppStrings.titleAndroid,
        AppStrings.titleTerminal,
        AppStrings.titleCalculator,
        AppStrings.titleSnake,
        AppStrings.titleContact,
        AppStrings.titleLicenses,
        AppStrings.titleInterceptedHttp,
      ];
      for (final t in titles) {
        expect(t, isNotEmpty);
      }
    });
  });
}
