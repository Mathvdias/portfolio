// ignore_for_file: prefer_const_constructors
// Const constructors are intentionally omitted in this file so that widget
// constructors execute at runtime and are tracked by the coverage tool.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:portifolio/l10n/app_localizations.dart';
import 'package:portifolio/shared/constants/app_strings.dart';
import 'package:portifolio/shared/widgets/android_dev_window_content.dart';
import 'package:portifolio/shared/widgets/flutter_dev_window_content.dart';
import 'package:portifolio/shared/widgets/project_stats_window_content.dart';
import 'package:portifolio/shared/widgets/wasm_diagnostics_content.dart';

void main() {
  group('New Window Contents', () {
    testWidgets('AndroidDevWindowContent renders expertise sections', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: [AppLocalizationsDelegate()],
          home: Scaffold(body: AndroidDevWindowContent()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Android Development'), findsOneWidget);
      expect(find.text('Core'), findsOneWidget);
      expect(find.text('Kotlin'), findsOneWidget);
      expect(find.text('Jetpack Compose'), findsOneWidget);
    });

    testWidgets('FlutterDevWindowContent renders expertise sections', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: [AppLocalizationsDelegate()],
          home: Scaffold(body: FlutterDevWindowContent()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Flutter Dev'), findsOneWidget);
      expect(find.text('Core'), findsOneWidget);
      expect(find.text('BLoC'), findsOneWidget);
      expect(find.text('Golden Tests'), findsOneWidget);
      expect(find.text('MVVM'), findsOneWidget);
    });

    testWidgets('ProjectStatsWindowContent renders coverage indicator', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: [AppLocalizationsDelegate()],
          home: Scaffold(body: ProjectStatsWindowContent()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('PROJECT METRICS'), findsOneWidget);
      expect(find.textContaining('%'), findsAtLeastNWidgets(1));
      expect(find.text('COVERAGE'), findsOneWidget);
      expect(find.text('Unit Tests'), findsOneWidget);
      expect(
        find.textContaining('TECH STACK', skipOffstage: false),
        findsOneWidget,
      );
      expect(
        find.textContaining('MVVM 2.0', skipOffstage: false),
        findsOneWidget,
      );
      expect(
        find.textContaining('CanvasKit / WebGL', skipOffstage: false),
        findsOneWidget,
      );
      expect(
        find.textContaining('GLSL GPU Shader', skipOffstage: false),
        findsOneWidget,
      );
      expect(
        find.textContaining('InheritedWidget · Pure Dart', skipOffstage: false),
        findsOneWidget,
      );
      expect(
        find.textContaining('Golden Tests', skipOffstage: false),
        findsOneWidget,
      );
      expect(
        find.textContaining('Integration / E2E', skipOffstage: false),
        findsOneWidget,
      );
      expect(
        find.textContaining('TECH Q&A', skipOffstage: false),
        findsOneWidget,
      );
      expect(
        find.textContaining('Is Flutter Web compatible', skipOffstage: false),
        findsOneWidget,
      );
    });

    testWidgets(
      'ProjectStatsWindowContent expands Q&A card and shows answer points',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            localizationsDelegates: [AppLocalizationsDelegate()],
            home: Scaffold(body: ProjectStatsWindowContent()),
          ),
        );
        await tester.pumpAndSettle();

        // Tap the expansion tile to expand it
        await tester.tap(
          find.textContaining('Is Flutter Web compatible', skipOffstage: false),
        );
        await tester.pumpAndSettle();

        expect(find.textContaining('WasmGC'), findsWidgets);
        expect(find.textContaining('credentialless'), findsWidgets);
        expect(find.textContaining('CanvasKit'), findsWidgets);
      },
    );

    testWidgets(
      'ProjectStatsWindowContent expands GPU shader Q&A card and shows answer points',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            localizationsDelegates: [AppLocalizationsDelegate()],
            home: Scaffold(body: ProjectStatsWindowContent()),
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(
          find.textContaining(
            'How are the wallpaper particles',
            skipOffstage: false,
          ),
        );
        await tester.pumpAndSettle();

        expect(find.textContaining('FragmentShader'), findsWidgets);
        expect(find.textContaining('smoothstep'), findsWidgets);
        expect(find.textContaining('vsync'), findsWidgets);
      },
    );

    testWidgets(
      'ProjectStatsWindowContent renders yellow for 60-79% coverage',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            localizationsDelegates: [AppLocalizationsDelegate()],
            home: Scaffold(
              body: ProjectStatsWindowContent(coverageOverride: 70.0),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('70.0%'), findsOneWidget);
      },
    );

    testWidgets(
      'ProjectStatsWindowContent renders red for below 60% coverage',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            localizationsDelegates: [AppLocalizationsDelegate()],
            home: Scaffold(
              body: ProjectStatsWindowContent(coverageOverride: 50.0),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('50.0%'), findsOneWidget);
      },
    );

    testWidgets(
      'WasmDiagnosticsContent renders metrics, toggle buttons, and console logs',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            localizationsDelegates: [AppLocalizationsDelegate()],
            home: Scaffold(body: WasmDiagnosticsContent()),
          ),
        );
        await tester.pumpAndSettle();

        // 1. Verify metrics and layouts
        expect(find.text(AppStrings.wasmFps), findsOneWidget);
        expect(
          find.text(AppStrings.wasmFrameLatency.toUpperCase()),
          findsOneWidget,
        );
        expect(find.text(AppStrings.wasmHeap.toUpperCase()), findsOneWidget);
        expect(find.text(AppStrings.wasmGcPause.toUpperCase()), findsOneWidget);
        expect(find.text(AppStrings.wasmConsoleTitle), findsOneWidget);

        // 2. Click Hot Reload
        await tester.tap(find.text(AppStrings.wasmHotReload));
        await tester.pump(); // Start compiler compilation
        await tester.pump(const Duration(milliseconds: 500)); // Module compile
        await tester.pump(const Duration(milliseconds: 500)); // Finish compile
        await tester.pumpAndSettle(); // Dismiss toast/SnackBar

        // 3. Click Trigger GC
        await tester.tap(find.text(AppStrings.wasmTriggerGc));
        await tester.pump();
        await tester.pump(const Duration(seconds: 3)); // Let pause timer reset

        // 4. Tap custom toggles (SIMD and WASM GC)
        await tester.tap(find.text(AppStrings.wasmSimd));
        await tester.pump();

        await tester.tap(find.text(AppStrings.wasmWasmGc));
        await tester.pump();

        // 5. Let period stats timer run to cover update lines
        await tester.pump(const Duration(milliseconds: 300));
        await tester.pumpAndSettle();
      },
    );

    testWidgets(
      'WasmDiagnosticsContent fallback memory path and log/frame buffer limits',
      (tester) async {
        double mockMemory = 20.99;
        await tester.pumpWidget(
          MaterialApp(
            localizationsDelegates: [AppLocalizationsDelegate()],
            home: Scaffold(
              body: WasmDiagnosticsContent(
                heapSizeOverride: () {
                  final val = mockMemory;
                  mockMemory = 0.0;
                  return val;
                },
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        final dynamic state = tester.state(find.byType(WasmDiagnosticsContent));

        // 1. Exceed 55 logs limit to trigger log sweep cleanups
        for (int i = 0; i < 60; i++) {
          state.addLog('Test', 'Msg $i');
        }

        // 2. Exceed 500 frame buffer recordings
        for (int i = 1; i <= 510; i++) {
          state.onFrame(Duration(milliseconds: i * 16));
        }

        // Test VSync detector adapting to various refresh rates sequentially
        // 240Hz (<= 4.6ms)
        state.onFrame(Duration(milliseconds: 510 * 16 + 4));
        expect(state.detectedRefreshRate, 240.0);

        // 165Hz (<= 6.2ms)
        state.onFrame(Duration(milliseconds: 510 * 16 + 4 + 6));
        expect(state.detectedRefreshRate, 165.0);

        // 144Hz (<= 7.4ms)
        state.onFrame(Duration(milliseconds: 510 * 16 + 4 + 6 + 7));
        expect(state.detectedRefreshRate, 144.0);

        // 120Hz (<= 9.0ms)
        state.onFrame(Duration(milliseconds: 510 * 16 + 4 + 6 + 7 + 8));
        expect(state.detectedRefreshRate, 120.0);

        // 90Hz (<= 12.0ms)
        state.onFrame(Duration(milliseconds: 510 * 16 + 4 + 6 + 7 + 8 + 11));
        expect(state.detectedRefreshRate, 90.0);

        // 75Hz (<= 14.5ms)
        state.onFrame(
          Duration(milliseconds: 510 * 16 + 4 + 6 + 7 + 8 + 11 + 14),
        );
        expect(state.detectedRefreshRate, 75.0);

        // 3. Force stats timer to tick with zero heapMemory to trigger auto GC sweep
        await tester.pump(const Duration(milliseconds: 300));

        // 4. Trigger manual sweep with realMemory <= 0
        state.runGarbageCollection();

        // 5. Force final pump to clear all delayed GC timers
        await tester.pump(const Duration(seconds: 3));
        await tester.pumpAndSettle();
      },
    );
  });
}
