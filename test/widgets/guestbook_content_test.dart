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
    messages.add(
      GuestbookMessage(
        id: 'mock',
        name: name,
        message: message,
        rating: rating,
        timestamp: DateTime.now(),
      ),
    );
    _controller.add(messages);
  }

  @override
  Future<void> deleteMessage(String id) async {
    messages.removeWhere((m) => m.id == id);
    _controller.add(messages);
  }
}

Widget buildApp(GuestbookViewModel vm) {
  return MaterialApp(
    localizationsDelegates: const [
      AppLocalizationsDelegate(),
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
    ],
    supportedLocales: const [Locale('en'), Locale('pt')],
    home: Scaffold(body: GuestbookContent(viewModel: vm)),
  );
}

void main() {
  testWidgets('GuestbookContent displays UI and handles submission', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({'isAdmin': false});
    final prefs = await SharedPreferences.getInstance();
    final repo = MockGuestbookRepository();
    final vm = GuestbookViewModel(repo, prefs);

    await tester.pumpWidget(buildApp(vm));

    repo._controller.add([]);
    await tester.pumpAndSettle();

    expect(find.text('No messages yet. Be the first!'), findsOneWidget);

    await tester.enterText(find.byType(TextField).first, 'John');
    await tester.enterText(find.byType(TextField).last, 'Hello');
    await tester.tap(find.text('Post'));
    await tester.pumpAndSettle();

    expect(find.text('John'), findsOneWidget);
    expect(find.text('Hello'), findsOneWidget);
  });

  testWidgets('shows error snackbar when name is empty', (tester) async {
    SharedPreferences.setMockInitialValues({'isAdmin': false});
    final prefs = await SharedPreferences.getInstance();
    final repo = MockGuestbookRepository();
    final vm = GuestbookViewModel(repo, prefs);

    await tester.pumpWidget(buildApp(vm));
    repo._controller.add([]);
    await tester.pumpAndSettle();

    // Tap Post without filling name/message
    await tester.tap(find.text('Post'));
    await tester.pumpAndSettle();

    expect(find.text('Name and message cannot be empty'), findsOneWidget);
  });

  testWidgets('shows waitToPost snackbar when posting too quickly', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      'isAdmin': false,
      'last_guestbook_post': DateTime.now().millisecondsSinceEpoch,
    });
    final prefs = await SharedPreferences.getInstance();
    final repo = MockGuestbookRepository();
    final vm = GuestbookViewModel(repo, prefs);

    await tester.pumpWidget(buildApp(vm));
    repo._controller.add([]);
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).first, 'Alice');
    await tester.enterText(find.byType(TextField).last, 'Nice portfolio!');
    await tester.tap(find.text('Post'));
    await tester.pumpAndSettle();

    expect(
      find.text('Please wait a minute before posting again.'),
      findsOneWidget,
    );
  });

  testWidgets('shows error state with retry button on stream failure', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({'isAdmin': false});
    final prefs = await SharedPreferences.getInstance();
    final repo = MockGuestbookRepository();
    final vm = GuestbookViewModel(repo, prefs);

    await tester.pumpWidget(buildApp(vm));
    await tester.pump();

    repo._controller.addError('Connection failed');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Retry Connection'), findsOneWidget);
    expect(find.byIcon(Icons.refresh), findsOneWidget);
  });

  testWidgets('tapping star changes rating', (tester) async {
    SharedPreferences.setMockInitialValues({'isAdmin': false});
    final prefs = await SharedPreferences.getInstance();
    final repo = MockGuestbookRepository();
    final vm = GuestbookViewModel(repo, prefs);

    await tester.pumpWidget(buildApp(vm));
    repo._controller.add([]);
    await tester.pumpAndSettle();

    final starIcons = find.byIcon(Icons.star);
    final firstStar = starIcons.first;
    await tester.tap(firstStar);
    await tester.pump();

    expect(find.byIcon(Icons.star), findsWidgets);
  });

  testWidgets('messages list shows separator between messages', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({'isAdmin': false});
    final prefs = await SharedPreferences.getInstance();
    final repo = MockGuestbookRepository();
    final vm = GuestbookViewModel(repo, prefs);

    await tester.pumpWidget(buildApp(vm));

    repo._controller.add([
      GuestbookMessage(
        id: '1',
        name: 'Alice',
        message: 'Hello!',
        rating: 5,
        timestamp: DateTime.now(),
      ),
      GuestbookMessage(
        id: '2',
        name: 'Bob',
        message: 'World!',
        rating: 4,
        timestamp: DateTime.now(),
      ),
    ]);
    await tester.pumpAndSettle();

    expect(find.text('Alice'), findsOneWidget);
    expect(find.text('Bob'), findsOneWidget);
  });

  testWidgets('admin can delete a message', (tester) async {
    SharedPreferences.setMockInitialValues({'isAdmin': true});
    final prefs = await SharedPreferences.getInstance();
    final repo = MockGuestbookRepository();
    repo.messages = [
      GuestbookMessage(
        id: 'del1',
        name: 'ToDelete',
        message: 'Remove me',
        rating: 1,
        timestamp: DateTime.now(),
      ),
    ];
    final vm = GuestbookViewModel(repo, prefs);

    await tester.pumpWidget(buildApp(vm));
    repo._controller.add(repo.messages);
    await tester.pumpAndSettle();

    expect(find.text('ToDelete'), findsOneWidget);
    expect(find.byIcon(Icons.delete), findsOneWidget);

    await tester.tap(find.byIcon(Icons.delete));
    await tester.pumpAndSettle();
  });
}
