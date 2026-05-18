// ignore_for_file: unused_element
//
// Widget Previews — flutter widget-preview start
// Experimental: https://docs.flutter.dev/tools/widget-previewer
//
// Run:  flutter widget-preview start
// Then open the "Flutter Widget Preview" panel in VS Code / Android Studio.

import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/di/app_dependencies.dart';
import 'core/result/result.dart';
import 'core/services/analytics_service.dart';
import 'features/desktop/domain/models/desktop_notification.dart';
import 'features/desktop/presentation/viewmodels/desktop_viewmodel.dart';
import 'features/guestbook/data/repositories/guestbook_repository.dart';
import 'features/guestbook/domain/models/guestbook_message.dart';
import 'features/guestbook/presentation/viewmodels/guestbook_viewmodel.dart';
import 'features/guestbook/presentation/widgets/guestbook_content.dart';
import 'features/localization/presentation/viewmodels/locale_viewmodel.dart';
import 'features/visitors/domain/repositories/visitor_repository.dart';
import 'l10n/app_localizations.dart';
import 'shared/models/experience.dart';
import 'shared/widgets/about_window_content.dart';
import 'shared/widgets/android_dev_window_content.dart';
import 'shared/widgets/calculator_content.dart';
import 'shared/widgets/contact_form_content.dart';
import 'shared/widgets/desktop_icon.dart';
import 'shared/widgets/dock.dart';
import 'shared/widgets/experience_window_content.dart';
import 'shared/widgets/finder_content.dart';
import 'shared/widgets/mac_menu_bar.dart';
import 'shared/widgets/notification_center.dart';
import 'shared/widgets/pixel_wallpaper.dart';
import 'shared/widgets/project_window_content.dart';
import 'shared/widgets/rubber_band_selection.dart';
import 'shared/widgets/skills_window_content.dart';
import 'shared/widgets/snake_game_content.dart';
import 'shared/widgets/sticky_note.dart';
import 'shared/widgets/terminal_content.dart';
import 'theme/app_theme.dart';

// ── Fakes ─────────────────────────────────────────────────────────────────────
// These are never reachable from main.dart → tree-shaken out of production WASM.

class _FakeGuestbookRepo extends GuestbookRepository {
  static final _sample = [
    GuestbookMessage(
      id: '1',
      name: 'Alice',
      message: 'Amazing portfolio! The terminal easter egg is my favourite.',
      rating: 5,
      timestamp: DateTime(2026, 3, 10),
    ),
    GuestbookMessage(
      id: '2',
      name: 'Bob',
      message: 'Love the snake game and the pixel wallpaper. Very creative!',
      rating: 5,
      timestamp: DateTime(2026, 4, 2),
    ),
    GuestbookMessage(
      id: '3',
      name: 'Carol',
      message: 'Clean UI and fast load times. Great work.',
      rating: 4,
      timestamp: DateTime(2026, 5, 14),
    ),
  ];

  @override
  Stream<List<GuestbookMessage>> watchMessages() => Stream.value(_sample);
  @override
  Future<void> addMessage(String name, String message, int rating) async {}
  @override
  Future<void> deleteMessage(String id) async {}
}

class _FakeVisitorRepo implements VisitorRepository {
  @override
  Future<Result<void>> recordVisit() async => const Success(null);
  @override
  Stream<int> watchVisitorCount() => Stream.value(1337);
}

class _FakeAnalytics extends AnalyticsService {
  @override
  Future<void> logWindowOpen(String windowId) async {}
  @override
  Future<void> logWindowClose(String windowId) async {}
  @override
  Future<void> logLinkClick(String destination, String url) async {}
  @override
  Future<void> logResumeDownload() async {}
  @override
  Future<void> logLocaleChange(String locale) async {}
  @override
  Future<void> logLocaleView(String locale, {required bool initial}) async {}
  @override
  Future<void> logSpotlightOpen() async {}
  @override
  Future<void> logSpotlightSelect(String windowId) async {}
  @override
  Future<void> logContextMenuOpen() async {}
  @override
  Future<void> logContextMenuAction(String action) async {}
  @override
  Future<void> logGuestbookPost(int rating) async {}
  @override
  Future<void> logError(
    String errorType,
    String message, {
    String? stackTrace,
  }) async {}
  @override
  Future<void> logJankFrame({
    required int totalMs,
    required int buildMs,
    required int rasterMs,
    int? openWindowCount,
  }) async {}
  @override
  Future<void> logDeferredLoad({
    required String windowId,
    required int durationMs,
    required bool fromCache,
  }) async {}
  @override
  Future<void> logWindowDwellTime({
    required String windowId,
    required int seconds,
  }) async {}
  @override
  Future<void> logFirstWindow(String windowId) async {}
}

