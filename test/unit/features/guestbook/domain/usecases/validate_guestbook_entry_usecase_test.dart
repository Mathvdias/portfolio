import 'package:flutter_test/flutter_test.dart';
import 'package:portifolio/core/errors/app_failure.dart';
import 'package:portifolio/core/result/result.dart';
import 'package:portifolio/features/guestbook/domain/usecases/validate_guestbook_entry_usecase.dart';

void main() {
  final usecase = ValidateGuestbookEntryUseCase();

  group('ValidateGuestbookEntryUseCase', () {
    test('returns Success for valid name and message', () {
      final result = usecase('Alice', 'Hello there!');
      expect(result, isA<Success<void>>());
    });

    test('returns failure when name is empty', () {
      final result = usecase('', 'Hello');
      expect(result, isA<Failure<void>>());
      expect((result as Failure).failure.message, 'nameMessageEmpty');
    });

    test('returns failure when message is empty', () {
      final result = usecase('Alice', '');
      expect(result, isA<Failure<void>>());
      expect((result as Failure).failure.message, 'nameMessageEmpty');
    });

    test('returns failure when both are empty', () {
      final result = usecase('', '');
      expect(result, isA<Failure<void>>());
      expect((result as Failure).failure, isA<ValidationFailure>());
    });

    test('accepts name of exactly $maxNameLength chars', () {
      final result = usecase(
        'a' * ValidateGuestbookEntryUseCase.maxNameLength,
        'msg',
      );
      expect(result, isA<Success<void>>());
    });

    test('rejects name exceeding $maxNameLength chars', () {
      final result = usecase(
        'a' * (ValidateGuestbookEntryUseCase.maxNameLength + 1),
        'msg',
      );
      expect(result, isA<Failure<void>>());
      expect((result as Failure).failure.message, contains('too long'));
    });

    test('accepts message of exactly $maxMessageLength chars', () {
      final result = usecase(
        'Alice',
        'a' * ValidateGuestbookEntryUseCase.maxMessageLength,
      );
      expect(result, isA<Success<void>>());
    });

    test('rejects message exceeding $maxMessageLength chars', () {
      final result = usecase(
        'Alice',
        'a' * (ValidateGuestbookEntryUseCase.maxMessageLength + 1),
      );
      expect(result, isA<Failure<void>>());
      expect((result as Failure).failure.message, contains('too long'));
    });
  });
}

const int maxNameLength = ValidateGuestbookEntryUseCase.maxNameLength;
const int maxMessageLength = ValidateGuestbookEntryUseCase.maxMessageLength;
