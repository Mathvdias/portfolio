import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:portifolio/shared/widgets/snake_game_content.dart';

// seed=94 places first food at (12,8) — directly ahead of the snake going right —
// and second food at (2,11) reachable via the scripted path below.
const _kTestSeed = 94;

Widget _buildApp({int? seed}) =>
    MaterialApp(home: Scaffold(body: SnakeGameContent(randomSeed: seed)));

void main() {
  testWidgets('SnakeGameContent handles keyboard input correctly', (
    tester,
  ) async {
    await tester.pumpWidget(_buildApp());
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();

    expect(find.textContaining('WASD / ↑↓←→'), findsOneWidget);

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pump();

    await tester.sendKeyEvent(LogicalKeyboardKey.keyW);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.keyS);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.keyA);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.keyD);
    await tester.pump();

    expect(find.textContaining('SCORE:'), findsOneWidget);
  });

  testWidgets('SnakeGameContent restarts on Enter when running', (
    tester,
  ) async {
    await tester.pumpWidget(_buildApp());
    await tester.pumpAndSettle();

    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();

    expect(find.textContaining('SCORE:'), findsOneWidget);
  });

  testWidgets('SnakeGameContent starts with Space key', (tester) async {
    await tester.pumpWidget(_buildApp());
    await tester.pumpAndSettle();

    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    await tester.pump();

    expect(find.textContaining('WASD / ↑↓←→'), findsOneWidget);
  });

  testWidgets('SnakeGameContent tap requests focus while running', (
    tester,
  ) async {
    await tester.pumpWidget(_buildApp(seed: _kTestSeed));
    await tester.pumpAndSettle();

    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();

    // Tap while game is running (no _StartScreen, outer GestureDetector.onTap fires)
    await tester.tap(find.byType(SnakeGameContent));
    await tester.pump();
  });

  testWidgets('SnakeGameContent tick moves snake and eats food', (
    tester,
  ) async {
    await tester.pumpWidget(_buildApp(seed: _kTestSeed));
    await tester.pumpAndSettle();

    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();

    // Advance one tick: snake goes right and eats food at (12,8)
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.textContaining('SCORE: 1'), findsOneWidget);
  });

  testWidgets('SnakeGameContent reaches game over and shows game over UI', (
    tester,
  ) async {
    // With seed=94: food1=(12,8), food2=(2,11).
    // Route: right×1 (eat food1), down×3, left×11 (eat food2 on tick 14,
    // continue to (1,11) on tick 15), then up→right→down to self-collide (tick 18).
    await tester.pumpWidget(_buildApp(seed: _kTestSeed));
    await tester.pumpAndSettle();

    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();

    // Tick 1: right → eats food at (12,8), score=1
    await tester.pump(const Duration(milliseconds: 200));

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    // Ticks 2-4: down
    for (int i = 0; i < 3; i++) {
      await tester.pump(const Duration(milliseconds: 200));
    }

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
    // Ticks 5-15: left (eats food at (2,11) on tick 14, arrives (1,11) on tick 15)
    for (int i = 0; i < 11; i++) {
      await tester.pump(const Duration(milliseconds: 200));
    }

    // Ticks 16-18: up→right→down → self-collision on tick 18
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
    await tester.pump(const Duration(milliseconds: 200));

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pump(const Duration(milliseconds: 200));

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pump(const Duration(milliseconds: 200));

    await tester.pump();

    expect(find.textContaining('GAME OVER  •  SCORE: 2'), findsOneWidget);
    await tester.pumpAndSettle();
  });
}
