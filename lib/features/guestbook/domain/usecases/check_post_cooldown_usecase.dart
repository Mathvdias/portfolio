import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/errors/app_failure.dart';
import '../../../../core/result/result.dart';

/// Enforces the 60-second anti-spam cooldown between guestbook submissions.
///
/// Admin users bypass the cooldown.
/// Returns [Success] when posting is allowed, or [Failure] with a
/// [ValidationFailure('waitToPost')] when the cooldown has not elapsed.
class CheckPostCooldownUseCase {
  const CheckPostCooldownUseCase(this._prefs);

  final SharedPreferences _prefs;

  static const int cooldownMs = 60000;
  static const String prefKey = 'last_guestbook_post';

  Result<void> call({required bool isAdmin}) {
    if (isAdmin) return const Success(null);

    final lastPost = _prefs.getInt(prefKey) ?? 0;
    final now = DateTime.now().millisecondsSinceEpoch;

    if (now - lastPost < cooldownMs) {
      return const Failure(ValidationFailure('waitToPost'));
    }

    return const Success(null);
  }
}
