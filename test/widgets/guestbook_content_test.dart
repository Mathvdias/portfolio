import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:portifolio/features/guestbook/presentation/widgets/guestbook_content.dart';
import 'package:portifolio/features/guestbook/presentation/viewmodels/guestbook_viewmodel.dart';
import 'package:portifolio/features/guestbook/data/repositories/guestbook_repository.dart';
import 'package:portifolio/features/guestbook/domain/models/guestbook_message.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:portifolio/l10n/app_localizations.dart';

class MockGuestbookRepository implements GuestbookRepository {
  final _controller = StreamController<List<GuestbookMessage>>.broadcast();
  List<GuestbookMessage> messages = [];

  @override
  Stream<List<GuestbookMessage>> watchMessages() => _controller.stream;

  @override
  Future<void> addMessage(String name, String message, int rating) async {
    messages.add(GuestbookMessage(
      id: 'mock', name: name, message: message, rating: rating, timestamp: DateTime.now()
    ));
    _controller.add(messages);
  }

  @override
  Future<void> deleteMessage(String id) async {
    messages.removeWhere((m) => m.id == id);
    _controller.add(messages);
  }
}

void main() {
  testWidgets('GuestbookContent displays UI and handles submission', (tester) async {
    SharedPreferences.setMockInitialValues({'isAdmin': false});
    final prefs = await SharedPreferences.getInstance();
    final repo = MockGuestbookRepository();
    final vm = GuestbookViewModel(repo, prefs);
    
    await tester.pumpWidget(MaterialApp(
      localizationsDelegates: const [
        AppLocalizationsDelegate(),
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      supportedLocales: const [Locale('en'), Locale('pt')],
      home: Scaffold(
        body: GuestbookContent(viewModel: vm),
      ),
    ));
    
    // Load messages
    repo._controller.add([]);
    await tester.pumpAndSettle();
    
    expect(find.text('No messages yet. Be the first!'), findsOneWidget);
    
    // Test input
    await tester.enterText(find.byType(TextField).first, 'John');
    await tester.enterText(find.byType(TextField).last, 'Hello');
    await tester.tap(find.text('Post'));
    await tester.pumpAndSettle();
    
    expect(find.text('John'), findsOneWidget);
    expect(find.text('Hello'), findsOneWidget);
  });
}
