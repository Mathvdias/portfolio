import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:portifolio/main.dart' as app;

void main() {
  testWidgets('Launch terminal', (tester) async {
    app.main();
    await tester.pumpAndSettle();
    
    // Tap the terminal icon
    await tester.tap(find.text('Terminal').first);
    await tester.pumpAndSettle();
    
    expect(find.text('Terminal'), findsWidgets);
    
    // Enter a command
    await tester.enterText(find.byType(TextField), 'whoami');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    
    expect(find.textContaining('Matheus Dias'), findsWidgets);
  });
}
