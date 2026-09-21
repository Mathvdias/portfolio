import 'dart:async';
import 'dart:convert';
import 'dart:ui' show PointerDeviceKind;

import 'package:flutter/gestures.dart' show kPressTimeout;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lava_flutter/lava_flutter.dart';
import 'package:portifolio/shared/widgets/lava_key.dart';
import 'package:portifolio/shared/widgets/lava_restart_button.dart';
import 'package:portifolio/theme/app_theme.dart';

// Not const on purpose: a const widget is canonicalised at compile time and
// its constructor would never show up in the coverage report.
// ignore_for_file: prefer_const_constructors

const _restart = 'Restart';

/// One frame of the key at 30 fps (rounded up so every pump advances one).
const _tick = Duration(microseconds: 33334);

/// A bundle whose files are never there.
class _MissingBundle extends CachingAssetBundle {
  @override
  Future<ByteData> load(String key) async => throw FlutterError('no $key');
}

/// The real assets, held back until [open] completes.
class _GatedBundle extends CachingAssetBundle {
  final Completer<void> open = Completer<void>();

  @override
  Future<ByteData> load(String key) async {
    await open.future;
    return rootBundle.load(key);
  }
}

Widget _host({
  VoidCallback? onPressed,
  double size = 70,
  bool reduceMotion = false,
  bool tooltip = true,
  bool second = false,
  AssetBundle? assetBundle,
}) {
  LavaRestartButton button() => LavaRestartButton(
    onPressed: onPressed ?? () {},
    size: size,
    tooltip: tooltip ? _restart : null,
    assetBundle: assetBundle,
  );

  return MaterialApp(
    home: Builder(
      builder: (context) {
        final data = MediaQuery.of(context);
        return MediaQuery(
          data: data.copyWith(disableAnimations: reduceMotion),
          child: Scaffold(
            body: Align(
              alignment: Alignment.topLeft,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [button(), if (second) button()],
              ),
            ),
          ),
        );
      },
    ),
  );
}

final _button = find.byType(LavaRestartButton);

/// The key as painted by the Lava engine (absent while the fallback shows).
final _lavaKey = find.descendant(
  of: _button,
  matching: find.byWidgetPredicate(
    (widget) => widget is CustomPaint && widget.painter is LavaPainter,
  ),
);

LavaPainter _painter(WidgetTester tester) =>
    tester.widget<CustomPaint>(_lavaKey.first).painter! as LavaPainter;

int _frame(WidgetTester tester) => _painter(tester).controller.currentFrame;

/// Pumps [widget] and waits, on the real event loop (image decoding never
/// completes under the fake clock), until the Lava key is on screen.
Future<void> _pumpLoaded(WidgetTester tester, Widget widget) async {
  await tester.runAsync(() async {
    await tester.pumpWidget(widget);
    for (var i = 0; i < 200 && _lavaKey.evaluate().isEmpty; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 25));
      await tester.pump();
    }
  });
  expect(_lavaKey, findsWidgets, reason: 'the bundle never finished decoding');
}

/// Lets playback run for [ticks] frames and returns the frames shown, without
/// the repeats of pumps that did not advance.
Future<List<int>> _watch(WidgetTester tester, int ticks) async {
  final shown = <int>[_frame(tester)];
  for (var i = 0; i < ticks; i++) {
    await tester.pump(_tick);
    if (_frame(tester) != shown.last) shown.add(_frame(tester));
  }
  return shown;
}

List<int> _range(int first, int last) => [
  for (var i = first; i <= last; i++) i,
];

double _scale(WidgetTester tester) {
  final scale = find.descendant(
    of: _button,
    matching: find.byType(AnimatedScale),
  );
  return tester.widget<AnimatedScale>(scale).scale;
}

