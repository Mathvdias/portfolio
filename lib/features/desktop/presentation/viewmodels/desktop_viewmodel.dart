import 'package:flutter/material.dart';
import 'package:app_window/app_window.dart';

class DesktopViewModel extends ChangeNotifier {
  final List<WindowEntry> _windows = [];
  int _windowCount = 0;
  bool _showNotifications = false;

  List<WindowEntry> get windows => List.unmodifiable(_windows);
  bool get showNotifications => _showNotifications;

  void openWindow(String id, String title, Widget content, Color accent) {
    _windows.removeWhere((w) => w.id == id);
    final offset = Offset(
      80 + (_windowCount % 6) * 28.0,
      48 + (_windowCount % 6) * 28.0,
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

  void toggleNotifications() {
    _showNotifications = !_showNotifications;
    notifyListeners();
  }
}
