import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lava_flutter/lava_flutter.dart';
import 'package:portifolio/l10n/app_localizations.dart';
import 'package:portifolio/shared/constants/app_strings.dart';
import 'package:portifolio/shared/constants/lava_format_stats.dart';
import 'package:portifolio/shared/widgets/lava_studio_content.dart';
import 'package:portifolio/theme/app_theme.dart';

/// Asset keys answered by the test instead of the files on disk.
final Map<String, Uint8List> _assetOverrides = {};

/// Same lookup as flutter_test's own `flutter/assets` mock, with
/// [_assetOverrides] consulted first.
void _installAssetHandler(TestWidgetsFlutterBinding binding) {
  final root = Platform.environment['UNIT_TEST_ASSETS']!;
  binding.defaultBinaryMessenger.setMockMessageHandler('flutter/assets', (
    ByteData? message,
  ) {
    final key = Uri.decodeFull(utf8.decode(message!.buffer.asUint8List()));
    final bytes = _assetOverrides[key] ?? _diskAsset(root, key);
    return SynchronousFuture<ByteData?>(
      bytes == null ? null : Uint8List.fromList(bytes).buffer.asByteData(),
    );
  });
}

Uint8List? _diskAsset(String root, String key) {
  final file = File('$root/$key');
  return file.existsSync() ? file.readAsBytesSync() : null;
}

Uint8List _realAsset(String key) =>
    _diskAsset(Platform.environment['UNIT_TEST_ASSETS']!, key)!;

/// A three-frame Macintosh bundle whose recipe is known by heart:
/// 180x162 on 32 px cells is a 6x6 grid (36 tiles).
///  * frame 1 - key frame: the whole key image in one copy;
///  * frame 2 - 2x1 tiles from the key image + 1 tile from the atlas;
///  * frame 3 - one 2x2 block from the atlas.
/// Images are declared as AVIF without a fallback when [avif] is set (the
/// bytes are the real WebP files: the decoder sniffs content, not names).
void _serveKnownMacintosh({String directory = 'macintosh', bool avif = false}) {
  final path = 'assets/lava/$directory';
  final real =
      jsonDecode(utf8.decode(_realAsset('$path/manifest.json')))
          as Map<String, dynamic>;
  _assetOverrides['$path/manifest.json'] = utf8.encode(
    jsonEncode({
      ...real,
      'images': [
        if (avif) ...[
          {'url': 'image_1.avif'},
          {'url': 'image_2.avif'},
        ] else ...[
          {'url': 'image_1.avif', 'fallbackUrl': 'image_1.webp'},
          {'url': 'image_2.avif', 'fallbackUrl': 'image_2.webp'},
        ],
      ],
      'frames': [
        {'type': 'key', 'imageIndex': 0},
        {
          'type': 'diff',
          'diffs': [
            [0, 0, 2, 1, 0],
            [1, 3, 1, 1, 7],
          ],
        },
        {
          'type': 'diff',
          'diffs': [
            [1, 5, 2, 2, 14],
          ],
        },
      ],
    }),
  );
  if (avif) {
    for (final image in ['image_1', 'image_2']) {
      _assetOverrides['$path/$image.avif'] = _realAsset('$path/$image.webp');
    }
  }
}

const _allModels = [
  AppStrings.lavaModelMacintosh,
  AppStrings.lavaModelTree,
  AppStrings.lavaModelLavaLamp,
  AppStrings.lavaModelCampfire,
  AppStrings.lavaModelRocket,
  AppStrings.lavaModelSenna,
  AppStrings.lavaModelChristmasTree,
  AppStrings.lavaModelF1Car,
  AppStrings.lavaModelF1Front,
  AppStrings.lavaModelSennaMp4,
];

// Not const on purpose: a const widget is canonicalised at compile time and
// its constructor would never show up in the coverage report.
// ignore_for_file: prefer_const_constructors
Widget _studio() => MaterialApp(
  localizationsDelegates: [AppLocalizationsDelegate()],
  home: Scaffold(body: LavaStudioContent()),
);

/// 800x600 at 1x keeps the stage under the large-preview threshold, 3x (the
/// flutter_test default) goes over it.
void _setView(
  WidgetTester tester, {
  Size size = const Size(800, 600),
  double pixelRatio = 1.0,
}) {
  tester.view.physicalSize = size * pixelRatio;
  tester.view.devicePixelRatio = pixelRatio;
  addTearDown(tester.view.reset);
}

final _paintedIcons = find.descendant(
  of: find.byType(LavaIcon),
  matching: find.byType(CustomPaint),
);

