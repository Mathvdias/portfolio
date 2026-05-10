import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

class VisitorService {
  static final VisitorService _instance = VisitorService._internal();
  factory VisitorService() => _instance;
  VisitorService._internal();

  static const String _collection = 'stats';
  static const String _document = 'visitors';
  static const String _hasVisitedKey = 'has_visited';

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static bool _sessionRecorded = false;

  Future<void> recordVisit() async {
    if (_sessionRecorded) return;
    _sessionRecorded = true; // Set early to avoid parallel calls

    try {
      final prefs = await SharedPreferences.getInstance();
      final hasVisited = prefs.getBool(_hasVisitedKey) ?? false;

      if (!hasVisited) {
        await _firestore.collection(_collection).doc(_document).set({
          'count': FieldValue.increment(1),
        }, SetOptions(merge: true));
        await prefs.setBool(_hasVisitedKey, true);
      }
    } catch (e) {
      _sessionRecorded = false; // Reset on error to allow retry
      debugPrint('Error recording visit: $e');
    }
  }

  Stream<int> getVisitorCount() {
    return _firestore.collection(_collection).doc(_document).snapshots().map((
      doc,
    ) {
      if (doc.exists && doc.data() != null) {
        return (doc.data()!['count'] as num?)?.toInt() ?? 0;
      }
      return 0;
    });
  }
}
