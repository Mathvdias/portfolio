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
    required this.snakeSet,
    required this.food,
    required this.score,
    required this.running,
    required this.gameOver,
  });

  final List<_Pos> snake;
  // Mirrors snake positions for O(1) collision and food-spawn checks.
  final Set<_Pos> snakeSet;
  final _Pos food;
  final int score;
  final bool running;
  final bool gameOver;
}

class SnakeGameContent extends StatefulWidget {
  const SnakeGameContent({
    super.key,
    this.randomSeed,
    this.showDpad = false,
  });

  final int? randomSeed;
  final bool showDpad;

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
        snakeSet: {},
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
    final snakeSet = snake.toSet();
    _dir = _Dir.right;
    _nextDir = _Dir.right;
    _state.value = _GameState(
      snake: snake,
      snakeSet: snakeSet,
      food: _spawnFood(snakeSet),
      score: 0,
      running: true,
      gameOver: false,
    );
    _timer = Timer.periodic(const Duration(milliseconds: _kTickMs), _tick);
  }

  // O(1) lookup via Set instead of O(n) list scan.
  _Pos _spawnFood(Set<_Pos> occupied) {
    _Pos f;
    do {
      f = (x: _rng.nextInt(_kCols), y: _rng.nextInt(_kRows));
    } while (occupied.contains(f));
    return f;
  }

  void _tick(Timer _) {
    final s = _state.value;
    if (s.gameOver) return;
    _dir = _nextDir;
    final newHead = _move(s.snake.first, _dir);
    // O(1) collision check via Set.
    if (s.snakeSet.contains(newHead)) {
      _timer?.cancel();
      _state.value = _GameState(
        snake: s.snake,
        snakeSet: s.snakeSet,
        food: s.food,
        score: s.score,
        running: false,
        gameOver: true,
      );
      return;
    }
    // Records support structural ==.
    final ate = newHead == s.food;
    final tail = ate ? null : s.snake.last;
    final newSnake = [
      newHead,
      ...s.snake.sublist(0, ate ? s.snake.length : s.snake.length - 1),
    ];
    // O(1) set update: add head, remove tail when not eating.
    final newSet = {...s.snakeSet}..add(newHead);
    if (tail != null) newSet.remove(tail);
    _state.value = _GameState(
      snake: newSnake,
      snakeSet: newSet,
      food: ate ? _spawnFood(newSet) : s.food,
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
        behavior: HitTestBehavior.opaque,
        onTap: () {
          _focusNode.requestFocus();
          final s = _state.value;
          if (!s.running || s.gameOver) _start();
        },
        onVerticalDragEnd: (details) {
          final s = _state.value;
          if (!s.running || s.gameOver) _start();
          final v = details.primaryVelocity;
          if (v != null) {
            if (v < -100 && _dir != _Dir.down) _nextDir = _Dir.up;
            if (v > 100 && _dir != _Dir.up) _nextDir = _Dir.down;
          }
        },
        onHorizontalDragEnd: (details) {
          final s = _state.value;
          if (!s.running || s.gameOver) _start();
          final v = details.primaryVelocity;
          if (v != null) {
            if (v < -100 && _dir != _Dir.right) _nextDir = _Dir.left;
            if (v > 100 && _dir != _Dir.left) _nextDir = _Dir.right;
          }
        },
        child: Container(
          color: AppTheme.background,
          padding: const EdgeInsets.all(AppSizes.spacingLg),
          child: Column(
            children: [
              // Score bar
              ValueListenableBuilder<_GameState>(
                valueListenable: _state,
                builder:
                    (_, s, _) => Padding(
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
                            s.running
                                ? (widget.showDpad ? 'SWIPE / DPAD' : 'WASD / ↑↓←→')
                                : (widget.showDpad ? 'TAP TO START' : 'PRESS ENTER'),
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
                    (_, s, _) =>
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
              // Touch D-pad for mobile gameplay (only shown when showDpad is true)
              if (widget.showDpad) _buildDpad(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDpad() {
    Widget dpadBtn({
      required IconData icon,
      required _Dir dir,
    }) {
      return Material(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: () {
            final s = _state.value;
            if (!s.running || s.gameOver) _start();
            final opposite = switch (dir) {
              _Dir.up => _Dir.down,
              _Dir.down => _Dir.up,
              _Dir.left => _Dir.right,
              _Dir.right => _Dir.left,
            };
            if (_dir != opposite) {
              _nextDir = dir;
            }
          },
          borderRadius: BorderRadius.circular(8),
          splashColor: AppTheme.blue.withValues(alpha: 0.3),
          highlightColor: AppTheme.blue.withValues(alpha: 0.2),
          child: Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppTheme.surface0, width: 1.5),
            ),
            child: Center(
              child: Icon(icon, color: AppTheme.blue, size: 28),
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSizes.spacingSm),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          dpadBtn(icon: Icons.arrow_drop_up, dir: _Dir.up),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              dpadBtn(icon: Icons.arrow_left, dir: _Dir.left),
              Container(
                width: 36,
                height: 36,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  color: AppTheme.surface0,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppTheme.surface, width: 1),
                ),
                child: Center(
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: AppTheme.subtext,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
              dpadBtn(icon: Icons.arrow_right, dir: _Dir.right),
            ],
          ),
          const SizedBox(height: 4),
          dpadBtn(icon: Icons.arrow_drop_down, dir: _Dir.down),
        ],
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
  // Cached paints — never reallocated after painter creation.
  final _gridPaint =
      Paint()
        ..color = AppTheme.surface0.withValues(alpha: 0.25)
        ..strokeWidth = 0.5
        ..style = PaintingStyle.stroke;
  final _fillPaint = Paint();

  @override
  void paint(Canvas canvas, Size size) {
    final s = _state.value;
    final cw = size.width / _kCols;
    final ch = size.height / _kRows;

    // grid
    for (int r = 0; r <= _kRows; r++) {
      canvas.drawLine(
        Offset(0, r * ch),
        Offset(size.width, r * ch),
        _gridPaint,
      );
    }
    for (int c = 0; c <= _kCols; c++) {
      canvas.drawLine(
        Offset(c * cw, 0),
        Offset(c * cw, size.height),
        _gridPaint,
      );
    }

    // food
    _fillPaint.color = AppTheme.red;
    canvas.drawRect(
      Rect.fromLTWH(s.food.x * cw + 2, s.food.y * ch + 2, cw - 4, ch - 4),
      _fillPaint,
    );

    // snake body
    final bodyColor = s.gameOver ? AppTheme.subtext : AppTheme.teal;
    final headColor = s.gameOver ? AppTheme.red : AppTheme.green;
    for (int i = s.snake.length - 1; i >= 0; i--) {
      final p = s.snake[i];
      _fillPaint.color = i == 0 ? headColor : bodyColor;
      canvas.drawRect(
        Rect.fromLTWH(p.x * cw + 1, p.y * ch + 1, cw - 2, ch - 2),
        _fillPaint,
      );
    }
  }

  @override
  bool shouldRepaint(_) => false;
}
