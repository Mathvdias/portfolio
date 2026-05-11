
import 'package:flutter_test/flutter_test.dart';
import 'package:portifolio/core/errors/app_failure.dart';

class TestFailure extends AppFailure {
  const TestFailure(super.message);
}

void main() {
  group('AppFailure', () {
    test('props are correct', () {
      const failure = TestFailure('error');
      expect(failure.message, 'error');
      expect(failure.props, ['error']);
    });
  });
}
