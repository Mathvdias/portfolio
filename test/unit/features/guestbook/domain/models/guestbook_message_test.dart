
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:portifolio/features/guestbook/domain/models/guestbook_message.dart';
import 'package:mocktail/mocktail.dart';

class MockDocumentSnapshot extends Mock implements DocumentSnapshot {}

void main() {
  group('GuestbookMessage', () {
    test('fromFirestore creates correct object', () {
      final mockDoc = MockDocumentSnapshot();
      final now = DateTime.now();
      final timestamp = Timestamp.fromDate(now);
      
      when(() => mockDoc.id).thenReturn('123');
      when(() => mockDoc.data()).thenReturn({
        'name': 'John',
        'message': 'Hello',
        'rating': 4,
        'timestamp': timestamp,
      });

      final msg = GuestbookMessage.fromFirestore(mockDoc);

      expect(msg.id, '123');
      expect(msg.name, 'John');
      expect(msg.message, 'Hello');
      expect(msg.rating, 4);
      expect(msg.timestamp, now);
    });

    test('fromFirestore handles null values', () {
      final mockDoc = MockDocumentSnapshot();
      
      when(() => mockDoc.id).thenReturn('123');
      when(() => mockDoc.data()).thenReturn(null);

      final msg = GuestbookMessage.fromFirestore(mockDoc);

      expect(msg.name, 'Anonymous');
      expect(msg.message, '');
      expect(msg.rating, 5);
      expect(msg.timestamp, isA<DateTime>());
    });

    test('toFirestore creates correct map', () {
      final now = DateTime.now();
      final msg = GuestbookMessage(
        id: '123',
        name: 'John',
        message: 'Hello',
        rating: 4,
        timestamp: now,
      );

      final map = msg.toFirestore();

      expect(map['name'], 'John');
      expect(map['message'], 'Hello');
      expect(map['rating'], 4);
      expect(map['timestamp'], isA<Timestamp>());
    });
  });
}
