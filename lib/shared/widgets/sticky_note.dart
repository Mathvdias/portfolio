import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_sizes.dart';
import '../constants/app_strings.dart';

class StickyNote extends StatefulWidget {
  const StickyNote({
    super.key,
    required this.initialPosition,
    required this.text,
    this.color = const Color(0xFFFDE68A),
  });

  final Offset initialPosition;
  final String text;
  final Color color;

  @override
  State<StickyNote> createState() => _StickyNoteState();
}

class _StickyNoteState extends State<StickyNote> {
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
        onPanUpdate: (details) {
          setState(() => _position += details.delta);
        },
        child: _NoteContainer(
          color: widget.color,
          child: Text(
            widget.text,
            style: GoogleFonts.indieFlower(
              fontSize: AppSizes.font3xl,
              color: Colors.black87,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

class VisitorStickyNote extends StatefulWidget {
  const VisitorStickyNote({
    super.key,
    required this.initialPosition,
    required this.visitorCount,
    this.color = const Color(0xFFBAE6FD),
  });

  final Offset initialPosition;
  final int visitorCount;
  final Color color;

  @override
  State<VisitorStickyNote> createState() => _VisitorStickyNoteState();
}

class _VisitorStickyNoteState extends State<VisitorStickyNote> {
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
        onPanUpdate: (details) {
          setState(() => _position += details.delta);
        },
        child: _NoteContainer(
          color: widget.color,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                AppStrings.visitorsLabel,
                style: TextStyle(
                  fontSize: AppSizes.fontBase,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                  color: Colors.black54,
                ),
              ),
              const SizedBox(height: 4),
              Expanded(
                child: Center(
                  child: Text(
                    '${widget.visitorCount}',
                    style: GoogleFonts.pressStart2p(
                      fontSize: 20,
                      color: Colors.black87,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NoteContainer extends StatelessWidget {
  const _NoteContainer({required this.color, required this.child});

  final Color color;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: AppSizes.stickyNoteSize,
      height: AppSizes.stickyNoteSize,
      padding: const EdgeInsets.all(AppSizes.spacingLg),
      decoration: BoxDecoration(
        color: color,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(2, 4),
          ),
        ],
        borderRadius: const BorderRadius.only(
          bottomRight: Radius.circular(AppSizes.radiusXxl),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: AppSizes.stickyNoteTapeHeight,
            color: Colors.black.withValues(alpha: 0.05),
            margin: const EdgeInsets.only(bottom: AppSizes.spacingMd),
          ),
          Expanded(child: child),
        ],
      ),
    );
  }
}
