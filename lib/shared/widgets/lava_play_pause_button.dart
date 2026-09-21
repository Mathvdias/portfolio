import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lava_flutter/lava_flutter.dart';

import '../../theme/app_theme.dart';

/// Play / pause key rendered by the Lava engine.
///
/// The icon is a control, not a loop: its frames are three segments this
/// widget plays on demand (the `PlayPause` scene in
/// `packages/lava_flutter/tool/sdf_scenes.py` is the source of truth for the
/// layout, see the frame constants below). Paused, it rests on the unlit play
/// glyph; pressed, the key sinks while the glyph morphs into lit pause bars,
/// which then breathe for as long as [playing] stays true.
///
/// The widget is controlled: it never flips by itself, [onPressed] asks the
/// owner to change [playing].
class LavaPlayPauseButton extends StatefulWidget {
  const LavaPlayPauseButton({
    super.key,
    required this.playing,
    required this.onPressed,
    this.size = 84,
    this.playTooltip,
    this.pauseTooltip,
    this.assetBundle,
  });

  /// Whether the thing this key drives is playing (the key then shows the
  /// lit pause bars).
  final bool playing;

  /// Called on tap, Enter and Space.
  final VoidCallback onPressed;

  /// Painted width. The height follows the 180:162 canvas, and the key itself
  /// covers about two thirds of it (84 gives a 56 px key). The tap target
  /// never gets smaller than [minTapTarget].
  final double size;

  /// Tooltip and semantics label while paused (the action is "play").
  final String? playTooltip;

  /// Tooltip and semantics label while playing (the action is "pause").
  final String? pauseTooltip;

  /// Where the bundle is read from (defaults to the root bundle).
  final AssetBundle? assetBundle;

  /// OpenLava directory of the key.
  static const String assetPath = 'assets/lava/playpause';

  /// Frames in the bundle (`sum(PlayPause.SEGMENTS)` in the tool scene).
  static const int frameCount = 48;

  /// Playback rate the scene was rendered for.
  static const int fps = 30;

  /// Last frame of "to pause" (0..13): frame 0 is the unlit play glyph, this
  /// one the lit pause bars.
  static const int toPauseEnd = 13;

  /// First frame of "playing" (14..33), the breathing loop. Same picture as
  /// [toPauseEnd].
  static const int playingStart = 14;

  /// Last frame of "playing".
  static const int playingEnd = 33;

  /// First frame of "to play" (34..47): "to pause" backwards, frame for frame.
  static const int toPlayStart = 34;

  /// Last frame of the bundle, the same picture as frame 0. Frame `f` of one
  /// transition shows what frame `lastFrame - f` of the other one does, which
  /// is how a toggle in the middle of a transition turns round without a jump.
  static const int lastFrame = frameCount - 1;

  /// Smallest tap target, whatever the [size].
  static const double minTapTarget = 48;

  @override
  State<LavaPlayPauseButton> createState() => _LavaPlayPauseButtonState();
}

