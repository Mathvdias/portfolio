# Architecture

## Overview

This portfolio is a Flutter web application using **MVVM** architecture with Flutter-native
state management — no external state management or DI libraries.

```
portifolio/
├── lib/
│   ├── core/                     # Framework-level utilities
│   │   ├── di/                   # AppDependencies (InheritedWidget)
│   │   ├── errors/               # AppFailure sealed class
│   │   ├── result/               # Result<T> sealed class
│   │   └── extensions/           # BuildContext extensions
│   ├── features/                 # Self-contained feature modules
│   │   ├── desktop/              # Desktop UI + window management
│   │   ├── localization/         # Locale switching
│   │   └── visitors/             # Visitor count tracking
│   ├── shared/
│   │   ├── models/               # Shared data classes (Experience)
│   │   └── widgets/              # Reusable UI components
│   ├── l10n/                     # AppLocalizations + delegate
│   ├── theme/                    # AppTheme (Catppuccin Mocha)
│   └── main.dart                 # App entry point + DI setup
└── packages/
    ├── app_window/               # Draggable OS-style window widget
    └── pixel_art/                # 16×16 pixel-art painter + patterns
```

---

## Layers

Each feature follows the same three-layer structure:

```
feature/
├── domain/
│   ├── entities/       # Pure Dart data classes (no Flutter deps)
│   └── repositories/   # Abstract interfaces
├── data/
│   ├── datasources/    # Raw I/O (HTTP, Firestore, SharedPrefs)
│   └── repositories/   # Concrete implementations
└── presentation/
    └── viewmodels/     # ChangeNotifier — business logic + state
```

**Dependency rule:** domain knows nothing about data or Flutter.
Data depends on domain. Presentation depends on domain only.

---

## State Management

| Concern | Tool |
|---------|------|
| App-wide dependencies | `AppDependencies` (InheritedWidget) |
| ViewModel → View rebuild | `ListenableBuilder` |
| ViewModel state | `ChangeNotifier` |
| Locale reactivity | `ListenableBuilder` wrapping `LocaleViewModel` |

No Provider, Bloc, Riverpod, or GetX. All Flutter built-ins.

---

## Dependency Injection

`AppDependencies` is a single `InheritedWidget` instantiated in `_AppRootState`.
It holds:
- `LocaleViewModel` — locale state
- `VisitorRepository` — visitor data access

ViewModels are created by the page's `State` using `AppDependencies.of(context)`.

```dart
// In _DesktopPageState.initState():
final deps = AppDependencies.of(context);
_visitorVM = VisitorViewModel(deps.visitorRepository)..init();
```

---

## Error Handling

The `Result<T>` sealed class wraps all repository return values:

```dart
sealed class Result<T> { ... }
final class Success<T> extends Result<T> { final T value; }
final class Failure<T> extends Result<T> { final AppFailure failure; }
```

Consume with `.fold()`:
```dart
result.fold(
  (failure) => _status = Status.failure,
  (value)   => _data = value,
);
```

---

## Internal Packages

### `packages/app_window`
Draggable, macOS-style window widget with configurable traffic-light controls.
No dependency on app theme — all colors are constructor parameters.

```dart
AppWindow(
  title: 'Terminal',
  titleBarColor: AppTheme.surface,
  closeColor: AppTheme.red,
  onClose: () => vm.closeWindow('terminal'),
  child: const TerminalContent(),
)
```

### `packages/pixel_art`
16×16 pixel-art `CustomPainter` + 19 pre-defined icon patterns.

```dart
CustomPaint(
  painter: PixelIconPainter(pixels: kTerminalPixels, color: AppTheme.green),
)
```

---

## Adding a New Feature

1. Create `lib/features/<name>/` with `domain/`, `data/`, `presentation/` directories
2. Define the abstract repository in `domain/repositories/`
3. Implement it in `data/repositories/` using a datasource
4. Create a `ChangeNotifier` ViewModel in `presentation/viewmodels/`
5. Add the repository to `AppDependencies` and wire it in `main.dart`
6. Write unit tests for the ViewModel and repository

---

## Testing Strategy

| Type | Location | What it tests |
|------|----------|---------------|
| Unit | `test/unit/` | ViewModels and domain logic with fake repos |
| Widget | `test/widgets/` | Individual widgets in isolation |
| Smoke | `test/widget_test.dart` | Core MVVM primitives |
| Package | `packages/*/test/` | Package-level logic |
| Integration | `integration_test/` | Full app boot flow |
