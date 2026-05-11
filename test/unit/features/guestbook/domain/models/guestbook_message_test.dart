import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:portifolio/features/guestbook/domain/models/guestbook_message.dart';

void main() {
  group('GuestbookMessage', () {
    test('fromFirestore creates correct object', () {
      final now = DateTime.now();
      final timestamp = Timestamp.fromDate(now);
      final id = '123';
      final data = {
        'name': 'John',
        'message': 'Hello',
        'rating': 4,
        'timestamp': timestamp,
      };

      final msg = GuestbookMessage.fromFirestore(id, data);

      expect(msg.id, '123');
      expect(msg.name, 'John');
      expect(msg.message, 'Hello');
      expect(msg.rating, 4);
      expect(msg.timestamp, now);
    });

    test('fromFirestore handles null values', () {
      final id = '123';
      final Map<String, dynamic>? data = null;

      final msg = GuestbookMessage.fromFirestore(id, data);

      expect(msg.id, '123');
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
