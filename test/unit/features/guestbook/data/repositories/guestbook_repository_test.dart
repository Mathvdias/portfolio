import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:portifolio/features/guestbook/data/repositories/guestbook_repository.dart';

void main() {
  group('GuestbookRepository', () {
    late FakeFirebaseFirestore fakeFirestore;
    late GuestbookRepository repository;

    setUp(() {
      fakeFirestore = FakeFirebaseFirestore();
      repository = GuestbookRepository(fakeFirestore);
    });

    test('addMessage adds document to firestore', () async {
      await repository.addMessage('Test User', 'Test Message', 5);

      final snapshot = await fakeFirestore.collection('guestbook').get();
      expect(snapshot.docs.length, 1);
      expect(snapshot.docs.first['name'], 'Test User');
      expect(snapshot.docs.first['message'], 'Test Message');
      expect(snapshot.docs.first['rating'], 5);
    });

    test('watchMessages emits list of messages', () async {
      await fakeFirestore.collection('guestbook').add({
        'name': 'User 1',
        'message': 'Msg 1',
        'rating': 4,
        'timestamp': DateTime.now(),
      });

      final stream = repository.watchMessages();
      final messages = await stream.first;

      expect(messages.length, 1);
      expect(messages.first.name, 'User 1');
    });

    test('deleteMessage removes document', () async {
      final doc = await fakeFirestore.collection('guestbook').add({
        'name': 'User 1',
        'message': 'Msg 1',
        'rating': 4,
        'timestamp': DateTime.now(),
      });

      await repository.deleteMessage(doc.id);

      final snapshot = await fakeFirestore.collection('guestbook').get();
      expect(snapshot.docs.isEmpty, true);
    });
  });
}
