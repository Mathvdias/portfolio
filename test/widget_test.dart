import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:portifolio/main.dart';
import 'package:portifolio/controllers/language_controller.dart';

void main() {
  testWidgets('App renders without crashing', (tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => LanguageController(),
        child: const MyApp(),
      ),
    );
    await tester.pump();
    // App should render without throwing
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
