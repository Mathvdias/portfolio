import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:fake_async/fake_async.dart';
import 'package:portifolio/core/services/web_notification_service.dart';
import 'package:portifolio/features/desktop/domain/models/desktop_notification.dart';
import 'package:portifolio/features/desktop/presentation/viewmodels/desktop_viewmodel.dart';

class MockBuildContext extends Fake implements BuildContext {}

class MockWebNotificationService extends Mock
    implements WebNotificationService {}

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

  // ── Window by ID handler ──────────────────────────────────────
  group('openWindowById', () {
    test('calls onOpenWindowById when set', () {
      String? receivedId;
      vm.onOpenWindowById = (id, _) => receivedId = id;
      vm.openWindowById('myWindow', MockBuildContext());
      expect(receivedId, 'myWindow');
    });

    test('does nothing when onOpenWindowById is null', () {
      expect(() => vm.openWindowById('x', MockBuildContext()), returnsNormally);
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

    test('notifications list starts empty', () {
      expect(vm.notifications, isEmpty);
    });

    test('addNotification prepends to list and notifies', () {
      final n1 = DesktopNotification(
        title: 'T1',
        message: 'M1',
        icon: Icons.info,
        color: Colors.blue,
        time: DateTime.now(),
      );
      final n2 = DesktopNotification(
        title: 'T2',
        message: 'M2',
        icon: Icons.info,
        color: Colors.blue,
        time: DateTime.now(),
      );
      vm.addNotification(n1);
      vm.addNotification(n2);
      expect(vm.notifications.first, n2);
      expect(vm.notifications.length, 2);
    });

    test('addNotification notifies listeners', () {
      int notified = 0;
      vm.addListener(() => notified++);
      vm.addNotification(
        DesktopNotification(
          title: 'T',
          message: 'M',
          icon: Icons.info,
          color: Colors.blue,
          time: DateTime.now(),
        ),
      );
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

  // ── requestPermissionAndSendWelcome ────────────────────────────
  group('requestPermissionAndSendWelcome', () {
    late MockWebNotificationService mockNotificationService;
    late DesktopViewModel customVm;

    setUp(() {
      mockNotificationService = MockWebNotificationService();
      customVm = DesktopViewModel(
        webNotificationService: mockNotificationService,
      );
    });

    tearDown(() {
      customVm.dispose();
    });

    test('does nothing if welcome is already sent', () async {
      when(
        () => mockNotificationService.requestPermission(),
      ).thenAnswer((_) async => true);
      when(
        () => mockNotificationService.showNotification(
          title: any(named: 'title'),
          body: any(named: 'body'),
        ),
      ).thenAnswer((_) async {});

      fakeAsync((async) {
        customVm.requestPermissionAndSendWelcome(title: 'T1', message: 'M1');
        async.elapse(const Duration(seconds: 2));
      });

      expect(customVm.notifications, hasLength(1));

      fakeAsync((async) {
        customVm.requestPermissionAndSendWelcome(title: 'T2', message: 'M2');
        async.elapse(const Duration(seconds: 2));
      });

      expect(customVm.notifications, hasLength(1));
      verify(() => mockNotificationService.requestPermission()).called(1);
    });

    test('does not send notification if permission is denied', () {
      when(
        () => mockNotificationService.requestPermission(),
      ).thenAnswer((_) async => false);

      fakeAsync((async) {
        customVm.requestPermissionAndSendWelcome(title: 'T', message: 'M');
        async.elapse(const Duration(seconds: 2));
      });

      expect(customVm.notifications, isEmpty);
      verify(() => mockNotificationService.requestPermission()).called(1);
      verifyNever(
        () => mockNotificationService.showNotification(
          title: any(named: 'title'),
          body: any(named: 'body'),
        ),
      );
    });

    test('sends notification after delay if permission is granted', () {
      when(
        () => mockNotificationService.requestPermission(),
      ).thenAnswer((_) async => true);
      when(
        () => mockNotificationService.showNotification(
          title: any(named: 'title'),
          body: any(named: 'body'),
        ),
      ).thenAnswer((_) async {});

      fakeAsync((async) {
        customVm.requestPermissionAndSendWelcome(
          title: 'Welcome',
          message: 'Hello',
        );

        async.elapse(const Duration(seconds: 1));
        expect(customVm.notifications, isEmpty);

        async.elapse(const Duration(seconds: 1));
        expect(customVm.notifications, hasLength(1));
        expect(customVm.notifications.first.title, 'Welcome');
        expect(customVm.notifications.first.message, 'Hello');
      });

      verify(
        () => mockNotificationService.showNotification(
          title: 'Welcome',
          body: 'Hello',
        ),
      ).called(1);
    });
  });
}
