import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lava_flutter/lava_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../theme/app_theme.dart';
import '../constants/app_strings.dart';
import '../constants/lava_format_stats.dart';

/// Interactive showcase window for the `lava_flutter` package.
///
/// Left: the Airbnb-style category bar and the stage, with an X-ray that
/// tints every tile of the frame by where it was copied from. Right: a live
/// inspector reading the engine while it plays - the frame's recipe, the atlas
/// blocks being read, the decode path, and the measured size of the same
/// animation in other containers.
class LavaStudioContent extends StatefulWidget {
  const LavaStudioContent({super.key});

  @override
  State<LavaStudioContent> createState() => _LavaStudioContentState();
}

/// Sizes and type scale derived from the space the studio actually gets (it
/// lives in a resizable window, so the viewport is not the right reference).
class _Metrics {
  _Metrics(double width, double viewportHeight)
    : wide = width >= 1080,
      scale = (width / 1280).clamp(0.92, 1.18).toDouble(),
      gutter = width < 600 ? 16.0 : 28.0 {
    final stageWidth = wide ? (width - gutter * 3) * 0.54 : width - gutter * 2;
    previewSize = math.min(
      (stageWidth * 0.52).clamp(150.0, 340.0).toDouble(),
      math.max(150.0, viewportHeight * 0.36),
    );
    tabIconSize = (stageWidth / 11).clamp(44.0, 72.0).toDouble();
  }

  final bool wide;
  final double scale;
  final double gutter;
  late final double previewSize;
  late final double tabIconSize;

  // Pixel display face: reads larger than its point size, so it stays small.
  TextStyle get title => GoogleFonts.pressStart2p(
    fontSize: 15 * scale,
    height: 1.6,
    color: AppTheme.peach,
  );
  TextStyle get section => GoogleFonts.pressStart2p(
    fontSize: 10.5 * scale,
    height: 1.6,
    color: AppTheme.teal,
  );
  // Reading sizes never drop under 12 px; long copy gets a 1.6 line height.
  TextStyle get body => GoogleFonts.spaceMono(
    fontSize: 14 * scale,
    height: 1.6,
    color: AppTheme.text,
  );
  TextStyle get caption => GoogleFonts.spaceMono(
    fontSize: math.max(12.0, 12.5 * scale),
    height: 1.5,
    color: AppTheme.subtext,
  );
  TextStyle get label => GoogleFonts.spaceMono(
    fontSize: math.max(12.0, 13 * scale),
    fontWeight: FontWeight.bold,
    color: AppTheme.text,
  );
}

