import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mocktail/mocktail.dart';
import 'package:portifolio/core/di/app_dependencies.dart';
import 'package:portifolio/core/services/analytics_service.dart';
import 'package:portifolio/features/desktop/presentation/viewmodels/desktop_viewmodel.dart';
import 'package:portifolio/features/guestbook/data/repositories/guestbook_repository.dart';
import 'package:portifolio/features/guestbook/domain/models/guestbook_message.dart';
import 'package:portifolio/features/guestbook/presentation/viewmodels/guestbook_viewmodel.dart';
import 'package:portifolio/features/localization/presentation/viewmodels/locale_viewmodel.dart';
import 'package:portifolio/features/visitors/domain/repositories/visitor_repository.dart';
import 'package:portifolio/shared/constants/app_strings.dart';
import 'package:portifolio/shared/widgets/terminal_content.dart';
import 'package:portifolio/theme/app_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _MockGuestbookRepository extends Mock implements GuestbookRepository {}

class _MockVisitorRepository extends Mock implements VisitorRepository {}

class _MockAnalyticsService extends Mock implements AnalyticsService {}

const _prompt = 'matheus@portfolio:~\$ ';
const _urlLauncherChannel = MethodChannel('plugins.flutter.io/url_launcher');
const _outsideKey = Key('outside-terminal');

TestDefaultBinaryMessenger get _messenger =>
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

/// Pumps the terminal inside the dependencies it reads (`admin_login` needs the
/// guestbook view model) next to a plain area that is *not* part of it.
Widget _buildTerminal(GuestbookViewModel guestbook) {
  return MaterialApp(
    home: Scaffold(
      body: AppDependencies(
        localeViewModel: LocaleViewModel(),
        visitorRepository: _MockVisitorRepository(),
        guestbookViewModel: guestbook,
        desktopViewModel: DesktopViewModel(),
        analyticsService: _MockAnalyticsService(),
        child: const Column(
          children: [
            ColoredBox(
              key: _outsideKey,
              color: Colors.grey,
              child: SizedBox(height: 60, width: double.infinity),
            ),
            Expanded(child: TerminalContent()),
          ],
        ),
      ),
    ),
  );
}

TextEditingController _input(WidgetTester tester) =>
    tester.widget<TextField>(find.byType(TextField)).controller!;

FocusNode _inputFocus(WidgetTester tester) =>
    tester.widget<TextField>(find.byType(TextField)).focusNode!;

ScrollPosition _outputScroll(WidgetTester tester) =>
    tester.widget<ListView>(find.byType(ListView)).controller!.position;

int _outputLineCount(WidgetTester tester) {
  final list = tester.widget<ListView>(find.byType(ListView));
  return list.childrenDelegate.estimatedChildCount!;
}

/// Lets the command finish, its output paint and the 100 ms scroll-to-bottom
/// animation (started from a post-frame callback) run to its end.
Future<void> _settleOutput(WidgetTester tester) => tester.pumpAndSettle();

/// Types [command] at the prompt and presses Enter.
Future<void> _run(WidgetTester tester, String command) async {
  await tester.enterText(find.byType(TextField), command);
  await tester.testTextInput.receiveAction(TextInputAction.done);
  await _settleOutput(tester);
}

/// Types [text] at the prompt without submitting it.
Future<void> _type(WidgetTester tester, String text) async {
  await tester.enterText(find.byType(TextField), text);
  await tester.pump();
}

/// Presses [key], returning whether it was handled.
///
/// The focus is deliberately left wherever the previous step put it: the keys
/// only reach the terminal while its prompt is focused, as in the app.
Future<bool> _press(WidgetTester tester, LogicalKeyboardKey key) async {
  final handled = await tester.sendKeyEvent(key);
  await _settleOutput(tester);
  return handled;
}

