import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

const _kCols = 22;
const _kRows = 16;
const _kTickMs = 140;

enum _Dir { up, down, left, right }

typedef _Pos = ({int x, int y});

_Pos _move(_Pos p, _Dir d) => switch (d) {
  _Dir.up => (x: p.x, y: (p.y - 1 + _kRows) % _kRows),
  _Dir.down => (x: p.x, y: (p.y + 1) % _kRows),
  _Dir.left => (x: (p.x - 1 + _kCols) % _kCols, y: p.y),
  _Dir.right => (x: (p.x + 1) % _kCols, y: p.y),
};

class SnakeGameContent extends StatefulWidget {
  const SnakeGameContent({super.key});

  @override
  State<SnakeGameContent> createState() => _SnakeGameContentState();
}

class _SnakeGameContentState extends State<SnakeGameContent> {
  List<_Pos> _snake = [];
  _Dir _dir = _Dir.right;
  _Dir _nextDir = _Dir.right;
  _Pos _food = (x: 5, y: 5);
  int _score = 0;
  bool _running = false;
  bool _gameOver = false;
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _start() {
    _timer?.cancel();
    final center = (x: _kCols ~/ 2, y: _kRows ~/ 2);
    setState(() {
      _snake = [
        center,
        (x: center.x - 1, y: center.y),
        (x: center.x - 2, y: center.y),
      ];
      _dir = _Dir.right;
      _nextDir = _Dir.right;
      _score = 0;
      _gameOver = false;
      _running = true;
    });
    _spawnFood();
    _timer = Timer.periodic(const Duration(milliseconds: _kTickMs), _tick);
  }

  void _spawnFood() {
    final rng = Random();
    _Pos f;
    do {
      f = (x: rng.nextInt(_kCols), y: rng.nextInt(_kRows));
    } while (_snake.any((p) => p.x == f.x && p.y == f.y));
    setState(() => _food = f);
  }

  void _tick(Timer _) {
    if (_gameOver) return;
    setState(() {
      _dir = _nextDir;
      final newHead = _move(_snake.first, _dir);
      if (_snake.any((p) => p.x == newHead.x && p.y == newHead.y)) {
        _gameOver = true;
        _running = false;
        _timer?.cancel();
        return;
      }
      final ate = newHead.x == _food.x && newHead.y == _food.y;
      _snake = [
        newHead,
        ..._snake.sublist(0, ate ? _snake.length : _snake.length - 1),
      ];
      if (ate) {
        _score++;
        _spawnFood();
      }
    });
  }

  KeyEventResult _onKey(FocusNode _, KeyEvent e) {
    if (e is! KeyDownEvent) return KeyEventResult.ignored;
    switch (e.logicalKey) {
      case LogicalKeyboardKey.arrowUp:
      case LogicalKeyboardKey.keyW:
        if (_dir != _Dir.down) _nextDir = _Dir.up;
      case LogicalKeyboardKey.arrowDown:
      case LogicalKeyboardKey.keyS:
        if (_dir != _Dir.up) _nextDir = _Dir.down;
      case LogicalKeyboardKey.arrowLeft:
      case LogicalKeyboardKey.keyA:
        if (_dir != _Dir.right) _nextDir = _Dir.left;
      case LogicalKeyboardKey.arrowRight:
      case LogicalKeyboardKey.keyD:
        if (_dir != _Dir.left) _nextDir = _Dir.right;
      case LogicalKeyboardKey.enter:
      case LogicalKeyboardKey.space:
        if (!_running || _gameOver) _start();
      default:
        return KeyEventResult.ignored;
    }
    return KeyEventResult.handled;
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      autofocus: true,
      onKeyEvent: _onKey,
      child: Container(
        color: AppTheme.background,
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            // Score bar
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'SCORE: $_score',
                    style: GoogleFonts.pressStart2p(
                      fontSize: 9,
                      color: AppTheme.yellow,
                    ),
                  ),
                  Text(
                    _running ? 'WASD / ↑↓←→' : 'PRESS ENTER',
                    style: GoogleFonts.pressStart2p(
                      fontSize: 7,
                      color: AppTheme.subtext,
                    ),
                  ),
                ],
              ),
            ),
            // Game grid
            Expanded(
              child: AspectRatio(
                aspectRatio: _kCols / _kRows,
                child:
                    _running || _gameOver
                        ? CustomPaint(
                          painter: _SnakePainter(
                            snake: _snake,
                            food: _food,
                            cols: _kCols,
                            rows: _kRows,
                            gameOver: _gameOver,
                          ),
                        )
                        : _StartScreen(onStart: _start),
              ),
            ),
            if (_gameOver)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Column(
                  children: [
                    Text(
                      'GAME OVER  •  SCORE: $_score',
                      style: GoogleFonts.pressStart2p(
                        fontSize: 9,
                        color: AppTheme.red,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: _start,
                      child: Text(
                        '[ PLAY AGAIN ]',
                        style: GoogleFonts.pressStart2p(
                          fontSize: 8,
                          color: AppTheme.green,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _StartScreen extends StatelessWidget {
  const _StartScreen({required this.onStart});
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onStart,
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: AppTheme.surface0, width: 1),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'SNAKE',
                style: GoogleFonts.pressStart2p(
                  fontSize: 20,
                  color: AppTheme.green,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'press ENTER or tap to start',
                style: GoogleFonts.pressStart2p(
                  fontSize: 7,
                  color: AppTheme.subtext,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'use WASD or arrow keys',
                style: GoogleFonts.pressStart2p(
                  fontSize: 7,
                  color: AppTheme.subtext,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SnakePainter extends CustomPainter {
  final List<_Pos> snake;
  final _Pos food;
  final int cols;
  final int rows;
  final bool gameOver;

  const _SnakePainter({
    required this.snake,
    required this.food,
    required this.cols,
    required this.rows,
    required this.gameOver,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cw = size.width / cols;
    final ch = size.height / rows;

    // grid
    final gridPaint =
        Paint()
          ..color = AppTheme.surface0.withValues(alpha: 0.25)
          ..strokeWidth = 0.5;
    for (int r = 0; r <= rows; r++) {
      canvas.drawLine(Offset(0, r * ch), Offset(size.width, r * ch), gridPaint);
    }
    for (int c = 0; c <= cols; c++) {
      canvas.drawLine(
        Offset(c * cw, 0),
        Offset(c * cw, size.height),
        gridPaint,
      );
    }

    // food (blinking red square)
    canvas.drawRect(
      Rect.fromLTWH(food.x * cw + 2, food.y * ch + 2, cw - 4, ch - 4),
      Paint()..color = AppTheme.red,
    );

    // snake body
    final bodyColor = gameOver ? AppTheme.subtext : AppTheme.teal;
    final headColor = gameOver ? AppTheme.red : AppTheme.green;
    for (int i = snake.length - 1; i >= 0; i--) {
      final p = snake[i];
      canvas.drawRect(
        Rect.fromLTWH(p.x * cw + 1, p.y * ch + 1, cw - 2, ch - 2),
        Paint()..color = i == 0 ? headColor : bodyColor,
      );
    }
  }

  @override
  bool shouldRepaint(_SnakePainter old) => true;
}
