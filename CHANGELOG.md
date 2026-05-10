# Changelog

All notable changes to this project will be documented in this file.
Format follows [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
versioning follows [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [Unreleased]

---

## [2.0.0] — 2026-05-10

### Architecture
- Migrated to **MVVM** with clean separation of layers: domain → data → presentation
- Replaced `provider` package with Flutter-native `InheritedWidget` + `ListenableBuilder`
- Introduced `AppDependencies` InheritedWidget as manual DI container (no external library)
- All ViewModels extend `ChangeNotifier`; views consume them via `ListenableBuilder`

### Added
- `DesktopViewModel` — manages window stack (open, close, focus, notifications)
- `LocaleViewModel` — drives app locale; replaces `LanguageController`
- `VisitorViewModel` — streams visitor count; subscribes to Firestore via repository
- `VisitorRepository` (abstract) + `VisitorRepositoryImpl` + `VisitorDatasource`
- `AppFailure` sealed class and `Result<T>` sealed class for typed error handling
- `AppLocale` enum with all 5 supported locales and helper extensions
- Internal package **`packages/app_window`** — standalone draggable OS-style window widget
- Internal package **`packages/pixel_art`** — 16×16 pixel-art painter + 19 icon patterns
- **36 tests** across unit, widget, and package suites (0 → 36)
- `docs/ARCHITECTURE.md` — layer diagram and contribution guide
- `integration_test/app_integration_test.dart` — boot smoke test

### Removed
- `provider` dependency (replaced by InheritedWidget)
- `flutter_staggered_animations` dependency (was unused)
- `GitHubService` and dynamic GitHub repo fetching (simplified to curated icons)
- `LanguageController` (replaced by `LocaleViewModel`)
- `lib/pages/home_page.dart` (desktop-first; home page removed)
- Old `lib/widgets/`, `lib/models/`, `lib/services/`, `lib/controllers/` directories

### Changed
- `main.dart` — `AppRoot` is now a `StatefulWidget`; no Provider wrap
- `lib/main.dart` → owns `LocaleViewModel`, `VisitorRepository` instances
- `DesktopPage` — pure UI; all state moved to `DesktopViewModel`
- `VisitorStickyNote` — now accepts `visitorCount` as param (no internal stream)
- `AppWindow` — moved to `packages/app_window`; fully configurable colors via params
- `PixelIconPainter` + all pixel patterns — moved to `packages/pixel_art`
- All widgets moved to `lib/shared/widgets/`
- `Experience` model moved to `lib/shared/models/`

---

## [1.5.0] — 2026-03-15

### Added
- MathOS retro boot screen on load (`screen_animation.dart`)
- WebAssembly build support
- Google Search Console verification tag

### Changed
- All URLs migrated to custom domain `matheusvinicius.dev.br`

---

## [1.4.0] — 2026-02-20

### Added
- SEO meta tags, PWA manifest and service worker
- Performance optimizations (image caching, lazy loading)
- Resume PDF download from icon

---

## [1.3.0] — 2025-12-10

### Added
- Visitor counter with Firestore integration
- Draggable sticky notes on desktop

---

## [1.2.0] — 2025-11-01

### Added
- Snake game window
- Calculator window
- Finder window (file browser mockup)

---

## [1.1.0] — 2025-10-01

### Added
- Terminal emulator with 10+ commands (help, whoami, neofetch, echo, open…)
- Multi-language support (EN, ES, FR, IT, PT)
- macOS-style dock with social links

---

## [1.0.0] — 2025-09-01

### Added
- Initial release: desktop portfolio with draggable windows
- Catppuccin Mocha dark theme
- Pixel-art desktop icons
- About, Experience, Skills, Contact windows
- GitHub API integration for project icons
- Responsive layout (desktop / tablet / mobile fallback)
