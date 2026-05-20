import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
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
        id: 'mock_${messages.length}',
        name: name,
        message: message,
        rating: rating,
        timestamp: DateTime(2026, 5, 20, 10, 30),
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
    locale: const Locale('en'),
    theme: ThemeData.dark(),
    home: Scaffold(body: GuestbookContent(viewModel: vm)),
  );
}

void main() {
  GoogleFonts.config.allowRuntimeFetching = false;

  group('GuestbookContent Golden Tests', () {
    late MockGuestbookRepository repo;
    late GuestbookViewModel vm;

    setUp(() async {
      SharedPreferences.setMockInitialValues({'isAdmin': false});
      final prefs = await SharedPreferences.getInstance();
      repo = MockGuestbookRepository();
      vm = GuestbookViewModel(repo, prefs);
    });

    testWidgets('guestbook_empty_state', (WidgetTester tester) async {
      // Define a standard viewport size for desktop-like rendering
      tester.view.physicalSize = const Size(800, 600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(buildApp(vm));
      repo._controller.add([]);
      await tester.pumpAndSettle();

      await expectLater(
        find.byType(GuestbookContent),
        matchesGoldenFile('goldens/guestbook_empty_state.png'),
      );
    });

    testWidgets('guestbook_with_messages_state', (WidgetTester tester) async {
      // Define a standard viewport size for desktop-like rendering
      tester.view.physicalSize = const Size(800, 600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(buildApp(vm));

      repo.messages = [
        GuestbookMessage(
          id: '1',
          name: 'Matheus Dias',
          message: 'Welcome to my engineering portfolio! 🚀',
          rating: 5,
          timestamp: DateTime(2026, 5, 20, 12, 0),
        ),
        GuestbookMessage(
          id: '2',
          name: 'Visitor 007',
          message: 'This runs so smoothly at 120 FPS! Nice work.',
          rating: 5,
          timestamp: DateTime(2026, 5, 20, 12, 15),
        ),
      ];
      repo._controller.add(repo.messages);
      await tester.pumpAndSettle();

      await expectLater(
        find.byType(GuestbookContent),
        matchesGoldenFile('goldens/guestbook_with_messages_state.png'),
      );
    });
  });
}
