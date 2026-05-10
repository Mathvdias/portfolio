import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../controllers/language_controller.dart';
import '../l10n/app_localizations.dart';
import '../models/experience.dart';
import '../models/project.dart';
import '../services/github_service.dart';
import '../theme/app_theme.dart';
import '../widgets/about_window_content.dart';
import '../widgets/app_window.dart';
import '../widgets/desktop_icon.dart';
import '../widgets/dock.dart';
import '../widgets/experience_window_content.dart';
import '../widgets/mac_menu_bar.dart';
import '../widgets/pixel_icon_painter.dart';
import '../widgets/project_window_content.dart';
import '../widgets/responsive_layout.dart';

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

  @override
  void initState() {
    super.initState();
    _loadRepos();
  }

  Future<void> _loadRepos() async {
    try {
      final data = await _githubService.getRepositories();
      if (!mounted) return;
      setState(() {
        _repos = data
            .map((r) => Project.fromJson(r as Map<String, dynamic>))
            .where((p) => p.name != 'intercepted_http' && p.name != 'portifolio')
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
        technologies: (e['technologies'] as List<dynamic>?)
                ?.map((t) => t as String)
                .toList() ??
            [],
      );
    }).toList();
  }

  Color _colorForCompany(String company) {
    if (company.contains('Zallpy')) {
      return AppTheme.mauve;
    }
    if (company.contains('Banco') ||
        company.contains('PAN') ||
        company.contains('Pan')) {
      return AppTheme.green;
    }
    if (company.contains('Conecthus')) {
      return AppTheme.peach;
    }
    return AppTheme.subtext;
  }

  List<List<int>> _pixelsForCompany(String company) {
    if (company.contains('Zallpy')) {
      return kTerminalPixels;
    }
    if (company.contains('Banco') ||
        company.contains('PAN') ||
        company.contains('Pan')) {
      return kBankPixels;
    }
    if (company.contains('Conecthus')) {
      return kCircuitPixels;
    }
    return kTerminalPixels;
  }

  Widget _buildIconsArea(
      AppLocalizations l10n, List<Experience> experiences) {
    final icons = <Widget>[];

    // About icon
    icons.add(
      DesktopIcon(
        label: l10n.about,
        pixels: kPersonPixels,
        color: AppTheme.blue,
        onTap: () => _openWindow(
          'about',
          l10n.about,
          AboutWindowContent(bio: l10n.bio, role: l10n.role),
          AppTheme.blue,
        ),
      ),
    );

    // Experience icons
    for (int i = 0; i < experiences.length; i++) {
      final exp = experiences[i];
      final color = _colorForCompany(exp.company);
      final pixels = _pixelsForCompany(exp.company);
      final shortName = exp.company.split(' ').first;
      icons.add(
        DesktopIcon(
          label: shortName,
          pixels: pixels,
          color: color,
          onTap: () => _openWindow(
            'exp_$i',
            shortName,
            ExperienceWindowContent(experience: exp, accentColor: color),
            color,
          ),
        ),
      );
    }

    // intercepted_http icon
    icons.add(
      DesktopIcon(
        label: 'intercepted\n_http',
        pixels: kPackagePixels,
        color: AppTheme.teal,
        onTap: () => _openWindow(
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
            version: '1.0.0',
            technologies: ['Flutter', 'Dart', 'HTTP', 'Testing'],
            accentColor: AppTheme.teal,
          ),
          AppTheme.teal,
        ),
      ),
    );

    // GitHub repo icons
    for (int i = 0; i < _repos.length; i++) {
      final repo = _repos[i];
      final label = repo.name.length > 12
          ? '${repo.name.substring(0, 12)}...'
          : repo.name;
      icons.add(
        DesktopIcon(
          label: label,
          pixels: kGithubPixels,
          color: AppTheme.mauve,
          onTap: () => _openWindow(
            'repo_$i',
            repo.name,
            ProjectWindowContent(
              name: repo.name,
              description: repo.description.isEmpty
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

    return Align(
      alignment: Alignment.topRight,
      child: Padding(
        padding: const EdgeInsets.only(top: 12, right: 12),
        child: Wrap(
          direction: Axis.vertical,
          spacing: 6,
          runSpacing: 6,
          children: icons,
        ),
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
          // Desktop icons area
          Positioned.fill(
            top: 28,
            bottom: 60,
            child: _buildIconsArea(l10n, experiences),
          ),
          // Open windows
          ..._windows.map((w) => AppWindow(
                key: ValueKey(w.id),
                title: w.title,
                initialPosition: w.position,
                accentColor: w.accentColor,
                onClose: () => _closeWindow(w.id),
                onFocus: () => _focusWindow(w.id),
                child: w.content,
              )),
          // Menu bar (on top of everything)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: MacMenuBar(
              currentLanguage: languageController.currentLanguage,
              onLanguageChanged: (code) =>
                  languageController.setLocale(Locale(code)),
            ),
          ),
          // Dock (on top)
          const Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Dock(),
          ),
        ],
      ),
    );
  }
}
