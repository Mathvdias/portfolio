import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../theme/app_theme.dart';
import '../constants/app_sizes.dart';
import '../constants/app_strings.dart';

const _kPrompt = 'matheus@portfolio:~\$ ';

const _kHelp = '''available commands:
  help       show this message
  whoami     about me
  ls         list sections
  cat        cat <file> — read a section
  skills     tech stack
  date       current date/time
  neofetch   system info
  open       open <github|linkedin|medium|pubdev>
  clear      clear terminal
  echo       echo <text>
  history    show command history

  Supports sequential commands:
    cmd1 && cmd2   run cmd2 only if cmd1 succeeds
    cmd1 ; cmd2    run both regardless''';

const _kWhoami =
    'Matheus Dias — Flutter/Mobile Engineer\n'
    'Building fast, beautiful apps with Flutter & Kotlin\n'
    'Open source contributor · pub.dev author';

const _kLs =
    'about.txt   experience.txt   skills.txt   projects/   contact.txt';

const _kSkills = '''languages:   Dart · Kotlin · Swift (basic)
frameworks:  Flutter · Android SDK · Jetpack Compose
backend:     REST APIs · Firebase · GraphQL (basic)
tools:       Git · GitHub · Fastlane · Figma · VS Code
testing:     Unit · Widget · Integration''';

const _kNeofetch = '''
  ██████  matheus @ portfolio
  ██████  ─────────────────────
  ██████  OS:       Portfolio OS 1.0
  ██████  Kernel:   Flutter 3.x
          Shell:    portfolio-sh
          Terminal: PortfolioTerm
          CPU:      Dart VM
          Memory:   ∞ widgets loaded
          Theme:    Catppuccin Mocha
          Uptime:   always on ☕
''';

const _kCatFiles = <String, String>{
  'about.txt':
      'Flutter/Mobile Engineer based in Brazil.\n'
      'Passionate about pixel-perfect UIs and open source.\n'
      'Author of intercepted_http on pub.dev.',
  'experience.txt':
      '• Zallpy Digital        – Sep 2024 – Present  (Flutter)\n'
      '• Banco Pan             – Jan 2024 – Aug 2024 (Flutter)\n'
      '• Conecthus             – Aug 2021 – Dec 2023 (Android/Flutter)',
  'skills.txt': _kSkills,
  'contact.txt':
      'Email:    mattmvc56@gmail.com\n'
      'GitHub:   github.com/Mathvdias\n'
      'LinkedIn: linkedin.com/in/matheusvdias\n'
      'Medium:   medium.com/@matheusvdias',
};

const _kUrls = <String, String>{
  'github': AppStrings.urlGitHub,
  'linkedin': AppStrings.urlLinkedIn,
  'medium': AppStrings.urlMedium,
  'pubdev': AppStrings.urlPubDev,
};

/// Known command names for tab-completion.
const _kCommands = [
  'help', 'whoami', 'ls', 'cat', 'skills', 'date',
  'neofetch', 'open', 'clear', 'echo', 'history',
];

/// Known file names for `cat` tab-completion.
const _kFiles = [
  'about.txt', 'experience.txt', 'skills.txt', 'contact.txt',
];

/// Known `open` targets for tab-completion.
const _kOpenTargets = ['github', 'linkedin', 'medium', 'pubdev'];

class TerminalContent extends StatefulWidget {
  const TerminalContent({super.key});

  @override
  State<TerminalContent> createState() => _TerminalContentState();
}

/// Represents a styled line in the terminal output.
class _Line {
  final String text;
  final Color color;
  const _Line(this.text, [this.color = AppTheme.text]);
}

class _TerminalContentState extends State<TerminalContent> {
  final _scroll = ScrollController();
  final _ctrl = TextEditingController();
  final _focus = FocusNode();
  final _history = <_Line>[];
  final _cmdHistory = <String>[];
  int _historyIndex = -1;

  @override
  void initState() {
    super.initState();
    _history.add(
      const _Line(
        'Portfolio Terminal v2.0 — type "help" to start',
        AppTheme.teal,
      ),
    );
    _history.add(const _Line(''));
  }

  @override
  void dispose() {
    _scroll.dispose();
    _ctrl.dispose();
    _focus.dispose();
    super.dispose();
  }

  // ── Submit ─────────────────────────────────────────────────────
  Future<void> _submit(String input) async {
    final trimmed = input.trim();
    setState(() {
      _history.add(_Line('$_kPrompt$trimmed', AppTheme.blue));
      if (trimmed.isNotEmpty) {
        _cmdHistory.insert(0, trimmed);
      }
      _historyIndex = -1;
    });
    _ctrl.clear();

    await _executeSequential(trimmed);

    _scrollToBottom();
  }

  // ── Sequential command parsing (&&  ;) ─────────────────────────
  Future<void> _executeSequential(String raw) async {
    // Split by ; first (always run both)
    final semiParts = raw.split(';');
    for (final semiPart in semiParts) {
      // Within each semicolon segment, split by && (stop on failure)
      final andParts = semiPart.split('&&');
      for (final part in andParts) {
        final cmd = part.trim();
        if (cmd.isEmpty) continue;
        final output = await _run(cmd);
        if (!mounted) return;
        setState(() {
          if (output == null) {
            _history.clear();
          } else if (output.isNotEmpty) {
            for (final line in output.split('\n')) {
              _history.add(_Line(line));
            }
          }
          _history.add(const _Line(''));
        });
        // If the command "failed" (command not found) and we're in && mode,
        // skip remaining && parts
        if (output != null && output.contains('command not found')) break;
      }
    }
  }

