import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/errors/app_failure.dart';
import '../../../../core/result/result.dart';

class VisitorDatasource {
  VisitorDatasource({FirebaseFirestore? firestore, bool? isDebug})
    : _firestore =
          firestore ?? FirebaseFirestore.instance, // coverage:ignore-line
      _isDebug = isDebug ?? kDebugMode;

  static const _collection = 'stats';
  static const _document = 'visitors';
  static const _hasVisitedKey = 'has_visited';

  final FirebaseFirestore _firestore;
  final bool _isDebug;

  @visibleForTesting
  static bool _sessionRecorded = false;

  /// Resets the in-process session flag. For use in tests only.
  @visibleForTesting
  static void resetSessionForTesting() => _sessionRecorded = false;

  /// Exposes session flag for assertion in tests.
  @visibleForTesting
  static bool get sessionRecordedForTesting => _sessionRecorded;

  Future<Result<void>> recordVisit() async {
    if (_isDebug) return const Success(null); // Don't count debug/test runs.
    if (_sessionRecorded) return const Success(null);
    _sessionRecorded = true;

    try {
      final prefs = await SharedPreferences.getInstance();
      final hasVisited = prefs.getBool(_hasVisitedKey) ?? false;

      if (!hasVisited) {
        await _firestore.collection(_collection).doc(_document).set({
          'count': FieldValue.increment(1),
        }, SetOptions(merge: true));
        await prefs.setBool(_hasVisitedKey, true);
      }
      return const Success(null);
    } catch (e) {
      _sessionRecorded = false;
      debugPrint('Error recording visit: $e');
      return Failure(CacheFailure('Failed to record visit: $e'));
    }
  }

  Stream<int> watchCount() {
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
