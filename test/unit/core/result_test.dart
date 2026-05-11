import 'package:flutter_test/flutter_test.dart';
import 'package:portifolio/core/result/result.dart';
import 'package:portifolio/core/errors/app_failure.dart';

void main() {
  group('Result', () {
    test('Success.isSuccess returns true', () {
      const result = Success(42);
      expect(result.isSuccess, isTrue);
    });

    test('Success.isFailure returns false', () {
      const result = Success(42);
      expect(result.isFailure, isFalse);
    });

    test('Failure.isFailure returns true', () {
      const result = Failure<int>(NetworkFailure('error'));
      expect(result.isFailure, isTrue);
    });

    test('Failure.isSuccess returns false', () {
      const result = Failure<int>(NetworkFailure('error'));
      expect(result.isSuccess, isFalse);
    });

    test('fold calls onSuccess for Success', () {
      const result = Success(10);
      final out = result.fold(
        (f) => 'failure: ${f.message}',
        (v) => 'success: $v',
      );
      expect(out, 'success: 10');
    });

    test('fold calls onFailure for Failure', () {
      const result = Failure<int>(NetworkFailure('boom'));
      final out = result.fold(
        (f) => 'failure: ${f.message}',
        (v) => 'success: $v',
      );
      expect(out, 'failure: boom');
    });

    test('Failure stores the AppFailure', () {
      const failure = NetworkFailure('oops');
      const result = Failure<String>(failure);
      expect(result.failure, failure);
    });

    test('Success stores the value', () {
      const result = Success('hello');
      expect(result.value, 'hello');
    });
  });
}
