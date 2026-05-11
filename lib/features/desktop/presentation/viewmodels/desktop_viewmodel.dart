import 'package:flutter/material.dart';
import 'package:app_window/app_window.dart';

import '../../../../shared/constants/app_sizes.dart';
import '../../domain/models/desktop_notification.dart';

/// Manages all mutable desktop state: open windows, notifications,
/// context menu, spotlight visibility, and rubber-band selection.
class DesktopViewModel extends ChangeNotifier {
  // ─── Windows ────────────────────────────────────────────────────
  final List<WindowEntry> _windows = [];
  int _windowCount = 0;

  List<WindowEntry> get windows => List.unmodifiable(_windows);

  void openWindow(String id, String title, Widget content, Color accent) {
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
      ),
    );
    notifyListeners();
  }

  void closeWindow(String id) {
    _windows.removeWhere((w) => w.id == id);
    notifyListeners();
  }

  void focusWindow(String id) {
    final idx = _windows.indexWhere((w) => w.id == id);
    if (idx == -1 || idx == _windows.length - 1) return;
    final entry = _windows.removeAt(idx);
    _windows.add(entry);
    notifyListeners();
  }

  // ─── Notification centre ────────────────────────────────────────
  bool _showNotifications = false;
  bool get showNotifications => _showNotifications;

  final List<DesktopNotification> _notifications = [];
  List<DesktopNotification> get notifications => List.unmodifiable(_notifications);

  void toggleNotifications() {
    _showNotifications = !_showNotifications;
    notifyListeners();
  }

  void addNotification(DesktopNotification notification) {
    _notifications.insert(0, notification);
    // Show the notification centre briefly or just badge it
    // Or we can just play a sound and show a temporary toast!
    notifyListeners();
  }

  // ─── Context menu ───────────────────────────────────────────────
  Offset? _contextMenuPosition;
  Offset? get contextMenuPosition => _contextMenuPosition;
  bool get showContextMenu => _contextMenuPosition != null;

  void openContextMenu(Offset position) {
    _contextMenuPosition = position;
    notifyListeners();
  }

  void closeContextMenu() {
    if (_contextMenuPosition == null) return;
    _contextMenuPosition = null;
    notifyListeners();
  }

  // ─── Spotlight ──────────────────────────────────────────────────
  bool _showSpotlight = false;
  bool get showSpotlight => _showSpotlight;

  void openSpotlight() {
    _showSpotlight = true;
    notifyListeners();
  }

  void closeSpotlight() {
    if (!_showSpotlight) return;
    _showSpotlight = false;
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
}
