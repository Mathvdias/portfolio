import 'package:flutter/widgets.dart';

import '../engine/lava_controller.dart';
import '../engine/lava_painter.dart';
import '../loader/lava_bundle.dart';
import '../model/lava_types.dart';
import 'lava_interactive.dart';

/// Renders a high-performance tile-based Lava animation with optional
/// tactile 3D interactivity and zero-allocation paint loops.
class LavaIcon extends StatefulWidget {
  /// Creates a [LavaIcon] using a preloaded [LavaBundle].
  const LavaIcon({
    super.key,
    required LavaBundle this.bundle,
    this.controller,
    this.size,
    this.width,
    this.height,
    this.fit = BoxFit.contain,
    this.alignment = Alignment.center,
    this.color,
    this.blendMode = BlendMode.srcIn,
    this.filterQuality = FilterQuality.medium,
    this.interactive = false,
    this.onTap,
    this.onStateChanged,
  }) : _isDemo = false,
       _imageAsset = null,
       _manifestAsset = null,
       _assetBundle = null;

  /// Creates a [LavaIcon] rendering the built-in 3D procedural demo animation.
  const LavaIcon.demo({
    super.key,
    this.controller,
    this.size,
    this.width,
    this.height,
    this.fit = BoxFit.contain,
    this.alignment = Alignment.center,
    this.color,
    this.blendMode = BlendMode.srcIn,
    this.filterQuality = FilterQuality.medium,
    this.interactive = false,
    this.onTap,
    this.onStateChanged,
  }) : bundle = null,
       _isDemo = true,
       _imageAsset = null,
       _manifestAsset = null,
       _assetBundle = null;

  /// Creates a [LavaIcon] by loading assets asynchronously.
  const LavaIcon.asset({
    super.key,
    required String imageAsset,
    required String manifestAsset,
    AssetBundle? assetBundle,
    this.controller,
    this.size,
    this.width,
    this.height,
    this.fit = BoxFit.contain,
    this.alignment = Alignment.center,
    this.color,
    this.blendMode = BlendMode.srcIn,
    this.filterQuality = FilterQuality.medium,
    this.interactive = false,
    this.onTap,
    this.onStateChanged,
  }) : bundle = null,
       _isDemo = false,
       _imageAsset = imageAsset,
       _manifestAsset = manifestAsset,
       _assetBundle = assetBundle;

  /// The preloaded bundle containing atlas texture and manifest metadata.
  final LavaBundle? bundle;

  /// Optional playback controller. If omitted, an internal controller
  /// is created with auto-play enabled.
  final LavaController? controller;

  /// Shorthand dimension setting both width and height equally.
  final double? size;

  /// Explicit width of the rendered icon box.
  final double? width;

  /// Explicit height of the rendered icon box.
  final double? height;

  /// Scaling mode applied when mapping frames to the widget boundaries.
  final BoxFit fit;

  /// Alignment of the frame within the render box.
  final Alignment alignment;

  /// Optional color filter tint.
  final Color? color;

  /// Blend mode for the color tint filter.
  final BlendMode blendMode;

  /// Filtering quality when scaling texture frames.
  final FilterQuality filterQuality;

  /// Whether to enable tactile 3D perspective tilt and spring compression.
  final bool interactive;

  /// Callback executed when tapped.
  final VoidCallback? onTap;

  /// Callback fired when interactive state transitions.
  final ValueChanged<LavaInteractiveState>? onStateChanged;

  final bool _isDemo;
  final String? _imageAsset;
  final String? _manifestAsset;
  final AssetBundle? _assetBundle;

  @override
  State<LavaIcon> createState() => _LavaIconState();
}

class _LavaIconState extends State<LavaIcon>
    with SingleTickerProviderStateMixin {
  LavaBundle? _bundle;
  LavaController? _internalController;
  bool _isLoading = false;

  LavaController get _effectiveController {
    if (widget.controller != null) return widget.controller!;
    return _internalController!;
  }

  @override
  void initState() {
    super.initState();
    if (widget.bundle != null) {
      _bundle = widget.bundle;
      _initControllerIfNeeded();
    } else {
      _loadBundleAsync();
    }
  }

  @override
  void didUpdateWidget(covariant LavaIcon oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.bundle != oldWidget.bundle && widget.bundle != null) {
      _bundle = widget.bundle;
      _initControllerIfNeeded();
    }
  }

  Future<void> _loadBundleAsync() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final loadedBundle =
          widget._isDemo
              ? await LavaBundle.demo()
              : await LavaBundle.fromAsset(
                imageAsset: widget._imageAsset!,
                manifestAsset: widget._manifestAsset!,
                bundle: widget._assetBundle,
              );

      if (mounted) {
        setState(() {
          _bundle = loadedBundle;
          _isLoading = false;
        });
        _initControllerIfNeeded();
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _initControllerIfNeeded() {
    if (widget.controller == null && _bundle != null) {
      _internalController?.dispose();
      _internalController = LavaController(
        totalFrames: _bundle!.manifest.totalFrames,
        fps: _bundle!.manifest.frameRate,
        loop: _bundle!.manifest.loop,
        loopStartFrame: _bundle!.manifest.loopStartFrame,
        loopEndFrame: _bundle!.manifest.loopEndFrame,
        autoPlay: true,
        vsync: this,
      );
    } else if (widget.controller != null) {
      widget.controller!.attach(this);
    }
  }

  @override
  void dispose() {
    _internalController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final effectiveWidth = widget.width ?? widget.size ?? 64.0;
    final effectiveHeight = widget.height ?? widget.size ?? 64.0;

    if (_isLoading || _bundle == null) {
      return SizedBox(width: effectiveWidth, height: effectiveHeight);
    }

    Widget content = RepaintBoundary(
      child: CustomPaint(
        size: Size(effectiveWidth, effectiveHeight),
        painter: LavaPainter(
          atlas: _bundle!.atlas,
          manifest: _bundle!.manifest,
          controller: _effectiveController,
          fit: widget.fit,
          alignment: widget.alignment,
          color: widget.color,
          blendMode: widget.blendMode,
          filterQuality: widget.filterQuality,
        ),
      ),
    );

    if (widget.interactive) {
      content = LavaInteractive(
        onTap: widget.onTap,
        onStateChanged: widget.onStateChanged,
        child: content,
      );
    }

    return SizedBox(
      width: effectiveWidth,
      height: effectiveHeight,
      child: content,
    );
  }
}
