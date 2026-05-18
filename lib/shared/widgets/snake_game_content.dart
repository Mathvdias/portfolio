import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';
import '../constants/app_sizes.dart';
import '../constants/app_strings.dart';

const _kCols = AppSizes.snakeCols;
const _kRows = AppSizes.snakeRows;
const _kTickMs = AppSizes.snakeTickMs;

enum _Dir { up, down, left, right }

typedef _Pos = ({int x, int y});

_Pos _move(_Pos p, _Dir d) => switch (d) {
  _Dir.up => (x: p.x, y: (p.y - 1 + _kRows) % _kRows),
  _Dir.down => (x: p.x, y: (p.y + 1) % _kRows),
  _Dir.left => (x: (p.x - 1 + _kCols) % _kCols, y: p.y),
  _Dir.right => (x: (p.x + 1) % _kCols, y: p.y),
};

class _GameState {
  const _GameState({
    required this.snake,
    required this.food,
    required this.score,
    required this.running,
    required this.gameOver,
  });

  final List<_Pos> snake;
  final _Pos food;
  final int score;
  final bool running;
  final bool gameOver;
}

class SnakeGameContent extends StatefulWidget {
  const SnakeGameContent({super.key, this.randomSeed});

  final int? randomSeed;

  @override
  State<SnakeGameContent> createState() => _SnakeGameContentState();
}

class _SnakeGameContentState extends State<SnakeGameContent> {
  final FocusNode _focusNode = FocusNode();
  late final Random _rng;
  late final ValueNotifier<_GameState> _state;
  _Dir _dir = _Dir.right;
  _Dir _nextDir = _Dir.right;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _rng = widget.randomSeed != null ? Random(widget.randomSeed!) : Random();
    _state = ValueNotifier(
      const _GameState(
        snake: [],
        food: (x: 5, y: 5),
        score: 0,
        running: false,
        gameOver: false,
      ),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _focusNode.dispose();
    _state.dispose();
    super.dispose();
  }

  void _start() {
    _timer?.cancel();
    final center = (x: _kCols ~/ 2, y: _kRows ~/ 2);
    final snake = [
      center,
      (x: center.x - 1, y: center.y),
      (x: center.x - 2, y: center.y),
    ];
    _dir = _Dir.right;
    _nextDir = _Dir.right;
    _state.value = _GameState(
      snake: snake,
      food: _spawnFood(snake),
      score: 0,
      running: true,
      gameOver: false,
    );
    _timer = Timer.periodic(const Duration(milliseconds: _kTickMs), _tick);
  }

  _Pos _spawnFood(List<_Pos> snake) {
    _Pos f;
    do {
      f = (x: _rng.nextInt(_kCols), y: _rng.nextInt(_kRows));
    } while (snake.any((p) => p.x == f.x && p.y == f.y));
    return f;
  }

  void _tick(Timer _) {
    final s = _state.value;
    if (s.gameOver) return;
    _dir = _nextDir;
    final newHead = _move(s.snake.first, _dir);
    if (s.snake.any((p) => p.x == newHead.x && p.y == newHead.y)) {
      _timer?.cancel();
      _state.value = _GameState(
        snake: s.snake,
        food: s.food,
        score: s.score,
        running: false,
        gameOver: true,
      );
      return;
    }
    final ate = newHead.x == s.food.x && newHead.y == s.food.y;
    final newSnake = [
      newHead,
      ...s.snake.sublist(0, ate ? s.snake.length : s.snake.length - 1),
    ];
    _state.value = _GameState(
      snake: newSnake,
      food: ate ? _spawnFood(newSnake) : s.food,
      score: ate ? s.score + 1 : s.score,
      running: true,
      gameOver: false,
    );
  }

