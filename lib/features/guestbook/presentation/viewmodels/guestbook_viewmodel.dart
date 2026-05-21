import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/result/result.dart';
import '../../../../core/services/analytics_service.dart';
import '../../../../theme/app_theme.dart';
import '../../../desktop/domain/models/desktop_notification.dart';
import '../../data/repositories/guestbook_repository.dart';
import '../../domain/models/guestbook_message.dart';
import '../../domain/usecases/check_post_cooldown_usecase.dart';
import '../../domain/usecases/validate_guestbook_entry_usecase.dart';

class GuestbookViewModel extends ChangeNotifier {
  final GuestbookRepository _repository;
  final SharedPreferences _prefs;
  final ValidateGuestbookEntryUseCase _validateEntry;
  final CheckPostCooldownUseCase _checkCooldown;
  final Duration _submitTimeout;

  void Function(DesktopNotification)? onNotification;
  AnalyticsService? analytics;

  List<GuestbookMessage> _messages = [];
  List<GuestbookMessage> get messages => _messages;

  bool _isLoading = true;
  bool get isLoading => _isLoading;

  bool _isAdmin = false;
  bool get isAdmin => _isAdmin;

  bool _isSubmitting = false;
  bool get isSubmitting => _isSubmitting;

  String? _lastError;
  String? get lastError => _lastError;

  bool _success = false;
  bool get success => _success;

  StreamSubscription<List<GuestbookMessage>>? _subscription;
  Timer? _loadingTimer;
  final DateTime _initTime = DateTime.now();

  GuestbookViewModel(
    this._repository,
    this._prefs, {
    ValidateGuestbookEntryUseCase? validateEntry,
    CheckPostCooldownUseCase? checkCooldown,
    @visibleForTesting Duration? submitTimeout,
  }) : _validateEntry = validateEntry ?? const ValidateGuestbookEntryUseCase(),
       _checkCooldown = checkCooldown ?? CheckPostCooldownUseCase(_prefs),
       _submitTimeout = submitTimeout ?? const Duration(seconds: 10) {
    _isAdmin = _prefs.getBool('isAdmin') ?? false;
    _subscribe();
  }

  void resetStatus() {
    _lastError = null;
    _success = false;
    notifyListeners();
  }

  void retry() {
    _isLoading = true;
    _lastError = null;
    _subscription?.cancel();
    notifyListeners();
    _subscribe();
  }

  void _subscribe() {
    _subscription = _repository.watchMessages().listen(
      (messages) {
        _loadingTimer?.cancel();
        // Find new messages to notify
        if (!_isLoading) {
          final newMsgs = messages.where(
            (m) =>
                m.timestamp.isAfter(_initTime) &&
                !_messages.any((old) => old.id == m.id),
          );

          for (final msg in newMsgs) {
            onNotification?.call(
              DesktopNotification(
                title: 'New Guestbook Message',
                message: '${msg.name} left a ${msg.rating}-star review!',
                icon: Icons.book,
                color: AppTheme.blue,
                time: DateTime.now(),
              ),
            );
          }
        }

        _messages = messages;
        _isLoading = false;
        notifyListeners();
      },
      onError: (Object e) {
        _isLoading = false;
        _lastError = 'Error loading messages: $e';
        notifyListeners();
      },
    );
  }

  Future<void> submitMessage(String name, String message, int rating) async {
    _isSubmitting = true;
    _lastError = null;
    _success = false;
    notifyListeners();

    final validation = _validateEntry(name, message);
    if (validation case Failure(:final failure)) {
      _lastError = failure.message;
      _isSubmitting = false;
      notifyListeners();
      return;
    }

    final cooldown = _checkCooldown(isAdmin: _isAdmin);
    if (cooldown case Failure(:final failure)) {
      _lastError = failure.message;
      _isSubmitting = false;
      notifyListeners();
      return;
    }

    try {
      await _repository
          .addMessage(name, message, rating)
          .timeout(
            _submitTimeout,
            onTimeout:
                () =>
                    throw TimeoutException(
                      'Connection timed out. Check your internet or Firebase rules.',
                    ),
          );
      _success = true;
      unawaited(analytics?.logGuestbookPost(rating));
      if (!_isAdmin) {
        _prefs.setInt(
          'last_guestbook_post',
          DateTime.now().millisecondsSinceEpoch,
        );
      }
    } catch (e) {
      _lastError = '$e';
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  Future<void> deleteMessage(String id) async {
    if (!_isAdmin) return;
    await _repository.deleteMessage(id);
  }

  void setAdmin(bool value) {
    _isAdmin = value;
    _prefs.setBool('isAdmin', value);
    notifyListeners();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _loadingTimer?.cancel();
    super.dispose();
  }
}