// Builds an AppDependencies subtree with fake implementations.
// Used for TerminalContent, Dock, and GuestbookContent previews.
Widget _withDeps({required Widget child, GuestbookViewModel? guestbookVM}) {
  final desktopVM = DesktopViewModel();
  final localeVM = LocaleViewModel()..init();
  return AppDependencies(
    localeViewModel: localeVM,
    visitorRepository: _FakeVisitorRepo(),
    guestbookViewModel:
        guestbookVM ?? GuestbookViewModel(_FakeGuestbookRepo(), _emptyPrefs()),
    desktopViewModel: desktopVM,
    analyticsService: _FakeAnalytics(),
    child: child,
  );
}

// Returns a synchronous SharedPreferences backed by an empty in-memory store.
// setMockInitialValues is @visibleForTesting but this file is dev-only and
// is fully tree-shaken from production WASM builds.
// ignore: invalid_use_of_visible_for_testing_member
SharedPreferences _emptyPrefs() {
  // ignore: invalid_use_of_visible_for_testing_member
  SharedPreferences.setMockInitialValues({});
  late SharedPreferences result;
  SharedPreferences.getInstance().then((p) => result = p);
  return result;
}

// ── Shared wrapper ────────────────────────────────────────────────────────────
// Provides Catppuccin Mocha theme + EN localizations to every preview.
// Must be a top-level public function so @Preview(wrapper:) can reference it.
Widget previewWrapper(Widget child) => MaterialApp(
  debugShowCheckedModeBanner: false,
  theme: AppTheme.darkTheme,
  localizationsDelegates: const [
    AppLocalizationsDelegate(),
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ],
  supportedLocales: const [Locale('en')],
  home: Scaffold(backgroundColor: AppTheme.background, body: child),
);

// ── PixelWallpaper ────────────────────────────────────────────────────────────

@Preview(name: 'PixelWallpaper', wrapper: previewWrapper, size: Size(600, 380))
Widget previewPixelWallpaper() => const PixelWallpaper();

// ── SnakeGameContent ──────────────────────────────────────────────────────────

@Preview(
  name: 'Snake — start screen',
  wrapper: previewWrapper,
  size: Size(420, 520),
)
Widget previewSnakeStart() => const SnakeGameContent(randomSeed: 42);

// ── CalculatorContent ─────────────────────────────────────────────────────────

@Preview(name: 'Calculator', wrapper: previewWrapper, size: Size(320, 520))
Widget previewCalculator() => const CalculatorContent();

// ── FinderContent ─────────────────────────────────────────────────────────────

@Preview(name: 'Finder', wrapper: previewWrapper, size: Size(520, 400))
Widget previewFinder() => const FinderContent();

// ── SkillsWindowContent ───────────────────────────────────────────────────────

@Preview(name: 'Skills', wrapper: previewWrapper, size: Size(520, 620))
Widget previewSkills() => const SkillsWindowContent();

// ── AboutWindowContent ────────────────────────────────────────────────────────

@Preview(name: 'About', wrapper: previewWrapper, size: Size(500, 300))
Widget previewAbout() => const AboutWindowContent(
  bio:
      'Flutter / Mobile Engineer based in Brazil.\n'
      'Passionate about pixel-perfect UIs and open source.\n'
      'Author of intercepted_http on pub.dev.',
  role: 'Flutter Engineer',
);

// ── AndroidDevWindowContent ───────────────────────────────────────────────────

@Preview(name: 'Android Dev', wrapper: previewWrapper, size: Size(520, 620))
Widget previewAndroidDev() => const AndroidDevWindowContent();

// ── ContactFormContent ────────────────────────────────────────────────────────

@Preview(name: 'Contact Form', wrapper: previewWrapper, size: Size(420, 360))
Widget previewContactForm() => const ContactFormContent();

// ── MacMenuBar ────────────────────────────────────────────────────────────────

@Preview(name: 'MacMenuBar — EN', wrapper: previewWrapper, size: Size(900, 42))
Widget previewMacMenuBarEn() => MacMenuBar(
  currentLanguage: 'en',
  onLanguageChanged: (_) {},
  onSpotlight: () {},
  onToggleNotifications: () {},
);

@Preview(name: 'MacMenuBar — PT', wrapper: previewWrapper, size: Size(900, 42))
Widget previewMacMenuBarPt() =>
    MacMenuBar(currentLanguage: 'pt', onLanguageChanged: (_) {});

// ── ProjectWindowContent ──────────────────────────────────────────────────────

@Preview(
  name: 'Project — with pub.dev',
  wrapper: previewWrapper,
  size: Size(520, 420),
)
Widget previewProjectWithPub() => const ProjectWindowContent(
  name: 'intercepted_http',
  description:
      'A Flutter package that intercepts HTTP requests and responses, '
      'making it easy to inspect, mock, and log network traffic.',
  githubUrl: 'https://github.com/Mathvdias/intercepted_http',
  pubDevUrl: 'https://pub.dev/packages/intercepted_http',
  version: '1.2.0',
  technologies: ['Dart', 'Flutter', 'HTTP'],
  accentColor: AppTheme.teal,
);