class _LavaStudioContentState extends State<LavaStudioContent>
    with SingleTickerProviderStateMixin {
  late final LavaController _controller;
  LavaDemoType _selectedType = LavaDemoType.macintosh;
  double _speed = 1.0;
  bool _xray = false;
  LavaBundle? _bundle;

  /// The bundle on stage, unless it was given back since: a large preview is
  /// disposed when its last icon lets go, and its images must not be painted.
  LavaBundle? get _liveBundle => (_bundle?.isDisposed ?? true) ? null : _bundle;

  static const _names = {
    LavaDemoType.macintosh: AppStrings.lavaModelMacintosh,
    LavaDemoType.sunflower: AppStrings.lavaModelTree,
    LavaDemoType.lavaLamp: AppStrings.lavaModelLavaLamp,
    LavaDemoType.campfire: AppStrings.lavaModelCampfire,
    LavaDemoType.rocket: AppStrings.lavaModelRocket,
    LavaDemoType.senna: AppStrings.lavaModelSenna,
    LavaDemoType.christmasTree: AppStrings.lavaModelChristmasTree,
    LavaDemoType.f1Car: AppStrings.lavaModelF1Car,
    LavaDemoType.f1Front: AppStrings.lavaModelF1Front,
    LavaDemoType.sennaMp4: AppStrings.lavaModelSennaMp4,
  };

  static const _descriptions = {
    LavaDemoType.macintosh: AppStrings.lavaModelMacintoshDesc,
    LavaDemoType.sunflower: AppStrings.lavaModelTreeDesc,
    LavaDemoType.lavaLamp: AppStrings.lavaModelLavaLampDesc,
    LavaDemoType.campfire: AppStrings.lavaModelCampfireDesc,
    LavaDemoType.rocket: AppStrings.lavaModelRocketDesc,
    LavaDemoType.senna: AppStrings.lavaModelSennaDesc,
    LavaDemoType.christmasTree: AppStrings.lavaModelChristmasTreeDesc,
    LavaDemoType.f1Car: AppStrings.lavaModelF1CarDesc,
    LavaDemoType.f1Front: AppStrings.lavaModelF1FrontDesc,
    LavaDemoType.sennaMp4: AppStrings.lavaModelSennaMp4Desc,
  };

  @override
  void initState() {
    super.initState();
    _controller = LavaController(
      totalFrames: 24,
      fps: 30,
      autoPlay: true,
      loop: true,
      vsync: this,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _launch(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  void _selectModel(LavaDemoType type) {
    if (_selectedType == type) return;
    setState(() {
      _selectedType = type;
      // Frame count / fps come from the bundle manifest: LavaIcon reconfigures
      // the shared controller as soon as the new bundle is decoded.
      _controller.reset();
    });
  }

  @override
  Widget build(BuildContext context) {
    final viewportHeight = MediaQuery.sizeOf(context).height;
    return LayoutBuilder(
      builder: (context, constraints) {
        final m = _Metrics(constraints.maxWidth, viewportHeight);
        final stage = _buildStage(m);
        final inspector = _buildInspector(m);

        return SingleChildScrollView(
          padding: EdgeInsets.all(m.gutter),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(m),
              SizedBox(height: m.gutter),
              if (m.wide)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 54, child: stage),
                    SizedBox(width: m.gutter),
                    Expanded(flex: 46, child: inspector),
                  ],
                )
              else ...[
                stage,
                SizedBox(height: m.gutter),
                inspector,
              ],
              SizedBox(height: m.gutter * 1.5),
              _buildFooter(m),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(_Metrics m) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(AppStrings.lavaStudioTitle, style: m.title),
        const SizedBox(height: 8),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: Text(AppStrings.lavaStudioSubtitle, style: m.body),
        ),
        const SizedBox(height: 14),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _Badge(AppStrings.lavaStudioBadgeTile, AppTheme.blue, m),
            _Badge(AppStrings.lavaStudioBadgeAlpha, AppTheme.green, m),
            _Badge(AppStrings.lavaStudioBadgePerspective, AppTheme.peach, m),
            _Badge(AppStrings.lavaStudioBadgeZeroAlloc, AppTheme.teal, m),
            _Badge(AppStrings.lavaStudioBadgeWasm, AppTheme.mauve, m),
          ],
        ),
      ],
    );
  }

  // --------------------------------------------------------------------- stage
  Widget _buildStage(_Metrics m) {
    final bundle = _liveBundle;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Panel(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: LayoutBuilder(
            builder: (context, box) {
              // One row when every label fits unbroken; otherwise two rows
              // (every icon stays visible, which a scrolling strip does not
              // guarantee); a scrolling strip only on very narrow screens.
              const minTab = 88.0;
              final types = LavaDemoType.values;
              final rows = box.maxWidth / types.length >= minTab ? 1 : 2;
              final perRow = (types.length / rows).ceil();
              final fits = box.maxWidth / perRow >= minTab;
              final tabWidth = fits ? box.maxWidth / perRow : 104.0;

              Widget tab(LavaDemoType type) => SizedBox(
                width: tabWidth,
                child: _CategoryTab(
                  label: _names[type]!,
                  demoType: type,
                  isSelected: _selectedType == type,
                  iconSize: math.min(m.tabIconSize, tabWidth - 28),
                  metrics: m,
                  onTap: () => _selectModel(type),
                ),
              );

              if (!fits) {
                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(children: [for (final type in types) tab(type)]),
                );
              }
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (var start = 0; start < types.length; start += perRow)
                    Row(
                      children: [
                        for (final type in types.skip(start).take(perRow))
                          tab(type),
                      ],
                    ),
                ],
              );
            },
          ),
        ),
        SizedBox(height: m.gutter * 0.6),
        _Panel(
          color: AppTheme.background,
          borderColor: AppTheme.surface0,
          shadow: true,
          padding: EdgeInsets.symmetric(
            vertical: m.gutter * 1.2,
            horizontal: m.gutter,
          ),
          child: Column(
            children: [
              LavaIcon.demo(
                demoType: _selectedType,
                controller: _controller,
                size: m.previewSize,
                interactive: true,
                filterQuality: FilterQuality.medium,
                foregroundPainter:
                    _xray && bundle != null
                        ? _XrayPainter(bundle, _controller)
                        : null,
                onBundleChanged: (b) => setState(() => _bundle = b),
              ),
              const SizedBox(height: 16),
              Text(
                _names[_selectedType]!,
                textAlign: TextAlign.center,
                style: m.label.copyWith(
                  color: AppTheme.peach,
                  fontSize: m.label.fontSize! + 2,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                _descriptions[_selectedType]!,
                textAlign: TextAlign.center,
                style: m.caption,
              ),
              const SizedBox(height: 14),
              Wrap(
                alignment: WrapAlignment.center,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 14,
                runSpacing: 10,
                children: [
                  _XrayToggle(
                    value: _xray,
                    metrics: m,
                    onChanged: (v) => setState(() => _xray = v),
                  ),
                  Text(AppStrings.lavaStudioHint, style: m.caption),
                ],
              ),
              if (_xray) ...[
                const SizedBox(height: 12),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 16,
                  runSpacing: 6,
                  children: [
                    _Legend(_keyColor, AppStrings.lavaStudioFromKey, m),
                    _Legend(_atlasColor, AppStrings.lavaStudioFromAtlas, m),
                    _Legend(AppTheme.surface0, AppStrings.lavaStudioFree, m),
                  ],
                ),
              ],
            ],
          ),
        ),
        SizedBox(height: m.gutter * 0.6),
        _buildTransport(m),
      ],
    );
  }

  Widget _buildTransport(_Metrics m) {
    return _Panel(
      child: Column(
        children: [
          AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${AppStrings.lavaStudioFrame} ${_controller.currentFrame + 1} / ${_controller.totalFrames}',
                    style: m.label.copyWith(color: AppTheme.peach),
                  ),
                  Text(
                    '${_controller.status.name.toUpperCase()} • ${_controller.fps} ${AppStrings.lavaStudioFps}',
                    style: m.caption,
                  ),
                ],
              );
            },
          ),
          AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              return SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  activeTrackColor: AppTheme.peach,
                  inactiveTrackColor: AppTheme.surface0,
                  thumbColor: AppTheme.peach,
                  overlayColor: AppTheme.peach.withValues(alpha: 0.2),
                  trackHeight: 4,
                ),
                child: Slider(
                  value: _controller.currentFrame.toDouble(),
                  min: 0,
                  max: math.max(1, _controller.totalFrames - 1).toDouble(),
                  semanticFormatterCallback:
                      (v) => '${AppStrings.lavaStudioFrame} ${v.round() + 1}',
                  onChanged: (val) => _controller.seekToFrame(val.round()),
                ),
              );
            },
          ),
          Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 12,
            runSpacing: 10,
            children: [
              IconButton.filled(
                tooltip: AppStrings.lavaStudioAutoRotate,
                iconSize: 26,
                constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                onPressed: () {
                  if (_controller.isPlaying) {
                    _controller.pause();
                  } else {
                    _controller.play();
                  }
                },
                style: IconButton.styleFrom(
                  backgroundColor: AppTheme.peach,
                  foregroundColor: AppTheme.background,
                ),
                icon: AnimatedBuilder(
                  animation: _controller,
                  builder: (context, _) {
                    return Icon(
                      _controller.isPlaying ? Icons.pause : Icons.play_arrow,
                    );
                  },
                ),
              ),
              IconButton.outlined(
                tooltip: AppStrings.lavaStudioReplay,
                constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                onPressed: () => _controller.reset(),
                style: IconButton.styleFrom(
                  foregroundColor: AppTheme.subtext,
                  side: const BorderSide(color: AppTheme.surface0),
                ),
                icon: const Icon(Icons.replay),
              ),
              SegmentedButton<double>(
                segments: const [
                  ButtonSegment(value: 0.5, label: Text('0.5x')),
                  ButtonSegment(value: 1.0, label: Text('1.0x')),
                  ButtonSegment(value: 2.0, label: Text('2.0x')),
                ],
                selected: {_speed},
                style: ButtonStyle(
                  textStyle: WidgetStatePropertyAll(m.caption),
                  minimumSize: const WidgetStatePropertyAll(Size(56, 44)),
                ),
                onSelectionChanged: (selected) {
                  setState(() {
                    _speed = selected.first;
                    _controller.setSpeed(_speed);
                  });
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ----------------------------------------------------------------- inspector
  Widget _buildInspector(_Metrics m) {
    final bundle = _liveBundle;
    final stats = LavaFormatStats.byIcon[_selectedType];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(AppStrings.lavaStudioInspector, style: m.section),
        const SizedBox(height: 6),
        Text(AppStrings.lavaStudioInspectorLead, style: m.caption),
        SizedBox(height: m.gutter * 0.6),
        _Panel(
          child:
              bundle?.compositor == null
                  ? Text(AppStrings.lavaStudioLoading, style: m.caption)
                  : _RecipeCard(bundle!, _controller, m),
        ),
        SizedBox(height: m.gutter * 0.6),
        _Panel(
          child:
              bundle?.compositor == null
                  ? Text(AppStrings.lavaStudioLoading, style: m.caption)
                  : _AtlasCard(bundle!, _controller, m),
        ),
        SizedBox(height: m.gutter * 0.6),
        if (stats != null) ...[
          _Panel(child: _FaceOffCard(stats, m)),
          SizedBox(height: m.gutter * 0.6),
        ],
        _Panel(
          child:
              bundle == null
                  ? Text(AppStrings.lavaStudioLoading, style: m.caption)
                  : _RuntimeCard(bundle, _controller, stats, m),
        ),
      ],
    );
  }

  Widget _buildFooter(_Metrics m) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(AppStrings.lavaStudioArchitecture, style: m.section),
        const SizedBox(height: 10),
        ConstrainedBox(
          // ~75 characters per line keeps the paragraph comfortable to read.
          constraints: const BoxConstraints(maxWidth: 760),
          child: Text(AppStrings.lavaStudioArchitectureDesc, style: m.body),
        ),
        const SizedBox(height: 18),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _LinkButton(
              AppStrings.lavaStudioBtnGithub,
              AppTheme.peach,
              m,
              () => _launch(AppStrings.urlGitHubLava),
            ),
            _LinkButton(
              AppStrings.lavaStudioBtnPubDev,
              AppTheme.blue,
              m,
              () => _launch(AppStrings.urlPubDev),
            ),
          ],
        ),
      ],
    );
  }
}

