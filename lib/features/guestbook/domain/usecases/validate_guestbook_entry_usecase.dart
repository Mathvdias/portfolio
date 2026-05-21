import '../../../../core/errors/app_failure.dart';
import '../../../../core/result/result.dart';

/// Validates name and message before a guestbook submission.
///
/// Returns [Success] when all rules pass, or [Failure] with a
/// [ValidationFailure] containing the l10n error key.
class ValidateGuestbookEntryUseCase {
  const ValidateGuestbookEntryUseCase(); // coverage:ignore-line

  static const int maxNameLength = 30;
  static const int maxMessageLength = 500;

  Result<void> call(String name, String message) {
    if (name.isEmpty || message.isEmpty) {
      return const Failure(ValidationFailure('nameMessageEmpty'));
    }
    if (name.length > maxNameLength) {
      return const Failure(ValidationFailure('Name is too long'));
    }
    if (message.length > maxMessageLength) {
      return const Failure(ValidationFailure('Message is too long'));
    }
    return const Success(null);
  }
}