@Preview(
  name: 'Project — no pub.dev',
  wrapper: previewWrapper,
  size: Size(520, 420),
)
Widget previewProjectNoPub() => const ProjectWindowContent(
  name: 'portfolio',
  description: 'This portfolio — a macOS-inspired Flutter web app with WASM.',
  githubUrl: 'https://github.com/Mathvdias/portfolio',
  technologies: ['Flutter', 'WASM', 'Firebase'],
  accentColor: AppTheme.blue,
);

// ── ExperienceWindowContent ───────────────────────────────────────────────────

@Preview(name: 'Experience', wrapper: previewWrapper, size: Size(520, 440))
Widget previewExperience() => const ExperienceWindowContent(
  accentColor: AppTheme.mauve,
  experience: Experience(
    company: 'Zallpy Digital',
    role: 'Flutter Engineer',
    period: 'Sep 2024 – Present',
    description:
        'Building cross-platform mobile experiences with Flutter. '
        'Leading performance and architecture improvements.',
    technologies: ['Flutter', 'Dart', 'Firebase', 'REST APIs'],
  ),
);

// ── StickyNote ────────────────────────────────────────────────────────────────

@Preview(name: 'StickyNote', wrapper: previewWrapper, size: Size(260, 200))
Widget previewStickyNote() => StickyNote(
  initialPosition: Offset.zero,
  text: '✨ Welcome to my portfolio!\nFeel free to explore.',
);

@Preview(
  name: 'VisitorStickyNote',
  wrapper: previewWrapper,
  size: Size(260, 160),
)
Widget previewVisitorStickyNote() =>
    VisitorStickyNote(initialPosition: Offset.zero, visitorCount: 1337);

// ── DesktopIcon ───────────────────────────────────────────────────────────────

@Preview(name: 'DesktopIcon', wrapper: previewWrapper, size: Size(120, 120))
Widget previewDesktopIcon() => DesktopIcon(
  label: 'Terminal',
  iconWidget: const Icon(Icons.terminal, color: Colors.white, size: 36),
  color: AppTheme.green,
  onTap: () {},
);

// ── RubberBandSelection ───────────────────────────────────────────────────────

@Preview(
  name: 'RubberBandSelection',
  wrapper: previewWrapper,
  size: Size(400, 300),
)
Widget previewRubberBand() => Stack(
  children: [
    Container(color: AppTheme.background),
    const RubberBandSelection(
      origin: Offset(60, 60),
      current: Offset(280, 200),
    ),
  ],
);

// ── TerminalContent ───────────────────────────────────────────────────────────
// Needs AppDependencies for admin_login / admin_logout commands only.

@Preview(name: 'Terminal', wrapper: previewWrapper, size: Size(640, 480))
Widget previewTerminal() => _withDeps(child: const TerminalContent());

// ── NotificationCenter ────────────────────────────────────────────────────────

@Preview(
  name: 'NotificationCenter — empty',
  wrapper: previewWrapper,
  size: Size(320, 500),
)
Widget previewNotificationCenterEmpty() =>
    NotificationCenter(desktopVM: DesktopViewModel());

@Preview(
  name: 'NotificationCenter — with items',
  wrapper: previewWrapper,
  size: Size(320, 500),
)
Widget previewNotificationCenterFilled() {
  final vm =
      DesktopViewModel()
        ..addNotification(
          DesktopNotification(
            title: 'New Guestbook Message',
            message: 'Alice left a 5-star review!',
            icon: Icons.book,
            color: AppTheme.blue,
            time: DateTime.now(),
          ),
        )
        ..addNotification(
          DesktopNotification(
            title: 'Welcome',
            message: 'Visitor #1337 just arrived.',
            icon: Icons.people,
            color: AppTheme.green,
            time: DateTime.now().subtract(const Duration(minutes: 2)),
          ),
        );
  return NotificationCenter(desktopVM: vm);
}

// ── Dock ──────────────────────────────────────────────────────────────────────

@Preview(name: 'Dock', wrapper: previewWrapper, size: Size(600, 100))
Widget previewDock() => _withDeps(child: const Dock());

// ── GuestbookContent ──────────────────────────────────────────────────────────

@Preview(
  name: 'Guestbook — messages',
  wrapper: previewWrapper,
  size: Size(500, 700),
)
Widget previewGuestbookMessages() {
  final vm = GuestbookViewModel(_FakeGuestbookRepo(), _emptyPrefs());
  return GuestbookContent(viewModel: vm);
}

@Preview(
  name: 'Guestbook — admin view',
  wrapper: previewWrapper,
  size: Size(500, 700),
)
Widget previewGuestbookAdmin() {
  final vm = GuestbookViewModel(_FakeGuestbookRepo(), _emptyPrefs())
    ..setAdmin(true);
  return GuestbookContent(viewModel: vm);
}
