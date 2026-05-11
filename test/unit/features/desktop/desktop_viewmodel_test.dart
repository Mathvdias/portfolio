import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:portifolio/features/desktop/presentation/viewmodels/desktop_viewmodel.dart';

void main() {
  late DesktopViewModel vm;

  setUp(() => vm = DesktopViewModel());
  tearDown(() => vm.dispose());

  // ── Windows ────────────────────────────────────────────────────
  group('windows', () {
    test('starts with no windows', () {
      expect(vm.windows, isEmpty);
    });

    test('openWindow adds a window', () {
      vm.openWindow('w1', 'title1', const Text('c'), Colors.blue);
      expect(vm.windows, hasLength(1));
      expect(vm.windows.first.id, 'w1');
    });

    test('openWindow replaces existing window with same id', () {
      vm.openWindow('w1', 'v1', const Text('a'), Colors.blue);
      vm.openWindow('w1', 'v2', const Text('b'), Colors.red);
      expect(vm.windows, hasLength(1));
      expect(vm.windows.first.title, 'v2');
    });

    test('openWindow cascades window position', () {
      vm.openWindow('w1', 't', const Text('c'), Colors.blue);
      vm.openWindow('w2', 't', const Text('c'), Colors.blue);
      expect(vm.windows[0].position, isNot(vm.windows[1].position));
    });

    test('closeWindow removes the window', () {
      vm.openWindow('w1', 't', const Text('c'), Colors.blue);
      vm.closeWindow('w1');
      expect(vm.windows, isEmpty);
    });

    test('closeWindow is a no-op for unknown id', () {
      vm.openWindow('w1', 't', const Text('c'), Colors.blue);
      vm.closeWindow('w99');
      expect(vm.windows, hasLength(1));
    });

    test('focusWindow moves window to the top', () {
      vm.openWindow('w1', 't1', const Text('c'), Colors.blue);
      vm.openWindow('w2', 't2', const Text('c'), Colors.blue);
      vm.openWindow('w3', 't3', const Text('c'), Colors.blue);
      vm.focusWindow('w1');
      expect(vm.windows.last.id, 'w1');
    });

    test('focusWindow is a no-op if already on top', () {
      vm.openWindow('w1', 't1', const Text('c'), Colors.blue);
      vm.focusWindow('w1');
      expect(vm.windows.last.id, 'w1');
    });

    test('focusWindow is a no-op for unknown id', () {
      vm.openWindow('w1', 't1', const Text('c'), Colors.blue);
      vm.focusWindow('w99');
      expect(vm.windows.last.id, 'w1');
    });

    test('notifies listeners when opening a window', () {
      int notified = 0;
      vm.addListener(() => notified++);
      vm.openWindow('w1', 't', const Text('c'), Colors.blue);
      expect(notified, 1);
    });

    test('notifies listeners when closing a window', () {
      vm.openWindow('w1', 't', const Text('c'), Colors.blue);
      int notified = 0;
      vm.addListener(() => notified++);
      vm.closeWindow('w1');
      expect(notified, 1);
    });

    test('notifies listeners when focusing a window', () {
      vm.openWindow('w1', 't', const Text('c'), Colors.blue);
      vm.openWindow('w2', 't', const Text('c'), Colors.blue);
      int notified = 0;
      vm.addListener(() => notified++);
      vm.focusWindow('w1');
      expect(notified, 1);
    });
  });

  // ── Notifications ──────────────────────────────────────────────
  group('notifications', () {
    test('starts hidden', () {
      expect(vm.showNotifications, isFalse);
    });

    test('toggleNotifications flips state', () {
      vm.toggleNotifications();
      expect(vm.showNotifications, isTrue);
      vm.toggleNotifications();
      expect(vm.showNotifications, isFalse);
    });

    test('notifies listeners on toggle', () {
      int notified = 0;
      vm.addListener(() => notified++);
      vm.toggleNotifications();
      expect(notified, 1);
    });
  });

  // ── Context menu ───────────────────────────────────────────────
  group('context menu', () {
    test('starts closed', () {
      expect(vm.showContextMenu, isFalse);
      expect(vm.contextMenuPosition, isNull);
    });

    test('openContextMenu opens at position', () {
      vm.openContextMenu(const Offset(100, 200));
      expect(vm.showContextMenu, isTrue);
      expect(vm.contextMenuPosition, const Offset(100, 200));
    });

    test('closeContextMenu hides menu', () {
      vm.openContextMenu(const Offset(100, 200));
      vm.closeContextMenu();
      expect(vm.showContextMenu, isFalse);
    });

    test('closeContextMenu is a no-op when already closed', () {
      int notified = 0;
      vm.addListener(() => notified++);
      vm.closeContextMenu();
      expect(notified, 0);
    });
  });

  // ── Spotlight ──────────────────────────────────────────────────
  group('spotlight', () {
    test('starts hidden', () {
      expect(vm.showSpotlight, isFalse);
    });

    test('openSpotlight shows overlay', () {
      vm.openSpotlight();
      expect(vm.showSpotlight, isTrue);
    });

    test('closeSpotlight hides overlay', () {
      vm.openSpotlight();
      vm.closeSpotlight();
      expect(vm.showSpotlight, isFalse);
    });

    test('closeSpotlight is a no-op when already hidden', () {
      int notified = 0;
      vm.addListener(() => notified++);
      vm.closeSpotlight();
      expect(notified, 0);
    });
  });

  // ── Rubber-band selection ──────────────────────────────────────
  group('rubber-band selection', () {
    test('starts inactive', () {
      expect(vm.isSelecting, isFalse);
      expect(vm.rubberBandOrigin, isNull);
      expect(vm.rubberBandCurrent, isNull);
    });

    test('startSelection activates', () {
      vm.startSelection(const Offset(10, 20));
      expect(vm.isSelecting, isTrue);
      expect(vm.rubberBandOrigin, const Offset(10, 20));
      expect(vm.rubberBandCurrent, const Offset(10, 20));
    });

    test('updateSelection tracks pointer', () {
      vm.startSelection(const Offset(10, 20));
      vm.updateSelection(const Offset(50, 60));
      expect(vm.rubberBandCurrent, const Offset(50, 60));
    });

    test('endSelection resets', () {
      vm.startSelection(const Offset(10, 20));
      vm.updateSelection(const Offset(50, 60));
      vm.endSelection();
      expect(vm.isSelecting, isFalse);
      expect(vm.rubberBandOrigin, isNull);
      expect(vm.rubberBandCurrent, isNull);
    });
  });
}
