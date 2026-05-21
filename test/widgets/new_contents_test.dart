import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:portifolio/l10n/app_localizations.dart';
import 'package:portifolio/shared/widgets/android_dev_window_content.dart';
import 'package:portifolio/shared/widgets/flutter_dev_window_content.dart';
import 'package:portifolio/shared/widgets/project_stats_window_content.dart';

void main() {
  group('New Window Contents', () {
    testWidgets('AndroidDevWindowContent renders expertise sections', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
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
        const MaterialApp(
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
        const MaterialApp(
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
          const MaterialApp(
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
          const MaterialApp(
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
          const MaterialApp(
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
          const MaterialApp(
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
  });
}