  KeyEventResult _onKey(FocusNode _, KeyEvent e) {
    if (e is! KeyDownEvent) return KeyEventResult.ignored;
    switch (e.logicalKey) {
      case LogicalKeyboardKey.arrowUp:
      case LogicalKeyboardKey.keyW:
        if (_dir != _Dir.down) _nextDir = _Dir.up;
        return KeyEventResult.handled;
      case LogicalKeyboardKey.arrowDown:
      case LogicalKeyboardKey.keyS:
        if (_dir != _Dir.up) _nextDir = _Dir.down;
        return KeyEventResult.handled;
      case LogicalKeyboardKey.arrowLeft:
      case LogicalKeyboardKey.keyA:
        if (_dir != _Dir.right) _nextDir = _Dir.left;
        return KeyEventResult.handled;
      case LogicalKeyboardKey.arrowRight:
      case LogicalKeyboardKey.keyD:
        if (_dir != _Dir.left) _nextDir = _Dir.right;
        return KeyEventResult.handled;
      case LogicalKeyboardKey.enter:
      case LogicalKeyboardKey.space:
        final s = _state.value;
        if (!s.running || s.gameOver) _start();
        return KeyEventResult.handled;
      default:
        return KeyEventResult.ignored;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      focusNode: _focusNode,
      autofocus: true,
      onKeyEvent: _onKey,
      child: GestureDetector(
        onTap: () => _focusNode.requestFocus(),
        child: Container(
          color: AppTheme.background,
          padding: const EdgeInsets.all(AppSizes.spacingLg),
          child: Column(
            children: [
              // Score bar
              ValueListenableBuilder<_GameState>(
                valueListenable: _state,
                builder:
                    (_, s, __) => Padding(
                      padding: const EdgeInsets.only(
                        bottom: AppSizes.spacingMd,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'SCORE: ${s.score}',
                            style: GoogleFonts.pressStart2p(
                              fontSize: AppSizes.fontMd,
                              color: AppTheme.yellow,
                            ),
                          ),
                          Text(
                            s.running ? 'WASD / ↑↓←→' : 'PRESS ENTER',
                            style: GoogleFonts.pressStart2p(
                              fontSize: AppSizes.fontXs,
                              color: AppTheme.subtext,
                            ),
                          ),
                        ],
                      ),
                    ),
              ),
              // Game canvas — CustomPainter.repaint drives paint() directly,
              // child is built once so _SnakePainter is never recreated mid-game.
              Expanded(
                child: AspectRatio(
                  aspectRatio: _kCols / _kRows,
                  child: ValueListenableBuilder<_GameState>(
                    valueListenable: _state,
                    child: RepaintBoundary(
                      child: CustomPaint(painter: _SnakePainter(_state)),
                    ),
                    builder:
                        (_, s, gameCanvas) =>
                            (s.running || s.gameOver)
                                ? gameCanvas!
                                : _StartScreen(onStart: _start),
                  ),
                ),
              ),
              // Game-over overlay
              ValueListenableBuilder<_GameState>(
                valueListenable: _state,
                builder:
                    (_, s, __) =>
                        s.gameOver
                            ? Padding(
                              padding: const EdgeInsets.only(
                                top: AppSizes.spacingLg,
                              ),
                              child: Column(
                                children: [
                                  Text(
                                    'GAME OVER  •  SCORE: ${s.score}',
                                    style: GoogleFonts.pressStart2p(
                                      fontSize: AppSizes.fontMd,
                                      color: AppTheme.red,
                                    ),
                                  ),
                                  const SizedBox(height: AppSizes.spacingMd),
                                  TextButton(
                                    onPressed: _start,
                                    child: Text(
                                      AppStrings.snakePlayAgain,
                                      style: GoogleFonts.pressStart2p(
                                        fontSize: AppSizes.fontSm,
                                        color: AppTheme.green,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            )
                            : const SizedBox.shrink(),
              ),
            ],
          ),
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
              const SizedBox(height: AppSizes.spacingXl),
              Text(
                AppStrings.snakeStart,
                style: GoogleFonts.pressStart2p(
                  fontSize: AppSizes.fontXs,
                  color: AppTheme.subtext,
                ),
              ),
              const SizedBox(height: AppSizes.spacingMd),
              Text(
                AppStrings.snakeControls,
                style: GoogleFonts.pressStart2p(
                  fontSize: AppSizes.fontXs,
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
  _SnakePainter(this._state) : super(repaint: _state);

  final ValueNotifier<_GameState> _state;

  @override
  void paint(Canvas canvas, Size size) {
    final s = _state.value;
    final cw = size.width / _kCols;
    final ch = size.height / _kRows;

    // grid
    final gridPaint =
        Paint()
          ..color = AppTheme.surface0.withValues(alpha: 0.25)
          ..strokeWidth = 0.5;
    for (int r = 0; r <= _kRows; r++) {
      canvas.drawLine(Offset(0, r * ch), Offset(size.width, r * ch), gridPaint);
    }
    for (int c = 0; c <= _kCols; c++) {
      canvas.drawLine(
        Offset(c * cw, 0),
        Offset(c * cw, size.height),
        gridPaint,
      );
    }

    // food
    canvas.drawRect(
      Rect.fromLTWH(s.food.x * cw + 2, s.food.y * ch + 2, cw - 4, ch - 4),
      Paint()..color = AppTheme.red,
    );

    // snake body
    final bodyColor = s.gameOver ? AppTheme.subtext : AppTheme.teal;
    final headColor = s.gameOver ? AppTheme.red : AppTheme.green;
    for (int i = s.snake.length - 1; i >= 0; i--) {
      final p = s.snake[i];
      canvas.drawRect(
        Rect.fromLTWH(p.x * cw + 1, p.y * ch + 1, cw - 2, ch - 2),
        Paint()..color = i == 0 ? headColor : bodyColor,
      );
    }
  }

  @override
  bool shouldRepaint(_) => false;
}
