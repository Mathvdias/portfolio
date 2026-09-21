import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lava_flutter/lava_flutter.dart';

import '../../theme/app_theme.dart';

/// A round key rendered by the Lava engine: the body shared by the transport
/// controls (the `LavaKey` scene in `packages/lava_flutter/tool/sdf_scenes.py`).
///
/// It loads the OpenLava bundle at [assetPath], paints the frame [controller]
/// is on and behaves like a button: tap, Enter and Space, hover and press
/// feedback, focus ring, tooltip and one semantics node. What the frames mean
/// is the owner's business: it drives [controller] and hears from
/// [onBundleReady] when there is something to show.
///
/// Until the bundle is decoded, and if that fails, [fallback] is shown in the
/// key's place with the same footprint, so nothing moves when the key arrives.
class LavaKey extends StatefulWidget {
  const LavaKey({
    super.key,
    required this.assetPath,
    required this.controller,
    required this.onPressed,
    required this.fallback,
    required this.errorContext,
    this.size = 84,
    this.label,
    this.assetBundle,
    this.onBundleReady,
  });

  /// OpenLava directory of the key.
  final String assetPath;

  /// Playhead of the key, owned and driven by the widget that uses this one.
  final LavaController controller;

  /// Called on tap, Enter and Space.
  final VoidCallback onPressed;

  /// Stand-in drawn inside the key's circle, given its diameter.
  final Widget Function(BuildContext context, double diameter) fallback;

  /// What was being loaded, for the error report of a bundle that fails.
  final String errorContext;

  /// Painted width. The height follows the 180:162 canvas, and the key itself
  /// covers about two thirds of it (84 gives a 56 px key). The tap target
  /// never gets smaller than [minTapTarget].
  final double size;

  /// Tooltip and semantics label: the action a press performs.
  final String? label;

  /// Where the bundle is read from (defaults to the root bundle).
  final AssetBundle? assetBundle;

  /// The bundle is decoded and on screen: [controller] now decides the picture.
  final VoidCallback? onBundleReady;

  /// Smallest tap target, whatever the [size].
  static const double minTapTarget = 48;

  @override
  State<LavaKey> createState() => _LavaKeyState();
}

class _LavaKeyState extends State<LavaKey> {
  // Where the key sits in the 180x162 canvas (opaque bounds of the bezel; the
  // rest is its contact shadow): centre as a fraction of the canvas, diameter
  // as a fraction of the width.
  static const _keyCentre = Alignment(0.006, -0.154);
  static const _keyDiameter = 0.672;
  static const _canvasAspect = 162 / 180;

  static const _shortcuts = <ShortcutActivator, Intent>{
    SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(),
    SingleActivator(LogicalKeyboardKey.space): ActivateIntent(),
  };

  LavaBundle? _bundle;
  bool _hovered = false;
  bool _pressed = false;
  bool _focusRing = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _bundle?.release();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final loaded = await LavaBundle.openLavaAsset(
        assetPath: widget.assetPath,
        bundle: widget.assetBundle,
      );
      // Decoded bundles are shared and reference counted: one that arrives
      // after this key left the tree was never taken, so there is nothing to
      // give back.
      if (!mounted) return;
      loaded.retain();
      setState(() => _bundle = loaded);
      widget.onBundleReady?.call();
    } catch (error, stackTrace) {
      // The fallback stays on screen and keeps working; say why.
      FlutterError.reportError(
        FlutterErrorDetails(
          exception: error,
          stack: stackTrace,
          library: 'portifolio',
          context: ErrorDescription(widget.errorContext),
        ),
      );
    }
  }

  /// The textures of an evicted bundle are gone: it must not be painted.
  LavaBundle? get _liveBundle => (_bundle?.isDisposed ?? true) ? null : _bundle;

  Object? _activate(Intent _) {
    widget.onPressed();
    return null;
  }

  void _setPressed(bool pressed) => setState(() => _pressed = pressed);

  Widget _buildKey(LavaBundle bundle, Size canvas) {
    return RepaintBoundary(
      child: CustomPaint(
        size: canvas,
        painter: LavaPainter(
          images: bundle.images,
          compositor: bundle.compositor,
          manifest: bundle.manifest,
          controller: widget.controller,
          filterQuality: FilterQuality.medium,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final canvas = Size(widget.size, widget.size * _canvasAspect);
    final diameter = widget.size * _keyDiameter;
    // The key sits above the middle of its canvas (the shadow is underneath):
    // padding the top by the difference puts the key, not the canvas, on the
    // centre line of whatever row this button is in.
    final topInset = -_keyCentre.y * canvas.height;
    final bundle = _liveBundle;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);

    var scale = 1.0;
    if (!reduceMotion) {
      if (_pressed) {
        scale = 0.94;
      } else if (_hovered) {
        scale = 1.06;
      }
    }

    final Widget face;
    if (bundle == null) {
      face = Align(
        alignment: _keyCentre,
        child: SizedBox.square(
          dimension: diameter,
          child: widget.fallback(context, diameter),
        ),
      );
    } else {
      face = _buildKey(bundle, canvas);
    }

    final ringColour = _focusRing ? AppTheme.teal : Colors.transparent;
    final art = SizedBox.fromSize(
      size: canvas,
      child: Stack(
        fit: StackFit.expand,
        children: [
          AnimatedScale(
            scale: scale,
            alignment: _keyCentre,
            duration: const Duration(milliseconds: 120),
            curve: Curves.easeOut,
            child: face,
          ),
          Align(
            alignment: _keyCentre,
            child: IgnorePointer(
              child: Container(
                width: diameter + 10,
                height: diameter + 10,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: ringColour, width: 2),
                ),
              ),
            ),
          ),
        ],
      ),
    );

    Widget button = FocusableActionDetector(
      mouseCursor: SystemMouseCursors.click,
      shortcuts: _shortcuts,
      actions: {
        ActivateIntent: CallbackAction<ActivateIntent>(onInvoke: _activate),
      },
      onShowHoverHighlight: (value) => setState(() => _hovered = value),
      onShowFocusHighlight: (value) => setState(() => _focusRing = value),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        excludeFromSemantics: true,
        onTap: widget.onPressed,
        onTapDown: (_) => _setPressed(true),
        onTapUp: (_) => _setPressed(false),
        onTapCancel: () => _setPressed(false),
        child: SizedBox(
          width: math.max(LavaKey.minTapTarget, canvas.width),
          height: math.max(LavaKey.minTapTarget, canvas.height + topInset),
          child: Center(
            child: Padding(
              padding: EdgeInsets.only(top: topInset),
              child: ExcludeSemantics(child: art),
            ),
          ),
        ),
      ),
    );

    final label = widget.label;
    if (label != null) {
      button = Tooltip(
        message: label,
        excludeFromSemantics: true,
        child: button,
      );
    }

    return Semantics(
      container: true,
      button: true,
      label: label,
      onTap: widget.onPressed,
      child: button,
    );
  }
}
