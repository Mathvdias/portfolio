import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:portifolio/core/errors/app_failure.dart';
import 'package:portifolio/core/result/result.dart';
import 'package:portifolio/features/visitors/data/datasources/visitor_datasource.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _MockFirebaseFirestore extends Mock implements FirebaseFirestore {}

class _MockCollectionReference extends Mock
    implements CollectionReference<Map<String, dynamic>> {}

class _MockDocumentReference extends Mock
    implements DocumentReference<Map<String, dynamic>> {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('VisitorDatasource', () {
    late FakeFirebaseFirestore fakeFirestore;

    setUp(() {
      fakeFirestore = FakeFirebaseFirestore();
      SharedPreferences.setMockInitialValues({});
      // Reset the static session flag between tests.
      VisitorDatasource.resetSessionForTesting();
    });

    group('debug mode guard', () {
      test('returns Success immediately without touching Firestore', () async {
        final datasource = VisitorDatasource(
          firestore: fakeFirestore,
          isDebug: true,
        );

        final result = await datasource.recordVisit();

        expect(result, isA<Success<void>>());
        // Firestore must be untouched.
        final snap =
            await fakeFirestore.collection('stats').doc('visitors').get();
        expect(snap.exists, isFalse);
      });

      test('does not set session flag so release mode still records', () async {
        final debugDs = VisitorDatasource(
          firestore: fakeFirestore,
          isDebug: true,
        );
        await debugDs.recordVisit();

        // A release-mode datasource created afterwards should still record.
        final releaseDs = VisitorDatasource(
          firestore: fakeFirestore,
          isDebug: false,
        );
        final result = await releaseDs.recordVisit();

        expect(result, isA<Success<void>>());
        final snap =
            await fakeFirestore.collection('stats').doc('visitors').get();
        expect(snap.exists, isTrue);
      });
    });

    group('release mode behaviour', () {
      test('records visit on first call', () async {
        final datasource = VisitorDatasource(
          firestore: fakeFirestore,
          isDebug: false,
        );

        final result = await datasource.recordVisit();

        expect(result, isA<Success<void>>());
        final snap =
            await fakeFirestore.collection('stats').doc('visitors').get();
        expect(snap.exists, isTrue);
        expect(snap.data()?['count'], isNotNull);
      });

      test('does not double-count within the same session', () async {
        final datasource = VisitorDatasource(
          firestore: fakeFirestore,
          isDebug: false,
        );

        await datasource.recordVisit();
        await datasource.recordVisit();

        // Session flag prevents second Firestore write — only one increment.
        final snap =
            await fakeFirestore.collection('stats').doc('visitors').get();
        expect(snap.exists, isTrue);
      });

      test(
        'does not re-count returning visitor (has_visited pref set)',
        () async {
          SharedPreferences.setMockInitialValues({'has_visited': true});
          final datasource = VisitorDatasource(
            firestore: fakeFirestore,
            isDebug: false,
          );

          final result = await datasource.recordVisit();

          expect(result, isA<Success<void>>());
          final snap =
              await fakeFirestore.collection('stats').doc('visitors').get();
          // Firestore document not created because user already visited.
          expect(snap.exists, isFalse);
        },
      );

      test('watchCount emits 0 when document does not exist', () async {
        final datasource = VisitorDatasource(
          firestore: fakeFirestore,
          isDebug: false,
        );

        final count = await datasource.watchCount().first;
        expect(count, 0);
      });

      test('watchCount emits count from Firestore document', () async {
        await fakeFirestore.collection('stats').doc('visitors').set({
          'count': 42,
        });

        final datasource = VisitorDatasource(
          firestore: fakeFirestore,
          isDebug: false,
        );

        final count = await datasource.watchCount().first;
        expect(count, 42);
      });

      test(
        'returns Failure and resets session flag when Firestore throws',
        () async {
          SharedPreferences.setMockInitialValues({});

          final mockFirestore = _MockFirebaseFirestore();
          final mockCollection = _MockCollectionReference();
          final mockDoc = _MockDocumentReference();

          when(
            () => mockFirestore.collection('stats'),
          ).thenReturn(mockCollection);
          when(() => mockCollection.doc('visitors')).thenReturn(mockDoc);
          when(
            () => mockDoc.set(any(), any()),
          ).thenThrow(Exception('Firestore unavailable'));

          final datasource = VisitorDatasource(
            firestore: mockFirestore,
            isDebug: false,
          );

          final result = await datasource.recordVisit();

          expect(result, isA<Failure<void>>());
          expect((result as Failure).failure, isA<CacheFailure>());
          // Session flag is reset so a retry is possible.
          expect(VisitorDatasource.sessionRecordedForTesting, isFalse);
        },
      );
    });
  });
}
