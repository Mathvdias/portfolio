import 'package:flutter/widgets.dart';

import '../engine/lava_controller.dart';
import '../engine/lava_painter.dart';
import '../loader/lava_bundle.dart';
import '../model/lava_types.dart';
import 'lava_interactive.dart';

/// Renders a high-performance tile-based Lava animation with optional
/// tactile 3D interactivity, drag rotation, and zero-allocation paint loops.
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
    this.autoPlay,
    this.dragToRotate = true,
    this.scrubOnHover = false,
    this.onTap,
    this.onStateChanged,
  }) : demoType = LavaDemoType.macintosh,
       _isDemo = false,
       _imageAsset = null,
       _manifestAsset = null,
       _assetBundle = null;

  /// Creates a [LavaIcon] rendering one of the built-in demo bundles (see [LavaDemoType]).
  const LavaIcon.demo({
    super.key,
    this.demoType = LavaDemoType.macintosh,
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
    this.autoPlay,
    this.dragToRotate = true,
    this.scrubOnHover = false,
    this.onTap,
    this.onStateChanged,
    AssetBundle? assetBundle,
  }) : bundle = null,
       _isDemo = true,
       _imageAsset = null,
       _manifestAsset = null,
       _assetBundle = assetBundle;

  /// Creates a [LavaIcon] rendering the built-in sunflower demo bundle.
  const LavaIcon.demoSunflower({
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
    this.autoPlay,
    this.dragToRotate = true,
    this.scrubOnHover = false,
    this.onTap,
    this.onStateChanged,
    AssetBundle? assetBundle,
  }) : bundle = null,
       demoType = LavaDemoType.sunflower,
       _isDemo = true,
       _imageAsset = null,
       _manifestAsset = null,
       _assetBundle = assetBundle;

  /// Creates a [LavaIcon] rendering the built-in 3D procedural nature tree animation.
  const LavaIcon.demoTree({
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
    this.autoPlay,
    this.dragToRotate = true,
    this.scrubOnHover = false,
    this.onTap,
    this.onStateChanged,
    AssetBundle? assetBundle,
  }) : bundle = null,
       demoType = LavaDemoType.sunflower,
       _isDemo = true,
       _imageAsset = null,
       _manifestAsset = null,
       _assetBundle = assetBundle;

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
    this.autoPlay,
    this.dragToRotate = true,
    this.scrubOnHover = false,
    this.onTap,
    this.onStateChanged,
  }) : bundle = null,
       demoType = LavaDemoType.macintosh,
       _isDemo = false,
       _imageAsset = imageAsset,
       _manifestAsset = manifestAsset,
       _assetBundle = assetBundle;

  /// The preloaded bundle containing atlas texture and manifest metadata.
  final LavaBundle? bundle;

  /// Optional playback controller. If omitted, an internal controller is created.
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

  /// Whether to automatically play the animation loop continuously.
  /// When [interactive] is true, defaults to `false` so the user can interact
  /// with the model directly via touch or drag.
  final bool? autoPlay;

  /// Whether horizontal dragging rotates the 3D model 360 degrees.
  final bool dragToRotate;

  /// Whether cursor hover tilts and tracks the 3D model toward the pointer.
  final bool scrubOnHover;

  /// Callback executed when tapped.
  final VoidCallback? onTap;

  /// Callback fired when interactive state transitions.
  final ValueChanged<LavaInteractiveState>? onStateChanged;

  /// The procedural 3D model variant when rendering demo icons.
  final LavaDemoType demoType;

  final bool _isDemo;
  final String? _imageAsset;
  final String? _manifestAsset;
  final AssetBundle? _assetBundle;

  @override
  State<LavaIcon> createState() => _LavaIconState();
}

