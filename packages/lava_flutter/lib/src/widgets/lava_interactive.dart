import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../model/lava_types.dart';

/// Wraps a widget with tactile 3D perspective tilt and spring compression
/// physics inspired by modern micro-interaction standards.
class LavaInteractive extends StatefulWidget {
  const LavaInteractive({
    super.key,
    required this.child,
    this.maxTiltAngle = 0.26,
    this.pressedScale = 0.92,
    this.returnDuration = const Duration(milliseconds: 250),
    this.bounceDuration = const Duration(milliseconds: 350),
    this.perspective = 0.0015,
    this.enableTilt = true,
    this.enableBounce = true,
    this.enableHaptics = true,
    this.onTap,
    this.onStateChanged,
  });

  /// The child widget to transform.
  final Widget child;

  /// Maximum angular rotation in radians during hover tilt.
  final double maxTiltAngle;

  /// Scale factor applied while the user is actively pressing.
  final double pressedScale;

  /// Duration to return tilt to origin when pointer exits.
  final Duration returnDuration;

  /// Duration of the elastic spring release animation.
  final Duration bounceDuration;

  /// Depth coefficient applied to the 3D projection matrix.
  final double perspective;

  /// Whether pointer hover tilts the 3D perspective.
  final bool enableTilt;

  /// Whether tap interactions produce elastic scale bounce.
  final bool enableBounce;

  /// Whether to invoke light haptic feedback on touch down.
  final bool enableHaptics;

  /// Callback fired when the interactive surface is tapped.
  final VoidCallback? onTap;

  /// Callback fired when [LavaInteractiveState] transitions.
  final ValueChanged<LavaInteractiveState>? onStateChanged;

  @override
  State<LavaInteractive> createState() => _LavaInteractiveState();
}

class _LavaInteractiveState extends State<LavaInteractive>
    with TickerProviderStateMixin {
  late final AnimationController _bounceController;
  late final Animation<double> _scaleAnimation;

  late final AnimationController _tiltReturnController;
  Animation<Offset>? _tiltReturnAnimation;

  Offset _currentTilt = Offset.zero;
  bool _isHovered = false;
  LavaInteractiveState _state = LavaInteractiveState.idle;

  @override
  void initState() {
    super.initState();

    _bounceController = AnimationController(
      vsync: this,
      duration: widget.bounceDuration,
      value: 1.0,
    );

    _scaleAnimation = CurvedAnimation(
      parent: _bounceController,
      curve: Curves.easeOutBack,
    );

    _tiltReturnController = AnimationController(
      vsync: this,
      duration: widget.returnDuration,
    )..addListener(() {
      if (_tiltReturnAnimation != null) {
        setState(() {
          _currentTilt = _tiltReturnAnimation!.value;
        });
      }
    });
  }

  @override
  void dispose() {
    _bounceController.dispose();
    _tiltReturnController.dispose();
    super.dispose();
  }

  void _updateState(LavaInteractiveState newState) {
    if (_state != newState) {
      _state = newState;
      widget.onStateChanged?.call(newState);
    }
  }

  void _onPointerHover(PointerHoverEvent event, BoxConstraints constraints) {
    if (!widget.enableTilt ||
        constraints.maxWidth == 0 ||
        constraints.maxHeight == 0) {
      return;
    }

    final localPos = event.localPosition;
    final normalizedX = ((localPos.dx / constraints.maxWidth) * 2.0 - 1.0)
        .clamp(-1.0, 1.0);
    final normalizedY = ((localPos.dy / constraints.maxHeight) * 2.0 - 1.0)
        .clamp(-1.0, 1.0);

    setState(() {
      _currentTilt = Offset(normalizedX, normalizedY);
    });
  }

  void _onPointerEnter(PointerEnterEvent event) {
    _isHovered = true;
    _tiltReturnController.stop();
    _updateState(LavaInteractiveState.hover);
  }

  void _onPointerExit(PointerExitEvent event) {
    _isHovered = false;
    _updateState(LavaInteractiveState.idle);

    if (widget.enableTilt && _currentTilt != Offset.zero) {
      _tiltReturnAnimation = Tween<Offset>(
        begin: _currentTilt,
        end: Offset.zero,
      ).animate(
        CurvedAnimation(
          parent: _tiltReturnController,
          curve: Curves.easeOutCubic,
        ),
      );
      _tiltReturnController.forward(from: 0.0);
    }
  }

  void _onTapDown(TapDownDetails details) {
    _updateState(LavaInteractiveState.pressed);

    if (widget.enableHaptics) {
      HapticFeedback.lightImpact();
    }

    if (widget.enableBounce) {
      _bounceController.animateTo(
        widget.pressedScale,
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeOut,
      );
    }
  }

  void _onTapUp(TapUpDetails details) {
    _handleRelease();
    widget.onTap?.call();
  }

  void _onTapCancel() {
    _handleRelease();
  }

  void _handleRelease() {
    _updateState(
      _isHovered ? LavaInteractiveState.hover : LavaInteractiveState.idle,
    );

    if (widget.enableBounce) {
      _bounceController.animateTo(
        1.0,
        duration: widget.bounceDuration,
        curve: Curves.elasticOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return MouseRegion(
          onEnter: _onPointerEnter,
          onHover: (e) => _onPointerHover(e, constraints),
          onExit: _onPointerExit,
          cursor:
              widget.onTap != null
                  ? SystemMouseCursors.click
                  : MouseCursor.defer,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapDown: _onTapDown,
            onTapUp: _onTapUp,
            onTapCancel: _onTapCancel,
            child: AnimatedBuilder(
              animation: _scaleAnimation,
              builder: (context, child) {
                final tiltX =
                    widget.enableTilt
                        ? -_currentTilt.dy * widget.maxTiltAngle
                        : 0.0;
                final tiltY =
                    widget.enableTilt
                        ? _currentTilt.dx * widget.maxTiltAngle
                        : 0.0;

                final s = _scaleAnimation.value;
                final matrix =
                    Matrix4.identity()
                      ..setEntry(3, 2, widget.perspective)
                      ..rotateX(tiltX)
                      ..rotateY(tiltY)
                      ..scaleByDouble(s, s, 1.0, 1.0);

                return Transform(
                  transform: matrix,
                  alignment: Alignment.center,
                  child: child,
                );
              },
              child: widget.child,
            ),
          ),
        );
      },
    );
  }
}