/// Colour of the ring drawn round the key (transparent unless focused).
Color _ringColour(WidgetTester tester) {
  final boxes = find.descendant(
    of: _button,
    matching: find.byType(DecoratedBox),
  );
  final rings = <BoxDecoration>[
    for (final box in tester.widgetList<DecoratedBox>(boxes))
      if (box.decoration case final BoxDecoration d when d.border != null)
        if ((d.border! as Border).top.width == 2) d,
  ];
  return (rings.single.border! as Border).top.color;
}

/// flutter_test runs as a touch platform, where hover highlights never show;
/// the app is a desktop web page.
void _useDesktopHighlights() {
  final focus = FocusManager.instance;
  focus.highlightStrategy = FocusHighlightStrategy.alwaysTraditional;
  addTearDown(() => focus.highlightStrategy = FocusHighlightStrategy.automatic);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  // A tap that lands on nothing must fail the test, not just print a warning.
  WidgetController.hitTestWarningShouldBeFatal = true;

  // Loads started under a previous test's fake clock never finish and stay
  // cached: every test starts from clean caches.
  setUp(() {
    rootBundle.clear();
    LavaBundle.evictOpenLavaCache();
  });

  tearDown(() {
    rootBundle.clear();
    LavaBundle.evictOpenLavaCache();
  });

  test(
    'the bundle has the frames the key counts on, ending where it starts',
    () async {
      final manifest =
          jsonDecode(
                await rootBundle.loadString(
                  '${LavaRestartButton.assetPath}/manifest.json',
                ),
              )
              as Map<String, dynamic>;
      final frames = manifest['frames'] as List<dynamic>;

      expect(frames, hasLength(LavaRestartButton.frameCount));
      expect(manifest['fps'], LavaRestartButton.fps);
      // A run that completes must be back on the resting picture: the last
      // frame puts blocks of the key image back where they came from.
      final keyImage = (frames.first as Map<String, dynamic>)['imageIndex'];
      final last = frames.last as Map<String, dynamic>;
      expect(last['type'], 'diff');
      for (final blit in last['diffs'] as List<dynamic>) {
        final [image, source, _, _, destination] = blit as List<dynamic>;
        expect(image, keyImage);
        expect(destination, source);
      }
    },
  );

  group('LavaRestartButton before the key is decoded', () {
    testWidgets('shows the outlined replay stand-in, and it works', (
      tester,
    ) async {
      var presses = 0;
      await tester.pumpWidget(_host(onPressed: () => presses++));

      expect(_lavaKey, findsNothing);
      final icon = tester.widget<Icon>(find.byIcon(Icons.replay));
      expect(icon.color, AppTheme.subtext);

      await tester.tap(_button);
      await tester.pump();
      expect(presses, 1);
      // Nothing to turn yet: no frame is asked for.
      expect(tester.binding.hasScheduledFrame, isFalse);
    });

    testWidgets('keeps the stand-in and reports why when the bundle fails', (
      tester,
    ) async {
      final reported = <FlutterErrorDetails>[];
      final previous = FlutterError.onError;
      FlutterError.onError = reported.add;
      addTearDown(() => FlutterError.onError = previous);

      await tester.runAsync(() async {
        await tester.pumpWidget(_host(assetBundle: _MissingBundle()));
        for (var i = 0; i < 40 && reported.isEmpty; i++) {
          await Future<void>.delayed(const Duration(milliseconds: 10));
          await tester.pump();
        }
      });
      FlutterError.onError = previous;

      expect(reported, hasLength(1));
      expect(reported.single.context.toString(), contains('restart Lava key'));
      expect(find.byIcon(Icons.replay), findsOneWidget);
      expect(_lavaKey, findsNothing);
    });

    testWidgets('a bundle that arrives after the key left is not taken', (
      tester,
    ) async {
      // On the real event loop from the start: a gate created under the fake
      // clock would never open.
      await tester.runAsync(() async {
        final gate = _GatedBundle();
        await tester.pumpWidget(_host(assetBundle: gate));
        await tester.pumpWidget(const SizedBox());
        gate.open.complete();
        await Future<void>.delayed(const Duration(milliseconds: 300));
        await tester.pump();

        expect(tester.takeException(), isNull);
        // Never retained, so the cache still holds a live bundle for the
        // next key that asks.
        final bundle = await LavaBundle.openLavaAsset(
          assetPath: LavaRestartButton.assetPath,
          bundle: gate,
        );
        expect(bundle.isDisposed, isFalse);
      });
    });

    testWidgets('the stand-in keeps the footprint of the key', (tester) async {
      await tester.pumpWidget(_host());
      final before = tester.getSize(_button);

      await _pumpLoaded(tester, _host());

      expect(tester.getSize(_button), before);
    });
  });

  group('LavaRestartButton turning', () {
    testWidgets('rests on the first frame without ticking', (tester) async {
      await _pumpLoaded(tester, _host());

      expect(_frame(tester), 0);
      await tester.pump(const Duration(seconds: 1));
      expect(_frame(tester), 0);
      expect(tester.binding.hasScheduledFrame, isFalse);
    });

    testWidgets('a press asks the owner first, then makes one full turn', (
      tester,
    ) async {
      final log = <String>[];
      await _pumpLoaded(tester, _host(onPressed: () => log.add('pressed')));

      await tester.tap(_button);
      await tester.pump();
      expect(log, ['pressed']);

      final shown = await _watch(tester, 40);
      expect(shown, _range(0, LavaRestartButton.frameCount - 1));

      // Back at rest: the run is over and nothing asks for frames any more.
      await tester.pump(const Duration(seconds: 1));
      expect(_frame(tester), LavaRestartButton.frameCount - 1);
      expect(tester.binding.hasScheduledFrame, isFalse);
    });

    testWidgets('a press after a finished turn turns again from the start', (
      tester,
    ) async {
      await _pumpLoaded(tester, _host());
      await tester.tap(_button);
      await tester.pump();
      await _watch(tester, 40);

      await tester.tap(_button);
      await tester.pump();

      expect(await _watch(tester, 40), _range(0, 23));
    });

    testWidgets('a press in the middle of a turn starts the turn again', (
      tester,
    ) async {
      var presses = 0;
      await _pumpLoaded(tester, _host(onPressed: () => presses++));
      await tester.tap(_button);
      await tester.pump();
      for (var i = 0; i < 9; i++) {
        await tester.pump(_tick);
      }
      expect(_frame(tester), inInclusiveRange(7, 10));

      await tester.tap(_button);
      await tester.pump();

      expect(presses, 2);
      expect(_frame(tester), lessThan(2));
      expect((await _watch(tester, 40)).last, 23);
    });

    testWidgets('under reduced motion a press restarts without the turn', (
      tester,
    ) async {
      var presses = 0;
      await _pumpLoaded(
        tester,
        _host(onPressed: () => presses++, reduceMotion: true),
      );

      await tester.tap(_button);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(presses, 1);
      expect(_frame(tester), 0);
      expect(tester.binding.hasScheduledFrame, isFalse);
    });

    testWidgets('leaving in the middle of a turn is quiet', (tester) async {
      await _pumpLoaded(tester, _host());
      await tester.tap(_button);
      await tester.pump();
      await tester.pump(_tick);
      await tester.pump(_tick);

      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 1));

      expect(tester.takeException(), isNull);
      expect(tester.binding.hasScheduledFrame, isFalse);
    });
  });

  group('LavaRestartButton as a button', () {
    testWidgets('is one button that says what a press does', (tester) async {
      final semantics = tester.ensureSemantics();
      await tester.pumpWidget(_host());

      final node = find.semantics.byLabel(_restart);
      expect(node, findsOne);
      expect(
        node.evaluate().single.getSemanticsData().flagsCollection.isButton,
        isTrue,
      );
      semantics.dispose();
    });

    testWidgets('shows its name on a long press', (tester) async {
      await tester.pumpWidget(_host());

      await tester.longPress(_button);
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text(_restart), findsOneWidget);
    });

    testWidgets('has no tooltip and no label when none is given', (
      tester,
    ) async {
      await tester.pumpWidget(_host(tooltip: false));

      expect(find.byType(Tooltip), findsNothing);
      await tester.tap(_button);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Enter and Space press it once it has the focus', (
      tester,
    ) async {
      _useDesktopHighlights();
      var presses = 0;
      await tester.pumpWidget(_host(onPressed: () => presses++));
      expect(_ringColour(tester), Colors.transparent);

      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      expect(_ringColour(tester), AppTheme.teal);

      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      expect(presses, 2);
    });

    testWidgets('grows under the pointer and gives under a press', (
      tester,
    ) async {
      _useDesktopHighlights();
      await tester.pumpWidget(_host());
      expect(_scale(tester), 1.0);

      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await mouse.addPointer(location: const Offset(700, 500));
      addTearDown(mouse.removePointer);
      await mouse.moveTo(tester.getCenter(_button));
      await tester.pump();
      expect(_scale(tester), 1.06);

      await mouse.down(tester.getCenter(_button));
      await tester.pump();
      expect(_scale(tester), 0.94);

      await mouse.up();
      await tester.pump();
      expect(_scale(tester), 1.06);

      await mouse.moveTo(const Offset(700, 500));
      await tester.pump();
      expect(_scale(tester), 1.0);
    });

    testWidgets('a press that slides away is let go without a restart', (
      tester,
    ) async {
      var presses = 0;
      await tester.pumpWidget(_host(onPressed: () => presses++));

      final touch = await tester.startGesture(tester.getCenter(_button));
      // The tooltip's long press competes for a touch: the tap only shows
      // itself once the press timeout has run.
      await tester.pump(kPressTimeout);
      expect(_scale(tester), 0.94);
      await touch.moveBy(const Offset(0, 300));
      await touch.up();
      await tester.pump();

      expect(_scale(tester), 1.0);
      expect(presses, 0);
    });

    testWidgets('stays still under the pointer when motion is reduced', (
      tester,
    ) async {
      _useDesktopHighlights();
      await tester.pumpWidget(_host(reduceMotion: true));

      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await mouse.addPointer(location: const Offset(700, 500));
      addTearDown(mouse.removePointer);
      await mouse.moveTo(tester.getCenter(_button));
      await tester.pump();

      expect(_scale(tester), 1.0);
    });

    testWidgets('never offers a target under 48 px', (tester) async {
      await tester.pumpWidget(_host(size: 30));

      final target = tester.getSize(find.byType(LavaKey));
      expect(target.width, greaterThanOrEqualTo(LavaKey.minTapTarget));
      expect(target.height, greaterThanOrEqualTo(LavaKey.minTapTarget));
    });
  });

  group('LavaRestartButton and the shared bundle', () {
    testWidgets('gives the bundle back, but not while another key shows it', (
      tester,
    ) async {
      await _pumpLoaded(tester, _host(second: true));
      expect(_lavaKey, findsNWidgets(2));
      await tester.tap(_button.first);
      await tester.pump();
      await _watch(tester, 3);
      expect(_frame(tester), greaterThan(0));
      final composed = _painter(tester).compositor!;
      expect(composed.cachedFrameCount, greaterThan(0));

      // One key leaves: the other still paints from the same frames.
      await tester.pumpWidget(_host());
      await tester.pump();
      expect(composed.cachedFrameCount, greaterThan(0));

      // The last one leaves: the composed frames go back.
      await tester.pumpWidget(const SizedBox());
      await tester.pump();
      expect(composed.cachedFrameCount, 0);
    });

    testWidgets('falls back if its bundle is thrown away under it', (
      tester,
    ) async {
      await _pumpLoaded(tester, _host());

      LavaBundle.evictOpenLavaCache();
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 50)),
      );
      await tester.pumpWidget(_host(size: 71));

      expect(tester.takeException(), isNull);
      expect(_lavaKey, findsNothing);
      expect(find.byIcon(Icons.replay), findsOneWidget);
    });
  });
}
