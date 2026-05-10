import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

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

  @override
  State<AppWindow> createState() => _AppWindowState();
}

class _AppWindowState extends State<AppWindow> {
  late Offset _position;

  @override
  void initState() {
    super.initState();
    _position = widget.initialPosition;
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: _position.dx,
      top: _position.dy,
      child: GestureDetector(
        onTap: widget.onFocus,
        onPanStart: (_) => widget.onFocus(),
        child: _buildWindow(),
      ),
    );
  }

  Widget _buildWindow() {
    return Container(
      width: widget.width,
      height: widget.height,
      decoration: BoxDecoration(
        color: widget.titleBarColor,
        border: Border.all(color: widget.borderColor, width: 2),
        boxShadow: const [
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
            child: Container(color: widget.contentColor, child: widget.child),
          ),
        ],
      ),
    );
  }

  Widget _buildTitleBar() {
    return GestureDetector(
      onPanUpdate: (details) {
        setState(() => _position += details.delta);
      },
      child: Container(
        height: 32,
        color: widget.titleBarColor,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Row(
          children: [
            GestureDetector(
              key: const Key('close_button'),
              onTap: widget.onClose,
              child: Container(
                width: 12,
                height: 12,
                color: widget.closeColor,
              ),
            ),
            const SizedBox(width: 6),
            Container(
              width: 12,
              height: 12,
              color: widget.minimizeColor,
            ),
            const SizedBox(width: 6),
            Container(
              width: 12,
              height: 12,
              color: widget.maximizeColor,
            ),
            Expanded(
              child: Center(
                child: Text(
                  widget.title,
                  style: GoogleFonts.pressStart2p(
                    fontSize: 7,
                    color: const Color(0xFF9399B2),
                  ),
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