const _keyColor = AppTheme.blue;
const _atlasColor = AppTheme.peach;

/// Tiles of the current frame, per source, from the compositor's blit list.
class _Recipe {
  _Recipe(LavaBundle bundle, int frame) {
    final manifest = bundle.manifest;
    final cell = (manifest.cellSize ?? 32).toDouble();
    total =
        (manifest.tileWidth / cell).ceil() *
        (manifest.tileHeight / cell).ceil();
    blits = bundle.compositor!.blits(frame);
    final sources = <int>{};
    for (final blit in blits) {
      final tiles =
          (blit.destination.width / cell).ceil() *
          (blit.destination.height / cell).ceil();
      sources.add(blit.imageIndex);
      if (blit.imageIndex == 0) {
        fromKey += tiles;
      } else {
        fromAtlas += tiles;
      }
    }
    fromKey = math.min(fromKey, total);
    drawCalls = sources.length;
    free = math.max(0, total - fromKey - fromAtlas);
  }

  late final List<LavaTileBlit> blits;
  late final int total;
  late final int drawCalls;
  late final int free;
  int fromKey = 0;
  int fromAtlas = 0;
}

class _RecipeCard extends StatelessWidget {
  const _RecipeCard(this.bundle, this.controller, this.m);

  final LavaBundle bundle;
  final LavaController controller;
  final _Metrics m;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final recipe = _Recipe(bundle, controller.currentFrame);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(AppStrings.lavaStudioRecipe, style: m.label),
                Text(
                  '${recipe.blits.length} ${recipe.blits.length == 1 ? AppStrings.lavaStudioBlit : AppStrings.lavaStudioBlits} → '
                  '${recipe.drawCalls} ${recipe.drawCalls == 1 ? AppStrings.lavaStudioDrawCall : AppStrings.lavaStudioDrawCalls}',
                  style: m.caption,
                ),
              ],
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: SizedBox(
                height: 14,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (recipe.fromKey > 0)
                      Expanded(
                        flex: recipe.fromKey,
                        child: const ColoredBox(color: _keyColor),
                      ),
                    if (recipe.fromAtlas > 0)
                      Expanded(
                        flex: recipe.fromAtlas,
                        child: const ColoredBox(color: _atlasColor),
                      ),
                    if (recipe.free > 0)
                      Expanded(
                        flex: recipe.free,
                        child: const ColoredBox(color: AppTheme.surface0),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 18,
              runSpacing: 6,
              children: [
                _Legend(
                  _keyColor,
                  '${recipe.fromKey} ${AppStrings.lavaStudioFromKey}',
                  m,
                ),
                _Legend(
                  _atlasColor,
                  '${recipe.fromAtlas} ${AppStrings.lavaStudioFromAtlas}',
                  m,
                ),
                _Legend(
                  AppTheme.surface0,
                  '${recipe.free} ${AppStrings.lavaStudioFree}',
                  m,
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}

class _AtlasCard extends StatelessWidget {
  const _AtlasCard(this.bundle, this.controller, this.m);

  final LavaBundle bundle;
  final LavaController controller;
  final _Metrics m;

  @override
  Widget build(BuildContext context) {
    final key = bundle.images.first;
    final atlas = bundle.images.length > 1 ? bundle.images[1] : null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(AppStrings.lavaStudioAtlas, style: m.label),
        const SizedBox(height: 4),
        Text(AppStrings.lavaStudioAtlasLead, style: m.caption),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 96 * m.scale,
                  height: 96 * m.scale * key.height / key.width,
                  child: CustomPaint(
                    painter: _SourcePainter(bundle, controller, 0, _keyColor),
                  ),
                ),
                const SizedBox(height: 6),
                Text(AppStrings.lavaStudioKeyFrame, style: m.caption),
              ],
            ),
            const SizedBox(width: 14),
            if (atlas != null)
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AspectRatio(
                      // Atlases run from 2048x192 to 2048x2752: clamp the box,
                      // the painter letterboxes inside it.
                      aspectRatio: (atlas.width / atlas.height).clamp(1.4, 7.0),
                      child: CustomPaint(
                        painter: _SourcePainter(
                          bundle,
                          controller,
                          1,
                          _atlasColor,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text('${atlas.width}×${atlas.height} px', style: m.caption),
                  ],
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _FaceOffCard extends StatelessWidget {
  const _FaceOffCard(this.stats, this.m);

  final LavaFormatStats stats;
  final _Metrics m;

  @override
  Widget build(BuildContext context) {
    final rows = [
      (AppStrings.lavaStudioFormatPng, stats.pngSequence, false),
      (AppStrings.lavaStudioFormatApng, stats.apng, false),
      (AppStrings.lavaStudioFormatGif, stats.gif, false),
      (AppStrings.lavaStudioFormatWebp, stats.animatedWebp, false),
      (AppStrings.lavaStudioFormatLava, stats.lavaAvif, true),
    ]..sort((a, b) => b.$2.compareTo(a.$2));
    final largest = rows.first.$2;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(AppStrings.lavaStudioFaceOff, style: m.label),
        const SizedBox(height: 12),
        for (final (name, bytes, isLava) in rows)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                SizedBox(
                  width: 124 * m.scale,
                  child: Text(
                    name,
                    style: m.caption.copyWith(
                      color: isLava ? AppTheme.peach : AppTheme.subtext,
                      fontWeight: isLava ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ),
                Expanded(
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: FractionallySizedBox(
                      widthFactor: math.max(0.02, bytes / largest),
                      child: Container(
                        height: 12,
                        decoration: BoxDecoration(
                          color: isLava ? AppTheme.peach : AppTheme.overlay,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(
                  width: 78 * m.scale,
                  child: Text(
                    _kb(bytes),
                    textAlign: TextAlign.right,
                    style: m.caption.copyWith(
                      color: isLava ? AppTheme.peach : AppTheme.text,
                    ),
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: 4),
        Text(AppStrings.lavaStudioFaceOffNote, style: m.caption),
      ],
    );
  }
}

class _RuntimeCard extends StatelessWidget {
  const _RuntimeCard(this.bundle, this.controller, this.stats, this.m);

  final LavaBundle bundle;
  final LavaController controller;
  final LavaFormatStats? stats;
  final _Metrics m;

  @override
  Widget build(BuildContext context) {
    final isHd = bundle.manifest.tileWidth > LavaBundle.demoBaseWidth;
    final file = bundle.imageFiles.isEmpty ? '' : bundle.imageFiles.last;
    final isAvif = file.endsWith('.avif');
    final atlas = bundle.images.last;
    final textureMb = atlas.width * atlas.height * 4 / (1024 * 1024);
    final downloaded =
        stats == null
            ? null
            : isAvif
            ? (isHd ? stats!.lavaHdAvif : stats!.lavaAvif)
            : (isHd ? null : stats!.lavaWebp);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(AppStrings.lavaStudioRuntime, style: m.label),
        const SizedBox(height: 10),
        _Fact(
          AppStrings.lavaStudioDecoded,
          isAvif
              ? 'AVIF 4:4:4${kIsWeb ? ' · createImageBitmap' : ''}'
              : file.isEmpty
              ? '—'
              : '${file.split('.').last.toUpperCase()} fallback',
          m,
        ),
        _Fact(
          AppStrings.lavaStudioVariant,
          isHd
              ? AppStrings.lavaStudioVariantHd
              : AppStrings.lavaStudioVariantStd,
          m,
        ),
        if (downloaded != null)
          _Fact(AppStrings.lavaStudioDownload, _kb(downloaded), m),
        _Fact(
          AppStrings.lavaStudioTexture,
          '${atlas.width}×${atlas.height} · ${textureMb.toStringAsFixed(1)} MB',
          m,
        ),
        AnimatedBuilder(
          animation: controller,
          builder: (context, _) {
            final compositor = bundle.compositor;
            return _Fact(
              AppStrings.lavaStudioCache,
              compositor == null
                  ? '—'
                  : '${compositor.cachedFrameCount} / ${math.max(0, compositor.frameCount - 1)}',
              m,
            );
          },
        ),
      ],
    );
  }
}

String _kb(int bytes) =>
    bytes >= 1024 * 1024
        ? '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB'
        : '${(bytes / 1024).round()} KB';

// ------------------------------------------------------------------- painters

/// Tints every block of the frame on stage by the image it was copied from,
/// over the 32 px tile grid. Lives inside LavaIcon's transform, so it tilts
/// and bounces with the icon.
class _XrayPainter extends CustomPainter {
  _XrayPainter(this.bundle, this.controller) : super(repaint: controller);

  final LavaBundle bundle;
  final LavaController controller;

  @override
  void paint(Canvas canvas, Size size) {
    final compositor = bundle.compositor;
    if (compositor == null) return;
    final manifest = bundle.manifest;
    final content = Size(
      manifest.tileWidth.toDouble(),
      manifest.tileHeight.toDouble(),
    );
    final fitted = applyBoxFit(BoxFit.contain, content, size);
    final box = Alignment.center.inscribe(
      fitted.destination,
      Offset.zero & size,
    );
    final scale = box.width / content.width;
    final cell = (manifest.cellSize ?? 32) * scale;

    canvas.save();
    canvas.translate(box.left, box.top);
    canvas.clipRect(Offset.zero & box.size);

    final fill = Paint();
    final stroke =
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5;
    for (final blit in compositor.blits(controller.currentFrame)) {
      final colour = blit.imageIndex == 0 ? _keyColor : _atlasColor;
      final rect = Rect.fromLTRB(
        blit.destination.left * scale,
        blit.destination.top * scale,
        blit.destination.right * scale,
        blit.destination.bottom * scale,
      );
      canvas.drawRect(
        rect,
        fill
          ..color = colour.withValues(
            alpha: blit.imageIndex == 0 ? 0.16 : 0.30,
          ),
      );
      canvas.drawRect(rect.deflate(0.75), stroke..color = colour);
    }

    final grid =
        Paint()
          ..color = AppTheme.text.withValues(alpha: 0.18)
          ..strokeWidth = 1;
    for (var x = 0.0; x <= box.width + 0.5; x += cell) {
      canvas.drawLine(Offset(x, 0), Offset(x, box.height), grid);
    }
    for (var y = 0.0; y <= box.height + 0.5; y += cell) {
      canvas.drawLine(Offset(0, y), Offset(box.width, y), grid);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _XrayPainter oldDelegate) =>
      oldDelegate.bundle != bundle || oldDelegate.controller != controller;
}

/// A bundle image (key frame or atlas) dimmed, with the blocks the current
/// frame reads from it drawn at full strength and outlined.
class _SourcePainter extends CustomPainter {
  _SourcePainter(this.bundle, this.controller, this.imageIndex, this.colour)
    : super(repaint: controller);

  final LavaBundle bundle;
  final LavaController controller;
  final int imageIndex;
  final Color colour;

  @override
  void paint(Canvas canvas, Size size) {
    final compositor = bundle.compositor;
    if (compositor == null || imageIndex >= bundle.images.length) return;
    final ui.Image image = bundle.images[imageIndex];
    final content = Size(image.width.toDouble(), image.height.toDouble());

    canvas.drawRRect(
      RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(6)),
      Paint()..color = AppTheme.background,
    );

    final fitted = applyBoxFit(BoxFit.contain, content, size);
    final box = Alignment.topLeft.inscribe(
      fitted.destination,
      Offset.zero & size,
    );
    final scale = box.width / content.width;
    final paint = Paint()..filterQuality = FilterQuality.medium;

    canvas.drawImageRect(
      image,
      Offset.zero & content,
      box,
      paint..color = const Color(0x59FFFFFF),
    );

    final stroke =
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5
          ..color = colour;
    paint.color = const Color(0xFFFFFFFF);
    for (final blit in compositor.blits(controller.currentFrame)) {
      if (blit.imageIndex != imageIndex) continue;
      final rect = Rect.fromLTRB(
        box.left + blit.source.left * scale,
        box.top + blit.source.top * scale,
        box.left + blit.source.right * scale,
        box.top + blit.source.bottom * scale,
      );
      canvas.drawImageRect(image, blit.source, rect, paint);
      canvas.drawRect(rect, stroke);
    }
  }

  @override
  bool shouldRepaint(covariant _SourcePainter oldDelegate) =>
      oldDelegate.bundle != bundle ||
      oldDelegate.controller != controller ||
      oldDelegate.imageIndex != imageIndex;
}

// -------------------------------------------------------------------- pieces

class _Panel extends StatelessWidget {
  const _Panel({
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.color,
    this.borderColor,
    this.shadow = false,
  });

  final Widget child;
  final EdgeInsets padding;
  final Color? color;
  final Color? borderColor;
  final bool shadow;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color ?? AppTheme.surface.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor ?? AppTheme.surface0),
        boxShadow:
            shadow
                ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.35),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ]
                : null,
      ),
      child: child,
    );
  }
}

class _Fact extends StatelessWidget {
  const _Fact(this.name, this.value, this.m);

  final String name;
  final String value;
  final _Metrics m;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(flex: 5, child: Text(name, style: m.caption)),
          const SizedBox(width: 12),
          Expanded(
            flex: 6,
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: m.caption.copyWith(color: AppTheme.text),
            ),
          ),
        ],
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend(this.colour, this.text, this.m);

  final Color colour;
  final String text;
  final _Metrics m;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: colour,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 6),
        Text(text, style: m.caption),
      ],
    );
  }
}

