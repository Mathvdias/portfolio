import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:portifolio/core/errors/app_failure.dart';
import 'package:portifolio/core/result/result.dart';
import 'package:portifolio/features/guestbook/domain/usecases/check_post_cooldown_usecase.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockSharedPreferences extends Mock implements SharedPreferences {}

void main() {
  late MockSharedPreferences prefs;
  late CheckPostCooldownUseCase usecase;

  setUp(() {
    prefs = MockSharedPreferences();
    usecase = CheckPostCooldownUseCase(prefs);
  });

  group('CheckPostCooldownUseCase', () {
    test('returns Success for admin regardless of last post time', () {
      when(
        () => prefs.getInt(CheckPostCooldownUseCase.prefKey),
      ).thenReturn(DateTime.now().millisecondsSinceEpoch);

      final result = usecase(isAdmin: true);
      expect(result, isA<Success<void>>());
    });

    test('returns Success when no last post recorded', () {
      when(
        () => prefs.getInt(CheckPostCooldownUseCase.prefKey),
      ).thenReturn(null);

      final result = usecase(isAdmin: false);
      expect(result, isA<Success<void>>());
    });

    test('returns Success when cooldown has elapsed', () {
      when(() => prefs.getInt(CheckPostCooldownUseCase.prefKey)).thenReturn(
        DateTime.now().millisecondsSinceEpoch -
            CheckPostCooldownUseCase.cooldownMs -
            1000,
      );

      final result = usecase(isAdmin: false);
      expect(result, isA<Success<void>>());
    });

    test('returns Failure when within cooldown window', () {
      when(
        () => prefs.getInt(CheckPostCooldownUseCase.prefKey),
      ).thenReturn(DateTime.now().millisecondsSinceEpoch);

      final result = usecase(isAdmin: false);
      expect(result, isA<Failure<void>>());
      expect((result as Failure).failure, isA<ValidationFailure>());
      expect((result).failure.message, 'waitToPost');
    });

    test('returns Failure when last post was just a moment ago', () {
      when(
        () => prefs.getInt(CheckPostCooldownUseCase.prefKey),
      ).thenReturn(DateTime.now().millisecondsSinceEpoch - 1000);

      final result = usecase(isAdmin: false);
      expect(result, isA<Failure<void>>());
    });
  });
}
