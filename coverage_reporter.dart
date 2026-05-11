import 'dart:developer' as dev;
import 'dart:io';

void main() {
  final lcovFile = File('coverage/lcov.info');
  if (!lcovFile.existsSync()) {
    dev.log(
      'Error: lcov.info not found. Run "flutter test --coverage" first.',
      name: 'CoverageReporter',
      level: 1000,
    );
    exit(1);
  }

  final lines = lcovFile.readAsLinesSync();
  final fileStats = <String, double>{};
  String? currentFile;
  int? currentLF;
  int? currentLH;

  for (final line in lines) {
    if (line.startsWith('SF:')) {
      currentFile = line
          .substring(3)
          .replaceAll('${Directory.current.path}/', '');
    } else if (line.startsWith('LF:')) {
      currentLF = int.parse(line.substring(3));
    } else if (line.startsWith('LH:')) {
      currentLH = int.parse(line.substring(3));
    } else if (line == 'end_of_record') {
      if (currentFile != null && currentLF != null && currentLH != null) {
        if (currentLF > 0) {
          fileStats[currentFile] = (currentLH / currentLF) * 100;
        }
      }
      currentFile = null;
      currentLF = null;
      currentLH = null;
    }
  }

  double totalLF = 0;
  double totalLH = 0;

  for (final line in lines) {
    if (line.startsWith('LF:')) totalLF += double.parse(line.substring(3));
    if (line.startsWith('LH:')) totalLH += double.parse(line.substring(3));
  }

  final sortedFiles =
      fileStats.keys.toList()
        ..sort((a, b) => fileStats[a]!.compareTo(fileStats[b]!));
  for (final file in sortedFiles) {
    final percentage = fileStats[file]!.toStringAsFixed(1);
    dev.log('$percentage% | $file', name: 'CoverageReporter');
  }

  final overall = (totalLH / totalLF) * 100;
  dev.log('----------------------------------------', name: 'CoverageReporter');
  dev.log(
    'OVERALL COVERAGE: ${overall.toStringAsFixed(2)}%',
    name: 'CoverageReporter',
  );
  dev.log('----------------------------------------', name: 'CoverageReporter');
}