  // ── Execute a single command ───────────────────────────────────
  Future<String?> _run(String input) async {
    if (input.isEmpty) return '';
    final parts = input.trim().split(RegExp(r'\s+'));
    final cmd = parts[0].toLowerCase();
    final args = parts.sublist(1);

    switch (cmd) {
      case 'help':
        return _kHelp;
      case 'whoami':
        return _kWhoami;
      case 'ls':
        return _kLs;
      case 'cat':
        if (args.isEmpty) return 'usage: cat <file>';
        final file = args[0];
        return _kCatFiles[file] ?? 'cat: $file: No such file or directory';
      case 'skills':
        return _kSkills;
      case 'date':
        return DateTime.now().toString();
      case 'neofetch':
        return _kNeofetch;
      case 'echo':
        return args.join(' ');
      case 'clear':
        return null;
      case 'history':
        if (_cmdHistory.isEmpty) return '(empty history)';
        final sb = StringBuffer();
        for (int i = _cmdHistory.length - 1; i >= 0; i--) {
          sb.writeln('  ${_cmdHistory.length - i}  ${_cmdHistory[i]}');
        }
        return sb.toString().trimRight();
      case 'open':
        if (args.isEmpty) return 'usage: open <github|linkedin|medium|pubdev>';
        final target = args[0].toLowerCase();
        final url = _kUrls[target];
        if (url == null) return 'open: unknown target "$target"';
        final uri = Uri.parse(url);
        if (await canLaunchUrl(uri)) await launchUrl(uri);
        return 'opening $url...';
      default:
        return 'command not found: $cmd\nType "help" for available commands.';
    }
  }

  // ── Tab completion ─────────────────────────────────────────────
  void _tabComplete() {
    final text = _ctrl.text;
    final parts = text.split(RegExp(r'\s+'));

    if (parts.length <= 1) {
      // Complete command name
      final prefix = parts[0].toLowerCase();
      final matches = _kCommands.where((c) => c.startsWith(prefix)).toList();
      if (matches.length == 1) {
        _ctrl.text = '${matches[0]} ';
        _ctrl.selection = TextSelection.collapsed(offset: _ctrl.text.length);
      } else if (matches.isNotEmpty) {
        setState(() {
          _history.add(_Line('$_kPrompt$text', AppTheme.blue));
          _history.add(_Line(matches.join('  ')));
          _history.add(const _Line(''));
        });
        _scrollToBottom();
      }
    } else {
      // Complete argument based on command
      final cmd = parts[0].toLowerCase();
      final argPrefix = parts.last.toLowerCase();
      List<String> pool;

      if (cmd == 'cat') {
        pool = _kFiles;
      } else if (cmd == 'open') {
        pool = _kOpenTargets;
      } else {
        return;
      }

      final matches = pool.where((f) => f.startsWith(argPrefix)).toList();
      if (matches.length == 1) {
        parts[parts.length - 1] = matches[0];
        _ctrl.text = '${parts.join(' ')} ';
        _ctrl.selection = TextSelection.collapsed(offset: _ctrl.text.length);
      } else if (matches.isNotEmpty) {
        setState(() {
          _history.add(_Line('$_kPrompt$text', AppTheme.blue));
          _history.add(_Line(matches.join('  ')));
          _history.add(const _Line(''));
        });
        _scrollToBottom();
      }
    }
  }

  // ── Keyboard handler for ↑ / ↓ / Tab ──────────────────────────
  KeyEventResult _onKey(FocusNode _, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;

    // Tab → autocomplete
    if (event.logicalKey == LogicalKeyboardKey.tab) {
      _tabComplete();
      return KeyEventResult.handled;
    }

    // ↑ → previous command
    if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
      if (_cmdHistory.isNotEmpty) {
        _historyIndex = (_historyIndex + 1).clamp(0, _cmdHistory.length - 1);
        _ctrl.text = _cmdHistory[_historyIndex];
        _ctrl.selection = TextSelection.collapsed(offset: _ctrl.text.length);
      }
      return KeyEventResult.handled;
    }

    // ↓ → next command
    if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
      if (_historyIndex > 0) {
        _historyIndex--;
        _ctrl.text = _cmdHistory[_historyIndex];
        _ctrl.selection = TextSelection.collapsed(offset: _ctrl.text.length);
      } else {
        _historyIndex = -1;
        _ctrl.clear();
      }
      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 100),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      padding: const EdgeInsets.all(AppSizes.terminalPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scroll,
              itemCount: _history.length,
              itemBuilder: (_, i) => Text(
                _history[i].text,
                style: GoogleFonts.spaceMono(
                  fontSize: AppSizes.terminalFontSize,
                  color: _history[i].color,
                  height: 1.5,
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSizes.spacingMd),
          Focus(
            onKeyEvent: _onKey,
            child: Row(
              children: [
                Text(
                  _kPrompt,
                  style: GoogleFonts.spaceMono(
                    fontSize: AppSizes.terminalFontSize,
                    color: AppTheme.green,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Expanded(
                  child: TextField(
                    controller: _ctrl,
                    focusNode: _focus,
                    autofocus: true,
                    style: GoogleFonts.spaceMono(
                      fontSize: AppSizes.terminalFontSize,
                      color: AppTheme.text,
                    ),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                    cursorColor: AppTheme.green,
                    onSubmitted: _submit,
                    onTapOutside: (_) => _focus.requestFocus(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
