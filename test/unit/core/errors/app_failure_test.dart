// ignore_for_file: prefer_const_constructors
import 'package:flutter_test/flutter_test.dart';
import 'package:portifolio/core/errors/app_failure.dart';

void main() {
  group('AppFailure Subclasses', () {
    test('NetworkFailure stores message correctly', () {
      final failure = NetworkFailure('no connection');
      expect(failure.message, 'no connection');
    });

    test('ServerFailure stores message correctly', () {
      final failure = ServerFailure('server error');
      expect(failure.message, 'server error');
    });

    test('CacheFailure stores message correctly', () {
      final failure = CacheFailure('cache error');
      expect(failure.message, 'cache error');
    });

    test('ValidationFailure stores message correctly', () {
      final failure = ValidationFailure('nameMessageEmpty');
      expect(failure.message, 'nameMessageEmpty');
      expect(failure, isA<AppFailure>());
    });
  });
}
