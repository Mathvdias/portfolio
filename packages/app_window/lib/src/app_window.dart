import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'window_animation_mixin.dart';

class AppWindow extends StatefulWidget {
  const AppWindow({
    super.key,
    required this.title,
    required this.child,
    required this.initialPosition,
    required this.onClose,
    required this.onFocus,
    this.accentColor = const Color(0xFF89B4FA),
    this.titleBarColor = const Color(0xFF313244),
    this.contentColor = const Color(0xFF1E1E2E),
    this.borderColor = const Color(0xFF45475A),
    this.closeColor = const Color(0xFFF38BA8),
    this.minimizeColor = const Color(0xFFF9E2AF),
    this.maximizeColor = const Color(0xFFA6E3A1),
    this.width = 480.0,
    this.height = 360.0,
    this.titleBarHeight = 32.0,
    this.trafficLightSize = 12.0,
    this.trafficLightSpacing = 6.0,
    this.maximizeTopOffset = 28.0,
    this.maximizeBottomOffset = 80.0,
    this.titleFontSize = 7.0,
  });

  final String title;
  final Widget child;
  final Offset initialPosition;
  final Color accentColor;
  final Color titleBarColor;
  final Color contentColor;
  final Color borderColor;
  final Color closeColor;
  final Color minimizeColor;
  final Color maximizeColor;
  final VoidCallback onClose;
  final VoidCallback onFocus;
  final double width;
  final double height;
  final double titleBarHeight;
  final double trafficLightSize;
  final double trafficLightSpacing;
  final double maximizeTopOffset;
  final double maximizeBottomOffset;
  final double titleFontSize;

  @override
  State<AppWindow> createState() => _AppWindowState();
}

class _AppWindowState extends State<AppWindow>
    with SingleTickerProviderStateMixin, WindowAnimationMixin {
  late final ValueNotifier<Offset> _positionNotifier;
  late double _width;
  late double _height;
  late final TextStyle _titleStyle;
  bool _isMaximized = false;
  Offset? _preMaximizePosition;
  Size? _preMaximizeSize;

  @override
  void initState() {
    super.initState();
    _positionNotifier = ValueNotifier(widget.initialPosition);
    _width = widget.width;
    _height = widget.height;
    _titleStyle = GoogleFonts.pressStart2p(
      fontSize: widget.titleFontSize,
      color: const Color(0xFF9399B2),
    );
  }

  @override
  void dispose() {
    _positionNotifier.dispose();
    super.dispose();
  }

  void _toggleMaximize() {
    if (_isMaximized) {
      _positionNotifier.value = _preMaximizePosition ?? widget.initialPosition;
      setState(() {
        _width = _preMaximizeSize?.width ?? widget.width;
        _height = _preMaximizeSize?.height ?? widget.height;
        _isMaximized = false;
      });
    } else {
      _preMaximizePosition = _positionNotifier.value;
      _preMaximizeSize = Size(_width, _height);
      final mq = MediaQuery.of(context);
      _positionNotifier.value = Offset(0, widget.maximizeTopOffset);
      setState(() {
        _width = mq.size.width;
        _height =
            mq.size.height -
            widget.maximizeTopOffset -
            widget.maximizeBottomOffset;
        _isMaximized = true;
      });
    }
    widget.onFocus();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Offset>(
      valueListenable: _positionNotifier,
      builder: (context, pos, child) => Positioned(
        left: pos.dx,
        top: pos.dy,
        child: child!,
      ),
      child: GestureDetector(
        onTap: widget.onFocus,
        child: RepaintBoundary(
          child: buildAnimatedWindow(_buildWindow()),
        ),
      ),
    );
  }

  Widget _buildWindow() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
      width: _width,
      height: _height,
      decoration: BoxDecoration(
        color: widget.titleBarColor,
        border: Border.all(
          color: widget.borderColor,
          width: _isMaximized ? 0 : 2,
        ),
        boxShadow:
            _isMaximized
                ? []
                : const [
                  BoxShadow(
                    color: Colors.black54,
                    blurRadius: 24,
                    offset: Offset(6, 6),
                  ),
                ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildTitleBar(),
          Expanded(
            child: RepaintBoundary(
              child: Container(color: widget.contentColor, child: widget.child),
            ),
          ),
        ],
      ),
    );
  }

  void _closeWindow() {
    closeWithAnimation(widget.onClose);
  }

  Widget _buildTitleBar() {
    return GestureDetector(
      onDoubleTap: _toggleMaximize,
      onPanStart: (_) => widget.onFocus(),
      onPanUpdate: (details) {
        if (!_isMaximized) {
          _positionNotifier.value += details.delta;
        }
      },
      child: Container(
        height: widget.titleBarHeight,
        color: widget.titleBarColor,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Row(
          children: [
            GestureDetector(
              key: const Key('close_button'),
              onTap: _closeWindow,
              child: Container(
                width: widget.trafficLightSize,
                height: widget.trafficLightSize,
                decoration: BoxDecoration(
                  color: widget.closeColor,
                  shape: BoxShape.circle,
                ),
              ),
            ),
            SizedBox(width: widget.trafficLightSpacing),
            Container(
              width: widget.trafficLightSize,
              height: widget.trafficLightSize,
              decoration: BoxDecoration(
                color: widget.minimizeColor,
                shape: BoxShape.circle,
              ),
            ),
            SizedBox(width: widget.trafficLightSpacing),
            GestureDetector(
              onTap: _toggleMaximize,
              child: Container(
                width: widget.trafficLightSize,
                height: widget.trafficLightSize,
                decoration: BoxDecoration(
                  color: widget.maximizeColor,
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Expanded(
              child: Center(
                child: Text(
                  widget.title,
                  style: _titleStyle,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            const SizedBox(width: 42),
          ],
        ),
      ),
    );
  }
}
