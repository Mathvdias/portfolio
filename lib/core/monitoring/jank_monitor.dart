import 'dart:async';

import 'package:flutter/scheduler.dart';

import '../services/analytics_service.dart';

final class JankMonitor {
  JankMonitor(this._analytics);

  final AnalyticsService _analytics;

  static const _thresholdMs = 32;
  static const _throttle = Duration(seconds: 1);

  DateTime? _lastReport;

  void start() => SchedulerBinding.instance.addTimingsCallback(_onTimings);

  void stop() => SchedulerBinding.instance.removeTimingsCallback(_onTimings);

  void _onTimings(List<FrameTiming> timings) {
    for (final t in timings) {
      final totalMs = t.totalSpan.inMilliseconds;
      if (totalMs <= _thresholdMs) continue;

      final now = DateTime.now();
      if (_lastReport != null && now.difference(_lastReport!) < _throttle) {
        continue;
      }
      _lastReport = now;

      unawaited(
        _analytics.logJankFrame(
          totalMs: totalMs,
          buildMs: t.buildDuration.inMilliseconds,
          rasterMs: t.rasterDuration.inMilliseconds,
        ),
      );
    }
  }
}
