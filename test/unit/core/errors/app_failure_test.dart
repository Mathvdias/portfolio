
import 'package:flutter_test/flutter_test.dart';
import 'package:portifolio/core/errors/app_failure.dart';

void main() {
  group('AppFailure Subclasses', () {
    test('NetworkFailure stores message correctly', () {
      const failure = NetworkFailure('no connection');
      expect(failure.message, 'no connection');
    });

    test('ServerFailure stores message correctly', () {
      const failure = ServerFailure('server error');
      expect(failure.message, 'server error');
    });

    test('CacheFailure stores message correctly', () {
      const failure = CacheFailure('cache error');
      expect(failure.message, 'cache error');
    });
  });
}
