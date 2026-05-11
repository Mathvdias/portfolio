import 'package:cloud_firestore/cloud_firestore.dart';

class GuestbookMessage {
  final String id;
  final String name;
  final String message;
  final int rating;
  final DateTime timestamp;

  const GuestbookMessage({
    required this.id,
    required this.name,
    required this.message,
    required this.rating,
    required this.timestamp,
  });

  factory GuestbookMessage.fromFirestore(
    String id,
    Map<String, dynamic>? data,
  ) {
    return GuestbookMessage(
      id: id,
      name: data?['name'] ?? 'Anonymous',
      message: data?['message'] ?? '',
      rating: data?['rating'] ?? 5,
      timestamp: (data?['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'message': message,
      'rating': rating,
      'timestamp': Timestamp.fromDate(timestamp),
    };
  }
}
