import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

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
              fontSize: 16,
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
                'VISITORS',
                style: TextStyle(
                  fontSize: 10,
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
      width: 140,
      height: 140,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(2, 4),
          ),
        ],
        borderRadius: const BorderRadius.only(bottomRight: Radius.circular(16)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 10,
            color: Colors.black.withValues(alpha: 0.05),
            margin: const EdgeInsets.only(bottom: 8),
          ),
          Expanded(child: child),
        ],
      ),
    );
  }
}
