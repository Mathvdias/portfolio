import 'dart:io';

void main() {
  final file = File('coverage/lcov.info');
  if (!file.existsSync()) return;

  final content = file.readAsStringSync();
  final sections = content.split('end_of_record');

  int totalFound = 0;
  int totalHit = 0;

  for (final section in sections) {
    if (section.trim().isEmpty) continue;
    final lines = section.split('\n');
    String sourceFile = '';
    int found = 0;
    int hit = 0;

    for (final line in lines) {
      if (line.startsWith('SF:')) sourceFile = line.substring(3);
      if (line.startsWith('LF:')) found = int.parse(line.substring(3));
      if (line.startsWith('LH:')) hit = int.parse(line.substring(3));
    }

    if (found > 0) {
      totalFound += found;
      totalHit += hit;
      final percentage = (hit / found) * 100;
      print(
        '${percentage.toStringAsFixed(1).padLeft(5)}% | ${sourceFile.split('portifolio/').last}',
      );
    }
  }

  if (totalFound > 0) {
    final overall = (totalHit / totalFound) * 100;
    print('-' * 40);
    print('OVERALL COVERAGE: ${overall.toStringAsFixed(2)}%');
    print('-' * 40);
  }
}
