import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../controllers/language_controller.dart';
import '../l10n/app_localizations.dart';
import '../models/experience.dart';
import '../models/project.dart';
import '../services/github_service.dart';
import '../services/visitor_service.dart';
import '../theme/app_theme.dart';
import '../widgets/about_window_content.dart';
import '../widgets/app_window.dart';
import '../widgets/calculator_content.dart';
import '../widgets/contact_form_content.dart';
import '../widgets/desktop_icon.dart';
import '../widgets/dock.dart';
import '../widgets/experience_window_content.dart';
import '../widgets/finder_content.dart';
import '../widgets/mac_menu_bar.dart';
import '../widgets/notification_center.dart';
import '../widgets/pixel_icon_painter.dart';
import '../widgets/pixel_wallpaper.dart';
import '../widgets/project_window_content.dart';
import '../widgets/responsive_layout.dart';
import '../widgets/skills_window_content.dart';
import '../widgets/snake_game_content.dart';
import '../widgets/sticky_note.dart';
import '../widgets/terminal_content.dart';

class _WindowEntry {
  _WindowEntry({
    required this.id,
    required this.title,
    required this.content,
    required this.accentColor,
    required this.position,
  });

  final String id;
  final String title;
  final Widget content;
  final Color accentColor;
  Offset position;
}

class DesktopPage extends StatefulWidget {
  const DesktopPage({super.key});

  @override
  State<DesktopPage> createState() => _DesktopPageState();
}

class _DesktopPageState extends State<DesktopPage> {
  final List<_WindowEntry> _windows = [];
  List<Project> _repos = [];
  final _githubService = GitHubService();
  int _windowCount = 0;
  bool _showNotifications = false;

  @override
  void initState() {
    super.initState();
    _loadRepos();
    VisitorService().recordVisit();
  }

  Future<void> _loadRepos() async {
    try {
      final data = await _githubService.getRepositories();
      if (!mounted) return;
      setState(() {
        _repos =
            data
                .map((r) => Project.fromJson(r as Map<String, dynamic>))
                .where(
                  (p) => p.name != 'intercepted_http' && p.name != 'portifolio',
                )
                .toList();
      });
    } catch (_) {}
  }

  void _openWindow(String id, String title, Widget content, Color accent) {
    setState(() {
      _windows.removeWhere((w) => w.id == id);
      final offset = Offset(
        80 + (_windowCount % 6) * 28.0,
        48 + (_windowCount % 6) * 28.0,
      );
      _windowCount++;
      _windows.add(
        _WindowEntry(
          id: id,
          title: title,
          content: content,
          accentColor: accent,
          position: offset,
        ),
      );
    });
  }

  void _closeWindow(String id) {
    setState(() => _windows.removeWhere((w) => w.id == id));
  }

  void _focusWindow(String id) {
    setState(() {
      final idx = _windows.indexWhere((w) => w.id == id);
      if (idx == -1 || idx == _windows.length - 1) return;
      final entry = _windows.removeAt(idx);
      _windows.add(entry);
    });
  }

  List<Experience> _buildExperiences(AppLocalizations l10n) {
    return l10n.experiences.map((e) {
      return Experience(
        company: e['company'] as String? ?? '',
        role: e['role'] as String? ?? '',
        period: e['period'] as String? ?? '',
        description: e['description'] as String? ?? '',
        technologies:
            (e['technologies'] as List<dynamic>?)
                ?.map((t) => t as String)
                .toList() ??
            [],
      );
    }).toList();
  }

  Color _colorForCompany(String company) {
    if (company.contains('Zallpy')) {
      return AppTheme.teal;
    }
    if (company.contains('Banco') ||
        company.contains('PAN') ||
        company.contains('Pan')) {
      return AppTheme.blue;
    }
    if (company.contains('Conecthus')) {
      return AppTheme.green;
    }
    return AppTheme.peach;
  }

  List<List<int>> _pixelsForCompany(String company) {
    if (company.contains('Zallpy')) {
      return kZallpyPixels;
    }
    if (company.contains('Banco') ||
        company.contains('PAN') ||
        company.contains('Pan')) {
      return kBankPixels;
    }
    if (company.contains('Conecthus')) {
      return kConecthusPixels;
    }
    if (company.contains('Oi')) {
      return kOiPixels;
    }
    return kTerminalPixels;
  }

