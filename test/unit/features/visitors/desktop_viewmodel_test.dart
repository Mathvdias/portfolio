import 'package:app_window/app_window.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:portifolio/features/desktop/presentation/viewmodels/desktop_viewmodel.dart';

void main() {
  group('DesktopViewModel', () {
    late DesktopViewModel vm;

    setUp(() => vm = DesktopViewModel());
    tearDown(() => vm.dispose());

    test('starts with no windows', () {
      expect(vm.windows, isEmpty);
    });

    test('starts with notifications hidden', () {
      expect(vm.showNotifications, isFalse);
    });

    test('openWindow adds a window', () {
      vm.openWindow('about', 'About', const Text('x'), Colors.blue);
      expect(vm.windows.length, 1);
      expect(vm.windows.first.id, 'about');
      expect(vm.windows.first.title, 'About');
    });

    test('openWindow with same id replaces existing', () {
      vm.openWindow('about', 'About', const Text('x'), Colors.blue);
      vm.openWindow('about', 'About 2', const Text('y'), Colors.red);
      expect(vm.windows.length, 1);
      expect(vm.windows.first.title, 'About 2');
    });

    test('closeWindow removes the window', () {
      vm.openWindow('about', 'About', const Text('x'), Colors.blue);
      vm.closeWindow('about');
      expect(vm.windows, isEmpty);
    });

    test('closeWindow on unknown id is no-op', () {
      vm.openWindow('about', 'About', const Text('x'), Colors.blue);
      vm.closeWindow('unknown');
      expect(vm.windows.length, 1);
    });

    test('focusWindow moves window to end of list', () {
      vm.openWindow('a', 'A', const Text('a'), Colors.blue);
      vm.openWindow('b', 'B', const Text('b'), Colors.red);
      vm.openWindow('c', 'C', const Text('c'), Colors.green);

      vm.focusWindow('a');

      expect(vm.windows.last.id, 'a');
    });

    test('focusWindow on top window is no-op', () {
      vm.openWindow('a', 'A', const Text('a'), Colors.blue);
      vm.openWindow('b', 'B', const Text('b'), Colors.red);

      vm.focusWindow('b');

      expect(vm.windows.last.id, 'b');
      expect(vm.windows.length, 2);
    });

    test('toggleNotifications flips the flag', () {
      vm.toggleNotifications();
      expect(vm.showNotifications, isTrue);
      vm.toggleNotifications();
      expect(vm.showNotifications, isFalse);
    });

    test('openWindow notifies listeners', () {
      var count = 0;
      vm.addListener(() => count++);
      vm.openWindow('a', 'A', const Text('a'), Colors.blue);
      expect(count, 1);
    });

    test('closeWindow notifies listeners', () {
      vm.openWindow('a', 'A', const Text('a'), Colors.blue);
      var count = 0;
      vm.addListener(() => count++);
      vm.closeWindow('a');
      expect(count, 1);
    });

    test('windows list is unmodifiable', () {
      vm.openWindow('a', 'A', const Text('a'), Colors.blue);
      final windows = vm.windows;
      final extra = WindowEntry(
        id: 'x',
        title: 'X',
        content: const SizedBox(),
        accentColor: Colors.white,
        position: Offset.zero,
      );
      expect(() => windows.add(extra), throwsUnsupportedError);
    });
  });
}