/// Pumps the studio and waits, on the real event loop (image decoding never
/// completes under the fake clock), until [ready] holds.
Future<void> _pumpDecodedStudio(
  WidgetTester tester, {
  bool Function()? ready,
}) async {
  // Loads started under a previous test's fake clock never finish and stay
  // cached: start from clean caches.
  rootBundle.clear();
  LavaBundle.evictOpenLavaCache();
  final isReady =
      ready ??
      () =>
          _paintedIcons.evaluate().length == 11 &&
          find.text(AppStrings.lavaStudioRuntime).evaluate().isNotEmpty;
  await tester.runAsync(() async {
    await tester.pumpWidget(_studio());
    for (var i = 0; i < 200 && !isReady(); i++) {
      await Future<void>.delayed(const Duration(milliseconds: 25));
      await tester.pump();
    }
  });
  expect(isReady(), isTrue, reason: 'the bundles never finished decoding');
}

Future<void> _pause(WidgetTester tester) async {
  await tester.ensureVisible(find.byIcon(Icons.pause));
  await tester.tap(find.byIcon(Icons.pause));
  await tester.pump();
}

/// Moves the playhead with the timeline slider (0 = first frame, 1 = last).
Future<void> _scrubTo(WidgetTester tester, double fraction) async {
  final slider = find.byType(Slider);
  await tester.ensureVisible(slider);
  final box = tester.getRect(slider);
  // The track is inset by the thumb overlay on both sides.
  final x = box.left + 24 + (box.width - 48) * fraction;
  await tester.tapAt(Offset(x, box.center.dy));
  await tester.pump();
}

typedef _PaintCall = ({Symbol method, List<dynamic> arguments});

/// Everything [finder]'s render object draws, in order.
List<_PaintCall> _paintCalls(Finder finder) {
  final calls = <_PaintCall>[];
  expect(
    finder,
    paints..everything((Symbol method, List<dynamic> arguments) {
      calls.add((method: method, arguments: arguments));
      return true;
    }),
  );
  return calls;
}

Finder _customPaintWith(String painterType) => find.byWidgetPredicate(
  (widget) =>
      widget is CustomPaint &&
      (widget.painter.runtimeType.toString() == painterType ||
          widget.foregroundPainter.runtimeType.toString() == painterType),
);

/// Sizes are shown in KB up to a mebibyte, then in MB with two decimals.
String _size(int bytes) =>
    bytes >= 1024 * 1024
        ? '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB'
        : '${(bytes / 1024).round()} KB';

/// 1-based frame shown by the transport ("FRAME 7 / 24").
int _frameOnTransport(WidgetTester tester) {
  final text = tester.widget<Text>(
    find.textContaining(RegExp('^${AppStrings.lavaStudioFrame} \\d+ / \\d+\$')),
  );
  return int.parse(text.data!.split(' ')[1]);
}

