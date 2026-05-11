import 'package:app_window/app_window.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../../../../core/di/app_dependencies.dart';
import '../../../../features/desktop/presentation/viewmodels/desktop_viewmodel.dart';
import '../../../../features/guestbook/presentation/widgets/guestbook_content.dart';
import '../../../../features/visitors/presentation/viewmodels/visitor_viewmodel.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/constants/app_sizes.dart';
import '../../../../shared/constants/app_strings.dart';
import '../../../../shared/mappers/experience_mapper.dart';
import '../../../../shared/widgets/about_window_content.dart';
import '../../../../shared/widgets/android_dev_window_content.dart';
import '../../../../shared/widgets/calculator_content.dart';
import '../../../../shared/widgets/contact_form_content.dart';
import '../../../../shared/widgets/desktop_context_menu.dart';
import '../../../../shared/widgets/desktop_icons_grid.dart';
import '../../../../shared/widgets/dock.dart';
import '../../../../shared/widgets/finder_content.dart';
import '../../../../shared/widgets/licenses_window_content.dart';
import '../../../../shared/widgets/mac_menu_bar.dart';
import '../../../../shared/widgets/mobile_fallback_page.dart';
import '../../../../shared/widgets/notification_center.dart';
import '../../../../shared/widgets/pixel_wallpaper.dart';
import '../../../../shared/widgets/project_stats_window_content.dart';
import '../../../../shared/widgets/responsive_layout.dart';
import '../../../../shared/widgets/rubber_band_selection.dart';
import '../../../../shared/widgets/skills_window_content.dart';
import '../../../../shared/widgets/snake_game_content.dart';
import '../../../../shared/widgets/spotlight_overlay.dart';
import '../../../../shared/widgets/sticky_note.dart';
import '../../../../shared/widgets/terminal_content.dart';
import '../../../../theme/app_theme.dart';

class DesktopPage extends StatefulWidget {
  const DesktopPage({super.key});

  @override
  State<DesktopPage> createState() => _DesktopPageState();
}

class _DesktopPageState extends State<DesktopPage> {
  late DesktopViewModel _desktopVM;
  late VisitorViewModel _visitorVM;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final deps = AppDependencies.of(context);
    _desktopVM = deps.desktopViewModel;

    _desktopVM.onOpenWindowById ??= (id, ctx) {
      final l10n = AppLocalizations.of(ctx);
      _openWindowForId(id, l10n);
    };

    if (!_initialized) {
      _initialized = true;
      _visitorVM = VisitorViewModel(deps.visitorRepository)..init();
    }

