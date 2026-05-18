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

import 'l10n/app_localizations.dart';
import 'shared/models/experience.dart';
import 'shared/widgets/about_window_content.dart';
import 'shared/widgets/android_dev_window_content.dart';
import 'shared/widgets/calculator_content.dart';
import 'shared/widgets/contact_form_content.dart';
import 'shared/widgets/desktop_icon.dart';
import 'shared/widgets/experience_window_content.dart';
import 'shared/widgets/finder_content.dart';
import 'shared/widgets/mac_menu_bar.dart';
import 'shared/widgets/pixel_wallpaper.dart';
import 'shared/widgets/project_window_content.dart';
import 'shared/widgets/rubber_band_selection.dart';
import 'shared/widgets/skills_window_content.dart';
import 'shared/widgets/snake_game_content.dart';
import 'shared/widgets/sticky_note.dart';
import 'theme/app_theme.dart';

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
