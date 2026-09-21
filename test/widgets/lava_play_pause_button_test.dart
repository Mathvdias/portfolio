import 'dart:async';
import 'dart:ui' show PointerDeviceKind;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lava_flutter/lava_flutter.dart';
import 'package:portifolio/shared/widgets/lava_play_pause_button.dart';
import 'package:portifolio/theme/app_theme.dart';

// Not const on purpose: a const widget is canonicalised at compile time and
// its constructor would never show up in the coverage report.
// ignore_for_file: prefer_const_constructors

const _play = 'Play';
const _pause = 'Pause';

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
  required bool playing,
  VoidCallback? onPressed,
  double size = 84,
  bool reduceMotion = false,
  bool tooltips = true,
  bool second = false,
  AssetBundle? assetBundle,
}) {
  LavaPlayPauseButton button() => LavaPlayPauseButton(
    playing: playing,
    onPressed: onPressed ?? () {},
    size: size,
    playTooltip: tooltips ? _play : null,
    pauseTooltip: tooltips ? _pause : null,
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

final _button = find.byType(LavaPlayPauseButton);

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

Future<void> _playUntil(WidgetTester tester, int frame) async {
  for (var i = 0; i < 80 && _frame(tester) != frame; i++) {
    await tester.pump(_tick);
  }
  expect(_frame(tester), frame);
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
      if (box.decoration case final BoxDecoration d when d.border != null) d,
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

  test('the segments cover the 48 frames and mirror each other', () {
    expect(
      LavaPlayPauseButton.playingStart,
      LavaPlayPauseButton.toPauseEnd + 1,
    );
    expect(LavaPlayPauseButton.toPlayStart, LavaPlayPauseButton.playingEnd + 1);
    expect(LavaPlayPauseButton.lastFrame, LavaPlayPauseButton.frameCount - 1);
    // "to play" is "to pause" backwards: same length, mirrored ends.
    expect(
      LavaPlayPauseButton.lastFrame - LavaPlayPauseButton.toPauseEnd,
      LavaPlayPauseButton.toPlayStart,
    );
  });

  group('LavaPlayPauseButton fallback', () {
    testWidgets('a Material key stands in until the bundle is decoded', (
      tester,
    ) async {
      await tester.pumpWidget(_host(playing: true));
      await tester.pump(const Duration(milliseconds: 100));

      expect(_lavaKey, findsNothing);
      expect(find.byIcon(Icons.pause), findsOneWidget);
      final icon = tester.widget<Icon>(find.byIcon(Icons.pause));
      expect(icon.color, AppTheme.background);
      final disc = find.ancestor(
        of: find.byIcon(Icons.pause),
        matching: find.byType(Container),
      );
      final decoration = tester.widget<Container>(disc.first).decoration;
      expect((decoration! as BoxDecoration).color, AppTheme.peach);
      expect((decoration as BoxDecoration).shape, BoxShape.circle);
      // About two thirds of the painted width, like the key it stands in for.
      expect(tester.getSize(disc.first).width, closeTo(56, 1));

      await tester.pumpWidget(_host(playing: false));
      await tester.pump();
      expect(find.byIcon(Icons.play_arrow), findsOneWidget);
      expect(find.byIcon(Icons.pause), findsNothing);
    });

    testWidgets('a failed load is reported once and the fallback works', (
      tester,
    ) async {
      final reported = <FlutterErrorDetails>[];
      final previous = FlutterError.onError;
      FlutterError.onError = reported.add;
      addTearDown(() => FlutterError.onError = previous);

      var presses = 0;
      final missing = _MissingBundle();
      await tester.pumpWidget(
        _host(playing: true, assetBundle: missing, onPressed: () => presses++),
      );
      for (var i = 0; i < 5; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }
      FlutterError.onError = previous;

      expect(reported, hasLength(1));
      expect(reported.single.library, 'portifolio');
      expect(reported.single.context.toString(), contains('play / pause'));
      expect(reported.single.exception.toString(), contains('manifest.json'));

      expect(_lavaKey, findsNothing);
      expect(find.byIcon(Icons.pause), findsOneWidget);
      await tester.tap(_button);
      expect(presses, 1);
      await tester.pumpWidget(
        _host(playing: false, assetBundle: missing, onPressed: () => presses++),
      );
      await tester.pump();
      expect(find.byIcon(Icons.play_arrow), findsOneWidget);
      expect(find.byTooltip(_play), findsOneWidget);
    });

    testWidgets('an evicted bundle is not painted any more', (tester) async {
      await _pumpLoaded(tester, _host(playing: false));
      expect(find.byIcon(Icons.play_arrow), findsNothing);

      await tester.runAsync(() async {
        LavaBundle.evictOpenLavaCache();
        await Future<void>.delayed(const Duration(milliseconds: 25));
      });
      await tester.pumpWidget(_host(playing: false));
      await tester.pump();

      expect(_lavaKey, findsNothing);
      expect(find.byIcon(Icons.play_arrow), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('LavaPlayPauseButton playback', () {
    testWidgets('paused, it rests on the play glyph without ticking', (
      tester,
    ) async {
      await _pumpLoaded(tester, _host(playing: false));

      expect(find.byIcon(Icons.play_arrow), findsNothing);
      expect(_frame(tester), 0);
      expect(await _watch(tester, 10), [0]);
      expect(tester.binding.hasScheduledFrame, isFalse);
    });

    testWidgets('playing, it starts on the lit bars and breathes in a loop', (
      tester,
    ) async {
      await _pumpLoaded(tester, _host(playing: true));

      expect(find.byIcon(Icons.pause), findsNothing);
      expect(_frame(tester), LavaPlayPauseButton.playingStart);
      // 14..33, then round again: never the transitions.
      final shown = await _watch(tester, 30);
      expect(shown.take(23), [..._range(14, 33), 14, 15, 16]);
      expect(tester.binding.hasScheduledFrame, isTrue);
    });

    testWidgets('pressing play runs "to pause", then loops the playing part', (
      tester,
    ) async {
      await _pumpLoaded(tester, _host(playing: false));

      await tester.pumpWidget(_host(playing: true));
      expect(_frame(tester), 0);
      final shown = await _watch(tester, 45);
      expect(shown.take(37), [..._range(0, 33), 14, 15, 16]);
    });

    testWidgets('pressing pause runs "to play" once and stops ticking', (
      tester,
    ) async {
      await _pumpLoaded(tester, _host(playing: true));
      await _playUntil(tester, 20);

      await tester.pumpWidget(_host(playing: false));
      expect(_frame(tester), LavaPlayPauseButton.toPlayStart);
      expect(await _watch(tester, 25), _range(34, 47));

      // Frame 47 is the play glyph again; nothing is left running.
      expect(tester.binding.hasScheduledFrame, isFalse);
      expect(await _watch(tester, 30), [47]);

      // And the next press starts the way back from its first frame.
      await tester.pumpWidget(_host(playing: true));
      expect(_frame(tester), 0);
      expect((await _watch(tester, 8)).take(4), _range(0, 3));
    });

    testWidgets('pausing in the middle of "to pause" turns round in place', (
      tester,
    ) async {
      await _pumpLoaded(tester, _host(playing: false));
      await tester.pumpWidget(_host(playing: true));
      await _playUntil(tester, 5);

      await tester.pumpWidget(_host(playing: false));
      // Frame 42 is the picture of frame 5.
      expect(_frame(tester), 42);
      expect(await _watch(tester, 12), _range(42, 47));
      expect(tester.binding.hasScheduledFrame, isFalse);
    });

    testWidgets('playing in the middle of "to play" turns round in place', (
      tester,
    ) async {
      await _pumpLoaded(tester, _host(playing: true));
      await tester.pumpWidget(_host(playing: false));
      await _playUntil(tester, 38);

      await tester.pumpWidget(_host(playing: true));
      // Frame 9 is the picture of frame 38.
      expect(_frame(tester), 9);
      final shown = await _watch(tester, 32);
      expect(shown.take(28), [..._range(9, 33), 14, 15, 16]);
    });

    testWidgets('a rebuild that does not toggle leaves the key alone', (
      tester,
    ) async {
      await _pumpLoaded(tester, _host(playing: true));
      await _playUntil(tester, 25);

      await tester.pumpWidget(_host(playing: true, size: 90));
      expect(_frame(tester), 25);
      expect((await _watch(tester, 5)).take(3), _range(25, 27));
    });
  });

  group('LavaPlayPauseButton reduced motion', () {
    testWidgets('shows the two resting pictures and never animates', (
      tester,
    ) async {
      await _pumpLoaded(tester, _host(playing: true, reduceMotion: true));
      expect(_frame(tester), LavaPlayPauseButton.playingStart);
      expect(await _watch(tester, 10), [14]);
      expect(tester.binding.hasScheduledFrame, isFalse);

      await tester.pumpWidget(_host(playing: false, reduceMotion: true));
      expect(await _watch(tester, 10), [0]);
      expect(tester.binding.hasScheduledFrame, isFalse);

      await tester.pumpWidget(_host(playing: true, reduceMotion: true));
      expect(await _watch(tester, 10), [14]);
      expect(tester.binding.hasScheduledFrame, isFalse);
    });

    testWidgets('follows the setting when it changes while mounted', (
      tester,
    ) async {
      await _pumpLoaded(tester, _host(playing: true));
      await _playUntil(tester, 22);

      await tester.pumpWidget(_host(playing: true, reduceMotion: true));
      expect(await _watch(tester, 10), [14]);
      expect(tester.binding.hasScheduledFrame, isFalse);

      await tester.pumpWidget(_host(playing: true));
      expect((await _watch(tester, 8)).take(4), _range(14, 17));
    });

    testWidgets('hover and press do not scale the key', (tester) async {
      _useDesktopHighlights();
      await tester.pumpWidget(_host(playing: false, reduceMotion: true));
      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await mouse.addPointer(location: const Offset(700, 500));
      addTearDown(mouse.removePointer);
      await mouse.moveTo(tester.getCenter(_button));
      await tester.pump();
      expect(_scale(tester), 1.0);
      await mouse.down(tester.getCenter(_button));
      await tester.pump();
      expect(_scale(tester), 1.0);
      await mouse.up();
    });
  });

  group('LavaPlayPauseButton interaction', () {
    testWidgets('tap, Enter and Space all press it', (tester) async {
      var presses = 0;
      await tester.pumpWidget(
        _host(playing: false, onPressed: () => presses++),
      );

      await tester.tap(_button);
      expect(presses, 1);

      // Not focused yet: the keyboard does nothing, and there is no ring.
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      expect(presses, 1);
      expect(_ringColour(tester), Colors.transparent);

      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      expect(_ringColour(tester), AppTheme.teal);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      expect(presses, 2);
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      expect(presses, 3);
    });

    testWidgets('is a button labelled with the action it performs', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      var presses = 0;
      await tester.pumpWidget(
        _host(playing: false, onPressed: () => presses++),
      );

      bool isButton(SemanticsNode node) =>
          node.getSemanticsData().flagsCollection.isButton;
      final playButton = find.semantics.byPredicate(
        (node) => node.label == _play && isButton(node),
      );
      expect(playButton, findsOne);
      expect(find.semantics.byLabel(_pause), findsNothing);
      tester.semantics.tap(playButton);
      expect(presses, 1);

      await tester.pumpWidget(_host(playing: true));
      final pauseButton = find.semantics.byPredicate(
        (node) => node.label == _pause && isButton(node),
      );
      expect(pauseButton, findsOne);
      expect(find.semantics.byLabel(_play), findsNothing);
      // The fallback glyph is decoration: only the button is announced.
      expect(find.semantics.byLabel(RegExp('.+')), findsOne);
      handle.dispose();
    });

    testWidgets('the tooltip names the current action', (tester) async {
      await tester.pumpWidget(_host(playing: false));
      expect(find.byTooltip(_play), findsOneWidget);
      expect(find.byTooltip(_pause), findsNothing);
      await tester.longPress(_button);
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text(_play), findsOneWidget);

      await tester.pumpWidget(_host(playing: true));
      expect(find.byTooltip(_pause), findsOneWidget);
      expect(find.byTooltip(_play), findsNothing);
      // Let the tooltip's dismiss timer run out.
      await tester.pump(const Duration(seconds: 3));
    });

    testWidgets('works without tooltips', (tester) async {
      var presses = 0;
      await tester.pumpWidget(
        _host(playing: false, tooltips: false, onPressed: () => presses++),
      );
      expect(find.byType(Tooltip), findsNothing);
      await tester.tap(_button);
      expect(presses, 1);
    });

    testWidgets('a small key keeps a 48 px target', (tester) async {
      var presses = 0;
      await tester.pumpWidget(
        _host(playing: false, size: 30, onPressed: () => presses++),
      );

      final target = tester.getSize(_button);
      expect(target.width, greaterThanOrEqualTo(48));
      expect(target.height, greaterThanOrEqualTo(48));
      // Outside the 30 px art, inside the target.
      await tester.tapAt(tester.getCenter(_button) + const Offset(21, 21));
      expect(presses, 1);
    });

    testWidgets('size is the painted width on a 180:162 canvas', (
      tester,
    ) async {
      await _pumpLoaded(tester, _host(playing: false));
      expect(tester.getSize(_lavaKey).width, 84);
      expect(tester.getSize(_lavaKey).height, closeTo(84 * 162 / 180, 0.001));
      expect(tester.getSize(_button).width, 84);

      await tester.pumpWidget(_host(playing: false, size: 120));
      expect(tester.getSize(_lavaKey).width, 120);
      expect(tester.getSize(_lavaKey).height, closeTo(108, 0.001));
    });

    testWidgets('hover grows the key and pressing shrinks it', (tester) async {
      _useDesktopHighlights();
      await tester.pumpWidget(_host(playing: false));
      expect(_scale(tester), 1.0);

      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await mouse.addPointer(location: const Offset(700, 500));
      addTearDown(mouse.removePointer);
      await mouse.moveTo(tester.getCenter(_button));
      await tester.pump();
      expect(_scale(tester), greaterThan(1.0));
      final tracker = RendererBinding.instance.mouseTracker;
      final cursor = tracker.debugDeviceActiveCursor(1);
      expect(cursor, SystemMouseCursors.click);

      await mouse.down(tester.getCenter(_button));
      await tester.pump();
      expect(_scale(tester), lessThan(1.0));
      await mouse.up();
      await tester.pump();
      expect(_scale(tester), greaterThan(1.0));

      // A press that slides off the key is cancelled and lets go of it.
      await mouse.down(tester.getCenter(_button));
      await tester.pump();
      expect(_scale(tester), lessThan(1.0));
      await mouse.moveTo(const Offset(700, 500));
      await tester.pump();
      expect(_scale(tester), 1.0);
      await mouse.up();
      await tester.pump(const Duration(milliseconds: 200));
    });
  });

  group('LavaPlayPauseButton bundle lifetime', () {
    testWidgets('the shared bundle is kept while one key still shows it', (
      tester,
    ) async {
      // Reduced motion: frame 14 is composed once and nothing repaints, so
      // the composed-frame cache only changes when the keys let go.
      await _pumpLoaded(
        tester,
        _host(playing: true, reduceMotion: true, second: true),
      );
      expect(_lavaKey, findsNWidgets(2));
      final compositor = _painter(tester).compositor!;
      expect(compositor.cachedFrameCount, greaterThan(0));

      await tester.pumpWidget(_host(playing: true, reduceMotion: true));
      await tester.pump();
      expect(_lavaKey, findsOneWidget);
      expect(compositor.cachedFrameCount, greaterThan(0));

      await tester.pumpWidget(const SizedBox());
      await tester.pump();
      expect(compositor.cachedFrameCount, 0);
    });

    testWidgets('a load that finishes after dispose is left alone', (
      tester,
    ) async {
      late LavaBundle loaded;
      // On the real event loop from the start: a load (or a gate) created
      // under the fake clock would never finish.
      await tester.runAsync(() async {
        final gated = _GatedBundle();
        await tester.pumpWidget(_host(playing: true, assetBundle: gated));
        expect(find.byIcon(Icons.pause), findsOneWidget);
        await tester.pumpWidget(const SizedBox());

        gated.open.complete();
        loaded = await LavaBundle.openLavaAsset(
          assetPath: LavaPlayPauseButton.assetPath,
          bundle: gated,
        );
        await Future<void>.delayed(const Duration(milliseconds: 25));
      });
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(loaded.isDisposed, isFalse);
      expect(loaded.compositor!.cachedFrameCount, 0);
    });
  });
}
