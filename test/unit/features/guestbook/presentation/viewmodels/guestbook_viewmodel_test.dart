import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:portifolio/features/guestbook/domain/models/guestbook_message.dart';
import 'package:portifolio/features/guestbook/data/repositories/guestbook_repository.dart';
import 'package:portifolio/features/guestbook/presentation/viewmodels/guestbook_viewmodel.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockGuestbookRepository implements GuestbookRepository {
  final _controller = StreamController<List<GuestbookMessage>>.broadcast();
  List<GuestbookMessage> messages = [];

  @override
  Stream<List<GuestbookMessage>> watchMessages() => _controller.stream;

  @override
  Future<void> addMessage(String name, String message, int rating) async {
    final msg = GuestbookMessage(
      id: 'mock_${messages.length}',
      name: name,
      message: message,
      rating: rating,
      timestamp: DateTime.now(),
    );
    messages.add(msg);
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
  test('GuestbookViewModel loads messages and handles admin', () async {
    SharedPreferences.setMockInitialValues({'isAdmin': false});
    final prefs = await SharedPreferences.getInstance();
    final repo = MockGuestbookRepository();
    
    final vm = GuestbookViewModel(repo, prefs);
    
    expect(vm.isLoading, true);
    expect(vm.isAdmin, false);
    
    repo._controller.add([]);
    await Future.delayed(Duration.zero);
    
    expect(vm.isLoading, false);
    expect(vm.messages.length, 0);

    vm.setAdmin(true);
    expect(vm.isAdmin, true);
    expect(prefs.getBool('isAdmin'), true);
    
    repo.dispose();
  });
}
