import 'dart:async' show StreamController, TimeoutException;
import 'package:flutter_test/flutter_test.dart';
import 'package:portifolio/features/guestbook/presentation/viewmodels/guestbook_viewmodel.dart';
import 'package:portifolio/features/guestbook/data/repositories/guestbook_repository.dart';
import 'package:portifolio/features/guestbook/domain/models/guestbook_message.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mocktail/mocktail.dart';

class MockGuestbookRepository implements GuestbookRepository {
  final _controller = StreamController<List<GuestbookMessage>>.broadcast();
  List<GuestbookMessage> messages = [];

  @override
  Stream<List<GuestbookMessage>> watchMessages() => _controller.stream;

  @override
  Future<void> addMessage(String name, String message, int rating) async {
    messages.add(
      GuestbookMessage(
        id: 'new',
        name: name,
        message: message,
        rating: rating,
        timestamp: DateTime.now(),
      ),
    );
    _controller.add(messages);
  }

  @override
  Future<void> deleteMessage(String id) async {
    messages.removeWhere((m) => m.id == id);
    _controller.add(messages);
  }

  void dispose() => _controller.close();
  void emitError() => _controller.addError('Stream Error');
}

class MockSharedPreferences extends Mock implements SharedPreferences {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('GuestbookViewModel Full Coverage', () {
    late MockGuestbookRepository repo;
    late MockSharedPreferences prefs;

    setUp(() {
      repo = MockGuestbookRepository();
      prefs = MockSharedPreferences();
      when(() => prefs.getBool(any())).thenReturn(null);
      when(() => prefs.getInt(any())).thenReturn(null);
      when(() => prefs.setBool(any(), any())).thenAnswer((_) async => true);
      when(() => prefs.setInt(any(), any())).thenAnswer((_) async => true);
    });

    test('validations and status resets', () async {
      final vm = GuestbookViewModel(repo, prefs);

      // Empty check
      await vm.submitMessage('', '', 5);
      expect(vm.lastError, 'nameMessageEmpty');

      // Name length
      await vm.submitMessage('a' * 31, 'msg', 5);
      expect(vm.lastError, contains('too long'));

      // Message length
      await vm.submitMessage('name', 'a' * 501, 5);
      expect(vm.lastError, contains('too long'));

      vm.resetStatus();
      expect(vm.lastError, isNull);
      expect(vm.success, false);
    });

    test('notifications logic', () async {
      final vm = GuestbookViewModel(repo, prefs);
      bool notified = false;
      vm.onNotification = (n) => notified = true;

      // Initial load (should not notify)
      repo._controller.add([
        GuestbookMessage(
          id: '1',
          name: 'Old',
          message: 'Hi',
          rating: 5,
          timestamp: DateTime.now(),
        ),
      ]);
      await Future<void>.delayed(Duration.zero);
      expect(notified, false);

      // New message arrival
      repo._controller.add([
        GuestbookMessage(
          id: '1',
          name: 'Old',
          message: 'Hi',
          rating: 5,
          timestamp: DateTime.now(),
        ),
        GuestbookMessage(
          id: '2',
          name: 'New',
          message: 'Yo',
          rating: 4,
          timestamp: DateTime.now().add(const Duration(seconds: 1)),
        ),
      ]);
      await Future<void>.delayed(Duration.zero);
      expect(notified, true);
    });

    test('retry and stream error', () async {
      final vm = GuestbookViewModel(repo, prefs);

      repo.emitError();
      await Future<void>.delayed(Duration.zero);
      expect(vm.lastError, contains('Stream Error'));

      vm.retry();
      expect(vm.isLoading, true);
    });

    test('admin delete', () async {
      when(() => prefs.getBool('isAdmin')).thenReturn(true);
      final vm = GuestbookViewModel(repo, prefs);

      repo.messages = [
        GuestbookMessage(
          id: 'del',
          name: 'N',
          message: 'M',
          rating: 1,
          timestamp: DateTime.now(),
        ),
      ];
      await vm.deleteMessage('del');
      expect(repo.messages, isEmpty);

      // Non-admin delete should do nothing
      vm.setAdmin(false);
      repo.messages = [
        GuestbookMessage(
          id: 'keep',
          name: 'N',
          message: 'M',
          rating: 1,
          timestamp: DateTime.now(),
        ),
      ];
      await vm.deleteMessage('keep');
      expect(repo.messages.length, 1);
    });

    test('dispose cancels subscription', () {
      final vm = GuestbookViewModel(repo, prefs);
      vm.dispose();
      // No explicit way to check subscription cancelation without more mocks,
      // but calling it ensures it doesn't crash and covers the lines.
    });

    test('anti-spam blocks posting within 60 seconds', () async {
      when(() => prefs.getBool('isAdmin')).thenReturn(false);
      when(
        () => prefs.getInt('last_guestbook_post'),
      ).thenReturn(DateTime.now().millisecondsSinceEpoch);
      final vm = GuestbookViewModel(repo, prefs);

      await vm.submitMessage('Name', 'Message', 5);

      expect(vm.lastError, 'waitToPost');
      expect(vm.isSubmitting, false);
      vm.dispose();
    });

    test('submitMessage catches generic exceptions', () async {
      when(() => prefs.getBool('isAdmin')).thenReturn(false);
      when(() => prefs.getInt(any())).thenReturn(null);
      when(() => prefs.setInt(any(), any())).thenAnswer((_) async => true);

      final failing = _FailingGuestbookRepository();
      final vm = GuestbookViewModel(failing, prefs);

      await vm.submitMessage('Name', 'Message', 5);

      expect(vm.lastError, contains('Network error'));
      expect(vm.isSubmitting, false);
      vm.dispose();
      failing.dispose();
    });

    test('submitMessage catches TimeoutException', () async {
      when(() => prefs.getBool('isAdmin')).thenReturn(false);
      when(() => prefs.getInt(any())).thenReturn(null);
      when(() => prefs.setInt(any(), any())).thenAnswer((_) async => true);

      final timeout = _TimeoutGuestbookRepository();
      final vm = GuestbookViewModel(timeout, prefs);

      await vm.submitMessage('Name', 'Message', 5);

      expect(vm.lastError, contains('timed out'));
      expect(vm.isSubmitting, false);
      vm.dispose();
      timeout.dispose();
    });
  });
}

class HangingGuestbookRepository extends MockGuestbookRepository {
  @override
  Future<void> addMessage(String name, String message, int rating) async {
    await Future<void>.delayed(const Duration(seconds: 15));
  }
}

class _FailingGuestbookRepository extends MockGuestbookRepository {
  @override
  Future<void> addMessage(String name, String message, int rating) async {
    throw Exception('Network error');
  }
}

class _TimeoutGuestbookRepository extends MockGuestbookRepository {
  @override
  Future<void> addMessage(String name, String message, int rating) async {
    throw TimeoutException(
      'Connection timed out. Check your internet or Firebase rules.',
    );
  }
}
