import 'dart:async';
import 'dart:developer' as dev;
import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../features/visitors/data/datasources/visitor_datasource.dart';
import '../../features/visitors/data/repositories/visitor_repository_impl.dart';
import '../../features/visitors/domain/repositories/visitor_repository.dart';
import '../../firebase_options.dart';
import '../services/analytics_service.dart';
import '../services/firebase_analytics_service.dart';

final class AppConfig {
  const AppConfig({
    required this.prefs,
    required this.analytics,
    required this.visitorRepository,
  });

  final SharedPreferences prefs;
  final AnalyticsService analytics;
  final VisitorRepository visitorRepository;
}

abstract final class AppBootstrap {
  static Future<AppConfig> init() async {
    WidgetsFlutterBinding.ensureInitialized();
    await _initFirebase();
    final prefs = await SharedPreferences.getInstance();
    final analytics = FirebaseAnalyticsService(FirebaseAnalytics.instance);
    _registerErrorHandlers(analytics);
    final visitorRepository = VisitorRepositoryImpl(
      VisitorDatasource(firestore: FirebaseFirestore.instance),
    );
    return AppConfig(
      prefs: prefs,
      analytics: analytics,
      visitorRepository: visitorRepository,
    );
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
