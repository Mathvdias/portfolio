import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../theme/app_theme.dart';

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
  echo       echo <text>''';

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
  'github': 'https://github.com/Mathvdias',
  'linkedin': 'https://www.linkedin.com/in/matheusvdias/',
  'medium': 'https://medium.com/@matheusvdias',
  'pubdev': 'https://pub.dev/packages/intercepted_http',
};

class TerminalContent extends StatefulWidget {
  const TerminalContent({super.key});

  @override
  State<TerminalContent> createState() => _TerminalContentState();
}

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

  @override
  void initState() {
    super.initState();
    _history.add(
      const _Line(
        'Portfolio Terminal v1.0 — type "help" to start',
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

  Future<void> _submit(String input) async {
    final trimmed = input.trim();
    setState(() {
      _history.add(_Line('$_kPrompt$trimmed', AppTheme.blue));
      if (trimmed.isNotEmpty) _cmdHistory.insert(0, trimmed);
    });
    _ctrl.clear();

    final output = await _run(trimmed);
    if (!mounted) return;
    setState(() {
      if (output == null) {
        // clear
        _history.clear();
      } else if (output.isNotEmpty) {
        for (final line in output.split('\n')) {
          _history.add(_Line(line));
        }
      }
      _history.add(const _Line(''));
    });

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

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scroll,
              itemCount: _history.length,
              itemBuilder:
                  (_, i) => Text(
                    _history[i].text,
                    style: GoogleFonts.spaceMono(
                      fontSize: 12,
                      color: _history[i].color,
                      height: 1.5,
                    ),
                  ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                _kPrompt,
                style: GoogleFonts.spaceMono(
                  fontSize: 12,
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
                    fontSize: 12,
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
        ],
      ),
    );
  }
}
