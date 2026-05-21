import 'dart:async';

import 'package:app_window/app_window.dart';
import 'package:flutter/material.dart';
import 'package:flutter_lazy_load_web/flutter_lazy_load_web.dart';

import '../../../../core/di/app_dependencies.dart';
import '../../../../core/services/analytics_service.dart';
import '../../../../features/desktop/domain/models/desktop_notification.dart';
import '../../../../features/desktop/presentation/viewmodels/desktop_viewmodel.dart';
import '../../../../features/guestbook/presentation/widgets/guestbook_content.dart'
    deferred as guestbook_content;
import '../../../../features/visitors/presentation/viewmodels/visitor_viewmodel.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/constants/app_sizes.dart';
import '../../../../shared/constants/app_strings.dart';
import '../../../../shared/mappers/experience_mapper.dart';
// Window content — deferred so each chunk is downloaded only when the
// user opens that window for the first time.
import '../../../../shared/widgets/about_window_content.dart'
    deferred as about_content;
import '../../../../shared/widgets/android_dev_window_content.dart'
    deferred as android_content;
import '../../../../shared/widgets/flutter_dev_window_content.dart'
    deferred as flutter_content;
import '../../../../shared/widgets/calculator_content.dart'
    deferred as calculator_content;
import '../../../../shared/widgets/contact_form_content.dart'
    deferred as contact_content;
// Shell widgets — always visible, kept as eager imports.
import '../../../../shared/widgets/desktop_context_menu.dart';
import '../../../../shared/widgets/desktop_icons_grid.dart';
import '../../../../shared/widgets/dock.dart';
import '../../../../shared/widgets/finder_content.dart'
    deferred as finder_content;
import '../../../../shared/widgets/licenses_window_content.dart'
    deferred as licenses_content;
import '../../../../shared/widgets/mac_menu_bar.dart';
import '../../../../shared/widgets/mobile_fallback_page.dart';
import '../../../../shared/widgets/notification_center.dart';
import '../../../../shared/widgets/pixel_wallpaper.dart';
import '../../../../shared/widgets/project_stats_window_content.dart'
    deferred as stats_content;
import '../../../../shared/widgets/responsive_layout.dart';
import '../../../../shared/widgets/rubber_band_selection.dart';
import '../../../../shared/widgets/skills_window_content.dart'
    deferred as skills_content;
import '../../../../shared/widgets/snake_game_content.dart'
    deferred as snake_content;
import '../../../../shared/widgets/spotlight_overlay.dart';
import '../../../../shared/widgets/sticky_note.dart';
import '../../../../shared/widgets/terminal_content.dart'
    deferred as terminal_content;
import '../../../../theme/app_theme.dart';

class DesktopPage extends StatefulWidget {
  const DesktopPage({super.key});

  @override
  State<DesktopPage> createState() => _DesktopPageState();
}

class _DesktopPageState extends State<DesktopPage> {
  late DesktopViewModel _desktopVM;
  late AnalyticsService _analytics;
  late VisitorViewModel _visitorVM;
  bool _initialized = false;

  // Local rubber-band state — never calls notifyListeners during drag.
  final _selectionNotifier = ValueNotifier<(Offset, Offset)?>(null);

  // Analytics session tracking.
  bool _firstWindowOpened = false;
  final _windowOpenTimes = <String, DateTime>{};

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final deps = AppDependencies.of(context);
    _desktopVM = deps.desktopViewModel;
    _analytics = deps.analyticsService;

    // Register window handler
    _desktopVM.onOpenWindowById ??= (id, ctx) {
      final l10n = AppLocalizations.of(ctx);
      _openWindowForId(id, l10n);
    };

    if (!_initialized) {
      _initialized = true;
      _visitorVM = VisitorViewModel(deps.visitorRepository)..init();
      unawaited(
        _analytics.logLocaleView(
          deps.localeViewModel.currentCode,
          initial: true,
        ),
      );

      WidgetsBinding.instance.addPostFrameCallback((_) {
        final l10n = AppLocalizations.of(context);
        _desktopVM.addNotification(
          DesktopNotification(
            title: l10n.welcomeTitle,
            message: l10n.welcomeBody,
            icon: Icons.waving_hand,
            color: AppTheme.blue,
            time: DateTime.now(),
          ),
        );
      });
    }

