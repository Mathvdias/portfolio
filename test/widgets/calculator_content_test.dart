import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:portifolio/shared/widgets/calculator_content.dart';

void main() {
  group('CalculatorContent', () {
    testWidgets('renders initial display as 0', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(width: 300, height: 400, child: CalculatorContent()),
          ),
        ),
      );

      expect(find.text('0'), findsWidgets);
    });

    testWidgets('pressing a digit updates display', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(width: 300, height: 400, child: CalculatorContent()),
          ),
        ),
      );

      await tester.tap(find.text('5'));
      await tester.pump();

      expect(find.text('5'), findsWidgets);
    });

    testWidgets('addition works correctly', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(width: 300, height: 400, child: CalculatorContent()),
          ),
        ),
      );

      await tester.tap(find.text('3'));
      await tester.pump();
      await tester.tap(find.text('+'));
      await tester.pump();
      await tester.tap(find.text('7'));
      await tester.pump();
      await tester.tap(find.text('='));
      await tester.pump();

      expect(find.text('10'), findsOneWidget);
    });

    testWidgets('clear resets to 0', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(width: 300, height: 400, child: CalculatorContent()),
          ),
        ),
      );

      await tester.tap(find.text('9'));
      await tester.pump();
      await tester.tap(find.text('C'));
      await tester.pump();

      expect(find.text('0'), findsWidgets);
    });

    testWidgets('subtraction works correctly', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(width: 300, height: 400, child: CalculatorContent()),
          ),
        ),
      );

      await tester.tap(find.text('9'));
      await tester.pump();
      await tester.tap(find.text('-'));
      await tester.pump();
      await tester.tap(find.text('4'));
      await tester.pump();
      await tester.tap(find.text('='));
      await tester.pump();

      expect(find.text('5'), findsWidgets);
    });

    testWidgets('multiplication works correctly', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(width: 300, height: 400, child: CalculatorContent()),
          ),
        ),
      );

      await tester.tap(find.text('3'));
      await tester.pump();
      await tester.tap(find.text('*'));
      await tester.pump();
      await tester.tap(find.text('4'));
      await tester.pump();
      await tester.tap(find.text('='));
      await tester.pump();

      expect(find.text('12'), findsOneWidget);
    });

    testWidgets('division works correctly', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(width: 300, height: 400, child: CalculatorContent()),
          ),
        ),
      );

      await tester.tap(find.text('8'));
      await tester.pump();
      await tester.tap(find.text('/'));
      await tester.pump();
      await tester.tap(find.text('2'));
      await tester.pump();
      await tester.tap(find.text('='));
      await tester.pump();

      expect(find.text('4'), findsWidgets);
    });

    testWidgets('multi-digit input appends digits', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(width: 300, height: 400, child: CalculatorContent()),
          ),
        ),
      );

      await tester.tap(find.text('1'));
      await tester.pump();
      await tester.tap(find.text('2'));
      await tester.pump();
      await tester.tap(find.text('3'));
      await tester.pump();

      expect(find.text('123'), findsOneWidget);
    });
  });
}
