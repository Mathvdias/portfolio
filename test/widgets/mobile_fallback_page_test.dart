import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mocktail/mocktail.dart';
import 'package:portifolio/core/di/app_dependencies.dart';
import 'package:portifolio/core/services/analytics_service.dart';
import 'package:portifolio/core/services/sound_service.dart';
import 'package:portifolio/features/desktop/presentation/viewmodels/desktop_viewmodel.dart';
import 'package:portifolio/features/guestbook/data/repositories/guestbook_repository.dart';
import 'package:portifolio/features/guestbook/domain/models/guestbook_message.dart';
import 'package:portifolio/features/guestbook/presentation/viewmodels/guestbook_viewmodel.dart';
import 'package:portifolio/features/guestbook/presentation/widgets/guestbook_content.dart';
import 'package:portifolio/features/localization/presentation/viewmodels/locale_viewmodel.dart';
import 'package:portifolio/features/visitors/domain/repositories/visitor_repository.dart';
import 'package:portifolio/l10n/app_localizations.dart';
import 'package:portifolio/shared/constants/app_strings.dart';
import 'package:portifolio/shared/widgets/about_window_content.dart';
import 'package:portifolio/shared/widgets/calculator_content.dart';
import 'package:portifolio/shared/widgets/experience_window_content.dart';
import 'package:portifolio/shared/widgets/lava_studio_content.dart';
import 'package:portifolio/shared/widgets/mobile_fallback_page.dart';
import 'package:portifolio/shared/widgets/pixel_wallpaper.dart';
import 'package:portifolio/shared/widgets/project_stats_window_content.dart';
import 'package:portifolio/shared/widgets/skills_window_content.dart';
import 'package:portifolio/shared/widgets/terminal_content.dart';
import 'package:portifolio/theme/app_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Channel `url_launcher` talks to under `flutter test` (no plugin registrant).
const _launcherChannel = MethodChannel('plugins.flutter.io/url_launcher');

const _supportedLocales = [
  Locale('en'),
  Locale('pt'),
  Locale('es'),
  Locale('fr'),
  Locale('it'),
];

const _delegates = <LocalizationsDelegate<dynamic>>[
  AppLocalizationsDelegate(),
  GlobalMaterialLocalizations.delegate,
  GlobalWidgetsLocalizations.delegate,
  GlobalCupertinoLocalizations.delegate,
];

class _MockVisitorRepository extends Mock implements VisitorRepository {}

class _MockDesktopViewModel extends Mock implements DesktopViewModel {}

class _MockAnalyticsService extends Mock implements AnalyticsService {}

/// Remembers every sound the page asked for, in order.
class _RecordingSoundService implements SoundService {
  _RecordingSoundService({bool muted = false}) : _muted = muted;

  final List<String> events = [];
  bool _muted;

  @override
  bool get isMuted => _muted;

  @override
  void toggleMute() {
    _muted = !_muted;
    events.add(_muted ? 'mute' : 'unmute');
  }

  @override
  void playClick() => events.add('click');

  @override
  void playWindowOpen() => events.add('windowOpen');

  @override
  void playWindowClose() => events.add('windowClose');

  @override
  void playChime() => events.add('chime');

  @override
  void playKeypress() => events.add('keypress');
}

/// Guestbook backend that already holds one signed message.
class _SeededGuestbookRepository implements GuestbookRepository {
  @override
  Stream<List<GuestbookMessage>> watchMessages() {
    return Stream.value([
      GuestbookMessage(
        id: 'seed',
        name: 'Ada Lovelace',
        message: 'Lovely pocket edition!',
        rating: 5,
        timestamp: DateTime(2024, 1, 1),
      ),
    ]);
  }

  @override
  Future<void> addMessage(String name, String message, int rating) async {}

  @override
  Future<void> deleteMessage(String id) async {}
}

/// The injected services a test can inspect after driving the page.
class _Deps {
  _Deps({required this.sound, required this.locale, required this.guestbook});

  final _RecordingSoundService sound;
  final LocaleViewModel locale;
  final GuestbookViewModel guestbook;
}

/// What the mocked url_launcher channel was asked to do.
class _LaunchLog {
  final List<String> checked = [];
  final List<String> launched = [];
}

