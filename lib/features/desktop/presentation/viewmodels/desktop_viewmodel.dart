import 'package:flutter/material.dart';
import 'package:app_window/app_window.dart';

import '../../../../shared/constants/app_sizes.dart';
import '../../domain/models/desktop_notification.dart';

/// Manages all mutable desktop state: open windows, notifications,
/// context menu, spotlight visibility, and rubber-band selection.
class DesktopViewModel extends ChangeNotifier {
  // ─── Window ID Handler ──────────────────────────────────────────
  void Function(String id, BuildContext context)? onOpenWindowById;

  void openWindowById(String id, BuildContext context) {
    onOpenWindowById?.call(id, context);
  }

  // ─── Windows ────────────────────────────────────────────────────
  final List<WindowEntry> _windows = [];
  int _windowCount = 0;

  List<WindowEntry> get windows => List.unmodifiable(_windows);

  late final ValueNotifier<List<WindowEntry>> windowsNotifier =
      ValueNotifier(List.unmodifiable(_windows));

  void openWindow(
    String id,
    String title,
    Widget content,
    Color accent, {
    double width = 480.0,
    double height = 360.0,
  }) {
    _windows.removeWhere((w) => w.id == id);
    final offset = Offset(
      AppSizes.windowCascadeBase +
          (_windowCount % AppSizes.windowCascadeModulo) *
              AppSizes.windowCascadeOffset,
      AppSizes.windowCascadeTop +
          (_windowCount % AppSizes.windowCascadeModulo) *
              AppSizes.windowCascadeOffset,
    );
    _windowCount++;
    _windows.add(
      WindowEntry(
        id: id,
        title: title,
        content: content,
        accentColor: accent,
        position: offset,
        width: width,
        height: height,
      ),
    );
    windowsNotifier.value = List.unmodifiable(_windows);
    notifyListeners();
  }

  void closeWindow(String id) {
    _windows.removeWhere((w) => w.id == id);
    windowsNotifier.value = List.unmodifiable(_windows);
    notifyListeners();
  }

  void focusWindow(String id) {
    final idx = _windows.indexWhere((w) => w.id == id);
    if (idx == -1 || idx == _windows.length - 1) return;
    final entry = _windows.removeAt(idx);
    _windows.add(entry);
    windowsNotifier.value = List.unmodifiable(_windows);
    notifyListeners();
  }

  // ─── Notification centre ────────────────────────────────────────
  bool _showNotifications = false;
  bool get showNotifications => _showNotifications;

  final List<DesktopNotification> _notifications = [];
  List<DesktopNotification> get notifications =>
      List.unmodifiable(_notifications);

  late final ValueNotifier<bool> showNotificationsNotifier =
      ValueNotifier(false);

  late final ValueNotifier<List<DesktopNotification>> notificationsNotifier =
      ValueNotifier(List.unmodifiable(_notifications));

  void toggleNotifications() {
    _showNotifications = !_showNotifications;
    showNotificationsNotifier.value = _showNotifications;
    notifyListeners();
  }

  void addNotification(DesktopNotification notification) {
    _notifications.insert(0, notification);
    notificationsNotifier.value = List.unmodifiable(_notifications);
    notifyListeners();
  }

  // ─── Context menu ───────────────────────────────────────────────
  Offset? _contextMenuPosition;
  Offset? get contextMenuPosition => _contextMenuPosition;
  bool get showContextMenu => _contextMenuPosition != null;

  late final ValueNotifier<Offset?> contextMenuPositionNotifier =
      ValueNotifier(null);

  void openContextMenu(Offset position) {
    _contextMenuPosition = position;
    contextMenuPositionNotifier.value = position;
    notifyListeners();
  }

  void closeContextMenu() {
    if (_contextMenuPosition == null) return;
    _contextMenuPosition = null;
    contextMenuPositionNotifier.value = null;
    notifyListeners();
  }

  // ─── Spotlight ──────────────────────────────────────────────────
  bool _showSpotlight = false;
  bool get showSpotlight => _showSpotlight;

  late final ValueNotifier<bool> showSpotlightNotifier =
      ValueNotifier(false);

  void openSpotlight() {
    _showSpotlight = true;
    showSpotlightNotifier.value = true;
    notifyListeners();
  }

  void closeSpotlight() {
    if (!_showSpotlight) return;
    _showSpotlight = false;
    showSpotlightNotifier.value = false;
    notifyListeners();
  }

  // ─── Rubber-band selection ──────────────────────────────────────
  Offset? _rubberBandOrigin;
  Offset? _rubberBandCurrent;

  Offset? get rubberBandOrigin => _rubberBandOrigin;
  Offset? get rubberBandCurrent => _rubberBandCurrent;
  bool get isSelecting => _rubberBandOrigin != null;

  void startSelection(Offset origin) {
    _rubberBandOrigin = origin;
    _rubberBandCurrent = origin;
    notifyListeners();
  }

  void updateSelection(Offset current) {
    _rubberBandCurrent = current;
    notifyListeners();
  }

  void endSelection() {
    _rubberBandOrigin = null;
    _rubberBandCurrent = null;
    notifyListeners();
  }

  @override
  void dispose() {
    windowsNotifier.dispose();
    showNotificationsNotifier.dispose();
    notificationsNotifier.dispose();
    contextMenuPositionNotifier.dispose();
    showSpotlightNotifier.dispose();
    super.dispose();
  }
}
