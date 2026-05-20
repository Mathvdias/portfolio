import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:portifolio/core/constants/project_stats.dart';

void main() {
  group('ProjectStats Synchronization (Quality Gate)', () {
    test('ProjectStats.coverage and ProjectStats.totalTests are synchronized with repository', () {
      final lcovFile = File('coverage/lcov.info');
      expect(
        lcovFile.existsSync(),
        true,
        reason: 'Error: coverage/lcov.info not found. Please run "flutter test --coverage" first.',
      );

      final lines = lcovFile.readAsLinesSync();
      int totalLines = 0;
      int hitLines = 0;

      for (final line in lines) {
        if (line.startsWith('LF:')) {
          totalLines += int.parse(line.split(':')[1]);
        } else if (line.startsWith('LH:')) {
          hitLines += int.parse(line.split(':')[1]);
        }
      }

      final double expectedCoverage = double.parse(((hitLines / totalLines) * 100).toStringAsFixed(2));

      // Count tests
      int count = 0;
      final testDir = Directory('test');
      final integrationDir = Directory('integration_test');
      final testRegExp = RegExp(r'\b(test|testWidgets)\s*\(');

      void scan(Directory dir) {
        if (!dir.existsSync()) return;
        for (final entity in dir.listSync(recursive: true)) {
          if (entity is File && entity.path.endsWith('_test.dart')) {
            final content = entity.readAsStringSync();
            final cleanContent = content
                .replaceAll(RegExp(r'//.*'), '')
                .replaceAll(RegExp(r'/\*[\s\S]*?\*/'), '');
            count += testRegExp.allMatches(cleanContent).length;
          }
        }
      }

      scan(testDir);
      scan(integrationDir);

      expect(
        ProjectStats.coverage,
        equals(expectedCoverage),
        reason: 'ProjectStats.coverage does not match the coverage computed from coverage/lcov.info.\n'
            'Expected: $expectedCoverage, Actual: ${ProjectStats.coverage}.\n'
            'Please run "dart scripts/generate_stats.dart" to synchronize.',
      );

      expect(
        ProjectStats.totalTests,
        equals(count),
        reason: 'ProjectStats.totalTests does not match the total tests counted in the test suites.\n'
            'Expected: $count, Actual: ${ProjectStats.totalTests}.\n'
            'Please run "dart scripts/generate_stats.dart" to synchronize.',
      );
    });
  });
}