    final guestbookVM = deps.guestbookViewModel;
    guestbookVM.onNotification ??= (notif) {
      _desktopVM.addNotification(notif);
    };
  }

  @override
  void dispose() {
    _visitorVM.dispose();
    super.dispose();
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
      SpotlightItem(
        id: AppStrings.winFinder,
        label: AppStrings.titleFinder,
        iconWidget: const Icon(Icons.folder),
        color: AppTheme.red,
      ),
      SpotlightItem(
        id: AppStrings.winSkills,
        label: AppStrings.titleSkills,
        iconWidget: const Icon(Icons.star),
        color: AppTheme.blue,
      ),
      SpotlightItem(
        id: AppStrings.winAndroid,
        label: l10n.androidDev,
        iconWidget: const FaIcon(FontAwesomeIcons.android),
        color: AppTheme.green,
      ),
      SpotlightItem(
        id: AppStrings.winTerminal,
        label: AppStrings.titleTerminal,
        iconWidget: const Icon(Icons.terminal),
        color: AppTheme.green,
      ),
      SpotlightItem(
        id: AppStrings.winCalculator,
        label: AppStrings.titleCalculator,
        iconWidget: const Icon(Icons.calculate),
        color: AppTheme.peach,
      ),
      SpotlightItem(
        id: AppStrings.winSnake,
        label: AppStrings.titleSnake,
        iconWidget: const FaIcon(FontAwesomeIcons.gamepad),
        color: AppTheme.peach,
      ),
      SpotlightItem(
        id: AppStrings.winContact,
        label: AppStrings.titleContact,
        iconWidget: const Icon(Icons.mail),
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
    _openWindowForId(item.id, l10n);
  }

  void _openWindowForId(String id, AppLocalizations l10n) {
    switch (id) {
      case AppStrings.winAbout:
        _desktopVM.openWindow(
          id,
          l10n.about,
          AboutWindowContent(bio: l10n.bio, role: l10n.role),
          AppTheme.blue,
        );
      case AppStrings.winFinder:
        _desktopVM.openWindow(
          id,
          AppStrings.titleFinder,
          const FinderContent(),
          AppTheme.red,
        );
      case AppStrings.winSkills:
        _desktopVM.openWindow(
          id,
          AppStrings.titleSkills,
          const SkillsWindowContent(),
          AppTheme.blue,
        );
      case AppStrings.winAndroid:
        _desktopVM.openWindow(
          id,
          l10n.androidDev,
          const AndroidDevWindowContent(),
          AppTheme.green,
        );
      case AppStrings.winTerminal:
        _desktopVM.openWindow(
          id,
          AppStrings.titleTerminal,
          const TerminalContent(),
          AppTheme.green,
        );
      case AppStrings.winCalculator:
        _desktopVM.openWindow(
          id,
          AppStrings.titleCalculator,
          const CalculatorContent(),
          AppTheme.peach,
        );
      case AppStrings.winSnake:
        _desktopVM.openWindow(
          id,
          AppStrings.titleSnake,
          const SnakeGameContent(),
          AppTheme.peach,
        );
      case AppStrings.winContact:
        _desktopVM.openWindow(
          id,
          AppStrings.titleContact,
          const ContactFormContent(),
          AppTheme.teal,
        );
      case AppStrings.winGuestbook:
        final vm = AppDependencies.of(context).guestbookViewModel;
        _desktopVM.openWindow(
          id,
          l10n.guestbook,
          GuestbookContent(viewModel: vm),
          AppTheme.mauve,
        );
      case AppStrings.winProjectStats:
        _desktopVM.openWindow(
          id,
          l10n.projectStats,
          const ProjectStatsWindowContent(),
          AppTheme.yellow,
        );
    }
  }

  // ── Context menu handler ─────────────────────────────────────────
  void _onContextAction(DesktopContextAction action, AppLocalizations l10n) {
    _desktopVM.closeContextMenu();
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

  // ── Keyboard shortcut handler ────────────────────────────────────
  KeyEventResult _onKey(FocusNode _, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    final meta = HardwareKeyboard.instance.isMetaPressed;

    if (meta && event.logicalKey == LogicalKeyboardKey.space) {
      _desktopVM.showSpotlight
          ? _desktopVM.closeSpotlight()
          : _desktopVM.openSpotlight();
      return KeyEventResult.handled;
    }
    if (meta && event.logicalKey == LogicalKeyboardKey.keyW) {
      if (_desktopVM.windows.isNotEmpty) {
        _desktopVM.closeWindow(_desktopVM.windows.last.id);
      }
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.escape) {
      if (_desktopVM.showSpotlight) {
        _desktopVM.closeSpotlight();
        return KeyEventResult.handled;
      }
      if (_desktopVM.showContextMenu) {
        _desktopVM.closeContextMenu();
        return KeyEventResult.handled;
      }
      if (_desktopVM.showNotifications) {
        _desktopVM.toggleNotifications();
        return KeyEventResult.handled;
      }
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    if (ResponsiveLayout.isMobile(context)) return const MobileFallbackPage();

    final l10n = AppLocalizations.of(context);
    final localeVM = AppDependencies.of(context).localeViewModel;
    final experiences = ExperienceMapper.fromL10n(l10n.experiences);

    return Focus(
      autofocus: true,
      onKeyEvent: _onKey,
      child: ListenableBuilder(
        listenable: _desktopVM,
        builder: (context, _) {
          return Scaffold(
            backgroundColor: AppTheme.background,
            body: GestureDetector(
              onSecondaryTapUp: (details) {
                _desktopVM.openContextMenu(details.localPosition);
              },
              onPanStart: (details) {
                _desktopVM.closeContextMenu();
                _desktopVM.startSelection(details.localPosition);
              },
              onPanUpdate: (details) {
                _desktopVM.updateSelection(details.localPosition);
              },
              onPanEnd: (_) => _desktopVM.endSelection(),
              child: Stack(
                children: [
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
                    child: DesktopIconsGrid(
                      experiences: experiences,
                      onOpenWindow: (id, title, content, accent) {
                        _desktopVM.openWindow(id, title, content, accent);
                      },
                    ),
                  ),

                  ..._desktopVM.windows.map(
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
                      onClose: () => _desktopVM.closeWindow(w.id),
                      onFocus: () => _desktopVM.focusWindow(w.id),
                      child: w.content,
                    ),
                  ),

                  if (_desktopVM.showNotifications)
                    Positioned(
                      top: AppSizes.menuBarOffset,
                      right: 0,
                      bottom: 0,
                      child: RepaintBoundary(
                        child: NotificationCenter(desktopVM: _desktopVM),
                      ),
                    ),

                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: RepaintBoundary(
                      child: MacMenuBar(
                        currentLanguage: localeVM.currentCode,
                        onLanguageChanged: localeVM.setLocaleByCode,
                        onToggleNotifications: _desktopVM.toggleNotifications,
                        onAppMenuAction: (action) async {
                          switch (action) {
                            case AppMenuAction.about:
                              _openWindowForId(AppStrings.winAbout, l10n);
                            case AppMenuAction.licenses:
                              _desktopVM.openWindow(
                                AppStrings.winLicenses,
                                AppStrings.titleLicenses,
                                const LicensesWindowContent(),
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

                  const Positioned(
                    bottom: AppSizes.dockBottomOffset,
                    left: 0,
                    right: 0,
                    child: Center(child: RepaintBoundary(child: Dock())),
                  ),

                  if (_desktopVM.isSelecting)
                    RubberBandSelection(
                      origin: _desktopVM.rubberBandOrigin!,
                      current: _desktopVM.rubberBandCurrent!,
                    ),

                  if (_desktopVM.showContextMenu)
                    DesktopContextMenu(
                      position: _desktopVM.contextMenuPosition!,
                      onAction: (action) => _onContextAction(action, l10n),
                      onDismiss: _desktopVM.closeContextMenu,
                    ),

                  if (_desktopVM.showSpotlight)
                    SpotlightOverlay(
                      items: _buildSpotlightItems(l10n),
                      onSelect: (item) => _onSpotlightSelect(item, l10n),
                      onDismiss: _desktopVM.closeSpotlight,
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
