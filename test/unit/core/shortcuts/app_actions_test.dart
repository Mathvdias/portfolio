import 'package:app_window/app_window.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:portifolio/core/services/analytics_service.dart';
import 'package:portifolio/core/shortcuts/app_actions.dart';
import 'package:portifolio/core/shortcuts/app_intents.dart';
import 'package:portifolio/features/desktop/presentation/viewmodels/desktop_viewmodel.dart';

// ── Fakes / mocks ─────────────────────────────────────────────────────────

class _MockDesktopViewModel extends Mock implements DesktopViewModel {}

class _MockAnalyticsService extends Mock implements AnalyticsService {}

// ── Helpers ───────────────────────────────────────────────────────────────

/// Retrieves the action for [I] from the map built by [AppActions.build].
Action<I> _actionFor<I extends Intent>(Map<Type, Action<Intent>> actions) =>
    actions[I]! as Action<I>;

/// Invokes the action for [I] using an [ActionDispatcher] to avoid protected member warnings.
Object? _invokeAction<I extends Intent>(
  Map<Type, Action<Intent>> actions,
  I intent,
) {
  final action = _actionFor<I>(actions);
  if (action.isActionEnabled) {
    return const ActionDispatcher().invokeAction(action, intent);
  }
  return null;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _MockDesktopViewModel vm;
  late _MockAnalyticsService analytics;
  late Map<Type, Action<Intent>> actions;

  setUp(() {
    vm = _MockDesktopViewModel();
    analytics = _MockAnalyticsService();
    actions = AppActions.build(desktopViewModel: vm, analytics: analytics);

    // Default stubs — can be overridden per test.
    when(() => vm.showSpotlight).thenReturn(false);
    when(() => vm.showContextMenu).thenReturn(false);
    when(() => vm.showNotifications).thenReturn(false);
    when(() => vm.windows).thenReturn([]);
    when(() => analytics.logSpotlightOpen()).thenAnswer((_) async {});
    when(() => analytics.logWindowClose(any())).thenAnswer((_) async {});
  });

  // ── OpenSpotlightAction ─────────────────────────────────────────────────

  group('OpenSpotlightAction', () {
    test('opens spotlight when it is closed', () {
      when(() => vm.showSpotlight).thenReturn(false);
      when(() => vm.openSpotlight()).thenReturn(null);

      _invokeAction(actions, const OpenSpotlightIntent());

      verify(() => vm.openSpotlight()).called(1);
      verify(() => analytics.logSpotlightOpen()).called(1);
    });

    test('closes spotlight when it is open', () {
      when(() => vm.showSpotlight).thenReturn(true);
      when(() => vm.closeSpotlight()).thenReturn(null);

      _invokeAction(actions, const OpenSpotlightIntent());

      verify(() => vm.closeSpotlight()).called(1);
      verifyNever(() => vm.openSpotlight());
    });
  });

  // ── CloseTopWindowAction ────────────────────────────────────────────────

  group('CloseTopWindowAction', () {
    test('isActionEnabled is false when no windows are open', () {
      when(() => vm.windows).thenReturn([]);
      expect(
        _actionFor<CloseTopWindowIntent>(actions).isActionEnabled,
        isFalse,
      );
    });

    test('isActionEnabled is true when at least one window is open', () {
      when(() => vm.windows).thenReturn([
        WindowEntry(
          id: 'terminal',
          title: 'Terminal',
          content: const SizedBox.shrink(),
          accentColor: const Color(0xFF89B4FA),
          position: Offset.zero,
        ),
      ]);
      expect(_actionFor<CloseTopWindowIntent>(actions).isActionEnabled, isTrue);
    });

    test('closes the topmost window and logs analytics', () {
      const windowId = 'terminal';
      when(() => vm.windows).thenReturn([
        WindowEntry(
          id: windowId,
          title: 'Terminal',
          content: const SizedBox.shrink(),
          accentColor: const Color(0xFF89B4FA),
          position: Offset.zero,
        ),
      ]);
      when(() => vm.closeWindow(windowId)).thenReturn(null);

      _invokeAction(actions, const CloseTopWindowIntent());

      verify(() => analytics.logWindowClose(windowId)).called(1);
      verify(() => vm.closeWindow(windowId)).called(1);
    });

    test('does nothing when window list is empty', () {
      when(() => vm.windows).thenReturn([]);

      _invokeAction(actions, const CloseTopWindowIntent());

      verifyNever(() => vm.closeWindow(any()));
      verifyNever(() => analytics.logWindowClose(any()));
    });
  });

  // ── DismissDesktopAction ────────────────────────────────────────────────

  group('DismissDesktopAction', () {
    test('isActionEnabled is false when no overlay is visible', () {
      expect(
        _actionFor<DismissDesktopIntent>(actions).isActionEnabled,
        isFalse,
      );
    });

    test('isActionEnabled is true when spotlight is open', () {
      when(() => vm.showSpotlight).thenReturn(true);
      expect(_actionFor<DismissDesktopIntent>(actions).isActionEnabled, isTrue);
    });

    test('closes spotlight (highest priority) when spotlight is open', () {
      when(() => vm.showSpotlight).thenReturn(true);
      when(() => vm.showContextMenu).thenReturn(true);
      when(() => vm.closeSpotlight()).thenReturn(null);

      _invokeAction(actions, const DismissDesktopIntent());

      verify(() => vm.closeSpotlight()).called(1);
      verifyNever(() => vm.closeContextMenu());
    });

    test('closes context menu when only context menu is open', () {
      when(() => vm.showContextMenu).thenReturn(true);
      when(() => vm.closeContextMenu()).thenReturn(null);

      _invokeAction(actions, const DismissDesktopIntent());

      verify(() => vm.closeContextMenu()).called(1);
      verifyNever(() => vm.closeSpotlight());
    });

    test('toggles notifications when only notification panel is open', () {
      when(() => vm.showNotifications).thenReturn(true);
      when(() => vm.toggleNotifications()).thenReturn(null);

      _invokeAction(actions, const DismissDesktopIntent());

      verify(() => vm.toggleNotifications()).called(1);
    });

    test('does nothing when no overlay is visible', () {
      _invokeAction(actions, const DismissDesktopIntent());

      verifyNever(() => vm.closeSpotlight());
      verifyNever(() => vm.closeContextMenu());
      verifyNever(() => vm.toggleNotifications());
    });
  });
}