_LaunchLog _mockUrlLauncher(WidgetTester tester, {bool canLaunch = true}) {
  final log = _LaunchLog();
  final messenger = tester.binding.defaultBinaryMessenger;
  messenger.setMockMethodCallHandler(_launcherChannel, (call) async {
    final url = (call.arguments as Map<Object?, Object?>)['url']! as String;
    if (call.method == 'canLaunch') {
      log.checked.add(url);
      return canLaunch;
    }
    if (call.method == 'launch') log.launched.add(url);
    return true;
  });
  addTearDown(() => messenger.setMockMethodCallHandler(_launcherChannel, null));
  return log;
}

void _useSurface(WidgetTester tester, Size size) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
}

/// Pumps the page with localizations only (no [AppDependencies] above it).
Future<void> _pumpLocalized(
  WidgetTester tester, {
  Locale locale = const Locale('en'),
}) async {
  await tester.pumpWidget(
    MaterialApp(
      locale: locale,
      supportedLocales: _supportedLocales,
      localizationsDelegates: _delegates,
      // Not const: a const instance is canonicalised at compile time and the
      // constructor never runs.
      // ignore: prefer_const_constructors
      home: MobileFallbackPage(),
    ),
  );
  await tester.pump(); // asynchronous localization load
}

/// Pumps the page the way `app.dart` hosts it: under [AppDependencies], with
/// the `MaterialApp` locale following the [LocaleViewModel].
Future<_Deps> _pumpWithDeps(
  WidgetTester tester, {
  _RecordingSoundService? sound,
  String localeCode = 'en',
}) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  final deps = _Deps(
    sound: sound ?? _RecordingSoundService(),
    locale: LocaleViewModel()..setLocaleByCode(localeCode),
    guestbook: GuestbookViewModel(_SeededGuestbookRepository(), prefs),
  );
  addTearDown(deps.locale.dispose);
  addTearDown(deps.guestbook.dispose);

  await tester.pumpWidget(
    AppDependencies(
      localeViewModel: deps.locale,
      visitorRepository: _MockVisitorRepository(),
      guestbookViewModel: deps.guestbook,
      desktopViewModel: _MockDesktopViewModel(),
      analyticsService: _MockAnalyticsService(),
      soundService: deps.sound,
      child: ListenableBuilder(
        listenable: deps.locale,
        builder:
            (context, _) => MaterialApp(
              locale: deps.locale.flutterLocale,
              supportedLocales: _supportedLocales,
              localizationsDelegates: _delegates,
              home: const MobileFallbackPage(),
            ),
      ),
    ),
  );
  await tester.pump(); // asynchronous localization load
  return deps;
}

/// Taps a launcher card and waits for the 220 ms window transition.
///
/// Fixed pumps instead of `pumpAndSettle`: some apps animate forever.
Future<void> _openApp(WidgetTester tester, String cardLabel) async {
  await tester.ensureVisible(find.text(cardLabel));
  await tester.pump();
  await tester.tap(find.text(cardLabel));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
}

/// Waits for the 180 ms reverse transition of a closing window.
Future<void> _waitForClose(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
}

/// Lets the `canLaunchUrl` -> `launchUrl` channel round trips complete.
Future<void> _flushLaunches(WidgetTester tester) async {
  await tester.pump();
  await tester.pump();
}

/// The title in the header of the open full-screen window.
Finder _windowTitle(String title, Color accent) {
  return find.byWidgetPredicate(
    (w) =>
        w is Text &&
        w.data == title &&
        w.style?.fontSize == 9.5 &&
        w.style?.color == accent,
    description: 'window title "$title"',
  );
}

Color? _textColor(WidgetTester tester, Finder text) {
  return tester.widget<Text>(text).style?.color;
}

