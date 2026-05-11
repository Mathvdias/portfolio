import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../theme/app_theme.dart';
import '../../../desktop/domain/models/desktop_notification.dart';
import '../../data/repositories/guestbook_repository.dart';
import '../../domain/models/guestbook_message.dart';

class GuestbookViewModel extends ChangeNotifier {
  final GuestbookRepository _repository;
  final SharedPreferences _prefs;
  void Function(DesktopNotification)? onNotification;

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

  StreamSubscription? _subscription;
  final DateTime _initTime = DateTime.now();

  GuestbookViewModel(this._repository, this._prefs) {
    _isAdmin = _prefs.getBool('isAdmin') ?? false;
    _subscribe();
  }

  void resetStatus() {
    _lastError = null;
    _success = false;
    notifyListeners();
  }

  void _subscribe() {
    _subscription = _repository.watchMessages().listen((messages) {
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
    });
  }

  Future<void> submitMessage(String name, String message, int rating) async {
    _isSubmitting = true;
    _lastError = null;
    _success = false;
    notifyListeners();

    if (name.isEmpty || message.isEmpty) {
      _lastError = 'nameMessageEmpty';
      _isSubmitting = false;
      notifyListeners();
      return;
    }

    if (name.length > 30) {
      _lastError = 'Name is too long';
      _isSubmitting = false;
      notifyListeners();
      return;
    }

    if (message.length > 500) {
      _lastError = 'Message is too long';
      _isSubmitting = false;
      notifyListeners();
      return;
    }

    // Anti-spam
    if (!_isAdmin) {
      final lastPost = _prefs.getInt('last_guestbook_post') ?? 0;
      final now = DateTime.now().millisecondsSinceEpoch;
      if (now - lastPost < 60000) {
        _lastError = 'waitToPost';
        _isSubmitting = false;
        notifyListeners();
        return;
      }
      _prefs.setInt('last_guestbook_post', now);
    }

    try {
      await _repository.addMessage(name, message, rating);
      _success = true;
    } catch (e) {
      _lastError = 'Error posting message: $e';
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
    super.dispose();
  }
}
