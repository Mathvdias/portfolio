import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:portifolio/core/di/app_dependencies.dart';
import 'package:portifolio/core/services/analytics_service.dart';
import 'package:portifolio/core/services/sound_service.dart';
import 'package:portifolio/features/desktop/presentation/viewmodels/desktop_viewmodel.dart';
import 'package:portifolio/features/guestbook/presentation/viewmodels/guestbook_viewmodel.dart';
import 'package:portifolio/features/localization/presentation/viewmodels/locale_viewmodel.dart';
import 'package:portifolio/features/visitors/domain/repositories/visitor_repository.dart';

class _MockLocaleViewModel extends Mock implements LocaleViewModel {}

class _MockVisitorRepository extends Mock implements VisitorRepository {}

class _MockGuestbookViewModel extends Mock implements GuestbookViewModel {}

class _MockDesktopViewModel extends Mock implements DesktopViewModel {}

class _MockAnalyticsService extends Mock implements AnalyticsService {}

class _MockSoundService extends Mock implements SoundService {}

void main() {
  final localeViewModel = _MockLocaleViewModel();
  final visitorRepository = _MockVisitorRepository();
  final guestbookViewModel = _MockGuestbookViewModel();
  final desktopViewModel = _MockDesktopViewModel();
  final analyticsService = _MockAnalyticsService();

  AppDependencies dependencies({
    required Widget child,
    LocaleViewModel? locale,
    SoundService? soundService,
  }) {
    return AppDependencies(
      localeViewModel: locale ?? localeViewModel,
      visitorRepository: visitorRepository,
      guestbookViewModel: guestbookViewModel,
      desktopViewModel: desktopViewModel,
      analyticsService: analyticsService,
      soundService: soundService,
      child: child,
    );
  }

  group('AppDependencies.of', () {
    testWidgets('hands descendants every dependency that was injected', (
      tester,
    ) async {
      final soundService = _MockSoundService();
      late AppDependencies found;

      await tester.pumpWidget(
        dependencies(
          soundService: soundService,
          child: Builder(
            builder: (context) {
              found = AppDependencies.of(context);
              return const SizedBox();
            },
          ),
        ),
      );

      expect(found.localeViewModel, same(localeViewModel));
      expect(found.visitorRepository, same(visitorRepository));
      expect(found.guestbookViewModel, same(guestbookViewModel));
      expect(found.desktopViewModel, same(desktopViewModel));
      expect(found.analyticsService, same(analyticsService));
      expect(found.soundService, same(soundService));
    });

    testWidgets('asserts when there is no AppDependencies above the context', (
      tester,
    ) async {
      await tester.pumpWidget(const SizedBox());

      expect(
        () => AppDependencies.of(tester.element(find.byType(SizedBox))),
        throwsA(
          isA<AssertionError>().having(
            (e) => e.message,
            'message',
            'No AppDependencies found in context',
          ),
        ),
      );
    });
  });

  group('AppDependencies sound service', () {
    testWidgets('falls back to one app-wide SoundService when none is '
        'injected', (tester) async {
      late SoundService seenByDescendant;

      await tester.pumpWidget(
        dependencies(
          child: Builder(
            builder: (context) {
              seenByDescendant = AppDependencies.of(context).soundService;
              return const SizedBox();
            },
          ),
        ),
      );

      // A second tree built on its own would hand out the very same service.
      final other = dependencies(child: const SizedBox());
      expect(seenByDescendant, same(other.soundService));
    });

    test('an injected SoundService wins over the app-wide default', () {
      final injected = _MockSoundService();

      final withInjected = dependencies(
        soundService: injected,
        child: const SizedBox(),
      );
      final withDefault = dependencies(child: const SizedBox());

      expect(withInjected.soundService, same(injected));
      expect(withDefault.soundService, isNot(same(injected)));
    });
  });

  group('AppDependencies updates', () {
    testWidgets('replacing it never rebuilds dependents, but new lookups see '
        'the new instance', (tester) async {
      var builds = 0;
      // A single widget instance: it can only rebuild through an inherited
      // notification, never because its parent rebuilt.
      final dependent = Builder(
        builder: (context) {
          builds++;
          AppDependencies.of(context);
          return const SizedBox();
        },
      );
      final replacementLocale = _MockLocaleViewModel();

      await tester.pumpWidget(dependencies(child: dependent));
      expect(builds, 1);

      final replacement = dependencies(
        locale: replacementLocale,
        child: dependent,
      );
      await tester.pumpWidget(replacement);

      expect(builds, 1);
      expect(
        replacement.updateShouldNotify(dependencies(child: dependent)),
        isFalse,
      );
      expect(
        AppDependencies.of(tester.element(find.byType(Builder))),
        same(replacement),
      );
      expect(
        AppDependencies.of(
          tester.element(find.byType(Builder)),
        ).localeViewModel,
        same(replacementLocale),
      );
    });
  });
}
