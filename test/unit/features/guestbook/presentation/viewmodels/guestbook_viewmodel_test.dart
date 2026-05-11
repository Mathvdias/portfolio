
import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:portifolio/features/guestbook/presentation/viewmodels/guestbook_viewmodel.dart';
import 'package:portifolio/features/guestbook/data/repositories/guestbook_repository.dart';
import 'package:portifolio/features/guestbook/domain/models/guestbook_message.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockGuestbookRepository implements GuestbookRepository {
  final _controller = StreamController<List<GuestbookMessage>>.broadcast();
  List<GuestbookMessage> messages = [
    GuestbookMessage(id: '1', name: 'User', message: 'Hi', rating: 5, timestamp: DateTime.now())
  ];

  @override
  Stream<List<GuestbookMessage>> watchMessages() => _controller.stream;

  @override
  Future<void> addMessage(String name, String message, int rating) async {
    messages.add(GuestbookMessage(id: '2', name: name, message: message, rating: rating, timestamp: DateTime.now()));
    _controller.add(messages);
  }

  @override
  Future<void> deleteMessage(String id) async {
    messages.removeWhere((m) => m.id == id);
    _controller.add(messages);
  }

  void dispose() => _controller.close();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('GuestbookViewModel', () {
    late MockGuestbookRepository repo;

    setUp(() {
      repo = MockGuestbookRepository();
    });

    test('loads messages and handles admin', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final vm = GuestbookViewModel(repo, prefs);

      expect(vm.isLoading, true);
      repo._controller.add(repo.messages);
      await Future.delayed(Duration.zero);
      expect(vm.isLoading, false);
      expect(vm.messages.length, 1);

      vm.setAdmin(true);
      expect(vm.isAdmin, true);
      
      vm.setAdmin(false);
      await vm.submitMessage('Test', 'Msg', 5);
      expect(vm.success, true);
      
      await vm.submitMessage('Test2', 'Msg2', 5);
      expect(vm.lastError, 'waitToPost');

      repo.dispose();
    });

    test('handles timeout', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final hangingRepo = HangingGuestbookRepository();
      final vm = GuestbookViewModel(hangingRepo, prefs);
      
      await vm.submitMessage('Hanging', 'Msg', 5);
      expect(vm.lastError, contains('Timeout'));
      
      hangingRepo.dispose();
    });
  });
}

class HangingGuestbookRepository extends MockGuestbookRepository {
  @override
  Future<void> addMessage(String name, String message, int rating) async {
    await Future.delayed(const Duration(seconds: 15));
  }
}
