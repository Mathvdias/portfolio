import 'dart:async';
import 'dart:developer' as dev;
import 'dart:ui';

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../firebase_options.dart';
import '../services/analytics_service.dart';
import '../services/firebase_analytics_service.dart';
import 'shader_registry.dart';

final class AppConfig {
  const AppConfig({required this.prefs, required this.analytics});

  final SharedPreferences prefs;
  final AnalyticsService analytics;
}

abstract final class AppBootstrap {
  static Future<AppConfig> init() async {
    WidgetsFlutterBinding.ensureInitialized();
    // Run Firebase init, prefs, and shader compilation in parallel.
    // Shaders are ready before the first widget mounts — no fallback flash.
    final results = await Future.wait<Object?>([
      _initFirebase(),
      SharedPreferences.getInstance(),
      ShaderRegistry.preloadAll(),
    ]);
    final prefs = results[1] as SharedPreferences;
    final analytics = FirebaseAnalyticsService(FirebaseAnalytics.instance);
    _registerErrorHandlers(analytics);
    return AppConfig(prefs: prefs, analytics: analytics);
  }

  static Future<void> _initFirebase() async {
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    } catch (e, stack) {
      dev.log(
        'Firebase init failed — running without Firebase',
        name: 'AppBootstrap',
        level: 1000,
        error: e,
        stackTrace: stack,
      );
    }
  }

  static void _registerErrorHandlers(AnalyticsService analytics) {
    FlutterError.onError = (details) {
      FlutterError.presentError(details);
      unawaited(
        analytics.logError(
          details.exceptionAsString(),
          details.toString(),
          stackTrace: details.stack?.toString(),
        ),
      );
    };

    PlatformDispatcher.instance.onError = (error, stack) {
      unawaited(
        analytics.logError(
          error.runtimeType.toString(),
          error.toString(),
          stackTrace: stack.toString(),
        ),
      );
      return true;
    };
  }
}
