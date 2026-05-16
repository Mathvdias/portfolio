import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:portifolio/core/services/firebase_analytics_service.dart';

class MockFirebaseAnalytics extends Mock implements FirebaseAnalytics {}

void main() {
  late MockFirebaseAnalytics mockAnalytics;
  late FirebaseAnalyticsService sut;

  setUp(() {
    mockAnalytics = MockFirebaseAnalytics();
    when(
      () => mockAnalytics.logEvent(
        name: any(named: 'name'),
        parameters: any(named: 'parameters'),
      ),
    ).thenAnswer((_) async {});
    sut = FirebaseAnalyticsService(mockAnalytics);
  });

  group('FirebaseAnalyticsService', () {
    test('logWindowOpen fires window_open with window_id', () async {
      await sut.logWindowOpen('skills');

      verify(
        () => mockAnalytics.logEvent(
          name: 'window_open',
          parameters: {'window_id': 'skills'},
        ),
      ).called(1);
    });

    test('logWindowClose fires window_close with window_id', () async {
      await sut.logWindowClose('terminal');

      verify(
        () => mockAnalytics.logEvent(
          name: 'window_close',
          parameters: {'window_id': 'terminal'},
        ),
      ).called(1);
    });

    test('logLinkClick fires link_click with destination and url', () async {
      await sut.logLinkClick('github', 'https://github.com/Mathvdias');

      verify(
        () => mockAnalytics.logEvent(
          name: 'link_click',
          parameters: {
            'destination': 'github',
            'url': 'https://github.com/Mathvdias',
          },
        ),
      ).called(1);
    });

    test(
      'logResumeDownload fires resume_download with no parameters',
      () async {
        await sut.logResumeDownload();

        verify(
          () => mockAnalytics.logEvent(
            name: 'resume_download',
            parameters: any(named: 'parameters'),
          ),
        ).called(1);
      },
    );

    test('logLocaleChange fires locale_change with locale', () async {
      await sut.logLocaleChange('pt');

      verify(
        () => mockAnalytics.logEvent(
          name: 'locale_change',
          parameters: {'locale': 'pt'},
        ),
      ).called(1);
    });

    test('logSpotlightOpen fires spotlight_open with no parameters', () async {
      await sut.logSpotlightOpen();

      verify(
        () => mockAnalytics.logEvent(
          name: 'spotlight_open',
          parameters: any(named: 'parameters'),
        ),
      ).called(1);
    });

    test('logSpotlightSelect fires spotlight_select with window_id', () async {
      await sut.logSpotlightSelect('about');

      verify(
        () => mockAnalytics.logEvent(
          name: 'spotlight_select',
          parameters: {'window_id': 'about'},
        ),
      ).called(1);
    });

    test(
      'logContextMenuOpen fires context_menu_open with no parameters',
      () async {
        await sut.logContextMenuOpen();

        verify(
          () => mockAnalytics.logEvent(
            name: 'context_menu_open',
            parameters: any(named: 'parameters'),
          ),
        ).called(1);
      },
    );

    test(
      'logContextMenuAction fires context_menu_action with action',
      () async {
        await sut.logContextMenuAction('openTerminal');

        verify(
          () => mockAnalytics.logEvent(
            name: 'context_menu_action',
            parameters: {'action': 'openTerminal'},
          ),
        ).called(1);
      },
    );

    test('logGuestbookPost fires guestbook_post with rating', () async {
      await sut.logGuestbookPost(5);

      verify(
        () => mockAnalytics.logEvent(
          name: 'guestbook_post',
          parameters: {'rating': 5},
        ),
      ).called(1);
    });

    test('logError fires app_error with capped fields', () async {
      await sut.logError('TypeError', 'Something went wrong');

      verify(
        () => mockAnalytics.logEvent(
          name: 'app_error',
          parameters: {
            'error_type': 'TypeError',
            'message': 'Something went wrong',
          },
        ),
      ).called(1);
    });

    test('logError includes stack_trace when provided', () async {
      await sut.logError(
        'RangeError',
        'Index out of bounds',
        stackTrace: '#0 main',
      );

      verify(
        () => mockAnalytics.logEvent(
          name: 'app_error',
          parameters: {
            'error_type': 'RangeError',
            'message': 'Index out of bounds',
            'stack_trace': '#0 main',
          },
        ),
      ).called(1);
    });

    test('logError caps error_type at 40 chars', () async {
      final long = 'A' * 50;
      await sut.logError(long, 'msg');

      verify(
        () => mockAnalytics.logEvent(
          name: 'app_error',
          parameters: {'error_type': 'A' * 40, 'message': 'msg'},
        ),
      ).called(1);
    });

    test('logJankFrame fires jank_frame with timing fields', () async {
      await sut.logJankFrame(totalMs: 45, buildMs: 20, rasterMs: 25);

      verify(
        () => mockAnalytics.logEvent(
          name: 'jank_frame',
          parameters: {'total_ms': 45, 'build_ms': 20, 'raster_ms': 25},
        ),
      ).called(1);
    });
  });
}
