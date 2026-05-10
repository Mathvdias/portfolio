import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:portifolio/features/localization/presentation/viewmodels/locale_viewmodel.dart';

// Smoke test that verifies core MVVM primitives work in isolation
// without requiring Firebase or network calls.
void main() {
  testWidgets('LocaleViewModel drives MaterialApp locale', (tester) async {
    final vm = LocaleViewModel();
    addTearDown(vm.dispose);

    await tester.pumpWidget(
      ListenableBuilder(
        listenable: vm,
        builder: (context, _) => MaterialApp(
          locale: vm.flutterLocale,
          home: const Scaffold(body: Text('ok')),
        ),
      ),
    );

    expect(find.byType(MaterialApp), findsOneWidget);
    expect(find.text('ok'), findsOneWidget);

    vm.setLocaleByCode('pt');
    await tester.pump();
    // locale changed — app still renders
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