    final guestbookVM = deps.guestbookViewModel;
    guestbookVM.onNotification ??= (notif) {
      _desktopVM.addNotification(notif);
    };
  }

  @override
  void dispose() {
    _visitorVM.dispose();
    _selectionNotifier.dispose();
    super.dispose();
  }

  // ── Deferred load timing ─────────────────────────────────────────

  Future<void> Function() _trackedLoad(
    String windowId,
    Future<void> Function() loader,
  ) {
    return () async {
      final sw = Stopwatch()..start();
      await loader();
      sw.stop();
      unawaited(
        _analytics.logDeferredLoad(
          windowId: windowId,
          durationMs: sw.elapsedMilliseconds,
          fromCache: sw.elapsedMilliseconds < 10,
        ),
      );
    };
  }

  // ── Spotlight items ──────────────────────────────────────────────
  List<SpotlightItem> _buildSpotlightItems(AppLocalizations l10n) {
    return [
      SpotlightItem(
        id: AppStrings.winAbout,
        label: l10n.about,
        iconWidget: const Icon(Icons.person),
        color: AppTheme.blue,
      ),
      const SpotlightItem(
        id: AppStrings.winFinder,
        label: AppStrings.titleFinder,
        iconWidget: Icon(Icons.folder),
        color: AppTheme.red,
      ),
      const SpotlightItem(
        id: AppStrings.winSkills,
        label: AppStrings.titleSkills,
        iconWidget: Icon(Icons.star),
        color: AppTheme.blue,
      ),
      SpotlightItem(
        id: AppStrings.winAndroid,
        label: l10n.androidDev,
        iconWidget: const Icon(Icons.android),
        color: AppTheme.green,
      ),
      const SpotlightItem(
        id: AppStrings.winFlutter,
        label: AppStrings.titleFlutter,
        iconWidget: Icon(Icons.flutter_dash),
        color: AppTheme.blue,
      ),
      const SpotlightItem(
        id: AppStrings.winTerminal,
        label: AppStrings.titleTerminal,
        iconWidget: Icon(Icons.terminal),
        color: AppTheme.green,
      ),
      const SpotlightItem(
        id: AppStrings.winCalculator,
        label: AppStrings.titleCalculator,
        iconWidget: Icon(Icons.calculate),
        color: AppTheme.peach,
      ),
      const SpotlightItem(
        id: AppStrings.winSnake,
        label: AppStrings.titleSnake,
        iconWidget: Icon(Icons.gamepad_rounded),
        color: AppTheme.peach,
      ),
      const SpotlightItem(
        id: AppStrings.winContact,
        label: AppStrings.titleContact,
        iconWidget: Icon(Icons.mail),
        color: AppTheme.teal,
      ),
      SpotlightItem(
        id: AppStrings.winGuestbook,
        label: l10n.guestbook,
        iconWidget: const Icon(Icons.book),
        color: AppTheme.mauve,
      ),
      SpotlightItem(
        id: AppStrings.winProjectStats,
        label: l10n.projectStats,
        iconWidget: const Icon(Icons.analytics),
        color: AppTheme.yellow,
      ),
    ];
  }

  void _onSpotlightSelect(SpotlightItem item, AppLocalizations l10n) {
    _desktopVM.closeSpotlight();
    unawaited(_analytics.logSpotlightSelect(item.id));
    _openWindowForId(item.id, l10n);
  }

  // ── Analytics helpers ────────────────────────────────────────────

  void _trackWindowOpen(String id) {
    if (!_firstWindowOpened) {
      _firstWindowOpened = true;
      unawaited(_analytics.logFirstWindow(id));
    }
    _windowOpenTimes[id] = DateTime.now();
    unawaited(_analytics.logWindowOpen(id));
  }

  void _trackWindowClose(String id) {
    unawaited(_analytics.logWindowClose(id));
    final openTime = _windowOpenTimes.remove(id);
    if (openTime != null) {
      final seconds = DateTime.now().difference(openTime).inSeconds;
      unawaited(_analytics.logWindowDwellTime(windowId: id, seconds: seconds));
    }
  }

  // ── Window opening ───────────────────────────────────────────────

  void _openWindowForId(String id, AppLocalizations l10n) {
    _trackWindowOpen(id);
    switch (id) {
      case AppStrings.winAbout:
        _desktopVM.openWindow(
          id,
          l10n.about,
          DeferredWidget(
            _trackedLoad(id, about_content.loadLibrary),
            () => about_content.AboutWindowContent(
              bio: l10n.bio,
              role: l10n.role,
            ),
          ),
          AppTheme.blue,
        );
      case AppStrings.winFinder:
        _desktopVM.openWindow(
          id,
          AppStrings.titleFinder,
          DeferredWidget(
            _trackedLoad(id, finder_content.loadLibrary),
            () => finder_content.FinderContent(),
          ),
          AppTheme.red,
        );
      case AppStrings.winSkills:
        _desktopVM.openWindow(
          id,
          AppStrings.titleSkills,
          DeferredWidget(
            _trackedLoad(id, skills_content.loadLibrary),
            () => skills_content.SkillsWindowContent(),
          ),
          AppTheme.blue,
        );
      case AppStrings.winAndroid:
        _desktopVM.openWindow(
          id,
          l10n.androidDev,
          DeferredWidget(
            _trackedLoad(id, android_content.loadLibrary),
            () => android_content.AndroidDevWindowContent(),
          ),
          AppTheme.green,
          width: 500,
          height: 700,
        );
      case AppStrings.winFlutter:
        _desktopVM.openWindow(
          id,
          AppStrings.titleFlutter,
          DeferredWidget(
            _trackedLoad(id, flutter_content.loadLibrary),
            () => flutter_content.FlutterDevWindowContent(),
          ),
          AppTheme.blue,
          width: 500,
          height: 700,
        );
      case AppStrings.winTerminal:
        _desktopVM.openWindow(
          id,
          AppStrings.titleTerminal,
          DeferredWidget(
            _trackedLoad(id, terminal_content.loadLibrary),
            () => terminal_content.TerminalContent(),
          ),
          AppTheme.green,
        );
      case AppStrings.winCalculator:
        _desktopVM.openWindow(
          id,
          AppStrings.titleCalculator,
          DeferredWidget(
            _trackedLoad(id, calculator_content.loadLibrary),
            () => calculator_content.CalculatorContent(),
          ),
          AppTheme.peach,
        );
      case AppStrings.winSnake:
        _desktopVM.openWindow(
          id,
          AppStrings.titleSnake,
          DeferredWidget(
            _trackedLoad(id, snake_content.loadLibrary),
            () => snake_content.SnakeGameContent(),
          ),
          AppTheme.peach,
        );
      case AppStrings.winContact:
        _desktopVM.openWindow(
          id,
          AppStrings.titleContact,
          DeferredWidget(
            _trackedLoad(id, contact_content.loadLibrary),
            () => contact_content.ContactFormContent(),
          ),
          AppTheme.teal,
        );
      case AppStrings.winGuestbook:
        final vm = AppDependencies.of(context).guestbookViewModel;
        _desktopVM.openWindow(
          id,
          l10n.guestbook,
          DeferredWidget(
            _trackedLoad(id, guestbook_content.loadLibrary),
            () => guestbook_content.GuestbookContent(viewModel: vm),
          ),
          AppTheme.mauve,
          width: 800,
          height: 600,
        );
      case AppStrings.winProjectStats:
        _desktopVM.openWindow(
          id,
          l10n.projectStats,
          DeferredWidget(
            _trackedLoad(id, stats_content.loadLibrary),
            () => stats_content.ProjectStatsWindowContent(),
          ),
          AppTheme.yellow,
        );
    }
  }

  // ── Context menu handler ─────────────────────────────────────────
  void _onContextAction(DesktopContextAction action, AppLocalizations l10n) {
    _desktopVM.closeContextMenu();
    unawaited(_analytics.logContextMenuAction(action.name));
    switch (action) {
      case DesktopContextAction.newNote:
        break;
      case DesktopContextAction.openTerminal:
        _openWindowForId(AppStrings.winTerminal, l10n);
      case DesktopContextAction.about:
        _openWindowForId(AppStrings.winAbout, l10n);
      case DesktopContextAction.spotlight:
        _desktopVM.openSpotlight();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (ResponsiveLayout.isMobile(context)) return const MobileFallbackPage();

    final l10n = AppLocalizations.of(context);
    final localeVM = AppDependencies.of(context).localeViewModel;
    final experiences = ExperienceMapper.fromL10n(l10n.experiences);

    // Focus(autofocus: true) ensures the desktop receives keyboard events
    // when no text field or button is focused. The actual shortcut dispatch
    // is handled by MaterialApp.shortcuts + MaterialApp.actions (AppShortcuts /
    // AppActions) so no onKeyEvent callback is needed here.
    return Focus(
      autofocus: true,
      child: Scaffold(
        backgroundColor: AppTheme.background,
        body: GestureDetector(
          onSecondaryTapUp: (details) {
            unawaited(_analytics.logContextMenuOpen());
            _desktopVM.openContextMenu(details.localPosition);
          },
          onPanStart: (details) {
            _desktopVM.closeContextMenu();
            _selectionNotifier.value = (
              details.localPosition,
              details.localPosition,
            );
          },
          onPanUpdate: (details) {
            final prev = _selectionNotifier.value;
            if (prev != null) {
              _selectionNotifier.value = (prev.$1, details.localPosition);
            }
          },
          onPanEnd: (_) => _selectionNotifier.value = null,
          child: Stack(
            children: [
              // Static layers — never rebuilt by VM changes.
              const Positioned.fill(child: PixelWallpaper()),

              StickyNote(
                initialPosition: const Offset(40, 100),
                text: l10n.stickyNoteTodo,
                color: const Color(0xFFFDE68A),
              ),

              ListenableBuilder(
                listenable: _visitorVM,
                builder:
                    (context, _) => VisitorStickyNote(
                      initialPosition: const Offset(40, 260),
                      color: const Color(0xFFBAE6FD),
                      visitorCount: _visitorVM.count,
                    ),
              ),

              Positioned.fill(
                top: AppSizes.menuBarOffset,
                bottom: AppSizes.desktopBottom,
                child: RepaintBoundary(
                  child: DesktopIconsGrid(
                    experiences: experiences,
                    onOpenWindow: (id, title, content, accent) {
                      _trackWindowOpen(id);
                      _desktopVM.openWindow(id, title, content, accent);
                    },
                  ),
                ),
              ),

              // Windows — rebuilt only when window list changes.
              ValueListenableBuilder<List<WindowEntry>>(
                valueListenable: _desktopVM.windowsNotifier,
                builder:
                    (context, windows, _) => Stack(
                      children:
                          windows
                              .map(
                                (w) => AppWindow(
                                  key: ValueKey(w.id),
                                  title: w.title,
                                  initialPosition: w.position,
                                  accentColor: w.accentColor,
                                  titleBarColor: AppTheme.surface,
                                  contentColor: AppTheme.background,
                                  borderColor: AppTheme.surface0,
                                  closeColor: AppTheme.red,
                                  minimizeColor: AppTheme.yellow,
                                  maximizeColor: AppTheme.green,
                                  width: w.width,
                                  height: w.height,
                                  titleBarHeight: AppSizes.windowTitleBarHeight,
                                  trafficLightSize:
                                      AppSizes.windowTrafficLightSize,
                                  trafficLightSpacing:
                                      AppSizes.windowTrafficLightSpacing,
                                  maximizeTopOffset: AppSizes.menuBarHeight,
                                  maximizeBottomOffset: AppSizes.desktopBottom,
                                  titleFontSize: AppSizes.fontXs,
                                  onClose: () {
                                    _trackWindowClose(w.id);
                                    _desktopVM.closeWindow(w.id);
                                  },
                                  onFocus: () => _desktopVM.focusWindow(w.id),
                                  child: w.content,
                                ),
                              )
                              .toList(),
                    ),
              ),

              // Notifications — rebuilt only when visibility changes.
              ValueListenableBuilder<bool>(
                valueListenable: _desktopVM.showNotificationsNotifier,
                builder: (context, showNotifications, _) {
                  if (!showNotifications) {
                    return const SizedBox.shrink();
                  }
                  return Positioned(
                    top: AppSizes.menuBarOffset,
                    right: 0,
                    bottom: 0,
                    child: RepaintBoundary(
                      child: NotificationCenter(desktopVM: _desktopVM),
                    ),
                  );
                },
              ),

              // Menu bar — static, own RepaintBoundary.
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: RepaintBoundary(
                  child: MacMenuBar(
                    currentLanguage: localeVM.currentCode,
                    onLanguageChanged: (code) {
                      unawaited(_analytics.logLocaleChange(code));
                      unawaited(_analytics.logLocaleView(code, initial: false));
                      localeVM.setLocaleByCode(code);
                    },
                    onSpotlight: () {
                      _desktopVM.openSpotlight();
                      unawaited(_analytics.logSpotlightOpen());
                    },
                    onToggleNotifications: _desktopVM.toggleNotifications,
                    onAppMenuAction: (action) async {
                      switch (action) {
                        case AppMenuAction.about:
                          _openWindowForId(AppStrings.winAbout, l10n);
                        case AppMenuAction.licenses:
                          _trackWindowOpen(AppStrings.winLicenses);
                          _desktopVM.openWindow(
                            AppStrings.winLicenses,
                            AppStrings.titleLicenses,
                            DeferredWidget(
                              _trackedLoad(
                                AppStrings.winLicenses,
                                licenses_content.loadLibrary,
                              ),
                              () => licenses_content.LicensesWindowContent(),
                            ),
                            AppTheme.teal,
                          );
                        case AppMenuAction.github:
                          break;
                        case AppMenuAction.linkedin:
                          break;
                      }
                    },
                  ),
                ),
              ),

              // Dock — static, own RepaintBoundary.
              const Positioned(
                bottom: AppSizes.dockBottomOffset,
                left: 0,
                right: 0,
                child: Center(child: RepaintBoundary(child: Dock())),
              ),

              // Rubber band — driven by local ValueNotifier, zero VM notifies.
              ValueListenableBuilder<(Offset, Offset)?>(
                valueListenable: _selectionNotifier,
                builder: (context, sel, _) {
                  if (sel == null) return const SizedBox.shrink();
                  return RubberBandSelection(origin: sel.$1, current: sel.$2);
                },
              ),

              // Context menu — rebuilt only when menu open/close changes.
              ValueListenableBuilder<Offset?>(
                valueListenable: _desktopVM.contextMenuPositionNotifier,
                builder: (context, contextMenuPosition, _) {
                  if (contextMenuPosition == null) {
                    return const SizedBox.shrink();
                  }
                  return DesktopContextMenu(
                    position: contextMenuPosition,
                    onAction: (action) => _onContextAction(action, l10n),
                    onDismiss: _desktopVM.closeContextMenu,
                  );
                },
              ),

              // Spotlight — rebuilt only when visibility changes.
              ValueListenableBuilder<bool>(
                valueListenable: _desktopVM.showSpotlightNotifier,
                builder: (context, showSpotlight, _) {
                  if (!showSpotlight) {
                    return const SizedBox.shrink();
                  }
                  return SpotlightOverlay(
                    items: _buildSpotlightItems(l10n),
                    onSelect: (item) => _onSpotlightSelect(item, l10n),
                    onDismiss: _desktopVM.closeSpotlight,
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