void main() {
  // PressStart2P / SpaceMono are not bundled; never reach for the network.
  GoogleFonts.config.allowRuntimeFetching = false;

  group('MobileFallbackPage', () {
    testWidgets('renders title and subtitle', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: MobileFallbackPage()));

      expect(find.text(AppStrings.mobileTitle), findsOneWidget);
      expect(find.text(AppStrings.mobileSubtitle), findsOneWidget);
    });

    testWidgets('renders GitHub link', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: MobileFallbackPage()));

      expect(find.text(AppStrings.mobileGitHubLink), findsOneWidget);
    });

    testWidgets('renders Pocket Apps grid and sections', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: MobileFallbackPage()));

      expect(find.text(AppStrings.mobilePocketApps), findsOneWidget);
      expect(find.text(AppStrings.mobileAppAbout), findsOneWidget);
      expect(find.text(AppStrings.mobileAppExperience), findsOneWidget);
      expect(find.text(AppStrings.mobileAppSkills), findsOneWidget);
      expect(find.text(AppStrings.mobileAppProjects), findsOneWidget);
      expect(find.text(AppStrings.mobileAppGuestbook), findsOneWidget);
      expect(find.text(AppStrings.mobileAppTerminal), findsOneWidget);
      expect(find.text(AppStrings.mobileAppSnake), findsOneWidget);
      expect(find.text(AppStrings.mobileAppCalc), findsOneWidget);
      expect(find.text(AppStrings.mobileAppMetrics), findsOneWidget);
    });

    testWidgets('renders quick dock links', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: MobileFallbackPage()));

      expect(find.text(AppStrings.dockGitHub), findsOneWidget);
      expect(find.text(AppStrings.dockLinkedIn), findsOneWidget);
      expect(find.text(AppStrings.dockMedium), findsOneWidget);
      expect(find.text(AppStrings.dockPubDev), findsOneWidget);
      expect(find.text(AppStrings.dockResume), findsOneWidget);
      expect(find.text(AppStrings.dockEmail), findsOneWidget);
    });

    testWidgets(
      'tapping app card opens full-screen window and closes via red button',
      (tester) async {
        await tester.pumpWidget(const MaterialApp(home: MobileFallbackPage()));

        // Tap ABOUT pocket app
        await tester.tap(find.text(AppStrings.mobileAppAbout));
        await tester.pumpAndSettle();

        expect(find.text(AppStrings.mobileAppAboutTitle), findsOneWidget);
        expect(find.text(AppStrings.mobileEsc), findsOneWidget);

        // Tap close button (the red traffic light with close icon)
        await tester.tap(find.byIcon(Icons.close));
        await tester.pumpAndSettle();

        expect(find.text(AppStrings.mobileAppAboutTitle), findsNothing);
      },
    );

    testWidgets(
      'tapping app card opens full-screen window and closes via ESC button',
      (tester) async {
        tester.view.physicalSize = const Size(600, 1200);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(const MaterialApp(home: MobileFallbackPage()));

        // Tap SNAKE pocket app
        await tester.tap(find.text(AppStrings.mobileAppSnake));
        await tester.pumpAndSettle();

        expect(find.text(AppStrings.mobileAppSnakeTitle), findsOneWidget);
        expect(
          find.byIcon(Icons.arrow_drop_up),
          findsOneWidget,
        ); // D-pad is visible on mobile

        // Tap ESC button
        await tester.tap(find.text(AppStrings.mobileEsc));
        await tester.pumpAndSettle();

        expect(find.text(AppStrings.mobileAppSnakeTitle), findsNothing);
      },
    );
  });

  group('MobileFallbackPage status bar', () {
    testWidgets('clock follows the time source on each one-second tick', (
      tester,
    ) async {
      var now = DateTime(2024, 1, 1, 9, 5, 59);
      await tester.pumpWidget(
        MaterialApp(home: MobileFallbackPage(clock: () => now)),
      );
      expect(find.text('09:05'), findsOneWidget);

      // The minute rolls over, but the label only catches up on the next tick.
      now = DateTime(2024, 1, 1, 9, 6);
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text('09:05'), findsOneWidget);

      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text('09:06'), findsOneWidget);
      expect(find.text('09:05'), findsNothing);

      // Unmount and let further ticks go by: the page is gone, so nothing may
      // fire any more. The test binding also fails a test that ends with a
      // timer still scheduled, which is what a leaked clock timer would be.
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 2));
      expect(tester.takeException(), isNull);
    });

    testWidgets('clock shows the wall time as HH:mm by default', (
      tester,
    ) async {
      String hhmm(DateTime t) =>
          '${t.hour.toString().padLeft(2, '0')}:'
          '${t.minute.toString().padLeft(2, '0')}';

      final before = DateTime.now();
      await tester.pumpWidget(const MaterialApp(home: MobileFallbackPage()));
      final after = DateTime.now();

      // `before`/`after` differ only if the run straddles a minute boundary.
      final clock = find.textContaining(RegExp(r'^\d{2}:\d{2}$'));
      expect(tester.widget<Text>(clock).data, anyOf(hhmm(before), hhmm(after)));
    });

    testWidgets('mute button silences the shared sound service and back', (
      tester,
    ) async {
      final deps = await _pumpWithDeps(tester);

      expect(find.byIcon(Icons.volume_off), findsNothing);
      expect(
        tester.widget<Icon>(find.byIcon(Icons.volume_up)).color,
        AppTheme.green,
      );

      await tester.tap(find.byIcon(Icons.volume_up));
      await tester.pump();

      expect(deps.sound.isMuted, isTrue);
      expect(find.byIcon(Icons.volume_up), findsNothing);
      expect(
        tester.widget<Icon>(find.byIcon(Icons.volume_off)).color,
        AppTheme.subtext,
      );
      // Muting is silent: no click is played on the way down.
      expect(deps.sound.events, ['mute']);

      await tester.tap(find.byIcon(Icons.volume_off));
      await tester.pump();

      expect(deps.sound.isMuted, isFalse);
      expect(find.byIcon(Icons.volume_up), findsOneWidget);
      // Un-muting confirms itself with a click.
      expect(deps.sound.events, ['mute', 'unmute', 'click']);
    });

    testWidgets('starts muted when the shared sound service already is', (
      tester,
    ) async {
      await _pumpWithDeps(tester, sound: _RecordingSoundService(muted: true));

      expect(find.byIcon(Icons.volume_off), findsOneWidget);
      expect(find.byIcon(Icons.volume_up), findsNothing);
    });

    testWidgets('mute button works without AppDependencies', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: MobileFallbackPage()));

      await tester.tap(find.byIcon(Icons.volume_up));
      await tester.pump();
      expect(find.byIcon(Icons.volume_off), findsOneWidget);

      await tester.tap(find.byIcon(Icons.volume_off));
      await tester.pump();
      expect(find.byIcon(Icons.volume_up), findsOneWidget);
    });

    testWidgets('language menu lists the five languages, current one in blue', (
      tester,
    ) async {
      await _pumpWithDeps(tester, localeCode: 'pt');

      // The status bar label follows the locale view model.
      expect(find.text('PT'), findsOneWidget);
      expect(find.text('EN'), findsNothing);

      await tester.tap(find.byIcon(Icons.language));
      await tester.pumpAndSettle();

      expect(find.byType(PopupMenuItem<String>), findsNWidgets(5));
      for (final flag in ['🇺🇸', '🇧🇷', '🇪🇸', '🇫🇷', '🇮🇹']) {
        expect(find.text(flag), findsOneWidget, reason: flag);
      }

      Finder menuLabel(String code) => find.descendant(
        of: find.byType(PopupMenuItem<String>),
        matching: find.text(code),
      );
      expect(_textColor(tester, menuLabel('PT')), AppTheme.blue);
      for (final code in ['EN', 'ES', 'FR', 'IT']) {
        expect(_textColor(tester, menuLabel(code)), AppTheme.text);
      }
    });

    testWidgets('picking a language switches the locale and clicks', (
      tester,
    ) async {
      final deps = await _pumpWithDeps(tester);
      expect(find.text('EN'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.language));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(PopupMenuItem<String>, 'PT'));
      await tester.pumpAndSettle();

      expect(deps.locale.currentCode, 'pt');
      expect(deps.sound.events, ['click']);
      // Menu is gone and the status bar label now reads the new language.
      expect(find.byType(PopupMenuItem<String>), findsNothing);
      expect(find.text('PT'), findsOneWidget);
      expect(find.text('EN'), findsNothing);
    });

    testWidgets('picking a language without AppDependencies is a no-op', (
      tester,
    ) async {
      await tester.pumpWidget(const MaterialApp(home: MobileFallbackPage()));
      expect(find.text('EN'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.language));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(PopupMenuItem<String>, 'FR'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(PopupMenuItem<String>), findsNothing);
      expect(find.text('EN'), findsOneWidget);
    });
  });

  group('MobileFallbackPage wallpaper', () {
    testWidgets('scrolling moves the wallpaper at 30% of the scroll offset', (
      tester,
    ) async {
      await tester.pumpWidget(const MaterialApp(home: MobileFallbackPage()));

      final wallpaperShift = find.descendant(
        of: find.byType(MobileFallbackPage),
        matching: find.ancestor(
          of: find.byType(PixelWallpaper),
          matching: find.byType(Transform),
        ),
      );
      double shiftY() =>
          tester.widget<Transform>(wallpaperShift).transform.getTranslation().y;

      expect(wallpaperShift, findsOneWidget);
      expect(shiftY(), 0.0);

      await tester.drag(
        find.byType(SingleChildScrollView),
        const Offset(0, -200),
      );
      await tester.pump();

      final scrolled =
          tester
              .state<ScrollableState>(find.byType(Scrollable).first)
              .position
              .pixels;
      expect(scrolled, greaterThan(0));
      expect(shiftY(), closeTo(-scrolled * 0.3, 1e-9));
    });
  });

  group('MobileFallbackPage links', () {
    testWidgets('GitHub profile link launches the GitHub URL', (tester) async {
      final log = _mockUrlLauncher(tester);
      await tester.pumpWidget(const MaterialApp(home: MobileFallbackPage()));

      await tester.tap(find.text(AppStrings.mobileGitHubLink));
      await _flushLaunches(tester);

      expect(log.checked, [AppStrings.urlGitHub]);
      expect(log.launched, [AppStrings.urlGitHub]);
    });

    testWidgets('nothing is launched when the platform cannot open the URL', (
      tester,
    ) async {
      final log = _mockUrlLauncher(tester, canLaunch: false);
      await tester.pumpWidget(const MaterialApp(home: MobileFallbackPage()));

      await tester.tap(find.text(AppStrings.mobileGitHubLink));
      await _flushLaunches(tester);

      expect(log.checked, [AppStrings.urlGitHub]);
      expect(log.launched, isEmpty);
    });

    testWidgets('each quick dock entry clicks and launches its own URL', (
      tester,
    ) async {
      _useSurface(tester, const Size(600, 1600));
      final log = _mockUrlLauncher(tester);
      final deps = await _pumpWithDeps(tester);

      const entries = [
        (AppStrings.dockGitHub, AppStrings.urlGitHub),
        (AppStrings.dockLinkedIn, AppStrings.urlLinkedIn),
        (AppStrings.dockMedium, AppStrings.urlMedium),
        (AppStrings.dockPubDev, AppStrings.urlPubDev),
        (AppStrings.dockResume, AppStrings.urlResume),
        (AppStrings.dockEmail, AppStrings.emailAddress),
      ];

      for (final (label, url) in entries) {
        await tester.ensureVisible(find.text(label));
        await tester.pump();
        await tester.tap(find.text(label));
        await _flushLaunches(tester);

        expect(log.launched.last, url, reason: label);
      }

      expect(log.launched, [for (final (_, url) in entries) url]);
      expect(deps.sound.events, List.filled(entries.length, 'click'));
    });
  });

  group('MobileFallbackPage app windows', () {
    const simpleApps = [
      (
        AppStrings.mobileAppSkills,
        AppStrings.mobileAppSkillsTitle,
        AppTheme.mauve,
        SkillsWindowContent,
      ),
      (
        AppStrings.mobileAppTerminal,
        AppStrings.mobileAppTerminalTitle,
        AppTheme.green,
        TerminalContent,
      ),
      (
        AppStrings.mobileAppCalc,
        AppStrings.mobileAppCalcTitle,
        AppTheme.peach,
        CalculatorContent,
      ),
      (
        AppStrings.mobileAppMetrics,
        AppStrings.mobileAppMetricsTitle,
        AppTheme.teal,
        ProjectStatsWindowContent,
      ),
      (
        AppStrings.mobileAppLava,
        AppStrings.mobileAppLavaTitle,
        AppTheme.peach,
        LavaStudioContent,
      ),
    ];

    for (final (card, title, accent, content) in simpleApps) {
      testWidgets('$card card opens the "$title" window and ESC returns', (
        tester,
      ) async {
        _useSurface(tester, const Size(430, 932));
        await _pumpLocalized(tester);

        expect(find.text(card), findsOneWidget);
        expect(find.byType(content), findsNothing);

        await _openApp(tester, card);

        expect(tester.takeException(), isNull);
        expect(_windowTitle(title, accent), findsOneWidget);
        expect(find.byType(content), findsOneWidget);
        // The launcher underneath is fully covered by the opaque window.
        expect(find.text(AppStrings.mobilePocketApps), findsNothing);

        await tester.tap(find.text(AppStrings.mobileEsc));
        await _waitForClose(tester);

        expect(find.byType(content), findsNothing);
        expect(find.text(AppStrings.mobileEsc), findsNothing);
        expect(find.text(AppStrings.mobilePocketApps), findsOneWidget);
      });
    }

    testWidgets('ABOUT shows the localized role and bio', (tester) async {
      _useSurface(tester, const Size(430, 932));
      await _pumpLocalized(tester, locale: const Locale('pt'));
      final pt = AppLocalizations(const Locale('pt'));
      // Guards the test itself: the fallback role must not match by accident.
      expect(pt.role, isNot(AppStrings.mobileDefaultRole));

      await _openApp(tester, AppStrings.mobileAppAbout);

      final about = tester.widget<AboutWindowContent>(
        find.byType(AboutWindowContent),
      );
      expect(about.role, pt.role);
      expect(about.bio, pt.bio);
      expect(find.text(pt.role), findsOneWidget);
      expect(find.text(pt.bio), findsOneWidget);
    });

    testWidgets('ABOUT falls back to the default role without localizations', (
      tester,
    ) async {
      await tester.pumpWidget(const MaterialApp(home: MobileFallbackPage()));

      await _openApp(tester, AppStrings.mobileAppAbout);

      final about = tester.widget<AboutWindowContent>(
        find.byType(AboutWindowContent),
      );
      expect(about.role, AppStrings.mobileDefaultRole);
      expect(about.bio, isEmpty);
      expect(find.text(AppStrings.mobileDefaultRole), findsOneWidget);
    });

    testWidgets('EXPERIENCE lists one card per localized experience', (
      tester,
    ) async {
      _useSurface(tester, const Size(600, 4000));
      await _pumpLocalized(tester);
      final experiences = AppLocalizations(const Locale('en')).experiences;
      expect(experiences, isNotEmpty);

      await _openApp(tester, AppStrings.mobileAppExperience);

      expect(
        _windowTitle(AppStrings.mobileAppExperienceTitle, AppTheme.peach),
        findsOneWidget,
      );
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(
        find.byType(ExperienceWindowContent),
        findsNWidgets(experiences.length),
      );

      final cards =
          tester
              .widgetList<ExperienceWindowContent>(
                find.byType(ExperienceWindowContent),
              )
              .toList();
      for (var i = 0; i < experiences.length; i++) {
        final company = experiences[i]['company'] as String;
        expect(cards[i].experience.company, company);
        expect(cards[i].experience.period, experiences[i]['period']);
        expect(find.text(company), findsOneWidget);
      }
      // Accent colour is resolved per company.
      expect(cards[0].experience.company, contains('Zallpy'));
      expect(cards[0].accentColor, AppTheme.teal);
      expect(cards[1].experience.company, contains('Pan'));
      expect(cards[1].accentColor, AppTheme.blue);
    });

    testWidgets('EXPERIENCE shows a spinner when there is nothing to list', (
      tester,
    ) async {
      // No localization delegate -> no experiences.
      await tester.pumpWidget(const MaterialApp(home: MobileFallbackPage()));

      await _openApp(tester, AppStrings.mobileAppExperience);

      expect(
        _windowTitle(AppStrings.mobileAppExperienceTitle, AppTheme.peach),
        findsOneWidget,
      );
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.byType(ExperienceWindowContent), findsNothing);
    });

    testWidgets('PROJECTS lists the four projects with their descriptions', (
      tester,
    ) async {
      _useSurface(tester, const Size(600, 1600));
      await _pumpLocalized(tester);

      await _openApp(tester, AppStrings.mobileAppProjects);

      expect(
        _windowTitle(AppStrings.mobileAppProjectsTitle, AppTheme.teal),
        findsOneWidget,
      );
      const projects = [
        (
          AppStrings.projectInterceptedName,
          AppStrings.projectInterceptedDesc,
          AppTheme.teal,
        ),
        (
          AppStrings.projectHomelabName,
          AppStrings.projectHomelabDesc,
          AppTheme.blue,
        ),
        (
          AppStrings.projectLiturgicalName,
          AppStrings.projectLiturgicalDesc,
          AppTheme.peach,
        ),
        (
          AppStrings.projectLazyLoadName,
          AppStrings.projectLazyLoadDesc,
          AppTheme.mauve,
        ),
      ];
      var previousY = double.negativeInfinity;
      for (final (name, description, color) in projects) {
        expect(find.text(name), findsOneWidget);
        expect(find.text(description), findsOneWidget);
        expect(_textColor(tester, find.text(name)), color, reason: name);
        // Cards keep the declared order, top to bottom.
        final y = tester.getTopLeft(find.text(name)).dy;
        expect(y, greaterThan(previousY), reason: name);
        previousY = y;
      }
      // Every project links to GitHub; only the two packages link to pub.dev.
      expect(find.text(AppStrings.projectBtnGitHub), findsNWidgets(4));
      expect(find.text(AppStrings.projectBtnPubDev), findsNWidgets(2));
    });

    testWidgets('PROJECTS buttons launch the repository and package URLs', (
      tester,
    ) async {
      _useSurface(tester, const Size(600, 1600));
      final log = _mockUrlLauncher(tester);
      await _pumpLocalized(tester);
      await _openApp(tester, AppStrings.mobileAppProjects);

      final gitHubButtons = find.text(AppStrings.projectBtnGitHub);
      for (var i = 0; i < 4; i++) {
        await tester.tap(gitHubButtons.at(i));
        await _flushLaunches(tester);
      }
      expect(log.launched, [
        AppStrings.urlGitHubIntercepted,
        AppStrings.urlGitHubHomelab,
        AppStrings.urlGitHubLiturgical,
        AppStrings.urlGitHubLazyLoad,
      ]);

      log.launched.clear();
      final pubDevButtons = find.text(AppStrings.projectBtnPubDev);
      for (var i = 0; i < 2; i++) {
        await tester.tap(pubDevButtons.at(i));
        await _flushLaunches(tester);
      }
      expect(log.launched, [
        AppStrings.urlPubDevIntercepted,
        AppStrings.urlPubDevLazyLoad,
      ]);
    });

    testWidgets('GUESTBOOK opens on the shared guestbook view model', (
      tester,
    ) async {
      _useSurface(tester, const Size(430, 932));
      final deps = await _pumpWithDeps(tester);

      await _openApp(tester, AppStrings.mobileAppGuestbook);

      expect(
        _windowTitle(AppStrings.mobileAppGuestbookTitle, AppTheme.mauve),
        findsOneWidget,
      );
      final guestbook = tester.widget<GuestbookContent>(
        find.byType(GuestbookContent),
      );
      expect(guestbook.viewModel, same(deps.guestbook));
      // The message served by the injected repository is on screen.
      expect(find.text('Ada Lovelace'), findsOneWidget);
      expect(find.text('Lovely pocket edition!'), findsOneWidget);
    });

    testWidgets('GUESTBOOK stays closed when no view model is available', (
      tester,
    ) async {
      _useSurface(tester, const Size(430, 932));
      await _pumpLocalized(tester);

      await _openApp(tester, AppStrings.mobileAppGuestbook);

      expect(tester.takeException(), isNull);
      expect(find.byType(GuestbookContent), findsNothing);
      expect(find.text(AppStrings.mobileEsc), findsNothing);
      expect(find.text(AppStrings.mobilePocketApps), findsOneWidget);
    });

    testWidgets('opening and closing a window plays click, open, then close', (
      tester,
    ) async {
      _useSurface(tester, const Size(430, 932));
      final deps = await _pumpWithDeps(tester);

      await _openApp(tester, AppStrings.mobileAppCalc);
      expect(find.byType(CalculatorContent), findsOneWidget);
      expect(deps.sound.events, ['click', 'windowOpen']);

      await tester.tap(find.byIcon(Icons.close));
      await _waitForClose(tester);

      expect(find.byType(CalculatorContent), findsNothing);
      expect(deps.sound.events, ['click', 'windowOpen', 'windowClose']);
    });

    testWidgets('system back closes the window and plays the close sound', (
      tester,
    ) async {
      _useSurface(tester, const Size(430, 932));
      final deps = await _pumpWithDeps(tester);

      await _openApp(tester, AppStrings.mobileAppSkills);
      expect(find.byType(SkillsWindowContent), findsOneWidget);

      final handled = await tester.binding.handlePopRoute();
      await _waitForClose(tester);

      expect(handled, isTrue);
      expect(find.byType(SkillsWindowContent), findsNothing);
      expect(find.text(AppStrings.mobilePocketApps), findsOneWidget);
      expect(deps.sound.events.last, 'windowClose');
    });
  });
}