class _XrayToggle extends StatelessWidget {
  const _XrayToggle({
    required this.value,
    required this.metrics,
    required this.onChanged,
  });

  final bool value;
  final _Metrics metrics;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final colour = value ? AppTheme.background : AppTheme.teal;
    return Tooltip(
      message:
          value ? AppStrings.lavaStudioXrayOn : AppStrings.lavaStudioXrayOff,
      child: Semantics(
        button: true,
        toggled: value,
        label: AppStrings.lavaStudioXray,
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: () => onChanged(!value),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            constraints: const BoxConstraints(minHeight: 44),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: value ? AppTheme.teal : Colors.transparent,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppTheme.teal, width: 1.5),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.grid_on, size: 18, color: colour),
                const SizedBox(width: 8),
                Text(
                  AppStrings.lavaStudioXray,
                  style: metrics.label.copyWith(color: colour),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LinkButton extends StatelessWidget {
  const _LinkButton(this.text, this.colour, this.m, this.onPressed);

  final String text;
  final Color colour;
  final _Metrics m;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: colour,
        side: BorderSide(color: colour),
        minimumSize: const Size(48, 48),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      ),
      child: Text(text, style: m.label.copyWith(color: colour)),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge(this.label, this.color, this.m);

  final String label;
  final Color color;
  final _Metrics m;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        label,
        style: m.caption.copyWith(color: color, fontWeight: FontWeight.bold),
      ),
    );
  }
}

