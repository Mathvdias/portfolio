
import 'package:flutter_test/flutter_test.dart';
import 'package:portifolio/features/guestbook/presentation/viewmodels/guestbook_viewmodel.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../mocks/mock_guestbook_repository.dart';

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
      await Future.delayed(Duration.zero);
      expect(vm.isLoading, false);
      expect(vm.messages.length, 1);
      expect(vm.isAdmin, false);

      vm.setAdmin(true);
      expect(vm.isAdmin, true);
      expect(prefs.getBool('isAdmin'), true);
      
      vm.setAdmin(false);
      await vm.submitMessage('Test', 'Msg', 5);
      expect(vm.success, true);
      
      // Rate limit test
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
    // Return a future that never completes or takes too long
    await Future.delayed(const Duration(seconds: 15));
  }
}
