import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/models/guestbook_message.dart';

class GuestbookRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<List<GuestbookMessage>> watchMessages() {
    return _firestore
        .collection('guestbook')
        .orderBy('timestamp', descending: true)
        .limit(100)
        .snapshots(includeMetadataChanges: true)
        .map((snapshot) => snapshot.docs
            .map((doc) => GuestbookMessage.fromFirestore(doc))
            .toList());
  }

  Future<void> addMessage(String name, String message, int rating) async {
    await _firestore.collection('guestbook').add({
      'name': name.trim(),
      'message': message.trim(),
      'rating': rating,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteMessage(String id) async {
    await _firestore.collection('guestbook').doc(id).delete();
  }
}
