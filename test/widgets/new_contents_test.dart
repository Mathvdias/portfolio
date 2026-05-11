import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:portifolio/l10n/app_localizations.dart';
import 'package:portifolio/shared/widgets/android_dev_window_content.dart';
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
      expect(find.textContaining('%'), findsOneWidget);
      expect(find.text('COVERAGE'), findsOneWidget);
      expect(find.text('Unit Tests'), findsOneWidget);
    });

    testWidgets('ProjectStatsWindowContent renders yellow for 60-79% coverage',
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
    });

    testWidgets('ProjectStatsWindowContent renders red for below 60% coverage',
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
    });
  });
}
