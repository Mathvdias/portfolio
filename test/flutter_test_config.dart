import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

/// Um comparador de arquivos de Golden Tests tolerante que aceita pequenas
/// diferenças de renderização entre sistemas operacionais (como macOS vs Linux).
class TolerantFileComparator extends LocalFileComparator {
  TolerantFileComparator(super.testFile, this.tolerance);

  /// Tolerância máxima aceitável de pixels divergentes (ex: 0.05 representa 5%).
  final double tolerance;

  @override
  Future<bool> compare(Uint8List imageBytes, Uri golden) async {
    final ComparisonResult result = await GoldenFileComparator.compareLists(
      imageBytes,
      await getGoldenBytes(golden),
    );

    if (result.passed || result.diffPercent <= tolerance) {
      if (!result.passed) {
        debugPrint(
          'Golden test para "$golden" passou com ${result.diffPercent * 100}% de diferença '
          '(dentro da tolerância de ${tolerance * 100}%).',
        );
      }
      result.dispose();
      return true;
    }

    final String error = await generateFailureOutput(result, golden, basedir);
    result.dispose();
    throw FlutterError(error);
  }
}

Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  if (goldenFileComparator is LocalFileComparator) {
    final original = goldenFileComparator as LocalFileComparator;
    final testUri = original.basedir.resolve('test.dart');
    // Configura 5% de tolerância para evitar quebra de testes na CI do GitHub Actions (Linux)
    goldenFileComparator = TolerantFileComparator(testUri, 0.05);
  }
  await testMain();
}
