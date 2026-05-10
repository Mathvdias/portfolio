import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

class AppWindow extends StatefulWidget {
  const AppWindow({
    super.key,
    required this.title,
    required this.child,
    required this.initialPosition,
    required this.onClose,
    required this.onFocus,
    this.accentColor = AppTheme.blue,
    this.width = 480.0,
    this.height = 360.0,
  });

  final String title;
  final Widget child;
  final Offset initialPosition;
  final Color accentColor;
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
        color: AppTheme.surface,
        border: Border.all(color: AppTheme.surface0, width: 2),
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
            child: Container(color: AppTheme.background, child: widget.child),
          ),
        ],
      ),
    );
  }

  Widget _buildTitleBar() {
    return GestureDetector(
      onPanUpdate: (details) {
        setState(() {
          _position += details.delta;
        });
      },
      child: Container(
        height: 32,
        color: AppTheme.surface,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Row(
          children: [
            // Traffic lights
            GestureDetector(
              key: const Key('close_button'),
              onTap: widget.onClose,
              child: Container(width: 12, height: 12, color: AppTheme.red),
            ),
            const SizedBox(width: 6),
            Container(width: 12, height: 12, color: AppTheme.yellow),
            const SizedBox(width: 6),
            Container(width: 12, height: 12, color: AppTheme.green),
            // Centered title
            Expanded(
              child: Center(
                child: Text(
                  widget.title,
                  style: GoogleFonts.pressStart2p(
                    fontSize: 7,
                    color: AppTheme.subtext,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            // Balance the traffic lights on the right
            const SizedBox(width: 42),
          ],
        ),
      ),
    );
  }
}