class _CategoryTab extends StatefulWidget {
  const _CategoryTab({
    required this.label,
    required this.demoType,
    required this.isSelected,
    required this.iconSize,
    required this.metrics,
    required this.onTap,
  });

  final String label;
  final LavaDemoType demoType;
  final bool isSelected;
  final double iconSize;
  final _Metrics metrics;
  final VoidCallback onTap;

  @override
  State<_CategoryTab> createState() => _CategoryTabState();
}

class _CategoryTabState extends State<_CategoryTab> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final colour =
        widget.isSelected
            ? AppTheme.peach
            : (_isHovered ? AppTheme.text : AppTheme.subtext);
    return Semantics(
      button: true,
      selected: widget.isSelected,
      label: widget.label,
      excludeSemantics: true,
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: widget.onTap,
          behavior: HitTestBehavior.opaque,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            constraints: const BoxConstraints(minHeight: 48),
            margin: const EdgeInsets.symmetric(horizontal: 3),
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color:
                      widget.isSelected ? AppTheme.peach : Colors.transparent,
                  width: 2.5,
                ),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                LavaIcon.demo(
                  demoType: widget.demoType,
                  size: widget.iconSize,
                  // Airbnb tabs: the icon comes alive when picked (or hovered).
                  autoPlay: widget.isSelected || _isHovered,
                  interactive: false,
                ),
                const SizedBox(height: 6),
                Text(
                  widget.label,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  // Fixed at the 12 px floor: eight tabs share the bar, and a
                  // scaled label would break words in the middle.
                  style: widget.metrics.caption.copyWith(
                    fontSize: 12,
                    height: 1.25,
                    color: colour,
                    fontWeight:
                        widget.isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
