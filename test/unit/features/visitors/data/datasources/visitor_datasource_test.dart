import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:portifolio/core/errors/app_failure.dart';
import 'package:portifolio/core/result/result.dart';
import 'package:portifolio/features/visitors/data/datasources/visitor_datasource.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('VisitorDatasource', () {
    late FakeFirebaseFirestore fakeFirestore;

    setUp(() {
      fakeFirestore = FakeFirebaseFirestore();
      SharedPreferences.setMockInitialValues({});
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
        final snap =
            await fakeFirestore.collection('stats').doc('visitors').get();
        expect(snap.exists, isFalse);
      });

      test(
        'uses kDebugMode when isDebug not provided (true in test env)',
        () async {
          final datasource = VisitorDatasource(firestore: fakeFirestore);

          final result = await datasource.recordVisit();

          expect(result, isA<Success<void>>());
          final snap =
              await fakeFirestore.collection('stats').doc('visitors').get();
          expect(snap.exists, isFalse);
        },
      );

      test('does not set session flag so release mode still records', () async {
        final debugDs = VisitorDatasource(
          firestore: fakeFirestore,
          isDebug: true,
        );
        await debugDs.recordVisit();

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
          expect(snap.exists, isFalse);
        },
      );

      test('watchCount emits 0 when document does not exist', () async {
        final datasource = VisitorDatasource(
          firestore: fakeFirestore,
          isDebug: false,
        );
        expect(await datasource.watchCount().first, 0);
      });

      test('watchCount emits count from Firestore document', () async {
        await fakeFirestore.collection('stats').doc('visitors').set({
          'count': 42,
        });
        final datasource = VisitorDatasource(
          firestore: fakeFirestore,
          isDebug: false,
        );
        expect(await datasource.watchCount().first, 42);
      });

      test(
        'returns Failure and resets session flag when write throws',
        () async {
          final datasource = VisitorDatasource(
            firestore: fakeFirestore,
            isDebug: false,
            writeOverride: () => throw Exception('Firestore unavailable'),
          );

          final result = await datasource.recordVisit();

          expect(result, isA<Failure<void>>());
          expect((result as Failure).failure, isA<CacheFailure>());
          expect(VisitorDatasource.sessionRecordedForTesting, isFalse);
        },
      );
    });
  });
}
