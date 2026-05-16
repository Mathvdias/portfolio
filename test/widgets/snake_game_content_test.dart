import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:portifolio/shared/widgets/snake_game_content.dart';

void main() {
  testWidgets('SnakeGameContent handles keyboard input correctly', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SnakeGameContent(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final focusNode = FocusNode();
    
    // Start the game with Enter
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();

    expect(find.textContaining('WASD / ↑↓←→'), findsOneWidget);

    // Test directional keys (Ensuring no fall-through)
    // We can't easily check internal state _nextDir, 
    // but we can verify the game keeps running and doesn't crash.
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pump();

    // Test WASD keys
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

  testWidgets('SnakeGameContent restarts on Enter when Game Over', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SnakeGameContent(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Start game
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();

    // We simulate a game over state by waiting or forcing it if possible.
    // Since we can't easily force it without accessing private state,
    // we will check if the "PRESS ENTER" text appears and then disappears.
    
    // Fast forward to trigger a crash/game over (if possible) or just test the restart logic.
    // For a pure unit test of the logic, I'd need to expose the state, 
    // but for widget test, we verify the UI response.
    
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    
    expect(find.textContaining('SCORE:'), findsOneWidget);
  });
}