void main() {
  final binding = TestWidgetsFlutterBinding.ensureInitialized();
  // A tap that lands on nothing must fail the test, not just print a warning.
  WidgetController.hitTestWarningShouldBeFatal = true;
  final macStats = LavaFormatStats.byIcon[LavaDemoType.macintosh]!;

  setUp(() {
    _assetOverrides.clear();
    _installAssetHandler(binding);
  });

  tearDown(() {
    _assetOverrides.clear();
    rootBundle.clear();
    LavaBundle.evictOpenLavaCache();
  });

  group('LavaStudioContent live inspector', () {
    testWidgets('shows placeholders until a bundle is on stage', (
      tester,
    ) async {
      _setView(tester);
      await tester.pumpWidget(_studio());
      await tester.pump(const Duration(milliseconds: 100));

      // Recipe, atlas and runtime cards wait for the bundle; the size
      // comparison only needs the selected model.
      expect(find.text(AppStrings.lavaStudioLoading), findsNWidgets(3));
      expect(find.text(AppStrings.lavaStudioRecipe), findsNothing);
      expect(find.text(AppStrings.lavaStudioAtlas), findsNothing);
      expect(find.text(AppStrings.lavaStudioRuntime), findsNothing);
      expect(find.text(AppStrings.lavaStudioFaceOff), findsOneWidget);
    });

    testWidgets(
      'goes back to placeholders if the bundle on stage is disposed',
      (tester) async {
        _setView(tester);
        _serveKnownMacintosh();
        await _pumpDecodedStudio(tester);
        await _pause(tester);
        expect(find.text(AppStrings.lavaStudioRecipe), findsOneWidget);

        // What happens to a large preview once its last icon lets go of it.
        final stageIcon = tester
            .widgetList<LavaIcon>(find.byType(LavaIcon))
            .singleWhere((icon) => icon.onBundleChanged != null);
        stageIcon.onBundleChanged!(
          LavaBundle(
            manifest: const LavaManifest(
              tileWidth: 32,
              tileHeight: 32,
              columns: 1,
              rows: 1,
              totalFrames: 1,
            ),
          )..dispose(),
        );
        await tester.pump();

        expect(tester.takeException(), isNull);
        expect(find.text(AppStrings.lavaStudioLoading), findsNWidgets(3));
        expect(find.text(AppStrings.lavaStudioRecipe), findsNothing);
      },
    );

    testWidgets('reads the recipe of the frame on stage', (tester) async {
      _setView(tester);
      _serveKnownMacintosh();
      await _pumpDecodedStudio(tester);
      await _pause(tester);
      expect(find.text(AppStrings.lavaStudioLoading), findsNothing);

      Iterable<Color> recipeBar() => tester
          .widgetList<ColoredBox>(
            find.descendant(
              of: find.byType(ClipRRect),
              matching: find.byType(ColoredBox),
            ),
          )
          .map((box) => box.color);

      await _scrubTo(tester, 0);
      expect(find.text('FRAME 1 / 3'), findsOneWidget);
      expect(find.text('1 copy → 1 draw call'), findsOneWidget);
      expect(find.text('36 from key frame'), findsOneWidget);
      expect(find.text('0 from atlas'), findsOneWidget);
      expect(find.text('0 transparent (free)'), findsOneWidget);
      expect(recipeBar(), [AppTheme.blue]);

      await _scrubTo(tester, 0.5);
      expect(find.text('FRAME 2 / 3'), findsOneWidget);
      expect(find.text('2 copies → 2 draw calls'), findsOneWidget);
      expect(find.text('2 from key frame'), findsOneWidget);
      expect(find.text('1 from atlas'), findsOneWidget);
      expect(find.text('33 transparent (free)'), findsOneWidget);
      expect(recipeBar(), [AppTheme.blue, AppTheme.peach, AppTheme.surface0]);

      await _scrubTo(tester, 1);
      expect(find.text('FRAME 3 / 3'), findsOneWidget);
      expect(find.text('1 copy → 1 draw call'), findsOneWidget);
      expect(find.text('0 from key frame'), findsOneWidget);
      expect(find.text('4 from atlas'), findsOneWidget);
      expect(find.text('32 transparent (free)'), findsOneWidget);
      expect(recipeBar(), [AppTheme.peach, AppTheme.surface0]);
    });

    testWidgets('X-ray tints the blocks of the frame by their source', (
      tester,
    ) async {
      _setView(tester);
      _serveKnownMacintosh();
      await _pumpDecodedStudio(tester);
      await _pause(tester);

      final xray = _customPaintWith('_XrayPainter');
      expect(xray, findsNothing);
      await tester.ensureVisible(find.text(AppStrings.lavaStudioXray));
      await tester.tap(find.text(AppStrings.lavaStudioXray));
      await tester.pump(const Duration(milliseconds: 250));
      expect(xray, findsOneWidget);

      // The 216 px stage letterboxes the 180x162 frame: 1.2x, 10.8 px bands.
      const scale = 216 / 180;
      List<_PaintCall> rects() =>
          _paintCalls(xray).where((c) => c.method == #drawRect).toList();

      // Key frame: one block, the whole image, in the key colour.
      await _scrubTo(tester, 0);
      final calls = _paintCalls(xray);
      final translate = calls.firstWhere((c) => c.method == #translate);
      expect(translate.arguments[0], 0.0);
      expect(translate.arguments[1], moreOrLessEquals(10.8, epsilon: 1e-6));
      var blocks = rects();
      expect(blocks, hasLength(2));
      expect(
        blocks[0].arguments[0] as Rect,
        rectMoreOrLessEquals(
          const Rect.fromLTWH(0, 0, 216, 162 * scale),
          epsilon: 1e-6,
        ),
      );
      final fill = blocks[0].arguments[1] as Paint;
      expect(fill.style, PaintingStyle.fill);
      expect(fill.color, isSameColorAs(AppTheme.blue.withValues(alpha: 0.16)));
      final stroke = blocks[1].arguments[1] as Paint;
      expect(stroke.style, PaintingStyle.stroke);
      expect(stroke.color, isSameColorAs(AppTheme.blue));
      // 32 px cells over the frame: 6 columns and 6 rows of grid lines.
      expect(calls.where((c) => c.method == #drawLine), hasLength(12));

      // Frame 2 copies two blocks: fill + outline for each.
      await _scrubTo(tester, 0.5);
      blocks = rects();
      expect(blocks, hasLength(4));
      expect(
        blocks[0].arguments[0] as Rect,
        rectMoreOrLessEquals(
          const Rect.fromLTRB(0, 0, 64 * scale, 32 * scale),
          epsilon: 1e-6,
        ),
      );
      expect(
        blocks[2].arguments[0] as Rect,
        rectMoreOrLessEquals(
          const Rect.fromLTRB(32 * scale, 32 * scale, 64 * scale, 64 * scale),
          epsilon: 1e-6,
        ),
      );

      // Frame 3 is a single atlas block: the atlas colour, more opaque.
      await _scrubTo(tester, 1);
      blocks = rects();
      expect(blocks, hasLength(2));
      expect(
        blocks[0].arguments[0] as Rect,
        rectMoreOrLessEquals(
          const Rect.fromLTRB(64 * scale, 64 * scale, 128 * scale, 128 * scale),
          epsilon: 1e-6,
        ),
      );
      expect(
        (blocks[0].arguments[1] as Paint).color,
        isSameColorAs(AppTheme.peach.withValues(alpha: 0.30)),
      );
      expect(
        (blocks[1].arguments[1] as Paint).color,
        isSameColorAs(AppTheme.peach),
      );
    });

    testWidgets('X-ray overlay only repaints for another bundle', (
      tester,
    ) async {
      _setView(tester);
      await _pumpDecodedStudio(tester);
      await _pause(tester);
      await tester.ensureVisible(find.text(AppStrings.lavaStudioXray));
      await tester.tap(find.text(AppStrings.lavaStudioXray));
      await tester.pump(const Duration(milliseconds: 250));

      CustomPainter overlay() =>
          tester
              .widget<CustomPaint>(_customPaintWith('_XrayPainter'))
              .foregroundPainter!;

      // A rebuild of the studio (speed change) keeps bundle and controller.
      final first = overlay();
      await tester.ensureVisible(find.text('2.0x'));
      await tester.tap(find.text('2.0x'));
      await tester.pump();
      final rebuilt = overlay();
      expect(rebuilt, isNot(same(first)));
      expect(rebuilt.shouldRepaint(first), isFalse);

      // Another model puts another bundle on stage.
      await tester.ensureVisible(find.text(AppStrings.lavaModelTree));
      await tester.tap(find.text(AppStrings.lavaModelTree));
      await tester.runAsync(() async {
        for (var i = 0; i < 200; i++) {
          await Future<void>.delayed(const Duration(milliseconds: 25));
          await tester.pump();
          if (overlay().shouldRepaint(rebuilt)) break;
        }
      });
      expect(overlay().shouldRepaint(rebuilt), isTrue);
    });

    testWidgets('atlas card outlines the blocks the frame reads', (
      tester,
    ) async {
      _setView(tester);
      _serveKnownMacintosh();
      await _pumpDecodedStudio(tester);
      await _pause(tester);

      final sources = _customPaintWith('_SourcePainter');
      expect(sources, findsNWidgets(2));
      expect(find.text(AppStrings.lavaStudioKeyFrame), findsOneWidget);
      expect(find.textContaining(RegExp(r'^2048×\d+ px$')), findsOneWidget);

      List<_PaintCall> draws(int index, Symbol method) =>
          _paintCalls(
            sources.at(index),
          ).where((c) => c.method == method).toList();

      // Frame 2: a 2x1 block of the key image and tile 3 of the atlas.
      await _scrubTo(tester, 0.5);
      final keyImages = draws(0, #drawImageRect);
      // The whole image dimmed, then the block at full strength.
      expect(keyImages, hasLength(2));
      expect(keyImages[0].arguments[1], const Rect.fromLTWH(0, 0, 180, 162));
      expect(keyImages[1].arguments[1], const Rect.fromLTRB(0, 0, 64, 32));
      final keyBox = tester.getSize(sources.at(0));
      expect(keyBox.width / keyBox.height, moreOrLessEquals(180 / 162));
      final keyScale = keyBox.width / 180;
      final keyOutline = draws(0, #drawRect).single;
      expect(
        keyOutline.arguments[0] as Rect,
        rectMoreOrLessEquals(
          Rect.fromLTRB(0, 0, 64 * keyScale, 32 * keyScale),
          epsilon: 1e-6,
        ),
      );
      expect(
        (keyOutline.arguments[1] as Paint).color,
        isSameColorAs(AppTheme.blue),
      );

      final atlasImages = draws(1, #drawImageRect);
      expect(atlasImages, hasLength(2));
      expect(atlasImages[1].arguments[1], const Rect.fromLTRB(96, 0, 128, 32));
      final atlasOutline = draws(1, #drawRect).single;
      expect(
        (atlasOutline.arguments[1] as Paint).color,
        isSameColorAs(AppTheme.peach),
      );

      // Frame 3 reads nothing from the key image, a 2x2 block from the atlas.
      await _scrubTo(tester, 1);
      expect(draws(0, #drawImageRect), hasLength(1));
      expect(draws(0, #drawRect), isEmpty);
      expect(
        draws(1, #drawImageRect)[1].arguments[1],
        const Rect.fromLTRB(160, 0, 224, 64),
      );

      // Key frame and atlas views differ; a rebuild of the same view does not.
      CustomPainter painter(int index) =>
          tester.widget<CustomPaint>(sources.at(index)).painter!;
      final keyPainter = painter(0);
      expect(painter(1).shouldRepaint(keyPainter), isTrue);
      await tester.ensureVisible(find.text('0.5x'));
      await tester.tap(find.text('0.5x'));
      await tester.pump();
      expect(painter(0), isNot(same(keyPainter)));
      expect(painter(0).shouldRepaint(keyPainter), isFalse);
    });

    testWidgets('runtime card reports the standard WebP fallback', (
      tester,
    ) async {
      _setView(tester);
      _serveKnownMacintosh();
      await _pumpDecodedStudio(tester);
      await _pause(tester);

      expect(find.text('WEBP fallback'), findsOneWidget);
      expect(find.text(AppStrings.lavaStudioVariantStd), findsOneWidget);
      expect(find.text(AppStrings.lavaStudioDownload), findsOneWidget);
      expect(find.text(_size(macStats.lavaWebp)), findsOneWidget);
      // RGBA texture of the 2048 px wide atlas.
      expect(
        find.textContaining(RegExp(r'^2048×\d+ · \d+\.\d MB$')),
        findsOneWidget,
      );

      // Both diff frames get composed once and stay cached.
      await _scrubTo(tester, 0);
      expect(find.text('0 / 2'), findsOneWidget);
      await _scrubTo(tester, 0.5);
      await _scrubTo(tester, 1);
      await _scrubTo(tester, 0);
      expect(find.text('2 / 2'), findsOneWidget);
    });

    testWidgets('runtime card reports the large preview on dense screens', (
      tester,
    ) async {
      _setView(tester, pixelRatio: 3.0);
      await _pumpDecodedStudio(
        tester,
        ready:
            () =>
                find.text(AppStrings.lavaStudioVariantHd).evaluate().isNotEmpty,
      );

      expect(find.text(AppStrings.lavaStudioVariantStd), findsNothing);
      expect(find.text('WEBP fallback'), findsOneWidget);
      // The large WebP fallback was never measured: no size is claimed.
      expect(find.text(AppStrings.lavaStudioDownload), findsNothing);
    });

    testWidgets('runtime card reports AVIF and its measured download', (
      tester,
    ) async {
      _setView(tester);
      _serveKnownMacintosh(avif: true);
      await _pumpDecodedStudio(tester);

      expect(find.text('AVIF 4:4:4'), findsOneWidget);
      expect(find.textContaining('fallback'), findsNothing);
      expect(find.text(AppStrings.lavaStudioVariantStd), findsOneWidget);
      expect(find.text(_size(macStats.lavaAvif)), findsNWidgets(2));
    });

    testWidgets('runtime card reports the large AVIF download', (tester) async {
      _setView(tester, pixelRatio: 3.0);
      _serveKnownMacintosh(avif: true);
      _serveKnownMacintosh(directory: 'macintosh_hd', avif: true);
      await _pumpDecodedStudio(
        tester,
        ready:
            () =>
                find.text(AppStrings.lavaStudioVariantHd).evaluate().isNotEmpty,
      );

      expect(find.text('AVIF 4:4:4'), findsOneWidget);
      expect(find.text(_size(macStats.lavaHdAvif)), findsOneWidget);
    });

    testWidgets('size comparison ranks the containers of the selected model', (
      tester,
    ) async {
      _setView(tester);
      await tester.pumpWidget(_studio());
      await tester.pump();

      List<String> ranking() {
        final names = [
          AppStrings.lavaStudioFormatPng,
          AppStrings.lavaStudioFormatApng,
          AppStrings.lavaStudioFormatGif,
          AppStrings.lavaStudioFormatWebp,
          AppStrings.lavaStudioFormatLava,
        ];
        names.sort(
          (a, b) => tester
              .getTopLeft(find.text(a))
              .dy
              .compareTo(tester.getTopLeft(find.text(b)).dy),
        );
        return names;
      }

      // Macintosh: the GIF is larger than the animated WebP.
      expect(ranking(), [
        AppStrings.lavaStudioFormatPng,
        AppStrings.lavaStudioFormatApng,
        AppStrings.lavaStudioFormatGif,
        AppStrings.lavaStudioFormatWebp,
        AppStrings.lavaStudioFormatLava,
      ]);
      expect(find.text(_size(macStats.pngSequence)), findsOneWidget);
      expect(find.text(_size(macStats.lavaAvif)), findsOneWidget);
      final bars =
          tester
              .widgetList<FractionallySizedBox>(
                find.byType(FractionallySizedBox),
              )
              .map((bar) => bar.widthFactor!)
              .toList();
      expect(bars.first, 1.0);
      expect(
        bars.last,
        moreOrLessEquals(macStats.lavaAvif / macStats.pngSequence),
      );
      final lavaLabel = tester.widget<Text>(
        find.text(AppStrings.lavaStudioFormatLava),
      );
      expect(lavaLabel.style!.color, AppTheme.peach);
      expect(lavaLabel.style!.fontWeight, FontWeight.bold);

      // Sunflower: the other way round.
      await tester.tap(find.text(AppStrings.lavaModelTree));
      await tester.pump();
      expect(ranking(), [
        AppStrings.lavaStudioFormatPng,
        AppStrings.lavaStudioFormatApng,
        AppStrings.lavaStudioFormatWebp,
        AppStrings.lavaStudioFormatGif,
        AppStrings.lavaStudioFormatLava,
      ]);

      // Campfire's PNG sequence is over a megabyte.
      final campfire = LavaFormatStats.byIcon[LavaDemoType.campfire]!;
      expect(campfire.pngSequence, greaterThan(1024 * 1024));
      await tester.tap(find.text(AppStrings.lavaModelCampfire));
      await tester.pump();
      final megabytes = _size(campfire.pngSequence);
      expect(megabytes, endsWith(' MB'));
      expect(find.text(megabytes), findsOneWidget);
    });
  });

  group('LavaStudioContent stage', () {
    testWidgets('category tabs put the picked model on stage', (tester) async {
      _setView(tester);
      await tester.pumpWidget(_studio());
      await tester.pump();

      expect(find.byType(LavaIcon), findsNWidgets(11));
      expect(find.text(AppStrings.lavaModelMacintoshDesc), findsOneWidget);
      LavaIcon stage() => tester.widget<LavaIcon>(find.byType(LavaIcon).last);
      Text tabLabel(String name) => tester.widget<Text>(find.text(name).first);
      expect(stage().demoType, LavaDemoType.macintosh);
      expect(stage().interactive, isTrue);

      for (final (index, name) in _allModels.indexed) {
        await tester.tap(find.text(name).first);
        await tester.pump();
        expect(stage().demoType, LavaDemoType.values[index]);
        // Tab label + stage title.
        expect(find.text(name), findsNWidgets(2));
        expect(tabLabel(name).style!.color, AppTheme.peach);
        expect(tabLabel(name).style!.fontWeight, FontWeight.bold);
        // Only the picked tab plays its icon.
        final playing = [
          for (final icon in tester.widgetList<LavaIcon>(find.byType(LavaIcon)))
            if (icon.autoPlay == true) icon.demoType,
        ];
        expect(playing, [LavaDemoType.values[index]]);
      }
      expect(find.text(AppStrings.lavaModelSennaMp4Desc), findsOneWidget);
      expect(find.text(AppStrings.lavaModelMacintoshDesc), findsNothing);
      expect(
        tabLabel(AppStrings.lavaModelMacintosh).style!.color,
        AppTheme.subtext,
      );
    });

    testWidgets('picking a model rewinds, picking the current one does not', (
      tester,
    ) async {
      _setView(tester);
      await tester.pumpWidget(_studio());
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 100));
      await _pause(tester);
      final frame = _frameOnTransport(tester);
      expect(frame, greaterThan(1));

      final current = find.text(AppStrings.lavaModelMacintosh).first;
      await tester.ensureVisible(current);
      await tester.tap(current);
      await tester.pump();
      expect(_frameOnTransport(tester), frame);

      await tester.tap(find.text(AppStrings.lavaModelRocket));
      await tester.pump();
      expect(_frameOnTransport(tester), 1);
      expect(find.text(AppStrings.lavaModelRocketDesc), findsOneWidget);
    });

    testWidgets('hovering a tab lights it up and plays its icon', (
      tester,
    ) async {
      _setView(tester);
      await tester.pumpWidget(_studio());
      await tester.pump();

      Text label() =>
          tester.widget<Text>(find.text(AppStrings.lavaModelCampfire));
      LavaIcon icon() => tester.widget<LavaIcon>(
        find.byType(LavaIcon).at(LavaDemoType.campfire.index),
      );
      expect(label().style!.color, AppTheme.subtext);
      expect(icon().autoPlay, isFalse);

      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await mouse.addPointer(location: Offset.zero);
      addTearDown(mouse.removePointer);
      await mouse.moveTo(
        tester.getCenter(find.text(AppStrings.lavaModelCampfire)),
      );
      await tester.pump();
      expect(label().style!.color, AppTheme.text);
      expect(icon().autoPlay, isTrue);

      await mouse.moveTo(Offset.zero);
      await tester.pump();
      expect(label().style!.color, AppTheme.subtext);
      expect(icon().autoPlay, isFalse);
    });

    testWidgets('X-ray toggle brings its legend and waits for a bundle', (
      tester,
    ) async {
      _setView(tester);
      await tester.pumpWidget(_studio());
      await tester.pump();
      await tester.ensureVisible(find.text(AppStrings.lavaStudioXray));

      expect(find.byTooltip(AppStrings.lavaStudioXrayOff), findsOneWidget);
      expect(find.text(AppStrings.lavaStudioFromKey), findsNothing);

      await tester.tap(find.text(AppStrings.lavaStudioXray));
      await tester.pump(const Duration(milliseconds: 250));
      expect(find.byTooltip(AppStrings.lavaStudioXrayOn), findsOneWidget);
      expect(find.text(AppStrings.lavaStudioFromKey), findsOneWidget);
      expect(find.text(AppStrings.lavaStudioFromAtlas), findsOneWidget);
      expect(find.text(AppStrings.lavaStudioFree), findsOneWidget);
      // Nothing decoded yet: there is no frame to overlay.
      expect(
        tester.widget<LavaIcon>(find.byType(LavaIcon).last).foregroundPainter,
        isNull,
      );

      await tester.tap(find.text(AppStrings.lavaStudioXray));
      await tester.pump(const Duration(milliseconds: 250));
      expect(find.byTooltip(AppStrings.lavaStudioXrayOff), findsOneWidget);
      expect(find.text(AppStrings.lavaStudioFromKey), findsNothing);
    });
  });

  group('LavaStudioContent transport', () {
    testWidgets('play / pause and restart drive the shared controller', (
      tester,
    ) async {
      _setView(tester);
      await tester.pumpWidget(_studio());
      await tester.pump();
      await tester.ensureVisible(find.byTooltip(AppStrings.lavaStudioReplay));

      expect(find.text('PLAYING • 30 FPS'), findsOneWidget);
      for (var i = 0; i < 4; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      expect(_frameOnTransport(tester), greaterThan(1));

      await tester.tap(find.byIcon(Icons.pause));
      await tester.pump();
      expect(find.text('PAUSED • 30 FPS'), findsOneWidget);
      expect(find.byIcon(Icons.play_arrow), findsOneWidget);
      final paused = _frameOnTransport(tester);
      await tester.pump(const Duration(milliseconds: 300));
      expect(_frameOnTransport(tester), paused);

      await tester.tap(find.byTooltip(AppStrings.lavaStudioReplay));
      await tester.pump();
      expect(_frameOnTransport(tester), 1);

      await tester.tap(find.byIcon(Icons.play_arrow));
      await tester.pump();
      expect(find.text('PLAYING • 30 FPS'), findsOneWidget);
      expect(find.byIcon(Icons.pause), findsOneWidget);
    });

    testWidgets('speed selector changes how fast frames advance', (
      tester,
    ) async {
      _setView(tester);
      await tester.pumpWidget(_studio());
      await tester.pump();
      await tester.ensureVisible(find.text('2.0x'));

      Future<int> framesPlayedAt(String speed) async {
        await tester.tap(find.byIcon(Icons.pause));
        await tester.pump();
        await tester.tap(find.byTooltip(AppStrings.lavaStudioReplay));
        await tester.tap(find.text(speed));
        await tester.tap(find.byIcon(Icons.play_arrow));
        for (var i = 0; i < 5; i++) {
          await tester.pump(const Duration(milliseconds: 50));
        }
        return _frameOnTransport(tester) - 1;
      }

      final slow = await framesPlayedAt('0.5x');
      final normal = await framesPlayedAt('1.0x');
      final fast = await framesPlayedAt('2.0x');
      expect(slow, greaterThan(0));
      expect(normal, greaterThan(slow));
      expect(fast, greaterThan(normal));
      expect(
        tester
            .widget<SegmentedButton<double>>(
              find.byType(SegmentedButton<double>),
            )
            .selected,
        {2.0},
      );
    });

    testWidgets('timeline slider scrubs and announces the frame', (
      tester,
    ) async {
      _setView(tester);
      final semantics = tester.ensureSemantics();
      await tester.pumpWidget(_studio());
      await tester.pump();
      await _pause(tester);

      await _scrubTo(tester, 1);
      expect(find.text('FRAME 24 / 24'), findsOneWidget);
      expect(tester.widget<Slider>(find.byType(Slider)).value, 23);
      // Which node of the slider carries the value differs between SDKs.
      expect(find.semantics.byValue('FRAME 24'), findsOne);

      await _scrubTo(tester, 0);
      expect(find.text('FRAME 1 / 24'), findsOneWidget);
      expect(find.semantics.byValue('FRAME 1'), findsOne);
      expect(find.semantics.byValue('FRAME 24'), findsNothing);
      semantics.dispose();
    });
  });

  group('LavaStudioContent layout', () {
    // Labels wrap to one or two lines, so tops within a row differ by a few
    // pixels; rows are a whole tab apart.
    int tabRows(WidgetTester tester) {
      final tops = [
        for (final name in _allModels)
          tester.getTopLeft(find.text(name).first).dy,
      ]..sort();
      var rows = 1;
      for (var i = 1; i < tops.length; i++) {
        if (tops[i] - tops[i - 1] > 40) rows++;
      }
      return rows;
    }

    testWidgets('wide windows put the inspector beside the stage', (
      tester,
    ) async {
      _setView(tester, size: const Size(1600, 1000));
      await tester.pumpWidget(_studio());
      await tester.pump();

      final stage = tester.getRect(find.byType(LavaIcon).last);
      final inspector = tester.getRect(
        find.text(AppStrings.lavaStudioInspector),
      );
      expect(inspector.left, greaterThan(stage.right));
      expect(inspector.top, lessThan(stage.top));
      expect(tabRows(tester), 2);
      expect(tester.takeException(), isNull);
    });

    testWidgets('medium windows stack the inspector under one row of tabs', (
      tester,
    ) async {
      _setView(tester, size: const Size(1000, 700));
      await tester.pumpWidget(_studio());
      await tester.pump();

      final transport = tester.getRect(find.byType(Slider));
      final inspector = tester.getRect(
        find.text(AppStrings.lavaStudioInspector),
      );
      expect(inspector.top, greaterThan(transport.bottom));
      expect(tabRows(tester), 1);
      expect(tester.takeException(), isNull);
    });

    testWidgets('phones get a scrolling tab strip', (tester) async {
      _setView(tester, size: const Size(360, 740));
      await tester.pumpWidget(_studio());
      await tester.pump();
      expect(tester.takeException(), isNull);

      // One row of 104 px tabs, wider than the screen.
      expect(tabRows(tester), 1);
      final last = find.text(AppStrings.lavaModelSennaMp4);
      expect(tester.getRect(last).left, greaterThan(360));
      final strip = find.ancestor(
        of: last,
        matching: find.byWidgetPredicate(
          (w) =>
              w is SingleChildScrollView &&
              w.scrollDirection == Axis.horizontal,
        ),
      );
      expect(strip, findsOneWidget);

      await tester.drag(strip, const Offset(-900, 0));
      await tester.pump();
      expect(tester.getRect(last).right, lessThanOrEqualTo(360));
      await tester.tap(last);
      await tester.pump();
      expect(find.text(AppStrings.lavaModelSennaMp4Desc), findsOneWidget);
    });
  });

  group('LavaStudioContent links', () {
    const channel = MethodChannel('plugins.flutter.io/url_launcher');

    List<MethodCall> mockLauncher({required bool canLaunch}) {
      final calls = <MethodCall>[];
      binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, (
        call,
      ) async {
        calls.add(call);
        return call.method == 'canLaunch' ? canLaunch : true;
      });
      addTearDown(
        () => binding.defaultBinaryMessenger.setMockMethodCallHandler(
          channel,
          null,
        ),
      );
      return calls;
    }

    String? url(MethodCall call) =>
        (call.arguments as Map<Object?, Object?>)['url'] as String?;

    testWidgets('footer buttons open the repository and the publisher page', (
      tester,
    ) async {
      _setView(tester);
      final calls = mockLauncher(canLaunch: true);
      await tester.pumpWidget(_studio());
      await tester.pump();

      final github = find.text(AppStrings.lavaStudioBtnGithub);
      await tester.ensureVisible(github);
      await tester.tap(github);
      await tester.pump();
      expect(calls.map((c) => c.method), ['canLaunch', 'launch']);
      expect(calls.map(url), everyElement(AppStrings.urlGitHubLava));

      calls.clear();
      await tester.tap(find.text(AppStrings.lavaStudioBtnPubDev));
      await tester.pump();
      expect(calls.map((c) => c.method), ['canLaunch', 'launch']);
      expect(calls.map(url), everyElement(AppStrings.urlPubDev));
    });

    testWidgets('nothing is launched when the platform cannot open links', (
      tester,
    ) async {
      _setView(tester);
      final calls = mockLauncher(canLaunch: false);
      await tester.pumpWidget(_studio());
      await tester.pump();

      final github = find.text(AppStrings.lavaStudioBtnGithub);
      await tester.ensureVisible(github);
      await tester.tap(github);
      await tester.pump();
      expect(calls.map((c) => c.method), ['canLaunch']);
    });
  });
}
