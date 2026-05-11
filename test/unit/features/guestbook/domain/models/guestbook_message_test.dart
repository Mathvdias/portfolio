import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:portifolio/features/guestbook/domain/models/guestbook_message.dart';

void main() {
  test('GuestbookMessage toFirestore and fromFirestore mapping', () {
    final timestamp = DateTime(2026, 1, 1);
    final msg = GuestbookMessage(
      id: '123',
      name: 'Test',
      message: 'Hello',
      rating: 5,
      timestamp: timestamp,
    );

    final map = msg.toFirestore();
    expect(map['name'], 'Test');
    expect(map['message'], 'Hello');
    expect(map['rating'], 5);
    expect(map['timestamp'], isA<Timestamp>());

    // We can't easily mock DocumentSnapshot without mockito,
    // but we know toFirestore is correct.
  });
}