class _LavaPlayPauseButtonState extends State<LavaPlayPauseButton>
    with SingleTickerProviderStateMixin {
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

  final LavaController _controller = LavaController(
    totalFrames: LavaPlayPauseButton.frameCount,
    fps: LavaPlayPauseButton.fps,
    loop: false,
    autoPlay: false,
  );
  LavaBundle? _bundle;
  bool _reduceMotion = false;
  bool _hovered = false;
  bool _pressed = false;
  bool _focusRing = false;

  @override
  void initState() {
    super.initState();
    _controller.attach(this);
    _load();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    if (reduceMotion == _reduceMotion) return;
    _reduceMotion = reduceMotion;
    _rest();
  }

  @override
  void didUpdateWidget(covariant LavaPlayPauseButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Owners rebuild for their own reasons: only a real toggle may restart
    // the key.
    if (widget.playing != oldWidget.playing) _toggle();
  }

  @override
  void dispose() {
    _controller.dispose();
    _bundle?.release();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final loaded = await LavaBundle.openLavaAsset(
        assetPath: LavaPlayPauseButton.assetPath,
        bundle: widget.assetBundle,
      );
      // Decoded bundles are shared and reference counted: one that arrives
      // after this key left the tree was never taken, so there is nothing to
      // give back.
      if (!mounted) return;
      loaded.retain();
      setState(() => _bundle = loaded);
      _rest();
    } catch (error, stackTrace) {
      // The Material fallback stays on screen and keeps working; say why.
      FlutterError.reportError(
        FlutterErrorDetails(
          exception: error,
          stack: stackTrace,
          library: 'portifolio',
          context: ErrorDescription('while loading the play / pause Lava key'),
        ),
      );
    }
  }

  /// The textures of an evicted bundle are gone: it must not be painted.
  LavaBundle? get _liveBundle => (_bundle?.isDisposed ?? true) ? null : _bundle;

  /// Shows [LavaPlayPauseButton.playing] without a transition: the first
  /// picture, and every picture under reduced motion.
  void _rest() {
    if (_bundle == null) return;
    if (widget.playing && !_reduceMotion) {
      _run(loop: true, from: LavaPlayPauseButton.playingStart);
      return;
    }
    _controller.pause();
    _controller.seekToFrame(
      widget.playing ? LavaPlayPauseButton.playingStart : 0,
    );
  }

  void _toggle() {
    if (_bundle == null) return;
    if (_reduceMotion) {
      _rest();
      return;
    }
    // A transition still in flight turns round on its mirrored frame; a key at
    // rest starts the transition from its first frame.
    final frame = _controller.currentFrame;
    final mirrored = LavaPlayPauseButton.lastFrame - frame;
    if (widget.playing) {
      final inToPlay = frame >= LavaPlayPauseButton.toPlayStart;
      _run(loop: true, from: inToPlay ? mirrored : 0);
    } else {
      final inToPause = frame <= LavaPlayPauseButton.toPauseEnd;
      _run(
        loop: false,
        from: inToPause ? mirrored : LavaPlayPauseButton.toPlayStart,
      );
    }
  }

  /// Looping, the controller runs "to pause" as an intro and then wraps inside
  /// the playing segment by itself; not looping, it completes on the last
  /// frame and stops its ticker.
  void _run({required bool loop, required int from}) {
    // Paused first: play() rewinds a run that completed.
    _controller.pause();
    _controller.configure(
      totalFrames: LavaPlayPauseButton.frameCount,
      loop: loop,
      loopStartFrame: loop ? LavaPlayPauseButton.playingStart : null,
      loopEndFrame: loop ? LavaPlayPauseButton.playingEnd : null,
    );
    _controller.seekToFrame(from);
    _controller.play();
  }

  Object? _activate(Intent _) {
    widget.onPressed();
    return null;
  }

  void _setPressed(bool pressed) => setState(() => _pressed = pressed);

  Widget _buildFallback(double diameter) {
    return Container(
      width: diameter,
      height: diameter,
      decoration: const BoxDecoration(
        color: AppTheme.peach,
        shape: BoxShape.circle,
      ),
      child: Icon(
        widget.playing ? Icons.pause : Icons.play_arrow,
        size: diameter * 0.46,
        color: AppTheme.background,
      ),
    );
  }

  Widget _buildKey(LavaBundle bundle, Size canvas) {
    return RepaintBoundary(
      child: CustomPaint(
        size: canvas,
        painter: LavaPainter(
          images: bundle.images,
          compositor: bundle.compositor,
          manifest: bundle.manifest,
          controller: _controller,
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
    final label = widget.playing ? widget.pauseTooltip : widget.playTooltip;

    var scale = 1.0;
    if (!_reduceMotion) {
      if (_pressed) {
        scale = 0.94;
      } else if (_hovered) {
        scale = 1.06;
      }
    }

    final Widget face;
    if (bundle == null) {
      face = Align(alignment: _keyCentre, child: _buildFallback(diameter));
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
          width: math.max(LavaPlayPauseButton.minTapTarget, canvas.width),
          height: math.max(
            LavaPlayPauseButton.minTapTarget,
            canvas.height + topInset,
          ),
          child: Center(
            child: Padding(
              padding: EdgeInsets.only(top: topInset),
              child: ExcludeSemantics(child: art),
            ),
          ),
        ),
      ),
    );

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