void main() {
  GoogleFonts.config.allowRuntimeFetching = false;

  late GuestbookViewModel guestbook;
  late SharedPreferences prefs;
  late List<MethodCall> launcherCalls;
  late bool canLaunch;

  setUp(() async {
    SharedPreferences.setMockInitialValues({'isAdmin': false});
    prefs = await SharedPreferences.getInstance();
    final repo = _MockGuestbookRepository();
    when(
      repo.watchMessages,
    ).thenAnswer((_) => const Stream<List<GuestbookMessage>>.empty());
    guestbook = GuestbookViewModel(repo, prefs);

    launcherCalls = [];
    canLaunch = true;
    _messenger.setMockMethodCallHandler(_urlLauncherChannel, (call) async {
      launcherCalls.add(call);
      return call.method == 'canLaunch' ? canLaunch : true;
    });
  });

  tearDown(() {
    _messenger.setMockMethodCallHandler(_urlLauncherChannel, null);
    guestbook.dispose();
  });

  group('TerminalContent startup', () {
    testWidgets('greets with the banner, a prompt and a focused input', (
      tester,
    ) async {
      await tester.pumpWidget(_buildTerminal(guestbook));
      await tester.pump();

      final banner = tester.widget<Text>(
        find.text('Portfolio Terminal v2.0 — type "help" to start'),
      );
      expect(banner.style?.color, AppTheme.teal);
      expect(find.text(_prompt), findsOneWidget);
      expect(_input(tester).text, isEmpty);
      expect(_inputFocus(tester).hasFocus, isTrue);
    });
  });

  group('TerminalContent commands', () {
    testWidgets('echoes the submitted command after the prompt, in blue', (
      tester,
    ) async {
      await tester.pumpWidget(_buildTerminal(guestbook));
      await _run(tester, '  whoami  ');

      final echoed = tester.widget<Text>(find.text('${_prompt}whoami'));
      expect(echoed.style?.color, AppTheme.blue);
      expect(_input(tester).text, isEmpty, reason: 'the prompt is cleared');
    });

    testWidgets('help lists every command and the sequencing operators', (
      tester,
    ) async {
      await tester.pumpWidget(_buildTerminal(guestbook));
      await _run(tester, 'help');

      expect(find.text('available commands:'), findsOneWidget);
      for (final command in [
        'help',
        'whoami',
        'ls',
        'cat',
        'skills',
        'date',
        'neofetch',
        'open',
        'clear',
        'echo',
        'history',
      ]) {
        expect(
          find.textContaining(RegExp('^  $command +\\S')),
          findsOneWidget,
          reason: '"$command" should be documented by help',
        );
      }
      expect(find.textContaining('cmd1 && cmd2'), findsOneWidget);
      expect(find.textContaining('cmd1 ; cmd2'), findsOneWidget);
    });

    testWidgets('command names are case-insensitive', (tester) async {
      await tester.pumpWidget(_buildTerminal(guestbook));
      await _run(tester, 'HELP');

      expect(find.text('available commands:'), findsOneWidget);
    });

    testWidgets('whoami prints the bio, one output line per row', (
      tester,
    ) async {
      await tester.pumpWidget(_buildTerminal(guestbook));
      await _run(tester, 'whoami');

      expect(
        find.text('Matheus Dias — Flutter/Mobile Engineer'),
        findsOneWidget,
      );
      expect(
        find.text('Building fast, beautiful apps with Flutter & Kotlin'),
        findsOneWidget,
      );
      expect(
        find.text('Open source contributor · pub.dev author'),
        findsOneWidget,
      );
    });

    testWidgets('ls lists the readable sections', (tester) async {
      await tester.pumpWidget(_buildTerminal(guestbook));
      await _run(tester, 'ls');

      expect(
        find.text(
          'about.txt   experience.txt   skills.txt   projects/   contact.txt',
        ),
        findsOneWidget,
      );
    });

    testWidgets('cat without a file prints its usage', (tester) async {
      await tester.pumpWidget(_buildTerminal(guestbook));
      await _run(tester, 'cat');

      expect(find.text('usage: cat <file>'), findsOneWidget);
    });

    testWidgets('cat prints the content of each known file', (tester) async {
      await tester.pumpWidget(_buildTerminal(guestbook));

      await _run(tester, 'cat about.txt');
      expect(
        find.text('Author of intercepted_http on pub.dev.'),
        findsOneWidget,
      );

      await _run(tester, 'cat experience.txt');
      expect(find.textContaining('Zallpy Digital'), findsOneWidget);
      expect(find.textContaining('Banco Pan'), findsOneWidget);
      expect(find.textContaining('Conecthus'), findsOneWidget);

      await _run(tester, 'cat contact.txt');
      expect(find.text('GitHub:   github.com/Mathvdias'), findsOneWidget);

      await _run(tester, 'clear');
      await _run(tester, 'cat skills.txt');
      expect(
        find.text('languages:   Dart · Kotlin · Swift (basic)'),
        findsOneWidget,
      );
    });

    testWidgets('cat reports a missing file', (tester) async {
      await tester.pumpWidget(_buildTerminal(guestbook));
      await _run(tester, 'cat secrets.txt');

      expect(
        find.text('cat: secrets.txt: No such file or directory'),
        findsOneWidget,
      );
    });

    testWidgets('skills prints the tech stack', (tester) async {
      await tester.pumpWidget(_buildTerminal(guestbook));
      await _run(tester, 'skills');

      expect(
        find.text('frameworks:  Flutter · Android SDK · Jetpack Compose'),
        findsOneWidget,
      );
      expect(
        find.text('testing:     Unit · Widget · Integration'),
        findsOneWidget,
      );
    });

    testWidgets('date prints the current date and time', (tester) async {
      await tester.pumpWidget(_buildTerminal(guestbook));
      final before = DateTime.now();
      await _run(tester, 'date');
      final after = DateTime.now();

      final line = tester.widget<Text>(
        find.textContaining(RegExp(r'^\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}')),
      );
      final printed = DateTime.parse(line.data!);
      expect(printed.isBefore(before), isFalse);
      expect(printed.isAfter(after), isFalse);
    });

    testWidgets('neofetch prints the system card', (tester) async {
      await tester.pumpWidget(_buildTerminal(guestbook));
      await _run(tester, 'neofetch');

      expect(find.textContaining('matheus @ portfolio'), findsOneWidget);
      expect(find.textContaining('OS:       Portfolio OS 1.0'), findsOneWidget);
      expect(find.textContaining('Theme:    Catppuccin Mocha'), findsOneWidget);
    });

    testWidgets('echo prints its arguments separated by single spaces', (
      tester,
    ) async {
      await tester.pumpWidget(_buildTerminal(guestbook));
      await _run(tester, 'echo hello    terminal   world');

      expect(find.text('hello terminal world'), findsOneWidget);
    });

    testWidgets('an unknown command is reported with a hint', (tester) async {
      await tester.pumpWidget(_buildTerminal(guestbook));
      await _run(tester, 'sudo rm -rf /');

      expect(find.text('command not found: sudo'), findsOneWidget);
      expect(find.text('Type "help" for available commands.'), findsOneWidget);
    });

    testWidgets('submitting an empty line only echoes the prompt', (
      tester,
    ) async {
      await tester.pumpWidget(_buildTerminal(guestbook));
      final linesBefore = _outputLineCount(tester);
      await _run(tester, '   ');

      expect(find.text(_prompt), findsNWidgets(2));
      expect(_outputLineCount(tester), linesBefore + 1);
      expect(find.textContaining('command not found'), findsNothing);
    });

    testWidgets('clear wipes the banner and every previous output', (
      tester,
    ) async {
      await tester.pumpWidget(_buildTerminal(guestbook));
      await _run(tester, 'whoami');
      await _run(tester, 'clear');

      expect(find.textContaining('Portfolio Terminal v2.0'), findsNothing);
      expect(find.textContaining('Matheus Dias'), findsNothing);
      expect(find.text('${_prompt}clear'), findsNothing);
      expect(_outputLineCount(tester), 1, reason: 'only a blank line is left');
    });

    testWidgets('history numbers the submitted commands, oldest first', (
      tester,
    ) async {
      await tester.pumpWidget(_buildTerminal(guestbook));
      await _run(tester, 'echo one');
      await _run(tester, 'ls');
      await _run(tester, 'history');

      expect(find.text('  1  echo one'), findsOneWidget);
      expect(find.text('  2  ls'), findsOneWidget);
      expect(find.text('  3  history'), findsOneWidget);
    });

    testWidgets('history counts itself, even as the very first command', (
      tester,
    ) async {
      await tester.pumpWidget(_buildTerminal(guestbook));
      await _run(tester, 'history');

      expect(find.text('  1  history'), findsOneWidget);
    });
  });

  group('TerminalContent sequential commands', () {
    testWidgets('"&&" runs the next command when the previous one succeeds', (
      tester,
    ) async {
      await tester.pumpWidget(_buildTerminal(guestbook));
      await _run(tester, 'echo first && echo second');

      expect(find.text('first'), findsOneWidget);
      expect(find.text('second'), findsOneWidget);
    });

    testWidgets('"&&" stops at the first unknown command', (tester) async {
      await tester.pumpWidget(_buildTerminal(guestbook));
      await _run(tester, 'nope && echo unreachable');

      expect(find.text('command not found: nope'), findsOneWidget);
      expect(find.text('unreachable'), findsNothing);
    });

    testWidgets('";" keeps going after an unknown command', (tester) async {
      await tester.pumpWidget(_buildTerminal(guestbook));
      await _run(tester, 'nope ; echo still-runs');

      expect(find.text('command not found: nope'), findsOneWidget);
      expect(find.text('still-runs'), findsOneWidget);
    });

    testWidgets('empty segments between separators are skipped', (
      tester,
    ) async {
      await tester.pumpWidget(_buildTerminal(guestbook));
      await _run(tester, 'echo a ;; && echo b ;');

      expect(find.text('a'), findsOneWidget);
      expect(find.text('b'), findsOneWidget);
      expect(find.textContaining('command not found'), findsNothing);
    });

    testWidgets('clear in the middle keeps only what ran after it', (
      tester,
    ) async {
      await tester.pumpWidget(_buildTerminal(guestbook));
      await _run(tester, 'echo before ; clear ; echo after');

      expect(find.text('before'), findsNothing);
      expect(find.text('after'), findsOneWidget);
    });
  });

  group('TerminalContent open', () {
    testWidgets('without a target prints its usage and launches nothing', (
      tester,
    ) async {
      await tester.pumpWidget(_buildTerminal(guestbook));
      await _run(tester, 'open');

      expect(
        find.text('usage: open <github|linkedin|medium|pubdev>'),
        findsOneWidget,
      );
      expect(launcherCalls, isEmpty);
    });

    testWidgets('rejects an unknown target', (tester) async {
      await tester.pumpWidget(_buildTerminal(guestbook));
      await _run(tester, 'open Twitter');

      expect(find.text('open: unknown target "twitter"'), findsOneWidget);
      expect(launcherCalls, isEmpty);
    });

    for (final MapEntry(key: target, value: url)
        in const {
          'github': AppStrings.urlGitHub,
          'linkedin': AppStrings.urlLinkedIn,
          'medium': AppStrings.urlMedium,
          'pubdev': AppStrings.urlPubDev,
        }.entries) {
      testWidgets('launches the $target profile', (tester) async {
        await tester.pumpWidget(_buildTerminal(guestbook));
        await _run(tester, 'open ${target.toUpperCase()}');

        expect(find.text('opening $url...'), findsOneWidget);
        final launch = launcherCalls.singleWhere((c) => c.method == 'launch');
        expect((launch.arguments as Map<Object?, Object?>)['url'], url);
      });
    }

    testWidgets('does not launch a URL the platform cannot open', (
      tester,
    ) async {
      canLaunch = false;
      await tester.pumpWidget(_buildTerminal(guestbook));
      await _run(tester, 'open github');

      expect(launcherCalls.map((c) => c.method), ['canLaunch']);
      expect(find.text('opening ${AppStrings.urlGitHub}...'), findsOneWidget);
    });

    testWidgets('stops quietly when the window closes before the launch', (
      tester,
    ) async {
      final gate = Completer<bool>();
      _messenger.setMockMethodCallHandler(_urlLauncherChannel, (call) {
        launcherCalls.add(call);
        return call.method == 'canLaunch' ? gate.future : Future.value(true);
      });
      await tester.pumpWidget(_buildTerminal(guestbook));
      await tester.enterText(
        find.byType(TextField),
        'open github ; open linkedin',
      );
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();
      // The first command is still waiting on the platform.
      expect(launcherCalls.map((c) => c.method), ['canLaunch']);

      await tester.pumpWidget(const SizedBox());
      gate.complete(false);
      await _settleOutput(tester);

      expect(tester.takeException(), isNull);
      // Nothing is launched and the rest of the line is dropped.
      expect(launcherCalls.map((c) => c.method), ['canLaunch']);
    });
  });

  group('TerminalContent admin mode', () {
    testWidgets('admin_login denies a missing or wrong password', (
      tester,
    ) async {
      await tester.pumpWidget(_buildTerminal(guestbook));
      await _run(tester, 'admin_login');
      await _run(tester, 'admin_login letmein');

      expect(find.text('Access Denied'), findsNWidgets(2));
      expect(guestbook.isAdmin, isFalse);
      expect(prefs.getBool('isAdmin'), isFalse);
    });

    testWidgets('admin_login and admin_logout toggle the guestbook admin', (
      tester,
    ) async {
      await tester.pumpWidget(_buildTerminal(guestbook));

      await _run(tester, 'admin_login portifolio2026');
      expect(find.text('Admin mode activated.'), findsOneWidget);
      expect(guestbook.isAdmin, isTrue);
      expect(prefs.getBool('isAdmin'), isTrue);

      await _run(tester, 'admin_logout');
      expect(find.text('Admin mode deactivated.'), findsOneWidget);
      expect(guestbook.isAdmin, isFalse);
      expect(prefs.getBool('isAdmin'), isFalse);
    });
  });

  group('TerminalContent history navigation', () {
    testWidgets('arrow up does nothing before any command was run', (
      tester,
    ) async {
      await tester.pumpWidget(_buildTerminal(guestbook));
      await _run(tester, '');

      expect(await _press(tester, LogicalKeyboardKey.arrowUp), isTrue);
      expect(_input(tester).text, isEmpty);
    });

    testWidgets('arrow up walks back and stops at the oldest command', (
      tester,
    ) async {
      await tester.pumpWidget(_buildTerminal(guestbook));
      await _run(tester, 'echo one');
      await _run(tester, 'echo two');

      await _press(tester, LogicalKeyboardKey.arrowUp);
      expect(_input(tester).text, 'echo two');
      expect(
        _input(tester).selection,
        const TextSelection.collapsed(offset: 8),
        reason: 'the caret goes to the end of the recalled command',
      );

      await _press(tester, LogicalKeyboardKey.arrowUp);
      expect(_input(tester).text, 'echo one');

      await _press(tester, LogicalKeyboardKey.arrowUp);
      expect(_input(tester).text, 'echo one');
    });

    testWidgets('arrow down walks forward and ends on an empty prompt', (
      tester,
    ) async {
      await tester.pumpWidget(_buildTerminal(guestbook));
      await _run(tester, 'echo one');
      await _run(tester, 'echo two');
      await _press(tester, LogicalKeyboardKey.arrowUp);
      await _press(tester, LogicalKeyboardKey.arrowUp);

      expect(await _press(tester, LogicalKeyboardKey.arrowDown), isTrue);
      expect(_input(tester).text, 'echo two');
      expect(
        _input(tester).selection,
        const TextSelection.collapsed(offset: 8),
      );

      await _press(tester, LogicalKeyboardKey.arrowDown);
      expect(_input(tester).text, isEmpty);

      await _press(tester, LogicalKeyboardKey.arrowDown);
      expect(_input(tester).text, isEmpty);
    });

    testWidgets('submitting restarts the navigation from the newest command', (
      tester,
    ) async {
      await tester.pumpWidget(_buildTerminal(guestbook));
      await _run(tester, 'echo one');
      await _run(tester, 'echo two');
      await _press(tester, LogicalKeyboardKey.arrowUp);
      await _press(tester, LogicalKeyboardKey.arrowUp);
      await _run(tester, 'echo three');

      await _press(tester, LogicalKeyboardKey.arrowUp);
      expect(_input(tester).text, 'echo three');
    });

    testWidgets('a recalled command can be run again', (tester) async {
      await tester.pumpWidget(_buildTerminal(guestbook));
      await _run(tester, 'echo again');
      await _press(tester, LogicalKeyboardKey.arrowUp);
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await _settleOutput(tester);

      expect(find.text('again'), findsNWidgets(2));
    });

    testWidgets('other keys are left to the text field', (tester) async {
      await tester.pumpWidget(_buildTerminal(guestbook));
      await _type(tester, 'ls');

      expect(await _press(tester, LogicalKeyboardKey.f9), isFalse);
      expect(_input(tester).text, 'ls');
    });
  });

  group('TerminalContent tab completion', () {
    testWidgets('completes a unique command prefix and adds a space', (
      tester,
    ) async {
      await tester.pumpWidget(_buildTerminal(guestbook));
      await _type(tester, 'WH');

      expect(await _press(tester, LogicalKeyboardKey.tab), isTrue);
      expect(_input(tester).text, 'whoami ');
      expect(
        _input(tester).selection,
        const TextSelection.collapsed(offset: 7),
      );
      expect(_inputFocus(tester).hasFocus, isTrue, reason: 'Tab keeps focus');
    });

    testWidgets('lists the candidates of an ambiguous command prefix', (
      tester,
    ) async {
      await tester.pumpWidget(_buildTerminal(guestbook));
      await _type(tester, 'h');
      await _press(tester, LogicalKeyboardKey.tab);

      expect(find.text('${_prompt}h'), findsOneWidget);
      expect(find.text('help  history'), findsOneWidget);
      expect(_input(tester).text, 'h', reason: 'the typed text is kept');
    });

    testWidgets('lists every command on an empty prompt', (tester) async {
      await tester.pumpWidget(_buildTerminal(guestbook));
      await _press(tester, LogicalKeyboardKey.tab);

      expect(
        find.text(
          'help  whoami  ls  cat  skills  date  neofetch  open  clear  '
          'echo  history',
        ),
        findsOneWidget,
      );
    });

    testWidgets('ignores a prefix no command starts with', (tester) async {
      await tester.pumpWidget(_buildTerminal(guestbook));
      final linesBefore = _outputLineCount(tester);
      await _type(tester, 'zz');
      await _press(tester, LogicalKeyboardKey.tab);

      expect(_input(tester).text, 'zz');
      expect(_outputLineCount(tester), linesBefore);
    });

    testWidgets('completes a unique file name for cat', (tester) async {
      await tester.pumpWidget(_buildTerminal(guestbook));
      await _type(tester, 'cat AB');
      await _press(tester, LogicalKeyboardKey.tab);

      expect(_input(tester).text, 'cat about.txt ');
      expect(
        _input(tester).selection,
        const TextSelection.collapsed(offset: 14),
      );
    });

    testWidgets('lists every file for a bare cat', (tester) async {
      await tester.pumpWidget(_buildTerminal(guestbook));
      await _type(tester, 'cat ');
      await _press(tester, LogicalKeyboardKey.tab);

      expect(find.text('${_prompt}cat '), findsOneWidget);
      expect(
        find.text('about.txt  experience.txt  skills.txt  contact.txt'),
        findsOneWidget,
      );
      expect(_input(tester).text, 'cat ');
    });

    testWidgets('completes and lists the targets of open', (tester) async {
      await tester.pumpWidget(_buildTerminal(guestbook));
      await _type(tester, 'open ');
      await _press(tester, LogicalKeyboardKey.tab);
      expect(find.text('github  linkedin  medium  pubdev'), findsOneWidget);

      await _type(tester, 'open l');
      await _press(tester, LogicalKeyboardKey.tab);
      expect(_input(tester).text, 'open linkedin ');
    });

    testWidgets('ignores an argument nothing starts with', (tester) async {
      await tester.pumpWidget(_buildTerminal(guestbook));
      final linesBefore = _outputLineCount(tester);
      await _type(tester, 'cat zz');
      await _press(tester, LogicalKeyboardKey.tab);

      expect(_input(tester).text, 'cat zz');
      expect(_outputLineCount(tester), linesBefore);
    });

    testWidgets('still completes after a command was run', (tester) async {
      await tester.pumpWidget(_buildTerminal(guestbook));
      await _run(tester, 'ls');

      tester.testTextInput.enterText('neo');
      await tester.pump();
      expect(await _press(tester, LogicalKeyboardKey.tab), isTrue);
      expect(_input(tester).text, 'neofetch ');
    });

    testWidgets('does not complete arguments of other commands', (
      tester,
    ) async {
      await tester.pumpWidget(_buildTerminal(guestbook));
      final linesBefore = _outputLineCount(tester);
      await _type(tester, 'echo ab');

      expect(await _press(tester, LogicalKeyboardKey.tab), isTrue);
      expect(_input(tester).text, 'echo ab');
      expect(_outputLineCount(tester), linesBefore);
    });
  });

  group('TerminalContent scrolling', () {
    testWidgets('follows the output to the bottom once it overflows', (
      tester,
    ) async {
      await tester.pumpWidget(_buildTerminal(guestbook));
      expect(_outputScroll(tester).maxScrollExtent, 0);

      await _run(tester, 'help');
      await _run(tester, 'neofetch');
      await _run(tester, 'help');

      final scroll = _outputScroll(tester);
      expect(scroll.maxScrollExtent, greaterThan(0));
      expect(scroll.pixels, scroll.maxScrollExtent);
      expect(find.textContaining('cmd1 ; cmd2'), findsOneWidget);
      expect(find.textContaining('Portfolio Terminal v2.0'), findsNothing);
    });

    testWidgets('animates to the bottom instead of jumping', (tester) async {
      await tester.pumpWidget(_buildTerminal(guestbook));
      await _run(tester, 'help');
      await _run(tester, 'help');
      final start = _outputScroll(tester).pixels;

      await tester.enterText(find.byType(TextField), 'help');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump(); // runs the command
      await tester.pump(); // paints the output, then asks for the scroll
      await tester.pump(); // first tick of the animation
      await tester.pump(const Duration(milliseconds: 50));
      final scroll = _outputScroll(tester);
      expect(scroll.pixels, greaterThan(start));
      expect(scroll.pixels, lessThan(scroll.maxScrollExtent));

      await tester.pump(const Duration(milliseconds: 60));
      expect(scroll.pixels, scroll.maxScrollExtent);
    });

    testWidgets('tab suggestions are scrolled into view too', (tester) async {
      await tester.pumpWidget(_buildTerminal(guestbook));
      await _run(tester, 'help');
      await _run(tester, 'help');
      await _type(tester, 'cat ');
      await _press(tester, LogicalKeyboardKey.tab);

      final scroll = _outputScroll(tester);
      expect(scroll.pixels, scroll.maxScrollExtent);
      expect(
        find.text('about.txt  experience.txt  skills.txt  contact.txt'),
        findsOneWidget,
      );
    });
  });

  group('TerminalContent focus', () {
    testWidgets('the prompt keeps the focus after a command, so arrow up '
        'recalls it without clicking the terminal again', (tester) async {
      await tester.pumpWidget(_buildTerminal(guestbook));
      await _run(tester, 'echo kept');

      expect(_inputFocus(tester).hasFocus, isTrue);

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
      await tester.pump();
      expect(_input(tester).text, 'echo kept');
    });

    testWidgets('the next command can be typed straight away', (tester) async {
      await tester.pumpWidget(_buildTerminal(guestbook));
      await _run(tester, 'echo one');

      // Straight to the attached keyboard: `enterText` on the field would
      // focus it first, which is exactly the click this must not need.
      expect(tester.testTextInput.isVisible, isTrue);
      tester.testTextInput.enterText('echo two');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await _settleOutput(tester);

      expect(find.text('two'), findsOneWidget);
      expect(_inputFocus(tester).hasFocus, isTrue);
    });

    testWidgets('tapping the output gives the focus back to the prompt', (
      tester,
    ) async {
      await tester.pumpWidget(_buildTerminal(guestbook));
      await tester.pump();
      _inputFocus(tester).unfocus();
      await tester.pump();
      expect(_inputFocus(tester).hasFocus, isFalse);

      await tester.tap(find.byType(ListView));
      await tester.pump();

      expect(_inputFocus(tester).hasFocus, isTrue);
    });

    testWidgets('clicking outside the terminal does not blur the prompt', (
      tester,
    ) async {
      // On desktop a TextField drops its focus on any outside click by default.
      debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
      await tester.pumpWidget(_buildTerminal(guestbook));
      await tester.pump();
      expect(_inputFocus(tester).hasFocus, isTrue);

      await tester.tap(find.byKey(_outsideKey), kind: PointerDeviceKind.mouse);
      await tester.pump();

      expect(_inputFocus(tester).hasFocus, isTrue);
      debugDefaultTargetPlatformOverride = null;
    });
  });
}
