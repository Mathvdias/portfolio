import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:portifolio/l10n/app_localizations.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AppLocalizations', () {
    late AppLocalizations enL10n;

    setUp(() {
      enL10n = AppLocalizations(const Locale('en'));
    });

    test('basic string getters return non-empty English values', () {
      expect(enL10n.hello, isNotEmpty);
      expect(enL10n.role, isNotEmpty);
      expect(enL10n.about, isNotEmpty);
      expect(enL10n.experience, isNotEmpty);
      expect(enL10n.projects, isNotEmpty);
      expect(enL10n.bio, isNotEmpty);
      expect(enL10n.companyName, isNotEmpty);
      expect(enL10n.experienceDescription, isNotEmpty);
      expect(enL10n.name, isNotEmpty);
      expect(enL10n.location, isNotEmpty);
    });

    test('notification-related getters return values', () {
      expect(enL10n.stickyNoteTodo, isNotEmpty);
      expect(enL10n.notificationCenter, isNotEmpty);
      expect(enL10n.dailyVerse, isNotEmpty);
      expect(enL10n.dailyVerseText, isNotEmpty);
      expect(enL10n.system, isNotEmpty);
      expect(enL10n.portfolioUpdated, isNotEmpty);
      expect(enL10n.musicPlaying, isNotEmpty);
      expect(enL10n.github, isNotEmpty);
      expect(enL10n.githubUpdate, isNotEmpty);
      expect(enL10n.timeNow, isNotEmpty);
      expect(enL10n.time2hAgo, isNotEmpty);
      expect(enL10n.time1dAgo, isNotEmpty);
    });

    test('guestbook getters return values', () {
      expect(enL10n.guestbook, isNotEmpty);
      expect(enL10n.signGuestbook, isNotEmpty);
      expect(enL10n.yourName, isNotEmpty);
      expect(enL10n.yourMessage, isNotEmpty);
      expect(enL10n.post, isNotEmpty);
      expect(enL10n.rating, isNotEmpty);
      expect(enL10n.noMessages, isNotEmpty);
      expect(enL10n.messagePosted, isNotEmpty);
      expect(enL10n.nameMessageEmpty, isNotEmpty);
      expect(enL10n.waitToPost, isNotEmpty);
      expect(enL10n.accessDenied, isNotEmpty);
      expect(enL10n.adminActivated, isNotEmpty);
      expect(enL10n.adminDeactivated, isNotEmpty);
      expect(enL10n.noNewNotifications, isNotEmpty);
      expect(enL10n.newGuestbookMessage, isNotEmpty);
      expect(enL10n.leftReview, isNotEmpty);
    });

    test('project and skill getters return values', () {
      expect(enL10n.androidDev, isNotEmpty);
      expect(enL10n.androidDevSubtitle, isA<String>());
      expect(enL10n.projectStats, isNotEmpty);
      expect(enL10n.projectMetrics, isNotEmpty);
      expect(enL10n.coverageLabel, isNotEmpty);
      expect(enL10n.unitTests, isNotEmpty);
      expect(enL10n.codeQuality, isNotEmpty);
      expect(enL10n.buildStatus, isNotEmpty);
      expect(enL10n.passing, isNotEmpty);
      expect(enL10n.keepBuilding, isNotEmpty);
      expect(enL10n.expertise, isNotEmpty);
      expect(enL10n.core, isNotEmpty);
      expect(enL10n.tools, isNotEmpty);
      expect(enL10n.architecture, isNotEmpty);
    });

    test('experiences getter returns non-empty list for English', () {
      expect(enL10n.experiences, isNotEmpty);
    });

    test('experiences getter returns empty list for unknown locale', () {
      final l10n = AppLocalizations(const Locale('zz'));
      expect(l10n.experiences, isEmpty);
    });

    test('getSection maps known keys to localized strings', () {
      expect(enL10n.getSection('about'), enL10n.about);
      expect(enL10n.getSection('experience'), enL10n.experience);
      expect(enL10n.getSection('projects'), enL10n.projects);
    });

    test('getSection returns the key itself for unknown keys', () {
      expect(enL10n.getSection('unknown_key'), 'unknown_key');
      expect(enL10n.getSection('foo'), 'foo');
    });

    test('unknown locale falls back to empty strings via ?? operator', () {
      final l10n = AppLocalizations(const Locale('zz'));
      expect(l10n.hello, '');
      expect(l10n.role, '');
      expect(l10n.guestbook, 'Guestbook');
    });
  });

  group('AppLocalizationsDelegate', () {
    const delegate = AppLocalizationsDelegate();

    test('isSupported returns true for supported locales', () {
      for (final code in ['en', 'es', 'fr', 'it', 'pt']) {
        expect(delegate.isSupported(Locale(code)), isTrue, reason: code);
      }
    });

    test('isSupported returns false for unsupported locales', () {
      expect(delegate.isSupported(const Locale('zz')), isFalse);
      expect(delegate.isSupported(const Locale('ja')), isFalse);
    });

    test('load returns AppLocalizations instance', () async {
      final l10n = await delegate.load(const Locale('en'));
      expect(l10n, isA<AppLocalizations>());
      expect(l10n.locale.languageCode, 'en');
    });

    test('shouldReload returns false', () {
      expect(delegate.shouldReload(delegate), isFalse);
    });
  });
}
