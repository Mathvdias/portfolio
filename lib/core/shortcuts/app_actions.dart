import 'dart:async';

import 'package:flutter/widgets.dart';

import '../services/analytics_service.dart';
import '../../features/desktop/presentation/viewmodels/desktop_viewmodel.dart';
import 'app_intents.dart';

/// Factory that assembles the [MaterialApp.actions] map.
///
/// Keeping actions in a dedicated file means [app.dart] stays free of
/// business logic, and each action can be unit-tested in isolation by
/// calling [Action.invoke] directly on the instance returned by [build].
abstract final class AppActions {
  static Map<Type, Action<Intent>> build({
    required DesktopViewModel desktopViewModel,
    required AnalyticsService analytics,
  }) => {
    OpenSpotlightIntent: _OpenSpotlightAction(desktopViewModel, analytics),
    CloseTopWindowIntent: _CloseTopWindowAction(desktopViewModel, analytics),
    DismissDesktopIntent: _DismissDesktopAction(desktopViewModel),
  };
}

// ── Actions ─────────────────────────────────────────────────────────────────

class _OpenSpotlightAction extends Action<OpenSpotlightIntent> {
  _OpenSpotlightAction(this._vm, this._analytics);

  final DesktopViewModel _vm;
  final AnalyticsService _analytics;

  @override
  void invoke(OpenSpotlightIntent intent) {
    if (_vm.showSpotlight) {
      _vm.closeSpotlight();
    } else {
      _vm.openSpotlight();
      unawaited(_analytics.logSpotlightOpen());
    }
  }
}

class _CloseTopWindowAction extends Action<CloseTopWindowIntent> {
  _CloseTopWindowAction(this._vm, this._analytics);

  final DesktopViewModel _vm;
  final AnalyticsService _analytics;

  @override
  bool get isActionEnabled => _vm.windows.isNotEmpty;

  @override
  void invoke(CloseTopWindowIntent intent) {
    if (_vm.windows.isEmpty) return;
    final id = _vm.windows.last.id;
    unawaited(_analytics.logWindowClose(id));
    _vm.closeWindow(id);
  }
}

class _DismissDesktopAction extends Action<DismissDesktopIntent> {
  _DismissDesktopAction(this._vm);

  final DesktopViewModel _vm;

  @override
  bool get isActionEnabled =>
      _vm.showSpotlight || _vm.showContextMenu || _vm.showNotifications;

  @override
  void invoke(DismissDesktopIntent intent) {
    if (_vm.showSpotlight) {
      _vm.closeSpotlight();
    } else if (_vm.showContextMenu) {
      _vm.closeContextMenu();
    } else if (_vm.showNotifications) {
      _vm.toggleNotifications();
    }
  }
}