  String _shortNameFor(String company) {
    if (company.contains('Zallpy')) return 'Zallpy';
    if (company.contains('PAN') ||
        company.contains('Pan') ||
        company.contains('Banco')) {
      return 'Banco Pan';
    }
    if (company.contains('Conecthus')) return 'Conecthus';
    return company.split(' ').first;
  }

  Widget _buildIconsArea(AppLocalizations l10n, List<Experience> experiences) {
    final icons = <Widget>[];

    icons.add(
      DesktopIcon(
        label: l10n.about,
        pixels: kPersonPixels,
        color: AppTheme.blue,
        onTap:
            () => _openWindow(
              'about',
              l10n.about,
              AboutWindowContent(bio: l10n.bio, role: l10n.role),
              AppTheme.blue,
            ),
      ),
    );

    icons.add(
      DesktopIcon(
        label: 'Finder',
        pixels: kFinderPixels,
        color: AppTheme.red,
        onTap:
            () => _openWindow(
              'finder',
              'Finder',
              const FinderContent(),
              AppTheme.red,
            ),
      ),
    );

    for (int i = 0; i < experiences.length; i++) {
      final exp = experiences[i];
      final color = _colorForCompany(exp.company);
      final pixels = _pixelsForCompany(exp.company);
      final shortName = _shortNameFor(exp.company);
      icons.add(
        DesktopIcon(
          label: shortName,
          pixels: pixels,
          color: color,
          onTap:
              () => _openWindow(
                'exp_$i',
                shortName,
                ExperienceWindowContent(experience: exp, accentColor: color),
                color,
              ),
        ),
      );
    }

    icons.add(
      DesktopIcon(
        label: 'Skills',
        pixels: kSkillsPixels,
        color: AppTheme.blue,
        onTap:
            () => _openWindow(
              'skills',
              'Skills',
              const SkillsWindowContent(),
              AppTheme.blue,
            ),
      ),
    );

    icons.add(
      DesktopIcon(
        label: 'Android',
        pixels: kAndroidPixels,
        color: AppTheme.green,
        onTap:
            () => _openWindow(
              'android',
              'Android Dev',
              const SkillsWindowContent(),
              AppTheme.green,
            ),
      ),
    );

    icons.add(
      DesktopIcon(
        label: 'Terminal',
        pixels: kTerminalPixels,
        color: AppTheme.green,
        onTap:
            () => _openWindow(
              'terminal',
              'Terminal',
              const TerminalContent(),
              AppTheme.green,
            ),
      ),
    );

    icons.add(
      DesktopIcon(
        label: 'Calculator',
        pixels: kCalculatorPixels,
        color: AppTheme.peach,
        onTap:
            () => _openWindow(
              'calculator',
              'Calculator',
              const CalculatorContent(),
              AppTheme.peach,
            ),
      ),
    );

    icons.add(
      DesktopIcon(
        label: 'Snake',
        pixels: kSnakePixels,
        color: AppTheme.peach,
        onTap:
            () => _openWindow(
              'snake',
              'Snake',
              const SnakeGameContent(),
              AppTheme.peach,
            ),
      ),
    );

    icons.add(
      DesktopIcon(
        label: 'Contact',
        pixels: kMailPixels,
        color: AppTheme.teal,
        onTap:
            () => _openWindow(
              'contact',
              'Contact',
              const ContactFormContent(),
              AppTheme.teal,
            ),
      ),
    );

    icons.add(
      DesktopIcon(
        label: 'Whitepaper',
        pixels: kMarianaPixels,
        color: AppTheme.blue,
        onTap: () async {
          final uri = Uri.parse('https://matheusdias.gitbook.io/tesouro');
          if (await canLaunchUrl(uri)) await launchUrl(uri);
        },
      ),
    );

    icons.add(
      DesktopIcon(
        label: 'Resume',
        pixels: kLinkPixels,
        color: AppTheme.red,
        onTap: () async {
          final uri = Uri.parse('assets/resume.pdf');
          if (await canLaunchUrl(uri)) await launchUrl(uri);
        },
      ),
    );

    icons.add(
      DesktopIcon(
        label: 'intercepted\n_http',
        pixels: kShieldPixels,
        color: AppTheme.blue,
        onTap:
            () => _openWindow(
              'intercepted_http',
              'intercepted_http',
              const ProjectWindowContent(
                name: 'intercepted_http',
                description:
                    'A Flutter/Dart package that intercepts HTTP requests and responses, '
                    'allowing you to inspect, mock, and modify network traffic in your app. '
                    'Useful for debugging and testing.',
                githubUrl: 'https://github.com/Mathvdias/intercepted_http',
                pubDevUrl: 'https://pub.dev/packages/intercepted_http',
                version: '0.2.1',
                technologies: ['Flutter', 'Dart', 'HTTP', 'Testing'],
                accentColor: AppTheme.teal,
              ),
              AppTheme.teal,
            ),
      ),
    );

    for (int i = 0; i < _repos.length; i++) {
      final repo = _repos[i];
      final label =
          repo.name.length > 10 ? repo.name.substring(0, 10) : repo.name;
      icons.add(
        DesktopIcon(
          label: label,
          pixels: kGithubPixels,
          color: AppTheme.mauve,
          onTap:
              () => _openWindow(
                'repo_$i',
                repo.name,
                ProjectWindowContent(
                  name: repo.name,
                  description:
                      repo.description.isEmpty
                          ? 'No description available.'
                          : repo.description,
                  githubUrl: repo.githubUrl,
                  technologies: repo.technologies,
                  accentColor: AppTheme.mauve,
                ),
                AppTheme.mauve,
              ),
        ),
      );
    }

    return Container(
      alignment: Alignment.topRight,
      padding: const EdgeInsets.only(top: 8, right: 8, bottom: 8, left: 8),
      child: Wrap(
        direction: Axis.vertical,
        alignment: WrapAlignment.start,
        runAlignment: WrapAlignment.end,
        verticalDirection: VerticalDirection.down,
        textDirection: TextDirection.rtl,
        spacing: 6.0,
        runSpacing: 6.0,
        children: icons,
      ),
    );
  }

