import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:portifolio/shared/widgets/android_dev_window_content.dart';
import 'package:portifolio/shared/widgets/project_stats_window_content.dart';

void main() {
  group('New Window Contents', () {
    testWidgets('AndroidDevWindowContent renders expertise sections', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: AndroidDevWindowContent())),
      );

      expect(find.text('Android Development'), findsOneWidget);
      expect(find.text('Core Technologies'), findsOneWidget);
      expect(find.text('Kotlin'), findsOneWidget);
      expect(find.text('Jetpack Compose'), findsOneWidget);
    });

    testWidgets('ProjectStatsWindowContent renders coverage indicator', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: ProjectStatsWindowContent())),
      );

      expect(find.text('PROJECT METRICS'), findsOneWidget);
      expect(find.textContaining('%'), findsOneWidget);
      expect(find.text('COVERAGE'), findsOneWidget);
      expect(find.text('Unit Tests'), findsOneWidget);
    });
  });
}
