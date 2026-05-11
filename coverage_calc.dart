import 'dart:io';

void main() {
  final file = File('coverage/lcov.info');
  if (!file.existsSync()) {
    print('Coverage file not found.');
    return;
  }

  int linesFound = 0;
  int linesHit = 0;

  final lines = file.readAsLinesSync();
  for (final line in lines) {
    if (line.startsWith('LF:')) {
      linesFound += int.parse(line.substring(3));
    } else if (line.startsWith('LH:')) {
      linesHit += int.parse(line.substring(3));
    }
  }

  if (linesFound == 0) {
    print('No lines found for coverage.');
  } else {
    final percentage = (linesHit / linesFound) * 100;
    print('Total Coverage: ${percentage.toStringAsFixed(2)}% ($linesHit / $linesFound lines)');
  }
}