  Widget _buildMobileView(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'MATHEUS DIAS',
              style: GoogleFonts.pressStart2p(
                fontSize: 14,
                color: AppTheme.blue,
                height: 1.8,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Portfolio\ndesigned\nfor desktop',
              style: GoogleFonts.pressStart2p(
                fontSize: 8,
                color: AppTheme.subtext,
                height: 1.8,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            TextButton(
              onPressed: () async {
                final uri = Uri.parse('https://github.com/Mathvdias');
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri);
                }
              },
              child: Text(
                'github.com/Mathvdias',
                style: GoogleFonts.spaceMono(
                  fontSize: 13,
                  color: AppTheme.teal,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (ResponsiveLayout.isMobile(context)) return _buildMobileView(context);

    final l10n = AppLocalizations.of(context);
    final languageController = Provider.of<LanguageController>(context);
    final experiences = _buildExperiences(l10n);

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Stack(
        children: [
          const Positioned.fill(child: PixelWallpaper()),

          StickyNote(
            initialPosition: const Offset(40, 100),
            text: l10n.stickyNoteTodo,
            color: const Color(0xFFFDE68A),
          ),

          VisitorStickyNote(
            initialPosition: const Offset(40, 260),
            color: const Color(0xFFBAE6FD),
          ),

          Positioned.fill(
            top: 28,
            bottom: 80,
            child: _buildIconsArea(l10n, experiences),
          ),

          ..._windows.map(
            (w) => AppWindow(
              key: ValueKey(w.id),
              title: w.title,
              initialPosition: w.position,
              accentColor: w.accentColor,
              onClose: () => _closeWindow(w.id),
              onFocus: () => _focusWindow(w.id),
              child: w.content,
            ),
          ),

          if (_showNotifications)
            Positioned(
              top: 28,
              right: 0,
              bottom: 0,
              child: const NotificationCenter(),
            ),

          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: MacMenuBar(
              currentLanguage: languageController.currentLanguage,
              onLanguageChanged:
                  (code) => languageController.setLocale(Locale(code)),
              onToggleNotifications: () {
                setState(() {
                  _showNotifications = !_showNotifications;
                });
              },
            ),
          ),

          const Positioned(
            bottom: 10,
            left: 0,
            right: 0,
            child: Center(child: Dock()),
          ),
        ],
      ),
    );
  }
}