class _LavaIconState extends State<LavaIcon>
    with TickerProviderStateMixin {
  LavaBundle? _bundle;
  // Only bundles decoded by LavaIcon.asset belong to this widget; demo
  // bundles are shared through the loader caches and injected ones belong to
  // the caller.
  bool _ownsBundle = false;
  LavaController? _internalController;
  bool _isLoading = false;
  int _loadGeneration = 0;

  LavaController get _effectiveController {
    if (widget.controller != null) return widget.controller!;
    return _internalController!;
  }

  bool get _effectiveAutoPlay {
    if (widget.autoPlay != null) return widget.autoPlay!;
    return !widget.interactive;
  }

  @override
  void initState() {
    super.initState();
    if (widget.bundle != null) {
      _setBundle(widget.bundle!);
      _initControllerIfNeeded();
    } else {
      _loadBundleAsync();
    }
  }

  void _setBundle(LavaBundle bundle, {bool owned = false}) {
    if (_ownsBundle && !identical(_bundle, bundle)) _bundle?.dispose();
    _bundle = bundle;
    _ownsBundle = owned;
  }

  @override
  void didUpdateWidget(covariant LavaIcon oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.bundle != oldWidget.bundle && widget.bundle != null) {
      _loadGeneration++;
      _setBundle(widget.bundle!);
      _initControllerIfNeeded();
    } else if (widget._isDemo && widget.demoType != oldWidget.demoType) {
      _loadBundleAsync();
    } else if (widget.controller != oldWidget.controller &&
        widget.controller != null &&
        _bundle != null) {
      _initControllerIfNeeded();
    } else if (_effectiveAutoPlay !=
        (oldWidget.autoPlay ?? !oldWidget.interactive)) {
      if (widget.controller != null) {
        if (_effectiveAutoPlay && !widget.controller!.isPlaying) {
          widget.controller!.play();
        } else if (!_effectiveAutoPlay && widget.controller!.isPlaying) {
          widget.controller!.pause();
        }
      } else if (_internalController != null) {
        if (_effectiveAutoPlay) {
          _internalController!.play();
        } else {
          _internalController!.pause();
          _internalController!.reset();
        }
      }
    }
  }

  Future<void> _loadBundleAsync() async {
    // A slower load started for a previous demo type must not overwrite this one.
    final generation = ++_loadGeneration;
    // The current bundle stays on screen until the next one is decoded.
    setState(() {
      _isLoading = _bundle == null;
    });

    try {
      final loadedBundle =
          widget._isDemo
              ? await LavaBundle.demo(
                type: widget.demoType,
                bundle: widget._assetBundle,
              )
              : await LavaBundle.fromAsset(
                imageAsset: widget._imageAsset!,
                manifestAsset: widget._manifestAsset!,
                bundle: widget._assetBundle,
              );

      if (!mounted || generation != _loadGeneration) {
        if (!widget._isDemo) loadedBundle.dispose();
        return;
      }
      setState(() {
        _setBundle(loadedBundle, owned: !widget._isDemo);
        _isLoading = false;
      });
      _initControllerIfNeeded();
    } catch (error, stackTrace) {
      // A missing or corrupt bundle leaves the placeholder box; report it
      // instead of failing silently.
      FlutterError.reportError(
        FlutterErrorDetails(
          exception: error,
          stack: stackTrace,
          library: 'lava_flutter',
          context: ErrorDescription('while loading a LavaIcon bundle'),
        ),
      );
      if (mounted && generation == _loadGeneration) {
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
        autoPlay: _effectiveAutoPlay,
        vsync: this,
      );
    } else if (widget.controller != null && _bundle != null) {
      if (!widget.controller!.isAttached) {
        widget.controller!.attach(this);
      }
      widget.controller!.configure(
        totalFrames: _bundle!.manifest.totalFrames,
        fps: _bundle!.manifest.frameRate,
        loop: _bundle!.manifest.loop,
        loopStartFrame: _bundle!.manifest.loopStartFrame,
        loopEndFrame: _bundle!.manifest.loopEndFrame,
      );
      if (widget.autoPlay == true && !widget.controller!.isPlaying) {
        widget.controller!.play();
      }
    }
  }

  @override
  void dispose() {
    _internalController?.dispose();
    if (_ownsBundle) _bundle?.dispose();
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
          images: _bundle!.images,
          compositor: _bundle!.compositor,
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
        controller: _effectiveController,
        dragToRotate: widget.dragToRotate,
        scrubOnHover: widget.scrubOnHover,
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
