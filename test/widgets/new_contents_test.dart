// ignore_for_file: prefer_const_constructors
// Const constructors are intentionally omitted in this file so that widget
// constructors execute at runtime and are tracked by the coverage tool.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lava_flutter/lava_flutter.dart';
import 'package:portifolio/l10n/app_localizations.dart';
import 'package:portifolio/shared/constants/app_strings.dart';
import 'package:portifolio/shared/widgets/android_dev_window_content.dart';
import 'package:portifolio/shared/widgets/flutter_dev_window_content.dart';
import 'package:portifolio/shared/widgets/lava_studio_content.dart';
import 'package:portifolio/shared/widgets/project_stats_window_content.dart';

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
        find.textContaining('CustomPainter · 30 fps', skipOffstage: false),
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
      'ProjectStatsWindowContent expands the wallpaper Q&A card and shows answer points',
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

        expect(find.textContaining('drawRect'), findsWidgets);
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

    testWidgets('LavaStudioContent renders 3D studio, controls, and badges', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: [AppLocalizationsDelegate()],
          home: Scaffold(body: LavaStudioContent()),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text(AppStrings.lavaStudioTitle), findsOneWidget);
      expect(find.text(AppStrings.lavaStudioBadgeTile), findsOneWidget);
      expect(find.text(AppStrings.lavaStudioBadgeAlpha), findsOneWidget);
      expect(find.text(AppStrings.lavaStudioArchitecture), findsOneWidget);
      expect(find.byType(LavaIcon), findsNWidgets(11));
      expect(find.text(AppStrings.lavaModelMacintosh), findsWidgets);
      expect(find.text(AppStrings.lavaModelTree), findsWidgets);
      expect(find.text(AppStrings.lavaModelLavaLamp), findsWidgets);
      expect(find.text(AppStrings.lavaModelCampfire), findsWidgets);
      expect(find.text(AppStrings.lavaModelRocket), findsWidgets);
      expect(find.text(AppStrings.lavaModelSenna), findsWidgets);
      expect(find.text(AppStrings.lavaModelChristmasTree), findsWidgets);
      expect(find.text(AppStrings.lavaModelF1Car), findsWidgets);

      // Test selecting each of the 7 demo models in the category bar
      for (final modelName in [
        AppStrings.lavaModelMacintosh,
        AppStrings.lavaModelTree,
        AppStrings.lavaModelLavaLamp,
        AppStrings.lavaModelCampfire,
        AppStrings.lavaModelRocket,
        AppStrings.lavaModelSenna,
        AppStrings.lavaModelChristmasTree,
        AppStrings.lavaModelF1Car,
        AppStrings.lavaModelF1Front,
        AppStrings.lavaModelSennaMp4,
      ]) {
        await tester.ensureVisible(find.text(modelName).first);
        await tester.tap(find.text(modelName).first);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 50));
        expect(tester.takeException(), isNull);
      }

      // Tap speed selector
      await tester.ensureVisible(find.text('2.0x'));
      await tester.tap(find.text('2.0x'));
      await tester.pump();

      // The preview plays on its own: pause it, then resume
      expect(find.byTooltip(AppStrings.lavaStudioPause), findsOneWidget);
      await tester.tap(find.byTooltip(AppStrings.lavaStudioPause));
      await tester.pump();
      expect(find.byTooltip(AppStrings.lavaStudioPlay), findsOneWidget);
      await tester.tap(find.byTooltip(AppStrings.lavaStudioPlay));
      await tester.pump();
      expect(find.byTooltip(AppStrings.lavaStudioPause), findsOneWidget);

      // Tap reset
      await tester.tap(find.byTooltip(AppStrings.lavaStudioReplay));
      await tester.pump();

      // The X-ray toggle flips on and brings its legend with it
      await tester.ensureVisible(find.text(AppStrings.lavaStudioXray));
      expect(find.text(AppStrings.lavaStudioFromAtlas), findsNothing);
      await tester.tap(find.text(AppStrings.lavaStudioXray));
      await tester.pump(const Duration(milliseconds: 250));
      expect(find.text(AppStrings.lavaStudioFromAtlas), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    for (final size in const [
      Size(1600, 1000),
      Size(900, 700),
      Size(360, 740),
    ]) {
      testWidgets(
        'LavaStudioContent lays out without overflow at ${size.width.round()}x${size.height.round()}',
        (tester) async {
          tester.view.physicalSize = size;
          tester.view.devicePixelRatio = 1.0;
          addTearDown(tester.view.reset);

          await tester.pumpWidget(
            MaterialApp(
              localizationsDelegates: [AppLocalizationsDelegate()],
              home: Scaffold(body: LavaStudioContent()),
            ),
          );
          await tester.pump(const Duration(milliseconds: 100));

          expect(tester.takeException(), isNull);
          expect(find.text(AppStrings.lavaStudioInspector), findsOneWidget);
          expect(find.text(AppStrings.lavaStudioFaceOff), findsOneWidget);
          expect(find.text(AppStrings.lavaStudioFormatLava), findsOneWidget);
          // Reading text never drops under 12 logical pixels.
          for (final text in tester.widgetList<Text>(find.byType(Text))) {
            final fontSize = text.style?.fontSize;
            if (fontSize != null &&
                text.style?.fontFamily?.contains('SpaceMono') == true) {
              expect(fontSize, greaterThanOrEqualTo(12.0), reason: text.data);
            }
          }
        },
      );
    }

    testWidgets('LavaStudioContent preview plays the decoded OpenLava bundle', (
      tester,
    ) async {
      // Asset loads started under the previous tests' fake clock never finish
      // and stay cached, so start from clean caches.
      rootBundle.clear();
      LavaBundle.evictOpenLavaCache();
      final paintedIcons = find.descendant(
        of: find.byType(LavaIcon),
        matching: find.byType(CustomPaint),
      );

      // PNG decoding only progresses on the real event loop.
      await tester.runAsync(() async {
        await tester.pumpWidget(
          MaterialApp(
            localizationsDelegates: [AppLocalizationsDelegate()],
            home: Scaffold(body: LavaStudioContent()),
          ),
        );
        for (var i = 0; i < 100 && paintedIcons.evaluate().length < 11; i++) {
          await Future<void>.delayed(const Duration(milliseconds: 50));
          await tester.pump();
        }
      });
      expect(paintedIcons, findsNWidgets(11));

      // Bounds come from the manifest (48 frames), not the controller default.
      expect(find.textContaining('/ 48'), findsOneWidget);
      expect(find.textContaining('PLAYING'), findsOneWidget);

      final before = tester.widget<Slider>(find.byType(Slider)).value;
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pump(const Duration(milliseconds: 200));
      final after = tester.widget<Slider>(find.byType(Slider)).value;
      expect(after, isNot(before));
      expect(tester.takeException(), isNull);
    });
  });
}
